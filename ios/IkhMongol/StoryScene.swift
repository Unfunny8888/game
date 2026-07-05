import SpriteKit

/// Монголын нууц товчоо — түүхийн бүлгүүдийн дэлгэц
final class StoryScene: SKScene {

    private var built = false
    private var content: SKNode?
    private var readingIndex: Int?   // nil = жагсаалт, утга = уншиж буй бүлэг

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

        if let idx = readingIndex {
            buildReader(in: c, chapterIndex: idx)
        } else {
            buildList(in: c)
        }
    }

    // MARK: - Бүлгийн жагсаалт (2 багана × 4 мөр)

    private func buildList(in c: SKNode) {
        let cx = size.width / 2

        let title = UIFactory.label("МОНГОЛЫН НУУЦ ТОВЧОО", font: Fonts.heavy, size: 20, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 30)
        c.addChild(title)

        let sub = UIFactory.label("Тэмүжингээс Чингис хаан хүртэлх зам · Тоглох тусам бүлгүүд нээгдэнэ",
                                  font: Fonts.demi, size: 10,
                                  color: SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1))
        sub.position = CGPoint(x: cx, y: size.height - 48)
        c.addChild(sub)

        let rowW = min(360, (size.width - 60) / 2)
        let rowH: CGFloat = 38
        let gapX: CGFloat = 14
        let gapY: CGFloat = 9
        let topY = size.height - 84

        for (i, ch) in GameData.chapters.enumerated() {
            let col = CGFloat(i / 4)          // эхний 4 зүүн баганад
            let row = CGFloat(i % 4)
            let unlocked = ch.req.isMet
            let unread = unlocked && !Progress.readChapters.contains(ch.id)

            let node = SKShapeNode(rectOf: CGSize(width: rowW, height: rowH), cornerRadius: 9)
            node.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.96)
            node.strokeColor = SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            node.lineWidth = 1.5
            node.alpha = unlocked ? 1 : 0.5
            node.name = "chapter\(i)"
            node.position = CGPoint(x: cx + (col == 0 ? -1 : 1) * (rowW / 2 + gapX / 2),
                                    y: topY - row * (rowH + gapY))
            c.addChild(node)

            let icon = UIFactory.label(unlocked ? "📜" : "🔒", size: 15)
            icon.position = CGPoint(x: -rowW / 2 + 22, y: 0)
            icon.name = node.name
            node.addChild(icon)

            let titleL = UIFactory.label("\(i + 1). " + (unlocked ? ch.title : "???"),
                                         font: Fonts.bold, size: 11,
                                         color: SKColor(red: 0.94, green: 0.87, blue: 0.68, alpha: 1))
            titleL.horizontalAlignmentMode = .left
            titleL.position = CGPoint(x: -rowW / 2 + 40, y: unlocked && !unread ? 0 : 5)
            titleL.name = node.name
            node.addChild(titleL)

            let subText = unlocked ? (unread ? "● шинэ" : "") : ch.req.text
            if !subText.isEmpty {
                let subL = UIFactory.label(subText, font: Fonts.demi, size: 8.5,
                                           color: unread
                                            ? SKColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1)
                                            : SKColor(red: 0.54, green: 0.46, blue: 0.31, alpha: 1))
                subL.horizontalAlignmentMode = .left
                subL.position = CGPoint(x: -rowW / 2 + 40, y: -9)
                subL.name = node.name
                node.addChild(subL)
            }
        }

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 180, height: 42, primary: false)
        back.position = CGPoint(x: cx, y: max(28, size.height * 0.07))
        c.addChild(back)
    }

    // MARK: - Уншигч (илгэн цаасны хуудас)

    private func buildReader(in c: SKNode, chapterIndex: Int) {
        let ch = GameData.chapters[chapterIndex]
        Progress.markChapterRead(ch.id)
        let cx = size.width / 2

        let pageW = min(620, size.width * 0.86)
        let pageH = size.height * 0.72
        let page = SKShapeNode(rectOf: CGSize(width: pageW, height: pageH), cornerRadius: 6)
        page.fillColor = SKColor(red: 0.93, green: 0.88, blue: 0.76, alpha: 1)
        page.strokeColor = SKColor(red: 0.66, green: 0.51, blue: 0.23, alpha: 1)
        page.lineWidth = 2.5
        page.position = CGPoint(x: cx, y: size.height * 0.60)
        c.addChild(page)

        let ornament = UIFactory.label("⁂ ᠊᠊᠊᠊᠊᠊ ⁂", font: Fonts.serif, size: 11,
                                       color: SKColor(red: 0.66, green: 0.46, blue: 0.23, alpha: 1))
        ornament.position = CGPoint(x: 0, y: pageH / 2 - 22)
        page.addChild(ornament)

        let titleL = UIFactory.label("\(chapterIndex + 1). " + ch.title, font: Fonts.serifBold, size: 17,
                                     color: SKColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1))
        titleL.position = CGPoint(x: 0, y: pageH / 2 - 46)
        page.addChild(titleL)

        let body = UIFactory.multiline(ch.text, font: Fonts.serif, size: 12.5,
                                       color: SKColor(red: 0.23, green: 0.16, blue: 0.08, alpha: 1),
                                       width: pageW - 56)
        body.verticalAlignmentMode = .top
        body.position = CGPoint(x: 0, y: pageH / 2 - 62)
        page.addChild(body)

        let srcL = UIFactory.label("— Монголын нууц товчоо, " + ch.src, font: Fonts.serif, size: 10.5,
                                   color: SKColor(red: 0.48, green: 0.36, blue: 0.18, alpha: 1))
        srcL.horizontalAlignmentMode = .right
        srcL.position = CGPoint(x: pageW / 2 - 24, y: -pageH / 2 + 16)
        page.addChild(srcL)

        let back = UIFactory.button(text: "БУЦАХ", name: "readerBack", width: 160, height: 40, primary: false)
        let hasNext = chapterIndex + 1 < GameData.chapters.count
            && GameData.chapters[chapterIndex + 1].req.isMet
        if hasNext {
            back.position = CGPoint(x: cx - 110, y: max(26, size.height * 0.065))
            let next = UIFactory.button(text: "ДАРААХ БҮЛЭГ →", name: "readerNext", width: 200, height: 40)
            next.position = CGPoint(x: cx + 90, y: max(26, size.height * 0.065))
            c.addChild(next)
        } else {
            back.position = CGPoint(x: cx, y: max(26, size.height * 0.065))
        }
        c.addChild(back)
    }

    // MARK: - Оролт

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
        if name == "readerBack" {
            Audio.shared.play("tap")
            readingIndex = nil
            buildUI()
            return
        }
        if name == "readerNext", let idx = readingIndex {
            Audio.shared.play("tap")
            readingIndex = idx + 1
            buildUI()
            return
        }
        for i in 0..<GameData.chapters.count where name == "chapter\(i)" {
            guard GameData.chapters[i].req.isMet else { return }
            Audio.shared.play("tap")
            Haptics.hit()
            readingIndex = i
            buildUI()
            return
        }
    }
}
