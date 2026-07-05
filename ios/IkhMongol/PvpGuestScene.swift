import SpriteKit
import UIKit

/// PvP зочны тал — хостын симуляцийг зурж, оролтоо илгээнэ
final class PvpGuestScene: SKScene {

    private let myHeroIndex: Int
    private let hostHeroIndex: Int

    private let world = SKNode()
    private let hud = SKNode()
    private var worldScale: CGFloat = 1
    private var insets = UIEdgeInsets.zero
    private var built = false
    private var ended = false

    // хостын байдлаас бүтээгдэх нэгжүүд
    private var netUnits: [Int32: Unit] = [:]
    private var netTargets: [Int32: CGPoint] = [:]
    private var projNodes: [SKShapeNode] = []
    private var lastSnapshot: Snapshot?
    private var camX: CGFloat = 0
    private var lastUpdate: TimeInterval = 0
    private var inputT: CGFloat = 0
    private var matchTime: CGFloat = 0

    // оролт
    private weak var joyTouch: UITouch?
    private var joyOrigin = CGPoint.zero
    private var joyVec = CGVector.zero

    // HUD
    private let joyBase = SKShapeNode(circleOfRadius: 55)
    private let joyKnob = SKShapeNode(circleOfRadius: 24)
    private var hpFillHUD: SKSpriteNode!
    private var xpFillHUD: SKSpriteNode!
    private var lvlLabel: SKLabelNode!
    private var killLabel: SKLabelNode!
    private var announceLabel: SKLabelNode!
    private var topbar: SKNode!
    private var skillButtons: [SkillButton] = []
    private var attackButton: SKNode!
    private var exitButton: SKNode!
    private var announceQueue: [String] = []
    private var announceBusy = false

    init(size: CGSize, myHeroIndex: Int, hostHeroIndex: Int) {
        self.myHeroIndex = myHeroIndex
        self.hostHeroIndex = hostHeroIndex
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = Palette.night
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        insets = view.safeAreaInsets
        Multiplayer.shared.delegate = self

        buildBackground()
        buildHUD()
        built = true
        layout()

        announce("Тулаан эхэллээ!")
        announce("Дайсны их хаалгыг нураа!")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        if let v = view { insets = v.safeAreaInsets }
        layout()
    }

    // MARK: - Арын дэвсгэр (хөнгөн хувилбар)

    private var skySprite: SKSpriteNode?

