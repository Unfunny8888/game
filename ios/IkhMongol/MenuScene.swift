import SpriteKit

/// Үндсэн цэс
final class MenuScene: SKScene {

    private var built = false
    private var content: SKNode?

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        built = true
        Audio.shared.preload()
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

        // Соёмбо сүлд
        let emblem = makeSoyombo(height: min(140, size.height * 0.17))
        emblem.position = CGPoint(x: cx, y: size.height * 0.855)
        c.addChild(emblem)

        let ornament = UIFactory.label("⁂ ᠊᠊᠊᠊᠊᠊᠊᠊᠊᠊ ⁂", font: Fonts.demi, size: 13,
                                       color: SKColor(red: 0.79, green: 0.59, blue: 0.25, alpha: 1))
        ornament.position = CGPoint(x: cx, y: size.height * 0.71)
        c.addChild(ornament)

        let title = UIFactory.label("ИХ МОНГОЛ", font: Fonts.heavy,
                                    size: min(54, size.width * 0.085), color: Palette.gold)
        title.position = CGPoint(x: cx, y: size.height * 0.615)
        c.addChild(title)

        let subtitle = UIFactory.label("ТУЛААНЫ ТАЛБАР", font: Fonts.bold, size: 17,
                                       color: SKColor(red: 0.85, green: 0.76, blue: 0.60, alpha: 1))
        subtitle.position = CGPoint(x: cx, y: size.height * 0.535)
        c.addChild(subtitle)

