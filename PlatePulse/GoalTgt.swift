import Foundation

/// Daily energy and macro targets. Onboarding never writes zeros.
struct GoalTgt: Codable, Sendable, Equatable {
    var kcal: Double
    var prot: Double
    var carb: Double
    var fat: Double

    static let seed = GoalTgt(kcal: 2000, prot: 120, carb: 250, fat: 70)

    var valid: Bool {
        (800...6000).contains(kcal) &&
        (1...400).contains(prot) &&
        (1...600).contains(carb) &&
        (1...250).contains(fat)
    }
}
