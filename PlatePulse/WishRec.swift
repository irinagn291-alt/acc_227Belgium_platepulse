import Foundation

/// Wish-list row. Unique by barcode.
struct WishRec: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var code: String
    var name: String
    var brand: String
    var kcal100: Double?
    var prot100: Double?
    var carb100: Double?
    var fat100: Double?
    var imgURL: String?
    var shelfImg: String?
    var added: Date

    func asFood() -> FoodItem {
        FoodItem(
            code: code,
            name: name,
            brand: brand,
            kcal100: kcal100,
            prot100: prot100,
            carb100: carb100,
            fat100: fat100,
            imgURL: imgURL,
            shelfImg: shelfImg,
            refreshed: added
        )
    }

    static func from(_ item: FoodItem) -> WishRec {
        WishRec(
            id: UUID(),
            code: item.code,
            name: item.name,
            brand: item.brand,
            kcal100: item.kcal100,
            prot100: item.prot100,
            carb100: item.carb100,
            fat100: item.fat100,
            imgURL: item.imgURL,
            shelfImg: item.shelfImg,
            added: Date()
        )
    }
}
