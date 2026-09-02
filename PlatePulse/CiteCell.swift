import UIKit

/// One citation row with a tappable source link.
@MainActor
final class CiteCell: UITableViewCell {
    static let reuse = "CiteCell"
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var bodyLbl: UILabel!
    @IBOutlet private weak var hrefLbl: UILabel!

    func apply(_ row: CiteRowVM, hi: Bool) {
        backgroundColor = PulseHue.surface(hi)
        contentView.backgroundColor = PulseHue.surface(hi)
        titleLbl.do {
            $0.text = row.title
            $0.font = PulseType.font(.label, bold: true)
            $0.textColor = PulseHue.ink(hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        bodyLbl.do {
            $0.text = row.body
            $0.font = PulseType.font(.caption)
            $0.textColor = PulseHue.muted(hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        hrefLbl.do {
            $0.text = row.href
            $0.font = PulseType.font(.caption)
            $0.textColor = PulseHue.accent(hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        isAccessibilityElement = true
        accessibilityTraits = .link
        accessibilityLabel = "\(row.title). \(row.body)"
        accessibilityHint = "Opens \(row.href)"
        selectionStyle = .none
        accessoryType = .none
        contentView.layer.borderWidth = hi ? 2 : 0
        contentView.layer.borderColor = PulseHue.stroke(hi).cgColor
    }
}
