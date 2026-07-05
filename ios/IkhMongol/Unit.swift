import SpriteKit

/// Тулааны нэгж: цэрэг, баатар, цамхаг, их хаалга
final class Unit: SKNode {

    let kind: UnitKind
    let team: Team
    let radius: CGFloat
    let displayName: String
    let isBoss: Bool
    var isNpc = false          // аврах NPC (Бөртэ) — дагадаг, дайсан онилно
    var freed = false          // NPC чөлөөлөгдсөн эсэх

    var maxHp: CGFloat
    var hp: CGFloat
    var dmg: CGFloat
    var range: CGFloat
    var atkCd: CGFloat
    var atkT: CGFloat = 0
    var moveSpeed: CGFloat
    var aggro: CGFloat
    var archer = false

    var face: CGFloat = 1 {
        didSet { front?.xScale = face }
    }
    var stun: CGFloat = 0 {
        didSet { stunLabel?.isHidden = stun <= 0 }
    }
    var shield: CGFloat = 0 {
        didSet {
            shieldRing?.isHidden = shield <= 0
            updateBars()
        }
    }
    var shieldT: CGFloat = 0
    var hasteT: CGFloat = 0
    var rageT: CGFloat = 0      // Тугийн уриа — довтолгооны хүч ×1.45
    var frenzyT: CGFloat = 0    // Тэнгэрийн нум — харвах хурд ×2
    var isDead = false
    var respawnT: CGFloat = 0
    var netId: Int32 = 0        // PvP горимд нэгжийг таних дугаар

    // Ухасхийлт (Сүбээдэй) — нэгж бүрд тусдаа
    var dashT: CGFloat = 0
    var dashVX: CGFloat = 0
    var dashVY: CGFloat = 0
    var dashDmg: CGFloat = 0
    var dashHit = Set<Unit>()

    // Зөвхөн баатарт хамаарах
    var heroDef: HeroDef?
    var level = 1
    var xp: CGFloat = 0
    var s1T: CGFloat = 0
    var s2T: CGFloat = 0

    private var hpFill: SKSpriteNode?
    private var shieldFill: SKSpriteNode?
    private var front: SKNode?
    private var shieldRing: SKShapeNode?
    private var stunLabel: SKLabelNode?
    private var barWidth: CGFloat = 36

    // MARK: - Инициализаци

