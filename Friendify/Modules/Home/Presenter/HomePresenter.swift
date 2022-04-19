//
//  HomePresenter.swift
//  Friendify
//
//  Created by Mina Ashna on 18/04/2022.
//

import Foundation
import MultipeerConnectivity
import NearbyInteraction

protocol HomePresenterProtocol {
    func mingleButtonPressed()
}

class HomePresenter {
    var viewModel: AppViewModel
    var currentDistanceDirectionState: DistanceDirectionState = .unknown
    var connectedPeer: MCPeerID?
    var sharedTokenWithPeer = false

    var mpc: MultipeerConnectivityManagerProtocol?
    var nearbyInteractionManager: NearbyInteractionManager?

    // A threshold, in meters, the app uses to update its display.
    let nearbyDistanceThreshold: Float = 0.3

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func startup() {
        guard NISession.isSupported else {
            viewModel.sessionState = .notSupported
            return
        }

        nearbyInteractionManager = NearbyInteractionManager()
        nearbyInteractionManager?.start()
        nearbyInteractionManager?.delegate = self

        // Because the session is new, reset the token-shared flag.
        sharedTokenWithPeer = false

        // If `connectedPeer` exists, share the discovery token, if needed.
        if connectedPeer != nil && mpc != nil {
            if let myToken = nearbyInteractionManager?.session?.discoveryToken {
                viewModel.sessionState = .initializing
                if !sharedTokenWithPeer {
                    shareMyDiscoveryToken(token: myToken)
                }
                guard let peerToken = nearbyInteractionManager?.peerDiscoveryToken else {
                    fatalError("peer discovery token is not available")
                }
                let config = NINearbyPeerConfiguration(peerToken: peerToken)
                nearbyInteractionManager?.session?.run(config)
            } else {
                fatalError("Unable to get self discovery token, is this session invalidated?")
            }
        } else {
            viewModel.sessionState = .discovering
            startupMPC()

            // Set the display state.
            currentDistanceDirectionState = .unknown
        }
    }


    func startupMPC() {
        if mpc == nil {
            mpc = MultipeerConnectivityManager(service: "friendify", identity: "com.minaashna.Friendify", maxPeers: 1)
            mpc?.delegate = self
        }
        mpc?.invalidate()
        mpc?.start()
    }

    func shareMyDiscoveryToken(token: NIDiscoveryToken) {
        guard let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        mpc?.sendDataToAllPeers(data: encodedData)
        sharedTokenWithPeer = true
    }

    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        if connectedPeer != peer {
            fatalError("Received token from unexpected peer.")
        }
        // Create a configuration.
        nearbyInteractionManager?.peerDiscoveryToken = token

        let config = NINearbyPeerConfiguration(peerToken: token)

        // Run the session.
        nearbyInteractionManager?.session?.run(config)
    }
}

extension HomePresenter: HomePresenterProtocol {
    func mingleButtonPressed() {
        if viewModel.sessionState == .notConnected {
            startup()
        } else {
         // TBD: cancel the flow

        }
    }
}

extension HomePresenter: MultipeerConnectivityDelegate {
    func peerDidReceiveData(data: Data, peer: MCPeerID) {
        guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            fatalError("Unexpectedly failed to decode discovery token.")
        }
        peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
    }

    func didConnect(toPeer peer: MCPeerID) {
        guard let myToken = nearbyInteractionManager?.session?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }

        if connectedPeer != nil {
            fatalError("Already connected to a peer.")
        }

        if !sharedTokenWithPeer {
            shareMyDiscoveryToken(token: myToken)
        }

        connectedPeer = peer
        viewModel.connectedPeerDisplayName = peer.displayName
        viewModel.sessionState = .peerConnected
    }

    func didDisconnect(fromPeer peer: MCPeerID) {
        if connectedPeer == peer {
            connectedPeer = nil
            sharedTokenWithPeer = false
            viewModel.sessionState = .notConnected
            viewModel.distanceToPeer = nil
            viewModel.connectedPeerDisplayName = ""
        }
    }
}

extension HomePresenter: NearbyInteractionDelegate {
    func sessionWasSuspended(_ session: NISession) {
        currentDistanceDirectionState = .unknown
        viewModel.sessionState = .sessionSuspended
        viewModel.distanceToPeer = nil
    }

    func sessionSuspentionEnded(_ session: NISession) {
        // Create a valid configuration.
        startup()
    }

    func sessionInvalidated(_ session: NISession, withError error: Error) {
        currentDistanceDirectionState = .unknown
        viewModel.distanceToPeer = nil

        if case NIError.userDidNotAllow = error {
            viewModel.sessionState = .accessRequired
        }

        // Recreate a valid session.
        startup()
    }

    func sessionDidRemoveObject(_ session: NISession, reason: NINearbyObject.RemovalReason) {
        currentDistanceDirectionState = .unknown
        viewModel.distanceToPeer = nil

        switch reason {
        case .peerEnded:
            // Restart the sequence to see if the peer comes back.
            startup()

            // Update the app's display.
            viewModel.sessionState = .peerEnded
        case .timeout:
            viewModel.sessionState = .peerTimeout
        default:
            fatalError("Unknown and unhandled NINearbyObject.RemovalReason")
        }
    }

    func sessionDidUpdateDistanceToPeer(_ obj: NINearbyObject) {
        let nextState = getDistanceDirectionState(from: obj)
        currentDistanceDirectionState = nextState
        viewModel.distanceToPeer = obj.distance
        Task { @MainActor in
            calculateRotationAngle(from: currentDistanceDirectionState, to: nextState, with: obj)
        }
    }
}

// MARK: - Private functions
extension HomePresenter {
    private func getDistanceDirectionState(from nearbyObject: NINearbyObject) -> DistanceDirectionState {
        if nearbyObject.distance == nil && nearbyObject.direction == nil {
            return .unknown
        }

        let isNearby = nearbyObject.distance.map(isNearby(_:)) ?? false
        let directionAvailable = nearbyObject.direction != nil

        if isNearby && directionAvailable {
            return .closeUpInFOV
        }

        if !isNearby && directionAvailable {
            return .notCloseUpInFOV
        }

        return .outOfFOV
    }

    private func isNearby(_ distance: Float) -> Bool {
        return distance < nearbyDistanceThreshold
    }

    private func isPointingAt(_ angleRad: Float) -> Bool {
        // Consider the range -15 to +15 to be "pointing at".
        return abs(angleRad.radiansToDegrees) <= 15
    }

    private func calculateRotationAngle(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
        let azimuth = peer.direction.map(azimuth(from:))
        let rotationAngle = CGFloat(azimuth ?? 0.0)
        viewModel.rotationAngle = rotationAngle
        print("Rotation Angle: \(rotationAngle)")
    }
}
