import Foundation

/// Computed macros. Never persisted.
struct MacroVM: Sendable, Equatable {
    var kcal: Double
    var prot: Double?
    var carb: Double?
    var fat: Double?
}

/// Persisted high-contrast preference for the accessibility twist.
struct A11yPrefs: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var hiContrast: Bool

    static let seed = A11yPrefs(schemaVersion: 1, hiContrast: false)
}
