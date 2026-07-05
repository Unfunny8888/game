import SpriteKit

// MARK: - Багууд ба нэгжийн төрлүүд

enum Team: Int {
    case mongol = 0      // тоглогчийн тал
    case khwarezm = 1    // дайсны тал — Хорезмын хаант улс

    var bannerColor: SKColor { self == .mongol ? Palette.mongolBlue : Palette.enemyRed }
    var hpColor: SKColor { self == .mongol ? Palette.hpGreen : Palette.hpRed }
}

enum UnitKind {
    case minion, hero, tower, gate
}

// MARK: - Баатрын тодорхойлолт

struct SkillDef {
    let name: String
    let short: String
    let icon: String
    let cd: CGFloat
    let desc: String
}

struct HeroDef {
    let id: String
    let name: String
    let role: String
    let icon: String
    let color: SKColor
    let hp: CGFloat
    let dmg: CGFloat
    let range: CGFloat
    let speed: CGFloat
    let atkCd: CGFloat
    let desc: String
    let s1: SkillDef
    let s2: SkillDef
    var cost: Int = 0          // 0 = үнэгүй; бусад нь алтаар нээгдэнэ
}

struct DifficultyDef {
    let name: String
    let desc: String
    let minionHp: CGFloat
    let minionDmg: CGFloat
    let heroHp: CGFloat
    let heroDmg: CGFloat
    let goldMult: CGFloat      // тулааны шагналын үржүүлэгч
}

enum GameData {

