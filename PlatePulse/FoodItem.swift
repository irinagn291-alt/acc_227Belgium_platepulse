import Foundation

/// Cached / shelf product. Macros per 100 g stay optional.
struct FoodItem: Codable, Sendable, Equatable, Identifiable {
    var code: String
    var name: String
    var brand: String
    var kcal100: Double?
    var prot100: Double?
    var carb100: Double?
    var fat100: Double?
    var imgURL: String?
    var shelfImg: String?
    var refreshed: Date

    var id: String { code }

    var usable: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func matches(_ q: String) -> Bool {
        let n = q.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !n.isEmpty else { return false }
        return name.lowercased().contains(n) || brand.lowercased().contains(n) || code.contains(n)
    }
}

enum SearchMix {
    static func merge(remote: [FoodItem], shelf: [FoodItem], query: String) -> [FoodItem] {
        let local = shelf.filter { $0.matches(query) }
        var seen = Set<String>()
        var out: [FoodItem] = []
        for item in remote + local where item.usable {
            if seen.insert(item.code).inserted {
                out.append(item)
            }
        }
        return out
    }
}
