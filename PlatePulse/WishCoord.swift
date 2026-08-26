import UIKit

/// Wish-list sheet. Promote hands a product to the logging flow.
@MainActor
final class WishCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?
    var onPick: ((FoodItem) -> Void)?

    let store: PulseMgr
    let imgs: ImgLoad
    let root: WishVC
    private let prsntr: WishPrsntr

    init(store: PulseMgr, imgs: ImgLoad) {
        self.store = store
        self.imgs = imgs
        root = WishVC()
        prsntr = WishPrsntr(store: store)
        prsntr.view = root
        root.prsntr = prsntr
        root.imgs = imgs
        prsntr.coord = self
    }

    func start() {
        prsntr.reload()
    }

    func promote(_ item: FoodItem) {
        root.dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { [weak self] in
            self?.onPick?(item)
            self?.didFinish?()
        }
    }

    func close() {
        root.dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { [weak self] in
            self?.didFinish?()
        }
    }
}