        let tagline = UIFactory.multiline(
            "Мөнх тэнгэрийн хүчин дор — Чингис хааны дайчдыг удирдан,\nХорезмын их хаалгыг нурааж, талбарыг эзэгнэ!",
            font: Fonts.demi, size: 12,
            color: SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1),
            width: size.width * 0.8)
        tagline.position = CGPoint(x: cx, y: size.height * 0.45)
        c.addChild(tagline)

        let hub = UIFactory.button(text: "🏛 ХАР ХОРУМ — ТӨВ ХОТ", name: "hub", width: 300, height: 54)
        hub.position = CGPoint(x: cx, y: size.height * 0.37)
        c.addChild(hub)

        let campaign = UIFactory.button(text: "⚔️ АЯН ДАЙН", name: "campaign", width: 200, height: 40, primary: false)
        campaign.position = CGPoint(x: cx - 110, y: size.height * 0.265)
        c.addChild(campaign)

        let play = UIFactory.button(text: "Чөлөөт тулаан", name: "play", width: 200, height: 40, primary: false)
        play.position = CGPoint(x: cx + 110, y: size.height * 0.265)
        c.addChild(play)

        let pvp = UIFactory.button(text: "🤝 НАЙЗТАЙГАА", name: "pvp", width: 200, height: 40, primary: false)
        pvp.position = CGPoint(x: cx - 110, y: size.height * 0.185)
        c.addChild(pvp)

        let camp = UIFactory.button(text: "🏕️ БУУРЬ", name: "camp", width: 200, height: 40, primary: false)
        camp.position = CGPoint(x: cx + 110, y: size.height * 0.185)
        c.addChild(camp)

        let unread = GameData.unreadChapterCount
        let storyText = unread > 0 ? "📜 ТҮҮХ (\(unread))" : "📜 ТҮҮХ"
        let story = UIFactory.button(text: storyText, name: "story", width: 200, height: 40, primary: false)
        story.position = CGPoint(x: cx - 110, y: size.height * 0.105)
        c.addChild(story)

        let codex = UIFactory.button(text: "📚 НЭВТЭРХИЙ", name: "codex", width: 200, height: 40, primary: false)
        codex.position = CGPoint(x: cx + 110, y: size.height * 0.105)
        c.addChild(codex)
    }

    /// Соёмбо сүлдийг SpriteKit хэлбэрээр байгуулна (гал·нар·сар·гурвалжин·баганууд·хос загас).
    private func makeSoyombo(height: CGFloat) -> SKNode {
        let root = SKNode()
        let node = SKNode()
        root.addChild(node)
        let gold = SKColor(red: 0.91, green: 0.72, blue: 0.31, alpha: 1)
        let panel = SKColor(red: 0.12, green: 0.08, blue: 0.035, alpha: 1)

        // арын медальон (сийлбэрийг цэвэр болгоно)
        let plaque = SKShapeNode(rectOf: CGSize(width: 96, height: 176), cornerRadius: 20)
        plaque.fillColor = panel
        plaque.strokeColor = SKColor(red: 0.43, green: 0.31, blue: 0.13, alpha: 1)
        plaque.lineWidth = 3
        node.addChild(plaque)

        func poly(_ pts: [CGPoint], _ col: SKColor) {
            let p = UIBezierPath()
            p.move(to: pts[0]); for q in pts.dropFirst() { p.addLine(to: q) }; p.close()
            let s = SKShapeNode(path: p.cgPath); s.fillColor = col; s.strokeColor = .clear
            node.addChild(s)
        }
        func disc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ col: SKColor) {
            let s = SKShapeNode(circleOfRadius: r); s.fillColor = col; s.strokeColor = .clear
            s.position = CGPoint(x: x, y: y); node.addChild(s)
        }
        func barRect(_ y: CGFloat, _ half: CGFloat, _ h: CGFloat) {
            let s = SKShapeNode(rectOf: CGSize(width: half * 2, height: h), cornerRadius: 2)
            s.fillColor = gold; s.strokeColor = .clear; s.position = CGPoint(x: 0, y: y)
            node.addChild(s)
        }

        // 1. гал — гурван дөл (y дээшээ)
        barRect(53, 9, 4)
        poly([CGPoint(x: 0, y: 54), CGPoint(x: -5.5, y: 74), CGPoint(x: 0, y: 84), CGPoint(x: 5.5, y: 74)], gold)
        poly([CGPoint(x: -10, y: 54), CGPoint(x: -14, y: 68), CGPoint(x: -6, y: 64)], gold)
        poly([CGPoint(x: 10, y: 54), CGPoint(x: 14, y: 68), CGPoint(x: 6, y: 64)], gold)
        // 2. сар — хавирган (доор нь эхэлж зурж, дараа нь нар дээр нь)
        disc(0, 26, 11, gold)
        disc(0, 33.5, 10, panel)
        // 3. нар
        disc(0, 42, 7, gold)
        // 4. дээд гурвалжин (доош)
        poly([CGPoint(x: -15, y: 14), CGPoint(x: 15, y: 14), CGPoint(x: 0, y: -2)], gold)
        // 5. дээд хэвтээ баганა
        barRect(-9, 20, 6)
        // 6. хос загас (yin-yang)
        let yy: CGFloat = -26, R: CGFloat = 14
        disc(0, yy, R, gold)
        let rhalf = SKShapeNode(rectOf: CGSize(width: R, height: R * 2)); rhalf.fillColor = panel
        rhalf.strokeColor = .clear; rhalf.position = CGPoint(x: R / 2, y: yy); node.addChild(rhalf)
        disc(0, yy + R / 2, R / 2, gold)
        disc(0, yy - R / 2, R / 2, panel)
        disc(0, yy + R / 2, 2.6, panel)
        disc(0, yy - R / 2, 2.6, gold)
        // 7. доод хэвтээ баганя
        barRect(-43, 20, 6)
        // 8. доод гурвалжин (доош)
        poly([CGPoint(x: -15, y: -50), CGPoint(x: 15, y: -50), CGPoint(x: 0, y: -66)], gold)
        // 9. хоёр босоо багана (хана)
        for sgn: CGFloat in [-1, 1] {
            let s = SKShapeNode(rectOf: CGSize(width: 6, height: 80), cornerRadius: 3)
            s.fillColor = gold; s.strokeColor = .clear
            s.position = CGPoint(x: sgn * 27, y: -26); node.addChild(s)
        }

        // 150 нэгж өндөртэй загварыг зорьсон өндөрт тааруулна
        root.setScale(height / 150)
        return root
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let name = UIFactory.nodeName(at: t.location(in: self), in: self)
        if name == "hub", let view = view {
            Haptics.skill()
            Audio.shared.play("tap")
            let hub = HubScene(size: size)
            hub.scaleMode = .resizeFill
            view.presentScene(hub, transition: .fade(withDuration: 0.4))
        } else if name == "campaign", let view = view {
            Haptics.skill()
            Audio.shared.play("tap")
            let camp = CampaignScene(size: size)
            camp.scaleMode = .resizeFill
            view.presentScene(camp, transition: .fade(withDuration: 0.4))
        } else if name == "play", let view = view {
            Haptics.skill()
            Audio.shared.play("tap")
            let select = HeroSelectScene(size: size)
            select.scaleMode = .resizeFill
            view.presentScene(select, transition: .fade(withDuration: 0.4))
        } else if name == "story", let view = view {
            Haptics.hit()
            Audio.shared.play("tap")
            let story = StoryScene(size: size)
            story.scaleMode = .resizeFill
            view.presentScene(story, transition: .fade(withDuration: 0.4))
        } else if name == "pvp", let view = view {
            Haptics.hit()
            Audio.shared.play("tap")
            let lobby = PvpLobbyScene(size: size)
            lobby.scaleMode = .resizeFill
            view.presentScene(lobby, transition: .fade(withDuration: 0.4))
        } else if name == "codex", let view = view {
            Haptics.hit()
            Audio.shared.play("tap")
            let codex = CodexScene(size: size)
            codex.scaleMode = .resizeFill
            view.presentScene(codex, transition: .fade(withDuration: 0.4))
        } else if name == "camp", let view = view {
            Haptics.hit()
            Audio.shared.play("tap")
            let camp = CampScene(size: size)
            camp.scaleMode = .resizeFill
            view.presentScene(camp, transition: .fade(withDuration: 0.4))
        }
    }
}
