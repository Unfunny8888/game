import SpriteKit
import UIKit

// MARK: - Сум

final class Projectile {
    let node: SKShapeNode
    weak var target: Unit?
    var velocity = CGVector.zero
    let pierce: Bool
    let dmg: CGFloat
    let team: Team
    weak var owner: Unit?
    var life: CGFloat
    var hitSet = Set<Unit>()

    init(from: CGPoint, dmg: CGFloat, team: Team, owner: Unit?, pierce: Bool, life: CGFloat, big: Bool = false) {
        self.dmg = dmg
        self.team = team
        self.owner = owner
        self.pierce = pierce
        self.life = life

        let path = UIBezierPath()
        path.move(to: CGPoint(x: -12, y: 0))
        path.addLine(to: CGPoint(x: 8, y: 0))
        path.move(to: CGPoint(x: 10, y: 0))
        path.addLine(to: CGPoint(x: 4, y: -4))
        path.addLine(to: CGPoint(x: 4, y: 4))
        path.close()

        node = SKShapeNode(path: path.cgPath)
        let color: SKColor = team == .mongol
            ? SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1)
            : SKColor(red: 1.0, green: 0.69, blue: 0.63, alpha: 1)
        node.strokeColor = color
        node.fillColor = color
        node.lineWidth = big ? 4 : 2.5
        node.position = from
        node.zPosition = 600
    }
}

// MARK: - Талбайн цохилт (сумны бороо)

final class Zone {
    let center: CGPoint
    let r: CGFloat
    var delay: CGFloat
    let dmg: CGFloat
    let team: Team
    weak var owner: Unit?
    let node: SKShapeNode

    init(center: CGPoint, r: CGFloat, delay: CGFloat, dmg: CGFloat, team: Team, owner: Unit?) {
        self.center = center
        self.r = r
        self.delay = delay
        self.dmg = dmg
        self.team = team
        self.owner = owner

        let rect = CGRect(x: -r, y: -r * 0.5, width: r * 2, height: r)
        node = SKShapeNode(path: UIBezierPath(ovalIn: rect).cgPath)
        node.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.47, alpha: 0.85)
        node.lineWidth = 3
        node.fillColor = SKColor(red: 1.0, green: 0.86, blue: 0.47, alpha: 0.12)
        node.position = center
        node.zPosition = 10
    }
}

// MARK: - Чадварын товч

final class SkillButton: SKNode {
    private let cdOverlay: SKShapeNode
    private let cdLabel: SKLabelNode
    let btnRadius: CGFloat

    init(skill: SkillDef, radius: CGFloat) {
        btnRadius = radius
        cdOverlay = SKShapeNode(circleOfRadius: radius - 2)
        cdLabel = SKLabelNode(text: "")
        super.init()

        let bg = SKShapeNode(circleOfRadius: radius)
        bg.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.10, alpha: 0.92)
        bg.strokeColor = SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
        bg.lineWidth = 2.5
        addChild(bg)

        let icon = SKLabelNode(text: skill.icon)
        icon.fontSize = radius * 0.62
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: radius * 0.22)
        addChild(icon)

        let nameL = SKLabelNode(text: skill.short)
        nameL.fontName = Fonts.bold
        nameL.fontSize = radius * 0.30
        nameL.fontColor = Palette.parchment
        nameL.verticalAlignmentMode = .center
        nameL.position = CGPoint(x: 0, y: -radius * 0.42)
        addChild(nameL)

        cdOverlay.fillColor = SKColor(white: 0, alpha: 0.68)
        cdOverlay.strokeColor = .clear
        cdOverlay.isHidden = true
        addChild(cdOverlay)

        cdLabel.fontName = Fonts.heavy
        cdLabel.fontSize = radius * 0.6
        cdLabel.fontColor = .white
        cdLabel.verticalAlignmentMode = .center
        cdLabel.isHidden = true
        addChild(cdLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func setCooldown(_ remaining: CGFloat) {
        let active = remaining > 0
        cdOverlay.isHidden = !active
        cdLabel.isHidden = !active
        if active { cdLabel.text = "\(Int(remaining.rounded(.up)))" }
    }
}

// MARK: - Тулааны гол үзэгдэл

/// Хойшлуулсан цохилт (Боорчийн шуурхай цохилтод)
private struct DelayedStrike {
    var t: CGFloat
    weak var target: Unit?
    let dmg: CGFloat
    weak var from: Unit?
}

final class BattleScene: SKScene {

    private let heroIndex: Int
    private let difficultyIndex: Int
    private var diff: DifficultyDef { GameData.difficulties[difficultyIndex] }

    // давхаргууд
    private let world = SKNode()
    private let hud = SKNode()
    private var skySprite: SKSpriteNode?
    private var sunNode: SKNode?
    private var farHills: SKShapeNode?
    private var nearHills: SKShapeNode?
    private let cloudLayer = SKNode()

    // нэгжүүд
    private var units: [Unit] = []
    private var projectiles: [Projectile] = []
    private var zones: [Zone] = []
    private var strikes: [DelayedStrike] = []
    private var player: Unit!
    private var aiHero: Unit!
    private var pGate: Unit!
    private var eGate: Unit!

    // PvP (ойролцоох 1v1) — nil бол ганцаарчилсан горим
    private let pvpRemoteHero: Int?
    private var isPvp: Bool { pvpRemoteHero != nil }
    private var remoteJoy = CGVector.zero
    private var snapshotT: CGFloat = 0
    private var guestKills = 0
    private var nextNetId: Int32 = 1

    // байдал
    private var camX: CGFloat = 0
    private var lastUpdate: TimeInterval = 0
    private var waveNum = 0
    private var nextWave: CGFloat = 2.5
    private var kills = 0
    private var matchTime: CGFloat = 0
    private var matchGold = 0
    private var combo = 0
    private var comboT: CGFloat = 0
    private var shakeT: CGFloat = 0
    private var ended = false
    private var built = false
    private var worldScale: CGFloat = 1
    private var insets = UIEdgeInsets.zero

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
    private var respawnDim: SKSpriteNode!
    private var respawnLabel: SKLabelNode!
    private var muteButton: SKNode!
    private var muteIcon: SKLabelNode!
    private var attackButton: SKNode!
    private var exitButton: SKNode!
    private var lowHpFrame: SKShapeNode!
    private var attackHeld = false
    private weak var attackTouch: UITouch?
    private var announceQueue: [String] = []
    private var announceBusy = false

    private let hpBarW: CGFloat = 150

    // MARK: - Инициализаци

    private let campaignLevel: Int?
    private var isCampaign: Bool { campaignLevel != nil }
    private var camp: CampaignLevel? { campaignLevel.map { GameData.campaign[$0] } }

    // Аяны даалгаврын байдал
    private var objective: Objective?
    private var objDone = false
    private var pendingEvents: [CampaignEvent] = []
    private var commanderKills = 0
    private var surviveT: CGFloat = 0
    private var escapeZone: SKShapeNode?
    private var escapePos = CGPoint.zero
    private var pickups: [SKNode] = []        // цуглуулах морьд
    private var rescuee: Unit?
    private var rescueeFreed = false
    private var objBanner: SKLabelNode?
    private var objBannerBg: SKShapeNode?

    // Даалгаврын замын заагч (WoW/GTA маягийн зорилгын сум)
    private var questMarker: SKNode?
    private var questDiamond: SKShapeNode?
    private var questArrow: SKShapeNode?
    private var questLabel: SKLabelNode?
    private var questLabelBg: SKShapeNode?

    // Дайсны хүчний үржүүлэгчид — аян дайн эсвэл сонгосон хүндрэлээс
    private var effMinionHp: CGFloat { camp?.minionMul ?? diff.minionHp }
    private var effMinionDmg: CGFloat { camp?.minionMul ?? diff.minionDmg }
    private var effHeroHp: CGFloat { camp?.heroMul ?? diff.heroHp }
    private var effHeroDmg: CGFloat { camp?.heroMul ?? diff.heroDmg }
    private var enemyHeroName: String { camp?.enemyName ?? GameData.jalal.name }
    private var goldMult: CGFloat { isCampaign ? 1 : diff.goldMult }

