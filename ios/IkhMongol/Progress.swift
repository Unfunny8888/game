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
}
