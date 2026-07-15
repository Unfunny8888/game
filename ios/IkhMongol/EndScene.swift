import SpriteKit

/// Ялалт / ялагдлын дэлгэц
final class EndScene: SKScene {

    private let stats: MatchStats
    private var built = false
    private var content: SKNode?
    private var marchReady = true          // regroup gate: цугартал мородохгүй
    private weak var nextButton: SKNode?

    init(size: CGSize, stats: MatchStats) {
        self.stats = stats
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

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
        removeAllActions()          // өмнөх мөчлөгийн анимацийг цэвэрлэнэ (дахин байгуулахад)
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
        let isConquest = stats.win && stats.campaignLevel != nil

        let title = UIFactory.label(isConquest ? "⚔️ ЭЗЛЭГДЛЭЭ" : (stats.win ? "ЯЛАЛТ!" : "ЯЛАГДАЛ"),
                                    font: Fonts.heavy,
                                    size: isConquest ? min(44, size.width * 0.08) : min(58, size.width * 0.1),
                                    color: stats.win
                                        ? Palette.goldLight
                                        : SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1))
        title.position = CGPoint(x: cx, y: size.height * 0.72)
        c.addChild(title)

        // V2 эзлэлтийн мөчлөгийн зурвас (аяны ялалтад)
        if isConquest {
            buildConquestStrip(in: c, at: CGPoint(x: cx, y: size.height * 0.60))
            celebrateConquest(in: c)
        }

        let flavour = isConquest
            ? "\(stats.cityTitle ?? "Хот") хотыг эзлэн авлаа!"
            : (stats.win
                ? "Мөнх тэнгэрийн хүчин дор дайсны хаалга нурлаа!"
                : "Их хаалга нурсан ч дайн дуусаагүй...")
        let mins = stats.seconds / 60
        let secs = stats.seconds % 60
        let modeName = stats.campaignLevel.map { "\($0 + 1)-р түвшин" }
            ?? GameData.difficulties[stats.difficultyIndex].name
        var statsText = "\(flavour)\nАлалт: \(stats.kills)  ·  Түвшин: \(stats.level)  ·  Хугацаа: \(mins):\(String(format: "%02d", secs))  ·  \(modeName)"
        statsText += "\n🪙 Олсон алт: +\(stats.goldEarned)  ·  Нийт: \(stats.totalGold)"
        if isConquest && (stats.lootHorses > 0 || stats.lootIron > 0) {
            statsText += "\n🐎 +\(stats.lootHorses) адуу · ⚒️ +\(stats.lootIron) төмөр (буурьт цуглав)"
        }
        if let line = stats.campaignLine {
            statsText += "\n\(line)"
        }
        if stats.gainedStar {
            let hero = GameData.heroes[stats.heroIndex]
            let stars = String(repeating: "★", count: stats.masteryStars)
                + String(repeating: "☆", count: 5 - stats.masteryStars)
            statsText += "\n\(hero.name) мастери: \(stars) (+3% хүч)"
        }
        if let chapter = stats.newChapter {
            statsText += "\n📜 Нууц товчооны шинэ бүлэг: «\(chapter)»"
        }
        if let next = GameData.heroes.first(where: { !Progress.isUnlocked($0.id) }) {
            let hint = Progress.gold >= next.cost
                ? "нээх боломжтой!"
                : "дахин \(next.cost - Progress.gold) алт"
            statsText += "\nДараагийн баатар \(next.name): 🪙 \(next.cost) (\(hint))"
        }
        let statsL = UIFactory.multiline(statsText, font: Fonts.demi, size: 13,
                                         color: SKColor(red: 0.85, green: 0.76, blue: 0.60, alpha: 1),
                                         width: size.width * 0.85)
        statsL.position = CGPoint(x: cx, y: size.height * (isConquest ? 0.40 : 0.44))
        c.addChild(statsL)

