import SpriteKit

// ======================================================================
//  ХАР ХОРУМ — walkable төв хот (MMO-lite lobby). Тоглогч эндээс төрж,
//  түүхэн даалгавар авч, зэрэг ахьж, зэвсэг олж, багаа бүрдүүлээд дараагийн
//  эзлэлт рүү мордоно. Жинхэнэ онлайн «бусад тоглогчтой уулзах» нь ирээдүйн
//  netcode зам; энэ бол ганц тоглогчийн бүрхүүл.
// ======================================================================

final class HubScene: SKScene {

    private let hubW: CGFloat = 2400
    private let cam = SKCameraNode()

    private var built = false
    private var heroNode = SKNode()
    private var heroPos = CGPoint(x: 360, y: 0)
    private var heroFace: CGFloat = 1
    private var stepT: CGFloat = 0
    private var lastTime: TimeInterval = 0

    private var joyVec = CGPoint.zero
    private var joyTouch: UITouch?
    private var joyKnob: SKShapeNode?
    private let joyRadius: CGFloat = 46

    private struct Building { let id: String; let x: CGFloat; let label: String; let icon: String; let prompt: String? }
    private var buildings: [Building] = []
    private var nearId: String?
    private var promptNode: SKNode?
    private var promptLabel: SKLabelNode?

    private var panel: SKNode?
    private var dragTouch: UITouch?
    private var dragMoved = false