    private func buildBackground() {
        let sky = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.17, green: 0.24, blue: 0.40, alpha: 1),
                     UIColor(red: 0.54, green: 0.42, blue: 0.29, alpha: 1),
                     UIColor(red: 0.79, green: 0.58, blue: 0.36, alpha: 1)]))
        sky.zPosition = -1000
        addChild(sky)
        skySprite = sky

        let ground = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.48, green: 0.54, blue: 0.27, alpha: 1),
                     UIColor(red: 0.30, green: 0.35, blue: 0.16, alpha: 1)]),
            size: CGSize(width: World.width, height: World.groundTop + 60))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.zPosition = -800
        world.addChild(ground)

        let lane = SKSpriteNode(color: Palette.lane, size: CGSize(width: World.width, height: 180))
        lane.anchorPoint = CGPoint(x: 0, y: 0.5)
        lane.position = CGPoint(x: 0, y: World.laneY)
        lane.zPosition = -790
        world.addChild(lane)

        world.zPosition = 0
        addChild(world)
        hud.zPosition = 1000
        addChild(hud)
    }

    // MARK: - HUD

    private func buildHUD() {
        let def = GameData.heroes[myHeroIndex]

        joyBase.strokeColor = SKColor(red: 0.94, green: 0.89, blue: 0.77, alpha: 0.35)
        joyBase.lineWidth = 2
        joyBase.fillColor = SKColor(white: 0, alpha: 0.25)
        joyBase.isHidden = true
        hud.addChild(joyBase)

        joyKnob.fillColor = Palette.gold.withAlphaComponent(0.9)
        joyKnob.strokeColor = Palette.goldDark.withAlphaComponent(0.8)
        joyKnob.lineWidth = 2
        joyBase.addChild(joyKnob)

        topbar = SKNode()
        hud.addChild(topbar)

        let portrait = SKShapeNode(circleOfRadius: 22)
        portrait.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.10, alpha: 1)
        portrait.strokeColor = Palette.gold
        portrait.lineWidth = 2
        portrait.position = CGPoint(x: 22, y: -22)
        topbar.addChild(portrait)

        let pIcon = SKLabelNode(text: def.icon)
        pIcon.fontSize = 22
        pIcon.verticalAlignmentMode = .center
        pIcon.position = portrait.position
        topbar.addChild(pIcon)

        let lvlBg = SKShapeNode(circleOfRadius: 9)
        lvlBg.fillColor = Palette.gold
        lvlBg.strokeColor = Palette.goldDark
        lvlBg.position = CGPoint(x: 38, y: -38)
        topbar.addChild(lvlBg)

        lvlLabel = UIFactory.label("1", font: Fonts.heavy, size: 11,
                                   color: SKColor(red: 0.14, green: 0.08, blue: 0.01, alpha: 1))
        lvlLabel.position = lvlBg.position
        topbar.addChild(lvlLabel)

        let nameL = UIFactory.label(def.name, font: Fonts.bold, size: 10)
        nameL.horizontalAlignmentMode = .left
        nameL.position = CGPoint(x: 52, y: -10)
        topbar.addChild(nameL)

        let hpBg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55), size: CGSize(width: 152, height: 12))
        hpBg.anchorPoint = CGPoint(x: 0, y: 0.5)
        hpBg.position = CGPoint(x: 52, y: -24)
        topbar.addChild(hpBg)

        hpFillHUD = SKSpriteNode(color: Palette.hpGreen, size: CGSize(width: 150, height: 10))
        hpFillHUD.anchorPoint = CGPoint(x: 0, y: 0.5)
        hpFillHUD.position = CGPoint(x: 53, y: -24)
        topbar.addChild(hpFillHUD)

        let xpBg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55), size: CGSize(width: 152, height: 6))
        xpBg.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpBg.position = CGPoint(x: 52, y: -35)
        topbar.addChild(xpBg)

        xpFillHUD = SKSpriteNode(color: Palette.xpBlue, size: CGSize(width: 150, height: 4))
        xpFillHUD.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpFillHUD.position = CGPoint(x: 53, y: -35)
        xpFillHUD.xScale = 0
        topbar.addChild(xpFillHUD)

        killLabel = UIFactory.label("Алалт: 0 · Давалгаа: 0", font: Fonts.demi, size: 13)
        hud.addChild(killLabel)

        announceLabel = UIFactory.label("", font: Fonts.heavy, size: 24, color: Palette.goldLight)
        announceLabel.alpha = 0
        hud.addChild(announceLabel)

        // ML-маягийн товчнууд
        attackButton = SKNode()
        let atkBg = SKShapeNode(circleOfRadius: 36)
        atkBg.fillColor = SKColor(red: 0.55, green: 0.16, blue: 0.10, alpha: 0.92)
        atkBg.strokeColor = SKColor(red: 0.91, green: 0.55, blue: 0.35, alpha: 1)
        atkBg.lineWidth = 3
        attackButton.addChild(atkBg)
        let atkIcon = SKLabelNode(text: "⚔️")
        atkIcon.fontSize = 30
        atkIcon.verticalAlignmentMode = .center
        attackButton.addChild(atkIcon)
        hud.addChild(attackButton)

        let b1 = SkillButton(skill: def.s1, radius: 26)
        let b2 = SkillButton(skill: def.s2, radius: 26)
        skillButtons = [b1, b2]
        hud.addChild(b1)
        hud.addChild(b2)

        exitButton = SKNode()
        let exitBg = SKShapeNode(circleOfRadius: 18)
        exitBg.fillColor = SKColor(white: 0, alpha: 0.4)
        exitBg.strokeColor = SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 0.7)
        exitBg.lineWidth = 1.5
        exitButton.addChild(exitBg)
        let exitIcon = SKLabelNode(text: "✕")
        exitIcon.fontName = Fonts.bold
        exitIcon.fontSize = 16
        exitIcon.fontColor = SKColor(red: 1.0, green: 0.62, blue: 0.54, alpha: 1)
        exitIcon.verticalAlignmentMode = .center
        exitButton.addChild(exitIcon)
        hud.addChild(exitButton)
    }

    private func layout() {
        worldScale = size.height / World.viewH
        world.setScale(worldScale)

        skySprite?.size = CGSize(width: size.width, height: size.height)
        skySprite?.position = CGPoint(x: size.width / 2, y: size.height / 2)

        topbar.position = CGPoint(x: 12 + insets.left, y: size.height - 8 - insets.top)
        killLabel.position = CGPoint(x: size.width / 2, y: size.height - 24 - insets.top)
        announceLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        exitButton.position = CGPoint(x: size.width - 30 - insets.right, y: size.height - 28 - insets.top)

        let ax = size.width - 58 - insets.right
        let ay = 56 + insets.bottom
        attackButton.position = CGPoint(x: ax, y: ay)
        if skillButtons.count == 2 {
            skillButtons[0].position = CGPoint(x: ax - 90, y: ay + 6)
            skillButtons[1].position = CGPoint(x: ax - 60, y: ay + 74)
        }
    }

    // MARK: - Хостын байдлыг зурах

    private func applySnapshot(_ snap: Snapshot) {
        lastSnapshot = snap
        var seen = Set<Int32>()

        for su in snap.u {
            seen.insert(su.i)
            let target = CGPoint(x: CGFloat(su.x), y: CGFloat(su.y))
            if let unit = netUnits[su.i] {
                netTargets[su.i] = target
                unit.hp = CGFloat(su.hp)
                unit.maxHp = CGFloat(su.mh)
                unit.face = CGFloat(su.f)
                unit.updateBars()
            } else {
                let unit = makeVisualUnit(su)
                unit.position = target
                netUnits[su.i] = unit
                netTargets[su.i] = target
                world.addChild(unit)
            }
        }

        // алга болсон нэгжүүд — устгаад жижиг дэлбэрэлт
        for (id, unit) in netUnits where !seen.contains(id) {
            if unit.kind != .gate {
                burstFx(at: unit.position, color: unit.team == .khwarezm ? Palette.enemyRed : Palette.gold)
            }
            unit.removeFromParent()
            netUnits.removeValue(forKey: id)
            netTargets.removeValue(forKey: id)
        }

        // сумнууд — снапшот бүрд дахин зурна
        while projNodes.count < snap.p.count {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -12, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 0))
            let node = SKShapeNode(path: path.cgPath)
            node.lineWidth = 2.5
            node.zPosition = 600
            world.addChild(node)
            projNodes.append(node)
        }
        for (i, node) in projNodes.enumerated() {
            if i < snap.p.count {
                let sp = snap.p[i]
                node.isHidden = false
                node.position = CGPoint(x: CGFloat(sp.x), y: CGFloat(sp.y))
                node.zRotation = CGFloat(sp.r)
                let color: SKColor = sp.t == 0
                    ? SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1)
                    : SKColor(red: 1.0, green: 0.69, blue: 0.63, alpha: 1)
                node.strokeColor = color
            } else {
                node.isHidden = true
            }
        }
    }

    /// Снапшотын мэдээллээс зөв дүрстэй нэгж бүтээнэ.
    /// Анхаар: зочны дэлгэцэд багууд эсрэгээр — миний баатар (s==1) "монгол" талд харагдана.
    private func makeVisualUnit(_ su: SnapUnit) -> Unit {
        // хостын khwarezm = миний тал тул өнгийг урвуулна
        let visualTeam: Team = su.t == 1 ? .mongol : .khwarezm
        let kind: UnitKind
        let radius: CGFloat
        var name = ""
        var heroDef: HeroDef? = nil

        switch su.k {
        case 1:
            kind = .hero
            radius = 20
            if su.h >= 0 && Int(su.h) < GameData.heroes.count {
                heroDef = GameData.heroes[Int(su.h)]
                name = heroDef!.name
            }
        case 2:
            kind = .tower
            radius = 34
            name = visualTeam == .mongol ? "Манай цамхаг" : "Дайсны цамхаг"
        case 3:
            kind = .gate
            radius = 52
            name = visualTeam == .mongol ? "Их хаалга" : "Дайсны хаалга"
        default:
            kind = .minion
            radius = su.b ? 26 : 15
            if su.b { name = "Аварга дайчин" }
        }

        return Unit(kind: kind, team: visualTeam, displayName: name,
                    radius: radius, hp: CGFloat(su.hp),
                    archer: su.a, boss: su.b, heroDef: heroDef)
    }

    private func burstFx(at pos: CGPoint, color: SKColor) {
        for _ in 0..<10 {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let dot = SKShapeNode(circleOfRadius: .random(in: 2...4))
            dot.fillColor = color
            dot.strokeColor = .clear
            dot.position = pos
            dot.zPosition = 750
            world.addChild(dot)
            let dur = Double.random(in: 0.35...0.6)
            dot.run(.sequence([
                .group([.moveBy(x: cosF(a) * 50, y: sinF(a) * 50, duration: dur),
                        .fadeOut(withDuration: dur)]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Шинэчлэл

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime }
        let dt = CGFloat(min(currentTime - lastUpdate, 0.05))
        lastUpdate = currentTime
        guard built, !ended, dt > 0 else { return }
        matchTime += dt

        // оролтоо хостод илгээх (~16 удаа/сек)
        inputT -= dt
        if inputT <= 0 {
            inputT = 0.06
            Multiplayer.shared.send(.input(dx: Float(joyVec.dx), dy: Float(joyVec.dy)),
                                    reliable: false)
        }

        // байрлалын зөөлөн интерполяци
        for (id, unit) in netUnits {
            guard let target = netTargets[id] else { continue }
            let k = min(1, dt * 12)
            unit.position = CGPoint(x: unit.position.x + (target.x - unit.position.x) * k,
                                    y: unit.position.y + (target.y - unit.position.y) * k)
            if unit.kind == .minion || unit.kind == .hero {
                unit.zPosition = 500 - unit.position.y
            }
        }

        // камер миний баатрыг дагана
        if let me = myUnit() {
            let viewWWorld = size.width / worldScale
            let target = clampF(me.position.x - viewWWorld / 2, 0, max(0, World.width - viewWWorld))
            camX += (target - camX) * min(1, dt * 6)
            world.position = CGPoint(x: -camX * worldScale, y: 0)
        }

        processAnnouncements()
        updateHUD()
    }

    /// Миний баатар — снапшотод s == 1 гэж тэмдэглэгдсэн нэгж
    private func myUnit() -> Unit? {
        guard let snap = lastSnapshot else { return nil }
        guard let su = snap.u.first(where: { $0.s == 1 }) else { return nil }
        return netUnits[su.i]
    }

    private func updateHUD() {
        guard let snap = lastSnapshot else { return }
        hpFillHUD.xScale = snap.gMax > 0 ? clampF(CGFloat(snap.gHp / snap.gMax), 0, 1) : 0
        xpFillHUD.xScale = snap.gNeed > 0 ? clampF(CGFloat(snap.gXp / snap.gNeed), 0, 1) : 0
        lvlLabel.text = "\(snap.gLvl)"
        killLabel.text = "Алалт: \(snap.guestKills) · Давалгаа: \(snap.wave)"
        if skillButtons.count == 2 {
            skillButtons[0].setCooldown(CGFloat(snap.gS1))
            skillButtons[1].setCooldown(CGFloat(snap.gS2))
        }
    }

    private func announce(_ text: String) {
        announceQueue.append(text)
    }

    private func processAnnouncements() {
        guard !announceBusy, !announceQueue.isEmpty else { return }
        announceBusy = true
        announceLabel.text = announceQueue.removeFirst()
        announceLabel.alpha = 0
        announceLabel.run(.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: 1.8),
            .fadeOut(withDuration: 0.4),
            .run { [weak self] in self?.announceBusy = false }
        ]))
    }

    // MARK: - Оролт

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)

            if p.distance(to: exitButton.position) <= 26 {
                exitToMenu(sendLeave: true)
                return
            }
            if p.distance(to: attackButton.position) <= 44 {
                Multiplayer.shared.send(.attack)
                attackButton.run(.sequence([.scale(to: 0.88, duration: 0.05),
                                            .scale(to: 1.0, duration: 0.08)]))
                Haptics.hit()
                continue
            }
            var handled = false
            for (i, b) in skillButtons.enumerated() {
                if p.distance(to: b.position) <= b.btnRadius + 10 {
                    Multiplayer.shared.send(.skill(i))
                    Haptics.skill()
                    handled = true
                    break
                }
            }
            if handled { continue }

            if joyTouch == nil && p.x < size.width * 0.55 {
                joyTouch = t
                joyOrigin = p
                joyBase.position = p
                joyBase.isHidden = false
                joyKnob.position = .zero
                joyVec = .zero
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches where t === joyTouch {
            let p = t.location(in: self)
            var dx = p.x - joyOrigin.x
            var dy = p.y - joyOrigin.y
            let d = vecLen(dx, dy)
            let maxR: CGFloat = 48
            if d > maxR {
                dx = dx / d * maxR
                dy = dy / d * maxR
            }
            joyKnob.position = CGPoint(x: dx, y: dy)
            joyVec = CGVector(dx: dx / maxR, dy: dy / maxR)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches where t === joyTouch {
            joyTouch = nil
            joyVec = .zero
            joyBase.isHidden = true
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func exitToMenu(sendLeave: Bool) {
        if sendLeave { Multiplayer.shared.send(.leave) }
        Multiplayer.shared.stop()
        Audio.shared.play("tap")
        guard let view = view else { return }
        let menu = MenuScene(size: size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .fade(withDuration: 0.4))
    }

    private func finish(win: Bool, kills: Int) {
        guard !ended else { return }
        ended = true
        if win { Haptics.victory() } else { Haptics.defeat() }
        Audio.shared.play(win ? "win" : "lose", volume: 0.9)

        let earned = win ? 100 : 30
        Progress.gold += earned
        Progress.recordMatch(win: win)
        let heroId = GameData.heroes[myHeroIndex].id
        var gainedStar = false
        if win && Progress.mastery(heroId) < 5 {
            Progress.addMasteryStar(heroId)
            gainedStar = true
        }
        let stats = MatchStats(win: win, kills: kills,
                               level: lastSnapshot.map { $0.gLvl } ?? 1,
                               seconds: Int(matchTime), heroIndex: myHeroIndex,
                               difficultyIndex: 1,
                               goldEarned: earned, totalGold: Progress.gold,
                               masteryStars: Progress.mastery(heroId), gainedStar: gainedStar,
                               newChapter: nil, isPvp: true)
        run(.sequence([
            .wait(forDuration: 0.9),
            .run { [weak self] in
                guard let self = self, let view = self.view else { return }
                Multiplayer.shared.stop()
                let end = EndScene(size: self.size, stats: stats)
                end.scaleMode = .resizeFill
                view.presentScene(end, transition: .fade(withDuration: 0.8))
            }
        ]))
    }
}

// MARK: - Сүлжээний мессежүүд (зочин)

extension PvpGuestScene: MultiplayerDelegate {
    func mpConnected(peerName: String) {}

    func mpDisconnected() {
        guard !ended else { return }
        announce("Найз тоглоомоос гарлаа")
        finish(win: true, kills: lastSnapshot?.guestKills ?? 0)
    }

    func mpReceived(_ msg: NetMsg) {
        switch msg {
        case .snapshot(let snap):
            applySnapshot(snap)
        case .announce(let text):
            announce(text)
        case .end(let hostWon, _, let guestKills):
            finish(win: !hostWon, kills: guestKills)
        case .leave:
            mpDisconnected()
        default:
            break
        }
    }
}
