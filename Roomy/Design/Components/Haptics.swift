// Why: a light tap on every selection change and one success tap per completed action — named so the
// intent is clear at each call site.
import UIKit

@MainActor enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
