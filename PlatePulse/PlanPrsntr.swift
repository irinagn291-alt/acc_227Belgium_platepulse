import Foundation

struct PlanRowVM: Sendable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var kcal: String
    var icon: String
    var imgURL: String?
    var shelfImg: String?
}

struct PlanVM: Sendable {
    var title: String
    var hint: String
    var rows: [PlanRowVM]
    var empty: Bool
    var emptyTitle: String
    var emptyBody: String
    var hi: Bool
}

@MainActor
protocol PlanView: AnyObject {
    func render(_ vm: PlanVM)
}

/// Formats the 14-day planned horizon.
@MainActor
final class PlanPrsntr {
    weak var view: PlanView?
    weak var coord: NavCoord?
    private let store: PulseMgr
    private var notes: [NSObjectProtocol] = []

    init(store: PulseMgr) {
        self.store = store
        notes.append(NotificationCenter.default.addObserver(forName: PulseNotif.store, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        })
    }

    func reload() {
        Task { [weak self] in await self?.push() }
    }

    func tapEmpty() {
        coord?.openFlow(page: .srch)
    }

    func eat(_ id: UUID) {
        Task { [weak self] in
            await self?.store.eatPlanned(id)
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            PulseHapt.commit()
            self?.coord?.jump(0)
            await self?.push()
        }
    }

    func drop(_ id: UUID) {
        Task { [weak self] in
            await self?.store.dropEntry(id)
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            await self?.push()
        }
    }

    private func push() async {
        let rows = await store.planRows(horizon: 14).sorted {
            if $0.day != $1.day { return $0.day.date() < $1.day.date() }
            return $0.slot.sort < $1.slot.sort
        }
        let hi = await store.prefs().hiContrast
        let vms = rows.map { row in
            PlanRowVM(
                id: row.id,
                title: row.name,
                body: "\(PulseFmt.day(row.day)) · \(row.slot.title) · \(PulseFmt.grams(row.grams)) g",
                kcal: PulseFmt.kcalUnit(row.kcal),
                icon: row.slot.icon,
                imgURL: row.imgURL,
                shelfImg: row.shelfImg
            )
        }
        view?.render(PlanVM(
            title: "Ahead Plan",
            hint: "Next 14 days. Interval remaps to Dusk Reading.",
            rows: vms,
            empty: rows.isEmpty,
            emptyTitle: "Horizon is clear",
            emptyBody: "Assign a future reading from Search or Scan.",
            hi: hi
        ))
    }
}
