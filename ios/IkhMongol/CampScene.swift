import SpriteKit

/// Буурь — V2 эдийн засаг. Эзэлсэн олзоор (адуу, төмөр) отрядыг хүчирхэгжүүлнэ.
final class CampScene: SKScene {

    private struct Upgrade {
        let icon: String
        let name: String
        let desc: String
        let resIcon: String
        let resName: String
        let level: () -> Int
        let resource: () -> Int
        let buy: () -> Void        // нэг түвшин ахиулна
        let cost: (Int) -> Int
    }

    private var built = false
    private var content: SKNode?

    private var upgrades: [Upgrade] = []

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        Audio.shared.startMusic()
        buildUpgrades()
        buildUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        buildUI()
    }

    private func buildUpgrades() {
        upgrades = [
            Upgrade(icon: "🐎", name: "Адууны сүрэг",
                    desc: "Отряд ба өөрийн хурд +4% / түвшин",
                    resIcon: "🐎", resName: "адуу",
                    level: { Progress.horseLevel }, resource: { Progress.horses },
                    buy: { Progress.horses -= (4 + Progress.horseLevel * 3); Progress.horseLevel += 1 },
                    cost: { 4 + $0 * 3 }),
            Upgrade(icon: "⚒️", name: "Дархны зэвсэг",
                    desc: "Отряд ба өөрийн хүч +5% / түвшин",
                    resIcon: "⚒️", resName: "төмөр",
                    level: { Progress.ironLevel }, resource: { Progress.iron },
                    buy: { Progress.iron -= (3 + Progress.ironLevel * 3); Progress.ironLevel += 1 },
                    cost: { 3 + $0 * 3 })
        ]
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

        let title = UIFactory.label("🏕️ БУУРЬ", font: Fonts.heavy, size: 22, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 28)
        c.addChild(title)

        let sub = UIFactory.label("Эзэлсэн олзоор отрядаа хүчирхэгжүүл — адуу маллаж, зэвсэг давт",
                                  font: Fonts.demi, size: 11,
                                  color: SKColor(red: 0.55, green: 0.46, blue: 0.30, alpha: 1))
        sub.position = CGPoint(x: cx, y: size.height - 50)
        c.addChild(sub)

        let res = UIFactory.label("🐎 \(Progress.horses) адуу    ·    ⚒️ \(Progress.iron) төмөр",
                                  font: Fonts.bold, size: 15, color: Palette.gold)
        res.position = CGPoint(x: cx, y: size.height - 78)
        c.addChild(res)

        // картууд
        let cardW = min(560, size.width - 30)
        let cardH: CGFloat = 92
        let top = size.height - 120
        for (i, up) in upgrades.enumerated() {
            let y = top - CGFloat(i) * (cardH + 16) - cardH / 2
            c.addChild(makeCard(up, index: i, width: cardW, height: cardH, center: CGPoint(x: cx, y: y)))
        }

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 180, height: 44, primary: false)
        back.position = CGPoint(x: cx, y: max(30, size.height * 0.08))
        c.addChild(back)
    }

    private func makeCard(_ up: Upgrade, index: Int, width: CGFloat, height: CGFloat, center: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = center

        let card = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 14)
        card.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.9)
        card.strokeColor = SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
        card.lineWidth = 1.5
        node.addChild(card)

        let lvl = up.level()
        let maxed = lvl >= Progress.campMaxLevel

        let icon = SKLabelNode(text: up.icon)
        icon.fontSize = 34; icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: -width / 2 + 34, y: 0)
        node.addChild(icon)

        let name = UIFactory.label("\(up.name)   Түв \(lvl)", font: Fonts.heavy, size: 15,
                                   color: SKColor(red: 0.94, green: 0.88, blue: 0.70, alpha: 1))
        name.horizontalAlignmentMode = .left
        name.position = CGPoint(x: -width / 2 + 64, y: 22)
        node.addChild(name)

        let desc = UIFactory.label(up.desc, font: Fonts.demi, size: 11,
                                   color: SKColor(red: 0.63, green: 0.54, blue: 0.38, alpha: 1))
        desc.horizontalAlignmentMode = .left
        desc.position = CGPoint(x: -width / 2 + 64, y: 2)
        node.addChild(desc)

        let stars = String(repeating: "★", count: lvl) + String(repeating: "☆", count: Progress.campMaxLevel - lvl)
        let starL = UIFactory.label(stars, font: Fonts.bold, size: 13,
                                    color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
        starL.horizontalAlignmentMode = .left
        starL.position = CGPoint(x: -width / 2 + 64, y: -20)
        node.addChild(starL)

        let cost = up.cost(lvl)
        let affordable = up.resource() >= cost
        let btnText = maxed ? "Дээд зэрэг" : "🔨 \(cost) \(up.resName)"
        let btn = UIFactory.button(text: btnText, name: maxed ? "maxed\(index)" : "buy\(index)",
                                   width: 150, height: 42, primary: !maxed && affordable)
        btn.position = CGPoint(x: width / 2 - 90, y: 0)
        if maxed { btn.alpha = 0.6 }
        node.addChild(btn)

        return node
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
        for i in upgrades.indices where name == "buy\(i)" {
            let up = upgrades[i]
            let cost = up.cost(up.level())
            if up.level() < Progress.campMaxLevel && up.resource() >= cost {
                up.buy()
                Audio.shared.play("level", volume: 0.7)
                Haptics.levelUp()
            } else {
                Audio.shared.play("tap", volume: 0.4)
                Haptics.hit()
            }
            buildUI()
            return
        }
    }
}
