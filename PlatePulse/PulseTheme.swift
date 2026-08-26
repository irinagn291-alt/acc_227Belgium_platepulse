import UIKit

/// Typed palette accessor. Hex lives only in the asset catalog.
enum PulseHue {
    static func bg(_ hi: Bool) -> UIColor {
        named("plp_background")
    }

    static func surface(_ hi: Bool) -> UIColor {
        let s = named("plp_surface")
        return hi ? s : s
    }

    static func ink(_ hi: Bool) -> UIColor {
        named("plp_ink")
    }

    static func accent(_ hi: Bool) -> UIColor {
        named("plp_accent")
    }

    static func muted(_ hi: Bool) -> UIColor {
        named(A11yLogic.mutedName(hi))
    }

    static func stroke(_ hi: Bool) -> UIColor {
        hi ? named("plp_ink") : named("plp_muted")
    }

    private static func named(_ key: String) -> UIColor {
        UIColor(named: key) ?? .label
    }
}

/// Six-step rounded Dynamic Type scale.
enum PulseType {
    enum Step {
        case hero, title, label, body, caption, micro
    }

    static func font(_ step: Step, bold: Bool = false) -> UIFont {
        let style: UIFont.TextStyle
        let pt: CGFloat
        switch step {
        case .hero:
            style = .largeTitle
            pt = 34
        case .title:
            style = .title2
            pt = 22
        case .label:
            style = .headline
            pt = 17
        case .body:
            style = .body
            pt = 17
        case .caption:
            style = .footnote
            pt = 13
        case .micro:
            style = .caption2
            pt = 11
        }
        let weight: UIFont.Weight = bold ? .bold : .regular
        let sys = UIFont.systemFont(ofSize: pt, weight: weight)
        let rounded = UIFont(descriptor: sys.fontDescriptor.withDesign(.rounded) ?? sys.fontDescriptor, size: pt)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: rounded)
    }
}

/// High-contrast token swap. Persisted by A11yPrefs, tested in isolation.
enum A11yLogic {
    static func mutedName(_ hi: Bool) -> String {
        hi ? "plp_ink" : "plp_muted"
    }
}

enum PulseSp {
    static let u: CGFloat = 8
    static func n(_ k: CGFloat) -> CGFloat { u * k }
}

enum PulseBtn {
    static func paint(_ btn: UIButton?, title: String, hi: Bool, accentInk: Bool = false) {
        guard let btn else { return }
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.baseForegroundColor = accentInk ? PulseHue.accent(hi) : PulseHue.ink(hi)
        config.background.backgroundColor = PulseHue.surface(hi)
        config.background.strokeColor = PulseHue.accent(hi)
        config.background.strokeWidth = hi ? 2 : 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = PulseType.font(.label, bold: true)
            return out
        }
        btn.configuration = config
        btn.setImage(nil, for: .normal)
        btn.accessibilityLabel = title
    }
}

enum PulseNotif {
    static let store = Notification.Name("plp.store")
    static let a11y = Notification.Name("plp.a11y")
}

final class PulseBar: UIView {
    private let fill = UIView()
    private var fillW: NSLayoutConstraint?

    var frac: Double = 0 {
        didSet { sync() }
    }

    var hi: Bool = false {
        didSet { paint() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated { boot() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        boot()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func boot() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(greaterThanOrEqualToConstant: PulseSp.n(1)).isActive = true
        fill.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fill)
        let w = fill.widthAnchor.constraint(equalToConstant: 0)
        fillW = w
        NSLayoutConstraint.activate([
            fill.leadingAnchor.constraint(equalTo: leadingAnchor),
            fill.topAnchor.constraint(equalTo: topAnchor),
            fill.bottomAnchor.constraint(equalTo: bottomAnchor),
            w
        ])
        isAccessibilityElement = true
        paint()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sync()
    }

    private func paint() {
        backgroundColor = PulseHue.muted(hi).withAlphaComponent(hi ? 0.35 : 0.22)
        fill.backgroundColor = PulseHue.accent(hi)
        layer.borderWidth = hi ? 2 : 0
        layer.borderColor = PulseHue.stroke(hi).cgColor
    }

    private func sync() {
        let f = min(max(frac, 0), 1.4)
        fillW?.constant = bounds.width * CGFloat(min(f, 1))
        accessibilityValue = "\(Int((min(frac, 1) * 100).rounded())) percent"
    }
}

extension Array {
    subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
