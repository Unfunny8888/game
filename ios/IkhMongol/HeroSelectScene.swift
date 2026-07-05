import SpriteKit

/// Баатар болон хэцүү байдал сонгох дэлгэц
final class HeroSelectScene: SKScene {

    private var selIndex = 0
    private var selDiff = 1
    private var cardNodes: [SKShapeNode] = []
    private var diffNodes: [SKShapeNode] = []
    private var diffLabels: [SKLabelNode] = []
    private var infoLabel: SKLabelNode?
    private var goldLabel: SKLabelNode?
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
        cardNodes = []
        diffNodes = []
        diffLabels = []
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

        let title = UIFactory.label("БААТРАА СОНГО", font: Fonts.heavy, size: 20, color: Palette.gold)
        title.position = CGPoint(x: cx - 90, y: size.height - 26)
        c.addChild(title)

        let gold = UIFactory.label("🪙 \(Progress.gold) алт", font: Fonts.bold, size: 14,
                                   color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
        gold.position = CGPoint(x: cx + 120, y: size.height - 26)
        c.addChild(gold)
        goldLabel = gold

        // 4+3 картын сүлжээ (7 баатар)
        let cardW = min(165, (size.width - 100) / 4)
        let cardH: CGFloat = size.height * 0.155
        let gapX: CGFloat = 10
        let gapY: CGFloat = 10
        let row1Y = size.height * 0.72
        let row2Y = row1Y - cardH - gapY

        for (i, hero) in GameData.heroes.enumerated() {
            let inFirstRow = i < 4
            let col = CGFloat(inFirstRow ? i : i - 4)
            let count: CGFloat = inFirstRow ? 4 : 3
            let rowWidth = count * cardW + (count - 1) * gapX
            let startX = cx - rowWidth / 2 + cardW / 2
            let rowY = inFirstRow ? row1Y : row2Y
            let unlocked = Progress.isUnlocked(hero.id)

            let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 10)
            card.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.96)
            card.strokeColor = hero.id == "chinggis"
                ? Palette.goldLight
                : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            card.lineWidth = 2
            card.name = "card\(i)"
            card.position = CGPoint(x: startX + col * (cardW + gapX), y: rowY)
            card.alpha = unlocked ? 1 : (hero.id == "chinggis" ? 0.8 : 0.55)
            c.addChild(card)
            cardNodes.append(card)

