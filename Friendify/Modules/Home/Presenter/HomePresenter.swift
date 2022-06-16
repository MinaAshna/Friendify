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

    var mpc: MultipeerConnectivityManager?
    var nearbyInteractionManager: NearbyInteractionManagerProtocol?

    var limiter = Limiter(policy: .debounce, duration: 2)
    // A threshold, in meters, the app uses to update its display.
    let nearbyDistanceThreshold: Float = 0.3
    var currentDistanceDirectionState: DistanceDirectionState = .unknown

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func startup(session: NISession?) {
        if let session = session, mpc != nil, !viewModel.niObjects.isEmpty {
            if let obj = viewModel.niObjects.first(where: { $0.value.session?.discoveryToken == session.discoveryToken }) {
                if let token = obj.value.session?.discoveryToken {
                    if obj.value.sharedTokenWithPeer == false {
                        shareMyDiscoveryToken(token: token, toPeer: obj.key)
                    }

                    guard let peerToken = obj.value.peerDiscoveryToken else {
                        return
                    }

                    runSession(forPeer: obj.key, peerToken: peerToken)
                } else {
                    fatalError("Unable to get self discovery token, is this session invalidated?")
                }
            }
            fatalError("unhandled condition")
        } else {
            startupMPC()
            viewModel.currentDistanceDirectionState = .unknown
        }
    }
}

// MARK: - Multipeer Connectivity
extension HomePresenter {
    func startupMPC() {
        if mpc == nil {
            mpc = MultipeerConnectivityManager(service: "friendify",
                                               identity: "MPC-UWB-Experience",
                                               maxPeers: 1)
            mpc?.delegate = self
        }
        mpc?.invalidate()
        mpc?.start()
    }

    func shareMyDiscoveryToken(token: NIDiscoveryToken, toPeer peer: MCPeerID) {
        guard let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        print("I \(peer.displayName) share my discovery token.")
        viewModel.logs.append("I \(peer.displayName) share my discovery token.")
        mpc?.sendDataToAllPeers(data: encodedData)
        viewModel.niObjects[peer]?.sharedTokenWithPeer = true
    }

    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        print("\(peer.displayName) did share discovery token.")
        viewModel.logs.append("\(peer.displayName) did share discovery token.")
        viewModel.logs.append("peer discovery token \(token)")


        viewModel.niObjects[peer]?.peerDiscoveryToken = token
        runSession(forPeer: peer, peerToken: token)
    }
}

// MARK: - NearbyInteraction
extension HomePresenter {
    func startupNI(forPeer peer: MCPeerID) {
        if nearbyInteractionManager == nil {
            nearbyInteractionManager = NearbyInteractionManager()
            nearbyInteractionManager?.delegate = self
        }
        viewModel.logs.append("setup ni for peer \(peer.displayName)")
        print("setup ni for peer \(peer.displayName)")
        setup(forPeer: peer)
    }


    func setup(forPeer peer: MCPeerID) {
        var niObject = NIObject()
        niObject.session = NISession()
        niObject.session?.delegate = nearbyInteractionManager as? NISessionDelegate
        niObject.peer = peer
        viewModel.niObjects[peer] = niObject
        viewModel.logs.append("niobject \(viewModel.niObjects[peer]?.peer?.displayName)")

        print("niobject \(viewModel.niObjects[peer]?.peer?.displayName)")
    }

    func runSession(forPeer peer: MCPeerID, peerToken token: NIDiscoveryToken) {
        let config = NINearbyPeerConfiguration(peerToken: token)
        viewModel.niObjects[peer]?.session?.run(config)
    }

    private func updateDistanceToPeer(_ session: NISession, nearbyObject: NINearbyObject) {
        if let niObject = self.viewModel.niObjects.first(where: { $0.value.peerDiscoveryToken == nearbyObject.discoveryToken }) {
            let currentDistance = self.viewModel.niObjects[niObject.key]?.distanceToPeer
            if currentDistance == nil {
                self.viewModel.niObjects[niObject.key]?.distanceToPeer = nearbyObject.distance
                self.viewModel.nearbyObjectsDistance[niObject.key] = nearbyObject.distance
                
            } else {
//                if let distance = currentDistance,
//                   let nearbyObjectDistance = nearbyObject.distance,
//                    abs(distance - nearbyObjectDistance) > 0.1 {
                    self.viewModel.niObjects[niObject.key]?.distanceToPeer = nearbyObject.distance
                    self.viewModel.nearbyObjectsDistance[niObject.key] = nearbyObject.distance
                    self.viewModel.distanceToPeer = nearbyObject.distance
//                }
            }

            let nextState = getDistanceDirectionState(from: nearbyObject)
            calculateRotationAngle(from: viewModel.currentDistanceDirectionState, to: nextState, with: nearbyObject)
            viewModel.currentDistanceDirectionState = nextState

        }
    }
}

