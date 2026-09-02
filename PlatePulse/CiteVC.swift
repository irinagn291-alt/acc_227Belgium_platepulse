import UIKit

/// Passive sources view. Each row opens the cited URL.
@MainActor
final class CiteVC: UIViewController, CiteView, UITableViewDataSource, UITableViewDelegate {
    var prsntr: CitePrsntr!
    private var vm = CiteVM(title: "", body: "", rows: [], hi: false)

    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var bodyLbl: UILabel!
    @IBOutlet private weak var closeBtn: UIButton!
    @IBOutlet private weak var table: UITableView!

    init() { super.init(nibName: "CiteVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UINib(nibName: "CiteCell", bundle: nil), forCellReuseIdentifier: CiteCell.reuse)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 120
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.accessibilityLabel = "Close sources"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: CiteVM) {
        self.vm = vm
        view.backgroundColor = PulseHue.bg(vm.hi)
        titleLbl.do {
            $0.text = vm.title
            $0.font = PulseType.font(.title, bold: true)
            $0.textColor = PulseHue.ink(vm.hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        bodyLbl.do {
            $0.text = vm.body
            $0.font = PulseType.font(.body)
            $0.textColor = PulseHue.muted(vm.hi)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        closeBtn.tintColor = PulseHue.ink(vm.hi)
        table.backgroundColor = .clear
        table.separatorColor = PulseHue.muted(vm.hi).withAlphaComponent(0.3)
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { vm.rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CiteCell.reuse, for: indexPath) as? CiteCell ?? CiteCell()
        if let row = vm.rows[safe: indexPath.row] {
            cell.apply(row, hi: vm.hi)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let row = vm.rows[safe: indexPath.row] else { return }
        prsntr.open(row.id)
    }

    @objc private func close() { prsntr.close() }
}
