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
            id: "temuujin",
            name: "Тэмүжин",
            role: "ЗАЛУУ ДАЙЧИН",
            icon: "🐺",
            color: SKColor(red: 0.85, green: 0.64, blue: 0.35, alpha: 1),
            hp: 850, dmg: 56, range: 75, speed: 185, atkCd: 0.9,
            desc: "Ирээдүйн их хааны залуу нас. Эр зориг бадарсан залуу дайчин.",
            s1: SkillDef(name: "Хурц сэлэм", short: "Сэлэм", icon: "⚔️", cd: 6,
                         desc: "Урд байгаа дайснуудыг хүчтэй цавчина."),
            s2: SkillDef(name: "Өсөх хүч", short: "Хүч", icon: "🌱", cd: 14,
                         desc: "Амиа хэсэгчлэн сэргээнэ.")
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
        ),
        HeroDef(
            id: "chinggis",
            name: "Чингис хаан",
            role: "ИХ ЭЗЭН ХААН 👑",
            icon: "⚔️",
            color: SKColor(red: 0.91, green: 0.71, blue: 0.30, alpha: 1),
            hp: 1150, dmg: 78, range: 80, speed: 188, atkCd: 0.8,
            desc: "Их Монгол улсын эзэн хаан — тоглоомын хамгийн хүчирхэг дээд зэргийн баатар.",
            s1: SkillDef(name: "Сэлмийн хуй", short: "Сэлэм", icon: "🌪", cd: 6,
                         desc: "Эргэн тойрны бүх дайсанд аймшигт хүчтэй цохилт өгнө."),
            s2: SkillDef(name: "Тэнгэрийн ивээл", short: "Ивээл", icon: "🌟", cd: 13,
                         desc: "Амиа ихээр сэргээж, удаан хугацаанд хурдална."),
            cost: 1500
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

// MARK: - Нэвтэрхий толь (encyclopedia — сургалтын агуулга)

struct CodexEntry {
    let icon: String
    let title: String
    let sub: String
    let text: String
}
struct CodexCategory {
    let name: String
    let entries: [CodexEntry]
}

extension GameData {
    static let codex: [CodexCategory] = [
        CodexCategory(name: "Баатрууд", entries: [
            CodexEntry(icon: "🐺", title: "Тэмүжин / Чингис хаан", sub: "~1162–1227",
                       text: "Есүхэй баатрын хүү. Олон дайтагч овгийг нэгтгэж 1206 онд Их Монгол Улсыг байгуулав. «Их засаг» хууль, шуудангийн өртөө, бичиг үсэг, шашны хүлцэл зэргийг нэвтрүүлсэн төр ёсны агуу шинэчлэгч."),
            CodexEntry(icon: "🏹", title: "Зэв (Жэбэ)", sub: "«Сум» жанжин",
                       text: "Анх Тэмүжинг тулаанд сумаар онсон дайсан байсан ч үнэнч зангаараа өршөөгдөж жанжин болов. Сүбээдэйтэй хамт Перс, Кавказ, Оросыг тагнан довтолсон домогт морин цэргийн удирдагч."),
            CodexEntry(icon: "🛡", title: "Сүбээдэй баатар", sub: "1175–1248",
                       text: "Түүхэн дэх хамгийн агуу цэргийн жанжны нэг. 20 гаруй улсыг эзэлж, Оросын ноёдыг Калк голд, Унгар Польшийг Европт бут цохив. Уриангхай гаралтай, стратегийн суут ухаантан."),
            CodexEntry(icon: "🪓", title: "Мухулай жанжин", sub: "1170–1223",
                       text: "Зүүн гарын түмний ноён, Хойд Хятадыг захирах орлогч хаан (гуй ван) цол авсан. Жинь гүрний эсрэг аяныг Чингис хааны өмнөөс удирдсан итгэлт жанжин."),
            CodexEntry(icon: "🗡", title: "Боорчи ноён", sub: "Анхны нөхөр",
                       text: "Хулгайлагдсан адуу хайж явсан залуу Тэмүжинд туслаж, насан туршийн анд болов. Чингис хааны «дөрвөн хүлэг»-ийн тэргүүн, хамгийн итгэлт хүмүүсийн нэг."),
            CodexEntry(icon: "🎯", title: "Хасар мэргэн", sub: "Хааны дүү",
                       text: "Чингис хааны дүү, домогт хүчтэй мэргэн харваач. Асар хүчтэй гар, хол оновчтой харвадгаараа алдартай. Нэгтгэлийн тулаануудад чухал үүрэг гүйцэтгэсэн.")
        ]),
        CodexCategory(name: "Дайснууд", entries: [
            CodexEntry(icon: "⚔️", title: "Тайчууд", sub: "МНТ §79–87",
                       text: "Хамаг Монголын хүчирхэг овог. Есүхэйг үхсэний дараа Өэлүн эхийн айлыг орхиж, дараа нь залуу Тэмүжинг олзолж боол болгосон. Тэмүжин эндээс зугтсан нь эр зоригийнх нь эхлэл болов."),
            CodexEntry(icon: "🏕", title: "Мэргэд", sub: "МНТ §104–113",
                       text: "Сэлэнгэ мөрний сав нутгийн овог. Есүхэй Өэлүнг мэргэдээс булаасны өшөөгөөр тэд Бөртэ үжинг олзолсон. Тэмүжин холбоотнуудынхаа хамт мэргэдийг бут цохиж хатнаа авардаг."),
            CodexEntry(icon: "🤝", title: "Жамуха", sub: "МНТ §128",
                       text: "Тэмүжинтэй гурван удаа анд болсон найз бөгөөд хожмын гол өрсөлдөгч. «Гүр хаан» цол авсан ч харгислалаараа дэмжигчдээ алдав. Далан балжудын тулаанд Тэмүжинг ялж байсан."),
            CodexEntry(icon: "✝️", title: "Ван хан (Хэрэйд)", sub: "МНТ §183",
                       text: "Тоорил Ван хан — Хэрэйдийн (Христийн Несториан шашинт) хаан, Есүхэйн анд, Тэмүжинг ивээн тэтгэгч. 1203 онд холбоо эвдэрч, Жэр хавцалд ялагдав."),
            CodexEntry(icon: "📜", title: "Таян хан (Найман)", sub: "МНТ §189",
                       text: "Найманы (Алтайн, Уйгур бичигтэй) хаан. 1204 онд Тэмүжинд ялагдсанаар Хамаг Монгол нэгдэв. Найманы бичээч Тататунга Монголд бичиг үсэг нэвтрүүлсэн."),
            CodexEntry(icon: "🕌", title: "Мухаммед II шах", sub: "Хорезм, 1219",
                       text: "Хорезмын эзэнт гүрний султан. Отрарт монголын элч, худалдаачдыг алуулсан нь их аяны шалтгаан болов. Гүрэн нь нурж, тэрээр Каспийн тэнгисийн арал дээр гачигдан нас барав."),
            CodexEntry(icon: "🗡", title: "Жалал ад-Дин", sub: "Инд, 1221",
                       text: "Хорезмын сүүлчийн зоригт хунтайж (Мангуберди). Инд мөрний тулаанд ялагдсан ч мориороо эгц эргээс мөрөнд үсэрч амиа авран зугтсан нь Чингис хааны биширлийг төрүүлсэн.")
        ]),
        CodexCategory(name: "Соёл", entries: [
            CodexEntry(icon: "⛺", title: "Гэр", sub: "Нүүдлийн орон сууц",
                       text: "Модон хана, тооно, унины хийцтэй, эсгийгээр бүрсэн зөөврийн орон сууц. Задлаад тэргэн дээр ачиж нүүдэг. Тооногоор гэрэл орж, утаа гардаг. Дугуй хэлбэр нь салхи даахад тохиромжтой."),
            CodexEntry(icon: "🛖", title: "Тэрэг", sub: "Ачааны хэрэгсэл",
                       text: "Модон дугуйтай, үхэр буюу тэмээгээр хөллөдөг тээврийн хэрэгсэл. Гэр, эд хогшлоо нүүлгэхэд зайлшгүй. Их нүүдэлд хэдэн зуун тэрэг цуваа болон хөдөлдөг байв."),
            CodexEntry(icon: "🪨", title: "Овоо", sub: "Тахилгын босгол",
                       text: "Уул, давааны дээр босгосон чулуун овоо. Аялагчид чулуу нэмж, хөх хадаг өргөн, эргэн тойрон гурван удаа тойрч замын аюулгүй, сайн сайхныг ерөөдөг уламжлалтай."),
            CodexEntry(icon: "🎻", title: "Морин хуур", sub: "Ардын хөгжим",
                       text: "Адууны толгойгоор чимэглэсэн хоёр чавхдаст нумт хөгжим. Монгол ардын хөгжмийн бэлгэдэл, тал нутгийн дуу аялгууны сэтгэлийг илэрхийлдэг. ЮНЕСКО-гийн соёлын өвд бүртгэгдсэн."),
            CodexEntry(icon: "🎤", title: "Хөөмий", sub: "Хоолойн урлаг",
                       text: "Нэг хоолойгоор нэгэн зэрэг хоёр ая — гүн басс дуу ба исгэрсэн дээд аялгуу — гаргадаг өвөрмөц дуулах урлаг. Байгаль, уул усны дуу авиаг дуурайдаг. ЮНЕСКО-гийн өвд бүртгэгдсэн."),
            CodexEntry(icon: "🏹", title: "Монгол нум", sub: "Гол зэвсэг",
                       text: "Эвэр, мод, шөрмөсөөр хийсэн нугарамтгай (композит) нум. Мориноос давхиж байхдаа буцаж эргэн харвах чадвар нь монгол цэргийн дэлхийг байлдан дагуулсан гол давуу тал байв."),
            CodexEntry(icon: "🕌", title: "Хорезмын сүм & минарет", sub: "Төв Ази",
                       text: "Ислам соёлын цэнхэр вааран бөмбөгөрт сүм, өндөр минарет цамхаг. Самарканд, Бухар нь дэлхийд алдартай эрдэм соёлын төв байв. Монголчууд эдгээр хотыг 1220 онд эзэлсэн.")
        ]),
        CodexCategory(name: "Он цаг", entries: [
            CodexEntry(icon: "👶", title: "~1162", sub: "Мэндэлсэн нь",
                       text: "Тэмүжин Онон голын Дэлүүн болдогт баруун гартаа нөж атган мэндэлэв — агуу заяаны бэлгэ тэмдэг гэж үздэг."),
            CodexEntry(icon: "⛓", title: "~1177", sub: "Зугталт",
                       text: "Тайчиудын боолчлолоос харуулын толгойг цохиж мултран зугтав. Энэ эр зориг түүний нэрийг тал нутагт цуурайтуулж эхлэв."),
            CodexEntry(icon: "🏇", title: "1189", sub: "Анхны хаан",
                       text: "Хамаг Монголын хаан өргөмжлөгдөв. Ван хан, Жамуха нартай хүчээ уяж мэргэд, татаарыг дийлж эхлэв."),
            CodexEntry(icon: "👑", title: "1206", sub: "Их Монгол Улс",
                       text: "Онон мөрний эхэнд их хуралдай чуулж, есөн хөлт цагаан тугаа босгоод Тэмүжинд «Чингис хаан» цол өргөмжлөв. Монголчууд нэгдэв."),
            CodexEntry(icon: "🏰", title: "1211–1215", sub: "Жинь аян",
                       text: "Хойд Хятадын Жинь гүрний эсрэг аян эхлэв. 1215 онд нийслэл Бээжинг (Жунду) эзэлж, Торгоны замд хүрэв."),
            CodexEntry(icon: "🕌", title: "1219–1221", sub: "Баруун их аян",
                       text: "Отрарын хядлагын хариуд Хорезмыг довтлов. Бухар, Самарканд, Ургэнч унаж, Жалал ад-Дин Инд мөрөн уруу шахагдав."),
            CodexEntry(icon: "⚰️", title: "1227", sub: "Их хааны төгсгөл",
                       text: "Чингис хаан Тангуд (Баруун Ся) аяны үеэр таалал төгсөв. Оршуулгын газар нь өнөө хэр нууц хэвээр."),
            CodexEntry(icon: "🗺", title: "1279", sub: "Хамгийн том хүрээ",
                       text: "Ач хүү Хубилай хаан Өмнөд Сүн гүрнийг эзэлж Юань улсыг байгуулав. Эзэнт гүрэн Номхон далайгаас Дунай хүртэл — түүхэн дэх хамгийн том тив залгасан гүрэн болов.")
        ])
    ]
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
    static let serif = "Georgia"
    static let serifBold = "Georgia-Bold"
}

// MARK: - Монголын нууц товчоо — түүхийн бүлгүүд

enum ChapterReq {
    case always
    case level(Int)      // аян дайны түвшин дуусгасан тоо

    var isMet: Bool {
        switch self {
        case .always: return true
        case .level(let n): return Progress.campaign >= n
        }
    }

    var text: String {
        switch self {
        case .always: return ""
        case .level(let n): return "Аян дайны \(n)-р түвшинг дуусгаж нээнэ"
        }
    }
}

struct Chapter {
    let id: String
    let title: String
    let src: String
    let req: ChapterReq
    let text: String
}

extension GameData {

    static let chapters: [Chapter] = [
        Chapter(id: "ch1", title: "Чонын удам", src: "§1", req: .always,
                text: "Дээд тэнгэрээс заяат төрсөн Бөртэ чоно, түүний гэргий Гоо марал хоёр их далайг гэтэлж ирээд, Онон мөрний эх Бурхан халдун ууланд нутаглажээ. Тэдний удам угсаа өнөр өтгөн болж, монгол түмний язгуур эндээс эхэлсэн гэдэг. Хожим энэ удмаас дэлхийг донсолгох их хаан мэндлэх ажээ."),
        Chapter(id: "ch2", title: "Шагайн чинээ нөж атгасан хүү", src: "§59", req: .level(1),
                text: "Есүхэй баатрын гэргий Өэлүн үжин Онон мөрний Дэлүүн болдогт хөвгүүн төрүүлэв. Хүү баруун гартаа шагайн чинээ нөж атган мэндэлжээ — энэ нь агуу заяаны бэлгэ тэмдэг байлаа. Тэр цагт татаарын Тэмүжин-Үгэг дийлсэн тул хүүдээ Тэмүжин хэмээх нэр өгөв."),
        Chapter(id: "ch3", title: "Таван мөчир сум", src: "§19–22", req: .level(2),
                text: "Алун гоо эх таван хөвгүүндээ тус бүр нэг мөчир өгч хугал гэв — хялбархан хугарав. Тэгээд таван мөчрийг багцлан өгөхөд хэн нь ч хугалж чадсангүй. «Ганц нэгээрээ бол та нар хэврэг мөчир мэт. Эв нэгдэлтэй бол хэн ч та нарыг дийлэхгүй» гэж сургажээ."),
        Chapter(id: "ch4", title: "Өнчин хөвгүүний тангараг", src: "§68–73", req: .level(3),
                text: "Есүхэй баатар татаарын хорд хорлогдон нас барахад Тэмүжин есөн настай байв. Тайчууд овгийнхон бэлбэсэн Өэлүн эхийг үр хүүхэдтэй нь эзгүй талд орхин нүүжээ. Эх нь үндэс, жимс түүж, Онон мөрнөөс загас барьж үр хүүхдээ өсгөв. Зовлон дундаас хатан зориг төржээ."),
        Chapter(id: "ch5", title: "Анхны анд Боорчи", src: "§90–93", req: .level(4),
                text: "Тэмүжиний найман шарга морийг хулгайч авч одоход тэрбээр ганцаар мөрдөн хөөв. Замд гүү саж байсан Наху баяны хүү Боорчид учрахад тэр: «Эрийн зовлон адилхан. Би чамд нөхөр болъё» гээд хамт мордов. Ийнхүү анхны шадар анд олдож, хожмын их гүрний тулгын анхны чулуу тавигджээ."),
        Chapter(id: "ch6", title: "Бөртэ үжинг аварсан нь", src: "§104–113", req: .level(5),
                text: "Гурван мэргэд гэнэт довтолж, Тэмүжиний хатан Бөртэ үжинг олзолж одов. Тэмүжин Бурхан халдунд мөргөж, Тоорил хан, Жамуха нартай хүч хамтран мэргэдийг бут цохив. Ийнхүү хатнаа эргүүлэн авчирч, алдсанаа дайнаар нөхөж болдгийг харуулжээ."),
        Chapter(id: "ch7", title: "Дөрвөн нохой, дөрвөн хүлэг", src: "§195, 209", req: .level(6),
                text: "Чингис хаанд дөрвөн догшин «нохой» байв: Хубилай, Зэлмэ, Зэв, Сүбээдэй. Тулалдааны өдөр тэд хуй салхи мэт довтолно. Мөн дөрвөн «хүлэг» байв: Боорчи, Мухулай, Борохул, Чулуун. Эдгээр өрлөг жанжид газар дэлхийг доргиосон их аяныг тэргүүлжээ."),
        Chapter(id: "ch8", title: "Есөн хөлт цагаан туг", src: "§202", req: .level(8),
                text: "Барс жил (1206) Онон мөрний эхэнд их хуралдай чуулж, есөн хөлт цагаан тугаа босгоод, Тэмүжинд «Чингис хаан» цол өргөмжлөв. Хамаг Монголыг нэгтгэсэн их эзэн хаан ийнхүү мандаж, Мөнх тэнгэрийн хүчин дор Их Монгол Улс байгуулагдав.")
    ]

    static var unlockedChapterCount: Int {
        chapters.filter { $0.req.isMet }.count
    }

    static var unreadChapterCount: Int {
        chapters.filter { $0.req.isMet && !Progress.readChapters.contains($0.id) }.count
    }
}

// MARK: - Аян дайн — Нууц товчооны замаар 8 түвшин

/// Аяны даалгаврын төрөл — түвшин болгонд өөр зорилго (GTA маягийн эрхэм зорилго)
enum Objective {
    case reach(label: String)              // тэмдэглэсэн цэг уруу гүйж хүрэх
    case collect(count: Int, label: String) // тарсан объектуудыг цуглуулах
    case rescue(label: String)             // NPC-д хүрч, гэртээ дагуулан авчрах
    case slay(count: Int, label: String)   // командлагчийг N удаа дийлэх
    case survive(secs: CGFloat, label: String) // тодорхой хугацаанд тэсэх
    case gate(label: String)               // дайсны их хаалгыг нураах (сонгодог)

    var label: String {
        switch self {
        case .reach(let l), .rescue(let l), .gate(let l): return l
        case .collect(_, let l), .slay(_, let l): return l
        case .survive(_, let l): return l
        }
    }
}

/// Аяны дундах динамик үйл явдал
enum CampaignEventKind { case reinforce, ambush, enrage }
struct CampaignEvent {
    let t: CGFloat            // хэдэн секундэд гарах
    let kind: CampaignEventKind
    let text: String
}

/// Дайсны соёл иргэншил — талбарын архитектурыг тодорхойлно
enum BattleTheme { case steppe, khwarezm }

struct CampaignLevel {
    let title: String
    let src: String
    let desc: String
    let minionMul: CGFloat   // цэргийн хүч
    let heroMul: CGFloat     // дайсны командлагчийн хүч
    let enemyName: String
    let reward: Int          // анх удаа даван туулбал өгөх бонус алт
    let objective: Objective
    let intro: String        // тулааны өмнөх түүхэн танилцуулга
    let events: [CampaignEvent]
    let theme: BattleTheme
    let fact: String         // түүхэн баримт (сургалтын зорилготой)
}

extension GameData {
    static let campaign: [CampaignLevel] = [
        CampaignLevel(title: "Зугталт", src: "МНТ §79–87",
                      desc: "Тайчиудаас зугтаж, баруун гарц уруу гүй.",
                      minionMul: 0.55, heroMul: 0.55, enemyName: "Тайчууд дайчин", reward: 80,
                      objective: .reach(label: "Тайчиудаас зугтаж, БАРУУН ГАРЦ уруу гүй"),
                      intro: "Тайчиудын Таргутай Тэмүжинг хүлж, боол болгов. Нэгэн шөнө хүү харуулын толгойг цохиж мултран, Онон голын харгайд нуугдав. Одоо шөнийн харанхуйгаар гарц уруу зугтах цаг!",
                      events: [CampaignEvent(t: 7, kind: .ambush, text: "Отолт! Тайчууд хажуугаас гарч ирлээ!")],
                      theme: .steppe,
                      fact: "Тайчууд бол Хамаг Монголын нэгэн овог. Есүхэйг нас барсны дараа тэд Өэлүн эхийн гэр бүлийг орхиж явсан. Тэмүжин ~1177 онд боолчлолоос зугтсан нь түүний хүч чадлын анхны шинж байв."),
        CampaignLevel(title: "Найман шарга морь", src: "МНТ §90–93",
                      desc: "Хулгайлагдсан 8 моримо цуглуулж буцааж ав.",
                      minionMul: 0.70, heroMul: 0.70, enemyName: "Хулгайн ноён", reward: 100,
                      objective: .collect(count: 8, label: "Хулгайлагдсан МОРИ цуглуул"),
                      intro: "Найман шарга унаган мориодыг маань хулгайч тууж одов. Тэмүжин ганц морьтой мөрдөн хөөж, замдаа Боорчитой учрав. Тарж бэлчсэн мориодоо цуглуулан гэртээ тууж авчир!",
                      events: [CampaignEvent(t: 9, kind: .reinforce, text: "Хулгайчид нэмэлт хүч дуудлаа!")],
                      theme: .steppe,
                      fact: "Монголчуудын хувьд адуу бол амьдралын үндэс — унаа, хоол, эд хөрөнгийн хэмжүүр. Морь хулгайлах нь ноцтой гэмт хэрэг байв. Энэ явдал Тэмүжин, Боорчи нарын анд барилдсан эхлэл болжээ."),
        CampaignLevel(title: "Бөртэг аврах", src: "МНТ §104–113",
                      desc: "Мэргэдээс Бөртэд хүрч, гэр орондоо авчир.",
                      minionMul: 0.85, heroMul: 0.85, enemyName: "Тогтоа бэх", reward: 120,
                      objective: .rescue(label: "БӨРТЭД хүрч, гэртээ дагуулан авчир"),
                      intro: "Гурван мэргэд гэнэт довтолж, Тэмүжиний хатан Бөртэ үжинг олзолж одов. Тэмүжин Тоорил хан, анд Жамуха хоёртой хүч нэгтгэн мэргэдийг мөрдөв. Бөртэдээ хүрч чөлөөлж, гэр орондоо аюулгүй хүргэ!",
                      events: [CampaignEvent(t: 6, kind: .reinforce, text: "Мэргэдийн харуул сэрлээ!"),
                               CampaignEvent(t: 16, kind: .ambush, text: "Гэрлэх замд отолт!")],
                      theme: .steppe,
                      fact: "Мэргэд бол Сэлэнгэ мөрний хүчирхэг овог. Бөртэг хулгайлсан нь эртний өшөө байв. Тэмүжин Тоорил хан, Жамуха нартай холбоо байгуулж мэргэдийг ялсан."),
        CampaignLevel(title: "Анд ба дайсан", src: "МНТ §128–129",
                      desc: "Далан балжудад анд Жамухаг гурван удаа дийл.",
                      minionMul: 1.00, heroMul: 1.00, enemyName: "Жамуха", reward: 150,
                      objective: .slay(count: 3, label: "ЖАМУХАГ дийл"),
                      intro: "Нэгэн цагийн андаа өргөсөн Жамуха эдүгээ эрх мэдлийн төлөө өрсөлдөгч болов. Далан балжудын хээр талд хоёр цэрэг нүүр тулав. Хайр гунигтай ч ялахаас өөр зам үгүй — андаа гурван удаа дийл!",
                      events: [CampaignEvent(t: 12, kind: .enrage, text: "Жамуха хилэгнэн дайрав!")],
                      theme: .steppe,
                      fact: "Жамуха, Тэмүжин хоёр гурван удаа анд болсон ч эрх мэдлийн төлөө хагарсан. 1187 оны орчим Далан балжудын тулаанд Жамуха ялсан ч харгислалаараа дэмжигчдээ алдаж эхэлсэн."),
        CampaignLevel(title: "Хэрэйдийн уналт", src: "МНТ §183–185",
                      desc: "Ван ханы хүчийг хоёр удаа буулгаж дуусга.",
                      minionMul: 1.12, heroMul: 1.10, enemyName: "Ван хан", reward: 180,
                      objective: .slay(count: 2, label: "ВАН ХАНЫГ дийл"),
                      intro: "Хэрэйдийн Тоорил Ван хан урвасан тул Тэмүжин эсэргүүцэв. Жэр хавцалд хэрэйдийн их цэрэг бүрэлгэв. Гурван өдрийн тулааны эцэст Ван ханы хүчийг бут ниргэ!",
                      events: [CampaignEvent(t: 10, kind: .reinforce, text: "Хэрэйдийн нөөц цэрэг ирлээ!"),
                               CampaignEvent(t: 22, kind: .enrage, text: "Ван хан эцсийн хүчээ дайчлав!")],
                      theme: .steppe,
                      fact: "Хэрэйд бол Христийн (Несториан) шашинтай хүчирхэг хаант улс. Ван хан Есүхэйн анд байсан ивээн тэтгэгч. 1203 онд холбоо задарч, Жэр хавцлын тулаанд Тэмүжин Хэрэйдийг эзэлсэн."),
        CampaignLevel(title: "Найманы төгсгөл", src: "МНТ §189–196",
                      desc: "Таян ханы хаалгыг нурааж, Найманыг эзэл.",
                      minionMul: 1.25, heroMul: 1.20, enemyName: "Таян хан", reward: 220,
                      objective: .gate(label: "Таян ханы ИХ ХААЛГЫГ нураа"),
                      intro: "Баруун зүгийн сүүлчийн их гүрэн — Найман. Таян хан монголчуудыг басамжлав. Тэмүжин шөнөдөө галаа олон асааж, тоогоо үржүүлэн харуулав. Таян ханы их хаалгыг нурааж, талыг нэгтгэ!",
                      events: [CampaignEvent(t: 14, kind: .reinforce, text: "Найманы нэмэлт цэрэг!"),
                               CampaignEvent(t: 28, kind: .reinforce, text: "Дахин нэмэлт хүч ирлээ!")],
                      theme: .steppe,
                      fact: "Найман бол Алтайн нутгийн соёл иргэншилтэй, Уйгур бичиг хэрэглэдэг овог. 1204 онд Таян ханыг ялж Хамаг Монголыг нэгтгэсний дараа 1206 онд Чингис хаан өргөмжлөгдсөн."),
        CampaignLevel(title: "Хорезмын аян", src: "1219 он",
                      desc: "Их баруун аян — Шахын довтолгоог 80 секунд тэсэж няц.",
                      minionMul: 1.38, heroMul: 1.30, enemyName: "Мухаммед шах", reward: 260,
                      objective: .survive(secs: 80, label: "Шахын довтолгоог ТЭСЭЖ ГАРАХ"),
                      intro: "Отрарын захирагч монголын элч, худалдаачдыг алав. Хилэгнэсэн Чингис хаан их баруун аяныг зарлав. Хорезмын Мухаммед шахын тоо томшгүй цэрэг давалгаалан ирнэ — байраа бариж 80 секунд тэсэж гар!",
                      events: [CampaignEvent(t: 25, kind: .ambush, text: "Шахын морьт цэрэг хажуугаас цохив!"),
                               CampaignEvent(t: 50, kind: .enrage, text: "Шах эцсийн бүх хүчээ шидлээ!")],
                      theme: .khwarezm,
                      fact: "Хорезмын эзэнт гүрэн бол Төв Азийн Ислам шашинт хүчирхэг гүрэн (Самарканд, Бухар). 1218 онд Отрарт монголын цуваа алагдсан нь их аяны шалтгаан болов. Тэдний сүм, минарет дэлхийд алдартай."),
        CampaignLevel(title: "Инду мөрний тулаан", src: "1221 он",
                      desc: "Инду мөрөнд зоригт Жалал ад-Диныг эцэслэн дийл.",
                      minionMul: 1.50, heroMul: 1.45, enemyName: "Жалал ад-Дин", reward: 300,
                      objective: .slay(count: 1, label: "ЖАЛАЛ АД-ДИНЫГ эцэслэн дийл"),
                      intro: "Хорезмын хунтайж Жалал ад-Дин эцгээсээ ялгаатай нь зоригтой байв. Инду мөрний эрэг дээр сүүлчийн тулаан болов. Тэрээр мориороо голд үсрэн амиа авран зугтсан ч, өнөөдөр түүнийг эцэслэн дийл!",
                      events: [CampaignEvent(t: 12, kind: .enrage, text: "Жалал ад-Дин зоригтойгоор эргэн дайрав!")],
                      theme: .khwarezm,
                      fact: "Жалал ад-Дин Мангуберди бол Хорезмын сүүлчийн хунтайж. 1221 онд Инд мөрний тулаанд ялагдсан ч мориороо эгц эргээс мөрөнд үсэрч амиа авран зугтсан нь Чингис хааны биширлийг хүртсэн домогт үйл явдал.")
    ]
}
