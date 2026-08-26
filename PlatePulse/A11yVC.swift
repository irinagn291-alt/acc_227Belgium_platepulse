import UIKit

/// Twist screen for Access Mode.
@MainActor
final class A11yVC: UIViewController, A11yView {
    var prsntr: A11yPrsntr!

    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var heroImg: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var bodyLbl: UILabel!
    @IBOutlet private weak var hiSw: UISwitch!
    @IBOutlet private weak var hiLbl: UILabel!
    @IBOutlet private weak var motionLbl: UILabel!
    @IBOutlet private weak var typeLbl: UILabel!
    @IBOutlet private weak var closeBtn: UIButton!

    init() { super.init(nibName: "A11yVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        heroImg.image = UIImage(named: "plp_TwistHero")
        heroImg.isAccessibilityElement = false
        hiSw.addTarget(self, action: #selector(tog), for: .valueChanged)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        hiSw.accessibilityLabel = "High contrast theme"
        hiSw.accessibilityHint = "Increases border and text contrast across the app"
        closeBtn.accessibilityLabel = "Close Access Mode"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: A11yVM) {
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do { $0.text = vm.title; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        bodyLbl.do { $0.text = vm.body; $0.font = PulseType.font(.body); $0.textColor = PulseHue.muted(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        hiLbl.do { $0.text = vm.hiLabel; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        motionLbl.do { $0.text = vm.motion; $0.font = PulseType.font(.body); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        typeLbl.do { $0.text = vm.type; $0.font = PulseType.font(.body); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        hiSw.isOn = vm.hi
        hiSw.onTintColor = PulseHue.accent(vm.hi)
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.titleLabel?.font = PulseType.font(.label, bold: true)
        closeBtn.setTitleColor(PulseHue.ink(vm.hi), for: .normal)
        closeBtn.backgroundColor = PulseHue.surface(vm.hi)
        closeBtn.layer.borderWidth = 2
        closeBtn.layer.borderColor = PulseHue.accent(vm.hi).cgColor
    }

    @objc private func tog() { prsntr.setHi(hiSw.isOn) }
    @objc private func close() { prsntr.close() }
}