// MARK: - NearbyInteractionDelegate
extension HomePresenter: NearbyInteractionDelegate {
    func sessionSuspentionEnded(_ session: NISession) {
        print("NISession suspention ended.")
        viewModel.logs.append("NISession suspention ended.")

        if let config = session.configuration {
            session.run(config)
        } else {
            startup(session: session)
        }
    }

    func sessionInvalidated(_ session: NISession) {
        print("NISession Invalidated.")
        viewModel.logs.append("NISession Invalidated.")
        viewModel.currentDistanceDirectionState = .unknown

        startup(session: session)
    }

    func sessionIsSuspended(_ session: NISession) {
        viewModel.currentDistanceDirectionState = .unknown
    }

    func sessionDidRemoveObject(_ session: NISession) {
        print("NISession did remove object.")
        viewModel.logs.append("NISession did remove object.")
        viewModel.currentDistanceDirectionState = .unknown

        startup(session: session)
    }

    func sessionDistanceToPeerUpdated(_ session: NISession, _ obj: NINearbyObject) {
        Task { @MainActor in
            await limiter.submit {
                self.updateDistanceToPeer(session, nearbyObject: obj)
            }
        }
    }
}

// MARK: - MultipeerConnectiviyProtocol
extension HomePresenter: MultipeerConnectivityDelegate {
    func session(_ session: MCSession, didReceiveData data: Data, fromPeer peer: MCPeerID) {
        print("\(session.myPeerID.displayName) did receive data from \(peer.displayName)")
        viewModel.logs.append("\(session.myPeerID.displayName) did receive data from \(peer.displayName)")

        if let username = String(data: data, encoding: .utf8) {
            print("\(session.myPeerID.displayName) did receive data \(username) from \(peer.displayName)")
            viewModel.logs.append("\(session.myPeerID.displayName) did receive data \(username) from \(peer.displayName)")

            viewModel.nearbyObjectsNames[peer] = username
        } else {
            guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
                fatalError("Unexpectedly failed to decode discovery token.")
            }
            print("\(session.myPeerID.displayName) did receive discovery token from \(peer.displayName)")
            viewModel.logs.append("\(session.myPeerID.displayName) did receive discovery token from \(peer.displayName)")

            peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
        }
    }

    func session(_ session: MCSession, didConnecToPeer peer: MCPeerID) {
        startupNI(forPeer: peer)
        viewModel.connectedPeers.append(peer)
        viewModel.sessionState = .peerConnected
        print("\(session.myPeerID.displayName) did connect to peer \(peer.displayName)")
        viewModel.logs.append("\(session.myPeerID.displayName) did connect to peer \(peer.displayName)")

        guard let myToken = viewModel.niObjects[peer]?.session?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }


        if viewModel.niObjects[peer]?.sharedTokenWithPeer == false {
            shareMyDiscoveryToken(token: myToken, toPeer: peer)
        }
    }

    func session(_ session: MCSession, didDisconnectFromPeer peer: MCPeerID) {
        print("\(session.myPeerID.displayName) did disconnect from peer \(peer.displayName)")
        viewModel.logs.append("\(session.myPeerID.displayName) did disconnect from peer \(peer.displayName)")

        if let index = viewModel.connectedPeers.firstIndex(of: peer) {
            viewModel.connectedPeers.remove(at: index)
        }
        viewModel.nearbyObjectsNames.removeValue(forKey: peer)
        viewModel.nearbyObjectsDistance.removeValue(forKey: peer)
        viewModel.sessionState = .peerEnded
    }

    func session(_ session: MCSession, isConnectingToPeer peer: MCPeerID) {
        print("\(session.myPeerID.displayName) is connecting to peer \(peer.displayName)")
        viewModel.logs.append("\(session.myPeerID.displayName) is connecting to peer \(peer.displayName)")

        viewModel.sessionState = .connecting
    }

    func session(_ session: MCSession, isInUnknownStateWithPeer peer: MCPeerID) {
        print("\(session.myPeerID.displayName) is in unknown state with peer \(peer.displayName)")
        viewModel.logs.append("\(session.myPeerID.displayName) is in unknown state with peer \(peer.displayName)")

    }
    func peer(_ peerID: MCPeerID, lostPeer peer: MCPeerID) {
        print("\(peerID.displayName) lost connection to peer \(peer.displayName)")
        viewModel.logs.append("\(peerID.displayName) lost connection to peer \(peer.displayName)")
    }

    func failedToSendData(toPeers peers: [MCPeerID], error: Error) {
        peers.forEach { peer in
            viewModel.logs.append("Error in sending Data to \(peer). error: \(error)")
            print("Error in sending Data to \(peer). error: \(error)")
        }
    }

}

extension HomePresenter: HomePresenterProtocol {
    func mingleButtonPressed() {
        if viewModel.sessionState == .notConnected {
            startup(session: nil)
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
        viewModel.logs.append("Rotation Angle: \(rotationAngle)")
    }
}
