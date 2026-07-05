import SpriteKit

/// Үндсэн цэс
final class MenuScene: SKScene {

    private var built = false
    private var content: SKNode?

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
        let c = SKNode()
        content = c
        addChild(c)

        // дэвсгэр
        let bg = SKSpriteNode(texture: Tex.linearGradient(
            size: CGSize(width: 8, height: 128),
            colors: [UIColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1),
                     UIColor(red: 0.11, green: 0.07, blue: 0.03, alpha: 1),
                     UIColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 1)]),
            size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        c.addChild(bg)

        let cx = size.width / 2

        let ornament = UIFactory.label("⁂ ᠊᠊᠊᠊᠊᠊᠊᠊᠊᠊ ⁂", font: Fonts.demi, size: 13,
                                       color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
        ornament.position = CGPoint(x: cx, y: size.height * 0.86)
        c.addChild(ornament)

        let title = UIFactory.label("ИХ МОНГОЛ", font: Fonts.heavy,
                                    size: min(54, size.width * 0.085), color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height * 0.70)
        c.addChild(title)

        let subtitle = UIFactory.label("ТУЛААНЫ ТАЛБАР", font: Fonts.bold, size: 17,
                                       color: SKColor(red: 0.85, green: 0.76, blue: 0.60, alpha: 1))
        subtitle.position = CGPoint(x: cx, y: size.height * 0.585)
        c.addChild(subtitle)

        let tagline = UIFactory.multiline(
            "Мөнх тэнгэрийн хүчин дор — Чингис хааны дайчдыг удирдан,\nХорезмын их хаалгыг нурааж, талбарыг эзэгнэ!",
            font: Fonts.demi, size: 12,
            color: SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1),
            width: size.width * 0.8)
        tagline.position = CGPoint(x: cx, y: size.height * 0.47)
        c.addChild(tagline)

        let play = UIFactory.button(text: "ТОГЛОХ", name: "play")
        play.position = CGPoint(x: cx, y: size.height * 0.29)
        c.addChild(play)

        let hint = UIFactory.multiline(
            "Зүүн тал — хөдөлгөөний жойстик  ·  Баруун тал — чадварын товчнууд\nЭнгийн довтолгоо автоматаар хийгдэнэ.",
            font: Fonts.demi, size: 10.5,
            color: SKColor(red: 0.48, green: 0.41, blue: 0.28, alpha: 1),
            width: size.width * 0.85)
        hint.position = CGPoint(x: cx, y: size.height * 0.12)
        c.addChild(hint)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let name = UIFactory.nodeName(at: t.location(in: self), in: self)
        if name == "play", let view = view {
            Haptics.skill()
            let select = HeroSelectScene(size: size)
            select.scaleMode = .resizeFill
            view.presentScene(select, transition: .fade(withDuration: 0.4))
        }
    }
}
