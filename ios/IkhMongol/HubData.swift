import SpriteKit

// ======================================================================
//  ХАР ХОРУМ — төв хотын өгөгдөл (MMO-lite lobby). Веб хувилбартай нийцнэ.
//  Тоглогч эндээс төрж, түүхэн даалгавар авч, зэрэг ахьж, зэвсэг олж, багаа
//  бүрдүүлээд дараагийн эзлэлт рүү мордоно.
// ======================================================================

struct HubQuest {
    let id: String
    let level: Int      // GameData.campaign индекс (тулааны тохиргоо)
    let lvlReq: Int     // шаардагдах хотын зэрэг
    let partyReq: Int   // шаардагдах багийн хэмжээ
    let xp: Int
    let gold: Int
    let item: String    // шагналын зэвсэг (HubData.shop id)
    let title: String
    let giver: String
    let brief: String
}

struct HubRecruit {
    let id: String
    let name: String
    let role: String
    let icon: String
    let color: SKColor
    let cost: Int
    let ranged: Bool
    let hp: CGFloat
    let dmg: CGFloat
}

struct HubShopItem {
    let id: String
    let name: String
    let icon: String
    let cost: Int
    let desc: String
    let dmg: CGFloat    // довтолгооны хувь (0.08 = +8%)
    let hp: CGFloat
    let spd: CGFloat
}

enum HubData {

    static func xpForLevel(_ lv: Int) -> Int { 80 + (lv - 1) * 90 }

    static let recruits: [HubRecruit] = [
        HubRecruit(id: "jelme",   name: "Зэлмэ",    role: "Догшин нохой",  icon: "🗡️",
                   color: SKColor(red: 0.48, green: 0.76, blue: 0.69, alpha: 1), cost: 60,  ranged: false, hp: 820,  dmg: 48),
        HubRecruit(id: "boorchu", name: "Боорчи",   role: "Дөрвөн хүлэг",  icon: "🐎",
                   color: SKColor(red: 0.79, green: 0.54, blue: 0.29, alpha: 1), cost: 90,  ranged: false, hp: 900,  dmg: 52),
        HubRecruit(id: "jebe",    name: "Зэв",      role: "Мэргэн харваач", icon: "🏹",
                   color: SKColor(red: 0.56, green: 0.71, blue: 0.45, alpha: 1), cost: 120, ranged: true,  hp: 760,  dmg: 56),
        HubRecruit(id: "subutai", name: "Сүбээдэй", role: "Их жанжин",     icon: "🛡️",
                   color: SKColor(red: 0.62, green: 0.71, blue: 0.79, alpha: 1), cost: 180, ranged: false, hp: 1150, dmg: 58),
        HubRecruit(id: "khubilai", name: "Хубилай", role: "Догшин нохой",  icon: "⚔️",
                   color: SKColor(red: 0.85, green: 0.64, blue: 0.35, alpha: 1), cost: 150, ranged: false, hp: 980,  dmg: 60)
    ]
    static func recruit(_ id: String) -> HubRecruit? { recruits.first { $0.id == id } }

    static let shop: [HubShopItem] = [
        HubShopItem(id: "steel_sword", name: "Ган сэлэм",       icon: "⚔️", cost: 80,  desc: "Довтолгооны хүч +8%",  dmg: 0.08, hp: 0,    spd: 0),
        HubShopItem(id: "iron_armor",  name: "Төмөр хуяг",      icon: "🛡️", cost: 120, desc: "Амин хүч +12%",       dmg: 0,    hp: 0.12, spd: 0),
        HubShopItem(id: "war_horse",   name: "Байлдааны хүлэг", icon: "🐎", cost: 100, desc: "Хурд +10%",           dmg: 0,    hp: 0,    spd: 0.10),
        HubShopItem(id: "horn_bow",    name: "Эвэр нум",        icon: "🏹", cost: 140, desc: "Довтолгооны хүч +10%", dmg: 0.10, hp: 0,    spd: 0),
        HubShopItem(id: "silk_robe",   name: "Торгон дээл",     icon: "🧥", cost: 160, desc: "Амин хүч +15%",       dmg: 0,    hp: 0.15, spd: 0)
    ]
    static func shopItem(_ id: String) -> HubShopItem? { shop.first { $0.id == id } }

