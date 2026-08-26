import Foundation

/// One log or plan row. Totals are computed, never stored.
struct DayEntry: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var code: String
    var name: String
    var brand: String
    var grams: Double
    var kcal100: Double?
    var prot100: Double?
    var carb100: Double?
    var fat100: Double?
    var slot: SlotKind
    var day: DayKey
    var eaten: Bool
    var imgURL: String?
    var shelfImg: String?

    var kcal: Double? { PortionMath.part(kcal100, grams) }
    var prot: Double? { PortionMath.part(prot100, grams) }
    var carb: Double? { PortionMath.part(carb100, grams) }
    var fat: Double? { PortionMath.part(fat100, grams) }

    static func make(item: FoodItem, grams: Double, slot: SlotKind, day: DayKey, eaten: Bool) -> DayEntry {
        DayEntry(
            id: UUID(),
            code: item.code,
            name: item.name,
            brand: item.brand,
            grams: grams,
            kcal100: item.kcal100,
            prot100: item.prot100,
            carb100: item.carb100,
            fat100: item.fat100,
            slot: slot,
            day: day,
            eaten: eaten,
            imgURL: item.imgURL,
            shelfImg: item.shelfImg
        )
    }
}
