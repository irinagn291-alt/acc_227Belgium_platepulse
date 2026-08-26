import Foundation

/// Locale-aware number and day formatting. Round only at display.
enum PulseFmt {
    private static let kcalF: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    private static let macroF: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f
    }()

    private static let dayF: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func kcal(_ v: Double?) -> String {
        guard let v else { return "—" }
        return kcalF.string(from: NSNumber(value: v.rounded())) ?? "—"
    }

    static func kcalUnit(_ v: Double?) -> String {
        guard let v else { return "unknown kcal" }
        let n = kcalF.string(from: NSNumber(value: v.rounded())) ?? "—"
        return "\(n) kcal"
    }

    static func macro(_ v: Double?) -> String {
        guard let v else { return "—" }
        return macroF.string(from: NSNumber(value: v)) ?? "—"
    }

    static func macroUnit(_ v: Double?, unit: String) -> String {
        guard let v else { return "unknown" }
        let n = macroF.string(from: NSNumber(value: v)) ?? "—"
        return "\(n) \(unit)"
    }

    static func grams(_ v: Double) -> String {
        macroF.string(from: NSNumber(value: v)) ?? "0"
    }

    static func day(_ key: DayKey, cal: Calendar = .current) -> String {
        dayF.string(from: key.date(cal: cal))
    }

    static func parseDec(_ raw: String) -> Double? {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("-") { return nil }
        return f.number(from: trimmed)?.doubleValue
    }
}