    // байршил (дэлгэцийн өндрөөр)
    private var groundLine: CGFloat { size.height * 0.5 }
    private var walkBottom: CGFloat { size.height * 0.14 }
    private var walkTop: CGFloat { size.height * 0.45 }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        HubContext.activeQuest = nil          // төв хотод буцаж ирэв
        heroPos.y = (walkBottom + walkTop) / 2
        Audio.shared.startMusic()
        buildScene()
        built = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        heroPos.y = clampF(heroPos.y, walkBottom, walkTop)
        closePanel()
        buildScene()
    }

    // MARK: - Дүр зураг байгуулах

    private func buildScene() {
        removeAllChildren()
        camera = cam
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)

        // тэнгэр
        let sky = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [SKColor(red: 0.13, green: 0.20, blue: 0.37, alpha: 1),
                     SKColor(red: 0.29, green: 0.41, blue: 0.60, alpha: 1),
                     SKColor(red: 0.79, green: 0.65, blue: 0.42, alpha: 1)]),
            size: CGSize(width: hubW, height: size.height * 0.55))
        sky.position = CGPoint(x: hubW / 2, y: size.height * 0.725)
        sky.zPosition = -20
        addChild(sky)

        // алс уул
        let hill = SKShapeNode(rectOf: CGSize(width: hubW, height: 90))
        hill.fillColor = SKColor(red: 0.30, green: 0.34, blue: 0.24, alpha: 1)
        hill.strokeColor = .clear
        hill.position = CGPoint(x: hubW / 2, y: groundLine + 30)
        hill.zPosition = -15
        addChild(hill)

        // газар
        let ground = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [SKColor(red: 0.42, green: 0.47, blue: 0.24, alpha: 1),
                     SKColor(red: 0.28, green: 0.32, blue: 0.15, alpha: 1)]),
            size: CGSize(width: hubW, height: groundLine + 20))
        ground.position = CGPoint(x: hubW / 2, y: (groundLine + 20) / 2)
        ground.zPosition = -14
        addChild(ground)

        // хотын гол зам
        let road = SKSpriteNode(color: SKColor(red: 0.60, green: 0.49, blue: 0.31, alpha: 0.4),
                                size: CGSize(width: hubW, height: walkTop - walkBottom + 30))
        road.position = CGPoint(x: hubW / 2, y: (walkBottom + walkTop) / 2)
        road.zPosition = -13
        addChild(road)

        // барилгууд
        buildings = [
            Building(id: "quest",  x: 520,  label: "Зарлигийн самбар", icon: "📜", prompt: "Даалгавар авах"),
            Building(id: "party",  x: 880,  label: "Нөхдийн өргөө",    icon: "🤝", prompt: "Багаа бүрдүүлэх"),
            Building(id: "palace", x: 1240, label: "Тумэн амгалант ордон", icon: "🏯", prompt: nil),
            Building(id: "shop",   x: 1600, label: "Дархны газар",     icon: "⚒️", prompt: "Зэвсэг авах"),
            Building(id: "camp",   x: 1950, label: "Буурь",            icon: "🏕️", prompt: "Адуу малла")
        ]
        for b in buildings { addBuilding(b) }

        // хотын иргэд
        for (i, bx) in [640, 1080, 1420, 1760].enumerated() {
            addTownsfolk(x: CGFloat(bx), idx: i)
        }

        // баатар
        heroNode = buildHubHero()
        heroNode.position = heroPos
        heroNode.zPosition = 100 - heroPos.y
        addChild(heroNode)

        buildHUD()
        updateNear()
    }

    private func addBuilding(_ b: Building) {
        let node = SKNode()
        node.position = CGPoint(x: b.x, y: groundLine)
        node.zPosition = 100 - groundLine
        addChild(node)

        // сүүдэр
        let sh = SKShapeNode(ellipseOf: CGSize(width: 110, height: 28))
        sh.fillColor = SKColor(white: 0, alpha: 0.22); sh.strokeColor = .clear
        sh.position = CGPoint(x: 0, y: -6); node.addChild(sh)

        switch b.id {
        case "quest":
            for sx: CGFloat in [-40, 30] {
                let post = SKSpriteNode(color: SKColor(red: 0.35, green: 0.25, blue: 0.13, alpha: 1), size: CGSize(width: 10, height: 90))
                post.position = CGPoint(x: sx + 5, y: 40); node.addChild(post)
            }
            let board = SKSpriteNode(color: SKColor(red: 0.48, green: 0.35, blue: 0.20, alpha: 1), size: CGSize(width: 92, height: 52))
            board.position = CGPoint(x: 0, y: 78); node.addChild(board)
            let paper = SKSpriteNode(color: SKColor(red: 0.94, green: 0.89, blue: 0.78, alpha: 1), size: CGSize(width: 80, height: 40))
            paper.position = CGPoint(x: 0, y: 78); node.addChild(paper)
        case "party":
            addGerShape(to: node, scale: 1.5, banner: SKColor(red: 0.18, green: 0.43, blue: 0.37, alpha: 1))
            let pole = SKSpriteNode(color: SKColor(red: 0.35, green: 0.25, blue: 0.13, alpha: 1), size: CGSize(width: 3, height: 70))
            pole.position = CGPoint(x: 58, y: 40); node.addChild(pole)
            let flag = triangle(w: 34, h: 18, color: SKColor(red: 0.18, green: 0.43, blue: 0.37, alpha: 1))
            flag.position = CGPoint(x: 74, y: 66); node.addChild(flag)
        case "palace":
            let baseP = SKSpriteNode(color: SKColor(red: 0.42, green: 0.31, blue: 0.19, alpha: 1), size: CGSize(width: 180, height: 26))
            baseP.position = CGPoint(x: 0, y: 14); node.addChild(baseP)
            let hall = SKSpriteNode(color: SKColor(red: 0.54, green: 0.23, blue: 0.16, alpha: 1), size: CGSize(width: 156, height: 54))
            hall.position = CGPoint(x: 0, y: 50); node.addChild(hall)
            for t in 0..<3 {
                let w = 188 - CGFloat(t) * 52
                let roof = SKShapeNode(rectOf: CGSize(width: w, height: 14), cornerRadius: 6)
                roof.fillColor = t == 2 ? SKColor(red: 0.95, green: 0.79, blue: 0.42, alpha: 1)
                                        : SKColor(red: 0.85, green: 0.66, blue: 0.24, alpha: 1)
                roof.strokeColor = .clear
                roof.position = CGPoint(x: 0, y: 78 + CGFloat(t) * 20); node.addChild(roof)
            }
            let finial = SKShapeNode(circleOfRadius: 6)
            finial.fillColor = SKColor(red: 0.95, green: 0.79, blue: 0.42, alpha: 1); finial.strokeColor = .clear
            finial.position = CGPoint(x: 0, y: 150); node.addChild(finial)
        case "shop":
            let house = SKSpriteNode(color: SKColor(red: 0.36, green: 0.32, blue: 0.28, alpha: 1), size: CGSize(width: 84, height: 64))
            house.position = CGPoint(x: 0, y: 34); node.addChild(house)
            let roof = triangle(w: 100, h: 30, color: SKColor(red: 0.25, green: 0.22, blue: 0.19, alpha: 1))
            roof.position = CGPoint(x: 0, y: 66); node.addChild(roof)
            let forge = SKShapeNode(circleOfRadius: 20)
            forge.fillColor = SKColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 0.85); forge.strokeColor = .clear
            forge.position = CGPoint(x: -14, y: 28); node.addChild(forge)
            forge.run(.repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 0.5), .fadeAlpha(to: 0.85, duration: 0.5)])))
            let door = SKSpriteNode(color: SKColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1), size: CGSize(width: 24, height: 22))
            door.position = CGPoint(x: -14, y: 24); node.addChild(door)
        case "camp":
            addGerShape(to: node, scale: 0.95, banner: SKColor(red: 0.72, green: 0.27, blue: 0.16, alpha: 1))
        default: break
        }

        // нэрийн хаяг
        let tag = SKNode()
        let labelText = "\(b.icon) \(b.label)"
        let l = UIFactory.label(labelText, font: Fonts.bold, size: 12,
                                color: SKColor(red: 0.91, green: 0.85, blue: 0.69, alpha: 1))
        let bgW = l.frame.width + 16
        let bg = SKShapeNode(rectOf: CGSize(width: bgW, height: 22), cornerRadius: 6)
        bg.fillColor = SKColor(red: 0.08, green: 0.055, blue: 0.024, alpha: 0.72); bg.strokeColor = .clear
        tag.addChild(bg); tag.addChild(l)
        tag.position = CGPoint(x: 0, y: b.id == "palace" ? 176 : 118)
        tag.name = "tag_\(b.id)"
        node.addChild(tag)
    }

    private func addGerShape(to node: SKNode, scale s: CGFloat, banner: SKColor) {
        let w = 44 * s
        let wall = SKSpriteNode(color: SKColor(red: 0.94, green: 0.91, blue: 0.84, alpha: 1),
                                size: CGSize(width: w * 2, height: 18 * s))
        wall.position = CGPoint(x: 0, y: 18 * s); node.addChild(wall)
        let dome = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -w, y: 27 * s))
            p.addQuadCurve(to: CGPoint(x: w, y: 27 * s), controlPoint: CGPoint(x: 0, y: 27 * s + 30 * s))
            p.close(); return p.cgPath }())
        dome.fillColor = SKColor(red: 0.94, green: 0.91, blue: 0.84, alpha: 1); dome.strokeColor = .clear
        node.addChild(dome)
        let door = SKSpriteNode(color: banner, size: CGSize(width: 18 * s, height: 18 * s))
        door.position = CGPoint(x: 0, y: 16 * s); node.addChild(door)
    }

    private func triangle(w: CGFloat, h: CGFloat, color: SKColor) -> SKShapeNode {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: -w / 2, y: 0)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: w / 2, y: 0)); p.close()
        let s = SKShapeNode(path: p.cgPath); s.fillColor = color; s.strokeColor = .clear
        return s
    }

    private func addTownsfolk(x: CGFloat, idx: Int) {
        let colors = [SKColor(red: 0.54, green: 0.42, blue: 0.23, alpha: 1),
                      SKColor(red: 0.42, green: 0.48, blue: 0.29, alpha: 1),
                      SKColor(red: 0.48, green: 0.35, blue: 0.35, alpha: 1),
                      SKColor(red: 0.35, green: 0.42, blue: 0.48, alpha: 1)]
        let y = walkBottom + 20 + CGFloat((idx * 37) % 60)
        let f = SKNode()
        f.position = CGPoint(x: x, y: y); f.zPosition = 100 - y
        let body = triangle(w: 16, h: 24, color: colors[idx % colors.count])
        f.addChild(body)
        let head = SKShapeNode(circleOfRadius: 6)
        head.fillColor = SKColor(red: 0.90, green: 0.73, blue: 0.54, alpha: 1); head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 30); f.addChild(head)
        f.run(.repeatForever(.sequence([.moveBy(x: 16, y: 0, duration: 2.4), .moveBy(x: -16, y: 0, duration: 2.4)])))
        addChild(f)
    }

    private func buildHubHero() -> SKNode {
        let n = SKNode()
        let sh = SKShapeNode(ellipseOf: CGSize(width: 34, height: 12))
        sh.fillColor = SKColor(white: 0, alpha: 0.25); sh.strokeColor = .clear
        sh.position = CGPoint(x: 0, y: -2); n.addChild(sh)
        let body = triangle(w: 22, h: 32, color: SKColor(red: 0.66, green: 0.46, blue: 0.18, alpha: 1))
        n.addChild(body)
        let belt = SKSpriteNode(color: SKColor(red: 0.35, green: 0.23, blue: 0.09, alpha: 1), size: CGSize(width: 20, height: 5))
        belt.position = CGPoint(x: 0, y: 14); n.addChild(belt)
        let head = SKShapeNode(circleOfRadius: 7)
        head.fillColor = SKColor(red: 0.90, green: 0.73, blue: 0.54, alpha: 1); head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 40); n.addChild(head)
        let helm = SKShapeNode(path: {
            let p = UIBezierPath(); p.addArc(withCenter: .zero, radius: 8, startAngle: 0, endAngle: .pi, clockwise: false); return p.cgPath }())
        helm.fillColor = SKColor(red: 0.54, green: 0.42, blue: 0.16, alpha: 1); helm.strokeColor = .clear
        helm.position = CGPoint(x: 0, y: 43); n.addChild(helm)
        let spike = SKSpriteNode(color: SKColor(red: 0.79, green: 0.63, blue: 0.29, alpha: 1), size: CGSize(width: 2, height: 8))
        spike.position = CGPoint(x: 0, y: 52); n.addChild(spike)
        return n
    }

    // MARK: - HUD (камерт наалдана)

    private func buildHUD() {
        cam.removeAllChildren()
        let halfW = size.width / 2, halfH = size.height / 2
        let insetL: CGFloat = 14, insetT: CGFloat = 14

        // дээд самбар: зэрэг · алт · баг + XP зурвас
        let stats = SKNode()
        stats.position = CGPoint(x: -halfW + insetL, y: halfH - insetT)
        stats.zPosition = 500
        let need = HubData.xpForLevel(Progress.hubLevel)
        let info = "🏛 Хар Хорум    ⭐ Зэрэг \(Progress.hubLevel)    🪙 \(Progress.gold)    👥 Баг \(Progress.partySize)"
        let infoL = UIFactory.label(info, font: Fonts.bold, size: 13, color: Palette.parchment)
        infoL.horizontalAlignmentMode = .left; infoL.verticalAlignmentMode = .top
        stats.addChild(infoL)
        let barBG = SKShapeNode(rectOf: CGSize(width: 210, height: 12), cornerRadius: 6)
        barBG.fillColor = SKColor(white: 0.08, alpha: 0.72); barBG.strokeColor = Palette.goldDark; barBG.lineWidth = 1
        barBG.position = CGPoint(x: 105, y: -26); stats.addChild(barBG)
        let frac = min(1, CGFloat(Progress.hubXp) / CGFloat(max(1, need)))
        let fill = SKSpriteNode(color: Palette.hpGreen, size: CGSize(width: 208 * frac, height: 10))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5); fill.position = CGPoint(x: 1, y: -26); stats.addChild(fill)
        let xpL = UIFactory.label("\(Progress.hubXp) / \(need) XP", font: Fonts.demi, size: 9, color: .white)
        xpL.position = CGPoint(x: 105, y: -26); stats.addChild(xpL)
        cam.addChild(stats)

        // гарах товч (баруун дээд)
        let exit = UIFactory.button(text: "✕ Цэс", name: "hubExit", width: 90, height: 34, primary: false)
        exit.position = CGPoint(x: halfW - 60, y: halfH - 30); exit.zPosition = 500
        cam.addChild(exit)

        // жойстик (зүүн доод, үргэлж харагдана)
        let joyBase = SKShapeNode(circleOfRadius: joyRadius + 14)
        joyBase.fillColor = SKColor(white: 0, alpha: 0.22)
        joyBase.strokeColor = SKColor(red: 0.94, green: 0.89, blue: 0.77, alpha: 0.45); joyBase.lineWidth = 2
        joyBase.position = CGPoint(x: -halfW + 78, y: -halfH + 78); joyBase.zPosition = 500
        cam.addChild(joyBase)
        for (dx, dy) in [(0, 1), (0, -1), (1, 0), (-1, 0)] as [(CGFloat, CGFloat)] {
            let dot = SKShapeNode(circleOfRadius: 2.5)
            dot.fillColor = SKColor(red: 1, green: 0.94, blue: 0.78, alpha: 0.5); dot.strokeColor = .clear
            dot.position = CGPoint(x: dx * (joyRadius - 4), y: dy * (joyRadius - 4)); joyBase.addChild(dot)
        }
        let knob = SKShapeNode(circleOfRadius: 26)
        knob.fillColor = Palette.gold.withAlphaComponent(0.95); knob.strokeColor = Palette.goldDark; knob.lineWidth = 2
        joyBase.addChild(knob); joyKnob = knob
        let cap = UIFactory.label("🕹 Чирж хот дотор алх", font: Fonts.bold, size: 11,
                                  color: SKColor(red: 1, green: 0.92, blue: 0.74, alpha: 0.92))
        cap.position = CGPoint(x: -halfW + 78, y: -halfH + 150); cap.zPosition = 500
        cam.addChild(cap)

        // харилцан үйлдлийн зөвлөмж
        let pr = SKNode()
        let prBG = SKShapeNode(rectOf: CGSize(width: 260, height: 40), cornerRadius: 12)
        prBG.fillColor = SKColor(red: 0.08, green: 0.055, blue: 0.024, alpha: 0.86)
        prBG.strokeColor = Palette.gold; prBG.lineWidth = 1.5
        pr.addChild(prBG)
        let prL = UIFactory.label("", font: Fonts.bold, size: 14, color: SKColor(red: 1, green: 0.92, blue: 0.69, alpha: 1))
        pr.addChild(prL); promptLabel = prL
        pr.position = CGPoint(x: 0, y: -halfH + 70); pr.zPosition = 500
        pr.isHidden = true
        cam.addChild(pr); promptNode = pr
    }

    private func refreshHUD() { buildHUD() }

    // MARK: - Гүйлт / камер

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, 0.05)
        lastTime = currentTime
        guard panel == nil else { joyVec = .zero; return }

        if joyVec != .zero {
            let sp: CGFloat = 210
            heroPos.x = clampF(heroPos.x + joyVec.x * sp * CGFloat(dt), 60, hubW - 60)
            heroPos.y = clampF(heroPos.y + joyVec.y * sp * CGFloat(dt), walkBottom, walkTop)
            if joyVec.x > 0.1 { heroFace = 1 } else if joyVec.x < -0.1 { heroFace = -1 }
            heroNode.xScale = heroFace
            stepT += CGFloat(dt) * 10
            heroNode.position = CGPoint(x: heroPos.x, y: heroPos.y + sinF(stepT) * 1.5)
            heroNode.zPosition = 100 - heroPos.y
            updateNear()
        }
        cam.position = CGPoint(x: clampF(heroPos.x, size.width / 2, max(size.width / 2, hubW - size.width / 2)),
                               y: size.height / 2)
    }

    private func updateNear() {
        var found: Building?
        for b in buildings where b.prompt != nil {
            if abs(heroPos.x - b.x) < 96 { found = b; break }
        }
        if found?.id != nearId {
            nearId = found?.id
            if let b = found, let p = b.prompt {
                promptLabel?.text = "\(b.icon) \(p) — дар"
                promptNode?.isHidden = false
            } else {
                promptNode?.isHidden = true
            }
        }
    }

    private func interact() {
        guard let id = nearId else { return }
        Audio.shared.play("tap", volume: 0.5)
        switch id {
        case "quest": openQuestPanel()
        case "party": openPartyPanel()
        case "shop":  openShopPanel()
        case "camp":
            let camp = CampScene(size: size); camp.scaleMode = .resizeFill
            view?.presentScene(camp, transition: .fade(withDuration: 0.4))
        default: break
        }
    }

    // MARK: - Самбарууд (grid)

    private func newPanel(_ title: String) -> SKNode {
        let p = SKNode(); p.zPosition = 1000
        let bg = SKSpriteNode(color: SKColor(red: 0.05, green: 0.035, blue: 0.02, alpha: 0.94), size: size)
        bg.name = "panelBG"; p.addChild(bg)
        let t = UIFactory.label(title, font: Fonts.heavy, size: 20, color: Palette.gold)
        t.position = CGPoint(x: 0, y: size.height * 0.40); p.addChild(t)
        let close = UIFactory.button(text: "ХААХ", name: "closePanel", width: 160, height: 42, primary: false)
        close.position = CGPoint(x: 0, y: -size.height * 0.42); p.addChild(close)
        cam.addChild(p); panel = p
        return p
    }

    private func gridPosition(_ index: Int, cols: Int, cardW: CGFloat, cardH: CGFloat) -> CGPoint {
        let col = index % cols, row = index / cols
        let totalW = CGFloat(cols) * cardW + CGFloat(cols - 1) * 12
        let x = -totalW / 2 + cardW / 2 + CGFloat(col) * (cardW + 12)
        let y = size.height * 0.33 - CGFloat(row) * (cardH + 8) - cardH / 2
        return CGPoint(x: x, y: y)
    }

    private func card(width: CGFloat, height: CGFloat, name: String, available: Bool, done: Bool) -> SKNode {
        let node = SKNode(); node.name = name
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.92)
        bg.strokeColor = done ? Palette.hpGreen : (available ? Palette.gold : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1))
        bg.lineWidth = available ? 2 : 1.5
        bg.name = name
        node.addChild(bg)
        node.alpha = (available || done) ? 1 : 0.55
        return node
    }

    private func openQuestPanel() {
        let p = newPanel("📜 Зарлигийн самбар")
        let cols = 2
        let cardW = min(340, (size.width - 60) / 2)
        let cardH: CGFloat = 58
        for (i, q) in HubData.quests.enumerated() {
            let st = HubData.status(q)
            let c = card(width: cardW, height: cardH, name: "q_\(q.id)", available: st.ok, done: st.done)
            c.position = gridPosition(i, cols: cols, cardW: cardW, cardH: cardH)
            let icon = HubData.shopItem(q.item)?.icon ?? "📜"
            let title = UIFactory.label("\(icon) \(q.title)", font: Fonts.bold, size: 13,
                                        color: SKColor(red: 0.94, green: 0.88, blue: 0.70, alpha: 1))
            title.horizontalAlignmentMode = .left; title.position = CGPoint(x: -cardW / 2 + 12, y: 20)
            title.name = "q_\(q.id)"; c.addChild(title)
            let meta = UIFactory.label("⭐\(q.lvlReq)  👥\(q.partyReq)  +\(q.xp)XP · \(q.gold)🪙", font: Fonts.demi, size: 11,
                                       color: SKColor(red: 0.72, green: 0.63, blue: 0.42, alpha: 1))
            meta.horizontalAlignmentMode = .left; meta.position = CGPoint(x: -cardW / 2 + 12, y: 0)
            meta.name = "q_\(q.id)"; c.addChild(meta)
            let stColor = st.done ? Palette.hpGreen : (st.ok ? Palette.hpGreen : SKColor(red: 0.79, green: 0.63, blue: 0.42, alpha: 1))
            let stL = UIFactory.label(st.reason, font: Fonts.demi, size: 10, color: stColor)
            stL.horizontalAlignmentMode = .left; stL.position = CGPoint(x: -cardW / 2 + 12, y: -20)
            stL.name = "q_\(q.id)"; c.addChild(stL)
            p.addChild(c)
        }
    }

    private func openPartyPanel() {
        let p = newPanel("🤝 Нөхдийн өргөө")
        let cols = 2
        let cardW = min(340, (size.width - 60) / 2)
        let cardH: CGFloat = 70
        for (i, r) in HubData.recruits.enumerated() {
            let joined = Progress.isRecruited(r.id)
            let afford = !joined && Progress.gold >= r.cost
            let c = card(width: cardW, height: cardH, name: "recruit_\(r.id)", available: afford, done: joined)
            c.position = gridPosition(i, cols: cols, cardW: cardW, cardH: cardH)
            let title = UIFactory.label("\(r.icon) \(r.name)", font: Fonts.bold, size: 13,
                                        color: SKColor(red: 0.94, green: 0.88, blue: 0.70, alpha: 1))
            title.horizontalAlignmentMode = .left; title.position = CGPoint(x: -cardW / 2 + 12, y: 16)
            title.name = "recruit_\(r.id)"; c.addChild(title)
            let meta = UIFactory.label("\(r.role) · ❤️\(Int(r.hp)) ⚔️\(Int(r.dmg))", font: Fonts.demi, size: 10,
                                       color: SKColor(red: 0.72, green: 0.63, blue: 0.42, alpha: 1))
            meta.horizontalAlignmentMode = .left; meta.position = CGPoint(x: -cardW / 2 + 12, y: -2)
            meta.name = "recruit_\(r.id)"; c.addChild(meta)
            let act = UIFactory.label(joined ? "Багт нэгдсэн ✓" : "Элсүүлэх · 🪙\(r.cost)", font: Fonts.bold, size: 11,
                                      color: joined ? Palette.hpGreen : Palette.gold)
            act.horizontalAlignmentMode = .left; act.position = CGPoint(x: -cardW / 2 + 12, y: -20)
            act.name = "recruit_\(r.id)"; c.addChild(act)
            p.addChild(c)
        }
    }

    private func openShopPanel() {
        let p = newPanel("⚒️ Дархны газар")
        let cols = 2
        let cardW = min(340, (size.width - 60) / 2)
        let cardH: CGFloat = 70
        for (i, it) in HubData.shop.enumerated() {
            let owned = Progress.ownsItem(it.id)
            let afford = !owned && Progress.gold >= it.cost
            let c = card(width: cardW, height: cardH, name: "buy_\(it.id)", available: afford, done: owned)
            c.position = gridPosition(i, cols: cols, cardW: cardW, cardH: cardH)
            let title = UIFactory.label("\(it.icon) \(it.name)", font: Fonts.bold, size: 13,
                                        color: SKColor(red: 0.94, green: 0.88, blue: 0.70, alpha: 1))
            title.horizontalAlignmentMode = .left; title.position = CGPoint(x: -cardW / 2 + 12, y: 16)
            title.name = "buy_\(it.id)"; c.addChild(title)
            let meta = UIFactory.label(it.desc, font: Fonts.demi, size: 10,
                                       color: SKColor(red: 0.72, green: 0.63, blue: 0.42, alpha: 1))
            meta.horizontalAlignmentMode = .left; meta.position = CGPoint(x: -cardW / 2 + 12, y: -2)
            meta.name = "buy_\(it.id)"; c.addChild(meta)
            let act = UIFactory.label(owned ? "Эзэмшсэн ✓" : "Худалдаж авах · 🪙\(it.cost)", font: Fonts.bold, size: 11,
                                      color: owned ? Palette.hpGreen : Palette.gold)
            act.horizontalAlignmentMode = .left; act.position = CGPoint(x: -cardW / 2 + 12, y: -20)
            act.name = "buy_\(it.id)"; c.addChild(act)
            p.addChild(c)
        }
    }

    private func closePanel() {
        panel?.removeFromParent()
        panel = nil
    }

    private func startQuest(_ q: HubQuest) {
        HubContext.activeQuest = q
        Audio.shared.play("tap")
        let heroIndex = 0     // Хар Хорумд Тэмүжингээр эхэлнэ
        let battle = BattleScene(size: size, heroIndex: heroIndex, difficultyIndex: 1, campaignLevel: q.level)
        battle.scaleMode = .resizeFill
        view?.presentScene(battle, transition: .fade(withDuration: 0.6))
    }

    // MARK: - Хүрэлт

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)
            if panel != nil {
                dragTouch = t; dragMoved = false
                continue
            }
            let cx = t.location(in: cam)   // камер-локал (төв=0)
            if cx.x < 0 {                  // зүүн тал → жойстик
                joyTouch = t
                updateJoy(cx)
            } else if nearId != nil {
                // баруун тал → харилцан үйлдэх (товчнаас бусад)
                if UIFactory.nodeName(at: p, in: self) == nil { interact() }
            }
            if let name = UIFactory.nodeName(at: p, in: self), name == "hubExit" {
                goMenu()
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches where t == joyTouch {
            updateJoy(t.location(in: cam))
        }
        if dragTouch != nil { dragMoved = true }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if t == joyTouch {
                joyTouch = nil; joyVec = .zero
                joyKnob?.position = .zero
            }
            if t == dragTouch {
                dragTouch = nil
                if !dragMoved, let name = UIFactory.nodeName(at: t.location(in: self), in: self) {
                    handlePanelTap(name)
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func updateJoy(_ camLocal: CGPoint) {
        let halfW = size.width / 2, halfH = size.height / 2
        let center = CGPoint(x: -halfW + 78, y: -halfH + 78)
        var dx = camLocal.x - center.x, dy = camLocal.y - center.y
        let d = vecLen(dx, dy)
        if d > joyRadius { dx = dx / d * joyRadius; dy = dy / d * joyRadius }
        joyVec = CGPoint(x: dx / joyRadius, y: dy / joyRadius)
        joyKnob?.position = CGPoint(x: dx, y: dy)
    }

    private func handlePanelTap(_ name: String) {
        if name == "closePanel" || name == "panelBG" {
            if name == "closePanel" { closePanel() }
            return
        }
        if name.hasPrefix("q_") {
            let qid = String(name.dropFirst(2))
            if let q = HubData.quests.first(where: { $0.id == qid }) {
                let st = HubData.status(q)
                if st.ok || st.done { closePanel(); startQuest(q) }
                else { Audio.shared.play("tap", volume: 0.3); Haptics.hit() }
            }
        } else if name.hasPrefix("recruit_") {
            let rid = String(name.dropFirst(8))
            if let r = HubData.recruit(rid), Progress.recruit(r.id, cost: r.cost) {
                Audio.shared.play("level", volume: 0.7); Haptics.levelUp()
                closePanel(); refreshHUD(); openPartyPanel()
            } else { Audio.shared.play("tap", volume: 0.3); Haptics.hit() }
        } else if name.hasPrefix("buy_") {
            let iid = String(name.dropFirst(4))
            if let it = HubData.shopItem(iid), Progress.buyItem(it.id, cost: it.cost) {
                Audio.shared.play("level", volume: 0.7); Haptics.levelUp()
                closePanel(); refreshHUD(); openShopPanel()
            } else { Audio.shared.play("tap", volume: 0.3); Haptics.hit() }
        }
    }

    private func goMenu() {
        Audio.shared.play("tap")
        let menu = MenuScene(size: size); menu.scaleMode = .resizeFill
        view?.presentScene(menu, transition: .fade(withDuration: 0.4))
    }
}
