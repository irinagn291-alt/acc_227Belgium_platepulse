import UIKit

/// Twist screen for the accessibility-first feature.
@MainActor
final class A11yCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?

    let store: PulseMgr
    let root: A11yVC
    private let prsntr: A11yPrsntr

    init(store: PulseMgr) {
        self.store = store
        root = A11yVC()
        prsntr = A11yPrsntr(store: store)
        prsntr.view = root
        root.prsntr = prsntr
        prsntr.coord = self
    }

    func start() {
        prsntr.reload()
    }

    func close() {
        root.dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { [weak self] in
            self?.didFinish?()
        }
    }
}
