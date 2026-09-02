import UIKit

/// Keyboard avoidance and dismiss. Decimal fields stay visible.
@MainActor
enum PulseKbd {
    static func dock(_ field: UITextField, target: Any, done: Selector) {
        let bar = UIToolbar()
        bar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let item = UIBarButtonItem(title: "Done", style: .done, target: target, action: done)
        item.accessibilityLabel = "Dismiss keyboard"
        bar.items = [spacer, item]
        field.inputAccessoryView = bar
        field.keyboardType = .decimalPad
        field.adjustsFontForContentSizeCategory = true
    }

    static func watch(_ scroll: UIScrollView, owner: AnyObject) -> [NSObjectProtocol] {
        let hook = PulseKbdHook(scroll: scroll)
        hook.bind()
        _ = owner
        return [hook]
    }

    static func dismissTap(_ view: UIView) -> UITapGestureRecognizer {
        let g = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        g.cancelsTouchesInView = false
        view.addGestureRecognizer(g)
        return g
    }
}

@MainActor
final class PulseKbdHook: NSObject {
    private weak var scroll: UIScrollView?

    init(scroll: UIScrollView) {
        self.scroll = scroll
    }

    func bind() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(show(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self, selector: #selector(hide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func show(_ note: Notification) {
        apply(note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)
    }

    @objc private func hide() {
        apply(nil)
    }

    private func apply(_ end: CGRect?) {
        guard let scroll else { return }
        guard let end else {
            scroll.contentInset.bottom = 0
            scroll.verticalScrollIndicatorInsets.bottom = 0
            return
        }
        let local = scroll.convert(end, from: nil)
        let overlap = max(0, scroll.bounds.maxY - local.minY)
        scroll.contentInset.bottom = overlap
        scroll.verticalScrollIndicatorInsets.bottom = overlap
    }
}
