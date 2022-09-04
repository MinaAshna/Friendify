//
//  MultipeerConnectivitySesstionDelegate.swift
//  Friendify
//
//  Created by Mina Ashna on 14/08/2022.
//

import Foundation
import MultipeerConnectivity

extension MultipeerConnectivityManager: MCSessionDelegate {
    
    internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.delegate?.session(session, didConnecToPeer: peerID)
                if session.connectedPeers.count == maxNumPeers {
                    self.suspend()
                }
            case .notConnected:
                self.delegate?.session(session, didDisconnectFromPeer: peerID)
                if session.connectedPeers.count < maxNumPeers {
                    self.start()
                }
            case .connecting:
                self.delegate?.session(session, isConnectingToPeer: peerID)
            @unknown default:
                self.delegate?.session(session, isInUnknownStateWithPeer: peerID)
            }
        }
    }
    
    internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            delegate?.session(session, didReceiveData: data, fromPeer: peerID)
        }
    }
    
    
    
    
    // MARK: - Not part of the demo
    internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // The sample app intentional omits this implementation.
    }
    
    internal func session(_ session: MCSession,
                          didStartReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          with progress: Progress) {
        // The sample appdi intentional omits this implementation.
    }
    
    internal func session(_ session: MCSession,
                          didFinishReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          at localURL: URL?,
                          withError error: Error?) {
        // The sample app intentional omits this implementation.
    }
}
