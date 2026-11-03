import UIKit

@MainActor
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func pop() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// Something went a little wrong, like the crow hopping closer.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
