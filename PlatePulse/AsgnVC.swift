import UIKit

/// Passive assign view.
@MainActor
final class AsgnVC: UIViewController, AsgnView {
    var prsntr: AsgnPrsntr!

    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var dawnBtn: UIButton!
    @IBOutlet private weak var noonBtn: UIButton!
    @IBOutlet private weak var duskBtn: UIButton!
    @IBOutlet private weak var intBtn: UIButton!
    @IBOutlet private weak var eatenBtn: UIButton!
    @IBOutlet private weak var planBtn: UIButton!
    @IBOutlet private weak var datePick: UIDatePicker!
    @IBOutlet private weak var confirmBtn: UIButton!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var noteLbl: UILabel!
    @IBOutlet private weak var formBox: UIView!

    init() { super.init(nibName: "AsgnVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        dawnBtn.addTarget(self, action: #selector(dawn), for: .touchUpInside)
        noonBtn.addTarget(self, action: #selector(noon), for: .touchUpInside)
        duskBtn.addTarget(self, action: #selector(dusk), for: .touchUpInside)
        intBtn.addTarget(self, action: #selector(interval), for: .touchUpInside)
        eatenBtn.addTarget(self, action: #selector(eaten), for: .touchUpInside)
        planBtn.addTarget(self, action: #selector(plan), for: .touchUpInside)
        confirmBtn.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        datePick.addTarget(self, action: #selector(date), for: .valueChanged)
        datePick.datePickerMode = .date
        datePick.preferredDatePickerStyle = .compact
        datePick.minimumDate = Date()
        dawnBtn.accessibilityLabel = "Dawn Reading"
        noonBtn.accessibilityLabel = "Noon Reading"
        duskBtn.accessibilityLabel = "Dusk Reading"
        intBtn.accessibilityLabel = "Interval"
        eatenBtn.accessibilityLabel = "Eaten today"
        planBtn.accessibilityLabel = "Plan ahead"
        datePick.accessibilityLabel = "Reading date"
        confirmBtn.accessibilityLabel = "Confirm assignment"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: AsgnVM) {
        view.backgroundColor = PulseHue.bg(vm.hi)
        emptyBox.isHidden = !vm.empty
        formBox.isHidden = vm.empty
        emptyTitle.text = vm.emptyTitle
        emptyTitle.font = PulseType.font(.label, bold: true)
        emptyTitle.textColor = PulseHue.ink(vm.hi)
        emptyTitle.numberOfLines = 0
        titleLbl.text = "Assign reading"
        titleLbl.font = PulseType.font(.title, bold: true)
        titleLbl.textColor = PulseHue.ink(vm.hi)
        titleLbl.adjustsFontForContentSizeCategory = true
        noteLbl.text = vm.note
        noteLbl.font = PulseType.font(.caption)
        noteLbl.textColor = PulseHue.accent(vm.hi)
        noteLbl.numberOfLines = 0
        noteLbl.isHidden = vm.note.isEmpty
        confirmBtn.setTitle(vm.confirm, for: .normal)
        confirmBtn.isEnabled = !vm.busy && !vm.empty
        datePick.date = vm.day.date()
        datePick.isEnabled = !vm.eaten
        intBtn.isEnabled = !vm.intervalOff
        mark(dawnBtn, "Dawn Reading", on: vm.slot == .dawn, hi: vm.hi)
        mark(noonBtn, "Noon Reading", on: vm.slot == .noon, hi: vm.hi)
        mark(duskBtn, "Dusk Reading", on: vm.slot == .dusk, hi: vm.hi)
        mark(intBtn, "Interval", on: vm.slot == .interval, hi: vm.hi)
        mark(eatenBtn, "Eaten today", on: vm.eaten, hi: vm.hi)
        mark(planBtn, "Plan ahead", on: !vm.eaten, hi: vm.hi)
        paintBtn(confirmBtn, vm.hi)
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
    }

    @objc private func dawn() { prsntr.pick(.dawn) }
    @objc private func noon() { prsntr.pick(.noon) }
    @objc private func dusk() { prsntr.pick(.dusk) }
    @objc private func interval() { prsntr.pick(.interval) }
    @objc private func eaten() { prsntr.setEaten(true) }
    @objc private func plan() { prsntr.setEaten(false) }
    @objc private func date() { prsntr.setDay(datePick.date) }
    @objc private func confirm() { prsntr.confirm() }

    private func mark(_ btn: UIButton, _ title: String, on: Bool, hi: Bool) {
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = PulseType.font(.label, bold: true)
        btn.titleLabel?.adjustsFontForContentSizeCategory = true
        btn.titleLabel?.numberOfLines = 2
        btn.titleLabel?.textAlignment = .center
        btn.setTitleColor(PulseHue.ink(hi), for: .normal)
        btn.backgroundColor = on ? PulseHue.accent(hi).withAlphaComponent(0.35) : PulseHue.surface(hi)
        btn.layer.borderWidth = on || hi ? 2 : 1
        btn.layer.borderColor = PulseHue.accent(hi).cgColor
        btn.accessibilityValue = on ? "Selected" : "Not selected"
    }

    private func paintBtn(_ btn: UIButton, _ hi: Bool) {
        btn.titleLabel?.font = PulseType.font(.label, bold: true)
        btn.titleLabel?.adjustsFontForContentSizeCategory = true
        btn.setTitleColor(PulseHue.ink(hi), for: .normal)
        btn.backgroundColor = PulseHue.surface(hi)
        btn.layer.borderWidth = hi ? 2 : 1
        btn.layer.borderColor = PulseHue.accent(hi).cgColor
    }
}
