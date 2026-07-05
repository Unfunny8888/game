import SpriteKit

/// Ялалт / ялагдлын дэлгэц
final class EndScene: SKScene {

    private let stats: MatchStats
    private var built = false
    private var content: SKNode?

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

        let title = UIFactory.label(stats.win ? "ЯЛАЛТ!" : "ЯЛАГДАЛ",
                                    font: Fonts.heavy,
                                    size: min(58, size.width * 0.1),
                                    color: stats.win
                                        ? Palette.goldLight
                                        : SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1))
        title.position = CGPoint(x: cx, y: size.height * 0.68)
        c.addChild(title)

        let flavour = stats.win
            ? "Мөнх тэнгэрийн хүчин дор дайсны хаалга нурлаа!"
            : "Их хаалга нурсан ч дайн дуусаагүй..."
        let mins = stats.seconds / 60
        let secs = stats.seconds % 60
        let diffName = GameData.difficulties[stats.difficultyIndex].name
        var statsText = "\(flavour)\nАлалт: \(stats.kills)  ·  Түвшин: \(stats.level)  ·  Хугацаа: \(mins):\(String(format: "%02d", secs))  ·  Хэцүү байдал: \(diffName)"
        statsText += "\n🪙 Олсон алт: +\(stats.goldEarned)  ·  Нийт: \(stats.totalGold)"
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
        statsL.position = CGPoint(x: cx, y: size.height * 0.44)
        c.addChild(statsL)

        let again = UIFactory.button(text: "ДАХИН ТУЛАЛДАХ", name: "again", width: 250, height: 52)
        again.position = CGPoint(x: cx - 140, y: size.height * 0.22)
        c.addChild(again)

        let change = UIFactory.button(text: "БААТАР СОЛИХ", name: "change", width: 230, height: 52, primary: false)
        change.position = CGPoint(x: cx + 140, y: size.height * 0.22)
        c.addChild(change)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let view = view else { return }
        let name = UIFactory.nodeName(at: t.location(in: self), in: self)

        if name == "again" {
            Haptics.skill()
            Audio.shared.play("tap")
            let battle = BattleScene(size: size, heroIndex: stats.heroIndex,
                                     difficultyIndex: stats.difficultyIndex)
            view.presentScene(battle, transition: .fade(withDuration: 0.5))
        } else if name == "change" {
            Haptics.hit()
            Audio.shared.play("tap")
            let select = HeroSelectScene(size: size)
            select.scaleMode = .resizeFill
            view.presentScene(select, transition: .fade(withDuration: 0.4))
        }
    }
}
