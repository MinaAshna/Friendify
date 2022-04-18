//
//  SessionState.swift
//  Friendify
//
//  Created by Mina Ashna on 18/04/2022.
//

enum SessionState: String {
    case notConnected = "Not Connected"
    case initializing = "Initializing ..."
    case discovering = "Discovering Peer ..."
    case peerEnded = "Peer Ended"
    case peerTimeout = "Peer Timeout"
    case sessionSuspended = "Session suspended"
    case accessRequired = "Nearby Interactions access required. You can change access in Settings."
}
