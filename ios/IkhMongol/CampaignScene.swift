import SpriteKit

/// Аян дайн — Байлдан дагуулалтын газрын зураг.
/// Түвшин болгон газар зураг дээрх байршил; дуусгах тусам эзэнт гүрэн тэлнэ.
final class CampaignScene: SKScene {

    private var built = false
    private var content: SKNode?

    // Зургийн дотоод координат (1000×560) — дэлгэц рүү хувиргана
    private let mapW: CGFloat = 1000, mapH: CGFloat = 560
    private var mapScale: CGFloat = 1
    private var mapOrigin = CGPoint.zero

    private let nodePos: [CGPoint] = [
        CGPoint(x: 702, y: 206), CGPoint(x: 676, y: 236), CGPoint(x: 654, y: 182), CGPoint(x: 702, y: 256),
        CGPoint(x: 646, y: 232), CGPoint(x: 560, y: 216), CGPoint(x: 402, y: 316), CGPoint(x: 496, y: 430)
    ]
    private let regions: [(String, CGFloat, CGFloat)] = [
        ("Европ",110,214),("Орос",286,168),("Сибирь",560,150),("Төв Ази",432,300),
        ("Перс",330,392),("Энэтхэг",498,470),("Монгол",664,232),("Хятад",806,330),("Солонгос",918,300)
    ]
    // Нутаг дэвсгэрийн олон өнцөгтүүд (нэгдэх тусам тэлнэ)
    private let tHome: [CGFloat] = [638,176, 720,186, 746,226, 716,270, 654,276, 616,236, 620,196]
    private let tMong: [CGFloat] = [538,166, 732,176, 772,222, 742,286, 610,296, 544,256, 520,200]
    private let tCent: [CGFloat] = [358,272, 540,166, 732,176, 772,222, 742,286, 500,342, 380,332, 338,292]
    private let tFull: [CGFloat] = [150,150, 320,118, 560,108, 762,120, 902,160, 936,242, 872,302,
                                    762,342, 560,362, 470,442, 380,402, 300,382, 210,342, 150,250]

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        Audio.shared.startMusic()
        buildUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        buildUI()
    }

    // Зургийн координатыг дэлгэц рүү
    private func mp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: mapOrigin.x + x * mapScale, y: mapOrigin.y + (mapH - y) * mapScale)
    }
    private func poly(_ pts: [CGFloat]) -> CGPath {
        let path = CGMutablePath()
        var i = 0
        while i < pts.count {
            let p = mp(pts[i], pts[i+1])
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            i += 2
        }
        path.closeSubpath()
        return path
    }

    private func buildUI() {
        content?.removeFromParent()
        let c = SKNode()
        content = c
        addChild(c)

        let bg = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1),
                     UIColor(red: 0.06, green: 0.04, blue: 0.02, alpha: 1)]),
            size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        c.addChild(bg)

        let cx = size.width / 2
        let progress = Progress.campaign
        let done = progress >= GameData.campaign.count

        let title = UIFactory.label("АЯН ДАЙН — БАЙЛДАН ДАГУУЛАЛТЫН ЗУРАГ", font: Fonts.heavy, size: 17, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 24)
        c.addChild(title)

        let sub = UIFactory.label("Газар дээр дарж тулаанд мор · Дуусгах тусам эзэнт гүрэн тэлнэ",
                                  font: Fonts.demi, size: 10, color: SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1))
        sub.position = CGPoint(x: cx, y: size.height - 40)
        c.addChild(sub)

        // Зургийн хэмжээ ба байрлал
        let availH = size.height - 96
        let availW = size.width - 40
        mapScale = min(availW / mapW, availH / mapH)
        let drawnW = mapW * mapScale, drawnH = mapH * mapScale
        mapOrigin = CGPoint(x: cx - drawnW / 2, y: (size.height - 60) / 2 - drawnH / 2 + 4)

        // Тэнгис (зургийн дэвсгэр)
        let seaRect = CGRect(x: mapOrigin.x, y: mapOrigin.y, width: drawnW, height: drawnH)
        let sea = SKShapeNode(rect: seaRect, cornerRadius: 10)
        sea.fillColor = SKColor(red: 0.13, green: 0.22, blue: 0.26, alpha: 1)
        sea.strokeColor = SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
        sea.lineWidth = 2
        c.addChild(sea)

        // Эх газар
        let land = SKShapeNode(path: landmassPath())
        land.fillColor = SKColor(red: 0.55, green: 0.48, blue: 0.30, alpha: 1)
        land.strokeColor = SKColor(red: 0.48, green: 0.36, blue: 0.18, alpha: 1)
        land.lineWidth = 2
        c.addChild(land)

        // Эзэнт гүрний нутаг
        if done {
            let emp = SKShapeNode(path: poly(tFull))
            emp.fillColor = SKColor(red: 0.95, green: 0.79, blue: 0.42, alpha: 0.72)
            emp.strokeColor = SKColor(red: 1.0, green: 0.94, blue: 0.75, alpha: 1)
            emp.lineWidth = 3
            emp.glowWidth = 6
            c.addChild(emp)
        } else {
            let terr: [CGFloat]? = progress >= 7 ? tCent : (progress >= 6 ? tMong : (progress >= 1 ? tHome : nil))
            if let terr = terr {
                let t = SKShapeNode(path: poly(terr))
                t.fillColor = SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 0.33)
                t.strokeColor = SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1)
                t.lineWidth = 2
                c.addChild(t)
            }
        }

        // Бүс нутгийн нэрс
        for (name, x, y) in regions {
            let l = UIFactory.label(name, font: Fonts.serifBold, size: max(8, 13 * mapScale),
                                    color: SKColor(red: 0.24, green: 0.16, blue: 0.07, alpha: 0.75))
            l.position = mp(x, y)
            c.addChild(l)
        }

        // Байлдааны зам
        let routePath = CGMutablePath()
        var started = false
        for i in 0..<nodePos.count where progress >= i {
            let p = mp(nodePos[i].x, nodePos[i].y)
            if !started { routePath.move(to: p); started = true } else { routePath.addLine(to: p) }
        }
        if started {
            let route = SKShapeNode(path: routePath)
            route.strokeColor = Palette.gold
            route.lineWidth = 2.5
            route.lineCap = .round
            let dash = SKShapeNode(path: routePath.copy(dashingWithPhase: 0, lengths: [7, 6]))
            dash.strokeColor = Palette.gold
            dash.lineWidth = 2.5
            dash.alpha = 0.85
            c.addChild(dash)
        }

        // Цэгүүд
        for (i, n) in nodePos.enumerated() {
            let cleared = progress > i
            let unlocked = progress >= i
            let node = SKShapeNode(circleOfRadius: max(11, 15 * mapScale))
            node.fillColor = cleared
                ? SKColor(red: 0.55, green: 0.91, blue: 0.48, alpha: 1)
                : (unlocked ? Palette.gold : SKColor(red: 0.35, green: 0.29, blue: 0.19, alpha: 1))
            node.strokeColor = SKColor(red: 0.14, green: 0.10, blue: 0.03, alpha: 1)
            node.lineWidth = 2
            if unlocked { node.glowWidth = 3 }
            node.position = mp(n.x, n.y)
            node.name = "node\(i)"
            c.addChild(node)

            let lbl = UIFactory.label(cleared ? "✓" : "\(i + 1)", font: Fonts.heavy, size: max(11, 15 * mapScale),
                                      color: SKColor(red: 0.14, green: 0.08, blue: 0.01, alpha: 1))
            lbl.position = mp(n.x, n.y)
            lbl.name = "node\(i)"
            c.addChild(lbl)
        }

        // Гарчиг (дуусгасан үед)
        if done {
            let empTitle = UIFactory.label("ИХ МОНГОЛ ЭЗЭНТ ГҮРЭН", font: Fonts.serifBold, size: 18, color: Palette.goldLight)
            empTitle.position = CGPoint(x: cx, y: mapOrigin.y + drawnH - 20)
            empTitle.zPosition = 5
            c.addChild(empTitle)
            let empSub = UIFactory.label("1206–1279 · Номхон далайгаас Дунай мөрөн хүртэл",
                                         font: Fonts.serif, size: 10, color: SKColor(red: 0.85, green: 0.76, blue: 0.60, alpha: 1))
            empSub.position = CGPoint(x: cx, y: mapOrigin.y + drawnH - 36)
            empSub.zPosition = 5
            c.addChild(empSub)
        }

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 170, height: 40, primary: false)
        back.position = CGPoint(x: cx, y: max(24, size.height * 0.06))
        back.zPosition = 10
        c.addChild(back)
    }

    /// Стилизацдсан Ази эх газрын гулзайлттай контур
    private func landmassPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: mp(40, 232))
        func cv(_ c1x: CGFloat,_ c1y: CGFloat,_ c2x: CGFloat,_ c2y: CGFloat,_ ex: CGFloat,_ ey: CGFloat) {
            path.addCurve(to: mp(ex, ey), control1: mp(c1x, c1y), control2: mp(c2x, c2y))
        }
        cv(90,150, 210,116, 360,104)
        cv(540,90, 720,92, 870,128)
        cv(960,150, 984,210, 970,262)
        cv(956,314, 880,326, 812,312)
        cv(800,360, 720,388, 700,392)
        cv(640,404, 560,392, 524,404)
        cv(516,452, 486,498, 452,500)
        cv(420,502, 424,452, 452,420)
        cv(388,414, 300,404, 226,372)
        cv(150,340, 70,300, 40,262)
        path.closeSubpath()
        return path
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        guard let name = UIFactory.nodeName(at: t.location(in: self), in: self) else { return }

        if name == "back", let view = view {
            Audio.shared.play("tap")
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view.presentScene(menu, transition: .fade(withDuration: 0.35))
            return
        }
        for i in 0..<GameData.campaign.count where name == "node\(i)" {
            guard Progress.campaign >= i, let view = view else { return }
            Audio.shared.play("tap")
            Haptics.hit()
            let select = HeroSelectScene(size: size, campaignLevel: i)
            view.presentScene(select, transition: .fade(withDuration: 0.4))
            return
        }
    }
}
