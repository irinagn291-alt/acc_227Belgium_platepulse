import Foundation

/// Four monitor slots. Interval is eaten-only.
enum SlotKind: String, Codable, Sendable, CaseIterable {
    case dawn
    case noon
    case dusk
    case interval

    var title: String {
        switch self {
        case .dawn: return "Dawn Reading"
        case .noon: return "Noon Reading"
        case .dusk: return "Dusk Reading"
        case .interval: return "Interval"
        }
    }

    var icon: String {
        switch self {
        case .dawn: return "plp_SlotDawnReading"
        case .noon: return "plp_SlotNoonReading"
        case .dusk: return "plp_SlotDuskReading"
        case .interval: return "plp_SlotInterval"
        }
    }

    var canPlan: Bool { self != .interval }

    var sort: Int {
        switch self {
        case .dawn: return 0
        case .noon: return 1
        case .dusk: return 2
        case .interval: return 3
        }
    }
}

/// Pure slot rule. Interval remaps to Dusk (Evening) when planned ahead.
enum SlotRule {
    static func resolve(slot: SlotKind, future: Bool) -> SlotKind {
        if future && slot == .interval { return .dusk }
        return slot
    }
}
