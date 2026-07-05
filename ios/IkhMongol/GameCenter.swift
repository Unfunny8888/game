import GameKit
import UIKit

/// Game Center онлайн 1v1 — интернэтээр таарц хайж, GKMatch-аар мессеж дамжуулна
final class GameCenterLink: NSObject, NetLink {

    weak var delegate: MultiplayerDelegate?
    private var match: GKMatch?
    private var announcedConnection = false

    var peerName: String { match?.players.first?.displayName ?? "" }

    /// Хоёр төхөөрөмж дээр ижил дүгнэлт — тоглогчийн ID-гийн дарааллаар хост тодорно
    var isHost: Bool {
        guard let remote = match?.players.first else { return true }
        return GKLocalPlayer.local.gamePlayerID < remote.gamePlayerID
    }

    // MARK: - Нэвтрэлт

    static var isAuthenticated: Bool { GKLocalPlayer.local.isAuthenticated }

    /// Game Center-т нэвтэрнэ; шаардлагатай бол нэвтрэх дэлгэц гаргана
    static func authenticate(presenter: UIViewController?,
                             completion: @escaping (Bool) -> Void) {
        if GKLocalPlayer.local.isAuthenticated {
            completion(true)
            return
        }
        var done = false
        GKLocalPlayer.local.authenticateHandler = { vc, _ in
            DispatchQueue.main.async {
                if let vc = vc {
                    presenter?.present(vc, animated: true)
                    return
                }
                guard !done else { return }
                done = true
                completion(GKLocalPlayer.local.isAuthenticated)
            }
        }
    }

    // MARK: - Таарц хайх

    func findMatch(presenter: UIViewController) {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        guard let vc = GKMatchmakerViewController(matchRequest: request) else { return }
        vc.matchmakerDelegate = self
        presenter.present(vc, animated: true)
    }

    // MARK: - NetLink

    func send(_ msg: NetMsg, reliable: Bool) {
        guard let match = match, !match.players.isEmpty,
              let data = try? JSONEncoder().encode(msg) else { return }
        // GKMatch-ийн unreliable горим нь жижиг мессежид зориулагдсан —
        // том снапшотуудыг найдвартай сувгаар явуулна
        let mode: GKMatch.SendDataMode = (reliable || data.count > 900) ? .reliable : .unreliable
        try? match.send(data, to: match.players, dataMode: mode)
    }

    func stop() {
        match?.disconnect()
        match?.delegate = nil
        match = nil
        announcedConnection = false
    }
}

// MARK: - Таарц хайгчийн дэлгэц

extension GameCenterLink: GKMatchmakerViewControllerDelegate {

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        delegate?.mpDisconnected()
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        delegate?.mpDisconnected()
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        self.match = match
        match.delegate = self
        if match.expectedPlayerCount == 0 && !announcedConnection {
            announcedConnection = true
            delegate?.mpConnected(peerName: peerName)
        }
    }
}

// MARK: - Тоглолтын мессежүүд

extension GameCenterLink: GKMatchDelegate {

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let msg = try? JSONDecoder().decode(NetMsg.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.mpReceived(msg)
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connected:
                if match.expectedPlayerCount == 0 && !self.announcedConnection {
                    self.announcedConnection = true
                    self.delegate?.mpConnected(peerName: player.displayName)
                }
            case .disconnected:
                self.delegate?.mpDisconnected()
            default:
                break
            }
        }
    }
}
