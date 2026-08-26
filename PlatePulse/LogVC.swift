import UIKit

/// Passive eaten-log view.
@MainActor
final class LogVC: UIViewController, LogView, UITableViewDataSource, UITableViewDelegate {
    var prsntr: LogPrsntr!
    var imgs: ImgLoad?
    private var vm = LogVM(title: "", day: "", rows: [], empty: true, emptyTitle: "", emptyBody: "", hi: false)

    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var dayLbl: UILabel!
    @IBOutlet private weak var prevBtn: UIButton!
    @IBOutlet private weak var nextBtn: UIButton!
    @IBOutlet private weak var table: UITableView!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyImg: UIImageView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var emptyBody: UILabel!
    @IBOutlet private weak var emptyBtn: UIButton!

    init() { super.init(nibName: "LogVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UINib(nibName: "LogCell", bundle: nil), forCellReuseIdentifier: LogCell.reuse)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        prevBtn.addTarget(self, action: #selector(prev), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(nextDay), for: .touchUpInside)
        emptyBtn.addTarget(self, action: #selector(emptyTap), for: .touchUpInside)
        prevBtn.accessibilityLabel = "Previous day"
        nextBtn.accessibilityLabel = "Next day"
        prevBtn.widthAnchor.constraint(equalTo: nextBtn.widthAnchor).isActive = true
        emptyImg.image = UIImage(named: "plp_EmptyLog")
        emptyImg.isAccessibilityElement = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: LogVM) {
        self.vm = vm
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do { $0.text = vm.title; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        dayLbl.do { $0.text = vm.day; $0.font = PulseType.font(.label); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        emptyBox.isHidden = !vm.empty
        table.isHidden = vm.empty
        emptyTitle.do { $0.text = vm.emptyTitle; $0.font = PulseType.font(.label, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        emptyBody.do { $0.text = vm.emptyBody; $0.font = PulseType.font(.body); $0.textColor = PulseHue.muted(vm.hi); $0.adjustsFontForContentSizeCategory = true; $0.numberOfLines = 0 }
        emptyBtn.accessibilityLabel = "Search a pack"
        PulseBtn.paint(emptyBtn, title: "Search a pack", hi: vm.hi)
        PulseBtn.paint(prevBtn, title: "Prev", hi: vm.hi)
        PulseBtn.paint(nextBtn, title: "Next", hi: vm.hi)
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
        table.backgroundColor = .clear
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { vm.rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogCell.reuse, for: indexPath) as? LogCell ?? LogCell()
        if let row = vm.rows[safe: indexPath.row] {
            cell.apply(row, hi: vm.hi)
            Task { [weak cell] in
                let img = await (imgs ?? ImgLoad()).thumb(url: row.imgURL, shelf: row.shelfImg)
                cell?.setThumb(img)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let row = vm.rows[safe: indexPath.row], row.canDrop else { return nil }
        let act = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.confirmDrop(row.id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [act])
    }

    @objc private func prev() { prsntr.prev() }
    @objc private func nextDay() { prsntr.next() }
    @objc private func emptyTap() { prsntr.tapEmpty() }

    private func confirmDrop(_ id: UUID) {
        let a = UIAlertController(title: "Delete this reading?", message: "The row is removed from the log.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.prsntr.drop(id)
        })
        present(a, animated: !UIAccessibility.isReduceMotionEnabled)
    }

}
