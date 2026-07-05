import SpriteKit

/// Нэвтэрхий толь — Монголын түүх, соёл, баатрын тухай сургалтын нэвтэрхий толь
final class CodexScene: SKScene {

    private var built = false
    private var content: SKNode?
    private var catIndex = 0

    // гүйлгэх контейнер
    private let scrollNode = SKNode()
    private var scrollMinY: CGFloat = 0
    private var scrollMaxY: CGFloat = 0
    private var listTopY: CGFloat = 0
    private var listBottomY: CGFloat = 0
    private weak var scrollTouch: UITouch?
    private var lastTouchY: CGFloat = 0
    private var touchStartY: CGFloat = 0
    private var dragged = false

    // картуудыг таних (даран дэлгэрэнгүй унших)
    private var cards: [(entry: CodexEntry, node: SKShapeNode)] = []
    private var detailNode: SKNode?

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        Audio.shared.startMusic()
        buildUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        if detailNode != nil { closeDetail() }
        buildUI()
    }

    private func buildUI() {
        content?.removeFromParent()
        scrollNode.removeAllChildren()
        cards.removeAll()
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

        let title = UIFactory.label("📚 НЭВТЭРХИЙ ТОЛЬ", font: Fonts.heavy, size: 19, color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height - 24)
        c.addChild(title)

        let hint = UIFactory.label("Картыг дарж дэлгэрэнгүй уншина уу", font: Fonts.demi, size: 10,
                                   color: SKColor(red: 0.55, green: 0.46, blue: 0.30, alpha: 1))
        hint.position = CGPoint(x: cx, y: size.height - 40)
        c.addChild(hint)

        // ангиллын таб
        let cats = GameData.codex
        let tabW: CGFloat = min(150, (size.width - 40) / CGFloat(cats.count))
        let totalW = tabW * CGFloat(cats.count) + 8 * CGFloat(cats.count - 1)
        let startX = cx - totalW / 2 + tabW / 2
        for (i, cat) in cats.enumerated() {
            let pill = SKShapeNode(rectOf: CGSize(width: tabW, height: 30), cornerRadius: 15)
            let sel = i == catIndex
            pill.fillColor = sel ? Palette.gold : SKColor(red: 0.20, green: 0.15, blue: 0.07, alpha: 1)
            pill.strokeColor = sel ? Palette.goldDark : SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            pill.lineWidth = 1.5
            pill.position = CGPoint(x: startX + CGFloat(i) * (tabW + 8), y: size.height - 66)
            pill.name = "cat\(i)"
            c.addChild(pill)
            let l = UIFactory.label(cat.name, font: Fonts.bold, size: 12,
                                    color: sel ? SKColor(red: 0.14, green: 0.08, blue: 0.01, alpha: 1) : Palette.parchment)
            l.position = pill.position
            l.name = "cat\(i)"
            c.addChild(l)
        }

        let back = UIFactory.button(text: "БУЦАХ", name: "back", width: 170, height: 40, primary: false)
        back.position = CGPoint(x: cx, y: max(24, size.height * 0.06))
        back.zPosition = 20
        c.addChild(back)

        // ── гүйлгэх жагсаалт ──
        let crop = SKCropNode()
        listTopY = size.height - 86
        listBottomY = max(24, size.height * 0.06) + 30
        let listH = listTopY - listBottomY
        let listW = min(660, size.width - 30)
        let mask = SKSpriteNode(color: .white, size: CGSize(width: listW, height: listH))
        mask.position = CGPoint(x: cx, y: listBottomY + listH / 2)
        crop.maskNode = mask
        crop.addChild(scrollNode)
        c.addChild(crop)

        // картуудыг зурна (дээрээс доош)
        var y = listTopY - 6
        let cardW = listW - 6
        for e in cats[catIndex].entries {
            // жагсаалтад товч тайлбар
            let preview = shorten(e.text, limit: 96)
            let bodyText = UIFactory.multiline(preview, font: Fonts.demi, size: 10.5,
                                               color: SKColor(red: 0.78, green: 0.71, blue: 0.56, alpha: 1),
                                               width: cardW - 66)
            let textH = bodyText.calculateAccumulatedFrame().height
            let cardH = max(60, textH + 44)
            let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 10)
            card.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.94)
            card.strokeColor = SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            card.lineWidth = 1.5
            card.position = CGPoint(x: cx, y: y - cardH / 2)
            scrollNode.addChild(card)
            cards.append((e, card))

            let icon = SKLabelNode(text: e.icon)
            icon.fontSize = 28
            icon.verticalAlignmentMode = .center
            icon.position = CGPoint(x: -cardW / 2 + 26, y: cardH / 2 - 24)
            card.addChild(icon)

            let titleL = UIFactory.label(e.title, font: Fonts.heavy, size: 13,
                                         color: SKColor(red: 0.94, green: 0.87, blue: 0.68, alpha: 1))
            titleL.horizontalAlignmentMode = .left
            titleL.position = CGPoint(x: -cardW / 2 + 48, y: cardH / 2 - 16)
            card.addChild(titleL)

            let subL = UIFactory.label(e.sub, font: Fonts.demi, size: 9.5,
                                       color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
            subL.horizontalAlignmentMode = .left
            subL.position = CGPoint(x: -cardW / 2 + 48, y: cardH / 2 - 30)
            card.addChild(subL)

            bodyText.horizontalAlignmentMode = .left
            bodyText.verticalAlignmentMode = .top
            bodyText.position = CGPoint(x: -cardW / 2 + 48, y: cardH / 2 - 40)
            card.addChild(bodyText)

            // "цааш унших" сануулга
            let more = UIFactory.label("цааш унших ›", font: Fonts.bold, size: 9.5,
                                       color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
            more.horizontalAlignmentMode = .right
            more.position = CGPoint(x: cardW / 2 - 12, y: -cardH / 2 + 10)
            card.addChild(more)

            y -= cardH + 8
        }

        // гүйлгэх хязгаар
        let contentH = (listTopY - 6) - y
        scrollMinY = 0
        scrollMaxY = max(0, contentH - (listTopY - listBottomY))
        scrollNode.position = .zero
    }

    /// Урт текстийг богиносгоно
    private func shorten(_ s: String, limit: Int) -> String {
        if s.count <= limit { return s }
        let idx = s.index(s.startIndex, offsetBy: limit)
        var cut = String(s[..<idx])
        if let sp = cut.lastIndex(of: " ") { cut = String(cut[..<sp]) }
        return cut + "…"
    }

    // MARK: - Дэлгэрэнгүй харах

    private func showDetail(_ e: CodexEntry) {
        detailNode?.removeFromParent()
        let d = SKNode()
        d.zPosition = 100
        detailNode = d
        addChild(d)

        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.name = "detailDim"
        d.addChild(dim)

        let cx = size.width / 2
        let panelW = min(640, size.width - 30)
        let panelH = min(size.height - 60, size.height * 0.86)
        let panelTop = size.height / 2 + panelH / 2
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 14)
        panel.fillColor = SKColor(red: 0.15, green: 0.10, blue: 0.04, alpha: 0.99)
        panel.strokeColor = Palette.goldDark
        panel.lineWidth = 2
        panel.position = CGPoint(x: cx, y: size.height / 2)
        d.addChild(panel)

        let icon = SKLabelNode(text: e.icon)
        icon.fontSize = 40
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: cx, y: panelTop - 40)
        d.addChild(icon)

        let titleL = UIFactory.label(e.title, font: Fonts.heavy, size: 18,
                                     color: SKColor(red: 0.96, green: 0.89, blue: 0.70, alpha: 1))
        titleL.position = CGPoint(x: cx, y: panelTop - 74)
        d.addChild(titleL)

        let subL = UIFactory.label(e.sub, font: Fonts.demi, size: 12,
                                   color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
        subL.position = CGPoint(x: cx, y: panelTop - 96)
        d.addChild(subL)

        let body = UIFactory.multiline(e.text, font: Fonts.demi, size: 12.5,
                                       color: SKColor(red: 0.83, green: 0.76, blue: 0.60, alpha: 1),
                                       width: panelW - 44)
        body.verticalAlignmentMode = .top
        body.position = CGPoint(x: cx, y: panelTop - 116)
        d.addChild(body)

        let close = UIFactory.button(text: "ХААХ", name: "detailClose", width: 170, height: 42, primary: false)
        close.position = CGPoint(x: cx, y: size.height / 2 - panelH / 2 + 32)
        close.zPosition = 110
        d.addChild(close)

        Audio.shared.play("tap")
        Haptics.hit()
    }

    private func closeDetail() {
        detailNode?.removeFromParent()
        detailNode = nil
    }

    // MARK: - Оролт

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)

        // дэлгэрэнгүй нээлттэй бол — дарахад хаана
        if detailNode != nil {
            if let name = UIFactory.nodeName(at: p, in: self), name == "detailClose" {
                Audio.shared.play("tap")
            }
            closeDetail()
            return
        }

        if let name = UIFactory.nodeName(at: p, in: self) {
            if name == "back", let view = view {
                Audio.shared.play("tap")
                let menu = MenuScene(size: size)
                menu.scaleMode = .resizeFill
                view.presentScene(menu, transition: .fade(withDuration: 0.35))
                return
            }
            for i in 0..<GameData.codex.count where name == "cat\(i)" {
                if i != catIndex {
                    catIndex = i
                    Audio.shared.play("tap")
                    Haptics.hit()
                    buildUI()
                }
                return
            }
        }
        // гүйлгэх / дарах эхлэл
        scrollTouch = t
        lastTouchY = p.y
        touchStartY = p.y
        dragged = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches where t === scrollTouch {
            let p = t.location(in: self)
            let dy = p.y - lastTouchY
            lastTouchY = p.y
            if abs(p.y - touchStartY) > 8 { dragged = true }
            // байгалийн гүйлгэлт: хуруу дээш → доод карт харагдана
            var ny = scrollNode.position.y + dy
            ny = max(scrollMinY, min(scrollMaxY, ny))
            scrollNode.position.y = ny
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches where t === scrollTouch {
            if !dragged {
                // дарах — доор байгаа картыг олж дэлгэрэнгүй нээнэ
                let local = t.location(in: scrollNode)
                for (entry, node) in cards where node.frame.contains(local) {
                    showDetail(entry)
                    break
                }
            }
            scrollTouch = nil
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches where t === scrollTouch { scrollTouch = nil }
    }
}
