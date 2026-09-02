import UIKit

struct SlotVM: Sendable, Equatable {
    var id: String
    var title: String
    var body: String
    var icon: String
    var kcal: String
}

struct DayVM: Sendable {
    var title: String
    var energy: String
    var energySub: String
    var prot: String
    var carb: String
    var fat: String
    var kcalFrac: Double
    var protFrac: Double
    var carbFrac: Double
    var fatFrac: Double
    var slots: [SlotVM]
    var empty: Bool
    var exceeded: Bool
    var hi: Bool
    var a11yHint: String
    var emptyTitle: String
    var emptyBody: String
}

@MainActor
protocol DayView: AnyObject {
    func render(_ vm: DayVM)
}

/// Formats today's vitals and forwards actions to NavCoord.
@MainActor
final class DayPrsntr {
    weak var view: DayView?
    weak var coord: NavCoord?
    private let store: PulseMgr
    private var task: Task<Void, Never>?
    private var notes: [NSObjectProtocol] = []

    init(store: PulseMgr) {
        self.store = store
        notes.append(NotificationCenter.default.addObserver(forName: PulseNotif.store, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        })
        notes.append(NotificationCenter.default.addObserver(forName: PulseNotif.a11y, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        })
        notes.append(NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        })
    }

    func reload() {
        task?.cancel()
        task = Task { [weak self] in
            await self?.push()
        }
    }

    func tapSrch() { coord?.openFlow(page: .srch) }
    func tapScan() { coord?.openFlow(page: .scan) }
    func tapWish() { coord?.openWish() }
    func tapA11y() { coord?.openA11y() }
    func tapCite() { coord?.openCite() }

    private func push() async {
        let key = DayKey.today()
        let rows = await store.dayRows(key, eaten: true)
        let tgt = await store.tgt()
        let hi = await store.prefs().hiContrast
        let tot = DayAgg.sum(rows)
        let exceeded = tot.kcal > tgt.kcal
        let slots = SlotKind.allCases.map { slot -> SlotVM in
            let mine = rows.filter { $0.slot == slot }
            let names = mine.map(\.name).joined(separator: ", ")
            let sub = DayAgg.sum(mine)
            return SlotVM(
                id: slot.rawValue,
                title: slot.title,
                body: mine.isEmpty ? "No reading yet" : names,
                icon: slot.icon,
                kcal: mine.isEmpty ? "—" : PulseFmt.kcalUnit(sub.kcal)
            )
        }
        let vm = DayVM(
            title: "Today Pulse",
            energy: PulseFmt.kcal(tot.kcal),
            energySub: "of \(PulseFmt.kcalUnit(tgt.kcal))" + (exceeded ? " · over target" : ""),
            prot: "Protein \(PulseFmt.macroUnit(tot.prot, unit: "g")) / \(PulseFmt.macro(tgt.prot)) g",
            carb: "Carbs \(PulseFmt.macroUnit(tot.carb, unit: "g")) / \(PulseFmt.macro(tgt.carb)) g",
            fat: "Fat \(PulseFmt.macroUnit(tot.fat, unit: "g")) / \(PulseFmt.macro(tgt.fat)) g",
            kcalFrac: tgt.kcal == 0 ? 0 : tot.kcal / tgt.kcal,
            protFrac: tgt.prot == 0 ? 0 : (tot.prot ?? 0) / tgt.prot,
            carbFrac: tgt.carb == 0 ? 0 : (tot.carb ?? 0) / tgt.carb,
            fatFrac: tgt.fat == 0 ? 0 : (tot.fat ?? 0) / tgt.fat,
            slots: slots,
            empty: rows.isEmpty,
            exceeded: exceeded,
            hi: hi,
            a11yHint: hi ? "High contrast on" : "High contrast off",
            emptyTitle: "No readings yet",
            emptyBody: "Search or scan a pack to take the first reading."
        )
        view?.render(vm)
    }
}
