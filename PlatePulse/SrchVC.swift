import UIKit

/// Passive search view.
@MainActor
final class SrchVC: UIViewController, SrchView, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    var prsntr: SrchPrsntr!
    var imgs: ImgLoad?
    private var vm = SrchVM(state: .idle, rows: [], note: "", hi: false)

    @IBOutlet private weak var field: UITextField!
    @IBOutlet private weak var table: UITableView!
    @IBOutlet private weak var spin: UIActivityIndicatorView!
    @IBOutlet private weak var emptyBox: UIView!
    @IBOutlet private weak var emptyImg: UIImageView!
    @IBOutlet private weak var emptyTitle: UILabel!
    @IBOutlet private weak var emptyBody: UILabel!
    @IBOutlet private weak var emptyBtn: UIButton!
    @IBOutlet private weak var errBox: UIView!
    @IBOutlet private weak var errLbl: UILabel!
    @IBOutlet private weak var retryBtn: UIButton!
    @IBOutlet private weak var idleLbl: UILabel!

    init() { super.init(nibName: "SrchVC", bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(UINib(nibName: "SrchCell", bundle: nil), forCellReuseIdentifier: SrchCell.reuse)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 76
        field.delegate = self
        field.addTarget(self, action: #selector(typed), for: .editingChanged)
        field.placeholder = "Search a pack"
        field.accessibilityLabel = "Search products"
        field.accessibilityHint = "Results update after a short pause"
        field.adjustsFontForContentSizeCategory = true
        emptyImg.image = UIImage(named: "plp_EmptySearch")
        emptyImg.isAccessibilityElement = false
        emptyBtn.addTarget(self, action: #selector(toScan), for: .touchUpInside)
        retryBtn.addTarget(self, action: #selector(retry), for: .touchUpInside)
        spin.hidesWhenStopped = true
        _ = PulseKbd.dismissTap(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prsntr.reload()
    }

    func render(_ vm: SrchVM) {
        self.vm = vm
        view.backgroundColor = PulseHue.bg(vm.hi)
        field.font = PulseType.font(.body)
        field.textColor = PulseHue.ink(vm.hi)
        field.backgroundColor = PulseHue.surface(vm.hi)
        idleLbl.font = PulseType.font(.body)
        idleLbl.textColor = PulseHue.muted(vm.hi)
        idleLbl.numberOfLines = 0
        idleLbl.text = vm.note
        emptyTitle.font = PulseType.font(.label, bold: true)
        emptyTitle.textColor = PulseHue.ink(vm.hi)
        emptyTitle.numberOfLines = 0
        emptyBody.font = PulseType.font(.body)
        emptyBody.textColor = PulseHue.muted(vm.hi)
        emptyBody.numberOfLines = 0
        errLbl.font = PulseType.font(.body)
        errLbl.textColor = PulseHue.ink(vm.hi)
        errLbl.numberOfLines = 0
        emptyBtn.setTitle("Open Scan", for: .normal)
        retryBtn.setTitle("Retry search", for: .normal)
        [emptyBtn, retryBtn].forEach { b in
            b?.titleLabel?.font = PulseType.font(.label, bold: true)
            b?.setTitleColor(PulseHue.ink(vm.hi), for: .normal)
            b?.backgroundColor = PulseHue.surface(vm.hi)
        }
        emptyBox.backgroundColor = PulseHue.surface(vm.hi)
        errBox.backgroundColor = PulseHue.surface(vm.hi)
        table.backgroundColor = .clear
        switch vm.state {
        case .idle:
            spin.stopAnimating()
            table.isHidden = true
            emptyBox.isHidden = true
            errBox.isHidden = true
            idleLbl.isHidden = false
        case .load:
            spin.startAnimating()
            table.isHidden = true
            emptyBox.isHidden = true
            errBox.isHidden = true
            idleLbl.isHidden = true
        case .rows:
            spin.stopAnimating()
            table.isHidden = false
            emptyBox.isHidden = true
            errBox.isHidden = true
            idleLbl.isHidden = vm.note.isEmpty
        case .empty:
            spin.stopAnimating()
            table.isHidden = true
            emptyBox.isHidden = false
            errBox.isHidden = true
            idleLbl.isHidden = true
            emptyTitle.text = "No pack matched"
            emptyBody.text = vm.note
        case .err:
            spin.stopAnimating()
            table.isHidden = true
            emptyBox.isHidden = true
            errBox.isHidden = false
            idleLbl.isHidden = true
            errLbl.text = vm.note
        }
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { vm.rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SrchCell.reuse, for: indexPath) as? SrchCell ?? SrchCell()
        if let row = vm.rows[safe: indexPath.row] {
            cell.apply(row, hi: vm.hi)
            Task { [weak cell] in
                let img = await (imgs ?? ImgLoad()).thumb(url: row.imgURL, shelf: row.shelfImg)
                cell?.setThumb(img)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let row = vm.rows[safe: indexPath.row] {
            prsntr.pick(row.code)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    @objc private func typed() { prsntr.type(field.text ?? "") }
    @objc private func toScan() { prsntr.coord?.root.go(FlowPage.scan.rawValue) }
    @objc private func retry() { prsntr.type(field.text ?? "") }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
