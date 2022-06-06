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

    var mpc: MultipeerConnectivityManagerProtocol?
    var nearbyInteractionManager: NearbyInteractionManagerProtocol?

    var limiter = Limiter(policy: .debounce, duration: 2)
    // A threshold, in meters, the app uses to update its display.
    let nearbyDistanceThreshold: Float = 0.3

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
        } else {
            startupMPC()
        }
    }
}

// MARK: - Multipeer Connectivity
extension HomePresenter {
    func startupMPC() {
        if mpc == nil {
            mpc = MultipeerConnectivityManager(service: "Whitelabels",
                                                      identity: "MPC-UWB-Experience",
                                                      displayName: "InStore Employee")
        }
        mpc?.invalidate()
        mpc?.start()
    }

    func shareMyDiscoveryToken(token: NIDiscoveryToken, toPeer peer: MCPeerID) {
        guard let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        mpc?.sendDataToPeers(data: encodedData, peers: [peer], mode: .reliable)
        viewModel.niObjects[peer]?.sharedTokenWithPeer = true
    }

    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
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
        setup(forPeer: peer)
    }


    func setup(forPeer peer: MCPeerID) {
        var niObject = NIObject()
        niObject.session = NISession()
        niObject.session?.delegate = nearbyInteractionManager as? NISessionDelegate
        niObject.peer = peer
        viewModel.niObjects[peer] = niObject
    }

    func runSession(forPeer peer: MCPeerID, peerToken token: NIDiscoveryToken) {
        let config = NINearbyPeerConfiguration(peerToken: token)
        viewModel.niObjects[peer]?.session?.run(config)
    }

    private func updateDistanceToPeer(nearbyObject: NINearbyObject) {
        if let niObject = self.viewModel.niObjects.first(where: { $0.value.peerDiscoveryToken == nearbyObject.discoveryToken }) {
            let currentDistance = self.viewModel.niObjects[niObject.key]?.distanceToPeer
            if currentDistance == nil {
                self.viewModel.niObjects[niObject.key]?.distanceToPeer = nearbyObject.distance
                self.viewModel.nearbyObjectsDistance[niObject.key] = nearbyObject.distance
            } else {
                if let distance = currentDistance,
                   let nearbyObjectDistance = nearbyObject.distance,
                   abs(distance - nearbyObjectDistance) > 0.1 {
                    self.viewModel.niObjects[niObject.key]?.distanceToPeer = nearbyObject.distance
                    self.viewModel.nearbyObjectsDistance[niObject.key] = nearbyObject.distance
                }
            }
        }
    }
}

// MARK: - NearbyInteractionDelegate
extension HomePresenter: NearbyInteractionDelegate {
    func sessionSuspentionEnded(_ session: NISession) {
        if let config = session.configuration {
            session.run(config)
        } else {
            startup(session: session)
        }
    }

    func sessionInvalidated(_ session: NISession) {
        startup(session: session)
    }

    func sessionDidRemoveObject(_ session: NISession) {
        startup(session: session)
    }

    func sessionDistanceToPeerUpdated(_ obj: NINearbyObject) {
        Task { @MainActor in
            await limiter.submit {
                self.updateDistanceToPeer(nearbyObject: obj)
            }
        }
    }
}

// MARK: - MultipeerConnectiviyProtocol
extension HomePresenter: MultipeerConnectivityDelegate {
    func sessionDidReceiveData(_ data: Data, fromPeer peer: MCPeerID) {
        if let username = String(data: data, encoding: .utf8) {
            viewModel.nearbyObjectsNames[peer] = username
        } else {
            guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
                fatalError("Unexpectedly failed to decode discovery token.")
            }
            peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
        }
    }

    func sessionDidConnect(toPeer peer: MCPeerID) {
        startupNI(forPeer: peer)
        viewModel.connectedPeers.append(peer)

        guard let myToken = viewModel.niObjects[peer]?.session?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }

        if viewModel.niObjects[peer]?.sharedTokenWithPeer == false {
            shareMyDiscoveryToken(token: myToken, toPeer: peer)
        }
    }

    func sessionDidDisconnect(formPeer peer: MCPeerID) {
        if let index = viewModel.connectedPeers.firstIndex(of: peer) {
            viewModel.connectedPeers.remove(at: index)
        }
        viewModel.nearbyObjectsNames.removeValue(forKey: peer)
        viewModel.nearbyObjectsDistance.removeValue(forKey: peer)
    }

    func sessionIsConnecting(toPeer peer: MCPeerID) {}

    func sessionIsInUnknownState(toPeer peer: MCPeerID) {
        print("There is a new state that is not handled")
    }

    func failedToSendData(toPeers peers: [MCPeerID], error: Error) {
        print("Error in sending Data. error: \(error)")
    }

    func sessionLostPeer(_ peer: MCPeerID) {
        print("lost connection to peer: \(peer)")
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
    }
}
