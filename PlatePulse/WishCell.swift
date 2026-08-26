import UIKit

/// Wish-list row.
@MainActor
final class WishCell: UITableViewCell {
    static let reuse = "WishCell"
    @IBOutlet private weak var thumb: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var brandLbl: UILabel!
    @IBOutlet private weak var kcalLbl: UILabel!
    @IBOutlet private weak var goBtn: UIButton!
    private var onGo: (() -> Void)?

    func apply(_ row: WishRowVM, hi: Bool, go: @escaping () -> Void) {
        onGo = go
        backgroundColor = PulseHue.surface(hi)
        contentView.backgroundColor = PulseHue.surface(hi)
        thumb.image = UIImage(named: "plp_ProductPlaceholder")
        thumb.isAccessibilityElement = false
        titleLbl.do { $0.text = row.title; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2; $0.lineBreakMode = .byTruncatingTail }
        brandLbl.do { $0.text = row.brand; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.muted(hi); $0.adjustsFontForContentSizeCategory = true }
        kcalLbl.do { $0.text = row.kcal; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.accent(hi); $0.adjustsFontForContentSizeCategory = true }
        goBtn.setTitle("Log", for: .normal)
        goBtn.titleLabel?.font = PulseType.font(.label, bold: true)
        goBtn.setTitleColor(PulseHue.ink(hi), for: .normal)
        goBtn.backgroundColor = PulseHue.bg(hi)
        goBtn.accessibilityLabel = "Promote \(row.title) to a reading"
        goBtn.removeTarget(nil, action: nil, for: .allEvents)
        goBtn.addTarget(self, action: #selector(tap), for: .touchUpInside)
        selectionStyle = .none
        isAccessibilityElement = false
    }

    func setThumb(_ img: UIImage) {
        thumb.image = img
    }

    @objc private func tap() { onGo?() }
}
