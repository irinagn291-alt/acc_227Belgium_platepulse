import UIKit

/// Passive goals view.
@MainActor
final class GoalVC: UIViewController, GoalView, UITextFieldDelegate, UIScrollViewDelegate {
    var prsntr: GoalPrsntr!
    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var kcalField: UITextField!
    @IBOutlet private weak var protField: UITextField!
    @IBOutlet private weak var carbField: UITextField!
    @IBOutlet private weak var fatField: UITextField!
    @IBOutlet private weak var errLbl: UILabel!
    @IBOutlet private weak var saveBtn: UIButton!
    @IBOutlet private weak var onbBtn: UIButton!
    @IBOutlet private weak var resetBtn: UIButton!
    @IBOutlet private weak var contactBtn: UIButton!
    private var kbd: [NSObjectProtocol] = []
    private var hi = false

    init() { super.init(nibName: "GoalVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        [kcalField, protField, carbField, fatField].forEach { f in
            f?.delegate = self
            f?.addTarget(self, action: #selector(changed), for: .editingChanged)
            if let f { PulseKbd.dock(f, target: self, done: #selector(doneKbd)) }
        }
        caption("Energy kcal", above: kcalField)
        caption("Protein g", above: protField)
        caption("Carbs g", above: carbField)
        caption("Fat g", above: fatField)
        kcalField.accessibilityLabel = "Energy target in kilocalories"
        protField.accessibilityLabel = "Protein target in grams"
        carbField.accessibilityLabel = "Carbohydrate target in grams"
        fatField.accessibilityLabel = "Fat target in grams"
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)
        onbBtn.addTarget(self, action: #selector(onb), for: .touchUpInside)
        resetBtn.addTarget(self, action: #selector(reset), for: .touchUpInside)
        contactBtn.addTarget(self, action: #selector(contact), for: .touchUpInside)
        saveBtn.accessibilityLabel = "Save targets"
        onbBtn.accessibilityLabel = "Re-run onboarding"
        resetBtn.accessibilityLabel = "Reset all data"
        contactBtn.accessibilityLabel = "Contact PlatePulse"
        contactBtn.accessibilityHint = "Opens platepulse.pro contact page"
        _ = PulseKbd.dismissTap(view)
        kbd = PulseKbd.watch(scroll, owner: self)
        scroll.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: GoalVM) {
        hi = vm.hi
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do { $0.text = vm.title; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        if kcalField.text != vm.kcal { kcalField.text = vm.kcal }
        if protField.text != vm.prot { protField.text = vm.prot }
        if carbField.text != vm.carb { carbField.text = vm.carb }
        if fatField.text != vm.fat { fatField.text = vm.fat }
        errLbl.text = vm.err
        errLbl.font = PulseType.font(.caption)
        errLbl.textColor = PulseHue.accent(vm.hi)
        errLbl.numberOfLines = 0
        saveBtn.isEnabled = vm.canSave
        [kcalField, protField, carbField, fatField].forEach { paintField($0, vm.hi) }
        PulseBtn.paint(saveBtn, title: "Save targets", hi: vm.hi)
        PulseBtn.paint(onbBtn, title: "Re-run onboarding", hi: vm.hi)
        PulseBtn.paint(contactBtn, title: "Contact us", hi: vm.hi)
        PulseBtn.paint(resetBtn, title: "Reset all data", hi: vm.hi, accentInk: true)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.contains("-") { return false }
        return true
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    @objc private func changed() {
        prsntr.edit(kcal: kcalField.text, prot: protField.text, carb: carbField.text, fat: fatField.text)
    }

    @objc private func save() { view.endEditing(true); prsntr.save() }
    @objc private func onb() { prsntr.rerunOnb() }
    @objc private func doneKbd() { view.endEditing(true) }

    @objc private func reset() {
        let a = UIAlertController(title: "Reset all data?", message: "Logs, plans, wishes and targets return to defaults.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.prsntr.resetAll()
        })
        present(a, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    @objc private func contact() {
        WebContentHost.presentContact(from: self)
    }

    private func caption(_ title: String, above field: UITextField?) {
        guard let field, let stack = field.superview as? UIStackView,
              let idx = stack.arrangedSubviews.firstIndex(of: field) else { return }
        if stack.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == title }) { return }
        let label = UILabel()
        label.text = title
        label.font = PulseType.font(.caption)
        label.textColor = PulseHue.ink(hi)
        label.adjustsFontForContentSizeCategory = true
        stack.insertArrangedSubview(label, at: idx)
    }

    private func paintField(_ f: UITextField?, _ hi: Bool) {
        f?.font = PulseType.font(.body)
        f?.textColor = PulseHue.ink(hi)
        f?.backgroundColor = PulseHue.surface(hi)
        f?.adjustsFontForContentSizeCategory = true
        f?.layer.borderWidth = hi ? 2 : 1
        f?.layer.borderColor = PulseHue.stroke(hi).cgColor
    }

}
