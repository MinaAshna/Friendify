//
//  HomePresenter+MultipeerConnectivityDelegate.swift
//  Friendify
//
//  Created by Mina Ashna on 02/08/2022.
//

import Foundation
import MultipeerConnectivity
import NearbyInteraction

extension HomePresenter: MultipeerConnectivityDelegate {
    func session(_ session: MCSession, didReceiveData data: Data, fromPeer peer: MCPeerID) {
        viewModel.logs.append("\(session.myPeerID.displayName) did receive data from \(peer.displayName)")

        if let message = String(data: data, encoding: .utf8) {
            viewModel.logs.append("\(session.myPeerID.displayName) did receive message \(message) from \(peer.displayName)")
            viewModel.logs.append(message)
            viewModel.chat.append("\(session.myPeerID.displayName): \(message)")
        } else {
            guard let discoveryToken = try? NSKeyedUnarchiver
                .unarchivedObject(ofClass: NIDiscoveryToken.self,
                                  from: data) else {
                fatalError("Unexpectedly failed to decode discovery token.")
            }
            viewModel.logs.append("\(session.myPeerID.displayName) did receive discovery token from \(peer.displayName)")

            if viewModel.isNearbyInteractionSupported {
                peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
            }
        }
    }

    func session(_ session: MCSession, didConnecToPeer peer: MCPeerID) {
        viewModel.myObject.connectedPeer = peer
        viewModel.sessionState = .peerConnected
        viewModel.logs.append("\(session.myPeerID.displayName) did connect to peer \(peer.displayName)")


        viewModel.mpc = mpc
    }

    func session(_ session: MCSession, didDisconnectFromPeer peer: MCPeerID) {
        viewModel.logs.append("\(session.myPeerID.displayName) did disconnect from peer \(peer.displayName)")
        viewModel.sessionState = .peerEnded
        disconnect()
    }

    func session(_ session: MCSession, isConnectingToPeer peer: MCPeerID) {
        viewModel.logs.append("\(session.myPeerID.displayName) is connecting to peer \(peer.displayName)")

        viewModel.sessionState = .connecting
    }

    func session(_ session: MCSession, isInUnknownStateWithPeer peer: MCPeerID) {
        viewModel.logs.append("\(session.myPeerID.displayName) is in unknown state with peer \(peer.displayName)")

    }
    func peer(_ peerID: MCPeerID, lostPeer peer: MCPeerID) {
        viewModel.logs.append("\(peerID.displayName) lost connection to peer \(peer.displayName)")
    }

    func failedToSendData(toPeers peers: [MCPeerID], error: Error) {
        peers.forEach { peer in
            viewModel.logs.append("Error in sending Data to \(peer). error: \(error)")
        }
    }

}
