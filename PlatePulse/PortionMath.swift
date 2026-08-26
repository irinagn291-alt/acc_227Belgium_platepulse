import Foundation

/// Portion maths. Stored values stay full precision.
enum PortionMath {
    static func kcal100(kcal: Double?, kj: Double?) -> Double? {
        if let kcal { return kcal }
        if let kj { return kj / 4.184 }
        return nil
    }

    static func part(_ per100: Double?, _ grams: Double) -> Double? {
        guard let per100 else { return nil }
        return per100 * grams / 100
    }
}

/// Day totals. Unknown macros stay unknown when nothing known exists.
enum DayAgg {
    static func sum(_ rows: [DayEntry]) -> MacroVM {
        var kcal = 0.0
        var prot: Double?
        var carb: Double?
        var fat: Double?
        for row in rows {
            if let k = row.kcal { kcal += k }
            if let p = row.prot { prot = (prot ?? 0) + p }
            if let c = row.carb { carb = (carb ?? 0) + c }
            if let f = row.fat { fat = (fat ?? 0) + f }
        }
        return MacroVM(kcal: rows.isEmpty ? 0 : kcal, prot: prot, carb: carb, fat: fat)
    }
}
