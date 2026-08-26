import UIKit

/// Keyboard avoidance and dismiss. Decimal fields stay visible.
enum PulseKbd {
    @MainActor
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

    @MainActor
    static func watch(_ scroll: UIScrollView, owner: AnyObject) -> [NSObjectProtocol] {
        let show = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { note in
            let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            Task { @MainActor in
                guard let end else { return }
                let local = scroll.convert(end, from: nil)
                let overlap = max(0, scroll.bounds.maxY - local.minY)
                scroll.contentInset.bottom = overlap
                scroll.verticalScrollIndicatorInsets.bottom = overlap
            }
        }
        let hide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                scroll.contentInset.bottom = 0
                scroll.verticalScrollIndicatorInsets.bottom = 0
            }
        }
        _ = owner
        return [show, hide]
    }

    @MainActor
    static func dismissTap(_ view: UIView) -> UITapGestureRecognizer {
        let g = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        g.cancelsTouchesInView = false
        view.addGestureRecognizer(g)
        return g
    }
}
