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

    // нэгжүүд
    private var units: [Unit] = []
    private var projectiles: [Projectile] = []
    private var zones: [Zone] = []
    private var strikes: [DelayedStrike] = []
    private var player: Unit!
    private var aiHero: Unit!
    private var pGate: Unit!
    private var eGate: Unit!

    // ухасхийлт (Сүбээдэй)
    private var dashT: CGFloat = 0
    private var dashVec = CGVector.zero
    private var dashDmg: CGFloat = 0
    private var dashHit = Set<Unit>()

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
    private var lowHpFrame: SKShapeNode!
    private var announceQueue: [String] = []
    private var announceBusy = false

    private let hpBarW: CGFloat = 150

    // MARK: - Инициализаци

    init(size: CGSize, heroIndex: Int, difficultyIndex: Int) {
        self.heroIndex = heroIndex
        self.difficultyIndex = min(max(difficultyIndex, 0), GameData.difficulties.count - 1)
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

        announce("Тулаан эхэллээ!")
        announce("Дайсны их хаалгыг нураа!")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        if let v = view { insets = v.safeAreaInsets }
        layout()
    }

    // MARK: - Арын дэвсгэр

    private func buildBackground() {
        let sky = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.17, green: 0.24, blue: 0.40, alpha: 1),
                     UIColor(red: 0.54, green: 0.42, blue: 0.29, alpha: 1),
                     UIColor(red: 0.79, green: 0.58, blue: 0.36, alpha: 1)]))
        sky.zPosition = -1000
        addChild(sky)
        skySprite = sky

        let sun = SKNode()
        let core = SKShapeNode(circleOfRadius: 30)
        core.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.55, alpha: 0.9)
        core.strokeColor = .clear
        sun.addChild(core)
        let halo = SKShapeNode(circleOfRadius: 52)
        halo.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.55, alpha: 0.25)
        halo.strokeColor = .clear
        sun.addChild(halo)
        sun.zPosition = -990
        addChild(sun)
        sunNode = sun

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
            units.append(s)
        }

        // тоглогчийн баатар — мастерийн од бүр +3% амь, хүч
        let def = GameData.heroes[heroIndex]
        player = Unit(kind: .hero, team: .mongol, displayName: def.name,
                      radius: 20, hp: def.hp, dmg: def.dmg, range: def.range,
                      atkCd: def.atkCd, moveSpeed: def.speed, aggro: 320, heroDef: def)
        let mastery = Progress.mastery(def.id)
        if mastery > 0 {
            player.maxHp = (def.hp * (1 + 0.03 * CGFloat(mastery))).rounded()
            player.hp = player.maxHp
            player.dmg = (def.dmg * (1 + 0.03 * CGFloat(mastery))).rounded()
            player.updateBars()
        }
        player.position = CGPoint(x: World.pGateX + 130, y: World.laneY)
        world.addChild(player)
        units.append(player)

        // дайсны баатар (AI) — хэцүү байдлаар хүчийг тохируулна
        let jd = GameData.jalal
        aiHero = Unit(kind: .hero, team: .khwarezm, displayName: jd.name,
                      radius: 20, hp: (jd.hp * diff.heroHp).rounded(),
                      dmg: (jd.dmg * diff.heroDmg).rounded(), range: jd.range,
                      atkCd: jd.atkCd, moveSpeed: jd.speed, aggro: 320, heroDef: jd)
        aiHero.position = CGPoint(x: World.eGateX - 130, y: World.laneY)
        world.addChild(aiHero)
        units.append(aiHero)

        camX = 0
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
        // Монгол гэрүүд (өөрийн талд, замын ард)
        addGer(x: 210, y: 545, scale: 1.15)
        addGer(x: 340, y: 565, scale: 0.85)
        // Дайсны майхан
        addTent(x: 2760, y: 550, scale: 1.1)
        addTent(x: 2650, y: 568, scale: 0.85)
    }

    private func addGer(x: CGFloat, y: CGFloat, scale s: CGFloat) {
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

        let door = SKSpriteNode(color: SKColor(red: 0.72, green: 0.27, blue: 0.16, alpha: 1),
                                size: CGSize(width: 16 * s, height: 16 * s))
        door.position = CGPoint(x: 0, y: -wallH / 2 + 8 * s)
        ger.addChild(door)

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

        // зарлал
        announceLabel = UIFactory.label("", font: Fonts.heavy, size: 24, color: Palette.goldLight)
        announceLabel.alpha = 0
        hud.addChild(announceLabel)

        // чадварын товчнууд
        let b2 = SkillButton(skill: def.s2, radius: 30)
        let b1 = SkillButton(skill: def.s1, radius: 38)
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
        muteButton.position = CGPoint(x: size.width - 30 - insets.right, y: size.height - 28 - insets.top)
        announceLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)

        let bx = size.width - 60 - insets.right
        let by = 64 + insets.bottom
        if skillButtons.count == 2 {
            skillButtons[0].position = CGPoint(x: bx, y: by)
            skillButtons[1].position = CGPoint(x: bx - 88, y: by - 6)
        }

        respawnDim.size = size
        respawnDim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        respawnLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)

        lowHpFrame.path = UIBezierPath(
            roundedRect: CGRect(x: 4, y: 4, width: size.width - 8, height: size.height - 8),
            cornerRadius: 12).cgPath
    }

    // MARK: - Давалгаа

    private func spawnWave() {
        waveNum += 1
        let hp = 300 + CGFloat(waveNum) * 14
        let dmg = 27 + CGFloat(waveNum) * 1.5

        for team in [Team.mongol, Team.khwarezm] {
            let gate: Unit = team == .mongol ? pGate : eGate
            let dir: CGFloat = team == .mongol ? 1 : -1
            let mHp = team == .khwarezm ? hp * diff.minionHp : hp
            let mDmg = team == .khwarezm ? dmg * diff.minionDmg : dmg
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
                units.append(m)
            }
        }
        // 5 давалгаа тутамд аварга дайчин
        if waveNum % 5 == 0 {
            let bhp = (1100 + CGFloat(waveNum) * 45) * diff.minionHp
            let b = Unit(kind: .minion, team: .khwarezm, displayName: "Аварга дайчин",
                         radius: 26, hp: bhp,
                         dmg: (55 + CGFloat(waveNum) * 2) * diff.minionDmg,
                         range: 52, atkCd: 1.2, moveSpeed: 78, aggro: 320, boss: true)
            b.position = CGPoint(x: eGate.position.x - 90, y: World.laneY)
            b.face = -1
            world.addChild(b)
            units.append(b)
            announce("Аварга дайчин ирлээ!")
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
                announce("Дайсны баатрыг унагалаа!")
                u.respawnT = 9 + min(matchTime / 60, 8)
            } else {
                announce("Та унасан байна...")
                u.respawnT = 6 + CGFloat(player.level) * 1.2
            }

        case .tower:
            Haptics.crash()
            Audio.shared.play("crash", volume: 1)
            shakeT = max(shakeT, 0.55)
            announce(u.team == .khwarezm ? "Дайсны цамхаг нурлаа!" : "Манай цамхаг нурлаа!")
            if u.team == .khwarezm && byPlayer { giveXP(160); matchGold += 20 }
            u.removeFromParent()

        case .gate:
            Haptics.crash()
            Audio.shared.play("crash", volume: 1)
            shakeT = max(shakeT, 0.7)
            endMatch(win: u.team == .khwarezm)
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
            slashFx(at: CGPoint(x: u.position.x + u.face * u.radius, y: u.position.y), face: u.face,
                    color: u.team == .khwarezm
                        ? SKColor(red: 1.0, green: 0.62, blue: 0.54, alpha: 1)
                        : SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1))
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
        guard player.level < World.maxLevel else { return }
        player.xp += n
        var need = World.xpNeed(player.level)
        while player.xp >= need && player.level < World.maxLevel {
            player.xp -= need
            player.level += 1
            player.maxHp = (player.maxHp * 1.13).rounded()
            player.dmg = (player.dmg * 1.11).rounded()
            player.hp = min(player.maxHp, player.hp + player.maxHp * 0.35)
            player.updateBars()
            burst(at: player.position, color: Palette.xpBlue, count: 22)
            announce("Түвшин \(player.level) боллоо!")
            Haptics.levelUp()
            Audio.shared.play("level", volume: 0.7)
            need = World.xpNeed(player.level)
        }
    }

    // MARK: - Чадварууд

    private func useSkill(_ idx: Int) {
        guard !ended, let def = player.heroDef, !player.isDead, player.stun <= 0 else { return }
        let cd = idx == 0 ? def.s1.cd : def.s2.cd
        if idx == 0 { guard player.s1T <= 0 else { return }; player.s1T = cd }
        else        { guard player.s2T <= 0 else { return }; player.s2T = cd }
        Haptics.skill()
        Audio.shared.play("skill", volume: 0.6)
        let lvl = CGFloat(player.level)

        switch def.id {
        case "chinggis":
            if idx == 0 {
                // Сэлмийн хуй — том хүчирхэг тойрсон цохилт (премиум)
                let radius: CGFloat = 170
                ringFx(at: player.position, radius: radius,
                       color: SKColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1))
                for e in units where !e.isDead && e.team != player.team {
                    if player.position.distance(to: e.position) < radius + e.radius {
                        dealDamage(to: e, amount: player.dmg * 1.8 + lvl * 10, from: player)
                    }
                }
            } else {
                // Тэнгэрийн ивээл — их эдгэрэлт + урт хурд
                Audio.shared.play("heal", volume: 0.7)
                player.hp = min(player.maxHp, player.hp + player.maxHp * 0.35)
                player.hasteT = 4
                player.updateBars()
                for _ in 0..<14 {
                    let spark = SKShapeNode(circleOfRadius: 3)
                    spark.fillColor = SKColor(red: 0.66, green: 0.91, blue: 0.69, alpha: 1)
                    spark.strokeColor = .clear
                    spark.position = CGPoint(x: player.position.x + .random(in: -30...30),
                                             y: player.position.y + .random(in: -20...20))
                    spark.zPosition = 700
                    world.addChild(spark)
                    spark.run(.sequence([
                        .group([.moveBy(x: 0, y: 60, duration: 0.9), .fadeOut(withDuration: 0.9)]),
                        .removeFromParent()
                    ]))
                }
            }

        case "temuujin":
            if idx == 0 {
                // Хурц сэлэм — урд талын цавчилт
                let center = CGPoint(x: player.position.x + player.face * 80, y: player.position.y)
                ringFx(at: center, radius: 100,
                       color: SKColor(red: 1.0, green: 0.85, blue: 0.66, alpha: 1))
                for e in units where !e.isDead && e.team != player.team {
                    if center.distance(to: e.position) < 100 + e.radius {
                        dealDamage(to: e, amount: player.dmg * 1.5 + lvl * 7, from: player)
                    }
                }
            } else {
                // Өсөх хүч — дунд зэргийн эдгэрэлт
                Audio.shared.play("heal", volume: 0.6)
                player.hp = min(player.maxHp, player.hp + player.maxHp * 0.25)
                player.updateBars()
                for _ in 0..<10 {
                    let spark = SKShapeNode(circleOfRadius: 3)
                    spark.fillColor = SKColor(red: 0.78, green: 0.91, blue: 0.63, alpha: 1)
                    spark.strokeColor = .clear
                    spark.position = CGPoint(x: player.position.x + .random(in: -25...25),
                                             y: player.position.y + .random(in: -18...18))
                    spark.zPosition = 700
                    world.addChild(spark)
                    spark.run(.sequence([
                        .group([.moveBy(x: 0, y: 55, duration: 0.8), .fadeOut(withDuration: 0.8)]),
                        .removeFromParent()
                    ]))
                }
            }

        case "zev":
            if idx == 0 {
                // Нэвтлэх сум
                let t = findTarget(for: player, maxDist: 600, unitsOnly: false)
                let dir: CGFloat
                if let t = t {
                    dir = angle(dx: t.position.x - player.position.x, dy: t.position.y - player.position.y)
                } else {
                    dir = player.face > 0 ? 0 : .pi
                }
                let p = Projectile(from: CGPoint(x: player.position.x, y: player.position.y + 14),
                                   dmg: player.dmg * 2 + lvl * 10, team: .mongol,
                                   owner: player, pierce: true, life: 1.1)
                p.velocity = CGVector(dx: cosF(dir) * 680, dy: sinF(dir) * 680)
                world.addChild(p.node)
                projectiles.append(p)
            } else {
                // Сумны бороо
                let t = findTarget(for: player, maxDist: 520, unitsOnly: true)
                    ?? findTarget(for: player, maxDist: 520, unitsOnly: false)
                let cx = t?.position.x ?? (player.position.x + player.face * 220)
                let cy = t?.position.y ?? player.position.y
                let z = Zone(center: CGPoint(x: cx, y: cy), r: 130, delay: 0.7,
                             dmg: player.dmg * 1.7 + lvl * 9, team: .mongol, owner: player)
                world.addChild(z.node)
                zones.append(z)
            }

        case "subedei":
            if idx == 0 {
                // Шуурган довтолгоо
                let t = findTarget(for: player, maxDist: 420, unitsOnly: true)
                let dir: CGFloat
                if let t = t {
                    dir = angle(dx: t.position.x - player.position.x, dy: t.position.y - player.position.y)
                } else {
                    dir = player.face > 0 ? 0 : .pi
                }
                dashT = 0.28
                dashVec = CGVector(dx: cosF(dir) * 880, dy: sinF(dir) * 880)
                dashDmg = player.dmg * 1.3 + lvl * 7
                dashHit.removeAll()
            } else {
                // Төмөр бамбай
                player.shield = 320 + lvl * 45
                player.shieldT = 5
            }

        case "mukhulai":
            if idx == 0 {
                // Газар доргилт — тойрсон цохилт + зогсоолт
                let radius: CGFloat = 130
                ringFx(at: player.position, radius: radius,
                       color: SKColor(red: 0.91, green: 0.71, blue: 0.42, alpha: 1))
                for e in units where !e.isDead && e.team != player.team {
                    if player.position.distance(to: e.position) < radius + e.radius {
                        dealDamage(to: e, amount: player.dmg * 1.3 + lvl * 7, from: player)
                        if e.kind != .tower && e.kind != .gate { e.stun = max(e.stun, 0.7) }
                    }
                }
            } else {
                // Тугийн уриа — довтолгооны хүч нэмэгдэнэ
                player.rageT = 5
                floater("Уриа!", at: player.position, dy: player.radius + 26,
                        color: SKColor(red: 1.0, green: 0.62, blue: 0.29, alpha: 1))
                ringFx(at: player.position, radius: 90,
                       color: SKColor(red: 1.0, green: 0.62, blue: 0.29, alpha: 1))
            }

        case "boorchi":
            if idx == 0 {
                // Шуурхай цохилт — гурван даралт; бай олдохгүй бол cd буцаана
                guard let t = findTarget(for: player, maxDist: 150, unitsOnly: true) else {
                    player.s1T = 0
                    return
                }
                let hitDmg = player.dmg * 0.7 + lvl * 4
                for k in 0..<3 {
                    strikes.append(DelayedStrike(t: CGFloat(k) * 0.13, target: t,
                                                 dmg: hitDmg, from: player))
                }
            } else {
                // Салхины хөл — хурд + гайхшрал арилгана
                player.hasteT = 4
                player.stun = 0
                floater("Салхи!", at: player.position, dy: player.radius + 26,
                        color: SKColor(red: 0.48, green: 0.76, blue: 0.69, alpha: 1))
            }

        case "khasar":
            if idx == 0 {
                // Гурван сум — ойрын 3 дайсан руу; бай олдохгүй бол cd буцаана
                let targets = nearestEnemies(of: player, count: 3, maxDist: 420)
                guard !targets.isEmpty else {
                    player.s1T = 0
                    return
                }
                for t in targets {
                    let p = Projectile(from: CGPoint(x: player.position.x, y: player.position.y + 14),
                                       dmg: player.dmg * 1.2 + lvl * 6, team: .mongol,
                                       owner: player, pierce: false, life: 3)
                    p.target = t
                    world.addChild(p.node)
                    projectiles.append(p)
                }
            } else {
                // Тэнгэрийн нум — харвах хурд ×2
                player.frenzyT = 4
                floater("Тэнгэрийн нум!", at: player.position, dy: player.radius + 26,
                        color: SKColor(red: 0.69, green: 0.52, blue: 0.84, alpha: 1))
            }

        default: break
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
        u.s1T = max(0, u.s1T - dt)

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
        } else if let front = front {
            moveUnit(u, toward: CGPoint(x: front.position.x + 70, y: front.position.y), dt: dt)
        } else {
            moveUnit(u, toward: CGPoint(x: eGate.position.x - 200, y: World.laneY), dt: dt)
        }
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

        // давалгаа
        nextWave -= dt
        if nextWave <= 0 {
            spawnWave()
            nextWave = World.waveInterval
        }

        updatePlayer(dt: dt)

        if !aiHero.isDead {
            updateAI(dt: dt)
            if aiHero.position.distance(to: eGate.position) < 240 {
                aiHero.hp = min(aiHero.maxHp, aiHero.hp + aiHero.maxHp * 0.06 * dt)
                aiHero.updateBars()
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
        if m > 0.15 && player.stun <= 0 && dashT <= 0 {
            let sp = player.moveSpeed * (player.hasteT > 0 ? 1.35 : 1) * min(m, 1)
            player.position.x = clampF(player.position.x + joyVec.dx / m * sp * dt, 30, World.width - 30)
            player.position.y = clampF(player.position.y + joyVec.dy / m * sp * dt,
                                       World.groundBottom, World.groundTop)
            if abs(joyVec.dx) > 0.1 { player.face = joyVec.dx > 0 ? 1 : -1 }
        }

        // ухасхийлт
        if dashT > 0 {
            player.position.x = clampF(player.position.x + dashVec.dx * dt, 30, World.width - 30)
            player.position.y = clampF(player.position.y + dashVec.dy * dt,
                                       World.groundBottom, World.groundTop)
            let trail = SKShapeNode(circleOfRadius: 8)
            trail.fillColor = Palette.shieldBlue.withAlphaComponent(0.5)
            trail.strokeColor = .clear
            trail.position = player.position
            trail.zPosition = 650
            world.addChild(trail)
            trail.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))

            for e in units where !e.isDead && e.team != player.team {
                if e.kind == .tower || e.kind == .gate || dashHit.contains(e) { continue }
                if player.position.distance(to: e.position) < 46 + e.radius {
                    dashHit.insert(e)
                    dealDamage(to: e, amount: dashDmg, from: player)
                    e.stun = max(e.stun, 0.9)
                }
            }
            dashT -= dt
        }

        // автомат довтолгоо
        if player.atkT <= 0 && player.stun <= 0 && dashT <= 0 {
            if let t = findTarget(for: player, maxDist: player.range, unitsOnly: false) {
                performAttack(player, on: t)
            }
        }

        // хаалганы дэргэд эдгэрэх
        if player.position.distance(to: pGate.position) < 240 {
            player.hp = min(player.maxHp, player.hp + player.maxHp * 0.05 * dt)
            player.updateBars()
        }

        player.s1T = max(0, player.s1T - dt)
        player.s2T = max(0, player.s2T - dt)
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
                        u.maxHp = (u.maxHp * 1.1).rounded()
                        u.dmg = (u.dmg * 1.08).rounded()
                        u.hp = u.maxHp
                        u.stun = 0
                        u.position = CGPoint(x: eGate.position.x - 130, y: World.laneY)
                        u.updateBars()
                        burst(at: u.position, color: Palette.enemyRed, count: 16)
                    }
                }
                continue
            }

            u.atkT = max(0, u.atkT - dt)
            u.stun = max(0, u.stun - dt)
            u.hasteT = max(0, u.hasteT - dt)
            u.rageT = max(0, u.rageT - dt)
            u.frenzyT = max(0, u.frenzyT - dt)
            if u.shieldT > 0 {
                u.shieldT -= dt
                if u.shieldT <= 0 { u.shield = 0 }
            }

            if u.kind == .minion && u.stun <= 0 {
                if let t = findTarget(for: u, maxDist: u.aggro, unitsOnly: false) {
                    let d = u.position.distance(to: t.position)
                    if d <= u.range + t.radius {
                        if u.atkT <= 0 { performAttack(u, on: t) }
                    } else {
                        moveUnit(u, toward: t.position, dt: dt)
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
        if skillButtons.count == 2 {
            skillButtons[0].setCooldown(player.s1T)
            skillButtons[1].setCooldown(player.s2T)
        }
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
        world.addChild(l)
        l.run(.sequence([
            .group([.moveBy(x: 0, y: 40, duration: 0.9), .fadeOut(withDuration: 0.9)]),
            .removeFromParent()
        ]))
    }

    private func burst(at pos: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let s = CGFloat.random(in: 60...200)
            let dot = SKShapeNode(circleOfRadius: .random(in: 2...5))
            dot.fillColor = color
            dot.strokeColor = .clear
            dot.position = pos
            dot.zPosition = 750
            world.addChild(dot)
            let dur = Double.random(in: 0.4...0.8)
            dot.run(.sequence([
                .group([.moveBy(x: cosF(a) * s * 0.6, y: sinF(a) * s * 0.6, duration: dur),
                        .fadeOut(withDuration: dur)]),
                .removeFromParent()
            ]))
        }
    }

    private func ringFx(at pos: CGPoint, radius: CGFloat, color: SKColor) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.strokeColor = color
        ring.lineWidth = 5
        ring.fillColor = .clear
        ring.yScale = 0.55
        ring.position = pos
        ring.zPosition = 700
        ring.setScale(0.15)
        ring.yScale = 0.15 * 0.55
        world.addChild(ring)
        ring.run(.sequence([
            .group([.scaleX(to: 1, y: 0.55, duration: 0.3), .fadeOut(withDuration: 0.32)]),
            .removeFromParent()
        ]))
    }

    private func slashFx(at pos: CGPoint, face: CGFloat, color: SKColor) {
        let start: CGFloat = face > 0 ? -1 : .pi - 1
        let end: CGFloat = face > 0 ? 1 : .pi + 1
        let path = UIBezierPath(arcCenter: .zero, radius: 26,
                                startAngle: start, endAngle: end, clockwise: true)
        let arc = SKShapeNode(path: path.cgPath)
        arc.strokeColor = color
        arc.lineWidth = 4
        arc.fillColor = .clear
        arc.position = pos
        arc.zPosition = 700
        world.addChild(arc)
        arc.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
    }

    // MARK: - Тоглоомын төгсгөл

    private func endMatch(win: Bool) {
        guard !ended else { return }
        ended = true
        if win { Haptics.victory() } else { Haptics.defeat() }
        Audio.shared.play(win ? "win" : "lose", volume: 0.9)

        // шагнал: тулааны алт + түвшин + ялалтын урамшуулал, хэцүү байдлаар үржүүлнэ
        let heroId = GameData.heroes[heroIndex].id
        let chaptersBefore = Set(GameData.chapters.filter { $0.req.isMet }.map { $0.id })
        let earned = Int(((CGFloat(matchGold) + CGFloat(player.level) * 5 + (win ? 80 : 20))
                          * diff.goldMult).rounded())
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

        let stats = MatchStats(win: win, kills: kills, level: player.level,
                               seconds: Int(matchTime), heroIndex: heroIndex,
                               difficultyIndex: difficultyIndex,
                               goldEarned: earned, totalGold: Progress.gold,
                               masteryStars: Progress.mastery(heroId), gainedStar: gainedStar,
                               newChapter: newChapter)
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
        for t in touches where t === joyTouch {
            joyTouch = nil
            joyVec = .zero
            joyBase.isHidden = true
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
}
