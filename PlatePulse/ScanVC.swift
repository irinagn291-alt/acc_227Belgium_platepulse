import AVFoundation
import UIKit

/// Live camera scan with a large accessible lock trigger.
@MainActor
final class ScanVC: UIViewController, ScanView, UITextFieldDelegate {
    var prsntr: ScanPrsntr!
    private let eng = ScanEng()
    private var chips: [String] = []

    @IBOutlet private weak var previewBox: UIView!
    @IBOutlet private weak var overlayImg: UIImageView!
    @IBOutlet private weak var trigBtn: UIButton!
    @IBOutlet private weak var manField: UITextField!
    @IBOutlet private weak var goBtn: UIButton!
    @IBOutlet private weak var chipBox: UIStackView!
    @IBOutlet private weak var permBox: UIView!
    @IBOutlet private weak var permLbl: UILabel!
    @IBOutlet private weak var permBtn: UIButton!
    @IBOutlet private weak var statusLbl: UILabel!

    init() { super.init(nibName: "ScanVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        overlayImg.image = UIImage(named: "plp_ScanOverlay")
        overlayImg.isAccessibilityElement = false
        trigBtn.addTarget(self, action: #selector(lock), for: .touchUpInside)
        goBtn.addTarget(self, action: #selector(typed), for: .touchUpInside)
        permBtn.addTarget(self, action: #selector(perm), for: .touchUpInside)
        manField.delegate = self
        manField.placeholder = "Barcode or QR link"
        manField.accessibilityLabel = "Manual barcode or QR link"
        manField.accessibilityHint = "Type a barcode or paste a QR product URL when the camera is unavailable"
        PulseKbd.dock(manField, target: self, done: #selector(doneKbd))
        manField.keyboardType = .URL
        manField.textContentType = .URL
        manField.autocapitalizationType = .none
        manField.autocorrectionType = .no
        manField.spellCheckingType = .no
        trigBtn.accessibilityLabel = "Lock this reading"
        trigBtn.accessibilityHint = "Accepts the last spoken barcode and opens detail"
        trigBtn.accessibilityTraits = .button
        goBtn.accessibilityLabel = "Look up typed barcode"
        eng.onRead = { [weak self] raw in
            self?.prsntr.heard(raw)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(bg), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fg), name: UIApplication.willEnterForegroundNotification, object: nil)
        _ = PulseKbd.dismissTap(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.appear()
        eng.attach(to: previewBox)
        eng.start()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eng.layout(in: previewBox)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        eng.stop()
    }

    func armLive() { eng.start() }

    func render(_ vm: ScanVM) {
        view.backgroundColor = PulseHue.bg(vm.hi)
        statusLbl.do {
            $0.text = vm.status
            $0.font = PulseType.font(.caption)
            $0.textColor = PulseHue.ink(vm.hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        trigBtn.setTitle("Lock reading", for: .normal)
        goBtn.setTitle("Look up", for: .normal)
        [trigBtn, goBtn].forEach { paintBtn($0, vm.hi) }
        trigBtn.titleLabel?.font = PulseType.font(.title, bold: true)
        manField.font = PulseType.font(.body)
        manField.textColor = PulseHue.ink(vm.hi)
        manField.backgroundColor = PulseHue.surface(vm.hi)
        permBox.isHidden = vm.perm == .ok
        previewBox.isHidden = !vm.hasCam
        overlayImg.isHidden = !vm.hasCam
        permLbl.font = PulseType.font(.body)
        permLbl.textColor = PulseHue.ink(vm.hi)
        permLbl.numberOfLines = 0
        permLbl.adjustsFontForContentSizeCategory = true
        permLbl.text = [vm.permTitle, vm.permBody].filter { !$0.isEmpty }.joined(separator: "\n")
        switch vm.perm {
        case .ask:
            permBtn.setTitle("Allow camera", for: .normal)
            permBtn.accessibilityLabel = "Allow camera"
        case .denied, .lock:
            permBtn.setTitle("Open Settings", for: .normal)
            permBtn.accessibilityLabel = "Open Settings"
        case .none:
            permBtn.setTitle("Use a sample code", for: .normal)
            permBtn.accessibilityLabel = "Use a sample code"
        case .ok:
            break
        }
        paintBtn(permBtn, vm.hi)
        permBox.backgroundColor = PulseHue.surface(vm.hi)
        permBox.layer.borderWidth = vm.hi ? 2 : 0
        permBox.layer.borderColor = PulseHue.stroke(vm.hi).cgColor
        chips = vm.chips
        fillChips(vm.hi)
    }

    @objc private func lock() { prsntr.lock() }
    @objc private func typed() { prsntr.typed(manField.text ?? "") }
    @objc private func doneKbd() { view.endEditing(true) }
    @objc private func bg() { eng.stop() }
    @objc private func fg() { eng.start() }

    @objc private func perm() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            prsntr.askCam()
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default:
            if let first = chips.first { prsntr.chip(first) }
        }
    }

    private func fillChips(_ hi: Bool) {
        chipBox.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for code in chips {
            let b = UIButton(type: .system).then {
                $0.setTitle(code, for: .normal)
                $0.titleLabel?.font = PulseType.font(.caption, bold: true)
                $0.titleLabel?.adjustsFontForContentSizeCategory = true
                $0.setTitleColor(PulseHue.ink(hi), for: .normal)
                $0.backgroundColor = PulseHue.surface(hi)
                $0.layer.borderWidth = hi ? 2 : 1
                $0.layer.borderColor = PulseHue.accent(hi).cgColor
                $0.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
                $0.accessibilityLabel = "Sample barcode \(code)"
                $0.accessibilityHint = "Looks up this shelf product"
                $0.addTarget(self, action: #selector(chipTap(_:)), for: .touchUpInside)
            }
            chipBox.addArrangedSubview(b)
        }
    }

    @objc private func chipTap(_ sender: UIButton) {
        prsntr.chip(sender.title(for: .normal) ?? "")
    }

    private func paintBtn(_ btn: UIButton?, _ hi: Bool) {
        btn?.titleLabel?.font = PulseType.font(.label, bold: true)
        btn?.titleLabel?.adjustsFontForContentSizeCategory = true
        btn?.setTitleColor(PulseHue.ink(hi), for: .normal)
        btn?.backgroundColor = PulseHue.surface(hi)
        btn?.layer.borderWidth = hi ? 2 : 1
        btn?.layer.borderColor = PulseHue.accent(hi).cgColor
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        typed()
        return true
    }
}
