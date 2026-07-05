import SpriteKit

/// Аян дайн — Монголын нууц товчоогоор 8 түвшин
final class CampaignScene: SKScene {

    private var built = false
    private var content: SKNode?

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

    private func buildUI() {
        content?.removeFromParent()
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

        let title = UIFactory.label("АЯН ДАЙН", font: Fonts.heavy, size: 22, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 30)
        c.addChild(title)

        let sub = UIFactory.label("Монголын нууц товчоогоор — Тэмүжингээс дэлхийн эзэн хаан хүртэл",
                                  font: Fonts.demi, size: 10,
                                  color: SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1))
        sub.position = CGPoint(x: cx, y: size.height - 48)
        c.addChild(sub)

        // 2 багана × 4 мөр
        let rowW = min(360, (size.width - 60) / 2)
        let rowH: CGFloat = 42
        let gapX: CGFloat = 14
        let gapY: CGFloat = 9
        let topY = size.height - 86
        let progress = Progress.campaign

        for (i, L) in GameData.campaign.enumerated() {
            let col = CGFloat(i / 4)
            let row = CGFloat(i % 4)
            let cleared = progress > i
            let unlocked = progress >= i

            let node = SKShapeNode(rectOf: CGSize(width: rowW, height: rowH), cornerRadius: 9)
            node.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.96)
            node.strokeColor = cleared
                ? SKColor(red: 0.55, green: 0.91, blue: 0.48, alpha: 1)
                : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            node.lineWidth = 1.5
            node.alpha = unlocked ? 1 : 0.5
            node.name = "level\(i)"
            node.position = CGPoint(x: cx + (col == 0 ? -1 : 1) * (rowW / 2 + gapX / 2),
                                    y: topY - row * (rowH + gapY))
            c.addChild(node)

            let num = UIFactory.label("\(i + 1)", font: Fonts.heavy, size: 16,
                                      color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
            num.position = CGPoint(x: -rowW / 2 + 20, y: 0)
            num.name = node.name
            node.addChild(num)

            let tag = UIFactory.label(cleared ? "✅" : (unlocked ? "⚔️" : "🔒"), size: 15)
            tag.position = CGPoint(x: rowW / 2 - 22, y: 0)
            tag.name = node.name
            node.addChild(tag)

            let titleL = UIFactory.label(unlocked ? L.title : "???", font: Fonts.bold, size: 12,
                                         color: SKColor(red: 0.94, green: 0.87, blue: 0.68, alpha: 1))
            titleL.horizontalAlignmentMode = .left
            titleL.position = CGPoint(x: -rowW / 2 + 38, y: 6)
            titleL.name = node.name
            node.addChild(titleL)

            let descText = unlocked ? "🎯 \(L.objective.label)" : "Өмнөх түвшинг дуусга"
            let descL = UIFactory.label(descText, font: Fonts.demi, size: 8,
                                        color: SKColor(red: 0.54, green: 0.66, blue: 0.44, alpha: 1))
            descL.horizontalAlignmentMode = .left
            descL.position = CGPoint(x: -rowW / 2 + 38, y: -9)
            descL.name = node.name
            node.addChild(descL)
        }

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 180, height: 42, primary: false)
        back.position = CGPoint(x: cx, y: max(28, size.height * 0.07))
        c.addChild(back)
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
        for i in 0..<GameData.campaign.count where name == "level\(i)" {
            guard Progress.campaign >= i, let view = view else { return }
            Audio.shared.play("tap")
            Haptics.hit()
            let select = HeroSelectScene(size: size, campaignLevel: i)
            view.presentScene(select, transition: .fade(withDuration: 0.4))
            return
        }
    }
}
