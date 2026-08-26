import Foundation

struct OnbVM: Sendable {
    var page: Int
    var art: String
    var title: String
    var body: String
    var next: String
    var showTgt: Bool
    var kcal: String
    var prot: String
    var carb: String
    var fat: String
    var hi: Bool
}

@MainActor
protocol OnbView: AnyObject {
    func render(_ vm: OnbVM)
}

/// Four onboarding pages. Skip writes default targets.
@MainActor
final class OnbPrsntr {
    weak var view: OnbView?
    weak var coord: OnbCoord?
    private let store: PulseMgr
    private var page = 0
    private var draft = GoalTgt.seed

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        push()
    }

    func next() {
        if page < 3 {
            page += 1
            push()
            return
        }
        finish(draft)
    }

    func skip() {
        finish(.seed)
    }

    func edit(kcal: String?, prot: String?, carb: String?, fat: String?) {
        if let kcal, let v = PulseFmt.parseDec(kcal) { draft.kcal = v }
        if let prot, let v = PulseFmt.parseDec(prot) { draft.prot = v }
        if let carb, let v = PulseFmt.parseDec(carb) { draft.carb = v }
        if let fat, let v = PulseFmt.parseDec(fat) { draft.fat = v }
    }

    private func finish(_ t: GoalTgt) {
        let tgt = t.valid ? t : .seed
        Task { [weak self] in
            await self?.store.finishOnb(tgt)
            self?.coord?.finished()
        }
    }

    private func push() {
        let arts = ["plp_Onboarding1", "plp_Onboarding2", "plp_Onboarding3", "plp_Onboarding3"]
        let titles = [
            "Read every pack",
            "Search or scan",
            "Set daily vitals",
            "Your first targets"
        ]
        let bodies = [
            "PlatePulse is a personal food log with monitor-clear readings. It is not medical advice.",
            "Find a product by name or lock a barcode. Every control is built for VoiceOver and large type.",
            "Energy, protein, carbs and fat sit against targets you can change any time.",
            "Keep these starting readings or write your own. Skip still saves a sensible set."
        ]
        view?.render(OnbVM(
            page: page,
            art: arts[page],
            title: titles[page],
            body: bodies[page],
            next: page == 3 ? "Start logging" : "Next",
            showTgt: page == 3,
            kcal: PulseFmt.kcal(draft.kcal),
            prot: PulseFmt.macro(draft.prot),
            carb: PulseFmt.macro(draft.carb),
            fat: PulseFmt.macro(draft.fat),
            hi: false
        ))
    }
}
