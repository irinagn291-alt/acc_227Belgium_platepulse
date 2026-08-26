import UIKit

/// Planned row with a one-tap eat action.
@MainActor
final class PlanCell: UITableViewCell {
    static let reuse = "PlanCell"
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var bodyLbl: UILabel!
    @IBOutlet private weak var kcalLbl: UILabel!
    @IBOutlet private weak var eatBtn: UIButton!
    private var onEat: (() -> Void)?

    func apply(_ row: PlanRowVM, hi: Bool, eat: @escaping () -> Void) {
        onEat = eat
        backgroundColor = PulseHue.surface(hi)
        contentView.backgroundColor = PulseHue.surface(hi)
        icon.image = UIImage(named: row.icon)
        icon.isAccessibilityElement = false
        titleLbl.do { $0.text = row.title; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2; $0.lineBreakMode = .byTruncatingTail }
        bodyLbl.do { $0.text = row.body; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.muted(hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2 }
        kcalLbl.do { $0.text = row.kcal; $0.font = PulseType.font(.caption, bold: true); $0.textColor = PulseHue.accent(hi); $0.adjustsFontForContentSizeCategory = true }
        eatBtn.setTitle("Eat now", for: .normal)
        eatBtn.titleLabel?.font = PulseType.font(.label, bold: true)
        eatBtn.setTitleColor(PulseHue.ink(hi), for: .normal)
        eatBtn.backgroundColor = PulseHue.bg(hi)
        eatBtn.accessibilityLabel = "Convert \(row.title) to eaten today"
        eatBtn.removeTarget(nil, action: nil, for: .allEvents)
        eatBtn.addTarget(self, action: #selector(tap), for: .touchUpInside)
        selectionStyle = .none
        isAccessibilityElement = false
    }

    func setThumb(_ img: UIImage) {
        icon.image = img
    }

    @objc private func tap() { onEat?() }
}
