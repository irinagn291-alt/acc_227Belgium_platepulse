import UIKit

/// Four-page onboarding. Skip still writes default targets.
@MainActor
final class OnbCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?

    let store: PulseMgr
    let root: OnbVC
    private let prsntr: OnbPrsntr

    init(store: PulseMgr) {
        self.store = store
        root = OnbVC()
        prsntr = OnbPrsntr(store: store)
        prsntr.view = root
        root.prsntr = prsntr
        prsntr.coord = self
    }

    func start() {
        prsntr.reload()
    }

    func finished() {
        didFinish?()
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
}
