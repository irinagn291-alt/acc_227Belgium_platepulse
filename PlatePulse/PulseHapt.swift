import UIKit

/// Commit-only haptic. Never used for navigation.
enum PulseHapt {
    @MainActor
    static func commit() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