    static let quests: [HubQuest] = [
        HubQuest(id: "q1", level: 0, lvlReq: 1, partyReq: 1, xp: 90,  gold: 80,  item: "steel_sword",
                 title: "Боолчлолоос зугтах", giver: "Хатагтай Өэлүн",
                 brief: "Тайчиудын хавчлагаас ганцаараа зугт. Энэ бол чиний анхны сорилт."),
        HubQuest(id: "q2", level: 1, lvlReq: 2, partyReq: 1, xp: 90,  gold: 100, item: "war_horse",
                 title: "Найман шарга морь", giver: "Малчин өвгөн",
                 brief: "Хулгайлагдсан найман хүлэгээ ганцаараа мөрдөж буцаа."),
        HubQuest(id: "q3", level: 2, lvlReq: 2, partyReq: 2, xp: 130, gold: 140, item: "iron_armor",
                 title: "Бөртэг аврах", giver: "Тэмүжин",
                 brief: "Мэргэдээс хатан Бөртэг аврахад нэг найз хэрэгтэй."),
        HubQuest(id: "q4", level: 3, lvlReq: 3, partyReq: 2, xp: 170, gold: 180, item: "horn_bow",
                 title: "Анд ба дайсан", giver: "Хасар",
                 brief: "Далан балжудад анд Жамухатай хоёулаа нүүр тул."),
        HubQuest(id: "q5", level: 4, lvlReq: 4, partyReq: 3, xp: 220, gold: 230, item: "silk_robe",
                 title: "Хэрэйдийн уналт", giver: "Мухулай",
                 brief: "Ван ханы их цэргийг буулгахад гурван дайчны хүч хэрэгтэй."),
        HubQuest(id: "q6", level: 5, lvlReq: 5, partyReq: 3, xp: 270, gold: 280, item: "steel_sword",
                 title: "Найманы төгсгөл", giver: "Сүбээдэй",
                 brief: "Таян ханы хаалгыг нурааж талыг нэгтгэ."),
        HubQuest(id: "q7", level: 6, lvlReq: 6, partyReq: 4, xp: 330, gold: 340, item: "iron_armor",
                 title: "Хорезмын аян", giver: "Чингис хаан",
                 brief: "Их баруун аян. Дөрвөн хүлэг жанжин цугларч байж л Хорезмыг эзэлнэ."),
        HubQuest(id: "q8", level: 7, lvlReq: 7, partyReq: 4, xp: 400, gold: 420, item: "horn_bow",
                 title: "Инду мөрний тулаан", giver: "Чингис хаан",
                 brief: "Зоригт Жалал ад-Диныг эцэслэ. Бүрэн бүрэлдэхүүнтэй отряд хэрэгтэй.")
    ]

    /// Даалгавар эхлүүлэх боломжтой эсэх ба шалтгаан
    static func status(_ q: HubQuest) -> (ok: Bool, done: Bool, reason: String) {
        if Progress.questDone(q.id) { return (false, true, "Дуусгасан ✓") }
        if Progress.hubLevel < q.lvlReq {
            return (false, false, "🔒 \(q.lvlReq)-р зэрэг шаардана (одоо \(Progress.hubLevel))")
        }
        if Progress.partySize < q.partyReq {
            return (false, false, "👥 \(q.partyReq) гишүүн хэрэгтэй (одоо \(Progress.partySize))")
        }
        return (true, false, "Мордоход бэлэн ⚔️")
    }
}

/// Идэвхтэй Хар Хорумын даалгавар (тулаанаас буцахад шагнал өгөхөд).
enum HubContext {
    static var activeQuest: HubQuest? = nil
}
