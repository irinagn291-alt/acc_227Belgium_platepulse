import UIKit

struct A11yVM: Sendable {
    var title: String
    var body: String
    var hi: Bool
    var hiLabel: String
    var motion: String
    var type: String
}

@MainActor
protocol A11yView: AnyObject {
    func render(_ vm: A11yVM)
}

/// Persisted high-contrast twist plus Reduce Motion / Dynamic Type status.
@MainActor
final class A11yPrsntr {
    weak var view: A11yView?
    weak var coord: A11yCoord?
    private let store: PulseMgr

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        Task { await push() }
    }

    func setHi(_ on: Bool) {
        Task { [weak self] in
            await self?.store.setA11y(A11yPrefs(schemaVersion: 1, hiContrast: on))
            NotificationCenter.default.post(name: PulseNotif.a11y, object: nil)
            NotificationCenter.default.post(name: PulseNotif.store, object: nil)
            await self?.push()
        }
    }

    func close() {
        coord?.close()
    }

    private func push() async {
        let p = await store.prefs()
        let motion = UIAccessibility.isReduceMotionEnabled
            ? "Reduce Motion is on. Transitions fade."
            : "Reduce Motion is off. Short eased motion is used."
        view?.render(A11yVM(
            title: "Access Mode",
            body: "VoiceOver labels, 44-point targets, Dynamic Type through AX5, and a persisted high-contrast theme.",
            hi: p.hiContrast,
            hiLabel: p.hiContrast ? "High contrast is on" : "High contrast is off",
            motion: motion,
            type: "Type size follows the system, including the largest accessibility sizes."
        ))
    }
}
