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
    func mingleButtonPressed()
}

class HomePresenter {
    var viewModel: AppViewModel
    var session: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?
    var currentDistanceDirectionState: DistanceDirectionState = .unknown
    var connectedPeer: MCPeerID?
    var sharedTokenWithPeer = false

    var mpc: MultipeerConnectivityManagerProtocol?
    var nearbyInteractionManager: NearbyInteractionManager?

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func startup() {
        // Create the NISession.
        session = NISession()

        // Set the delegate.
        session?.delegate = nearbyInteractionManager

        // Because the session is new, reset the token-shared flag.
        sharedTokenWithPeer = false

        // If `connectedPeer` exists, share the discovery token, if needed.
        if connectedPeer != nil && mpc != nil {
            if let myToken = session?.discoveryToken {
                viewModel.sessionState = .initializing
                if !sharedTokenWithPeer {
                    shareMyDiscoveryToken(token: myToken)
                }
                guard let peerToken = peerDiscoveryToken else {
                    return
                }
                let config = NINearbyPeerConfiguration(peerToken: peerToken)
                session?.run(config)
            } else {
                fatalError("Unable to get self discovery token, is this session invalidated?")
            }
        } else {
            viewModel.sessionState = .discovering
            startupMPC()

            // Set the display state.
            currentDistanceDirectionState = .unknown
        }
    }


    func startupMPC() {
        if mpc == nil {
            mpc = MultipeerConnectivityManager(service: "nisample", identity: "com.example.apple-samplecode.simulator.peekaboo-nearbyinteraction", maxPeers: 1)
        }
        mpc?.invalidate()
        mpc?.start()
    }

    func shareMyDiscoveryToken(token: NIDiscoveryToken) {
        guard let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        mpc?.sendDataToAllPeers(data: encodedData)
        sharedTokenWithPeer = true
    }
}

extension HomePresenter: HomePresenterProtocol {
    func mingleButtonPressed() {

    }
}

extension HomePresenter: MultipeerConnectivityDelegate {
    func peerDidReceiveData(data: Data, peer: MCPeerID) {

    }

    func didConnect(toPeer peer: MCPeerID) {

    }

    func didDisconnect(fromPeer peer: MCPeerID) {

    }
}

extension HomePresenter: NearbyInteractionDelegate {
    func sessionWasSuspended(_ session: NISession) {
        currentDistanceDirectionState = .unknown
        viewModel.sessionState = .sessionSuspended
    }

    func sessionSuspentionEnded(_ session: NISession) {

    }

    func sessionInvalidated(_ session: NISession) {

    }

    func sessionDidRemoveObject(_ session: NISession) {

    }

    func sessionDidUpdateDistanceToPeer(_ obj: NINearbyObject) {

    }
}
