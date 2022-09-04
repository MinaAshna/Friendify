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
    @Published var myObject: Object = Object()
    @Published var nearbyObject: NearbyInteractionObject?
    
    @Published var message: String = ""
    @Published var sessionState: SessionState = .notConnected
    @Published var rotationAngle: Double = 0
    @Published var azimuthDirection: Direction?
    @Published var currentDistanceDirectionState: DistanceDirectionState = .unknown
    @Published var logs: [String] = []
    var isNearbyInteractionSupported: Bool {
        if #available(iOS 16.0, watchOS 9.0, *) {
           return NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
        } else {
            return NISession.isSupported
        }
    }
    var mpc: MultipeerConnectivityManager?
    

    var imageName: String {
        switch sessionState {
        case .discovering:
            return "discovering"
        case .disconnected:
            return "accessRequired"
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
        case .peerConnectedAndPositionShared:
            return "connected"
        }
    }
}

struct Object {
    var nearbyInteractionSession: NISession?
    var multipeerConnectivityPeerID: MCPeerID?
    var connectedPeer: MCPeerID?
    var displayName: String = ""
    var distanceToPeer: Float?
    var sharedTokenWithPeer = false
}

struct NearbyInteractionObject {
    var discoveryToken: NIDiscoveryToken?
    var displayName: String?
    var peerID: MCPeerID?
}

enum Direction: String {
    case left
    case right
}
