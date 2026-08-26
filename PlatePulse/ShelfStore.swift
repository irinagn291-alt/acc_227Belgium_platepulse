import Foundation

/// Bundled local shelf. Usable with no network.
enum ShelfStore {
    static let all: [FoodItem] = [
        FoodItem(code: "0074354611200", name: "Hummus Pack", brand: "Pulse Shelf", kcal100: 166, prot100: 7.9, carb100: 14.3, fat100: 9.6, imgURL: nil, shelfImg: "plp_ProductPlaceholder", refreshed: Date(timeIntervalSince1970: 0)),
        FoodItem(code: "0041303001943", name: "Kidney Bean Tin", brand: "Pulse Shelf", kcal100: 127, prot100: 8.7, carb100: 22.8, fat100: 0.5, imgURL: nil, shelfImg: "plp_ProductPlaceholder", refreshed: Date(timeIntervalSince1970: 0)),
        FoodItem(code: "8410054000129", name: "Chickpea Tin", brand: "Pulse Shelf", kcal100: 119, prot100: 7.1, carb100: 16.2, fat100: 2.6, imgURL: nil, shelfImg: "plp_ProductPlaceholder", refreshed: Date(timeIntervalSince1970: 0)),
        FoodItem(code: "8076809545013", name: "Dry Lentil Pack", brand: "Pulse Shelf", kcal100: 353, prot100: 25.8, carb100: 60.1, fat100: 1.1, imgURL: nil, shelfImg: "plp_ProductPlaceholder", refreshed: Date(timeIntervalSince1970: 0)),
        FoodItem(code: "5000168001012", name: "Wheat Loaf", brand: "Pulse Shelf", kcal100: 247, prot100: 9.4, carb100: 41.3, fat100: 3.5, imgURL: nil, shelfImg: "plp_ProductPlaceholder", refreshed: Date(timeIntervalSince1970: 0)),
        FoodItem(code: "0037000388401", name: "Green Tea Brew", brand: "Pulse Shelf", kcal100: 1, prot100: 0.0, carb100: 0.2, fat100: 0.0, imgURL: nil, shelfImg: "plp_ProductPlaceholder", refreshed: Date(timeIntervalSince1970: 0))
    ]

    static func byCode(_ code: String) -> FoodItem? {
        all.first { $0.code == code }
    }
}
