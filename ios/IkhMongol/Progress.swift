import Foundation
import CoreGraphics

/// Байнгын хадгалалт — алт, баатрын нээлт, мастери (UserDefaults)
enum Progress {

    private static let goldKey = "im_gold"
    private static let unlockedKey = "im_unlocked"
    private static let masteryKey = "im_mastery"
    private static let freeHeroes = ["temuujin", "zev"]

    static var gold: Int {
        get { UserDefaults.standard.integer(forKey: goldKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: goldKey) }
    }

    static func isUnlocked(_ id: String) -> Bool {
        if freeHeroes.contains(id) { return true }
        return (UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []).contains(id)
    }

    /// Хангалттай алттай бол нээгээд true буцаана
    @discardableResult
    static func unlock(_ id: String, cost: Int) -> Bool {
        guard !isUnlocked(id), gold >= cost else { return false }
        gold -= cost
        var arr = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []
        arr.append(id)
        UserDefaults.standard.set(arr, forKey: unlockedKey)
        return true
    }

    /// Мастерийн одны тоо (0–5); од бүр +3% амь ба хүч
    static func mastery(_ id: String) -> Int {
        let dict = UserDefaults.standard.dictionary(forKey: masteryKey) as? [String: Int] ?? [:]
        return dict[id] ?? 0
    }

    static func addMasteryStar(_ id: String) {
        var dict = UserDefaults.standard.dictionary(forKey: masteryKey) as? [String: Int] ?? [:]
        dict[id] = min(5, (dict[id] ?? 0) + 1)
        UserDefaults.standard.set(dict, forKey: masteryKey)
    }

    // MARK: - Тулааны статистик (түүхийн бүлэг нээхэд ашиглана)

    private static let matchesKey = "im_matches"
    private static let winsKey = "im_wins"
    private static let readChaptersKey = "im_read_chapters"

    static var matches: Int { UserDefaults.standard.integer(forKey: matchesKey) }
    static var wins: Int { UserDefaults.standard.integer(forKey: winsKey) }

    static func recordMatch(win: Bool) {
        UserDefaults.standard.set(matches + 1, forKey: matchesKey)
        if win { UserDefaults.standard.set(wins + 1, forKey: winsKey) }
    }

    /// Худалдаж авсан (үнэтэй) баатрын тоо
    static var paidUnlockCount: Int {
        (UserDefaults.standard.stringArray(forKey: unlockedKey) ?? [])
            .filter { !freeHeroes.contains($0) }.count
    }

    static var readChapters: [String] {
        UserDefaults.standard.stringArray(forKey: readChaptersKey) ?? []
    }

    static func markChapterRead(_ id: String) {
        var arr = readChapters
        guard !arr.contains(id) else { return }
        arr.append(id)
        UserDefaults.standard.set(arr, forKey: readChaptersKey)
    }

    // MARK: - Буурийн эдийн засаг (V2) — адуу, төмөр ба шинэчлэлүүд

    private static let horsesKey = "im_horses"
    private static let ironKey = "im_iron"
    private static let horseLvlKey = "im_horse_lvl"
    private static let ironLvlKey = "im_iron_lvl"
    static let campMaxLevel = 8

    static var horses: Int {
        get { UserDefaults.standard.integer(forKey: horsesKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: horsesKey) }
    }
    static var iron: Int {
        get { UserDefaults.standard.integer(forKey: ironKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: ironKey) }
    }
    static var horseLevel: Int {
        get { UserDefaults.standard.integer(forKey: horseLvlKey) }
        set { UserDefaults.standard.set(min(campMaxLevel, max(0, newValue)), forKey: horseLvlKey) }
    }
    static var ironLevel: Int {
        get { UserDefaults.standard.integer(forKey: ironLvlKey) }
        set { UserDefaults.standard.set(min(campMaxLevel, max(0, newValue)), forKey: ironLvlKey) }
    }

    /// Отряд ба тоглогчийн хурдны үржүүлэгч (адууны сүрэг: +4%/түвшин)
    static var horseSpeedMul: CGFloat { 1 + CGFloat(horseLevel) * 0.04 }
    /// Отряд ба тоглогчийн хүчний үржүүлэгч (дархны зэвсэг: +5%/түвшин)
    static var ironDamageMul: CGFloat { 1 + CGFloat(ironLevel) * 0.05 }

    // MARK: - Аян дайны ахиц (дуусгасан түвшний тоо)

    private static let campaignKey = "im_campaign"

