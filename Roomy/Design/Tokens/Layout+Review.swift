// Why: Review, the cleanup progress and the result (Figma "v5 — Sheets & delete flow") have sizes of their own.
// They live beside the shared tokens, in their own file, so the screens use names instead of numbers and the
// shared token files stay untouched by this flow.
import SwiftUI

extension Layout {
    /// A row's thumbnail or contact avatar in Review (Figma "ReviewRow v5").
    static let reviewThumbnail: CGFloat = 44
    /// The category icon square before a Review section's title, and the icon square on a result note.
    static let sectionIcon: CGFloat = 28
    /// A step's indicator circle while cleaning up (Figma "CleanupStep v5").
    static let stepIndicator: CGFloat = 28
    /// The numbered circle on a "Finish in Photos" step.
    static let stepNumber: CGFloat = 24
}

extension Radius {
    /// The small category or note icon square, so it reads as a chip beside the text.
    static let iconSquare: CGFloat = 8
}

extension MascotSize {
    /// Roomy on the compact total card at the medium detent, beside the one-line total.
    static let compactTotal: CGFloat = 34
    /// Roomy above the steps while a cleanup runs.
    static let progress: CGFloat = 84
}
