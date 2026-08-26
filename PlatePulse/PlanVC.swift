import UIKit

/// Passive 14-day plan view.
@MainActor
final class PlanVC: UIViewController, PlanView, UITableViewDataSource, UITableViewDelegate {
    var prsntr: PlanPrsntr!
    var imgs: ImgLoad?
    private var vm = PlanVM(title: "", hint: "", rows: [], empty: true, emptyTitle: "", emptyBody: "", hi: false)

    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var hintLbl: UILabel!
    @IBOutlet private weak var table: UITableView!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyImg: UIImageView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var emptyBody: UILabel!
    @IBOutlet private weak var emptyBtn: UIButton!

    init() { super.init(nibName: "PlanVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UINib(nibName: "PlanCell", bundle: nil), forCellReuseIdentifier: PlanCell.reuse)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 88
        emptyBtn.addTarget(self, action: #selector(emptyTap), for: .touchUpInside)
        emptyImg.image = UIImage(named: "plp_EmptyPlan")
        emptyImg.isAccessibilityElement = false
        emptyBtn.accessibilityLabel = "Plan a reading"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: PlanVM) {
        self.vm = vm
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do { $0.text = vm.title; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        hintLbl.do { $0.text = vm.hint; $0.font = PulseType.font(.caption); $0.textColor = PulseHue.muted(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        emptyBox.isHidden = !vm.empty
        table.isHidden = vm.empty
        emptyTitle.do { $0.text = vm.emptyTitle; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        emptyBody.do { $0.text = vm.emptyBody; $0.font = PulseType.font(.body); $0.textColor = PulseHue.muted(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        emptyBtn.setTitle("Plan a reading", for: .normal)
        emptyBtn.titleLabel?.font = PulseType.font(.label, bold: true)
        emptyBtn.setTitleColor(PulseHue.ink(vm.hi), for: .normal)
        emptyBtn.backgroundColor = PulseHue.surface(vm.hi)
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
        table.backgroundColor = .clear
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { vm.rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlanCell.reuse, for: indexPath) as? PlanCell ?? PlanCell()
        if let row = vm.rows[safe: indexPath.row] {
            cell.apply(row, hi: vm.hi) { [weak self] in self?.prsntr.eat(row.id) }
            Task { [weak cell] in
                let img = await (self.imgs ?? ImgLoad()).thumb(url: row.imgURL, shelf: row.shelfImg)
                cell?.setThumb(img)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let row = vm.rows[safe: indexPath.row] else { return nil }
        let act = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.confirmDrop(row.id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [act])
    }

    @objc private func emptyTap() { prsntr.tapEmpty() }

    private func confirmDrop(_ id: UUID) {
        let a = UIAlertController(title: "Delete this plan row?", message: "The planned reading is removed.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.prsntr.drop(id)
        })
        present(a, animated: !UIAccessibility.isReduceMotionEnabled)
    }
}
