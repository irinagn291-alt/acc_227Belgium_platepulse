import Foundation

struct AsgnVM: Sendable {
    var empty: Bool
    var emptyTitle: String
    var slot: SlotKind
    var eaten: Bool
    var day: DayKey
    var confirm: String
    var intervalOff: Bool
    var note: String
    var busy: Bool
    var hi: Bool
}

@MainActor
protocol AsgnView: AnyObject {
    func render(_ vm: AsgnVM)
}

/// Slot and day assignment. Interval remaps to Dusk when planned.
@MainActor
final class AsgnPrsntr {
    weak var view: AsgnView?
    weak var coord: FlowCoord?
    private let store: PulseMgr
    private var slot: SlotKind = .dawn
    private var eaten = true
    private var day = DayKey.today()
    private var busy = false

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        Task { await push() }
    }

    func pick(_ s: SlotKind) {
        slot = s
        Task { await push() }
    }

    func setEaten(_ v: Bool) {
        eaten = v
        if v {
            day = DayKey.today()
        } else if !day.isFuture {
            day = DayKey.today().shift(1)
        }
        Task { await push() }
    }

    func setDay(_ date: Date) {
        day = DayKey(date)
        if day.isToday || day.date() <= Calendar.current.startOfDay(for: Date()) {
            eaten = true
            day = DayKey.today()
        } else {
            eaten = false
        }
        Task { await push() }
    }

    func confirm() {
        guard let item = coord?.item, !busy else { return }
        let grams = coord?.grams ?? 100
        guard grams > 0, grams <= 10_000 else { return }
        busy = true
        let future = !eaten
        let resolved = SlotRule.resolve(slot: slot, future: future)
        slot = resolved
        Task { [weak self] in
            guard let self else { return }
            let row = DayEntry.make(item: item, grams: grams, slot: resolved, day: day, eaten: eaten)
            await store.addEntry(row)
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            busy = false
            coord?.assigned(eaten: eaten)
        }
    }

    private func push() async {
        let hi = await store.prefs().hiContrast
        guard coord?.item != nil else {
            view?.render(AsgnVM(
                empty: true,
                emptyTitle: "Resolve a pack first, then assign a slot.",
                slot: slot,
                eaten: eaten,
                day: day,
                confirm: "Confirm",
                intervalOff: !eaten,
                note: "",
                busy: false,
                hi: hi
            ))
            return
        }
        let future = !eaten
        let resolved = SlotRule.resolve(slot: slot, future: future)
        var note = ""
        if future && slot == .interval {
            note = "Interval cannot be planned. This reading will land on Dusk Reading."
        }
        view?.render(AsgnVM(
            empty: false,
            emptyTitle: "",
            slot: resolved,
            eaten: eaten,
            day: day,
            confirm: eaten ? "Log as eaten today" : "Park on the plan",
            intervalOff: future,
            note: note,
            busy: busy,
            hi: hi
        ))
    }
}
