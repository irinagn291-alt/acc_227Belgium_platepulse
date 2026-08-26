import UIKit

/// Eaten log row.
@MainActor
final class LogCell: UITableViewCell {
    static let reuse = "LogCell"
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var bodyLbl: UILabel!
    @IBOutlet private weak var kcalLbl: UILabel!

    func apply(_ row: LogRowVM, hi: Bool) {
        backgroundColor = PulseHue.surface(hi)
        contentView.backgroundColor = PulseHue.surface(hi)
        icon.image = UIImage(named: row.icon)
        icon.isAccessibilityElement = false
        titleLbl.do { $0.text = row.title; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2; $0.lineBreakMode = .byTruncatingTail }
        bodyLbl.do { $0.text = row.body; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.muted(hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2 }
        kcalLbl.do { $0.text = row.kcal; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.accent(hi); $0.adjustsFontForContentSizeCategory = true; $0.setContentCompressionResistancePriority(.required, for: .horizontal) }
        isAccessibilityElement = true
        accessibilityLabel = "\(row.title), \(row.body), \(row.kcal)"
        selectionStyle = .none
    }

    func setThumb(_ img: UIImage) {
        icon.image = img
    }
}
