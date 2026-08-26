import Foundation

struct LogRowVM: Sendable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var kcal: String
    var icon: String
    var imgURL: String?
    var shelfImg: String?
    var canDrop: Bool
}

struct LogVM: Sendable {
    var title: String
    var day: String
    var rows: [LogRowVM]
    var empty: Bool
    var emptyTitle: String
    var emptyBody: String
    var hi: Bool
}

@MainActor
protocol LogView: AnyObject {
    func render(_ vm: LogVM)
}

/// Formats the eaten list for one day.
@MainActor
final class LogPrsntr {
    weak var view: LogView?
    weak var coord: NavCoord?
    private let store: PulseMgr
    private var day = DayKey.today()
    private var notes: [NSObjectProtocol] = []

    init(store: PulseMgr) {
        self.store = store
        notes.append(NotificationCenter.default.addObserver(forName: PulseNotif.store, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        })
    }

    func reload() {
        Task { [weak self] in
            await self?.push()
        }
    }

    func prev() {
        day = day.shift(-1)
        reload()
    }

    func next() {
        day = day.shift(1)
        reload()
    }

    func tapEmpty() {
        coord?.openFlow(page: .srch)
    }

    func drop(_ id: UUID) {
        Task { [weak self] in
            await self?.store.dropEntry(id)
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            await self?.push()
        }
    }

    private func push() async {
        let rows = await store.dayRows(day, eaten: true).sorted { $0.slot.sort < $1.slot.sort }
        let hi = await store.prefs().hiContrast
        var vms: [LogRowVM] = []
        for slot in SlotKind.allCases {
            let mine = rows.filter { $0.slot == slot }
            guard !mine.isEmpty else { continue }
            let sub = DayAgg.sum(mine)
            vms.append(LogRowVM(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(slot.sort)") ?? UUID(),
                title: slot.title,
                body: "Slot total",
                kcal: PulseFmt.kcalUnit(sub.kcal),
                icon: slot.icon,
                imgURL: nil,
                shelfImg: slot.icon,
                canDrop: false
            ))
            for row in mine {
                vms.append(LogRowVM(
                    id: row.id,
                    title: row.name,
                    body: "\(PulseFmt.grams(row.grams)) g · \(row.brand)",
                    kcal: PulseFmt.kcalUnit(row.kcal),
                    icon: slot.icon,
                    imgURL: row.imgURL,
                    shelfImg: row.shelfImg,
                    canDrop: true
                ))
            }
        }
        view?.render(LogVM(
            title: "Eaten Log",
            day: PulseFmt.day(day),
            rows: vms,
            empty: rows.isEmpty,
            emptyTitle: "This day is quiet",
            emptyBody: "Take a reading to fill the log.",
            hi: hi
        ))
    }
}
