//
//  ViewModel.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import SwiftUI
import MultipeerConnectivity
import NearbyInteraction

class AppViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var connectedPeerDisplayName: String?
    @Published var sessionState: SessionState = .notConnected
    @Published var rotationAngle: Double = 0
    @Published var distanceToPeer: Float?
    @Published var azimuthDirection: Direction?
    @Published var elevationDirection: Direction?
    @Published var currentDistanceDirectionState: DistanceDirectionState = .unknown


    @Published var logs: [String] = []

    var niObjects: [MCPeerID: NIObject] = [:]
    @Published var nearbyObjectsDistance: [MCPeerID: Float] = [:] {
        didSet {
            sortConnectedPeers()
        }
    }
    @Published var nearbyObjectsNames: [MCPeerID: String] = [:]
    @Published var connectedPeers: [MCPeerID] = []
    var imageName: String {
        switch sessionState {
        case .discovering:
            return "discovering"
        case .connecting:
            return "connecting"
        case .peerConnected:
            return "connected"
        case .notConnected:
            return ""
        case .initializing:
            return ""
        case .peerEnded:
            return "peerEnded"
        case .peerTimeout:
            return ""
        case .sessionSuspended:
            return "suspended"
        case .accessRequired:
            return "accessRequired"
        case .notSupported:
            return "notSupported"
        }
    }
    func sortConnectedPeers() {
        connectedPeers.sort { (peer, peer1) in
            if let firstPeer = nearbyObjectsDistance[peer],
               let secondPeer = nearbyObjectsDistance[peer1] {
                return firstPeer < secondPeer
            } else {
                return false
            }
        }
    }
}

struct NIObject {
    var peerDiscoveryToken: NIDiscoveryToken?
    var session: NISession?
    var distanceToPeer: Float?
    var sharedTokenWithPeer = false
    var peer: MCPeerID?
}

enum Direction: String {
    case left
    case right
    case up
    case down
}