    /// Тоглогчийн сонгож болох баатрууд
    static let heroes: [HeroDef] = [
        HeroDef(
            id: "chinggis",
            name: "Чингис хаан",
            role: "ТУЛААНЧ",
            icon: "⚔️",
            color: SKColor(red: 0.91, green: 0.71, blue: 0.30, alpha: 1),
            hp: 980, dmg: 66, range: 78, speed: 182, atkCd: 0.85,
            desc: "Их Монгол улсыг үндэслэгч эзэн хаан. Ойрын тулаанд хүчирхэг, тэнцвэртэй баатар.",
            s1: SkillDef(name: "Сэлмийн хуй", short: "Сэлэм", icon: "🌪", cd: 6,
                         desc: "Эргэн тойрны бүх дайсанд хүчтэй цохилт өгнө."),
            s2: SkillDef(name: "Тэнгэрийн ивээл", short: "Ивээл", icon: "🌟", cd: 14,
                         desc: "Амиа сэргээж, түр хугацаанд хурдална.")
        ),
        HeroDef(
            id: "zev",
            name: "Зэв жанжин",
            role: "ХАРВААЧ",
            icon: "🏹",
            color: SKColor(red: 0.56, green: 0.71, blue: 0.45, alpha: 1),
            hp: 760, dmg: 58, range: 250, speed: 190, atkCd: 0.78,
            desc: "Чингис хааны шилдэг мэргэн харваач жанжин. Холоос аюултай.",
            s1: SkillDef(name: "Нэвтлэх сум", short: "Сум", icon: "➶", cd: 5,
                         desc: "Шулуун чиглэлд бүх дайсныг нэвтлэн онох сум харвана."),
            s2: SkillDef(name: "Сумны бороо", short: "Бороо", icon: "🌧", cd: 12,
                         desc: "Ойрын дайсны бөөгнөрөл дээр сумны бороо буулгана.")
        ),
        HeroDef(
            id: "subedei",
            name: "Сүбээдэй баатар",
            role: "ХАМГААЛАГЧ",
            icon: "🛡",
            color: SKColor(red: 0.62, green: 0.71, blue: 0.79, alpha: 1),
            hp: 1200, dmg: 50, range: 68, speed: 170, atkCd: 0.95,
            desc: "Түүхэн дэх хамгийн агуу жанжны нэг. Бат бөх, довтолгооны мастер.",
            s1: SkillDef(name: "Шуурган довтолгоо", short: "Довтлох", icon: "💨", cd: 7,
                         desc: "Урагш ухасхийж, дайрсан дайснаа зогсооно."),
            s2: SkillDef(name: "Төмөр бамбай", short: "Бамбай", icon: "🛡", cd: 13,
                         desc: "Түр зуур хохирлыг шингээх бамбай авна."),
            cost: 150
        ),
        HeroDef(
            id: "mukhulai",
            name: "Мухулай жанжин",
            role: "ЖАНЖИН",
            icon: "🪓",
            color: SKColor(red: 0.79, green: 0.54, blue: 0.29, alpha: 1),
            hp: 1050, dmg: 60, range: 72, speed: 172, atkCd: 0.9,
            desc: "Чингис хааны итгэлт жанжин, зүүн гарын түмний ноён.",
            s1: SkillDef(name: "Газар доргилт", short: "Доргилт", icon: "💥", cd: 7,
                         desc: "Ойр орчмын дайснуудыг цохиж, хэсэг зогсооно."),
            s2: SkillDef(name: "Тугийн уриа", short: "Уриа", icon: "🚩", cd: 15,
                         desc: "Түр хугацаанд довтолгооны хүчээ ихээхэн нэмнэ."),
            cost: 300
        ),
        HeroDef(
            id: "boorchi",
            name: "Боорчи ноён",
            role: "ШАЛМАГ ДАЙЧИН",
            icon: "🗡",
            color: SKColor(red: 0.48, green: 0.76, blue: 0.69, alpha: 1),
            hp: 850, dmg: 56, range: 70, speed: 200, atkCd: 0.7,
            desc: "Хааны анхны нөхөр, дөрвөн хүлгийн тэргүүн. Хурдан сэлэмчин.",
            s1: SkillDef(name: "Шуурхай цохилт", short: "Цохилт", icon: "⚡", cd: 6,
                         desc: "Хамгийн ойрын дайсныг гурван удаа даран цохино."),
            s2: SkillDef(name: "Салхины хөл", short: "Салхи", icon: "🌬", cd: 12,
                         desc: "Хурдаа эрс нэмж, гайхшралаас чөлөөлөгдөнө."),
            cost: 500
        ),
        HeroDef(
            id: "khasar",
            name: "Хасар мэргэн",
            role: "ХАРВААЧ",
            icon: "🎯",
            color: SKColor(red: 0.69, green: 0.52, blue: 0.84, alpha: 1),
            hp: 720, dmg: 54, range: 260, speed: 185, atkCd: 0.8,
            desc: "Чингис хааны дүү, домогт хүчтэй мэргэн харваач.",
            s1: SkillDef(name: "Гурван сум", short: "3 сум", icon: "☄️", cd: 6,
                         desc: "Ойрын гурван дайсан руу зэрэг сум харвана."),
            s2: SkillDef(name: "Тэнгэрийн нум", short: "Нум", icon: "🌠", cd: 13,
                         desc: "Түр хугацаанд харвах хурдаа хоёр дахин нэмнэ."),
            cost: 750
        )
    ]

    /// Хэцүү байдлын түвшингүүд — дайсны хүчийг үржүүлнэ
    static let difficulties: [DifficultyDef] = [
        DifficultyDef(name: "Хялбар", desc: "Шинэ тоглогчдод",
                      minionHp: 0.80, minionDmg: 0.80, heroHp: 0.85, heroDmg: 0.85, goldMult: 0.8),
        DifficultyDef(name: "Дунд", desc: "Жинхэнэ тулаан",
                      minionHp: 1.00, minionDmg: 1.00, heroHp: 1.00, heroDmg: 1.00, goldMult: 1.0),
        DifficultyDef(name: "Хэцүү", desc: "Зөвхөн баатруудад",
                      minionHp: 1.28, minionDmg: 1.22, heroHp: 1.25, heroDmg: 1.18, goldMult: 1.4)
    ]

