import UIKit

/// Passive wish-list view.
@MainActor
final class WishVC: UIViewController, WishView, UITableViewDataSource, UITableViewDelegate {
    var prsntr: WishPrsntr!
    var imgs: ImgLoad?
    private var vm = WishVM(title: "", rows: [], empty: true, emptyTitle: "", emptyBody: "", hi: false)

    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var closeBtn: UIButton!
    @IBOutlet private weak var table: UITableView!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyImg: UIImageView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var emptyBody: UILabel!
    @IBOutlet private weak var emptyBtn: UIButton!

    init() { super.init(nibName: "WishVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UINib(nibName: "WishCell", bundle: nil), forCellReuseIdentifier: WishCell.reuse)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 76
        emptyBtn.addTarget(self, action: #selector(emptyTap), for: .touchUpInside)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.accessibilityLabel = "Close wish shelf"
        emptyImg.image = UIImage(named: "plp_EmptyWish")
        emptyImg.isAccessibilityElement = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: WishVM) {
        self.vm = vm
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do { $0.text = vm.title; $0.font = PulseType.font(.title, bold: true); $0.textColor = PulseHue.ink(vm.hi); $0.adjustsFontForContentSizeCategory = true }
        emptyBox.isHidden = !vm.empty
        table.isHidden = vm.empty
        emptyTitle.text = vm.emptyTitle
        emptyBody.text = vm.emptyBody
        emptyTitle.font = PulseType.font(.label, bold: true)
        emptyBody.font = PulseType.font(.body)
        emptyTitle.textColor = PulseHue.ink(vm.hi)
        emptyBody.textColor = PulseHue.muted(vm.hi)
        emptyTitle.numberOfLines = 0
        emptyBody.numberOfLines = 0
        emptyBtn.setTitle("Find a pack", for: .normal)
        emptyBtn.titleLabel?.font = PulseType.font(.label, bold: true)
        emptyBtn.setTitleColor(PulseHue.ink(vm.hi), for: .normal)
        emptyBtn.backgroundColor = PulseHue.surface(vm.hi)
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
        closeBtn.tintColor = PulseHue.ink(vm.hi)
        table.backgroundColor = .clear
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { vm.rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WishCell.reuse, for: indexPath) as? WishCell ?? WishCell()
        if let row = vm.rows[safe: indexPath.row] {
            cell.apply(row, hi: vm.hi) { [weak self] in self?.prsntr.promote(row.id) }
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
            self?.prsntr.drop(row.id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [act])
    }

    @objc private func emptyTap() { prsntr.tapEmpty() }
    @objc private func close() { prsntr.close() }
}
