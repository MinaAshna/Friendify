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
    @Published var displayName: String = "Guest"
    @Published var connectedPeerDisplayName: String?
    @Published var sessionState: SessionState = .notConnected
    @Published var rotationAngle: Double = 0
    @Published var distanceToPeer: Float?

    @Published var logs: [String] = []

    var niObjects: [MCPeerID: NIObject] = [:]
    @Published var nearbyObjectsDistance: [MCPeerID: Float] = [:] {
        didSet {
            sortConnectedPeers()
        }
    }
    @Published var nearbyObjectsNames: [MCPeerID: String] = [:]
    @Published var connectedPeers: [MCPeerID] = []

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

