import UIKit

/// Passive product detail view.
@MainActor
final class DtlVC: UIViewController, DtlView, UITextFieldDelegate, UIScrollViewDelegate {
    var prsntr: DtlPrsntr!
    var imgs: ImgLoad?
    private var kbd: [NSObjectProtocol] = []
    private var hi = false

    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var backImg: UIImageView!
    @IBOutlet private weak var thumb: UIImageView!
    @IBOutlet private weak var nameLbl: UILabel!
    @IBOutlet private weak var brandLbl: UILabel!
    @IBOutlet private weak var kcalLbl: UILabel!
    @IBOutlet private weak var protLbl: UILabel!
    @IBOutlet private weak var carbLbl: UILabel!
    @IBOutlet private weak var fatLbl: UILabel!
    @IBOutlet private weak var gramField: UITextField!
    @IBOutlet private weak var totKcal: UILabel!
    @IBOutlet private weak var totProt: UILabel!
    @IBOutlet private weak var totCarb: UILabel!
    @IBOutlet private weak var totFat: UILabel!
    @IBOutlet private weak var asgnBtn: UIButton!
    @IBOutlet private weak var wishBtn: UIButton!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var missLbl: UILabel!
    @IBOutlet private weak var formBox: UIView!

    init() { super.init(nibName: "DtlVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        backImg.image = UIImage(named: "plp_CardBackdrop")
        backImg.isAccessibilityElement = false
        thumb.isAccessibilityElement = false
        gramField.delegate = self
        gramField.addTarget(self, action: #selector(grams), for: .editingChanged)
        PulseKbd.dock(gramField, target: self, done: #selector(doneKbd))
        gramField.accessibilityLabel = "Portion in grams"
        asgnBtn.addTarget(self, action: #selector(asgn), for: .touchUpInside)
        wishBtn.addTarget(self, action: #selector(wish), for: .touchUpInside)
        asgnBtn.accessibilityLabel = "Assign this reading"
        kbd = PulseKbd.watch(scroll, owner: self)
        scroll.delegate = self
        _ = PulseKbd.dismissTap(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: DtlVM) {
        hi = vm.hi
        view.backgroundColor = PulseHue.bg(vm.hi)
        emptyBox.isHidden = !vm.empty
        formBox.isHidden = vm.empty
        emptyTitle.text = vm.emptyTitle
        emptyTitle.font = PulseType.font(.label, bold: true)
        emptyTitle.textColor = PulseHue.ink(vm.hi)
        emptyTitle.numberOfLines = 0
        emptyTitle.adjustsFontForContentSizeCategory = true
        nameLbl.do { $0.text = vm.name; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 2; $0.lineBreakMode = .byTruncatingTail }
        brandLbl.do { $0.text = vm.brand; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.muted(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        [kcalLbl, protLbl, carbLbl, fatLbl].enumerated().forEach { i, l in
            let t = [vm.kcal100, vm.prot100, vm.carb100, vm.fat100][i]
            l?.do { $0.text = t; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        }
        totKcal.do { $0.text = vm.totKcal; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.accent(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        totProt.do { $0.text = vm.totProt; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        totCarb.do { $0.text = vm.totCarb; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        totFat.do { $0.text = vm.totFat; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        if gramField.text != vm.grams { gramField.text = vm.grams }
        gramField.font = PulseType.font(.body)
        gramField.textColor = PulseHue.ink(vm.hi)
        gramField.backgroundColor = PulseHue.surface(vm.hi)
        missLbl.isHidden = !vm.missingEnergy
        missLbl.text = "Energy for this pack is unknown. You can still log the grams."
        missLbl.font = PulseType.font(.caption)
        missLbl.textColor = PulseHue.accent(vm.hi)
        missLbl.numberOfLines = 0
        asgnBtn.setTitle("Assign slot", for: .normal)
        asgnBtn.isEnabled = vm.canAssign
        wishBtn.setTitle(vm.wishTitle, for: .normal)
        wishBtn.isEnabled = vm.wishOn
        wishBtn.accessibilityLabel = vm.wishTitle
        paintBtn(asgnBtn, vm.hi)
        paintBtn(wishBtn, vm.hi)
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
        Task { [weak self] in
            let img = await (self?.imgs ?? ImgLoad()).thumb(url: vm.imgURL, shelf: vm.shelfImg)
            self?.thumb.image = img
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        !string.contains("-")
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { view.endEditing(true) }

    @objc private func grams() { prsntr.grams(gramField.text ?? "") }
    @objc private func asgn() { prsntr.assign() }
    @objc private func wish() { prsntr.wish() }
    @objc private func doneKbd() { view.endEditing(true) }

    private func paintBtn(_ btn: UIButton, _ hi: Bool) {
        btn.titleLabel?.font = PulseType.font(.label, bold: true)
        btn.titleLabel?.adjustsFontForContentSizeCategory = true
        btn.setTitleColor(PulseHue.ink(hi), for: .normal)
        btn.backgroundColor = PulseHue.surface(hi)
        btn.layer.borderWidth = hi ? 2 : 1
        btn.layer.borderColor = PulseHue.accent(hi).cgColor
    }
}
