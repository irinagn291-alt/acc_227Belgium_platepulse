import Foundation

struct DtlVM: Sendable {
    var empty: Bool
    var emptyTitle: String
    var name: String
    var brand: String
    var kcal100: String
    var prot100: String
    var carb100: String
    var fat100: String
    var grams: String
    var totKcal: String
    var totProt: String
    var totCarb: String
    var totFat: String
    var wishTitle: String
    var wishOn: Bool
    var canAssign: Bool
    var imgURL: String?
    var shelfImg: String?
    var missingEnergy: Bool
    var cite: String
    var hi: Bool
}

@MainActor
protocol DtlView: AnyObject {
    func render(_ vm: DtlVM)
}

/// Live portion totals from grams. Unknown stays unknown.
@MainActor
final class DtlPrsntr {
    weak var view: DtlView?
    weak var coord: FlowCoord?
    private let store: PulseMgr

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        Task { await push() }
    }

    func grams(_ raw: String) {
        guard let g = PulseFmt.parseDec(raw), g > 0, g <= 10_000 else {
            Task { await push(badGrams: true) }
            return
        }
        coord?.setGrams(g)
        Task { await push() }
    }

    func assign() {
        coord?.root.go(FlowPage.asgn.rawValue)
    }

    func tapCite() {
        coord?.openCite()
    }

    func wish() {
        guard let item = coord?.item else { return }
        Task { [weak self] in
            _ = await self?.store.addWish(item)
            PulseHapt.commit()
            await self?.push()
        }
    }

    private func push(badGrams: Bool = false) async {
        let hi = await store.prefs().hiContrast
        guard let item = coord?.item else {
            view?.render(DtlVM(
                empty: true,
                emptyTitle: "Pick a pack on Search or Scan first.",
                name: "", brand: "", kcal100: "", prot100: "", carb100: "", fat100: "",
                grams: "", totKcal: "", totProt: "", totCarb: "", totFat: "",
                wishTitle: "", wishOn: false, canAssign: false,
                imgURL: nil, shelfImg: nil, missingEnergy: false,
                cite: "Nutrition from Open Food Facts", hi: hi
            ))
            return
        }
        let g = coord?.grams ?? 100
        let wished = await store.hasWish(item.code)
        view?.render(DtlVM(
            empty: false,
            emptyTitle: "",
            name: item.name,
            brand: item.brand.isEmpty ? "Unknown brand" : item.brand,
            kcal100: "Energy \(PulseFmt.kcalUnit(item.kcal100)) / 100 g",
            prot100: "Protein \(PulseFmt.macroUnit(item.prot100, unit: "g")) / 100 g",
            carb100: "Carbs \(PulseFmt.macroUnit(item.carb100, unit: "g")) / 100 g",
            fat100: "Fat \(PulseFmt.macroUnit(item.fat100, unit: "g")) / 100 g",
            grams: PulseFmt.grams(g),
            totKcal: PulseFmt.kcalUnit(PortionMath.part(item.kcal100, g)),
            totProt: PulseFmt.macroUnit(PortionMath.part(item.prot100, g), unit: "g"),
            totCarb: PulseFmt.macroUnit(PortionMath.part(item.carb100, g), unit: "g"),
            totFat: PulseFmt.macroUnit(PortionMath.part(item.fat100, g), unit: "g"),
            wishTitle: wished ? "Already on wish list" : "Save to wish list",
            wishOn: !wished,
            canAssign: !badGrams && g > 0 && g <= 10_000,
            imgURL: item.imgURL,
            shelfImg: item.shelfImg,
            missingEnergy: item.kcal100 == nil,
            cite: "Nutrition from Open Food Facts — open sources",
            hi: hi
        ))
    }
}
