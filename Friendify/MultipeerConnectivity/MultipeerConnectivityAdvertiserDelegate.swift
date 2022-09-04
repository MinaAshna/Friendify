//
//  MultipeerConnectivityAdvertiserDelegate.swift
//  Friendify
//
//  Created by Mina Ashna on 14/08/2022.
//

import Foundation
import MultipeerConnectivity

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                             didReceiveInvitationFromPeer peerID: MCPeerID,
                             withContext context: Data?,
                             invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if self.mcSession.connectedPeers.count < maxNumPeers {
            invitationHandler(true, mcSession)
        }
    }
}
