import UIKit

/// Passive Today view. Forwards taps; presenter pushes formatted strings.
@MainActor
final class DayVC: UIViewController, DayView, UITableViewDataSource, UITableViewDelegate {
    var prsntr: DayPrsntr!
    private var vm = DayVM(
        title: "", energy: "", energySub: "", prot: "", carb: "", fat: "",
        kcalFrac: 0, protFrac: 0, carbFrac: 0, fatFrac: 0, slots: [],
        empty: true, exceeded: false, hi: false, a11yHint: "",
        emptyTitle: "", emptyBody: ""
    )
    private var lastEnergy = ""

    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var texImg: UIImageView!
    @IBOutlet private weak var headImg: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var energyLbl: UILabel!
    @IBOutlet private weak var energySubLbl: UILabel!
    @IBOutlet private weak var kcalBar: PulseBar!
    @IBOutlet private weak var protImg: UIImageView!
    @IBOutlet private weak var protLbl: UILabel!
    @IBOutlet private weak var protBar: PulseBar!
    @IBOutlet private weak var carbImg: UIImageView!
    @IBOutlet private weak var carbLbl: UILabel!
    @IBOutlet private weak var carbBar: PulseBar!
    @IBOutlet private weak var fatImg: UIImageView!
    @IBOutlet private weak var fatLbl: UILabel!
    @IBOutlet private weak var fatBar: PulseBar!
    @IBOutlet private weak var table: UITableView!
    @IBOutlet private weak var tableH: NSLayoutConstraint!
    @IBOutlet private weak var srchBtn: UIButton!
    @IBOutlet private weak var scanBtn: UIButton!
    @IBOutlet private weak var wishBtn: UIButton!
    @IBOutlet private weak var a11yBtn: UIButton!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyImg: UIImageView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var emptyBody: UILabel!

    init() { super.init(nibName: "DayVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UINib(nibName: "SlotCell", bundle: nil), forCellReuseIdentifier: SlotCell.reuse)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        table.isScrollEnabled = false
        texImg.image = UIImage(named: "plp_Texture")
        texImg.alpha = 0.18
        texImg.isAccessibilityElement = false
        headImg.image = UIImage(named: "plp_HeaderDecor")
        headImg.isAccessibilityElement = false
        emptyImg.image = UIImage(named: "plp_EmptyLog")
        emptyImg.isAccessibilityElement = false
        protImg.image = UIImage(named: "plp_MacroProtein")
        carbImg.image = UIImage(named: "plp_MacroCarbs")
        fatImg.image = UIImage(named: "plp_MacroFat")
        [protImg, carbImg, fatImg].forEach { $0?.isAccessibilityElement = false }
        wire(srchBtn, "Search products", "Opens the searchable catalog", #selector(srch))
        wire(scanBtn, "Scan barcode", "Opens the live barcode reader", #selector(scan))
        wire(wishBtn, "Wish shelf", "Opens saved products", #selector(wish))
        wire(a11yBtn, "Access Mode", "Opens high contrast and accessibility controls", #selector(a11y))
        a11yBtn.setImage(nil, for: .normal)
        energyLbl.adjustsFontForContentSizeCategory = true
        energyLbl.accessibilityTraits = [.header, .updatesFrequently]
        titleLbl.adjustsFontForContentSizeCategory = true
        kcalBar.accessibilityLabel = "Energy progress"
        protBar.accessibilityLabel = "Protein progress"
        carbBar.accessibilityLabel = "Carbohydrate progress"
        fatBar.accessibilityLabel = "Fat progress"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: DayVM) {
        self.vm = vm
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do {
            $0.text = vm.title
            $0.font = PulseType.font(.title, bold: true)
            $0.textColor = PulseHue.ink(vm.hi)
            $0.adjustsFontForContentSizeCategory = true
        }
        energyLbl.font = PulseType.font(.hero, bold: true)
        energyLbl.textColor = PulseHue.accent(vm.hi)
        energySubLbl.do {
            $0.text = vm.energySub
            $0.font = PulseType.font(.caption)
            $0.textColor = PulseHue.muted(vm.hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        if lastEnergy != vm.energy {
            if lastEnergy.isEmpty || UIAccessibility.isReduceMotionEnabled {
                energyLbl.text = vm.energy
            } else {
                PulseAnim.run { [weak self] in self?.energyLbl.text = vm.energy }
            }
            lastEnergy = vm.energy
        }
        energyLbl.accessibilityLabel = "Energy \(vm.energy) kilocalories \(vm.energySub)"
        protLbl.do { paint($0, vm.prot, vm.hi) }
        carbLbl.do { paint($0, vm.carb, vm.hi) }
        fatLbl.do { paint($0, vm.fat, vm.hi) }
        kcalBar.hi = vm.hi
        protBar.hi = vm.hi
        carbBar.hi = vm.hi
        fatBar.hi = vm.hi
        kcalBar.frac = vm.kcalFrac
        protBar.frac = vm.protFrac
        carbBar.frac = vm.carbFrac
        fatBar.frac = vm.fatFrac
        emptyBox.isHidden = !vm.empty
        emptyTitle.do { paint($0, vm.emptyTitle, vm.hi, .label, true) }
        emptyBody.do { paint($0, vm.emptyBody, vm.hi, .caption, false) }
        a11yBtn.accessibilityValue = vm.a11yHint
        paintBtn(srchBtn, "Search", vm.hi)
        paintBtn(scanBtn, "Scan", vm.hi)
        paintBtn(wishBtn, "Wish", vm.hi)
        paintBtn(a11yBtn, "Access", vm.hi)
        table.reloadData()
        table.layoutIfNeeded()
        tableH.constant = max(table.contentSize.height, 44)
        table.backgroundColor = .clear
        table.separatorColor = PulseHue.muted(vm.hi).withAlphaComponent(0.3)
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
        emptyBox.layer.borderWidth = vm.hi ? 2 : 0
        emptyBox.layer.borderColor = PulseHue.stroke(vm.hi).cgColor
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { vm.slots.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SlotCell.reuse, for: indexPath) as? SlotCell ?? SlotCell()
        if let row = vm.slots[safe: indexPath.row] {
            cell.apply(row, hi: vm.hi)
        }
        return cell
    }

    @objc private func srch() { prsntr.tapSrch() }
    @objc private func scan() { prsntr.tapScan() }
    @objc private func wish() { prsntr.tapWish() }
    @objc private func a11y() { prsntr.tapA11y() }

    private func wire(_ btn: UIButton, _ label: String, _ hint: String, _ sel: Selector) {
        btn.addTarget(self, action: sel, for: .touchUpInside)
        btn.accessibilityLabel = label
        btn.accessibilityHint = hint
        btn.accessibilityTraits = .button
    }

    private func paint(_ lbl: UILabel, _ text: String, _ hi: Bool, _ step: PulseType.Step = .caption, _ bold: Bool = false) {
        lbl.text = text
        lbl.font = PulseType.font(step, bold: bold)
        lbl.textColor = PulseHue.ink(hi)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.numberOfLines = 0
    }

    private func paintBtn(_ btn: UIButton, _ title: String, _ hi: Bool) {
        PulseBtn.paint(btn, title: title, hi: hi)
    }
}
