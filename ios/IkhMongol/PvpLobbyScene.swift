import SpriteKit
import UIKit

/// Найзтайгаа тоглох — ойролцоо (Wi-Fi) эсвэл онлайн (Game Center) 1v1
final class PvpLobbyScene: SKScene {

    private enum Stage {
        case chooseMode   // ойролцоо / онлайн сонгох
        case searching    // хамтрагч хайж байна
        case connected    // баатар сонгож, бэлэн болох
    }

    private var stage: Stage = .chooseMode
    private var built = false
    private var content: SKNode?

    private var peerName = ""
    private var selHero = 0
    private var selfReady = false
    private var remoteHero: Int?
    private var starting = false

    private var cardNodes: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        buildUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        buildUI()
    }

    private func buildUI() {
        content?.removeFromParent()
        cardNodes = []
        let c = SKNode()
        content = c
        addChild(c)

        let bg = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1),
                     UIColor(red: 0.08, green: 0.05, blue: 0.03, alpha: 1)]),
            size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        c.addChild(bg)

        let cx = size.width / 2

        let title = UIFactory.label("🤝 НАЙЗТАЙГАА ТОГЛОХ", font: Fonts.heavy, size: 20, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 30)
        c.addChild(title)

        switch stage {
        case .chooseMode:
            let info = UIFactory.multiline(
                "Ойролцоо: хоёр утас нэг Wi-Fi сүлжээнд эсвэл Bluetooth-ээр ойрхон байх ёстой.\nОнлайн: Game Center-ээр интернэтийн хаанаас ч таарц хайна.",
                font: Fonts.demi, size: 11,
                color: SKColor(red: 0.72, green: 0.64, blue: 0.49, alpha: 1),
                width: size.width * 0.8)
            info.position = CGPoint(x: cx, y: size.height * 0.68)
            c.addChild(info)

            let nearby = UIFactory.button(text: "📶 ОЙРОЛЦОО", name: "nearby", width: 250, height: 52)
            nearby.position = CGPoint(x: cx - 140, y: size.height * 0.40)
            c.addChild(nearby)

            let online = UIFactory.button(text: "🌐 ОНЛАЙН", name: "online", width: 250, height: 52)
            online.position = CGPoint(x: cx + 140, y: size.height * 0.40)
            c.addChild(online)

        case .searching:
            let status = UIFactory.label("🔍 Хамтрагч хайж байна...", font: Fonts.demi, size: 14,
                                         color: SKColor(red: 0.72, green: 0.64, blue: 0.49, alpha: 1))
            status.position = CGPoint(x: cx, y: size.height * 0.55)
            c.addChild(status)
            status.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 0.7),
                .fadeAlpha(to: 1.0, duration: 0.7)
            ])))

        case .connected:
            let status = UIFactory.label("Холбогдлоо: \(peerName)", font: Fonts.demi, size: 13,
                                         color: SKColor(red: 0.56, green: 0.85, blue: 0.52, alpha: 1))
            status.position = CGPoint(x: cx, y: size.height - 56)
            c.addChild(status)

            let note = UIFactory.label("PvP-д бүх баатар нээлттэй · Мастерийн нэмэгдэл үйлчлэхгүй",
                                       font: Fonts.demi, size: 10,
                                       color: SKColor(red: 0.54, green: 0.46, blue: 0.31, alpha: 1))
            note.position = CGPoint(x: cx, y: size.height - 76)
            c.addChild(note)

            let cardR: CGFloat = min(34, size.width / 22)
            let gap: CGFloat = 18
            let totalW = CGFloat(GameData.heroes.count) * (cardR * 2 + gap) - gap
            let startX = cx - totalW / 2 + cardR

            for (i, hero) in GameData.heroes.enumerated() {
                let card = SKShapeNode(circleOfRadius: cardR)
                card.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.10, alpha: 1)
                card.strokeColor = SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
                card.lineWidth = 2
                card.name = "hero\(i)"
                card.position = CGPoint(x: startX + CGFloat(i) * (cardR * 2 + gap), y: size.height * 0.55)
                c.addChild(card)
                cardNodes.append(card)

                let icon = SKLabelNode(text: hero.icon)
                icon.fontSize = cardR * 0.9
                icon.verticalAlignmentMode = .center
                icon.position = card.position
                icon.name = card.name
                c.addChild(icon)

                let nameL = UIFactory.label(hero.name.components(separatedBy: " ").first ?? hero.name,
                                            font: Fonts.demi, size: 9,
                                            color: SKColor(red: 0.72, green: 0.64, blue: 0.49, alpha: 1))
                nameL.position = CGPoint(x: card.position.x, y: card.position.y - cardR - 14)
                c.addChild(nameL)
            }

            let readyText = selfReady
                ? (remoteHero == nil ? "Найзыг хүлээж байна..." : "Эхэлж байна...")
                : "БЭЛЭН!"
            let ready = UIFactory.button(text: readyText, name: selfReady ? "" : "ready",
                                         width: 240, height: 48)
            ready.alpha = selfReady ? 0.6 : 1
            ready.position = CGPoint(x: cx, y: size.height * 0.24)
            c.addChild(ready)
        }

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 160, height: 40, primary: false)
        back.position = CGPoint(x: cx, y: max(26, size.height * 0.08))
        c.addChild(back)

        refreshSelection()
    }

    private func refreshSelection() {
        for (i, card) in cardNodes.enumerated() {
            card.strokeColor = i == selHero
                ? Palette.goldLight
                : SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
            card.lineWidth = i == selHero ? 3.5 : 2
            card.setScale(i == selHero ? 1.12 : 1.0)
        }
    }

    // MARK: - Холболтын горимууд

    private func startNearby() {
        let link = Multiplayer.shared
        link.delegate = self
        NetHub.current = link
        link.start()
        stage = .searching
        buildUI()
    }

    private func startOnline() {
        guard let rootVC = view?.window?.rootViewController else { return }
        stage = .searching
        buildUI()
        GameCenterLink.authenticate(presenter: rootVC) { [weak self] ok in
            guard let self = self else { return }
            guard ok else {
                self.stage = .chooseMode
                self.buildUI()
                return
            }
            let link = GameCenterLink()
            link.delegate = self
            NetHub.current = link
            link.findMatch(presenter: rootVC)
        }
    }

    private func maybeStart() {
        guard !starting, selfReady, let remote = remoteHero,
              let link = NetHub.current else { return }
        starting = true
        if link.isHost {
            link.send(.start(hostHero: selHero, guestHero: remote), reliable: true)
            beginBattle(asHost: true, myHero: selHero, otherHero: remote)
        }
        // зочин .start мессеж хүлээнэ
    }

    private func beginBattle(asHost: Bool, myHero: Int, otherHero: Int) {
        guard let view = view else { return }
        Audio.shared.play("skill", volume: 0.7)
        if asHost {
            let battle = BattleScene(size: size, heroIndex: myHero,
                                     difficultyIndex: 1, pvpRemoteHero: otherHero)
            view.presentScene(battle, transition: .fade(withDuration: 0.6))
        } else {
            let battle = PvpGuestScene(size: size, myHeroIndex: myHero, hostHeroIndex: otherHero)
            view.presentScene(battle, transition: .fade(withDuration: 0.6))
        }
    }

    // MARK: - Оролт

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        guard let name = UIFactory.nodeName(at: t.location(in: self), in: self) else { return }

        if name == "back", let view = view {
            NetHub.current?.stop()
            NetHub.current = nil
            Audio.shared.play("tap")
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view.presentScene(menu, transition: .fade(withDuration: 0.35))
            return
        }
        switch stage {
        case .chooseMode:
            if name == "nearby" { Audio.shared.play("tap"); startNearby() }
            if name == "online" { Audio.shared.play("tap"); startOnline() }
        case .searching:
            break
        case .connected:
            if name == "ready" && !selfReady {
                selfReady = true
                NetHub.current?.send(.ready(heroIndex: selHero), reliable: true)
                Audio.shared.play("tap")
                buildUI()
                maybeStart()
                return
            }
            if !selfReady {
                for i in 0..<GameData.heroes.count where name == "hero\(i)" {
                    selHero = i
                    Audio.shared.play("tap")
                    Haptics.hit()
                    refreshSelection()
                    return
                }
            }
        }
    }
}

extension PvpLobbyScene: MultiplayerDelegate {

    func mpConnected(peerName name: String) {
        stage = .connected
        peerName = name
        Haptics.levelUp()
        Audio.shared.play("level", volume: 0.6)
        buildUI()
    }

    func mpDisconnected() {
        stage = .chooseMode
        peerName = ""
        selfReady = false
        remoteHero = nil
        starting = false
        NetHub.current?.stop()
        NetHub.current = nil
        buildUI()
    }

    func mpReceived(_ msg: NetMsg) {
        switch msg {
        case .ready(let heroIndex):
            remoteHero = heroIndex
            maybeStart()
        case .start(let hostHero, let guestHero):
            // зочин талд ирнэ — хост нь hostHero-той
            guard !starting else { return }
            starting = true
            beginBattle(asHost: false, myHero: guestHero, otherHero: hostHero)
        default:
            break
        }
    }
}
