import Foundation

struct GoalVM: Sendable {
    var title: String
    var cite: String
    var kcal: String
    var prot: String
    var carb: String
    var fat: String
    var err: String
    var canSave: Bool
    var hi: Bool
}

@MainActor
protocol GoalView: AnyObject {
    func render(_ vm: GoalVM)
}

/// Edits daily targets and hosts support actions.
@MainActor
final class GoalPrsntr {
    weak var view: GoalView?
    weak var coord: NavCoord?
    private let store: PulseMgr
    private var draft = GoalTgt.seed
    private var err = ""

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            self.draft = await store.tgt()
            self.err = ""
            await self.push()
        }
    }

    func edit(kcal: String?, prot: String?, carb: String?, fat: String?) {
        if let kcal, let v = PulseFmt.parseDec(kcal) { draft.kcal = v }
        if let prot, let v = PulseFmt.parseDec(prot) { draft.prot = v }
        if let carb, let v = PulseFmt.parseDec(carb) { draft.carb = v }
        if let fat, let v = PulseFmt.parseDec(fat) { draft.fat = v }
        err = draft.valid ? "" : "Each target needs a positive reading in range."
        Task { await push() }
    }

    func save() {
        guard draft.valid else {
            err = "Each target needs a positive reading in range."
            Task { await push() }
            return
        }
        Task { [weak self] in
            guard let self else { return }
            await store.setTgt(draft)
            await store.flush()
            PulseHapt.commit()
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            await push()
        }
    }

    func tapCite() {
        coord?.openCite()
    }

    func rerunOnb() {
        coord?.rerunOnb()
    }

    func resetAll() {
        Task { [weak self] in
            await self?.store.resetAllData()
            await self?.store.flush()
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            self?.reload()
        }
    }

    private func push() async {
        let hi = await store.prefs().hiContrast
        view?.render(GoalVM(
            title: "Daily Goals",
            cite: "Starting 2,000 kcal and macro grams follow USDA Dietary Guidelines, FDA Daily Values and National Academies DRIs. Pack figures come from Open Food Facts. Not medical advice.",
            kcal: PulseFmt.kcal(draft.kcal),
            prot: PulseFmt.macro(draft.prot),
            carb: PulseFmt.macro(draft.carb),
            fat: PulseFmt.macro(draft.fat),
            err: err,
            canSave: draft.valid,
            hi: hi
        ))
    }
}