    init(kind: UnitKind, team: Team, displayName: String = "",
         radius: CGFloat, hp: CGFloat, dmg: CGFloat = 0, range: CGFloat = 0,
         atkCd: CGFloat = 1, moveSpeed: CGFloat = 0, aggro: CGFloat = 270,
         archer: Bool = false, boss: Bool = false, heroDef: HeroDef? = nil) {

        self.kind = kind
        self.team = team
        self.displayName = displayName
        self.isBoss = boss
        self.radius = radius
        self.maxHp = hp
        self.hp = hp
        self.dmg = dmg
        self.range = range
        self.atkCd = atkCd
        self.moveSpeed = moveSpeed
        self.aggro = aggro
        self.archer = archer
        self.heroDef = heroDef

        super.init()

        face = team == .mongol ? 1 : -1
        switch kind {
        case .minion, .hero: buildBody()
        case .tower: buildTower()
        case .gate: buildGate()
        }
        front?.xScale = face
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Цэрэг / баатрын дүрс

    private func buildBody() {
        let r = radius
        let isHero = kind == .hero

        // сүүдэр ба багийн цагираг
        let shadow = SKShapeNode(ellipseOf: CGSize(width: r * 2.2, height: r * 0.9))
        shadow.fillColor = SKColor(white: 0, alpha: 0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -r * 0.75)
        addChild(shadow)

        let ring = SKShapeNode(ellipseOf: CGSize(width: r * 2.3, height: r * 1.0))
        ring.fillColor = .clear
        ring.strokeColor = team.bannerColor
        ring.lineWidth = 2.5
        ring.alpha = 0.8
        ring.position = CGPoint(x: 0, y: -r * 0.75)
        addChild(ring)

        let bodyColor: SKColor
        if isHero {
            bodyColor = heroDef?.color ?? Palette.gold
        } else {
            bodyColor = team == .mongol
                ? SKColor(red: 0.48, green: 0.35, blue: 0.20, alpha: 1)
                : SKColor(red: 0.54, green: 0.27, blue: 0.22, alpha: 1)
        }

        // хөл (SpriteKit-д +y дээшээ)
        let legColor = team == .mongol
            ? SKColor(red: 0.25, green: 0.16, blue: 0.09, alpha: 1)
            : SKColor(red: 0.23, green: 0.14, blue: 0.09, alpha: 1)
        for sx: CGFloat in [-1, 1] {
            let lp = UIBezierPath()
            lp.move(to: CGPoint(x: sx * r * 0.26, y: -r * 0.18))
            lp.addLine(to: CGPoint(x: sx * r * 0.28, y: -r * 0.74))
            let leg = SKShapeNode(path: lp.cgPath)
            leg.strokeColor = legColor
            leg.lineWidth = r * 0.32
            leg.lineCap = .round
            addChild(leg)
        }

        // ар гар
        let backArm = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -face * r * 0.4, y: r * 0.72))
            p.addLine(to: CGPoint(x: -face * r * 0.72, y: r * 0.1))
            return p.cgPath
        }())
        backArm.strokeColor = bodyColor
        backArm.lineWidth = r * 0.28
        backArm.lineCap = .round
        addChild(backArm)

        // их бие (дээл / хуяг)
        let body = SKShapeNode(ellipseOf: CGSize(width: r * 1.32, height: r * 1.44))
        body.fillColor = bodyColor
        body.strokeColor = SKColor(white: 0, alpha: 0.32)
        body.lineWidth = 1.5
        body.position = CGPoint(x: 0, y: r * 0.36)
        addChild(body)
        // гэрэл ба сүүдэр (эзэлхүүн)
        let hi = SKShapeNode(ellipseOf: CGSize(width: r * 0.7, height: r * 0.9))
        hi.fillColor = SKColor(white: 1, alpha: 0.22)
        hi.strokeColor = .clear
        hi.position = CGPoint(x: -r * 0.28, y: r * 0.6)
        addChild(hi)
        // мөр (мөрөвч)
        let shoulder = SKShapeNode(ellipseOf: CGSize(width: r * 1.32, height: r * 0.6))
        shoulder.fillColor = isHero ? SKColor(red: 0.90, green: 0.80, blue: 0.47, alpha: 0.55)
                                    : SKColor(white: 1, alpha: 0.14)
        shoulder.strokeColor = .clear
        shoulder.position = CGPoint(x: 0, y: r * 0.92)
        addChild(shoulder)

        // бүс + товруу
        let belt = SKSpriteNode(color: isHero ? SKColor(red: 0.42, green: 0.27, blue: 0.06, alpha: 1)
                                              : SKColor(red: 0.23, green: 0.15, blue: 0.05, alpha: 0.85),
                                size: CGSize(width: r * 1.28, height: r * 0.22))
        belt.position = CGPoint(x: 0, y: r * 0.2)
        addChild(belt)
        let buckle = SKSpriteNode(color: isHero ? SKColor(red: 0.91, green: 0.76, blue: 0.29, alpha: 1)
                                                : SKColor(red: 0.70, green: 0.59, blue: 0.35, alpha: 0.7),
                                  size: CGSize(width: r * 0.2, height: r * 0.22))
        buckle.position = CGPoint(x: 0, y: r * 0.2)
        addChild(buckle)

        // толгой + царай
        let head = SKShapeNode(circleOfRadius: r * 0.52)
        head.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.47, alpha: 1)
        head.strokeColor = SKColor(white: 0, alpha: 0.22)
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: r * 1.15)
        addChild(head)

        // дуулга
        if team == .mongol {
            // монгол шовгор дуулга
            let dome = SKShapeNode(circleOfRadius: r * 0.58)
            dome.fillColor = isHero ? SKColor(red: 0.85, green: 0.69, blue: 0.28, alpha: 1)
                                    : SKColor(red: 0.54, green: 0.48, blue: 0.35, alpha: 1)
            dome.strokeColor = .clear
            dome.position = CGPoint(x: 0, y: r * 1.32)
            addChild(dome)

            let spikePath = UIBezierPath()
            spikePath.move(to: CGPoint(x: -r * 0.2, y: 0))
            spikePath.addLine(to: CGPoint(x: 0, y: r * 0.62))
            spikePath.addLine(to: CGPoint(x: r * 0.2, y: 0))
            spikePath.close()
            let spike = SKShapeNode(path: spikePath.cgPath)
            spike.fillColor = dome.fillColor
            spike.strokeColor = .clear
            spike.position = CGPoint(x: 0, y: r * 1.68)
            addChild(spike)

            let brim = SKSpriteNode(color: SKColor(red: 0.23, green: 0.16, blue: 0.06, alpha: 1),
                                    size: CGSize(width: r * 1.2, height: r * 0.14))
            brim.position = CGPoint(x: 0, y: r * 1.28)
            addChild(brim)
        } else {
            // дайсны ороолттой дуулга
            let wrap = SKShapeNode(circleOfRadius: r * 0.56)
            wrap.fillColor = heroDef != nil
                ? SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1)
                : SKColor(red: 0.60, green: 0.42, blue: 0.29, alpha: 1)
            wrap.strokeColor = .clear
            wrap.position = CGPoint(x: 0, y: r * 1.35)
            addChild(wrap)

            let band = SKSpriteNode(color: SKColor(white: 0, alpha: 0.25),
                                    size: CGSize(width: r * 1.12, height: r * 0.2))
            band.position = CGPoint(x: 0, y: r * 1.28)
            addChild(band)
        }

        // зэвсэг — эргэх чиглэлтэй хэсэг
        let frontNode = SKNode()
        addChild(frontNode)
        front = frontNode

        if archer || heroDef?.id == "zev" {
            // нум
            let bowPath = UIBezierPath(arcCenter: .zero, radius: r * 0.7,
                                       startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: true)
            let bow = SKShapeNode(path: bowPath.cgPath)
            bow.strokeColor = SKColor(red: 0.48, green: 0.29, blue: 0.13, alpha: 1)
            bow.lineWidth = 3
            bow.fillColor = .clear
            bow.position = CGPoint(x: r * 0.95, y: r * 0.4)
            frontNode.addChild(bow)

            let string = SKShapeNode(rect: CGRect(x: -0.5, y: -r * 0.7, width: 1, height: r * 1.4))
            string.fillColor = SKColor(white: 0.9, alpha: 0.7)
            string.strokeColor = .clear
            string.position = bow.position
            frontNode.addChild(string)
        } else {
            // сэлэм — барих гар, хамгаалалт, гэрэлтэй ир
            let hand = SKShapeNode(path: {
                let p = UIBezierPath()
                p.move(to: CGPoint(x: -r * 0.5, y: r * 0.5))
                p.addLine(to: .zero)
                return p.cgPath
            }())
            hand.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.47, alpha: 1)
            hand.lineWidth = r * 0.24
            hand.lineCap = .round
            hand.position = CGPoint(x: r * 0.9, y: r * 0.3)
            frontNode.addChild(hand)

            let bladePath = UIBezierPath()
            bladePath.move(to: .zero)
            bladePath.addLine(to: CGPoint(x: r * 1.05, y: r * 1.0))
            let blade = SKShapeNode(path: bladePath.cgPath)
            blade.strokeColor = SKColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1)
            blade.lineWidth = 3.5
            blade.lineCap = .round
            blade.position = CGPoint(x: r * 0.9, y: r * 0.3)
            frontNode.addChild(blade)

            let guardPath = UIBezierPath()
            guardPath.move(to: CGPoint(x: -r * 0.12, y: -r * 0.14))
            guardPath.addLine(to: CGPoint(x: r * 0.12, y: r * 0.14))
            let guardN = SKShapeNode(path: guardPath.cgPath)
            guardN.strokeColor = SKColor(red: 0.54, green: 0.42, blue: 0.16, alpha: 1)
            guardN.lineWidth = 3
            guardN.position = CGPoint(x: r * 0.9, y: r * 0.3)
            frontNode.addChild(guardN)
        }

        // бамбайн цагираг
        let sRing = SKShapeNode(circleOfRadius: r * 1.6)
        sRing.strokeColor = Palette.shieldBlue
        sRing.lineWidth = 3
        sRing.fillColor = Palette.shieldBlue.withAlphaComponent(0.08)
        sRing.position = CGPoint(x: 0, y: r * 0.3)
        sRing.isHidden = true
        addChild(sRing)
        shieldRing = sRing

        // гайхшралын тэмдэг
        let stunL = SKLabelNode(text: "✦ ✦")
        stunL.fontName = Fonts.bold
        stunL.fontSize = 14
        stunL.fontColor = SKColor(red: 1.0, green: 0.89, blue: 0.42, alpha: 1)
        stunL.position = CGPoint(x: 0, y: r * 2.35)
        stunL.isHidden = true
        addChild(stunL)
        stunLabel = stunL

        // амийн зурвас
        let big = isHero || isBoss
        barWidth = big ? 52 : 36
        let barY = r * 2.05 + (big ? 12 : 4)
        addBars(width: barWidth, height: big ? 7 : 5, y: barY)

        if big {
            let nameL = SKLabelNode(text: displayName)
            nameL.fontName = Fonts.bold
            nameL.fontSize = 15
            if isBoss {
                nameL.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1)
            } else {
                nameL.fontColor = team == .mongol
                    ? SKColor(red: 0.81, green: 0.91, blue: 1.0, alpha: 1)
                    : SKColor(red: 1.0, green: 0.82, blue: 0.78, alpha: 1)
            }
            nameL.position = CGPoint(x: 0, y: barY + 12)
            addChild(nameL)
        }
    }

    // MARK: - Цамхаг

    private func buildTower() {
        let stone: SKColor = team == .mongol
            ? SKColor(red: 0.54, green: 0.50, blue: 0.44, alpha: 1)
            : SKColor(red: 0.48, green: 0.38, blue: 0.35, alpha: 1)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 104, height: 32))
        shadow.fillColor = SKColor(white: 0, alpha: 0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -30)
        addChild(shadow)

        let bodyNode = SKSpriteNode(color: stone, size: CGSize(width: 60, height: 125))
        bodyNode.position = CGPoint(x: 0, y: 32)
        addChild(bodyNode)

        let shade = SKSpriteNode(color: SKColor(white: 0, alpha: 0.18), size: CGSize(width: 22, height: 125))
        shade.position = CGPoint(x: 19, y: 32)
        addChild(shade)

        for i in -1...1 {
            let merlon = SKSpriteNode(color: stone, size: CGSize(width: 16, height: 18))
            merlon.position = CGPoint(x: CGFloat(i) * 20, y: 103)
            addChild(merlon)
        }

        let pole = SKSpriteNode(color: SKColor(red: 0.23, green: 0.16, blue: 0.06, alpha: 1),
                                size: CGSize(width: 3, height: 38))
        pole.position = CGPoint(x: 0, y: 130)
        addChild(pole)

        let flagPath = UIBezierPath()
        flagPath.move(to: .zero)
        flagPath.addLine(to: CGPoint(x: 30, y: -8))
        flagPath.addLine(to: CGPoint(x: 0, y: -16))
        flagPath.close()
        let flag = SKShapeNode(path: flagPath.cgPath)
        flag.fillColor = team.bannerColor
        flag.strokeColor = .clear
        flag.position = CGPoint(x: 0, y: 150)
        addChild(flag)

        barWidth = 84
        addBars(width: barWidth, height: 9, y: 168)
        addStructName(y: 182)
    }

    // MARK: - Их хаалга

    private func buildGate() {
        let stone: SKColor = team == .mongol
            ? SKColor(red: 0.54, green: 0.50, blue: 0.44, alpha: 1)
            : SKColor(red: 0.48, green: 0.38, blue: 0.35, alpha: 1)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 160, height: 40))
        shadow.fillColor = SKColor(white: 0, alpha: 0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -34)
        addChild(shadow)

        let wall = SKSpriteNode(color: stone, size: CGSize(width: 144, height: 145))
        wall.position = CGPoint(x: 0, y: 38)
        addChild(wall)

        let shade = SKSpriteNode(color: SKColor(white: 0, alpha: 0.18), size: CGSize(width: 52, height: 145))
        shade.position = CGPoint(x: 46, y: 38)
        addChild(shade)

        for i in -3...3 {
            let merlon = SKSpriteNode(color: stone, size: CGSize(width: 16, height: 20))
            merlon.position = CGPoint(x: CGFloat(i) * 20, y: 120)
            addChild(merlon)
        }

        // нуман хаалга
        let doorPath = UIBezierPath()
        doorPath.move(to: CGPoint(x: -34, y: -34))
        doorPath.addLine(to: CGPoint(x: -34, y: 40))
        doorPath.addArc(withCenter: CGPoint(x: 0, y: 40), radius: 34,
                        startAngle: .pi, endAngle: 0, clockwise: true)
        doorPath.addLine(to: CGPoint(x: 34, y: -34))
        doorPath.close()
        let door = SKShapeNode(path: doorPath.cgPath)
        door.fillColor = SKColor(red: 0.29, green: 0.19, blue: 0.09, alpha: 1)
        door.strokeColor = SKColor(red: 0.16, green: 0.10, blue: 0.03, alpha: 1)
        door.lineWidth = 2
        addChild(door)

        let seam = SKSpriteNode(color: SKColor(red: 0.16, green: 0.10, blue: 0.03, alpha: 1),
                                size: CGSize(width: 2, height: 106))
        seam.position = CGPoint(x: 0, y: 18)
        addChild(seam)

        // хос туг
        for side: CGFloat in [-1, 1] {
            let pole = SKSpriteNode(color: SKColor(red: 0.23, green: 0.16, blue: 0.06, alpha: 1),
                                    size: CGSize(width: 3, height: 40))
            pole.position = CGPoint(x: side * 58, y: 148)
            addChild(pole)

            let flagPath = UIBezierPath()
            flagPath.move(to: .zero)
            flagPath.addLine(to: CGPoint(x: 26, y: -8))
            flagPath.addLine(to: CGPoint(x: 0, y: -16))
            flagPath.close()
            let flag = SKShapeNode(path: flagPath.cgPath)
            flag.fillColor = team.bannerColor
            flag.strokeColor = .clear
            flag.position = CGPoint(x: side * 58, y: 168)
            addChild(flag)
        }

        barWidth = 130
        addBars(width: barWidth, height: 9, y: 190)
        addStructName(y: 204)
    }

    // MARK: - Амийн зурвас

    private func addBars(width: CGFloat, height: CGFloat, y: CGFloat) {
        let bg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.6),
                              size: CGSize(width: width + 2, height: height + 2))
        bg.position = CGPoint(x: 0, y: y)
        bg.zPosition = 5
        addChild(bg)

        let fill = SKSpriteNode(color: team.hpColor, size: CGSize(width: width, height: height))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -width / 2, y: y)
        fill.zPosition = 6
        addChild(fill)
        hpFill = fill

        let sFill = SKSpriteNode(color: Palette.shieldBlue,
                                 size: CGSize(width: width, height: max(2.5, height * 0.4)))
        sFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        sFill.position = CGPoint(x: -width / 2, y: y + height / 2 + 2.5)
        sFill.zPosition = 6
        sFill.xScale = 0
        addChild(sFill)
        shieldFill = sFill
    }

    private func addStructName(y: CGFloat) {
        let nameL = SKLabelNode(text: displayName)
        nameL.fontName = Fonts.bold
        nameL.fontSize = 15
        nameL.fontColor = Palette.parchment
        nameL.position = CGPoint(x: 0, y: y)
        nameL.zPosition = 6
        addChild(nameL)
    }

    func updateBars() {
        hpFill?.xScale = clampF(hp / maxHp, 0, 1)
        shieldFill?.xScale = clampF(shield / maxHp, 0, 1)
    }

    /// Хохирол авах үеийн цайвар гэрэлтэлт
    func flashHit() {
        guard kind == .minion || kind == .hero else { return }
        let r = radius
        let flash = SKShapeNode(ellipseOf: CGSize(width: r * 1.4, height: r * 1.7))
        flash.fillColor = SKColor(white: 1, alpha: 0.7)
        flash.strokeColor = .clear
        flash.position = CGPoint(x: 0, y: r * 0.5)
        flash.zPosition = 20
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.14), .removeFromParent()]))
    }

    /// Зэвсгээ хийсгэх цохилтын хөдөлгөөн
    func swingWeapon() {
        guard let f = front else { return }
        f.removeAction(forKey: "swing")
        let swing = SKAction.sequence([
            .rotate(toAngle: -face * 0.7, duration: 0.06, shortestUnitArc: true),
            .rotate(toAngle: 0, duration: 0.16, shortestUnitArc: true)
        ])
        f.run(swing, withKey: "swing")
    }
}
