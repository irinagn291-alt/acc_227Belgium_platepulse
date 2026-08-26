import UIKit

/// Parent/child navigation node with didFinish callbacks.
@MainActor
protocol Coord: AnyObject {
    var parent: Coord? { get set }
    var kids: [any Coord] { get set }
    var didFinish: (() -> Void)? { get set }
    func start()
}

extension Coord {
    func addKid(_ kid: any Coord) {
        kid.parent = self
        kids.append(kid)
    }

    func dropKid(_ kid: any Coord) {
        kids.removeAll { $0 === kid }
        kid.didFinish = nil
    }
}

enum FlowPage: Int, CaseIterable, Sendable {
    case srch, scan, dtl, asgn
}