    init(size: CGSize, heroIndex: Int, difficultyIndex: Int,
         pvpRemoteHero: Int? = nil, campaignLevel: Int? = nil) {
        self.heroIndex = heroIndex
        self.difficultyIndex = min(max(difficultyIndex, 0), GameData.difficulties.count - 1)
        self.pvpRemoteHero = pvpRemoteHero
        self.campaignLevel = campaignLevel
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = Palette.night
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        insets = view.safeAreaInsets

        buildBackground()
        buildWorld()
        buildHUD()
        built = true
        layout()

        Audio.shared.preload()
        Audio.shared.startMusic()

        if isPvp { NetHub.current?.delegate = self }

        if let level = campaignLevel {
            let L = GameData.campaign[level]
            setupObjective(L.objective)
            setupCamps(level: level)                 // задгай талбарын дайсны бууц
            setupWarband(level: level)               // нөхдийн отряд (co-op мэдрэмж)
            pendingEvents = L.events
            Audio.shared.play("horn", volume: 0.7)   // дайны эвэр бүрээ — аян эхлэв
            announce("\(level + 1)-р түвшин: \(L.title)")
            announce("🎯 \(L.objective.label)")
        } else {
            announce("Тулаан эхэллээ!")
            announce("Дайсны их хаалгыг нураа!")
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        if let v = view { insets = v.safeAreaInsets }
        layout()
    }

    // MARK: - Арын дэвсгэр

    private func buildBackground() {
        let desert = (camp?.theme ?? .steppe) == .khwarezm
        let skyColors: [UIColor] = desert
            ? [UIColor(red: 0.23, green: 0.19, blue: 0.31, alpha: 1),
               UIColor(red: 0.54, green: 0.35, blue: 0.28, alpha: 1),
               UIColor(red: 0.84, green: 0.60, blue: 0.35, alpha: 1),
               UIColor(red: 0.94, green: 0.78, blue: 0.50, alpha: 1)]
            : [UIColor(red: 0.13, green: 0.20, blue: 0.37, alpha: 1),
               UIColor(red: 0.29, green: 0.42, blue: 0.60, alpha: 1),
               UIColor(red: 0.79, green: 0.65, blue: 0.42, alpha: 1),
               UIColor(red: 0.90, green: 0.75, blue: 0.53, alpha: 1)]
        let sky = SKSpriteNode(texture: Tex.linearGradient(size: CGSize(width: 8, height: 160), colors: skyColors))
        sky.zPosition = -1000
        addChild(sky)
        skySprite = sky

        // нар + гэрлэн туяа
        let sunTint = desert ? SKColor(red: 1.0, green: 0.82, blue: 0.51, alpha: 1)
                             : SKColor(red: 1.0, green: 0.88, blue: 0.59, alpha: 1)
        let sun = SKNode()
        let glow = SKShapeNode(circleOfRadius: 90)
        glow.fillColor = sunTint.withAlphaComponent(0.22)
        glow.strokeColor = .clear
        sun.addChild(glow)
        let halo = SKShapeNode(circleOfRadius: 54)
        halo.fillColor = sunTint.withAlphaComponent(0.32)
        halo.strokeColor = .clear
        sun.addChild(halo)
        let core = SKShapeNode(circleOfRadius: 32)
        core.fillColor = sunTint.withAlphaComponent(0.95)
        core.strokeColor = .clear
        sun.addChild(core)
        sun.zPosition = -990
        addChild(sun)
        sunNode = sun

        // хөвөгч үүл
        cloudLayer.zPosition = -970
        addChild(cloudLayer)
        for i in 0..<4 {
            let cloud = makeCloud(scale: 0.7 + CGFloat(i % 3) * 0.25)
            cloud.position = CGPoint(x: CGFloat(i) * (size.width / 3) + 40,
                                     y: size.height - 40 - CGFloat(i % 2) * 34)
            cloud.alpha = 0.16
            cloudLayer.addChild(cloud)
            let span = size.width + 260
            let speed = 26.0 + Double(i % 3) * 8
            let drift = SKAction.moveBy(x: -span, y: 0, duration: span / speed)
            let reset = SKAction.moveBy(x: span, y: 0, duration: 0)
            cloud.run(.repeatForever(.sequence([drift, reset])))
        }

        let far = SKShapeNode()
        far.fillColor = Palette.hillFar
        far.strokeColor = .clear
        far.zPosition = -960
        addChild(far)
        farHills = far

        let near = SKShapeNode()
        near.fillColor = Palette.hillNear
        near.strokeColor = .clear
        near.zPosition = -950
        addChild(near)
        nearHills = near

        world.zPosition = 0
        addChild(world)
        hud.zPosition = 1000
        addChild(hud)
    }

    private func makeCloud(scale: CGFloat) -> SKNode {
        let node = SKNode()
        let puffs: [(CGFloat, CGFloat, CGFloat)] = [(0, 0, 34), (-24, 4, 22), (26, 3, 24), (4, -8, 20)]
        for (dx, dy, rr) in puffs {
            let p = SKShapeNode(ellipseOf: CGSize(width: rr * 2 * scale, height: rr * 1.0 * scale))
            p.fillColor = SKColor(white: 1, alpha: 1)
            p.strokeColor = .clear
            p.position = CGPoint(x: dx * scale, y: dy * scale)
            node.addChild(p)
        }
        return node
    }

    private func hillPath(parallax: CGFloat, base: CGFloat, amp: CGFloat, horizonY: CGFloat) -> CGPath {
        let width = size.width + World.width * worldScale * parallax + 200
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        var x: CGFloat = 0
        while x <= width {
            let y = horizonY + base + sinF(x * 0.008) * amp + sinF(x * 0.021) * amp * 0.4
            path.addLine(to: CGPoint(x: x, y: y))
            x += 24
        }
        path.addLine(to: CGPoint(x: width, y: 0))
        path.close()
        return path.cgPath
    }

    // MARK: - Дэлхий байгуулах

    private func buildWorld() {
        // газар
        let ground = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.48, green: 0.54, blue: 0.27, alpha: 1),
                     UIColor(red: 0.30, green: 0.35, blue: 0.16, alpha: 1)]),
            size: CGSize(width: World.width, height: World.groundTop + 60))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = CGPoint(x: 0, y: 0)
        ground.zPosition = -800
        world.addChild(ground)

        // зам
        let lane = SKSpriteNode(color: Palette.lane, size: CGSize(width: World.width, height: 180))
        lane.anchorPoint = CGPoint(x: 0, y: 0.5)
        lane.position = CGPoint(x: 0, y: World.laneY)
        lane.zPosition = -790
        world.addChild(lane)

        // чимэглэл — гэр, майхан, чулуу, өвс
        addDecorations()

        // байгууламжууд
        pGate = Unit(kind: .gate, team: .mongol, displayName: "Их хаалга", radius: 52, hp: 2000)
        pGate.position = CGPoint(x: World.pGateX, y: World.laneY)
        eGate = Unit(kind: .gate, team: .khwarezm, displayName: "Хорезмын хаалга", radius: 52, hp: 2000)
        eGate.position = CGPoint(x: World.eGateX, y: World.laneY)

        let pTower = Unit(kind: .tower, team: .mongol, displayName: "Харуулын цамхаг",
                          radius: 34, hp: 1500, dmg: 95, range: 270, atkCd: 1.5)
        pTower.position = CGPoint(x: World.pTowerX, y: World.laneY)
        let eTower = Unit(kind: .tower, team: .khwarezm, displayName: "Дайсны цамхаг",
                          radius: 34, hp: 1500, dmg: 95, range: 270, atkCd: 1.5)
        eTower.position = CGPoint(x: World.eTowerX, y: World.laneY)

        for s in [pGate!, eGate!, pTower, eTower] {
            s.zPosition = zFor(y: s.position.y)
            world.addChild(s)
            track(s)
        }

        // тоглогчийн баатар — мастерийн од бүр +3% амь, хүч
        let def = GameData.heroes[heroIndex]
        player = Unit(kind: .hero, team: .mongol, displayName: def.name,
                      radius: 20, hp: def.hp, dmg: def.dmg, range: def.range,
                      atkCd: def.atkCd, moveSpeed: def.speed, aggro: 320, heroDef: def)
        // PvP-д шударга байлгах үүднээс мастерийн нэмэгдэл үйлчлэхгүй
        let mastery = isPvp ? 0 : Progress.mastery(def.id)
        if mastery > 0 {
            player.maxHp = (def.hp * (1 + 0.03 * CGFloat(mastery))).rounded()
            player.hp = player.maxHp
            player.dmg = (def.dmg * (1 + 0.03 * CGFloat(mastery))).rounded()
            player.updateBars()
        }
        // буурийн шинэчлэл: адууны сүрэг → хурд, дархны зэвсэг → хүч (PvP-д үйлчлэхгүй)
        if !isPvp {
            player.moveSpeed = (player.moveSpeed * Progress.horseSpeedMul).rounded()
            player.dmg = (player.dmg * Progress.ironDamageMul).rounded()
        }
        player.position = CGPoint(x: World.pGateX + 130, y: World.laneY)
        world.addChild(player)
        track(player)

        // дайсны баатар: PvP-д алсын тоглогч, эсрэг тохиолдолд AI (Жалал ад-Дин)
        if let remoteIdx = pvpRemoteHero {
            let rd = GameData.heroes[remoteIdx]
            aiHero = Unit(kind: .hero, team: .khwarezm, displayName: rd.name,
                          radius: 20, hp: rd.hp, dmg: rd.dmg, range: rd.range,
                          atkCd: rd.atkCd, moveSpeed: rd.speed, aggro: 320, heroDef: rd)
        } else {
            let jd = GameData.jalal
            aiHero = Unit(kind: .hero, team: .khwarezm, displayName: enemyHeroName,
                          radius: 20, hp: (jd.hp * effHeroHp).rounded(),
                          dmg: (jd.dmg * effHeroDmg).rounded(), range: jd.range,
                          atkCd: jd.atkCd, moveSpeed: jd.speed, aggro: 320, heroDef: jd)
        }
        aiHero.position = CGPoint(x: World.eGateX - 130, y: World.laneY)
        world.addChild(aiHero)
        track(aiHero)

        camX = 0
    }

    /// Нэгжид сүлжээний дугаар өгч жагсаалтад бүртгэнэ
    private func track(_ u: Unit) {
        u.netId = nextNetId
        nextNetId += 1
        units.append(u)
    }

    // MARK: - Аяны даалгавар

    private func setupObjective(_ o: Objective) {
        objective = o
        switch o {
        case .reach:
            escapePos = CGPoint(x: World.eGateX - 40, y: World.laneY)
            let zone = SKShapeNode(ellipseOf: CGSize(width: 180, height: 90))
            zone.strokeColor = SKColor(red: 0.47, green: 0.90, blue: 0.47, alpha: 1)
            zone.lineWidth = 4
            zone.fillColor = SKColor(red: 0.47, green: 0.90, blue: 0.47, alpha: 0.13)
            zone.position = escapePos
            zone.zPosition = 10
            let flag = SKLabelNode(text: "⚑")
            flag.fontSize = 26
            flag.position = CGPoint(x: 0, y: 40)
            zone.addChild(flag)
            let lbl = UIFactory.label("ГАРЦ", font: Fonts.bold, size: 12,
                                      color: SKColor(red: 0.81, green: 0.91, blue: 0.66, alpha: 1))
            zone.addChild(lbl)
            world.addChild(zone)
            escapeZone = zone

        case .collect(let count, _):
            for i in 0..<count {
                let t = CGFloat(i) / CGFloat(count - 1)
                let x = World.pTowerX + 120 + t * (World.eTowerX - World.pTowerX - 120)
                let y = World.laneY + (i % 2 == 0 ? -1 : 1) * (50 + CGFloat((i * 13) % 70))
                let node = SKNode()
                node.position = CGPoint(x: x, y: y)
                node.zPosition = zFor(y: y)
                let ring = SKShapeNode(circleOfRadius: 18)
                ring.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.47, alpha: 0.6)
                ring.lineWidth = 2
                ring.fillColor = .clear
                node.addChild(ring)
                let horse = SKLabelNode(text: "🐎")
                horse.fontSize = 26
                horse.verticalAlignmentMode = .center
                node.addChild(horse)
                horse.run(.repeatForever(.sequence([
                    .moveBy(x: 0, y: 6, duration: 0.6),
                    .moveBy(x: 0, y: -6, duration: 0.6)
                ])))
                world.addChild(node)
                pickups.append(node)
            }

        case .rescue:
            let r = Unit(kind: .minion, team: .mongol, displayName: "Бөртэ",
                         radius: 16, hp: 900, moveSpeed: 210)
            r.isNpc = true
            r.position = CGPoint(x: World.eGateX - 40, y: World.laneY - 40)
            // энгийн ялгаатай дүрс
            r.removeAllChildren()
            let marker = SKLabelNode(text: "🙍‍♀️")
            marker.fontSize = 30
            marker.verticalAlignmentMode = .center
            r.addChild(marker)
            let ring = SKShapeNode(circleOfRadius: 20)
            ring.strokeColor = SKColor(red: 0.55, green: 0.91, blue: 0.48, alpha: 0.9)
            ring.lineWidth = 2.5
            ring.fillColor = .clear
            ring.position = CGPoint(x: 0, y: -4)
            r.addChild(ring)
            let nameL = UIFactory.label("Бөртэ", font: Fonts.bold, size: 12,
                                        color: SKColor(red: 0.81, green: 0.91, blue: 0.66, alpha: 1))
            nameL.position = CGPoint(x: 0, y: 30)
            r.addChild(nameL)
            r.zPosition = zFor(y: r.position.y)
            world.addChild(r)     // харагдана, гэхдээ чөлөөлөгдөх хүртэл units-д ороогүй
            rescuee = r

        case .survive(let secs, _):
            surviveT = secs

        case .slay, .gate:
            break
        }
    }

    /// Даалгаврын явцыг шинэчилнэ
    private func updateObjective(dt: CGFloat) {
        guard let o = objective, !objDone, !player.isDead else { return }
        switch o {
        case .reach:
            if player.position.distance(to: escapePos) < 90 { objComplete() }

        case .collect(let count, _):
            for node in pickups where node.parent != nil {
                if player.position.distance(to: node.position) < 40 {
                    node.removeFromParent()
                    Audio.shared.play("heal", volume: 0.6)
                    matchGold += 5
                    floater("🐎 +5 🪙", at: node.position, dy: 20,
                            color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
                    let got = pickups.filter { $0.parent == nil }.count
                    announce("Морь олдлоо! (\(got)/\(count))")
                    if got >= count { objComplete() }
                }
            }

        case .rescue:
            guard let r = rescuee, !r.isDead else { return }
            if !r.freed {
                if player.position.distance(to: r.position) < 60 {
                    r.freed = true
                    rescueeFreed = true
                    r.aggro = 0
                    track(r)          // одоо дайсан онилж болно
                    Audio.shared.play("level", volume: 0.7)
                    announce("Бөртэ чөлөөлөгдлөө! Гэртээ дагуулан аваач!")
                }
            } else {
                let dx = player.position.x - r.position.x
                let dy = player.position.y - r.position.y
                let d = vecLen(dx, dy)
                if d > 55 {
                    r.position.x = clampF(r.position.x + dx / d * r.moveSpeed * dt, 30, World.width - 30)
                    r.position.y = clampF(r.position.y + dy / d * r.moveSpeed * dt,
                                          World.groundBottom, World.groundTop)
                    r.face = dx > 0 ? 1 : -1
                }
                r.zPosition = zFor(y: r.position.y)
                if r.position.distance(to: pGate.position) < 200 { objComplete() }
            }

        case .survive:
            surviveT -= dt
            if surviveT <= 0 { objComplete() }

        case .slay, .gate:
            break
        }
    }

    private func objComplete() {
        guard !objDone else { return }
        objDone = true
        Audio.shared.play("win", volume: 0.7)
        Haptics.victory()
        announce("🎯 Даалгавар биелэв!")
        run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in
            guard let self = self, !self.ended else { return }
            self.endMatch(win: true)
        }]))
    }

    /// Аяны дундах динамик үйл явдлыг гаргана
    private func fireEvent(_ e: CampaignEvent) {
        announce("⚡ " + e.text)
        shakeT = max(shakeT, 0.4)
        Audio.shared.play("horn", volume: 0.5)
        let hpBase = 300 + CGFloat(waveNum) * 14
        let dmgBase = 27 + CGFloat(waveNum) * 1.5

        switch e.kind {
        case .reinforce:
            for i in 0..<4 {
                let archer = i == 3
                let hp = (archer ? hpBase * 0.72 : hpBase) * effMinionHp
                let m = Unit(kind: .minion, team: .khwarezm, radius: 15,
                             hp: hp, dmg: (archer ? dmgBase * 0.85 : dmgBase) * effMinionDmg,
                             range: archer ? 175 : 42, atkCd: archer ? 1.35 : 1.1,
                             moveSpeed: 105, archer: archer)
                m.position = CGPoint(x: eGate.position.x - (70 + CGFloat(i) * 30),
                                     y: World.laneY + (CGFloat(i) - 1.2) * 58)
                m.face = -1
                world.addChild(m)
                track(m)
            }

        case .ambush:
            for i in 0..<3 {
                let hp = (280 + CGFloat(waveNum) * 12) * effMinionHp
                let m = Unit(kind: .minion, team: .khwarezm, radius: 15,
                             hp: hp, dmg: (26 + CGFloat(waveNum) * 1.4) * effMinionDmg,
                             range: 42, atkCd: 1.1, moveSpeed: 120)
                m.position = CGPoint(x: clampF(player.position.x + CGFloat(i - 1) * 60, 200, World.width - 200),
                                     y: player.position.y + (i % 2 == 0 ? -80 : 80))
                m.face = -1
                world.addChild(m)
                track(m)
                burst(at: m.position, color: Palette.enemyRed, count: 12)
            }
            Audio.shared.play("drum", volume: 0.7)

        case .enrage:
            aiHero.dmg = (aiHero.dmg * 1.35).rounded()
            aiHero.moveSpeed *= 1.12
            aiHero.rageT = 9999
            Audio.shared.play("drum", volume: 0.8)
        }
    }

    private func addDecorations() {
        var seed = 7
        func rnd() -> CGFloat {
            seed = (seed &* 16807) % 2147483647
            return CGFloat(seed) / 2147483647
        }
        for _ in 0..<24 {
            let x = rnd() * World.width
            let y = World.groundBottom + rnd() * (World.groundTop - World.groundBottom)
            let grass = SKShapeNode()
            let path = UIBezierPath()
            for i in -1...1 {
                path.move(to: CGPoint(x: CGFloat(i) * 5, y: 0))
                path.addQuadCurve(to: CGPoint(x: CGFloat(i) * 8, y: 14),
                                  controlPoint: CGPoint(x: CGFloat(i) * 8, y: 7))
            }
            grass.path = path.cgPath
            grass.strokeColor = SKColor(red: 0.16, green: 0.24, blue: 0.08, alpha: 0.5)
            grass.lineWidth = 2
            grass.position = CGPoint(x: x, y: y)
            grass.zPosition = zFor(y: y) - 1
            world.addChild(grass)
        }
        for _ in 0..<7 {
            let x = 200 + rnd() * (World.width - 400)
            let y = World.groundBottom + rnd() * (World.groundTop - World.groundBottom)
            let s = 0.5 + rnd() * 0.9
            let rock = SKShapeNode(ellipseOf: CGSize(width: 32 * s, height: 20 * s))
            rock.fillColor = SKColor(red: 0.42, green: 0.42, blue: 0.35, alpha: 1)
            rock.strokeColor = SKColor(white: 0, alpha: 0.2)
            rock.position = CGPoint(x: x, y: y)
            rock.zPosition = zFor(y: y)
            world.addChild(rock)
        }
        // Монгол буурь (өөрийн талд): гэр, тэрэг, овоо
        addGer(x: 190, y: 548, scale: 1.2, banner: SKColor(red: 0.72, green: 0.23, blue: 0.16, alpha: 1))
        addGer(x: 315, y: 566, scale: 0.85, banner: SKColor(red: 0.72, green: 0.23, blue: 0.16, alpha: 1))
        addCart(x: 405, y: 552, scale: 1.0)
        addOvoo(x: 480, y: 560, scale: 1.0)
        // Дайсны тал — соёлоор ялгаатай
        let theme = camp?.theme ?? .khwarezm
        if theme == .khwarezm {
            addMosque(x: 2760, y: 552, scale: 1.15)
            addMinaret(x: 2645, y: 560, scale: 1.1)
            addMinaret(x: 2880, y: 556, scale: 0.9)
        } else {
            addGer(x: 2770, y: 550, scale: 1.15, banner: SKColor(red: 0.23, green: 0.35, blue: 0.55, alpha: 1))
            addGer(x: 2650, y: 568, scale: 0.85, banner: SKColor(red: 0.23, green: 0.35, blue: 0.55, alpha: 1))
            addCart(x: 2560, y: 556, scale: 0.95)
        }
    }

    // Монгол тэрэг (модон дугуйтай)
    private func addCart(x: CGFloat, y: CGFloat, scale s: CGFloat) {
        let cart = SKNode()
        let bed = SKSpriteNode(color: SKColor(red: 0.48, green: 0.35, blue: 0.20, alpha: 1),
                               size: CGSize(width: 52 * s, height: 8 * s))
        bed.position = CGPoint(x: 0, y: 4 * s)
        cart.addChild(bed)
        let load = SKShapeNode(ellipseOf: CGSize(width: 40 * s, height: 18 * s))
        load.fillColor = SKColor(red: 0.79, green: 0.66, blue: 0.42, alpha: 1)
        load.strokeColor = .clear
        load.position = CGPoint(x: 0, y: 14 * s)
        cart.addChild(load)
        for wx in [-16 * s, 16 * s] {
            let wheel = SKShapeNode(circleOfRadius: 9 * s)
            wheel.fillColor = .clear
            wheel.strokeColor = SKColor(red: 0.35, green: 0.23, blue: 0.10, alpha: 1)
            wheel.lineWidth = 2.5
            wheel.position = CGPoint(x: wx, y: -6 * s)
            cart.addChild(wheel)
        }
        cart.position = CGPoint(x: x, y: y)
        cart.zPosition = zFor(y: y)
        world.addChild(cart)
    }

    // Овоо (тахилгын чулуун овоо, хөх хадагтай)
    private func addOvoo(x: CGFloat, y: CGFloat, scale s: CGFloat) {
        let ovoo = SKNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -20 * s, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 44 * s))
        path.addLine(to: CGPoint(x: 20 * s, y: 0))
        path.close()
        let cairn = SKShapeNode(path: path.cgPath)
        cairn.fillColor = SKColor(red: 0.54, green: 0.51, blue: 0.45, alpha: 1)
        cairn.strokeColor = SKColor(white: 0, alpha: 0.2)
        ovoo.addChild(cairn)
        let pole = SKSpriteNode(color: SKColor(red: 0.35, green: 0.23, blue: 0.10, alpha: 1),
                                size: CGSize(width: 2, height: 16 * s))
        pole.position = CGPoint(x: 0, y: 52 * s)
        ovoo.addChild(pole)
        let khadag = SKShapeNode(rectOf: CGSize(width: 22 * s, height: 8 * s))
        khadag.fillColor = SKColor(red: 0.29, green: 0.56, blue: 0.82, alpha: 1)
        khadag.strokeColor = .clear
        khadag.position = CGPoint(x: 10 * s, y: 56 * s)
        ovoo.addChild(khadag)
        ovoo.position = CGPoint(x: x, y: y)
        ovoo.zPosition = zFor(y: y)
        world.addChild(ovoo)
    }

    // Хорезмын бөмбөгөр сүм (цэнхэр вааран бөмбөгөр)
    private func addMosque(x: CGFloat, y: CGFloat, scale s: CGFloat) {
        let m = SKNode()
        let base = SKSpriteNode(color: SKColor(red: 0.79, green: 0.66, blue: 0.47, alpha: 1),
                                size: CGSize(width: 80 * s, height: 34 * s))
        base.position = CGPoint(x: 0, y: 17 * s)
        m.addChild(base)
        let dome = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -30 * s, y: 34 * s))
            p.addCurve(to: CGPoint(x: 30 * s, y: 34 * s),
                       controlPoint1: CGPoint(x: -30 * s, y: 78 * s),
                       controlPoint2: CGPoint(x: 30 * s, y: 78 * s))
            p.close()
            return p.cgPath
        }())
        dome.fillColor = SKColor(red: 0.31, green: 0.66, blue: 0.82, alpha: 1)
        dome.strokeColor = SKColor(red: 0.10, green: 0.31, blue: 0.44, alpha: 1)
        dome.lineWidth = 1
        m.addChild(dome)
        let finial = SKShapeNode(circleOfRadius: 4 * s)
        finial.fillColor = SKColor(red: 0.91, green: 0.78, blue: 0.29, alpha: 1)
        finial.strokeColor = .clear
        finial.position = CGPoint(x: 0, y: 84 * s)
        m.addChild(finial)
        let arch = SKShapeNode(rectOf: CGSize(width: 16 * s, height: 22 * s))
        arch.fillColor = SKColor(red: 0.29, green: 0.22, blue: 0.16, alpha: 1)
        arch.strokeColor = .clear
        arch.position = CGPoint(x: 0, y: 11 * s)
        m.addChild(arch)
        m.position = CGPoint(x: x, y: y)
        m.zPosition = zFor(y: y)
        world.addChild(m)
    }

    // Минарет (өндөр цамхаг)
    private func addMinaret(x: CGFloat, y: CGFloat, scale s: CGFloat) {
        let m = SKNode()
        let shaft = SKSpriteNode(color: SKColor(red: 0.85, green: 0.72, blue: 0.53, alpha: 1),
                                 size: CGSize(width: 14 * s, height: 74 * s))
        shaft.position = CGPoint(x: 0, y: 37 * s)
        m.addChild(shaft)
        let balcony = SKSpriteNode(color: SKColor(red: 0.72, green: 0.60, blue: 0.41, alpha: 1),
                                   size: CGSize(width: 20 * s, height: 4 * s))
        balcony.position = CGPoint(x: 0, y: 60 * s)
        m.addChild(balcony)
        let top = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -8 * s, y: 74 * s))
            p.addQuadCurve(to: CGPoint(x: 8 * s, y: 74 * s), controlPoint: CGPoint(x: 0, y: 92 * s))
            p.close()
            return p.cgPath
        }())
        top.fillColor = SKColor(red: 0.23, green: 0.56, blue: 0.72, alpha: 1)
        top.strokeColor = .clear
        m.addChild(top)
        m.position = CGPoint(x: x, y: y)
        m.zPosition = zFor(y: y)
        world.addChild(m)
    }

    private func addGer(x: CGFloat, y: CGFloat, scale s: CGFloat,
                        banner: SKColor = SKColor(red: 0.72, green: 0.27, blue: 0.16, alpha: 1)) {
        let ger = SKNode()
        let wallH = 18 * s

        let base = SKShapeNode(ellipseOf: CGSize(width: 84 * s, height: 24 * s))
        base.fillColor = SKColor(red: 0.91, green: 0.88, blue: 0.82, alpha: 1)
        base.strokeColor = SKColor(red: 0.66, green: 0.60, blue: 0.47, alpha: 1)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -wallH / 2)
        ger.addChild(base)

        let wall = SKSpriteNode(color: SKColor(red: 0.91, green: 0.88, blue: 0.82, alpha: 1),
                                size: CGSize(width: 84 * s, height: wallH))
        ger.addChild(wall)

        let roofPath = UIBezierPath()
        roofPath.move(to: CGPoint(x: -46 * s, y: wallH / 2 - 2))
        roofPath.addLine(to: CGPoint(x: 0, y: wallH / 2 + 26 * s))
        roofPath.addLine(to: CGPoint(x: 46 * s, y: wallH / 2 - 2))
        roofPath.close()
        let roof = SKShapeNode(path: roofPath.cgPath)
        roof.fillColor = SKColor(red: 0.91, green: 0.88, blue: 0.82, alpha: 1)
        roof.strokeColor = SKColor(red: 0.66, green: 0.60, blue: 0.47, alpha: 1)
        roof.lineWidth = 1.5
        ger.addChild(roof)

        let door = SKSpriteNode(color: banner, size: CGSize(width: 16 * s, height: 16 * s))
        door.position = CGPoint(x: 0, y: -wallH / 2 + 8 * s)
        ger.addChild(door)

        // тооно (оройн цагираг)
        let toono = SKShapeNode(ellipseOf: CGSize(width: 16 * s, height: 7 * s))
        toono.strokeColor = SKColor(red: 0.54, green: 0.48, blue: 0.35, alpha: 1)
        toono.lineWidth = 1.5
        toono.fillColor = .clear
        toono.position = CGPoint(x: 0, y: wallH / 2 + 24 * s)
        ger.addChild(toono)

        ger.position = CGPoint(x: x, y: y)
        ger.zPosition = zFor(y: y)
        world.addChild(ger)
    }

    private func addTent(x: CGFloat, y: CGFloat, scale s: CGFloat) {
        let tent = SKNode()

        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -38 * s, y: -20 * s))
        bodyPath.addLine(to: CGPoint(x: 0, y: 30 * s))
        bodyPath.addLine(to: CGPoint(x: 38 * s, y: -20 * s))
        bodyPath.close()
        let bodyNode = SKShapeNode(path: bodyPath.cgPath)
        bodyNode.fillColor = SKColor(red: 0.48, green: 0.19, blue: 0.25, alpha: 1)
        bodyNode.strokeColor = .clear
        tent.addChild(bodyNode)

        let openPath = UIBezierPath()
        openPath.move(to: CGPoint(x: -10 * s, y: -20 * s))
        openPath.addLine(to: CGPoint(x: 0, y: 2 * s))
        openPath.addLine(to: CGPoint(x: 10 * s, y: -20 * s))
        openPath.close()
        let opening = SKShapeNode(path: openPath.cgPath)
        opening.fillColor = SKColor(red: 0.29, green: 0.11, blue: 0.16, alpha: 1)
        opening.strokeColor = .clear
        tent.addChild(opening)

        let pole = SKSpriteNode(color: SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1),
                                size: CGSize(width: 2.5, height: 14 * s))
        pole.position = CGPoint(x: 0, y: 37 * s)
        tent.addChild(pole)

        let flagPath = UIBezierPath()
        flagPath.move(to: CGPoint(x: 0, y: 44 * s))
        flagPath.addLine(to: CGPoint(x: 16 * s, y: 40 * s))
        flagPath.addLine(to: CGPoint(x: 0, y: 36 * s))
        flagPath.close()
        let flag = SKShapeNode(path: flagPath.cgPath)
        flag.fillColor = SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1)
        flag.strokeColor = .clear
        tent.addChild(flag)

        tent.position = CGPoint(x: x, y: y)
        tent.zPosition = zFor(y: y)
        world.addChild(tent)
    }

    /// y координатаас зурах дараалал: доогуур байх тусам урд
    private func zFor(y: CGFloat) -> CGFloat { 500 - y }

    // MARK: - HUD байгуулах

    private func buildHUD() {
        // жойстик
        joyBase.strokeColor = SKColor(red: 0.94, green: 0.89, blue: 0.77, alpha: 0.35)
        joyBase.lineWidth = 2
        joyBase.fillColor = SKColor(white: 0, alpha: 0.25)
        joyBase.isHidden = true
        hud.addChild(joyBase)

        joyKnob.fillColor = Palette.gold.withAlphaComponent(0.9)
        joyKnob.strokeColor = Palette.goldDark.withAlphaComponent(0.8)
        joyKnob.lineWidth = 2
        joyBase.addChild(joyKnob)

        // дээд самбар: хөрөг + амь + XP
        let def = GameData.heroes[heroIndex]
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

        let hpBg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55),
                                size: CGSize(width: hpBarW + 2, height: 12))
        hpBg.anchorPoint = CGPoint(x: 0, y: 0.5)
        hpBg.position = CGPoint(x: 52, y: -24)
        topbar.addChild(hpBg)

        hpFillHUD = SKSpriteNode(color: Palette.hpGreen, size: CGSize(width: hpBarW, height: 10))
        hpFillHUD.anchorPoint = CGPoint(x: 0, y: 0.5)
        hpFillHUD.position = CGPoint(x: 53, y: -24)
        topbar.addChild(hpFillHUD)

        let xpBg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55),
                                size: CGSize(width: hpBarW + 2, height: 6))
        xpBg.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpBg.position = CGPoint(x: 52, y: -35)
        topbar.addChild(xpBg)

        xpFillHUD = SKSpriteNode(color: Palette.xpBlue, size: CGSize(width: hpBarW, height: 4))
        xpFillHUD.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpFillHUD.position = CGPoint(x: 53, y: -35)
        xpFillHUD.xScale = 0
        topbar.addChild(xpFillHUD)

        // алалтын тоо
        killLabel = UIFactory.label("Алалт: 0  ·  Давалгаа: 0", font: Fonts.demi, size: 13)
        hud.addChild(killLabel)

        // даалгаврын самбар (аяны горимд)
        let bannerBg = SKShapeNode(rectOf: CGSize(width: 320, height: 26), cornerRadius: 13)
        bannerBg.fillColor = SKColor(red: 0.08, green: 0.16, blue: 0.06, alpha: 0.55)
        bannerBg.strokeColor = SKColor(red: 0.55, green: 0.91, blue: 0.48, alpha: 0.5)
        bannerBg.lineWidth = 1
        bannerBg.isHidden = true
        hud.addChild(bannerBg)
        objBannerBg = bannerBg
        let banner = UIFactory.label("", font: Fonts.bold, size: 13,
                                     color: SKColor(red: 0.55, green: 0.91, blue: 0.48, alpha: 1))
        banner.isHidden = true
        hud.addChild(banner)
        objBanner = banner

        // зарлал
        announceLabel = UIFactory.label("", font: Fonts.heavy, size: 24, color: Palette.goldLight)
        announceLabel.alpha = 0
        hud.addChild(announceLabel)

        // ML-маягийн удирдлага: том довтлох товч + жижиг чадварууд нуман байрлалтай
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

        // амь багасахад анхааруулах улаан хүрээ
        lowHpFrame = SKShapeNode()
        lowHpFrame.strokeColor = SKColor(red: 0.78, green: 0.12, blue: 0.08, alpha: 1)
        lowHpFrame.lineWidth = 10
        lowHpFrame.glowWidth = 18
        lowHpFrame.fillColor = .clear
        lowHpFrame.isHidden = true
        lowHpFrame.zPosition = 850
        hud.addChild(lowHpFrame)

        // дууны товч
        muteButton = SKNode()
        let muteBg = SKShapeNode(circleOfRadius: 18)
        muteBg.fillColor = SKColor(white: 0, alpha: 0.4)
        muteBg.strokeColor = Palette.gold.withAlphaComponent(0.5)
        muteBg.lineWidth = 1.5
        muteButton.addChild(muteBg)
        muteIcon = SKLabelNode(text: Audio.shared.muted ? "🔇" : "🔊")
        muteIcon.fontSize = 17
        muteIcon.verticalAlignmentMode = .center
        muteButton.addChild(muteIcon)
        hud.addChild(muteButton)

        // тулаанаас гарах товч
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

        // амилалтын бүрхүүл
        respawnDim = SKSpriteNode(color: SKColor(red: 0.16, green: 0.04, blue: 0.04, alpha: 0.45), size: size)
        respawnDim.isHidden = true
        respawnDim.zPosition = 900
        hud.addChild(respawnDim)

        respawnLabel = UIFactory.label("", font: Fonts.heavy, size: 26)
        respawnLabel.isHidden = true
        respawnLabel.zPosition = 901
        hud.addChild(respawnLabel)
    }

    // MARK: - Байрлал (дэлгэцийн хэмжээ өөрчлөгдөхөд)

    private func layout() {
        worldScale = size.height / World.viewH
        world.setScale(worldScale)

        skySprite?.size = CGSize(width: size.width, height: size.height)
        skySprite?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sunNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.82)

        let horizonY = (World.groundTop + 40) * worldScale
        farHills?.path = hillPath(parallax: 0.25, base: 55, amp: 45, horizonY: horizonY)
        nearHills?.path = hillPath(parallax: 0.45, base: 20, amp: 32, horizonY: horizonY)

        topbar.position = CGPoint(x: 12 + insets.left, y: size.height - 8 - insets.top)
        killLabel.position = CGPoint(x: size.width / 2, y: size.height - 24 - insets.top)
        objBannerBg?.position = CGPoint(x: size.width / 2, y: size.height - 52 - insets.top)
        objBanner?.position = CGPoint(x: size.width / 2, y: size.height - 52 - insets.top)
        muteButton.position = CGPoint(x: size.width - 30 - insets.right, y: size.height - 28 - insets.top)
        exitButton.position = CGPoint(x: size.width - 76 - insets.right, y: size.height - 28 - insets.top)
        announceLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)

        // довтлох товч буланд, чадварууд түүнийг тойрсон нумд (ML-маяг)
        let ax = size.width - 58 - insets.right
        let ay = 56 + insets.bottom
        attackButton.position = CGPoint(x: ax, y: ay)
        if skillButtons.count == 2 {
            skillButtons[0].position = CGPoint(x: ax - 90, y: ay + 6)    // чадвар 1 — зүүн
            skillButtons[1].position = CGPoint(x: ax - 60, y: ay + 74)   // чадвар 2 — дээд зүүн
        }

        respawnDim.size = size
        respawnDim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        respawnLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)

        lowHpFrame.path = UIBezierPath(
            roundedRect: CGRect(x: 4, y: 4, width: size.width - 8, height: size.height - 8),
            cornerRadius: 12).cgPath
    }

    // MARK: - Давалгаа

    /// Аяны горим — задгай талбарт тарсан дайсны бууц (марш давалгааны оронд).
    /// Бууц бүр байрандаа хамгаалж, тоглогч ойртоход л дайрна (WoW/GTA маягийн эрэл).
    private func setupCamps(level: Int) {
        let startX: CGFloat = 640, endX = World.eGateX - 300
        let nCamps = 5
        let band = Int(World.groundTop - World.groundBottom - 120)
        for c in 0..<nCamps {
            let t = nCamps > 1 ? CGFloat(c) / CGFloat(nCamps - 1) : 0
            let cx = startX + t * (endX - startX)
            let cy = World.groundBottom + 60 + CGFloat((c * 163 + 70) % max(1, band))
            let grunts = 3 + (c % 2)
            let hp = (300 + CGFloat(level) * 46) * effMinionHp
            let dmg = (25 + CGFloat(level) * 3.4) * effMinionDmg
            for i in 0..<grunts {
                let archer = i == grunts - 1
                let ox = (CGFloat(i) - CGFloat(grunts - 1) / 2) * 40
                let oy = CGFloat(i % 2 == 0 ? -1 : 1) * 26
                let gx = cx + ox
                let gy = clampF(cy + oy, World.groundBottom, World.groundTop)
                let m = Unit(kind: .minion, team: .khwarezm, radius: 15,
                             hp: archer ? hp * 0.7 : hp,
                             dmg: archer ? dmg * 0.85 : dmg,
                             range: archer ? 175 : 44,
                             atkCd: archer ? 1.35 : 1.1,
                             moveSpeed: 94, aggro: 205, archer: archer)
                m.isGuard = true
                m.homePos = CGPoint(x: gx, y: gy)
                m.position = m.homePos
                m.face = -1
                world.addChild(m)
                track(m)
            }
        }
        // сүүлийн бууцны аварга дайчин (жижиг босс)
        let bhp = (900 + CGFloat(level) * 90) * effMinionHp
        let b = Unit(kind: .minion, team: .khwarezm, displayName: "Хуарангийн ахлагч",
                     radius: 26, hp: bhp,
                     dmg: (48 + CGFloat(level) * 3) * effMinionDmg,
                     range: 52, atkCd: 1.2, moveSpeed: 74, aggro: 260, boss: true)
        b.isGuard = true
        b.homePos = CGPoint(x: endX, y: World.laneY)
        b.position = b.homePos
        b.face = -1
        world.addChild(b)
        track(b)
    }

    /// Нөхдийн отряд — тоглогчийг дагаж хамт байлдах жанжид (V2 co-op мэдрэмжийн прототип).
    private func setupWarband(level: Int) {
        let mates = GameData.heroes.filter { $0.id != GameData.heroes[heroIndex].id && $0.id != "chinggis" }.prefix(2)
        let offs = [CGPoint(x: -48, y: 48), CGPoint(x: -48, y: -48)]
        for (i, h) in mates.enumerated() {
            let ranged = h.range > 150
            let hp = 720 + CGFloat(level) * 42
            let c = Unit(kind: .minion, team: .mongol, displayName: h.name,
                         radius: 18, hp: hp,
                         dmg: ((42 + CGFloat(level) * 2.6) * Progress.ironDamageMul).rounded(),
                         range: ranged ? 200 : 64,
                         atkCd: 0.85, moveSpeed: (178 * Progress.horseSpeedMul).rounded(),
                         aggro: 250, archer: ranged)
            let off = offs[i]
            c.markCompanion(name: h.name, offset: off)
            c.position = CGPoint(x: player.position.x + off.x,
                                 y: clampF(player.position.y + off.y, World.groundBottom, World.groundTop))
            c.face = 1
            world.addChild(c)
            track(c)
        }
        if !mates.isEmpty { announce("🤝 Нөхдийн отряд тантай хамт мордов!") }
    }

    private func spawnWave() {
        waveNum += 1
        let hp = 300 + CGFloat(waveNum) * 14
        let dmg = 27 + CGFloat(waveNum) * 1.5

        for team in [Team.mongol, Team.khwarezm] {
            let gate: Unit = team == .mongol ? pGate : eGate
            let dir: CGFloat = team == .mongol ? 1 : -1
            let mHp = team == .khwarezm ? hp * effMinionHp : hp
            let mDmg = team == .khwarezm ? dmg * effMinionDmg : dmg
            for i in 0..<4 {
                let archer = i == 3
                let m = Unit(kind: .minion, team: team,
                             radius: 15,
                             hp: archer ? mHp * 0.72 : mHp,
                             dmg: archer ? mDmg * 0.85 : mDmg,
                             range: archer ? 175 : 42,
                             atkCd: archer ? 1.35 : 1.1,
                             moveSpeed: 105,
                             archer: archer)
                let yOff = (CGFloat(i) - 1.2) * 58 + sinF(CGFloat(waveNum) * 3 + CGFloat(i) * 7) * 18
                m.position = CGPoint(x: gate.position.x + dir * (70 + CGFloat(i) * 30),
                                     y: World.laneY + yOff)
                m.face = dir
                world.addChild(m)
                track(m)
            }
        }
        // 5 давалгаа тутамд аварга дайчин
        if waveNum % 5 == 0 {
            let bhp = (1100 + CGFloat(waveNum) * 45) * effMinionHp
            let b = Unit(kind: .minion, team: .khwarezm, displayName: "Аварга дайчин",
                         radius: 26, hp: bhp,
                         dmg: (55 + CGFloat(waveNum) * 2) * effMinionDmg,
                         range: 52, atkCd: 1.2, moveSpeed: 78, aggro: 320, boss: true)
            b.position = CGPoint(x: eGate.position.x - 90, y: World.laneY)
            b.face = -1
            world.addChild(b)
            track(b)
            announce("Аварга дайчин ирлээ!")
            netAnnounce("Аварга дайчин ирлээ!")
        }

        if waveNum == 1 { announce("Цэргүүд хөдөллөө!") }
    }

    /// Цуврал алалт — богино хугацаанд олон албал урамшуулна
    private func registerPlayerKill() {
        combo = comboT > 0 ? combo + 1 : 1
        comboT = 2.5
        if combo >= 3 {
            giveXP(CGFloat(combo * 4))
            floater("Цуврал x\(combo)!", at: player.position, dy: player.radius + 34,
                    color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
        }
    }

    // MARK: - Байлдааны туслахууд

    private func findTarget(for u: Unit, maxDist: CGFloat, unitsOnly: Bool) -> Unit? {
        var best: Unit?
        var bestD: CGFloat = .greatestFiniteMagnitude
        for e in units where !e.isDead && e.team != u.team {
            if unitsOnly && (e.kind == .tower || e.kind == .gate) { continue }
            let d = u.position.distance(to: e.position) - e.radius
            if d < bestD { bestD = d; best = e }
        }
        return bestD <= maxDist ? best : nil
    }

    private func dealDamage(to target: Unit, amount: CGFloat, from source: Unit?) {
        guard !target.isDead else { return }
        var amount = amount
        if target.shield > 0 {
            let absorbed = min(target.shield, amount)
            target.shield -= absorbed
            amount -= absorbed
            if amount <= 0 {
                floater("Бамбай!", at: target.position, dy: target.radius + 14, color: Palette.shieldBlue)
                return
            }
        }
        target.hp -= amount
        target.updateBars()
        target.flashHit()
        let color: SKColor = target.team == .mongol
            ? SKColor(red: 1.0, green: 0.48, blue: 0.42, alpha: 1)
            : SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1)
        floater("\(Int(amount))", at: target.position, dy: target.radius + 12, color: color)
        if target.hp <= 0 { kill(target, by: source) }
    }

    private func kill(_ u: Unit, by source: Unit?) {
        guard !u.isDead else { return }
        u.isDead = true
        burst(at: u.position, color: u.team == .khwarezm ? Palette.enemyRed : Palette.gold, count: 14)
        let byPlayer = source === player

        // Аврах NPC (Бөртэ) алагдвал даалгавар бүтэлгүйтнэ
        if u.isNpc {
            Audio.shared.play("crash", volume: 0.9)
            announce("Бөртэ алагдлаа...")
            u.removeFromParent()
            if !objDone { endMatch(win: false) }
            return
        }

        // Нөхдийн отряд — дайсны шагнал биш; дэргэд эргэн босно (устгахгүй)
        if u.isCompanion {
            u.isHidden = true
            u.respawnT = 6 + CGFloat(campaignLevel ?? 0) * 0.25
            floater("\(u.displayName) унав", at: u.position, dy: u.radius + 24, color: Palette.shieldBlue)
            return
        }

        switch u.kind {
        case .minion:
            if u.isBoss {
                shakeT = max(shakeT, 0.45)
                announce("Аварга дайчин уналаа!")
                Audio.shared.play("crash", volume: 0.9)
                if byPlayer {
                    giveXP(140)
                    matchGold += 25
                    floater("+25 🪙", at: u.position, dy: 40,
                            color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
                    registerPlayerKill()
                }
            } else if byPlayer {
                giveXP(26)
                matchGold += 2
                floater("+2 🪙", at: u.position, dy: 34,
                        color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
                registerPlayerKill()
            } else if isPvp, let s = source, s === aiHero {
                giveXP(26, to: s)
            } else if let s = source, s.team == .mongol {
                giveXP(10)
            }
            u.removeFromParent()

        case .hero:
            Haptics.crash()
            Audio.shared.play("crash", volume: 0.8)
            u.isHidden = true
            if u === aiHero {
                kills += 1
                giveXP(140)
                matchGold += 15
                floater("+15 🪙", at: u.position, dy: 40,
                        color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
                // Командлагчийг дийлэх даалгавар
                if case .slay(let count, _)? = objective {
                    commanderKills += 1
                    if commanderKills >= count { objComplete(); return }
                    announce("\(enemyHeroName)-г дийллээ! (\(commanderKills)/\(count))")
                    u.respawnT = 4.5
                } else {
                    announce("Дайсны баатрыг унагалаа!")
                    u.respawnT = isPvp ? 6 + CGFloat(u.level) * 1.2 : 9 + min(matchTime / 60, 8)
                }
                netAnnounce("Та унасан байна...")
            } else {
                if isPvp, let s = source, s === aiHero {
                    guestKills += 1
                    giveXP(140, to: s)
                }
                announce("Та унасан байна...")
                netAnnounce("Дайсны баатрыг унагалаа!")
                // Зарим даалгаварт үхэл = бүтэлгүйтэл
                if let o = objective {
                    switch o {
                    case .reach, .collect, .rescue:
                        u.isHidden = true
                        if !objDone { endMatch(win: false) }
                        return
                    default: break
                    }
                }
                u.respawnT = 6 + CGFloat(player.level) * 1.2
            }

        case .tower:
            Haptics.crash()
            Audio.shared.play("crash", volume: 1)
            burst(at: CGPoint(x: u.position.x, y: u.position.y + 40),
                  color: SKColor(red: 0.8, green: 0.72, blue: 0.6, alpha: 1), count: 26)
            ringFx(at: u.position, radius: 120, color: SKColor(white: 0.85, alpha: 0.8))
            screenFlash(SKColor(red: 0.91, green: 0.85, blue: 0.69, alpha: 1), alpha: 0.16)
            shakeT = max(shakeT, 0.55)
            announce(u.team == .khwarezm ? "Дайсны цамхаг нурлаа!" : "Манай цамхаг нурлаа!")
            netAnnounce(u.team == .khwarezm ? "Манай цамхаг нурлаа!" : "Дайсны цамхаг нурлаа!")
            if u.team == .khwarezm && byPlayer { giveXP(160); matchGold += 20 }
            if u.team == .mongol && isPvp { giveXP(160, to: aiHero) }
            u.removeFromParent()

        case .gate:
            Haptics.crash()
            Audio.shared.play("crash", volume: 1)
            burst(at: CGPoint(x: u.position.x, y: u.position.y + 50),
                  color: SKColor(red: 0.85, green: 0.75, blue: 0.63, alpha: 1), count: 40)
            ringFx(at: u.position, radius: 180, color: SKColor(white: 0.88, alpha: 0.85))
            screenFlash(SKColor(red: 0.94, green: 0.88, blue: 0.75, alpha: 1), alpha: 0.22)
            shakeT = max(shakeT, 0.7)
            if u.team == .mongol {
                // Манай хаалга унах нь зөвхөн хамгаалах даалгаварт ялагдал
                let guardMode: Bool
                switch objective {
                case .none, .some(.gate), .some(.slay), .some(.survive): guardMode = true
                default: guardMode = false
                }
                if guardMode && !objDone { endMatch(win: false) }
            } else {
                // дайсны хаалга: зөвхөн 'gate' даалгаварт эсвэл энгийн тулаанд ялалт
                switch objective {
                case .none, .some(.gate): objComplete()
                default: break
                }
            }
        }
    }

    private func performAttack(_ u: Unit, on target: Unit) {
        u.atkT = u.atkCd * (u.frenzyT > 0 ? 0.5 : 1)
        u.face = target.position.x >= u.position.x ? 1 : -1
        let dmg = u.dmg * (u.rageT > 0 ? 1.45 : 1)
        if u.range > 100 {
            Audio.shared.play("bow", volume: 0.35)
            let p = Projectile(from: CGPoint(x: u.position.x, y: u.position.y + 14),
                               dmg: dmg, team: u.team, owner: u, pierce: false, life: 3,
                               big: u.kind == .tower)
            p.target = target
            world.addChild(p.node)
            projectiles.append(p)
        } else {
            Audio.shared.play("hit", volume: 0.4)
            dealDamage(to: target, amount: dmg, from: u)
            let col: SKColor = u.team == .khwarezm
                ? SKColor(red: 1.0, green: 0.62, blue: 0.54, alpha: 1)
                : SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1)
            slashFx(at: CGPoint(x: u.position.x + u.face * u.radius * 1.3, y: u.position.y - u.radius * 0.3),
                    face: u.face, color: col)
            sparks(at: CGPoint(x: target.position.x - u.face * target.radius * 0.5,
                               y: target.position.y - target.radius * 0.4), face: u.face, color: col)
            u.swingWeapon()
            if u.kind == .hero { shakeT = max(shakeT, 0.12) }
            if u === player || target === player { Haptics.hit() }
        }
    }

    /// Хамгийн ойрын N дайсныг олох (байгууламж оруулахгүй)
    private func nearestEnemies(of u: Unit, count: Int, maxDist: CGFloat) -> [Unit] {
        let candidates = units.filter {
            !$0.isDead && $0.team != u.team && $0.kind != .tower && $0.kind != .gate
                && u.position.distance(to: $0.position) - $0.radius <= maxDist
        }
        return Array(candidates.sorted {
            u.position.distance(to: $0.position) < u.position.distance(to: $1.position)
        }.prefix(count))
    }

    private func moveUnit(_ u: Unit, toward point: CGPoint, dt: CGFloat) {
        guard u.stun <= 0 else { return }
        let dx = point.x - u.position.x
        let dy = point.y - u.position.y
        let d = vecLen(dx, dy)
        guard d > 4 else { return }
        let sp = u.moveSpeed * (u.hasteT > 0 ? 1.35 : 1)
        u.position.x = clampF(u.position.x + dx / d * sp * dt, 30, World.width - 30)
        u.position.y = clampF(u.position.y + dy / d * sp * dt, World.groundBottom, World.groundTop)
        if abs(dx) > 1 { u.face = dx > 0 ? 1 : -1 }
    }

    // MARK: - Туршлага, түвшин

    private func giveXP(_ n: CGFloat) {
        giveXP(n, to: player)
    }

    private func giveXP(_ n: CGFloat, to u: Unit) {
        guard u.level < World.maxLevel else { return }
        u.xp += n
        var need = World.xpNeed(u.level)
        while u.xp >= need && u.level < World.maxLevel {
            u.xp -= need
            u.level += 1
            u.maxHp = (u.maxHp * 1.13).rounded()
            u.dmg = (u.dmg * 1.11).rounded()
            u.hp = min(u.maxHp, u.hp + u.maxHp * 0.35)
            u.updateBars()
            burst(at: u.position, color: Palette.xpBlue, count: 22)
            ringFx(at: u.position, radius: 90, color: Palette.xpBlue)
            if u === player {
                screenFlash(SKColor(red: 0.75, green: 0.88, blue: 1.0, alpha: 1), alpha: 0.22)
                announce("Түвшин \(u.level) боллоо!")
                Haptics.levelUp()
                Audio.shared.play("level", volume: 0.7)
            }
            need = World.xpNeed(u.level)
        }
    }

    // MARK: - Чадварууд

    private func useSkill(_ idx: Int) {
        castSkill(for: player, idx: idx)
    }

    /// Аль ч баатрын чадвар — PvP-д алсын тоглогчийн баатарт мөн ашиглагдана
    private func castSkill(for u: Unit, idx: Int) {
        guard !ended, let def = u.heroDef, !u.isDead, u.stun <= 0 else { return }
        let cd = idx == 0 ? def.s1.cd : def.s2.cd
        if idx == 0 { guard u.s1T <= 0 else { return }; u.s1T = cd }
        else        { guard u.s2T <= 0 else { return }; u.s2T = cd }
        if u === player { Haptics.skill() }
        Audio.shared.play("skill", volume: 0.6)
        let lvl = CGFloat(u.level)

        switch def.id {
        case "chinggis":
            if idx == 0 {
                // Сэлмийн хуй — том хүчирхэг тойрсон цохилт (премиум)
                let radius: CGFloat = 170
                ringFx(at: u.position, radius: radius,
                       color: SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1))
                for e in units where !e.isDead && e.team != u.team {
                    if u.position.distance(to: e.position) < radius + e.radius {
                        dealDamage(to: e, amount: u.dmg * 1.8 + lvl * 10, from: u)
                    }
                }
            } else {
                // Тэнгэрийн ивээл — их эдгэрэлт + урт хурд
                Audio.shared.play("heal", volume: 0.7)
                u.hp = min(u.maxHp, u.hp + u.maxHp * 0.35)
                u.hasteT = 4
                u.updateBars()
                healSparks(at: u.position, count: 14)
            }

        case "temuujin":
            if idx == 0 {
                // Хурц сэлэм — урд талын цавчилт
                let center = CGPoint(x: u.position.x + u.face * 80, y: u.position.y)
                ringFx(at: center, radius: 100,
                       color: SKColor(red: 1.0, green: 0.85, blue: 0.66, alpha: 1))
                for e in units where !e.isDead && e.team != u.team {
                    if center.distance(to: e.position) < 100 + e.radius {
                        dealDamage(to: e, amount: u.dmg * 1.5 + lvl * 7, from: u)
                    }
                }
            } else {
                // Өсөх хүч — дунд зэргийн эдгэрэлт
                Audio.shared.play("heal", volume: 0.6)
                u.hp = min(u.maxHp, u.hp + u.maxHp * 0.25)
                u.updateBars()
                healSparks(at: u.position, count: 10)
            }

        case "zev":
            if idx == 0 {
                // Нэвтлэх сум
                let t = findTarget(for: u, maxDist: 600, unitsOnly: false)
                let dir: CGFloat
                if let t = t {
                    dir = angle(dx: t.position.x - u.position.x, dy: t.position.y - u.position.y)
                } else {
                    dir = u.face > 0 ? 0 : .pi
                }
                let p = Projectile(from: CGPoint(x: u.position.x, y: u.position.y + 14),
                                   dmg: u.dmg * 2 + lvl * 10, team: u.team,
                                   owner: u, pierce: true, life: 1.1)
                p.velocity = CGVector(dx: cosF(dir) * 680, dy: sinF(dir) * 680)
                world.addChild(p.node)
                projectiles.append(p)
            } else {
                // Сумны бороо
                let t = findTarget(for: u, maxDist: 520, unitsOnly: true)
                    ?? findTarget(for: u, maxDist: 520, unitsOnly: false)
                let cx = t?.position.x ?? (u.position.x + u.face * 220)
                let cy = t?.position.y ?? u.position.y
                let z = Zone(center: CGPoint(x: cx, y: cy), r: 130, delay: 0.7,
                             dmg: u.dmg * 1.7 + lvl * 9, team: u.team, owner: u)
                world.addChild(z.node)
                zones.append(z)
            }

        case "subedei":
            if idx == 0 {
                // Шуурган довтолгоо
                let t = findTarget(for: u, maxDist: 420, unitsOnly: true)
                let dir: CGFloat
                if let t = t {
                    dir = angle(dx: t.position.x - u.position.x, dy: t.position.y - u.position.y)
                } else {
                    dir = u.face > 0 ? 0 : .pi
                }
                u.dashT = 0.28
                u.dashVX = cosF(dir) * 880
                u.dashVY = sinF(dir) * 880
                u.dashDmg = u.dmg * 1.3 + lvl * 7
                u.dashHit.removeAll()
            } else {
                // Төмөр бамбай
                u.shield = 320 + lvl * 45
                u.shieldT = 5
            }

        case "mukhulai":
            if idx == 0 {
                // Газар доргилт — тойрсон цохилт + зогсоолт
                let radius: CGFloat = 130
                ringFx(at: u.position, radius: radius,
                       color: SKColor(red: 0.91, green: 0.71, blue: 0.42, alpha: 1))
                for e in units where !e.isDead && e.team != u.team {
                    if u.position.distance(to: e.position) < radius + e.radius {
                        dealDamage(to: e, amount: u.dmg * 1.3 + lvl * 7, from: u)
                        if e.kind != .tower && e.kind != .gate { e.stun = max(e.stun, 0.7) }
                    }
                }
            } else {
                // Тугийн уриа — довтолгооны хүч нэмэгдэнэ
                u.rageT = 5
                floater("Уриа!", at: u.position, dy: u.radius + 26,
                        color: SKColor(red: 1.0, green: 0.62, blue: 0.29, alpha: 1))
                ringFx(at: u.position, radius: 90,
                       color: SKColor(red: 1.0, green: 0.62, blue: 0.29, alpha: 1))
            }

        case "boorchi":
            if idx == 0 {
                // Шуурхай цохилт — гурван даралт; бай олдохгүй бол cd буцаана
                guard let t = findTarget(for: u, maxDist: 150, unitsOnly: true) else {
                    u.s1T = 0
                    return
                }
                let hitDmg = u.dmg * 0.7 + lvl * 4
                for k in 0..<3 {
                    strikes.append(DelayedStrike(t: CGFloat(k) * 0.13, target: t,
                                                 dmg: hitDmg, from: u))
                }
            } else {
                // Салхины хөл — хурд + гайхшрал арилгана
                u.hasteT = 4
                u.stun = 0
                floater("Салхи!", at: u.position, dy: u.radius + 26,
                        color: SKColor(red: 0.48, green: 0.76, blue: 0.69, alpha: 1))
            }

        case "khasar":
            if idx == 0 {
                // Гурван сум — ойрын 3 дайсан руу; бай олдохгүй бол cd буцаана
                let targets = nearestEnemies(of: u, count: 3, maxDist: 420)
                guard !targets.isEmpty else {
                    u.s1T = 0
                    return
                }
                for t in targets {
                    let p = Projectile(from: CGPoint(x: u.position.x, y: u.position.y + 14),
                                       dmg: u.dmg * 1.2 + lvl * 6, team: u.team,
                                       owner: u, pierce: false, life: 3)
                    p.target = t
                    world.addChild(p.node)
                    projectiles.append(p)
                }
            } else {
                // Тэнгэрийн нум — харвах хурд ×2
                u.frenzyT = 4
                floater("Тэнгэрийн нум!", at: u.position, dy: u.radius + 26,
                        color: SKColor(red: 0.69, green: 0.52, blue: 0.84, alpha: 1))
            }

        default: break
        }
    }

    private func healSparks(at pos: CGPoint, count: Int) {
        for _ in 0..<count {
            let spark = SKShapeNode(circleOfRadius: 3)
            spark.fillColor = SKColor(red: 0.70, green: 0.91, blue: 0.66, alpha: 1)
            spark.strokeColor = .clear
            spark.position = CGPoint(x: pos.x + .random(in: -28...28),
                                     y: pos.y + .random(in: -20...20))
            spark.zPosition = 700
            world.addChild(spark)
            spark.run(.sequence([
                .group([.moveBy(x: 0, y: 58, duration: 0.85), .fadeOut(withDuration: 0.85)]),
                .removeFromParent()
            ]))
        }
    }

    private func processStrikes(dt: CGFloat) {
        var idx = strikes.count - 1
        while idx >= 0 {
            strikes[idx].t -= dt
            if strikes[idx].t <= 0 {
                let s = strikes[idx]
                if let t = s.target, !t.isDead {
                    dealDamage(to: t, amount: s.dmg, from: s.from)
                    slashFx(at: t.position, face: CGFloat(Bool.random() ? 1 : -1),
                            color: SKColor(red: 0.48, green: 0.76, blue: 0.69, alpha: 1))
                    Audio.shared.play("hit", volume: 0.4)
                }
                strikes.remove(at: idx)
            }
            idx -= 1
        }
    }

    // MARK: - Дайсны баатрын AI

    private func updateAI(dt: CGFloat) {
        let u = aiHero!

        // амь багатай бол ухрах
        if u.hp < u.maxHp * 0.25 && u.position.distance(to: eGate.position) > 200 {
            moveUnit(u, toward: CGPoint(x: eGate.position.x - 90, y: eGate.position.y), dt: dt)
            return
        }

        // өөрийн цэргийн эгнээний ард явах
        var front: Unit?
        for m in units where !m.isDead && m.team == .khwarezm && m.kind == .minion {
            if front == nil || m.position.x < front!.position.x { front = m }
        }

        if let tgt = findTarget(for: u, maxDist: u.aggro, unitsOnly: false) {
            let d = u.position.distance(to: tgt.position)
            if d <= u.range + tgt.radius {
                if u.atkT <= 0 { performAttack(u, on: tgt) }
                // ойр байгаа баатрыг илднээс давалгаагаар цохих
                let isStructure = tgt.kind == .tower || tgt.kind == .gate
                if u.s1T <= 0 && !isStructure && d < 120 {
                    u.s1T = 7
                    ringFx(at: u.position, radius: 130,
                           color: SKColor(red: 1.0, green: 0.69, blue: 0.63, alpha: 1))
                    Haptics.skill()
                    for e in units where !e.isDead && e.team == .mongol {
                        if u.position.distance(to: e.position) < 130 + e.radius {
                            dealDamage(to: e, amount: u.dmg * 1.5, from: u)
                        }
                    }
                }
            } else {
                moveUnit(u, toward: tgt.position, dt: dt)
            }
        } else if isCampaign {
            // аяны горим: командлагч дайсны хаалгыг хамгаална (задгай талбарын босс)
            moveUnit(u, toward: CGPoint(x: eGate.position.x - 150, y: World.laneY), dt: dt)
        } else if let front = front {
            moveUnit(u, toward: CGPoint(x: front.position.x + 70, y: front.position.y), dt: dt)
        } else {
            moveUnit(u, toward: CGPoint(x: eGate.position.x - 200, y: World.laneY), dt: dt)
        }
    }

    // MARK: - PvP (хост тал)

    /// Зочны жойстик, чадвараар удирдагдах алсын баатар
    private func updateRemoteHero(dt: CGFloat) {
        let u = aiHero!
        let m = vecLen(remoteJoy.dx, remoteJoy.dy)
        if m > 0.15 && u.stun <= 0 && u.dashT <= 0 {
            let sp = u.moveSpeed * (u.hasteT > 0 ? 1.35 : 1) * min(m, 1)
            u.position.x = clampF(u.position.x + remoteJoy.dx / m * sp * dt, 30, World.width - 30)
            u.position.y = clampF(u.position.y + remoteJoy.dy / m * sp * dt,
                                  World.groundBottom, World.groundTop)
            if abs(remoteJoy.dx) > 0.1 { u.face = remoteJoy.dx > 0 ? 1 : -1 }
        }
        if u.atkT <= 0 && u.stun <= 0 && u.dashT <= 0 {
            if let t = findTarget(for: u, maxDist: u.range, unitsOnly: false) {
                performAttack(u, on: t)
            }
        }
    }

    private func netAnnounce(_ text: String) {
        guard isPvp else { return }
        NetHub.current?.send(.announce(text), reliable: true)
    }

    /// Довтлох товч (нэг удаагийн) — дайсны баатрыг тэргүүн ээлжид онилно (PvP-д ашиглагдана)
    private func forceAttack(_ u: Unit) {
        guard !u.isDead, u.stun <= 0, u.atkT <= 0, u.dashT <= 0 else { return }
        var target: Unit?
        for e in units where !e.isDead && e.team != u.team && e.kind == .hero {
            if u.position.distance(to: e.position) <= u.range + e.radius { target = e; break }
        }
        if target == nil {
            if let t = findTarget(for: u, maxDist: u.range, unitsOnly: false) { target = t }
        }
        if let t = target { performAttack(u, on: t) }
    }

    /// Довтлох товч (барих) — онилох бай: хүрээн доторх дайсны баатар → хамгийн ойрын дайсан →
    /// хүрээнээс гадуурх дайсны баатар (түүн уруу ойртоно)
    private func seekTarget(for u: Unit) -> Unit? {
        var hero: Unit?
        var heroD = CGFloat.greatestFiniteMagnitude
        for e in units where !e.isDead && e.team != u.team && e.kind == .hero {
            let d = u.position.distance(to: e.position) - e.radius
            if d < heroD { heroD = d; hero = e }
        }
        if let hero = hero, heroD <= u.range { return hero }
        if let near = findTarget(for: u, maxDist: u.range, unitsOnly: false) { return near }
        return hero
    }

    private func buildSnapshot() -> Snapshot {
        var snapUnits: [SnapUnit] = []
        for u in units where !u.isDead {
            let kindCode: UInt8
            switch u.kind {
            case .minion: kindCode = 0
            case .hero: kindCode = 1
            case .tower: kindCode = 2
            case .gate: kindCode = 3
            }
            var heroIdx: Int8 = -1
            var slot: Int8 = -1
            if u.kind == .hero, let def = u.heroDef,
               let idx = GameData.heroes.firstIndex(where: { $0.id == def.id }) {
                heroIdx = Int8(idx)
                slot = u === player ? 0 : 1
            }
            snapUnits.append(SnapUnit(
                i: u.netId, k: kindCode, t: UInt8(u.team.rawValue),
                x: Float(u.position.x), y: Float(u.position.y),
                hp: Float(u.hp), mh: Float(u.maxHp), f: Int8(u.face),
                h: heroIdx, b: u.isBoss, a: u.archer, s: slot))
        }
        let snapProjs = projectiles.map {
            SnapProj(x: Float($0.node.position.x), y: Float($0.node.position.y),
                     t: UInt8($0.team.rawValue), r: Float($0.node.zRotation))
        }
        let g = aiHero!
        return Snapshot(
            u: snapUnits, p: snapProjs, wave: waveNum,
            hostKills: kills, guestKills: guestKills,
            gHp: Float(g.hp), gMax: Float(g.maxHp), gLvl: g.level,
            gXp: Float(g.xp), gNeed: Float(World.xpNeed(g.level)),
            gS1: Float(g.s1T), gS2: Float(g.s2T))
    }

    // MARK: - Гол шинэчлэл

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime }
        let dt = CGFloat(min(currentTime - lastUpdate, 0.05))
        lastUpdate = currentTime
        guard built, !ended, dt > 0 else { return }

        matchTime += dt

        // цуврал ба чичиргээ буурах
        comboT = max(0, comboT - dt)
        if comboT <= 0 { combo = 0 }
        shakeT = max(0, shakeT - dt)

        if objective != nil && !objDone { updateObjective(dt: dt) }

        // аяны динамик үйл явдлууд
        if !pendingEvents.isEmpty {
            while let first = pendingEvents.first, matchTime >= first.t {
                pendingEvents.removeFirst()
                fireEvent(first)
            }
        }

        // Марш давалгаа зөвхөн энгийн тулаанд (аяны горим бол задгай талбарын бууц)
        if !isCampaign {
            nextWave -= dt
            if nextWave <= 0 {
                spawnWave()
                nextWave = World.waveInterval
            }
        }

        updatePlayer(dt: dt)

        if !aiHero.isDead {
            if isPvp {
                updateRemoteHero(dt: dt)
            } else {
                updateAI(dt: dt)
            }
            if aiHero.position.distance(to: eGate.position) < 240 {
                aiHero.hp = min(aiHero.maxHp, aiHero.hp + aiHero.maxHp * (isPvp ? 0.05 : 0.06) * dt)
                aiHero.updateBars()
            }
        }

        // PvP: тоглоомын байдлыг зочинд илгээх (~12 удаа/сек)
        if isPvp {
            snapshotT -= dt
            if snapshotT <= 0 {
                snapshotT = 0.08
                NetHub.current?.send(.snapshot(buildSnapshot()), reliable: false)
            }
        }

        updateUnits(dt: dt)
        applySeparation()
        updateProjectiles(dt: dt)
        updateZones(dt: dt)
        processStrikes(dt: dt)
        processAnnouncements()
        updateCamera(dt: dt)
        updateHUD()
    }

    private func updatePlayer(dt: CGFloat) {
        guard let player = player else { return }

        if player.isDead {
            player.respawnT -= dt
            respawnDim.isHidden = false
            respawnLabel.isHidden = false
            respawnLabel.text = "Дахин амилах: \(max(0, Int(player.respawnT.rounded(.up)))) сек"
            if player.respawnT <= 0 {
                player.isDead = false
                player.isHidden = false
                player.hp = player.maxHp
                player.stun = 0
                player.shield = 0
                player.position = CGPoint(x: pGate.position.x + 130, y: World.laneY)
                player.updateBars()
                burst(at: player.position, color: Palette.xpBlue, count: 16)
                respawnDim.isHidden = true
                respawnLabel.isHidden = true
            }
            return
        }
        respawnDim.isHidden = true
        respawnLabel.isHidden = true

        // жойстикийн хөдөлгөөн
        let m = vecLen(joyVec.dx, joyVec.dy)
        let moving = m > 0.15 && player.stun <= 0 && player.dashT <= 0
        if moving {
            let sp = player.moveSpeed * (player.hasteT > 0 ? 1.35 : 1) * min(m, 1)
            player.position.x = clampF(player.position.x + joyVec.dx / m * sp * dt, 30, World.width - 30)
            player.position.y = clampF(player.position.y + joyVec.dy / m * sp * dt,
                                       World.groundBottom, World.groundTop)
            if abs(joyVec.dx) > 0.1 { player.face = joyVec.dx > 0 ? 1 : -1 }
        }

        // Довтолгоо (ML маяг):
        //  · Довтлох товч барьж байвал: дайсныг мөшгин довтолно (хол бол ойртоно)
        //  · Жойстикээр хөдөлж байвал: автоматаар довтлохгүй
        //  · Зогсож байвал: хүрээн доторх дайсныг автоматаар цохино
        if player.stun <= 0 && player.dashT <= 0 {
            if attackHeld {
                if let t = seekTarget(for: player) {
                    let d = player.position.distance(to: t.position) - t.radius
                    if d <= player.range {
                        player.face = t.position.x >= player.position.x ? 1 : -1
                        if player.atkT <= 0 { performAttack(player, on: t) }
                    } else if !moving {
                        let dx = t.position.x - player.position.x
                        let dy = t.position.y - player.position.y
                        let dd = vecLen(dx, dy)
                        if dd > 1 {
                            let sp = player.moveSpeed * (player.hasteT > 0 ? 1.35 : 1)
                            player.position.x = clampF(player.position.x + dx / dd * sp * dt, 30, World.width - 30)
                            player.position.y = clampF(player.position.y + dy / dd * sp * dt,
                                                       World.groundBottom, World.groundTop)
                            player.face = dx > 0 ? 1 : -1
                        }
                    }
                }
            } else if !moving && player.atkT <= 0 {
                if let t = findTarget(for: player, maxDist: player.range, unitsOnly: false) {
                    performAttack(player, on: t)
                }
            }
        }

        // хаалганы дэргэд эдгэрэх
        if player.position.distance(to: pGate.position) < 240 {
            player.hp = min(player.maxHp, player.hp + player.maxHp * 0.05 * dt)
            player.updateBars()
        }
    }

    private func updateUnits(dt: CGFloat) {
        for u in units {
            if u.isDead {
                // дайсны баатрын амилалт
                if u === aiHero && u.respawnT > 0 {
                    u.respawnT -= dt
                    if u.respawnT <= 0 {
                        u.isDead = false
                        u.isHidden = false
                        if !isPvp {
                            // AI баатар амилах бүрдээ бага зэрэг хүчирхэгжинэ
                            u.maxHp = (u.maxHp * 1.1).rounded()
                            u.dmg = (u.dmg * 1.08).rounded()
                        }
                        u.hp = u.maxHp
                        u.stun = 0
                        u.position = CGPoint(x: eGate.position.x - 130, y: World.laneY)
                        u.updateBars()
                        burst(at: u.position, color: Palette.enemyRed, count: 16)
                    }
                }
                // нөхдийн отряд — тоглогчийн дэргэд эргэн босно
                if u.isCompanion && u.respawnT > 0 && !player.isDead {
                    u.respawnT -= dt
                    if u.respawnT <= 0 {
                        u.isDead = false
                        u.isHidden = false
                        u.hp = u.maxHp
                        u.stun = 0
                        u.position = CGPoint(x: player.position.x + u.compOff.x,
                                             y: clampF(player.position.y + u.compOff.y, World.groundBottom, World.groundTop))
                        u.updateBars()
                        burst(at: u.position, color: Palette.xpBlue, count: 12)
                    }
                }
                continue
            }

            u.atkT = max(0, u.atkT - dt)
            u.stun = max(0, u.stun - dt)
            u.hasteT = max(0, u.hasteT - dt)
            u.rageT = max(0, u.rageT - dt)
            u.frenzyT = max(0, u.frenzyT - dt)
            u.s1T = max(0, u.s1T - dt)
            u.s2T = max(0, u.s2T - dt)
            if u.shieldT > 0 {
                u.shieldT -= dt
                if u.shieldT <= 0 { u.shield = 0 }
            }

            // ухасхийлт — аль ч баатарт
            if u.dashT > 0 {
                u.position.x = clampF(u.position.x + u.dashVX * dt, 30, World.width - 30)
                u.position.y = clampF(u.position.y + u.dashVY * dt,
                                      World.groundBottom, World.groundTop)
                let trail = SKShapeNode(circleOfRadius: 8)
                trail.fillColor = Palette.shieldBlue.withAlphaComponent(0.5)
                trail.strokeColor = .clear
                trail.position = u.position
                trail.zPosition = 650
                world.addChild(trail)
                trail.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))

                for e in units where !e.isDead && e.team != u.team {
                    if e.kind == .tower || e.kind == .gate || u.dashHit.contains(e) { continue }
                    if u.position.distance(to: e.position) < 46 + e.radius {
                        u.dashHit.insert(e)
                        dealDamage(to: e, amount: u.dashDmg, from: u)
                        e.stun = max(e.stun, 0.9)
                    }
                }
                u.dashT -= dt
            }

            if u.kind == .minion && !u.isNpc && u.stun <= 0 {
                let searchR = u.isCompanion ? max(u.aggro, u.range + 40) : u.aggro
                let t = findTarget(for: u, maxDist: searchR, unitsOnly: false)
                if let t = t, !u.isCompanion || u.position.distance(to: t.position) < 260 {
                    let d = u.position.distance(to: t.position)
                    if d <= u.range + t.radius {
                        if u.atkT <= 0 { performAttack(u, on: t) }
                    } else {
                        moveUnit(u, toward: t.position, dt: dt)
                    }
                } else if u.isCompanion, !player.isDead {
                    // тоглогчийг формацаар дагана (хол хоцорвол гүйцэж ирнэ)
                    let tx = clampF(player.position.x + u.compOff.x, 30, World.width - 30)
                    let ty = clampF(player.position.y + u.compOff.y, World.groundBottom, World.groundTop)
                    let dest = CGPoint(x: tx, y: ty)
                    let gap = u.position.distance(to: dest)
                    if gap > 620 { u.position = dest }
                    else if gap > 22 { moveUnit(u, toward: dest, dt: dt) }
                } else if u.isGuard {
                    // хуарандаа буцаж хамгаална (задгай талбарын бууц)
                    if u.position.distance(to: u.homePos) > 10 {
                        moveUnit(u, toward: u.homePos, dt: dt)
                    }
                } else {
                    let goalX: CGFloat = u.team == .khwarezm ? World.pGateX : World.eGateX
                    let goalY = World.laneY + sinF(u.position.x * 0.01) * 70
                    moveUnit(u, toward: CGPoint(x: goalX, y: goalY), dt: dt)
                }
            }

            if u.kind == .tower && u.atkT <= 0 {
                if let t = findTarget(for: u, maxDist: u.range, unitsOnly: true) {
                    u.atkT = u.atkCd
                    let p = Projectile(from: CGPoint(x: u.position.x, y: u.position.y + 70),
                                       dmg: u.dmg, team: u.team, owner: u,
                                       pierce: false, life: 3, big: true)
                    p.target = t
                    world.addChild(p.node)
                    projectiles.append(p)
                }
            }

            // зурах дараалал
            if u.kind == .minion || u.kind == .hero {
                u.zPosition = zFor(y: u.position.y)
            }
        }

        units.removeAll { $0.isDead && $0.kind != .hero }
    }

    private func applySeparation() {
        for i in 0..<units.count {
            let a = units[i]
            if a.isDead || a.kind == .tower || a.kind == .gate { continue }
            for j in (i + 1)..<units.count {
                let b = units[j]
                if b.isDead || b.kind == .tower || b.kind == .gate { continue }
                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let d = vecLen(dx, dy)
                let minD = a.radius + b.radius - 4
                if d > 0.01 && d < minD {
                    let push = (minD - d) / 2
                    let nx = dx / d, ny = dy / d
                    a.position.x -= nx * push
                    a.position.y = clampF(a.position.y - ny * push, World.groundBottom, World.groundTop)
                    b.position.x += nx * push
                    b.position.y = clampF(b.position.y + ny * push, World.groundBottom, World.groundTop)
                }
            }
        }
    }

    private func updateProjectiles(dt: CGFloat) {
        var idx = projectiles.count - 1
        while idx >= 0 {
            let p = projectiles[idx]
            p.life -= dt
            var remove = p.life <= 0

            if !remove {
                if p.pierce {
                    p.node.position.x += p.velocity.dx * dt
                    p.node.position.y += p.velocity.dy * dt
                    p.node.zRotation = angle(dx: p.velocity.dx, dy: p.velocity.dy)
                    for e in units where !e.isDead && e.team != p.team && !p.hitSet.contains(e) {
                        if p.node.position.distance(to: e.position) < e.radius + 10 {
                            p.hitSet.insert(e)
                            dealDamage(to: e, amount: p.dmg, from: p.owner)
                            burst(at: p.node.position, color: SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1), count: 5)
                        }
                    }
                    if p.node.position.x < 0 || p.node.position.x > World.width { remove = true }
                } else {
                    guard let t = p.target, !t.isDead else {
                        p.node.removeFromParent()
                        projectiles.remove(at: idx)
                        idx -= 1
                        continue
                    }
                    let aim = CGPoint(x: t.position.x, y: t.position.y + 14)
                    let dx = aim.x - p.node.position.x
                    let dy = aim.y - p.node.position.y
                    let d = vecLen(dx, dy)
                    let step = 520 * dt
                    if d <= step + t.radius * 0.5 {
                        dealDamage(to: t, amount: p.dmg, from: p.owner)
                        burst(at: t.position,
                              color: p.team == .khwarezm
                                ? SKColor(red: 1.0, green: 0.62, blue: 0.54, alpha: 1)
                                : SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1),
                              count: 4)
                        remove = true
                    } else {
                        p.node.position.x += dx / d * step
                        p.node.position.y += dy / d * step
                        p.node.zRotation = angle(dx: dx, dy: dy)
                    }
                }
            }

            if remove {
                p.node.removeFromParent()
                projectiles.remove(at: idx)
            }
            idx -= 1
        }
    }

    private func updateZones(dt: CGFloat) {
        var idx = zones.count - 1
        while idx >= 0 {
            let z = zones[idx]
            z.delay -= dt

            // унаж буй сумнууд
            if Bool.random() {
                let arrow = SKShapeNode(rect: CGRect(x: -1, y: 0, width: 2, height: 14))
                arrow.fillColor = Palette.parchment
                arrow.strokeColor = .clear
                arrow.position = CGPoint(x: z.center.x + .random(in: -z.r...z.r),
                                         y: z.center.y + 180 + .random(in: 0...60))
                arrow.zPosition = 700
                world.addChild(arrow)
                arrow.run(.sequence([
                    .group([.moveBy(x: 0, y: -170, duration: 0.3), .fadeOut(withDuration: 0.3)]),
                    .removeFromParent()
                ]))
            }

            if z.delay <= 0 {
                ringFx(at: z.center, radius: z.r, color: SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1))
                for e in units where !e.isDead && e.team != z.team {
                    if z.center.distance(to: e.position) < z.r + e.radius {
                        dealDamage(to: e, amount: z.dmg, from: z.owner)
                    }
                }
                Haptics.hit()
                Audio.shared.play("hit", volume: 0.7)
                z.node.removeFromParent()
                zones.remove(at: idx)
            }
            idx -= 1
        }
    }

    // MARK: - Камер ба HUD

    private func updateCamera(dt: CGFloat) {
        let viewWWorld = size.width / worldScale
        let target = clampF(player.position.x - viewWWorld / 2, 0, max(0, World.width - viewWWorld))
        camX += (target - camX) * min(1, dt * 6)
        var sx: CGFloat = 0, sy: CGFloat = 0
        if shakeT > 0 {
            sx = CGFloat.random(in: -1...1) * 10 * shakeT * worldScale
            sy = CGFloat.random(in: -1...1) * 7 * shakeT * worldScale
        }
        world.position = CGPoint(x: -camX * worldScale + sx, y: sy)
        farHills?.position = CGPoint(x: -camX * worldScale * 0.25, y: 0)
        nearHills?.position = CGPoint(x: -camX * worldScale * 0.45, y: 0)
    }

    private func updateHUD() {
        hpFillHUD.xScale = clampF(player.hp / player.maxHp, 0, 1)
        xpFillHUD.xScale = clampF(player.xp / World.xpNeed(player.level), 0, 1)
        lvlLabel.text = "\(player.level)"
        killLabel.text = "Алалт: \(kills) · Давалгаа: \(waveNum) · 🪙 +\(matchGold)"
        let lowHp = !player.isDead && player.hp < player.maxHp * 0.3
        lowHpFrame.isHidden = !lowHp
        if lowHp { lowHpFrame.alpha = 0.45 + 0.3 * sinF(matchTime * 6) }

        // даалгаврын самбар
        if let o = objective {
            var txt = "🎯 " + o.label
            switch o {
            case .collect(let count, _):
                let got = pickups.filter { $0.parent == nil }.count
                txt += "  (\(got)/\(count))"
            case .slay(let count, _):
                txt += "  (\(commanderKills)/\(count))"
            case .survive:
                txt += "  (\(max(0, Int(surviveT.rounded(.up))))с)"
            case .rescue:
                if rescueeFreed { txt = "🎯 Бөртэг гэртээ хүргэ →" }
            default: break
            }
            objBanner?.text = txt
            objBanner?.isHidden = false
            objBannerBg?.isHidden = false
        }
        if skillButtons.count == 2 {
            skillButtons[0].setCooldown(player.s1T)
            skillButtons[1].setCooldown(player.s2T)
        }

        updateQuestMarker()
    }

    // MARK: - Даалгаврын замын заагч

    private func objectiveWorldTarget() -> (pos: CGPoint, label: String)? {
        if let z = escapeZone, z.parent != nil { return (z.position, "ГАРЦ") }
        if let r = rescuee, !r.isDead, !rescueeFreed { return (r.position, "Бөртэ") }
        if let pk = pickups.first(where: { $0.parent != nil }) { return (pk.position, "Морь") }
        if case .slay(_, _)? = objective, !aiHero.isDead { return (aiHero.position, aiHero.displayName) }
        // үлдсэн дайсны бууц руу — дараа нь хаалга руу чиглүүлнэ
        var near: Unit?
        var nd: CGFloat = .greatestFiniteMagnitude
        for u in units where !u.isDead && u.team == .khwarezm && u.kind == .minion && u.isGuard {
            let d = abs(u.position.x - player.position.x)
            if d < nd { nd = d; near = u }
        }
        if let n = near { return (n.position, "Дайсны бууц") }
        if !eGate.isDead { return (eGate.position, "Дайсны хаалга") }
        return nil
    }

    private func ensureQuestMarker() {
        guard questMarker == nil else { return }
        let node = SKNode()
        node.zPosition = 900
        hud.addChild(node)
        questMarker = node

        let dia = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 0, y: 16)); p.addLine(to: CGPoint(x: 11, y: 0))
            p.addLine(to: CGPoint(x: 0, y: -16)); p.addLine(to: CGPoint(x: -11, y: 0)); p.close()
            return p.cgPath
        }())
        dia.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.35, alpha: 0.96)
        dia.strokeColor = SKColor(red: 0.35, green: 0.24, blue: 0.04, alpha: 0.9)
        dia.lineWidth = 2
        node.addChild(dia)
        questDiamond = dia
        let bang = UIFactory.label("!", font: Fonts.heavy, size: 13,
                                   color: SKColor(red: 0.23, green: 0.16, blue: 0.03, alpha: 1))
        bang.verticalAlignmentMode = .center
        dia.addChild(bang)

        let arrow = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 20, y: 0)); p.addLine(to: CGPoint(x: -12, y: -13))
            p.addLine(to: CGPoint(x: -4, y: 0)); p.addLine(to: CGPoint(x: -12, y: 13)); p.close()
            return p.cgPath
        }())
        arrow.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.35, alpha: 0.96)
        arrow.strokeColor = SKColor(red: 0.35, green: 0.24, blue: 0.04, alpha: 0.9)
        arrow.lineWidth = 2
        arrow.isHidden = true
        node.addChild(arrow)
        questArrow = arrow

        let bg = SKShapeNode(rectOf: CGSize(width: 120, height: 20), cornerRadius: 6)
        bg.fillColor = SKColor(white: 0.07, alpha: 0.7)
        bg.strokeColor = .clear
        node.addChild(bg)
        questLabelBg = bg
        let lbl = UIFactory.label("", font: Fonts.bold, size: 12,
                                  color: SKColor(red: 1.0, green: 0.88, blue: 0.54, alpha: 1))
        lbl.verticalAlignmentMode = .center
        node.addChild(lbl)
        questLabel = lbl
    }

    private func updateQuestMarker() {
        // зөвхөн аяны горимд
        guard isCampaign, !player.isDead, let target = objectiveWorldTarget() else {
            questMarker?.isHidden = true
            return
        }
        ensureQuestMarker()
        questMarker?.isHidden = false

        let screenX = target.pos.x * worldScale + world.position.x
        let screenY = target.pos.y * worldScale + world.position.y
        let distM = Int(abs(target.pos.x - player.position.x) / 10)
        let onScreen = screenX > 40 && screenX < size.width - 40
            && screenY > 70 && screenY < size.height - 90

        if onScreen {
            let my = screenY + 66 + sinF(matchTime * 3) * 5
            questDiamond?.isHidden = false
            questArrow?.isHidden = true
            questDiamond?.position = CGPoint(x: screenX, y: my)
            questLabel?.text = "\(target.label) · \(distM)м"
            positionQuestLabel(x: screenX, y: my + 22)
        } else {
            let dir: CGFloat = screenX <= size.width / 2 ? -1 : 1
            let ex = dir < 0 ? 46 + insets.left : size.width - 46 - insets.right
            let ey = clampF(screenY, 110 + insets.bottom, size.height - 100 - insets.top)
            questDiamond?.isHidden = true
            questArrow?.isHidden = false
            questArrow?.position = CGPoint(x: ex, y: ey)
            questArrow?.xScale = dir
            questLabel?.text = "\(target.label) · \(distM)м"
            positionQuestLabel(x: ex, y: ey + 24)
        }
    }

    private func positionQuestLabel(x: CGFloat, y: CGFloat) {
        guard let lbl = questLabel, let bg = questLabelBg else { return }
        let w = lbl.frame.width + 16
        bg.path = CGPath(roundedRect: CGRect(x: -w / 2, y: -10, width: w, height: 20),
                         cornerWidth: 6, cornerHeight: 6, transform: nil)
        let cx = clampF(x, w / 2 + 6, size.width - w / 2 - 6)
        bg.position = CGPoint(x: cx, y: y)
        lbl.position = CGPoint(x: cx, y: y)
    }

    // MARK: - Зарлал ба эффект

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

    private func floater(_ text: String, at pos: CGPoint, dy: CGFloat, color: SKColor) {
        let l = SKLabelNode(text: text)
        l.fontName = Fonts.heavy
        l.fontSize = 20
        l.fontColor = color
        l.position = CGPoint(x: pos.x + .random(in: -10...10), y: pos.y + dy)
        l.zPosition = 800
        l.setScale(0.5)
        world.addChild(l)
        l.run(.sequence([
            .scale(to: 1.15, duration: 0.12),
            .group([.moveBy(x: 0, y: 34, duration: 0.78),
                    .sequence([.wait(forDuration: 0.4), .fadeOut(withDuration: 0.38)])]),
            .removeFromParent()
        ]))
    }

    private func burst(at pos: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let s = CGFloat.random(in: 50...200)
            let dot = SKShapeNode(circleOfRadius: .random(in: 2...5))
            dot.fillColor = color
            dot.strokeColor = .clear
            dot.position = pos
            dot.zPosition = 750
            world.addChild(dot)
            let dur = Double.random(in: 0.4...0.85)
            // таталцлын нум (дээшээ хөөрөөд унана)
            let up = SKAction.moveBy(x: cosF(a) * s * 0.5, y: sinF(a) * s * 0.5 + 30, duration: dur * 0.4)
            up.timingMode = .easeOut
            let down = SKAction.moveBy(x: cosF(a) * s * 0.25, y: -40, duration: dur * 0.6)
            down.timingMode = .easeIn
            dot.run(.sequence([
                .group([.sequence([up, down]), .fadeOut(withDuration: dur)]),
                .removeFromParent()
            ]))
        }
    }

    // цохилтын оч — чиглэлд шидэгдэх богино зураас
    private func sparks(at pos: CGPoint, face: CGFloat, color: SKColor, count: Int = 5) {
        for _ in 0..<count {
            let a = (face > 0 ? 0 : CGFloat.pi) + CGFloat.random(in: -0.7...0.7)
            let s = CGFloat.random(in: 100...180)
            let sp = SKShapeNode(rectOf: CGSize(width: 6, height: 1.6), cornerRadius: 0.8)
            sp.fillColor = color
            sp.strokeColor = .clear
            sp.zRotation = a
            sp.position = pos
            sp.zPosition = 760
            world.addChild(sp)
            sp.run(.sequence([
                .group([.moveBy(x: cosF(a) * s * 0.4, y: sinF(a) * s * 0.4, duration: 0.24),
                        .fadeOut(withDuration: 0.26)]),
                .removeFromParent()
            ]))
        }
    }

    private func ringFx(at pos: CGPoint, radius: CGFloat, color: SKColor) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.strokeColor = color
        ring.lineWidth = 6
        ring.fillColor = .clear
        ring.position = pos
        ring.zPosition = 700
        ring.setScale(0.15)
        ring.yScale = 0.15 * 0.55
        world.addChild(ring)
        ring.run(.sequence([
            .group([.scaleX(to: 1, y: 0.55, duration: 0.32), .fadeOut(withDuration: 0.34)]),
            .removeFromParent()
        ]))
    }

    // дэлгэцийн гэрэлтэлт (том үйл явдал)
    private func screenFlash(_ color: SKColor, alpha: CGFloat = 0.35) {
        let f = SKSpriteNode(color: color, size: size)
        f.position = CGPoint(x: size.width / 2, y: size.height / 2)
        f.zPosition = 1500
        f.alpha = alpha
        addChild(f)
        f.run(.sequence([.fadeOut(withDuration: 0.16), .removeFromParent()]))
    }

    private func slashFx(at pos: CGPoint, face: CGFloat, color: SKColor) {
        let start: CGFloat = face > 0 ? -1.15 : .pi - 1.15
        let end: CGFloat = start + 2.3
        let makeArc: (SKColor, CGFloat) -> SKShapeNode = { col, lw in
            let path = UIBezierPath(arcCenter: .zero, radius: 30,
                                    startAngle: start, endAngle: end, clockwise: true)
            let arc = SKShapeNode(path: path.cgPath)
            arc.strokeColor = col
            arc.lineWidth = lw
            arc.lineCap = .round
            arc.fillColor = .clear
            arc.position = pos
            arc.zPosition = 700
            return arc
        }
        let glow = makeArc(SKColor(white: 1, alpha: 0.9), 6)
        let core = makeArc(color, 3)
        world.addChild(glow); world.addChild(core)
        for a in [glow, core] {
            a.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        }
    }

    // MARK: - Тоглоомын төгсгөл

    private func endMatch(win: Bool) {
        guard !ended else { return }
        ended = true
        if win { Haptics.victory() } else { Haptics.defeat() }
        Audio.shared.play(win ? "win" : "lose", volume: 0.9)

        if isPvp {
            NetHub.current?.send(.end(hostWon: win, hostKills: kills, guestKills: guestKills), reliable: true)
        }

        // шагнал: тулааны алт + түвшин + ялалтын урамшуулал, хэцүү байдлаар үржүүлнэ
        // (PvP-д тогтмол: ялбал 100, ялагдвал 30)
        let heroId = GameData.heroes[heroIndex].id
        let chaptersBefore = Set(GameData.chapters.filter { $0.req.isMet }.map { $0.id })
        var earned = isPvp
            ? (win ? 100 : 30)
            : Int(((CGFloat(matchGold) + CGFloat(player.level) * 5 + (win ? 80 : 20))
                   * goldMult).rounded())

        // Эзлэлтийн олз: адуу ба төмөр (буурийн эдийн засаг) — аяны ялалтад
        var lootHorses = 0, lootIron = 0
        if let level = campaignLevel, win {
            lootHorses = 2 + Int(CGFloat(level) * 0.7)
            lootIron = 1 + Int(CGFloat(level) * 0.6)
            Progress.horses += lootHorses
            Progress.iron += lootIron
        }
        // нөхдийн отрядын тоо (regroup дэлгэцэд)
        let warband = units.filter { $0.isCompanion }
        let warbandAlive = warband.filter { !$0.isDead }.count

        // Аян дайн: анх удаа даван туулбал түвшин ахьж, бонус алт өгнө
        var campaignCleared: (index: Int, reward: Int, last: Bool)? = nil
        if let level = campaignLevel, win, Progress.clearCampaignLevel(level) {
            let L = GameData.campaign[level]
            earned += L.reward
            campaignCleared = (level, L.reward, level + 1 >= GameData.campaign.count)
        }

        Progress.gold += earned
        Progress.recordMatch(win: win)
        var gainedStar = false
        if win && Progress.mastery(heroId) < 5 {
            Progress.addMasteryStar(heroId)
            gainedStar = true
        }
        // тулааны дараа шинээр нээгдсэн түүхийн бүлэг
        let newChapter = GameData.chapters
            .first { $0.req.isMet && !chaptersBefore.contains($0.id) }?.title

        var campaignLine: String? = nil
        if let c = campaignCleared {
            campaignLine = c.last
                ? "🏆 Аян дайныг бүрэн дуусгав! Их Монгол Улс мандтугай!"
                : "⚔️ \(c.index + 1)-р түвшин анх удаа дуусгав! +\(c.reward) 🪙 · Дараагийн түвшин нээгдлээ"
        }

        let stats = MatchStats(win: win, kills: kills, level: player.level,
                               seconds: Int(matchTime), heroIndex: heroIndex,
                               difficultyIndex: difficultyIndex,
                               goldEarned: earned, totalGold: Progress.gold,
                               masteryStars: Progress.mastery(heroId), gainedStar: gainedStar,
                               newChapter: newChapter, isPvp: isPvp,
                               campaignLevel: campaignLevel, campaignLine: campaignLine,
                               cityTitle: campaignLevel.map { GameData.campaign[$0].title },
                               lootHorses: lootHorses, lootIron: lootIron,
                               warbandAlive: warbandAlive, warbandTotal: warband.count)
        run(.sequence([
            .wait(forDuration: 0.9),
            .run { [weak self] in
                guard let self = self, let view = self.view else { return }
                let end = EndScene(size: self.size, stats: stats)
                end.scaleMode = .resizeFill
                view.presentScene(end, transition: .fade(withDuration: 0.8))
            }
        ]))
    }

    /// Тулаанаас гарч үндсэн цэс рүү буцах
    private func exitToMenu() {
        if isPvp {
            NetHub.current?.send(.leave, reliable: true)
            NetHub.current?.stop()
            NetHub.current = nil
        }
        Audio.shared.play("tap")
        guard let view = view else { return }
        let menu = MenuScene(size: size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .fade(withDuration: 0.4))
    }

    // MARK: - Мэдрэгчийн оролт

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)

            // дууны товч
            if p.distance(to: muteButton.position) <= 26 {
                Audio.shared.muted.toggle()
                muteIcon.text = Audio.shared.muted ? "🔇" : "🔊"
                continue
            }

            // гарах товч
            if p.distance(to: exitButton.position) <= 26 {
                exitToMenu()
                return
            }

            // довтлох товч (барих) — дарж байх зуур дайсныг мөшгин довтолно
            if p.distance(to: attackButton.position) <= 46 {
                attackHeld = true
                attackTouch = t
                attackButton.setScale(0.9)
                Haptics.hit()
                continue
            }

            // чадварын товч
            var handled = false
            for (i, b) in skillButtons.enumerated() {
                if p.distance(to: b.position) <= b.btnRadius + 10 {
                    useSkill(i)
                    handled = true
                    break
                }
            }
            if handled { continue }

            // жойстик — дэлгэцийн зүүн хэсэг
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
        for t in touches {
            if t === joyTouch {
                joyTouch = nil
                joyVec = .zero
                joyBase.isHidden = true
            }
            if t === attackTouch {
                attackTouch = nil
                attackHeld = false
                attackButton.setScale(1.0)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

// MARK: - Тоглолтын үр дүн

struct MatchStats {
    let win: Bool
    let kills: Int
    let level: Int
    let seconds: Int
    let heroIndex: Int
    let difficultyIndex: Int
    let goldEarned: Int
    let totalGold: Int
    let masteryStars: Int
    let gainedStar: Bool
    let newChapter: String?
    var isPvp: Bool = false
    var campaignLevel: Int? = nil
    var campaignLine: String? = nil
    // V2 — эзлэлтийн олз ба нөхдийн отряд
    var cityTitle: String? = nil
    var lootHorses: Int = 0
    var lootIron: Int = 0
    var warbandAlive: Int = 0
    var warbandTotal: Int = 0
}

// MARK: - PvP мессеж хүлээн авах (хост)

extension BattleScene: MultiplayerDelegate {
    func mpConnected(peerName: String) {}

    func mpDisconnected() {
        guard isPvp, !ended else { return }
        announce("Найз тоглоомоос гарлаа")
        run(.sequence([.wait(forDuration: 1.0), .run { [weak self] in
            self?.endMatch(win: true)
        }]))
    }

    func mpReceived(_ msg: NetMsg) {
        guard isPvp else { return }
        switch msg {
        case .input(let dx, let dy):
            remoteJoy = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
        case .skill(let idx):
            if !aiHero.isDead { castSkill(for: aiHero, idx: idx) }
        case .attack:
            if !aiHero.isDead { forceAttack(aiHero) }
        case .leave:
            mpDisconnected()
        default:
            break
        }
    }
}
