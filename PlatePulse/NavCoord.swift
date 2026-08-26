import UIKit

/// Owns the Today / Log / Plan / Goals pager.
@MainActor
final class NavCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?

    let store: PulseMgr
    let food: FoodSvc
    let imgs: ImgLoad
    let root: PageHostVC
    private let dayVC = DayVC()
    private let logVC = LogVC()
    private let planVC = PlanVC()
    private let goalVC = GoalVC()
    private let dayP: DayPrsntr
    private let logP: LogPrsntr
    private let planP: PlanPrsntr
    private let goalP: GoalPrsntr

    init(store: PulseMgr, food: FoodSvc, imgs: ImgLoad) {
        self.store = store
        self.food = food
        self.imgs = imgs
        root = PageHostVC()
        dayP = DayPrsntr(store: store)
        logP = LogPrsntr(store: store)
        planP = PlanPrsntr(store: store)
        goalP = GoalPrsntr(store: store)
        dayP.view = dayVC
        logP.view = logVC
        planP.view = planVC
        goalP.view = goalVC
        dayVC.prsntr = dayP
        logVC.prsntr = logP
        planVC.prsntr = planP
        goalVC.prsntr = goalP
        logVC.imgs = imgs
        planVC.imgs = imgs
        dayP.coord = self
        logP.coord = self
        planP.coord = self
        goalP.coord = self
    }

    func start() {
        root.pages = [dayVC, logVC, planVC, goalVC]
        root.titles = ["Today", "Log", "Plan", "Goals"]
        let saved = UserDefaults.standard.integer(forKey: "plp.page")
        root.startAt = (0...3).contains(saved) ? saved : 0
        root.onPage = { idx in
            UserDefaults.standard.set(idx, forKey: "plp.page")
        }
    }

    func openFlow(page: FlowPage, item: FoodItem? = nil) {
        let flow = FlowCoord(store: store, food: food, imgs: imgs, start: page, item: item)
        flow.didFinish = { [weak self, weak flow] in
            guard let self, let flow else { return }
            self.dropKid(flow)
            self.refreshAll()
        }
        addKid(flow)
        flow.onLand = { [weak self] eaten in
            self?.root.go(eaten ? 0 : 2)
        }
        flow.start()
        present(flow.root)
    }

    func openWish() {
        let wish = WishCoord(store: store, imgs: imgs)
        wish.didFinish = { [weak self, weak wish] in
            guard let self, let wish else { return }
            self.dropKid(wish)
        }
        wish.onPick = { [weak self] item in
            self?.openFlow(page: .dtl, item: item)
        }
        addKid(wish)
        wish.start()
        present(wish.root)
    }

    func openA11y() {
        let a11y = A11yCoord(store: store)
        a11y.didFinish = { [weak self, weak a11y] in
            guard let self, let a11y else { return }
            self.dropKid(a11y)
            self.refreshAll()
        }
        addKid(a11y)
        a11y.start()
        present(a11y.root)
    }

    func rerunOnb() {
        (parent as? AppCoord)?.rerunOnb()
    }

    func jump(_ idx: Int) {
        root.go(idx)
    }

    func refreshAll() {
        dayP.reload()
        logP.reload()
        planP.reload()
        goalP.reload()
    }

    private func present(_ vc: UIViewController) {
        if UIAccessibility.isReduceMotionEnabled {
            vc.modalTransitionStyle = .crossDissolve
        }
        vc.modalPresentationStyle = .pageSheet
        root.present(vc, animated: !UIAccessibility.isReduceMotionEnabled)
    }
}
