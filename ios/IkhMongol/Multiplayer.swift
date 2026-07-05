import MultipeerConnectivity
import UIKit

// MARK: - Сүлжээний мессежүүд

struct SnapUnit: Codable {
    var i: Int32      // netId
    var k: UInt8      // 0 цэрэг, 1 баатар, 2 цамхаг, 3 хаалга
    var t: UInt8      // баг
    var x: Float
    var y: Float
    var hp: Float
    var mh: Float     // maxHp
    var f: Int8       // харах чиглэл
    var h: Int8       // баатрын индекс (-1 = баатар биш)
    var b: Bool       // аварга эсэх
    var a: Bool       // харваач эсэх
    var s: Int8       // 0 = хостын баатар, 1 = зочны баатар, -1 = бусад
}

struct SnapProj: Codable {
    var x: Float
    var y: Float
    var t: UInt8
    var r: Float      // эргэлт
}

struct Snapshot: Codable {
    var u: [SnapUnit]
    var p: [SnapProj]
    var wave: Int
    var hostKills: Int
    var guestKills: Int
    var gHp: Float
    var gMax: Float
    var gLvl: Int
    var gXp: Float
    var gNeed: Float
    var gS1: Float
    var gS2: Float
}

enum NetMsg: Codable {
    case ready(heroIndex: Int)                 // лоббид: баатраа сонгоод бэлэн
    case start(hostHero: Int, guestHero: Int)  // хост → зочин: тулаан эхэллээ
    case input(dx: Float, dy: Float)           // зочин → хост: жойстик
    case skill(Int)                            // зочин → хост: чадвар
    case attack                                // зочин → хост: довтлох товч
    case snapshot(Snapshot)                    // хост → зочин: тоглоомын байдал
    case announce(String)                      // хост → зочин: зарлал
    case end(hostWon: Bool, hostKills: Int, guestKills: Int)
    case leave
}

// MARK: - MultipeerConnectivity менежер (ойролцоох 1v1)

protocol MultiplayerDelegate: AnyObject {
    func mpConnected(peerName: String)
    func mpDisconnected()
    func mpReceived(_ msg: NetMsg)
}

final class Multiplayer: NSObject {

    static let shared = Multiplayer()

    private let serviceType = "ikhmongol"
    private var myPeer: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    weak var delegate: MultiplayerDelegate?

    private override init() {
        // ижил нэртэй төхөөрөмжүүдийг ялгахын тулд дугаар залгана
        let suffix = String(Int.random(in: 100...999))
        let name = String(UIDevice.current.name.prefix(20)) + "#" + suffix
        myPeer = MCPeerID(displayName: name)
        super.init()
    }

    var isConnected: Bool { session?.connectedPeers.isEmpty == false }
    var peerName: String {
        let raw = session?.connectedPeers.first?.displayName ?? ""
        return String(raw.split(separator: "#").first ?? "")
    }
    /// Хоёр төхөөрөмж дээр ижил дүгнэлт гарна — нэрсийн дарааллаар хост тодорно
    var isHost: Bool {
        guard let peer = session?.connectedPeers.first else { return true }
        return myPeer.displayName < peer.displayName
    }

    func start() {
        stop()
        let s = MCSession(peer: myPeer, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        session = s

        let adv = MCNearbyServiceAdvertiser(peer: myPeer, discoveryInfo: nil, serviceType: serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv

        let br = MCNearbyServiceBrowser(peer: myPeer, serviceType: serviceType)
        br.delegate = self
        br.startBrowsingForPeers()
        browser = br
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
    }

    func send(_ msg: NetMsg, reliable: Bool = true) {
        guard let session = session, !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(msg) else { return }
        try? session.send(data, toPeers: session.connectedPeers,
                          with: reliable ? .reliable : .unreliable)
    }
}

extension Multiplayer: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connected:
                self.delegate?.mpConnected(peerName: self.peerName)
            case .notConnected:
                self.delegate?.mpDisconnected()
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let msg = try? JSONDecoder().decode(NetMsg.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.mpReceived(msg)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Foundation.Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension Multiplayer: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension Multiplayer: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        // давхар урилтаас сэргийлж зөвхөн "бага" нэртэй тал урина
        guard let session = session, myPeer.displayName < peerID.displayName else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