    /// Дуусгасан аяны түвшний тоо (= дараагийн нээлттэй түвшний индекс)
    static var campaign: Int { UserDefaults.standard.integer(forKey: campaignKey) }

    /// Тухайн түвшин анх удаа дуусвал ахиулаад true буцаана
    @discardableResult
    static func clearCampaignLevel(_ index: Int) -> Bool {
        guard index == campaign else { return false }   // зөвхөн дараалсан түвшин
        UserDefaults.standard.set(index + 1, forKey: campaignKey)
        return true
    }

    // MARK: - Хар Хорум төв хот (MMO-lite lobby)

    private static let hubLevelKey = "im_hub_level"
    private static let hubXpKey = "im_hub_xp"
    private static let questsDoneKey = "im_quests_done"
    private static let itemsKey = "im_items"
    private static let partyKey = "im_party"

    /// Хотын зэрэг (доод тал нь 1)
    static var hubLevel: Int {
        get { max(1, UserDefaults.standard.integer(forKey: hubLevelKey)) }
        set { UserDefaults.standard.set(max(1, newValue), forKey: hubLevelKey) }
    }
    static var hubXp: Int {
        get { UserDefaults.standard.integer(forKey: hubXpKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: hubXpKey) }
    }
    static var questsDone: [String] { UserDefaults.standard.stringArray(forKey: questsDoneKey) ?? [] }
    static func questDone(_ id: String) -> Bool { questsDone.contains(id) }
    static var items: [String] { UserDefaults.standard.stringArray(forKey: itemsKey) ?? [] }
    static func ownsItem(_ id: String) -> Bool { items.contains(id) }
    static var party: [String] { UserDefaults.standard.stringArray(forKey: partyKey) ?? [] }
    static var partySize: Int { 1 + party.count }
    static func isRecruited(_ id: String) -> Bool { party.contains(id) }

    /// Багийн гишүүн элсүүлнэ (хангалттай алттай бол). Амжилттай бол true.
    @discardableResult
    static func recruit(_ id: String, cost: Int) -> Bool {
        guard !isRecruited(id), gold >= cost else { return false }
        gold -= cost
        var arr = party; arr.append(id)
        UserDefaults.standard.set(arr, forKey: partyKey)
        return true
    }

    /// Зэвсэг/хуяг худалдаж авна. Амжилттай бол true.
    @discardableResult
    static func buyItem(_ id: String, cost: Int) -> Bool {
        guard !ownsItem(id), gold >= cost else { return false }
        gold -= cost
        var arr = items; arr.append(id)
        UserDefaults.standard.set(arr, forKey: itemsKey)
        return true
    }

    /// Эд өлгийн нийт бонусын үржүүлэгчид (тулаанд player-т нэмэгдэнэ)
    static var itemDamageMul: CGFloat { 1 + items.compactMap { HubData.shopItem($0)?.dmg }.reduce(0, +) }
    static var itemHpMul: CGFloat { 1 + items.compactMap { HubData.shopItem($0)?.hp }.reduce(0, +) }
    static var itemSpeedMul: CGFloat { 1 + items.compactMap { HubData.shopItem($0)?.spd }.reduce(0, +) }

    /// Даалгавар гүйцэтгэвэл туршлага/зэвсэг олгож зэрэг ахиулна (алтыг тусад нь өгнө).
    /// Дэлгэцэд харуулах шагналын мөрийг буцаана.
    static func completeHubQuest(_ q: HubQuest) -> String {
        let already = questDone(q.id)
        var xp = hubXp + q.xp
        var lv = hubLevel
        var leveled = false
        while xp >= HubData.xpForLevel(lv) { xp -= HubData.xpForLevel(lv); lv += 1; leveled = true }
        hubXp = xp
        hubLevel = lv
        if !already {
            var arr = questsDone; arr.append(q.id)
            UserDefaults.standard.set(arr, forKey: questsDoneKey)
        }
        var itemLine = ""
        if !q.item.isEmpty, !ownsItem(q.item) {
            var arr = items; arr.append(q.item)
            UserDefaults.standard.set(arr, forKey: itemsKey)
            if let it = HubData.shopItem(q.item) { itemLine = "\n🎁 Шагнал: \(it.icon) \(it.name) (\(it.desc))" }
        }
        return "⭐ +\(q.xp) туршлага" + (leveled ? " · ЗЭРЭГ АХЛАА → \(lv)!" : "") + itemLine
    }
}
