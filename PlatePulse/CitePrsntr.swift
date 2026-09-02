import Foundation

struct CiteRowVM: Sendable {
    var id: String
    var title: String
    var body: String
    var href: String
}

struct CiteVM: Sendable {
    var title: String
    var body: String
    var rows: [CiteRowVM]
    var hi: Bool
}

@MainActor
protocol CiteView: AnyObject {
    func render(_ vm: CiteVM)
}

/// Pushes citation copy; taps open the official source URL.
@MainActor
final class CitePrsntr {
    weak var view: CiteView?
    weak var coord: CiteCoord?
    private let store: PulseMgr

    init(store: PulseMgr) {
        self.store = store
    }

    func reload() {
        Task { await push() }
    }

    func open(_ id: String) {
        guard let href = CiteSrc.href(id: id) else { return }
        coord?.open(href)
    }

    func close() {
        coord?.close()
    }

    private func push() async {
        let hi = await store.prefs().hiContrast
        view?.render(CiteVM(
            title: "Sources",
            body: "PlatePulse is a personal food log. It is not medical advice. Product figures and starting daily targets come from the citations below. Tap a row to open the source.",
            rows: CiteSrc.allCases.map {
                CiteRowVM(id: $0.rawValue, title: $0.title, body: $0.body, href: $0.href)
            },
            hi: hi
        ))
    }
}
