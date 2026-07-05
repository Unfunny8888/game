import SpriteKit

/// Тулааны өмнөх түүхэн танилцуулга (илгэн цаасны хуудас) — аяны горимд
final class MissionIntroScene: SKScene {

    private let heroIndex: Int
    private let level: Int
    private var built = false
    private var content: SKNode?

    init(size: CGSize, heroIndex: Int, level: Int) {
        self.heroIndex = heroIndex
        self.level = level
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        Audio.shared.startMusic()
        Audio.shared.play("horn", volume: 0.6)
        buildUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        buildUI()
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
        let L = GameData.campaign[level]

        // илгэн цаасны хуудас
        let pageW = min(640, size.width * 0.88)
        let pageH = size.height * 0.66
        let page = SKShapeNode(rectOf: CGSize(width: pageW, height: pageH), cornerRadius: 6)
        page.fillColor = SKColor(red: 0.93, green: 0.88, blue: 0.76, alpha: 1)
        page.strokeColor = SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
        page.lineWidth = 2.5
        page.position = CGPoint(x: cx, y: size.height * 0.58)
        c.addChild(page)

        let ornament = UIFactory.label("⚔ ᠊᠊᠊᠊᠊᠊ ⚔", font: Fonts.serif, size: 11,
                                       color: SKColor(red: 0.66, green: 0.46, blue: 0.23, alpha: 1))
        ornament.position = CGPoint(x: 0, y: pageH / 2 - 22)
        page.addChild(ornament)

        let titleL = UIFactory.label("\(level + 1). \(L.title)", font: Fonts.serifBold, size: 18,
                                     color: SKColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1))
        titleL.position = CGPoint(x: 0, y: pageH / 2 - 46)
        page.addChild(titleL)

        let body = UIFactory.multiline(L.intro, font: Fonts.serif, size: 12.5,
                                       color: SKColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1),
                                       width: pageW - 56)
        body.verticalAlignmentMode = .top
        body.position = CGPoint(x: 0, y: pageH / 2 - 64)
        page.addChild(body)

        let objL = UIFactory.label("🎯 \(L.objective.label)", font: Fonts.bold, size: 13,
                                   color: SKColor(red: 0.35, green: 0.48, blue: 0.18, alpha: 1))
        objL.position = CGPoint(x: 0, y: -pageH / 2 + 74)
        page.addChild(objL)

        // Түүхэн баримт (сургалтын самбар)
        let factBox = SKShapeNode(rectOf: CGSize(width: pageW - 40, height: 58), cornerRadius: 4)
        factBox.fillColor = SKColor(red: 0.63, green: 0.47, blue: 0.24, alpha: 0.16)
        factBox.strokeColor = SKColor(red: 0.66, green: 0.46, blue: 0.23, alpha: 1)
        factBox.lineWidth = 1
        factBox.position = CGPoint(x: 0, y: -pageH / 2 + 38)
        page.addChild(factBox)
        let factL = UIFactory.multiline("📖 Түүхэн баримт (\(L.src)): \(L.fact)",
                                        font: Fonts.serif, size: 9.5,
                                        color: SKColor(red: 0.35, green: 0.26, blue: 0.14, alpha: 1),
                                        width: pageW - 56)
        factL.position = CGPoint(x: 0, y: -pageH / 2 + 38)
        page.addChild(factL)

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 150, height: 44, primary: false)
        back.position = CGPoint(x: cx - 110, y: max(28, size.height * 0.1))
        c.addChild(back)

        let go = UIFactory.button(text: "⚔️ МОРД", name: "go", width: 190, height: 44)
        go.position = CGPoint(x: cx + 95, y: max(28, size.height * 0.1))
        c.addChild(go)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let view = view else { return }
        let name = UIFactory.nodeName(at: t.location(in: self), in: self)
        if name == "go" {
            Haptics.skill()
            Audio.shared.play("tap")
            let battle = BattleScene(size: size, heroIndex: heroIndex,
                                     difficultyIndex: 1, campaignLevel: level)
            view.presentScene(battle, transition: .fade(withDuration: 0.6))
        } else if name == "back" {
            Haptics.hit()
            Audio.shared.play("tap")
            let camp = CampaignScene(size: size)
            camp.scaleMode = .resizeFill
            view.presentScene(camp, transition: .fade(withDuration: 0.4))
        }
    }
}
