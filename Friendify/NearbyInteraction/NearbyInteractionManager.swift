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
    func sessionInvalidated(_ session: NISession)
    func sessionDidRemoveObject(_ session: NISession)
    func sessionDidUpdateDistanceToPeer(_ obj: NINearbyObject)
}

protocol NearbyInteractionManagerProtocol {
    
}

class NearbyInteractionManager: NSObject, NearbyInteractionManagerProtocol {
    weak var delegate: NearbyInteractionDelegate?
    init(delegate: NearbyInteractionDelegate?) {
        self.delegate = delegate
    }
}

extension NearbyInteractionManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        nearbyObjects.forEach {
            delegate?.sessionDidUpdateDistanceToPeer($0)
        }
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        switch reason {
        case .peerEnded:
            print("disconnected -> PeerEnded")
            session.invalidate()
            delegate?.sessionDidRemoveObject(session)
        case .timeout:
            print("disconnected -> timeout")
            if let config = session.configuration {
                session.run(config)
                print("Session is recovered")
            }
        @unknown default:
            fatalError()
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("Session is invalid")
        delegate?.sessionInvalidated(session)
    }

    func sessionWasSuspended(_ session: NISession) {
        print("session is suspended")
        delegate?.sessionWasSuspended(session)
    }

    func sessionSuspensionEnded(_ session: NISession) {
        print("session suspention ended")
        delegate?.sessionSuspentionEnded(session)
    }
}
