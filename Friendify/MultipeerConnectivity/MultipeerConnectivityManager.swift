import Foundation
import MultipeerConnectivity

struct MPCSessionConstants {
    static let kKeyIdentity: String = "identity"
}

protocol MultipeerConnectivityDelegate: AnyObject {
    func session(_ session: MCSession, didReceiveData data: Data, fromPeer peer: MCPeerID)
    func session(_ session: MCSession, didConnecToPeer peer: MCPeerID)
    func session(_ session: MCSession, didDisconnectFromPeer peer: MCPeerID)
    func session(_ session: MCSession, isConnectingToPeer peer: MCPeerID)
    func session(_ sessionL: MCSession, isInUnknownStateWithPeer peer: MCPeerID)
    func peer(_ peerID: MCPeerID, lostPeer peer: MCPeerID)
    func failedToSendData(toPeers peers: [MCPeerID], error: Error)
}

class MultipeerConnectivityManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    private let serviceString: String
    private let mcSession: MCSession
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let mcAdvertiser: MCNearbyServiceAdvertiser
    private let mcBrowser: MCNearbyServiceBrowser
    private let identityString: String
    private let maxNumPeers: Int
    var delegate: MultipeerConnectivityDelegate?

    init(service: String, identity: String, maxPeers: Int) {
        serviceString = service
        identityString = identity
        mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID,
                                                 discoveryInfo: [MPCSessionConstants.kKeyIdentity: identityString],
                                                 serviceType: serviceString)
        mcBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceString)
        maxNumPeers = maxPeers

        super.init()
        mcSession.delegate = self
        mcAdvertiser.delegate = self
        mcBrowser.delegate = self
    }

    // MARK: - `MPCSession` public methods.
    func start() {
        mcAdvertiser.startAdvertisingPeer()
        mcBrowser.startBrowsingForPeers()
    }

    func suspend() {
        mcAdvertiser.stopAdvertisingPeer()
        mcBrowser.stopBrowsingForPeers()
    }

    func invalidate() {
        suspend()
        mcSession.disconnect()
    }

    func sendDataToAllPeers(data: Data) {
        sendData(data: data, peers: mcSession.connectedPeers, mode: .reliable)
    }

    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            try mcSession.send(data, toPeers: peers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error)")
        }
    }

    // MARK: - `MCSessionDelegate`.
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
        print("MPC - \(session.myPeerID.displayName) did receive data from \(peerID.displayName)")

        Task { @MainActor in
            delegate?.session(session, didReceiveData: data, fromPeer: peerID)
        }
    }

    internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // The sample app intentional omits this implementation.
    }

    internal func session(_ session: MCSession,
                          didStartReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          with progress: Progress) {
        // The sample app intentional omits this implementation.
    }

    internal func session(_ session: MCSession,
                          didFinishReceivingResourceWithName resourceName: String,
                          fromPeer peerID: MCPeerID,
                          at localURL: URL?,
                          withError error: Error?) {
        // The sample app intentional omits this implementation.
    }

    // MARK: - `MCNearbyServiceBrowserDelegate`.
    internal func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let identityValue = info?[MPCSessionConstants.kKeyIdentity] else {
            return
        }
        if identityValue == identityString && mcSession.connectedPeers.count < maxNumPeers {
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
        }
    }

    internal func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // The sample app intentional omits this implementation.
    }

    // MARK: - `MCNearbyServiceAdvertiserDelegate`.
    internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                             didReceiveInvitationFromPeer peerID: MCPeerID,
                             withContext context: Data?,
                             invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept the invitation only if the number of peers is less than the maximum.
        if self.mcSession.connectedPeers.count < maxNumPeers {
            invitationHandler(true, mcSession)
        }
    }
}


