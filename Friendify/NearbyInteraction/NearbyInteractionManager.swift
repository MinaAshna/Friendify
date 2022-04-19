//
//  NearbyInteractionManager.swift
//  Friendify
//
//  Created by Mina Ashna on 18/04/2022.
//

import NearbyInteraction

protocol NearbyInteractionDelegate: AnyObject {
    func sessionWasSuspended(_ session: NISession)
    func sessionSuspentionEnded(_ session: NISession)
    func sessionInvalidated(_ session: NISession, withError error: Error)
    func sessionDidRemoveObject(_ session: NISession, reason: NINearbyObject.RemovalReason)
    func sessionDidUpdateDistanceToPeer(_ obj: NINearbyObject)
}

protocol NearbyInteractionManagerProtocol {
    
}

class NearbyInteractionManager: NSObject, NearbyInteractionManagerProtocol {
    weak var delegate: NearbyInteractionDelegate?
    var session: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?

    func start() {
        // Create the NISession.
        session = NISession()

        // Set the delegate.
        session?.delegate = self
    }
}

extension NearbyInteractionManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }

        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }

        guard let nearbyObjectUpdate = peerObj else {
            return
        }

        delegate?.sessionDidUpdateDistanceToPeer(nearbyObjectUpdate)
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }

        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }

        if peerObj == nil {
            return
        }

        switch reason {
        case .peerEnded:
            print("disconnected -> PeerEnded")
            peerDiscoveryToken = nil
            session.invalidate()
        case .timeout:
            print("disconnected -> timeout")
            if let config = session.configuration {
                session.run(config)
                print("Session is recovered")
            }
        @unknown default:
            fatalError()
        }

        delegate?.sessionDidRemoveObject(session, reason: reason)
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("Session is invalid")
        delegate?.sessionInvalidated(session, withError: error)
    }

    func sessionWasSuspended(_ session: NISession) {
        print("session is suspended")
        delegate?.sessionWasSuspended(session)
    }

    func sessionSuspensionEnded(_ session: NISession) {
        print("session suspention ended")
        if let config = session.configuration {
            session.run(config)
        } else {
            // Create a valid configuration.
            delegate?.sessionSuspentionEnded(session)
        }

    }
}


