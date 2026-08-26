import UIKit

/// Modal pager: Search / Scan / Detail / Assign.
@MainActor
final class FlowHostVC: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var pages: [UIViewController] = []
    var titles: [String] = []
    var startAt = 0
    var onClose: (() -> Void)?
    private let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private var idx = 0

    @IBOutlet private weak var closeBtn: UIButton!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var container: UIView!
    @IBOutlet private weak var pageCtrl: UIPageControl!

    init() {
        super.init(nibName: "FlowHostVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PulseHue.bg(false)
        addChild(pager)
        pager.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pager.view)
        NSLayoutConstraint.activate([
            pager.view.topAnchor.constraint(equalTo: container.topAnchor),
            pager.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pager.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pager.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        pager.didMove(toParent: self)
        pager.dataSource = self
        pager.delegate = self
        pageCtrl.numberOfPages = pages.count
        pageCtrl.currentPage = startAt
        pageCtrl.addTarget(self, action: #selector(dot), for: .valueChanged)
        pageCtrl.accessibilityLabel = "Logging steps"
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.accessibilityLabel = "Close logging flow"
        closeBtn.accessibilityHint = "Dismisses Search, Scan, Detail and Assign"
        titleLbl.font = PulseType.font(.title, bold: true)
        titleLbl.adjustsFontForContentSizeCategory = true
        titleLbl.textColor = PulseHue.ink(false)
        idx = startAt
        if let first = pages[safe: startAt] {
            pager.setViewControllers([first], direction: .forward, animated: false)
        }
        syncTitle()
        paint()
    }

    func go(_ i: Int) {
        guard pages.indices.contains(i) else { return }
        let dir: UIPageViewController.NavigationDirection = i >= idx ? .forward : .reverse
        pager.setViewControllers([pages[i]], direction: dir, animated: !UIAccessibility.isReduceMotionEnabled)
        idx = i
        pageCtrl.currentPage = i
        syncTitle()
    }

    @objc private func dot() { go(pageCtrl.currentPage) }
    @objc private func close() { onClose?() }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let i = pages.firstIndex(where: { $0 === viewController }), i > 0 else { return nil }
        return pages[i - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let i = pages.firstIndex(where: { $0 === viewController }), i + 1 < pages.count else { return nil }
        return pages[i + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let cur = pageViewController.viewControllers?.first, let i = pages.firstIndex(where: { $0 === cur }) else { return }
        idx = i
        pageCtrl.currentPage = i
        syncTitle()
    }

    private func syncTitle() {
        titleLbl.text = titles[safe: idx]
    }

    private func paint() {
        pageCtrl.pageIndicatorTintColor = PulseHue.muted(false)
        pageCtrl.currentPageIndicatorTintColor = PulseHue.accent(false)
        closeBtn.tintColor = PulseHue.ink(false)
    }
}
