import Foundation

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
}