        if stats.isPvp {
            // PvP: дахин тоглохын тулд лобби руу, эсвэл цэс рүү
            let again = UIFactory.button(text: "🤝 ДАХИН ХОЛБОГДОХ", name: "pvpAgain", width: 250, height: 50)
            again.position = CGPoint(x: cx - 140, y: size.height * 0.2)
            c.addChild(again)

            let menu = UIFactory.button(text: "ҮНДСЭН ЦЭС", name: "menu", width: 210, height: 50, primary: false)
            menu.position = CGPoint(x: cx + 140, y: size.height * 0.2)
            c.addChild(menu)
        } else if let level = stats.campaignLevel {
            // Аян дайн: ялбал дараагийн түвшин, эс бөгөөс дахин оролдох
            let hasNext = stats.win && level + 1 < GameData.campaign.count && Progress.campaign > level
            if hasNext {
                let next = UIFactory.button(text: "МОРОДОХ →", name: "nextLevel", width: 250, height: 50)
                next.position = CGPoint(x: cx - 140, y: size.height * 0.2)
                c.addChild(next)
                nextButton = next
                if isConquest {          // отряд цугартал түгжинэ (regroup gate)
                    marchReady = false
                    next.alpha = 0.45
                }
            } else {
                let retry = UIFactory.button(text: "ДАХИН ОРОЛДОХ", name: "again", width: 250, height: 50)
                retry.position = CGPoint(x: cx - 140, y: size.height * 0.2)
                c.addChild(retry)
            }
            let menu = UIFactory.button(text: "АЯН ДАЙН", name: "campaign", width: 210, height: 50, primary: false)
            menu.position = CGPoint(x: cx + 140, y: size.height * 0.2)
            c.addChild(menu)
        } else {
            let again = UIFactory.button(text: "ДАХИН ТУЛАЛДАХ", name: "again", width: 230, height: 48)
            again.position = CGPoint(x: cx - 175, y: size.height * 0.2)
            c.addChild(again)

            let change = UIFactory.button(text: "БААТАР СОЛИХ", name: "change", width: 200, height: 48, primary: false)
            change.position = CGPoint(x: cx + 55, y: size.height * 0.2)
            c.addChild(change)

            let menu = UIFactory.button(text: "ЦЭС", name: "menu", width: 110, height: 48, primary: false)
            menu.position = CGPoint(x: cx + 225, y: size.height * 0.2)
            c.addChild(menu)
        }
    }

    /// V2 эзлэлтийн мөчлөгийн зурвас: Эзлэх → Буурьших → Отрядаа цуглуул → Мородох.
    /// «Отрядаа цуглуул» алхам дуустал МОРОДОХ товч түгжээтэй (regroup gate).
    private func buildConquestStrip(in parent: SKNode, at center: CGPoint) {
        let steps: [(String, String)] = [("⚔️", "Эзлэх"), ("🏕️", "Буурьших"),
                                         ("🤝", "Отрядаа цуглуул"), ("🐎", "Мородох")]
        let chipW: CGFloat = min(120, (size.width - 40) / 4)
        let gap: CGFloat = 6
        let totalW = chipW * 4 + gap * 3
        var x = center.x - totalW / 2 + chipW / 2
        var chips: [SKNode] = []
        var checks: [SKLabelNode] = []
        var names: [SKLabelNode] = []
        for (icon, name) in steps {
            let chip = SKNode()
            chip.position = CGPoint(x: x, y: center.y)
            chip.alpha = 0.4
            parent.addChild(chip)
            let bg = SKShapeNode(rectOf: CGSize(width: chipW, height: 46), cornerRadius: 10)
            bg.fillColor = SKColor(white: 0.1, alpha: 0.5)
            bg.strokeColor = SKColor(red: 0.43, green: 0.33, blue: 0.15, alpha: 1)
            bg.lineWidth = 1
            chip.addChild(bg)
            let ic = SKLabelNode(text: icon)
            ic.fontSize = 20; ic.verticalAlignmentMode = .center
            ic.position = CGPoint(x: -8, y: 8)
            chip.addChild(ic)
            let ck = SKLabelNode(text: "✓")
            ck.fontSize = 13; ck.verticalAlignmentMode = .center
            ck.fontColor = SKColor(red: 0.55, green: 0.9, blue: 0.48, alpha: 1)
            ck.position = CGPoint(x: 12, y: 8); ck.isHidden = true
            chip.addChild(ck)
            let nm = UIFactory.label(name, font: Fonts.demi, size: 9, color: Palette.parchment)
            nm.position = CGPoint(x: 0, y: -13)
            chip.addChild(nm)
            chips.append(chip); checks.append(ck); names.append(nm)
            x += chipW + gap
        }
        chips[0].alpha = 1; checks[0].isHidden = false      // Эзлэх — тэр даруй
        run(.sequence([
            .wait(forDuration: 0.4),
            .run { chips[1].alpha = 1; checks[1].isHidden = false; Audio.shared.play("tap", volume: 0.5) },
            .wait(forDuration: 0.4),
            .run { chips[2].alpha = 1; names[2].text = "Отряд цугларч байна…" },
            .wait(forDuration: 0.7),
            .run { [weak self] in
                checks[2].isHidden = false
                let a = self?.stats.warbandAlive ?? 0, tot = self?.stats.warbandTotal ?? 0
                names[2].text = tot > 0 ? "Отряд \(a)/\(tot)" : "Отряд бэлэн"
                Audio.shared.play("tap", volume: 0.6)
            },
            .wait(forDuration: 0.3),
            .run { [weak self] in
                chips[3].alpha = 1
                self?.marchReady = true
                let pulse = SKAction.repeatForever(.sequence([
                    .scale(to: 1.07, duration: 0.55), .scale(to: 1.0, duration: 0.55)]))
                chips[3].run(pulse)
                if let nb = self?.nextButton {
                    nb.run(.fadeAlpha(to: 1, duration: 0.25))
                    nb.run(pulse)
                }
                Audio.shared.play("win", volume: 0.7)
            }
        ]))
    }

    /// Эзлэлтийн ялалтын алтан баяр хөөр (confetti) + дайны бөмбөр
    private func celebrateConquest(in parent: SKNode) {
        Audio.shared.play("drum", volume: 0.7)
        let colors = [SKColor(red: 0.91, green: 0.71, blue: 0.30, alpha: 1),
                      SKColor(red: 0.97, green: 0.84, blue: 0.48, alpha: 1),
                      SKColor(red: 0.78, green: 0.28, blue: 0.23, alpha: 1),
                      SKColor(red: 0.55, green: 0.90, blue: 0.48, alpha: 1),
                      SKColor(red: 0.37, green: 0.63, blue: 0.85, alpha: 1)]
        for _ in 0..<90 {
            let s = CGFloat.random(in: 4...9)
            let bit = SKSpriteNode(color: colors[Int.random(in: 0..<colors.count)],
                                   size: CGSize(width: s, height: s * 0.6))
            bit.position = CGPoint(x: size.width * CGFloat.random(in: 0.2...0.8),
                                   y: size.height + CGFloat.random(in: 0...120))
            bit.zRotation = CGFloat.random(in: 0...(2 * .pi))
            bit.zPosition = 60
            parent.addChild(bit)
            let dur = Double.random(in: 1.8...3.0)
            let dx = CGFloat.random(in: -90...90)
            let fall = SKAction.moveBy(x: dx, y: -(size.height + 160), duration: dur)
            fall.timingMode = .easeIn
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -8...8), duration: dur)
            bit.run(.sequence([
                .group([fall, spin, .sequence([.wait(forDuration: dur * 0.6), .fadeOut(withDuration: dur * 0.4)])]),
                .removeFromParent()
            ]))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let view = view else { return }
        let name = UIFactory.nodeName(at: t.location(in: self), in: self)

        // regroup gate — отряд цугартал МОРОДОХ товч ажиллахгүй
        if name == "nextLevel" && !marchReady {
            Haptics.hit()
            return
        }

        if name == "again" {
            Haptics.skill()
            Audio.shared.play("tap")
            if let level = stats.campaignLevel {
                // Аяны түвшинг дахин эхлэхэд даалгаврын танилцуулгыг эхлээд харуулна
                let intro = MissionIntroScene(size: size, heroIndex: stats.heroIndex, level: level)
                view.presentScene(intro, transition: .fade(withDuration: 0.5))
            } else {
                let battle = BattleScene(size: size, heroIndex: stats.heroIndex,
                                         difficultyIndex: stats.difficultyIndex,
                                         campaignLevel: nil)
                view.presentScene(battle, transition: .fade(withDuration: 0.5))
            }
        } else if name == "nextLevel", let level = stats.campaignLevel {
            Haptics.skill()
            Audio.shared.play("tap")
            // Дараагийн түвшний даалгаврын танилцуулгыг харуулна
            let intro = MissionIntroScene(size: size, heroIndex: stats.heroIndex, level: level + 1)
            view.presentScene(intro, transition: .fade(withDuration: 0.5))
        } else if name == "campaign" {
            Haptics.hit()
            Audio.shared.play("tap")
            let camp = CampaignScene(size: size)
            camp.scaleMode = .resizeFill
            view.presentScene(camp, transition: .fade(withDuration: 0.4))
        } else if name == "change" {
            Haptics.hit()
            Audio.shared.play("tap")
            let select = HeroSelectScene(size: size)
            select.scaleMode = .resizeFill
            view.presentScene(select, transition: .fade(withDuration: 0.4))
        } else if name == "menu" {
            Haptics.hit()
            Audio.shared.play("tap")
            let menu = MenuScene(size: size)
            menu.scaleMode = .resizeFill
            view.presentScene(menu, transition: .fade(withDuration: 0.4))
        } else if name == "pvpAgain" {
            Haptics.hit()
            Audio.shared.play("tap")
            let lobby = PvpLobbyScene(size: size)
            lobby.scaleMode = .resizeFill
            view.presentScene(lobby, transition: .fade(withDuration: 0.4))
        }
    }
}
