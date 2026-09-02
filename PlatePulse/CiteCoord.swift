import SafariServices
import UIKit

/// Modal sources list. Each row opens the cited page in Safari.
@MainActor
final class CiteCoord: Coord {
    var parent: Coord?
    var kids: [any Coord] = []
    var didFinish: (() -> Void)?

    let store: PulseMgr
    let root: CiteVC
    private let prsntr: CitePrsntr

    init(store: PulseMgr) {
        self.store = store
        root = CiteVC()
        prsntr = CitePrsntr(store: store)
        prsntr.view = root
        root.prsntr = prsntr
        prsntr.coord = self
    }

    func start() {
        prsntr.reload()
    }

    func open(_ href: String) {
        guard let url = URL(string: href) else { return }
        let safari = SFSafariViewController(url: url)
        safari.preferredBarTintColor = PulseHue.bg(false)
        safari.preferredControlTintColor = PulseHue.accent(false)
        safari.dismissButtonStyle = .close
        root.present(safari, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    func close() {
        root.dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { [weak self] in
            self?.didFinish?()
        }
    }
}
