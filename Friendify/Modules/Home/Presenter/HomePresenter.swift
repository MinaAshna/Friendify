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
    func connectButtonTapped()
    func sendMessage()
}

class HomePresenter {
    var viewModel: AppViewModel

    var mpc: MultipeerConnectivityManager?
    var nearbyInteractionManager: NearbyInteractionManager?

    var limiter = Limiter(policy: .debounce, duration: 2)
    // A threshold, in meters, the app uses to update its display.
    let nearbyDistanceThreshold: Float = 0.3
    var currentDistanceDirectionState: DistanceDirectionState = .unknown

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func startup(session: NISession?) {
        guard session != nil, mpc != nil else {
            startupMPC()
            return
        }
        
        if let token = viewModel.myObject.nearbyInteractionSession?.discoveryToken {
            if viewModel.nearbyObject != nil, let peer = viewModel.myObject.connectedPeer {
                shareMyDiscoveryToken(token: token, toPeer: peer)
                runSession(forPeer: peer, peerToken: token)
                viewModel.sessionState = .connecting
            }
        } else {
            fatalError("Unable to get self discovery token, is this session invalidated?")
        }
    }
}

// MARK: - Multipeer Connectivity
extension HomePresenter {
    func startupMPC() {
        if mpc == nil {
            mpc = MultipeerConnectivityManager(service: "friendify",
                                               identity: "MPC-UWB-Experience",
                                               peerID: viewModel.myObject.displayName,
                                               maxPeers: 1)
            mpc?.delegate = self
        }
        mpc?.invalidate()
        mpc?.start()
        if let myPeerID = self.mpc?.myPeerID {
            viewModel.myObject.multipeerConnectivityPeerID = myPeerID
        }
        viewModel.mpc = mpc
        
        viewModel.currentDistanceDirectionState = .unknown
        viewModel.sessionState = .discovering
    }

    func shareMyDiscoveryToken(token: NIDiscoveryToken, toPeer peer: MCPeerID) {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }

        mpc?.sendDataToAllPeers(data: encodedData)
        viewModel.myObject.sharedTokenWithPeer = true
        viewModel.sessionState = .peerConnectedAndPositionShared
        viewModel.logs.append("\(viewModel.myObject.displayName) shared discovery token with \(peer.displayName).")
        
    }

    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        viewModel.logs.append("\(peer.displayName) shared discovery token with \(viewModel.myObject.displayName).")
        viewModel.logs.append("\(peer.displayName) discovery token is \n\(token)")

        if viewModel.nearbyObject == nil {
            startupNI(forPeer: peer)
        }
        viewModel.nearbyObject?.discoveryToken = token
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
        viewModel.logs.append("Setting up Nearby Interaction with peer \(peer.displayName)")
        setup(forPeer: peer)
    }
    
    func setup(forPeer peer: MCPeerID) {
        viewModel.myObject.nearbyInteractionSession = NISession()
        viewModel.myObject.nearbyInteractionSession?.delegate = nearbyInteractionManager
        var nearbyObject = NearbyInteractionObject()
        nearbyObject.peerID = peer
        viewModel.nearbyObject = nearbyObject
    }
    
    func runSession(forPeer peer: MCPeerID, peerToken token: NIDiscoveryToken) {
        let config = NINearbyPeerConfiguration(peerToken: token)
        
        viewModel.myObject.nearbyInteractionSession?.run(config)
        
        viewModel.logs.append("\(viewModel.myObject.displayName) ran NISession with \(peer.displayName)")
    }
    
    func updateDistanceToPeer(_ session: NISession, nearbyObject: NINearbyObject) {
        if viewModel.nearbyObject?.discoveryToken == nearbyObject.discoveryToken {
            let currentDistance = self.viewModel.myObject.distanceToPeer
            if currentDistance == nil {
                self.viewModel.myObject.distanceToPeer = nearbyObject.distance
            } else {
                self.viewModel.myObject.distanceToPeer = nearbyObject.distance
            }
            
            let nextState = getDistanceDirectionState(from: nearbyObject)
            calculateRotationAngle(from: viewModel.currentDistanceDirectionState, to: nextState, with: nearbyObject)
            viewModel.currentDistanceDirectionState = nextState
        }
    }
    
    func disconnect() {
        viewModel.mpc?.invalidate()
        viewModel.myObject.connectedPeer = nil
        viewModel.myObject.distanceToPeer = nil
        viewModel.myObject.nearbyInteractionSession = nil
        viewModel.myObject.multipeerConnectivityPeerID = nil
        viewModel.nearbyObject = nil
        viewModel.azimuthDirection = nil
        viewModel.rotationAngle = 0
        viewModel.logs = []
        viewModel.mpc = nil
    }
}

extension HomePresenter: HomePresenterProtocol {
    func connectButtonTapped() {
        switch viewModel.sessionState {
        case .notConnected:
            startup(session: nil)
        case .peerConnected:
            if viewModel.isNearbyInteractionSupported {
                
                mpc = viewModel.mpc
                
                if let peer = viewModel.myObject.connectedPeer {
                    if viewModel.nearbyObject == nil {
                        startupNI(forPeer: peer)
                    }
                    if let myToken = viewModel.myObject.nearbyInteractionSession?.discoveryToken, viewModel.myObject.sharedTokenWithPeer == false {
                        shareMyDiscoveryToken(token: myToken, toPeer: peer)
                    }
                }
            } 
        default:
            fatalError("Button must not be active.")
        }
    }
    
    func sendMessage() {
        if let message = viewModel.message.data(using: .utf8) {
            viewModel.chat.append("You: \(viewModel.message)")
            viewModel.mpc?.sendDataToAllPeers(data: message)
            viewModel.message = ""
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

    private func calculateRotationAngle(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
        let azimuth = peer.direction.map(azimuth(from:))

        if let azimuth {
            let rotationAngle = CGFloat(azimuth)
            viewModel.rotationAngle = rotationAngle

            if nextState == .outOfFOV || nextState == .unknown {
                return
            }

            if azimuth < 0 {
                viewModel.azimuthDirection = .left
            } else {
                viewModel.azimuthDirection = .right
            }
        }
    }
}
