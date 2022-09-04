//
//  MultipeerConnectivityBrowserDelegate.swift
//  Friendify
//
//  Created by Mina Ashna on 14/08/2022.
//

import Foundation
import MultipeerConnectivity

extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    internal func browser(_ browser: MCNearbyServiceBrowser,
                          foundPeer peerID: MCPeerID,
                          withDiscoveryInfo info: [String: String]?) {
        guard let identityValue = info?[MPCSessionConstants.kKeyIdentity] else {
            return
        }
        if identityValue == identityString && mcSession.connectedPeers.count < maxNumPeers {
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
        }
    }
    
    internal func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
}
