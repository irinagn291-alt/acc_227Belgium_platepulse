import UIKit

/// Four-step logging journey: Search / Scan / Detail / Assign.
@MainActor
final class FlowCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?
    var onLand: ((Bool) -> Void)?

    let store: PulseMgr
    let food: FoodSvc
    let imgs: ImgLoad
    let root: FlowHostVC
    var item: FoodItem?
    var grams: Double = 100

    private let srchVC = SrchVC()
    private let scanVC = ScanVC()
    private let dtlVC = DtlVC()
    private let asgnVC = AsgnVC()
    private let srchP: SrchPrsntr
    private let scanP: ScanPrsntr
    private let dtlP: DtlPrsntr
    private let asgnP: AsgnPrsntr
    private let startPage: FlowPage

    init(store: PulseMgr, food: FoodSvc, imgs: ImgLoad, start: FlowPage, item: FoodItem?) {
        self.store = store
        self.food = food
        self.imgs = imgs
        self.startPage = start
        self.item = item
        root = FlowHostVC()
        srchP = SrchPrsntr(store: store, food: food)
        scanP = ScanPrsntr(store: store, food: food)
        dtlP = DtlPrsntr(store: store)
        asgnP = AsgnPrsntr(store: store)
        srchP.view = srchVC
        scanP.view = scanVC
        dtlP.view = dtlVC
        asgnP.view = asgnVC
        srchVC.prsntr = srchP
        scanVC.prsntr = scanP
        dtlVC.prsntr = dtlP
        asgnVC.prsntr = asgnP
        srchP.coord = self
        scanP.coord = self
        dtlP.coord = self
        asgnP.coord = self
        dtlVC.imgs = imgs
        srchVC.imgs = imgs
    }

    func start() {
        root.pages = [srchVC, scanVC, dtlVC, asgnVC]
        root.titles = ["Search", "Scan", "Detail", "Assign"]
        root.startAt = startPage.rawValue
        root.onClose = { [weak self] in
            self?.close()
        }
    }

    func picked(_ item: FoodItem) {
        self.item = item
        Task { await store.putFood(item) }
        ping()
        root.go(FlowPage.dtl.rawValue)
    }

    func setGrams(_ g: Double) {
        grams = g
        asgnP.reload()
    }

    func assigned(eaten: Bool) {
        PulseHapt.commit()
        let mark = UIImageView(image: UIImage(named: "plp_SuccessMark"))
        mark.bounds = CGRect(x: 0, y: 0, width: 128, height: 128)
        mark.center = CGPoint(x: root.view.bounds.midX, y: root.view.bounds.midY)
        mark.isAccessibilityElement = false
        mark.accessibilityElementsHidden = true
        root.view.addSubview(mark)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 280_000_000)
            mark.removeFromSuperview()
            self.onLand?(eaten)
            self.close()
        }
    }

    func close() {
        root.dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { [weak self] in
            self?.didFinish?()
        }
    }

    func openCite() {
        let cite = CiteCoord(store: store)
        cite.didFinish = { [weak self, weak cite] in
            guard let self, let cite else { return }
            self.dropKid(cite)
        }
        addKid(cite)
        cite.start()
        if UIAccessibility.isReduceMotionEnabled {
            cite.root.modalTransitionStyle = .crossDissolve
        }
        cite.root.modalPresentationStyle = .pageSheet
        root.present(cite.root, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    func ping() {
        srchP.reload()
        dtlP.reload()
        asgnP.reload()
    }
}
