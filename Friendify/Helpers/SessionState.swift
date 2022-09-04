//
//  SessionState.swift
//  Friendify
//
//  Created by Mina Ashna on 18/04/2022.
//

enum SessionState: String {
    case notConnected = "Not Connected"
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case initializing = "Initializing ..."
    case discovering = "Discovering Peer ..."
    case peerEnded = "Peer Ended"
    case peerConnected = "Connected"
    case peerConnectedAndPositionShared = "Connected "
    case peerTimeout = "Peer Timeout"
    case sessionSuspended = "Session suspended"
    case accessRequired = "Nearby Interactions access required. You can change access in Settings."
    case notSupported = "Nearby Interaction is not supported on this device"
}