            let iconBg = SKShapeNode(circleOfRadius: cardH * 0.32)
            iconBg.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.10, alpha: 1)
            iconBg.strokeColor = SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
            iconBg.lineWidth = 1.5
            iconBg.position = CGPoint(x: -cardW / 2 + cardH * 0.45, y: 0)
            iconBg.name = card.name
            card.addChild(iconBg)

            let icon = SKLabelNode(text: unlocked ? hero.icon : (hero.id == "chinggis" ? "👑" : "🔒"))
            icon.fontSize = cardH * 0.38
            icon.verticalAlignmentMode = .center
            icon.position = iconBg.position
            icon.name = card.name
            card.addChild(icon)

            let nameL = UIFactory.label(hero.name, font: Fonts.bold, size: 12,
                                        color: SKColor(red: 0.94, green: 0.87, blue: 0.68, alpha: 1))
            nameL.horizontalAlignmentMode = .left
            nameL.position = CGPoint(x: -cardW / 2 + cardH * 0.85, y: cardH * 0.20)
            nameL.name = card.name
            card.addChild(nameL)

            let roleL = UIFactory.label(hero.role, font: Fonts.demi, size: 9,
                                        color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
            roleL.horizontalAlignmentMode = .left
            roleL.position = CGPoint(x: -cardW / 2 + cardH * 0.85, y: -cardH * 0.08)
            roleL.name = card.name
            card.addChild(roleL)

            // мастерийн од эсвэл нээх үнэ
            let m = Progress.mastery(hero.id)
            let bottomText = unlocked
                ? (m > 0 ? String(repeating: "★", count: m) + String(repeating: "☆", count: 5 - m) : "")
                : "🪙 \(hero.cost) — нээх"
            if !bottomText.isEmpty {
                let bottomL = UIFactory.label(bottomText, font: Fonts.bold, size: 9,
                                              color: SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1))
                bottomL.horizontalAlignmentMode = .left
                bottomL.position = CGPoint(x: -cardW / 2 + cardH * 0.85, y: -cardH * 0.34)
                bottomL.name = card.name
                card.addChild(bottomL)
            }
        }

        // сонгосон баатрын мэдээлэл
        let info = UIFactory.multiline("", font: Fonts.demi, size: 11,
                                       color: SKColor(red: 0.72, green: 0.64, blue: 0.49, alpha: 1),
                                       width: size.width * 0.86)
        info.position = CGPoint(x: cx, y: size.height * 0.335)
        c.addChild(info)
        infoLabel = info

        // хэцүү байдал
        let diffTitle = UIFactory.label("Хэцүү байдал:", font: Fonts.demi, size: 11,
                                        color: SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1))
        diffTitle.position = CGPoint(x: cx - 190, y: size.height * 0.195)
        c.addChild(diffTitle)

        let pillW: CGFloat = 96
        for (i, d) in GameData.difficulties.enumerated() {
            let pill = SKShapeNode(rectOf: CGSize(width: pillW, height: 30), cornerRadius: 15)
            pill.name = "diff\(i)"
            pill.position = CGPoint(x: cx - 60 + CGFloat(i) * (pillW + 12), y: size.height * 0.195)
            c.addChild(pill)
            diffNodes.append(pill)

            let l = UIFactory.label(d.name, font: Fonts.bold, size: 12)
            l.position = pill.position
            l.name = pill.name
            c.addChild(l)
            diffLabels.append(l)
        }

        let start = UIFactory.button(text: "ТУЛААНД МОРД", name: "start", width: 240, height: 46)
        start.position = CGPoint(x: cx, y: max(30, size.height * 0.075))
        c.addChild(start)

        refreshSelection()
    }

    private func refreshSelection() {
        if !Progress.isUnlocked(GameData.heroes[selIndex].id) { selIndex = 0 }
        for (i, card) in cardNodes.enumerated() {
            let selected = i == selIndex
            let premium = GameData.heroes[i].id == "chinggis"
            card.strokeColor = (selected || premium)
                ? Palette.goldLight
                : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            card.lineWidth = selected ? 3 : 2
            card.setScale(selected ? 1.05 : 1.0)
        }
        for (i, pill) in diffNodes.enumerated() {
            let selected = i == selDiff
            pill.fillColor = selected ? Palette.gold : SKColor(red: 0.20, green: 0.15, blue: 0.07, alpha: 1)
            pill.strokeColor = selected ? Palette.goldDark : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            pill.lineWidth = 1.5
            diffLabels[i].fontColor = selected
                ? SKColor(red: 0.14, green: 0.08, blue: 0.01, alpha: 1)
                : Palette.parchment
        }
        let hero = GameData.heroes[selIndex]
        infoLabel?.text = "\(hero.desc)\n\(hero.s1.icon) \(hero.s1.name) — \(hero.s1.desc)   \(hero.s2.icon) \(hero.s2.name) — \(hero.s2.desc)"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        guard let name = UIFactory.nodeName(at: t.location(in: self), in: self) else { return }

        if name == "start", let view = view {
            Haptics.skill()
            Audio.shared.play("tap")
            let battle = BattleScene(size: size, heroIndex: selIndex, difficultyIndex: selDiff)
            view.presentScene(battle, transition: .fade(withDuration: 0.6))
            return
        }
        for i in 0..<GameData.heroes.count where name == "card\(i)" {
            let hero = GameData.heroes[i]
            if Progress.isUnlocked(hero.id) {
                selIndex = i
                Haptics.hit()
                Audio.shared.play("tap")
                refreshSelection()
            } else if Progress.unlock(hero.id, cost: hero.cost) {
                selIndex = i
                Haptics.levelUp()
                Audio.shared.play("level", volume: 0.8)
                buildUI()   // картуудыг шинэчилж, нээгдсэнийг харуулна
            } else {
                Haptics.crash()
                Audio.shared.play("hit", volume: 0.6)
                goldLabel?.text = "Дахин \(hero.cost - Progress.gold) алт хэрэгтэй!"
                goldLabel?.fontColor = SKColor(red: 1.0, green: 0.42, blue: 0.34, alpha: 1)
                goldLabel?.run(.sequence([
                    .wait(forDuration: 1.4),
                    .run { [weak self] in
                        self?.goldLabel?.text = "🪙 \(Progress.gold) алт"
                        self?.goldLabel?.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1)
                    }
                ]))
            }
            return
        }
        for i in 0..<GameData.difficulties.count where name == "diff\(i)" {
            selDiff = i
            Haptics.hit()
            Audio.shared.play("tap")
            refreshSelection()
            return
        }
    }
}
