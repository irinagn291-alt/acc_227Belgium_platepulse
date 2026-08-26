import UIKit

/// Root coordinator. Chooses onboarding or the paging shell.
@MainActor
final class AppCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?

    let win: UIWindow
    let store: PulseMgr
    let food: FoodSvc
    let imgs: ImgLoad

    init(win: UIWindow, store: PulseMgr = PulseMgr(), food: FoodSvc = FoodSvc(), imgs: ImgLoad = ImgLoad()) {
        self.win = win
        self.store = store
        self.food = food
        self.imgs = imgs
    }

    func start() {
        Task { [weak self] in
            guard let self else { return }
            let note = await store.boot()
            let done = await store.isOnboarded()
            if done {
                showMain()
            } else {
                showOnb()
            }
            if let note {
                warn(note)
            }
        }
    }

    func flush() async {
        await store.flush()
    }

    func showMain() {
        kids.removeAll()
        let nav = NavCoord(store: store, food: food, imgs: imgs)
        nav.didFinish = { [weak self] in
            guard let self, let nav = self.kids.first(where: { $0 is NavCoord }) else { return }
            self.dropKid(nav)
        }
        addKid(nav)
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-ReviewScreen"), index + 1 < args.count {
            switch args[index + 1] {
            case "log": UserDefaults.standard.set(1, forKey: "plp.page")
            case "goals": UserDefaults.standard.set(3, forKey: "plp.page")
            default: break
            }
        }
        nav.start()
        swap(nav.root)
    }

    func showOnb() {
        kids.removeAll()
        let onb = OnbCoord(store: store)
        onb.didFinish = { [weak self] in
            self?.showMain()
        }
        addKid(onb)
        onb.start()
        swap(onb.root)
    }

    func rerunOnb() {
        Task { [weak self] in
            await self?.store.reopenOnb()
            self?.showOnb()
        }
    }

    private func swap(_ root: UIViewController) {
        if UIAccessibility.isReduceMotionEnabled {
            win.rootViewController = root
            return
        }
        UIView.transition(with: win, duration: PulseAnim.dur, options: [.transitionCrossDissolve, .curveEaseInOut]) {
            self.win.rootViewController = root
        }
    }

    private func warn(_ msg: String) {
        guard let root = win.rootViewController else { return }
        let a = UIAlertController(title: "Readings restored", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        root.present(a, animated: !UIAccessibility.isReduceMotionEnabled)
    }
}