    /// Дайсны удирдагч — Хорезмын хунтайж
    static let jalal = HeroDef(
        id: "jalal",
        name: "Жалал ад-Дин",
        role: "ДАЙСАН",
        icon: "🗡",
        color: SKColor(red: 0.78, green: 0.35, blue: 0.29, alpha: 1),
        hp: 900, dmg: 60, range: 80, speed: 172, atkCd: 0.9,
        desc: "",
        s1: SkillDef(name: "Илдний давалгаа", short: "Илд", icon: "🗡", cd: 7, desc: ""),
        s2: SkillDef(name: "—", short: "—", icon: "", cd: 15, desc: "")
    )
}

// MARK: - Дэлхийн зохион байгуулалт (world units, y дээшээ)

enum World {
    static let width: CGFloat = 3000
    static let viewH: CGFloat = 760          // дэлгэцийн өндөрт харагдах world нэгж
    static let groundBottom: CGFloat = 70    // явж болох доод хязгаар
    static let groundTop: CGFloat = 500      // явж болох дээд хязгаар
    static let laneY: CGFloat = 285          // замын гол шугам

    static let pGateX: CGFloat = 130
    static let pTowerX: CGFloat = 720
    static let eTowerX: CGFloat = 2280
    static let eGateX: CGFloat = 2870

    static let waveInterval: CGFloat = 17
    static let maxLevel = 12

    static func xpNeed(_ level: Int) -> CGFloat { 90 + CGFloat(level - 1) * 70 }
}

// MARK: - Өнгөний палитр

enum Palette {
    static let gold      = SKColor(red: 0.91, green: 0.71, blue: 0.30, alpha: 1)
    static let goldLight = SKColor(red: 0.95, green: 0.79, blue: 0.42, alpha: 1)
    static let goldDark  = SKColor(red: 0.43, green: 0.30, blue: 0.07, alpha: 1)
    static let parchment = SKColor(red: 0.94, green: 0.89, blue: 0.77, alpha: 1)
    static let dim       = SKColor(red: 0.60, green: 0.52, blue: 0.38, alpha: 1)
    static let night     = SKColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 1)
    static let panel     = SKColor(red: 0.16, green: 0.11, blue: 0.05, alpha: 0.96)

    static let mongolBlue = SKColor(red: 0.35, green: 0.65, blue: 1.00, alpha: 1)
    static let enemyRed   = SKColor(red: 1.00, green: 0.42, blue: 0.34, alpha: 1)
    static let hpGreen    = SKColor(red: 0.31, green: 0.82, blue: 0.42, alpha: 1)
    static let hpRed      = SKColor(red: 0.91, green: 0.35, blue: 0.29, alpha: 1)
    static let shieldBlue = SKColor(red: 0.62, green: 0.82, blue: 0.91, alpha: 1)
    static let xpBlue     = SKColor(red: 0.56, green: 0.78, blue: 1.00, alpha: 1)

    static let skyTopDay    = SKColor(red: 0.17, green: 0.24, blue: 0.40, alpha: 1)
    static let skyMidDay    = SKColor(red: 0.54, green: 0.42, blue: 0.29, alpha: 1)
    static let skyHorizon   = SKColor(red: 0.79, green: 0.58, blue: 0.36, alpha: 1)
    static let hillFar      = SKColor(red: 0.29, green: 0.23, blue: 0.34, alpha: 1)
    static let hillNear     = SKColor(red: 0.36, green: 0.27, blue: 0.28, alpha: 1)
    static let grassTop     = SKColor(red: 0.48, green: 0.54, blue: 0.27, alpha: 1)
    static let grassBottom  = SKColor(red: 0.30, green: 0.35, blue: 0.16, alpha: 1)
    static let lane         = SKColor(red: 0.63, green: 0.51, blue: 0.31, alpha: 0.35)
}

enum Fonts {
    static let heavy = "AvenirNext-Heavy"
    static let bold  = "AvenirNext-Bold"
    static let demi  = "AvenirNext-DemiBold"
}
