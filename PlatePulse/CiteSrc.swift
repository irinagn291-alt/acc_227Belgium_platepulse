import Foundation

/// Official citations for pack nutrition and starting daily targets.
enum CiteSrc: String, CaseIterable, Sendable {
    case off
    case dga
    case fda
    case dri

    var title: String {
        switch self {
        case .off: "Open Food Facts"
        case .dga: "Dietary Guidelines for Americans"
        case .fda: "FDA Daily Values"
        case .dri: "Dietary Reference Intakes"
        }
    }

    var body: String {
        switch self {
        case .off:
            "Pack energy and macros come from this public food database, shown per 100 g. Incomplete values stay unknown. If a pack lists only kilojoules, PlatePulse divides by 4.184 to show kilocalories."
        case .dga:
            "The 2,000 kcal starting energy target follows the USDA / HHS 2,000-calorie reference eating pattern in the Dietary Guidelines for Americans, 2020–2025. You can change every target."
        case .fda:
            "U.S. Nutrition Facts labels use 2,000 calories as the Daily Value reference amount. That is the same energy baseline used for the first daily reading in PlatePulse."
        case .dri:
            "Starting protein, carbohydrate and fat grams sit inside the National Academies Acceptable Macronutrient Distribution Ranges: protein 10–35% of energy, carbohydrate 45–65%, fat 20–35%. They are a log starting set, not a prescription."
        }
    }

    var href: String {
        switch self {
        case .off:
            "https://world.openfoodfacts.org"
        case .dga:
            "https://www.dietaryguidelines.gov/"
        case .fda:
            "https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels"
        case .dri:
            "https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx"
        }
    }

    static func href(id: String) -> String? {
        Self(rawValue: id)?.href
    }
}
