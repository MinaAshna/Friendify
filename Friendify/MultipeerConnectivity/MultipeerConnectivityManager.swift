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

protocol MultipeerConnectivityProtocol {
    var myPeerID: MCPeerID { get }
    
    func start()
    func suspend()
    func invalidate()
    func sendDataToAllPeers(data: Data)
    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode)
}

class MultipeerConnectivityManager: NSObject {
    private let serviceString: String
    private let localPeerID: MCPeerID
    let mcSession: MCSession
    let mcAdvertiser: MCNearbyServiceAdvertiser
    let mcBrowser: MCNearbyServiceBrowser
    let identityString: String
    let maxNumPeers: Int
    var delegate: MultipeerConnectivityDelegate?
    var myPeerID: MCPeerID

    init(service: String, identity: String, peerID: String, maxPeers: Int) {
        serviceString = service
        identityString = identity
        localPeerID = MCPeerID(displayName: peerID)
        mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID,
                                                 discoveryInfo: [MPCSessionConstants.kKeyIdentity: identityString],
                                                 serviceType: serviceString)
        mcBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceString)
        maxNumPeers = maxPeers
        myPeerID = localPeerID
        
        super.init()
        mcSession.delegate = self
        mcAdvertiser.delegate = self
        mcBrowser.delegate = self
    }
    
}

extension MultipeerConnectivityManager: MultipeerConnectivityProtocol {
    
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
    
}
