// Why: "How deletion works" is one honest paragraph, shown as its three ideas with an icon each so it can be
// scanned. The words are the paragraph's own, in order; a test holds them to it, so splitting it up can never
// quietly change what Roomy promises.
import Foundation

nonisolated struct DeletionPoint: Equatable, Identifiable {
    let systemImage: String
    let text: String

    var id: String { systemImage }

    static let all = [
        DeletionPoint(
            systemImage: "trash",
            text: "Nothing is deleted without your approval. Photos and videos move to Recently Deleted and stay "
                + "there for 30 days; space is reclaimed only when you empty it."),
        DeletionPoint(
            systemImage: "person.2.fill",
            text: "Duplicate contact cards are merged into one, and every original card is backed up first."),
        DeletionPoint(
            systemImage: "info.circle",
            text: "Apps can't read notes, so notes on removed cards are not kept."),
    ]
}
