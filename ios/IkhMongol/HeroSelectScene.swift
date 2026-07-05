import SpriteKit

/// Баатар сонгох дэлгэц
final class HeroSelectScene: SKScene {

    private var selIndex = 0
    private var cardNodes: [SKShapeNode] = []
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

        let title = UIFactory.label("БААТРАА СОНГО", font: Fonts.heavy, size: 24, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 42)
        c.addChild(title)

        // картууд
        let cardW = min(200, (size.width - 80) / 3)
        let cardH = size.height * 0.52
        let gap: CGFloat = 16
        let totalW = cardW * 3 + gap * 2
        let startX = cx - totalW / 2 + cardW / 2
        let cardY = size.height * 0.52

        for (i, hero) in GameData.heroes.enumerated() {
            let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
            card.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.96)
            card.strokeColor = SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            card.lineWidth = 2
            card.name = "card\(i)"
            card.position = CGPoint(x: startX + CGFloat(i) * (cardW + gap), y: cardY)
            c.addChild(card)
            cardNodes.append(card)

            let iconBg = SKShapeNode(circleOfRadius: 26)
            iconBg.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.10, alpha: 1)
            iconBg.strokeColor = SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
            iconBg.lineWidth = 2
            iconBg.position = CGPoint(x: 0, y: cardH / 2 - 40)
            iconBg.name = card.name
            card.addChild(iconBg)

            let icon = SKLabelNode(text: hero.icon)
            icon.fontSize = 26
            icon.verticalAlignmentMode = .center
            icon.position = iconBg.position
            icon.name = card.name
            card.addChild(icon)

            let nameL = UIFactory.label(hero.name, font: Fonts.bold, size: 14,
                                        color: SKColor(red: 0.94, green: 0.87, blue: 0.68, alpha: 1))
            nameL.position = CGPoint(x: 0, y: cardH / 2 - 80)
            nameL.name = card.name
            card.addChild(nameL)

            let roleL = UIFactory.label(hero.role, font: Fonts.demi, size: 10,
                                        color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
            roleL.position = CGPoint(x: 0, y: cardH / 2 - 96)
            roleL.name = card.name
            card.addChild(roleL)

            let descL = UIFactory.multiline(hero.desc, font: Fonts.demi, size: 10,
                                            color: SKColor(red: 0.72, green: 0.64, blue: 0.49, alpha: 1),
                                            width: cardW - 24)
            descL.verticalAlignmentMode = .top
            descL.position = CGPoint(x: 0, y: cardH / 2 - 108)
            descL.name = card.name
            card.addChild(descL)

            let skillText = "\(hero.s1.icon) \(hero.s1.name) — \(hero.s1.desc)\n\(hero.s2.icon) \(hero.s2.name) — \(hero.s2.desc)"
            let skillL = UIFactory.multiline(skillText, font: Fonts.demi, size: 9,
                                             color: SKColor(red: 0.56, green: 0.71, blue: 0.45, alpha: 1),
                                             width: cardW - 24)
            skillL.verticalAlignmentMode = .bottom
            skillL.position = CGPoint(x: 0, y: -cardH / 2 + 14)
            skillL.name = card.name
            card.addChild(skillL)
        }

        let start = UIFactory.button(text: "ТУЛААНД МОРД", name: "start")
        start.position = CGPoint(x: cx, y: size.height * 0.115)
        c.addChild(start)

        refreshSelection()
    }

    private func refreshSelection() {
        for (i, card) in cardNodes.enumerated() {
            let selected = i == selIndex
            card.strokeColor = selected
                ? Palette.goldLight
                : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            card.lineWidth = selected ? 3.5 : 2
            card.setScale(selected ? 1.04 : 1.0)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        guard let name = UIFactory.nodeName(at: t.location(in: self), in: self) else { return }

        if name == "start", let view = view {
            Haptics.skill()
            let battle = BattleScene(size: size, heroIndex: selIndex)
            view.presentScene(battle, transition: .fade(withDuration: 0.6))
            return
        }
        for i in 0..<GameData.heroes.count where name == "card\(i)" {
            selIndex = i
            Haptics.hit()
            refreshSelection()
            return
        }
    }
}
