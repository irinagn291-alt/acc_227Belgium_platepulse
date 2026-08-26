import UIKit

/// Single shared easing. Reduce Motion becomes a fade or a snap.
enum PulseAnim {
    static let dur: TimeInterval = 0.28

    @MainActor
    static func run(_ body: @escaping () -> Void) {
        if UIAccessibility.isReduceMotionEnabled {
            body()
            return
        }
        UIView.animate(withDuration: dur, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: body)
    }

    @MainActor
    static func fade(_ view: UIView, show: Bool) {
        if UIAccessibility.isReduceMotionEnabled {
            view.alpha = show ? 1 : 0
            return
        }
        UIView.animate(withDuration: dur, delay: 0, options: [.curveEaseInOut], animations: {
            view.alpha = show ? 1 : 0
        })
    }

    @MainActor
    static func stagger(_ views: [UIView]) {
        if UIAccessibility.isReduceMotionEnabled {
            views.forEach { $0.alpha = 1 }
            return
        }
        for (i, v) in views.enumerated() {
            v.alpha = 0
            UIView.animate(withDuration: dur, delay: 0.04 * Double(i), options: [.curveEaseInOut], animations: {
                v.alpha = 1
            })
        }
    }

    @MainActor
    static func flash(_ view: UIView, hi: Bool) {
        let mark = PulseHue.accent(hi).withAlphaComponent(0.35)
        let rest = PulseHue.surface(hi)
        view.backgroundColor = mark
        if UIAccessibility.isReduceMotionEnabled {
            view.backgroundColor = rest
            return
        }
        UIView.animate(withDuration: 0.8, delay: 0.15, options: [.curveEaseInOut], animations: {
            view.backgroundColor = rest
        })
    }
}
