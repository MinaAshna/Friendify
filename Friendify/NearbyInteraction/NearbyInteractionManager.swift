import NearbyInteraction

public protocol NearbyInteractionDelegate: AnyObject {
    func sessionSuspentionEnded(_ session: NISession)
    func sessionInvalidated(_ session: NISession)
    func sessionIsSuspended(_ session: NISession)
    func sessionDidRemoveObject(_ session: NISession)
    func sessionDistanceToPeerUpdated(_ session: NISession, _ obj: NINearbyObject)
}

protocol NearbyInteractionManagerProtocol {
    var delegate: NearbyInteractionDelegate? { get set }
}

public class NearbyInteractionManager: NSObject {
     var delegate: NearbyInteractionDelegate?
}

extension NearbyInteractionManager: NISessionDelegate {
    public func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        nearbyObjects.forEach {
            delegate?.sessionDistanceToPeerUpdated(session, $0)
        }
    }

    
    // MARK: - Session state
    public func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
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

    public func session(_ session: NISession, didInvalidateWith error: Error) {
        print("Session is invalid")
        delegate?.sessionInvalidated(session)
    }

    public func sessionWasSuspended(_ session: NISession) {
        print("session is suspended")
        delegate?.sessionIsSuspended(session)
    }

    public func sessionSuspensionEnded(_ session: NISession) {
        print("session suspention ended")
        delegate?.sessionSuspentionEnded(session)
    }
}

