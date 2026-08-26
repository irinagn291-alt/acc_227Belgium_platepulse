import Foundation

struct WishRowVM: Sendable, Equatable {
    var id: UUID
    var code: String
    var title: String
    var brand: String
    var kcal: String
    var imgURL: String?
    var shelfImg: String?
}

struct WishVM: Sendable {
    var title: String
    var rows: [WishRowVM]
    var empty: Bool
    var emptyTitle: String
    var emptyBody: String
    var hi: Bool
}

@MainActor
protocol WishView: AnyObject {
    func render(_ vm: WishVM)
}

/// Wish list. Duplicate barcodes update the existing row.
@MainActor
final class WishPrsntr {
    weak var view: WishView?
    weak var coord: WishCoord?
    private let store: PulseMgr

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        Task { await push() }
    }

    func promote(_ id: UUID) {
        Task { [weak self] in
            guard let self else { return }
            let recs = await store.allWishes()
            guard let rec = recs.first(where: { $0.id == id }) else { return }
            coord?.promote(rec.asFood())
        }
    }

    func drop(_ id: UUID) {
        Task { [weak self] in
            await self?.store.dropWish(id)
            await self?.push()
        }
    }

    func tapEmpty() {
        coord?.close()
        (coord?.parent as? NavCoord)?.openFlow(page: .srch)
    }

    func close() {
        coord?.close()
    }

    private func push() async {
        let recs = await store.allWishes()
        let hi = await store.prefs().hiContrast
        view?.render(WishVM(
            title: "Wish Shelf",
            rows: recs.map {
                WishRowVM(
                    id: $0.id,
                    code: $0.code,
                    title: $0.name,
                    brand: $0.brand,
                    kcal: $0.kcal100 == nil ? "unknown kcal / 100 g" : "\(PulseFmt.kcalUnit($0.kcal100)) / 100 g",
                    imgURL: $0.imgURL,
                    shelfImg: $0.shelfImg
                )
            },
            empty: recs.isEmpty,
            emptyTitle: "Wish shelf is empty",
            emptyBody: "Save a pack from Detail to buy later.",
            hi: hi
        ))
    }
}
