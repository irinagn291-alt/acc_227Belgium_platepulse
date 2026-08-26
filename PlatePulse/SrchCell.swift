import UIKit

/// Search result row.
@MainActor
final class SrchCell: UITableViewCell {
    static let reuse = "SrchCell"
    @IBOutlet private weak var thumb: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var brandLbl: UILabel!
    @IBOutlet private weak var kcalLbl: UILabel!

    func apply(_ row: SrchRowVM, hi: Bool) {
        backgroundColor = PulseHue.surface(hi)
        contentView.backgroundColor = PulseHue.surface(hi)
        thumb.image = UIImage(named: "plp_ProductPlaceholder")
        thumb.isAccessibilityElement = false
        titleLbl.do { $0.text = row.title; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2; $0.lineBreakMode = .byTruncatingTail }
        brandLbl.do { $0.text = row.brand; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.muted(hi); $0.adjustsFontForContentSizeCategory = true }
        kcalLbl.do { $0.text = row.kcal; $0.font = PulseType.font(.caption, bold: true); $0.textColor = PulseHue.accent(hi); $0.adjustsFontForContentSizeCategory = true; $0.setContentCompressionResistancePriority(.required, for: .horizontal) }
        isAccessibilityElement = true
        accessibilityLabel = "\(row.title), \(row.brand), \(row.kcal)"
        accessibilityTraits = .button
        selectionStyle = .none
        accessoryType = .disclosureIndicator
    }

    func setThumb(_ img: UIImage) {
        thumb.image = img
    }
}
