import MultipeerConnectivity

public enum MPCType {
    case advertiser
    case browser
}

protocol MultipeerConnectivityManagerProtocol {
    func start()
    func suspend()
    func invalidate()
    func sendDataToAllPeers(data: Data)
    func sendDataToPeers(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode)
}

protocol MultipeerConnectivityDelegate: AnyObject {
    func sessionDidReceiveData(_ data: Data, fromPeer peer: MCPeerID)
    func sessionDidConnect(toPeer peer: MCPeerID)
    func sessionDidDisconnect(formPeer peer: MCPeerID)
    func sessionIsConnecting(toPeer peer: MCPeerID)
    func sessionIsInUnknownState(toPeer peer: MCPeerID)
    func failedToSendData(toPeers peers: [MCPeerID], error: Error)
    func sessionLostPeer(_ peer: MCPeerID)
}

class MultipeerConnectivityManager: NSObject {
    struct MPCSessionConstants {
        static let kKeyIdentity: String = "identity"
    }
    
    public private(set) var serviceString: String
    public private(set) var session: MCSession
    public private(set) var localPeerID: MCPeerID
    public private(set) var identityString: String
    
    private weak var delegate: MultipeerConnectivityDelegate?

    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?


    public init(service: String, identity: String, displayName: String) {
        serviceString = service
        identityString = identity
        localPeerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        

        
        super.init()
        self.session.delegate = self
        self.advertiser?.delegate = self
        self.browser?.delegate = self
    }
}

extension MultipeerConnectivityManager: MultipeerConnectivityManagerProtocol {
    // MARK: - `MPCSession` public methods.
    func start() {
        advertiser?.startAdvertisingPeer()
        browser?.startBrowsingForPeers()
    }
    func suspend() {
        advertiser?.startAdvertisingPeer()
        browser?.stopBrowsingForPeers()
    }
    
    final func invalidate() {
        suspend()
        session.disconnect()
    }
    
    final func sendDataToAllPeers(data: Data) {
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            delegate?.failedToSendData(toPeers: session.connectedPeers, error: error)
        }
    }
    
    final func sendDataToPeers(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            try session.send(data, toPeers: peers, with: mode)
        } catch {
            delegate?.failedToSendData(toPeers: peers, error: error)
        }
    }
}

extension MultipeerConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.delegate?.sessionDidConnect(toPeer: peerID)
            case .notConnected:
                self.delegate?.sessionDidDisconnect(formPeer: peerID)
            case .connecting:
                self.delegate?.sessionIsConnecting(toPeer: peerID)
            @unknown default:
                self.delegate?.sessionIsInUnknownState(toPeer: peerID)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            delegate?.sessionDidReceiveData(data, fromPeer: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
    }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
    }
}

extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let identityValue = info?[MPCSessionConstants.kKeyIdentity] else {
            return
        }
        if identityValue == identityString {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        delegate?.sessionLostPeer(peerID)
    }
}

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didReceiveInvitationFromPeer peerID: MCPeerID,
                           withContext context: Data?,
                           invitationHandler: @escaping (Bool, MCSession?) -> Void) {

            invitationHandler(true, session)
    }
}
