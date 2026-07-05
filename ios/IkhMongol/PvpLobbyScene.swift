import SpriteKit

/// Найзтайгаа тоглох — ойролцоох төхөөрөмж хайж, баатраа сонгоод 1v1 тулалдана
final class PvpLobbyScene: SKScene {

    private var built = false
    private var content: SKNode?

    private var connected = false
    private var peerName = ""
    private var selHero = 0
    private var selfReady = false
    private var remoteHero: Int?
    private var starting = false

    private var statusLabel: SKLabelNode?
    private var cardNodes: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        Multiplayer.shared.delegate = self
        Multiplayer.shared.start()
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

        let status = UIFactory.label(
            connected ? "Холбогдлоо: \(peerName)" : "🔍 Ойролцоох найзыг хайж байна...",
            font: Fonts.demi, size: 13,
            color: connected
                ? SKColor(red: 0.56, green: 0.85, blue: 0.52, alpha: 1)
                : SKColor(red: 0.72, green: 0.64, blue: 0.49, alpha: 1))
        status.position = CGPoint(x: cx, y: size.height - 56)
        c.addChild(status)
        statusLabel = status

        if connected {
            // баатрын сонголт — PvP-д бүх баатар нээлттэй
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

    private func maybeStart() {
        guard !starting, selfReady, let remote = remoteHero else { return }
        starting = true
        if Multiplayer.shared.isHost {
            Multiplayer.shared.send(.start(hostHero: selHero, guestHero: remote))
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        guard let name = UIFactory.nodeName(at: t.location(in: self), in: self) else { return }

        if name == "back", let view = view {
            Multiplayer.shared.stop()
            Audio.shared.play("tap")
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view.presentScene(menu, transition: .fade(withDuration: 0.35))
            return
        }
        if name == "ready" && connected && !selfReady {
            selfReady = true
            Multiplayer.shared.send(.ready(heroIndex: selHero))
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

extension PvpLobbyScene: MultiplayerDelegate {
    func mpConnected(peerName name: String) {
        connected = true
        peerName = name
        Haptics.levelUp()
        Audio.shared.play("level", volume: 0.6)
        buildUI()
    }

    func mpDisconnected() {
        connected = false
        peerName = ""
        selfReady = false
        remoteHero = nil
        starting = false
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
