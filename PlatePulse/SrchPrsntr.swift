import Foundation

struct SrchRowVM: Sendable, Equatable {
    var code: String
    var title: String
    var brand: String
    var kcal: String
    var imgURL: String?
    var shelfImg: String?
}

enum SrchState: Sendable {
    case idle
    case load
    case rows
    case empty
    case err
}

struct SrchVM: Sendable {
    var state: SrchState
    var rows: [SrchRowVM]
    var note: String
    var hi: Bool
}

@MainActor
protocol SrchView: AnyObject {
    func render(_ vm: SrchVM)
}

/// Debounced search. Cancels the in-flight request.
@MainActor
final class SrchPrsntr {
    weak var view: SrchView?
    weak var coord: FlowCoord?
    private let store: PulseMgr
    private let food: FoodSvc
    private var query = ""
    private var debounce: Task<Void, Never>?
    private var fetch: Task<Void, Never>?
    private var vm = SrchVM(state: .idle, rows: [], note: "Type a name to search the shelf and Open Food Facts.", hi: false)

    init(store: PulseMgr, food: FoodSvc) {
        self.store = store
        self.food = food
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            self.vm.hi = await store.prefs().hiContrast
            self.view?.render(self.vm)
        }
    }

    func type(_ text: String) {
        query = text
        debounce?.cancel()
        fetch?.cancel()
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            vm.state = .idle
            vm.rows = []
            vm.note = "Type a name to search the shelf and Open Food Facts."
            view?.render(vm)
            return
        }
        debounce = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await self?.run(q)
        }
    }

    func pick(_ code: String) {
        guard let row = vm.rows.first(where: { $0.code == code }) else { return }
        let item = FoodItem(
            code: row.code,
            name: row.title,
            brand: row.brand,
            kcal100: nil,
            prot100: nil,
            carb100: nil,
            fat100: nil,
            imgURL: row.imgURL,
            shelfImg: row.shelfImg,
            refreshed: Date()
        )
        Task { [weak self] in
            guard let self else { return }
            if let cached = await store.cached(code) {
                coord?.picked(cached)
                return
            }
            if let shelf = ShelfStore.byCode(code) {
                coord?.picked(shelf)
                return
            }
            do {
                let full = try await food.product(code)
                await store.putFood(full)
                coord?.picked(full)
            } catch {
                coord?.picked(item)
            }
        }
    }

    private func run(_ q: String) async {
        fetch?.cancel()
        fetch = Task { [weak self] in
            await self?.load(q)
        }
        let show = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self?.vm.state = .load
            self?.view?.render(self?.vm ?? SrchVM(state: .load, rows: [], note: "", hi: false))
        }
        await fetch?.value
        show.cancel()
    }

    private func load(_ q: String) async {
        var remote: [FoodItem] = []
        var failed = false
        do {
            remote = try await food.search(q)
        } catch {
            failed = true
        }
        if Task.isCancelled { return }
        let merged = SearchMix.merge(remote: remote, shelf: ShelfStore.all, query: q)
        if merged.isEmpty {
            vm.state = failed ? .err : .empty
            vm.rows = []
            vm.note = failed
                ? "The network pulse dropped. Retry or pick a shelf chip on Scan."
                : "No pack matched. Try another name or scan a barcode."
        } else {
            vm.state = .rows
            vm.rows = merged.map {
                SrchRowVM(
                    code: $0.code,
                    title: $0.name,
                    brand: $0.brand.isEmpty ? "Unknown brand" : $0.brand,
                    kcal: $0.kcal100 == nil ? "unknown kcal / 100 g" : "\(PulseFmt.kcalUnit($0.kcal100)) / 100 g",
                    imgURL: $0.imgURL,
                    shelfImg: $0.shelfImg
                )
            }
            vm.note = failed ? "Showing shelf matches while the network is quiet." : ""
        }
        view?.render(vm)
    }
}
