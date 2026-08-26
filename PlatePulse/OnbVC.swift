import UIKit

/// Passive onboarding view.
@MainActor
final class OnbVC: UIViewController, OnbView, UITextFieldDelegate, UIScrollViewDelegate {
    var prsntr: OnbPrsntr!
    private var kbd: [NSObjectProtocol] = []

    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var artImg: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var bodyLbl: UILabel!
    @IBOutlet private weak var pageCtrl: UIPageControl!
    @IBOutlet private weak var nextBtn: UIButton!
    @IBOutlet private weak var skipBtn: UIButton!
    @IBOutlet private weak var tgtBox: UIView!
    @IBOutlet private weak var kcalField: UITextField!
    @IBOutlet private weak var protField: UITextField!
    @IBOutlet private weak var carbField: UITextField!
    @IBOutlet private weak var fatField: UITextField!

    init() { super.init(nibName: "OnbVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        pageCtrl.numberOfPages = 4
        pageCtrl.isUserInteractionEnabled = false
        pageCtrl.accessibilityLabel = "Onboarding pages"
        nextBtn.addTarget(self, action: #selector(nextTap), for: .touchUpInside)
        skipBtn.addTarget(self, action: #selector(skipTap), for: .touchUpInside)
        skipBtn.accessibilityLabel = "Skip and use default targets"
        nextBtn.accessibilityLabel = "Continue onboarding"
        artImg.isAccessibilityElement = false
        [kcalField, protField, carbField, fatField].forEach { f in
            f?.delegate = self
            f?.addTarget(self, action: #selector(changed), for: .editingChanged)
            if let f { PulseKbd.dock(f, target: self, done: #selector(doneKbd)) }
        }
        kcalField.accessibilityLabel = "Energy target"
        protField.accessibilityLabel = "Protein target"
        carbField.accessibilityLabel = "Carbohydrate target"
        fatField.accessibilityLabel = "Fat target"
        kbd = PulseKbd.watch(scroll, owner: self)
        scroll.delegate = self
        _ = PulseKbd.dismissTap(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: OnbVM) {
        view.backgroundColor = PulseHue.bg(vm.hi)
        artImg.image = UIImage(named: vm.art)
        titleLbl.do { $0.text = vm.title; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        bodyLbl.do { $0.text = vm.body; $0.font = PulseType.font(.body); $0.textColor = PulseHue.muted(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        pageCtrl.currentPage = vm.page
        pageCtrl.pageIndicatorTintColor = PulseHue.muted(vm.hi)
        pageCtrl.currentPageIndicatorTintColor = PulseHue.accent(vm.hi)
        nextBtn.setTitle(vm.next, for: .normal)
        skipBtn.setTitle("Skip", for: .normal)
        tgtBox.isHidden = !vm.showTgt
        kcalField.text = vm.kcal
        protField.text = vm.prot
        carbField.text = vm.carb
        fatField.text = vm.fat
        [kcalField, protField, carbField, fatField].forEach {
            $0?.font = PulseType.font(.body)
            $0?.textColor = PulseHue.ink(vm.hi)
            $0?.backgroundColor = PulseHue.surface(vm.hi)
            $0?.adjustsFontForContentSizeCategory = true
        }
        paintBtn(nextBtn, vm.hi)
        skipBtn.titleLabel?.font = PulseType.font(.label)
        skipBtn.setTitleColor(PulseHue.muted(vm.hi), for: .normal)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        !string.contains("-")
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { view.endEditing(true) }

    @objc private func nextTap() { prsntr.next() }
    @objc private func skipTap() { prsntr.skip() }
    @objc private func doneKbd() { view.endEditing(true) }
    @objc private func changed() {
        prsntr.edit(kcal: kcalField.text, prot: protField.text, carb: carbField.text, fat: fatField.text)
    }

    private func paintBtn(_ btn: UIButton, _ hi: Bool) {
        btn.titleLabel?.font = PulseType.font(.label, bold: true)
        btn.titleLabel?.adjustsFontForContentSizeCategory = true
        btn.setTitleColor(PulseHue.ink(hi), for: .normal)
        btn.backgroundColor = PulseHue.surface(hi)
        btn.layer.borderWidth = 2
        btn.layer.borderColor = PulseHue.accent(hi).cgColor
    }
}