//import MultipeerConnectivity
//
//enum MPCType {
//    case advertiser
//    case browser
//}
//
//protocol MultipeerConnectivityManagerProtocol {
//    var delegate: MultipeerConnectivityDelegate? { get set }
//
//    func start()
//    func suspend()
//    func invalidate()
//    func sendDataToAllPeers(data: Data)
//    func sendDataToPeers(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode)
//}
//
//protocol MultipeerConnectivityDelegate: AnyObject {
//    func session(_ session: MCSession, didReceiveData data: Data, fromPeer peer: MCPeerID)
//    func session(_ session: MCSession, didConnecToPeer peer: MCPeerID)
//    func session(_ session: MCSession, didDisconnectFromPeer peer: MCPeerID)
//    func session(_ session: MCSession, isConnectingToPeer peer: MCPeerID)
//    func session(_ sessionL: MCSession, isInUnknownStateWithPeer peer: MCPeerID)
//    func peer(_ peerID: MCPeerID, lostPeer peer: MCPeerID)
//    func failedToSendData(toPeers peers: [MCPeerID], error: Error)
//}
//
//class MultipeerConnectivityManager: NSObject {
//    struct MPCSessionConstants {
//        static let kKeyIdentity: String = "identity"
//    }
//
//    weak var delegate: MultipeerConnectivityDelegate?
//
//    private(set) var serviceString: String
//    private(set) var session: MCSession
//    private(set) var localPeerID: MCPeerID
//    private(set) var identityString: String
//    private var browser: MCNearbyServiceBrowser
//    private var advertiser: MCNearbyServiceAdvertiser
//    private let maxNumPeers: Int
//
//
//    init(service: String, identity: String, displayName: String, maxPeers: Int) {
//        serviceString = service
//        identityString = identity
//        localPeerID = MCPeerID(displayName: displayName)
//        session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
//
//
//        advertiser = MCNearbyServiceAdvertiser(peer: localPeerID,
//                                               discoveryInfo: [MPCSessionConstants.kKeyIdentity: identityString],
//                                               serviceType: serviceString)
//
//        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceString)
//        maxNumPeers = maxPeers
//
//        super.init()
//        self.session.delegate = self
//        self.advertiser.delegate = self
//        self.browser.delegate = self
//        print("mpc init")
//    }
//}
//
//extension MultipeerConnectivityManager: MultipeerConnectivityManagerProtocol {
//    // MARK: - `MPCSession` public methods.
//    func start() {
//        print("MPC start")
//        advertiser.startAdvertisingPeer()
//        browser.startBrowsingForPeers()
//    }
//    func suspend() {
//        print("Session is suspended.")
//        advertiser.stopAdvertisingPeer()
//        browser.stopBrowsingForPeers()
//    }
//
//    final func invalidate() {
//        suspend()
//        session.disconnect()
//        print("\(session.myPeerID.displayName) is invalidated and disconnected")
//    }
//
//    final func sendDataToAllPeers(data: Data) {
//        do {
//            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
//        } catch {
//            delegate?.failedToSendData(toPeers: session.connectedPeers, error: error)
//        }
//    }
//
//    final func sendDataToPeers(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
//        do {
//            try session.send(data, toPeers: peers, with: mode)
//        } catch {
//            delegate?.failedToSendData(toPeers: peers, error: error)
//        }
//    }
//}
//
//extension MultipeerConnectivityManager: MCSessionDelegate {
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        Task { @MainActor in
//            switch state {
//            case .connected:
//                self.delegate?.session(session, didConnecToPeer: peerID)
//                if session.connectedPeers.count == maxNumPeers {
//                    self.suspend()
//                }
//            case .notConnected:
//                self.delegate?.session(session, didDisconnectFromPeer: peerID)
//                if session.connectedPeers.count < maxNumPeers {
//                    self.start()
//                }
//            case .connecting:
//                self.delegate?.session(session, isConnectingToPeer: peerID)
//            @unknown default:
//                self.delegate?.session(session, isInUnknownStateWithPeer: peerID)
//            }
//        }
//    }
//
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        print("MPC - \(session.myPeerID.displayName) did receive data from \(peerID.displayName)")
//
//        Task { @MainActor in
//            delegate?.session(session, didReceiveData: data, fromPeer: peerID)
//        }
//    }
//
//    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//    }
//
//    func session(_ session: MCSession,
//                 didStartReceivingResourceWithName resourceName: String,
//                 fromPeer peerID: MCPeerID,
//                 with progress: Progress) {
//    }
//
//    func session(_ session: MCSession,
//                 didFinishReceivingResourceWithName resourceName: String,
//                 fromPeer peerID: MCPeerID,
//                 at localURL: URL?,
//                 withError error: Error?) {
//    }
//}
//
//extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
//    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//        print("MPC - \(browser.myPeerID.displayName) found peer \(peerID.displayName)")
//
//        guard let identityValue = info?[MPCSessionConstants.kKeyIdentity] else {
//            return
//        }
//        if identityValue == identityString {
//
//             browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
//            print("\(browser.myPeerID.displayName) found peer: \(peerID.displayName) and sent invitation")
//        }
//    }
//
//    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//        print("MPC - \(browser.myPeerID.displayName) lost peer \(peerID.displayName)")
//        delegate?.peer(browser.myPeerID, lostPeer: peerID)
//    }
//}
//
//extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
//                           didReceiveInvitationFromPeer peerID: MCPeerID,
//                           withContext context: Data?,
//                           invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//
//        print("number of connected peers: \(session.connectedPeers.count)")
//        if self.session.connectedPeers.count < maxNumPeers {
//
//            print("\(advertiser.myPeerID.displayName) received invitation from \(peerID.displayName)")
//            invitationHandler(true, session)
//        }
//    }
//}
