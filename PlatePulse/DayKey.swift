import Foundation

/// Day identity as DateComponents year / month / day.
struct DayKey: Hashable, Sendable, Codable, Equatable {
    var year: Int
    var month: Int
    var day: Int

    var dateComps: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(dateComps: DateComponents) {
        self.init(year: dateComps.year ?? 1970, month: dateComps.month ?? 1, day: dateComps.day ?? 1)
    }

    init(_ date: Date, cal: Calendar = .current) {
        let start = cal.startOfDay(for: date)
        let c = cal.dateComponents([.year, .month, .day], from: start)
        self.init(dateComps: DateComponents(year: c.year, month: c.month, day: c.day))
    }

    static func today(cal: Calendar = .current) -> DayKey {
        DayKey(Date(), cal: cal)
    }

    func date(cal: Calendar = .current) -> Date {
        cal.date(from: dateComps) ?? cal.startOfDay(for: Date())
    }

    func shift(_ n: Int, cal: Calendar = .current) -> DayKey {
        let next = cal.date(byAdding: .day, value: n, to: date(cal: cal)) ?? date(cal: cal)
        return DayKey(next, cal: cal)
    }

    var isToday: Bool { self == DayKey.today() }

    var isFuture: Bool {
        date() > Calendar.current.startOfDay(for: Date()) && !isToday
    }
}
