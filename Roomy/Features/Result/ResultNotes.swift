// Why: a cleanup can leave confirmed items alone: they weren't in the library Roomy can see, they were the last
// photo of their group, or they couldn't run safely when it started. Each case gets one plain sentence, so a
// result never hides what it didn't do and never calls an item "moved" that wasn't.
import Foundation

nonisolated struct ResultNotes: Equatable {
    let report: CleanupReport

    var lines: [ResultLine] {
        [
            unavailable.map { ResultLine(kind: .notFound, text: $0) },
            spared.map { ResultLine(kind: .kept, text: $0) },
        ].compactMap { $0 }
            + [waitingForPhotos, waitingForComparison, waitingForContacts, onlyInICloud].compactMap { $0 }
            .map { ResultLine(kind: .held, text: $0) }
    }

    var isEmpty: Bool { lines.isEmpty }

    private var unavailable: String? {
        Self.sentence(
            report.assets.unavailableIDs.count,
            one: "1 item wasn't in the photos Roomy can see, so it was taken out of Review.",
            many: { "\($0) items weren't in the photos Roomy can see, so they were taken out of Review." })
    }

    private var spared: String? {
        Self.sentence(
            report.assets.sparedIDs.count,
            one: "1 photo was kept and taken out of Review, because it was the last of its similar shots.",
            many: { "\($0) photos were kept and taken out of Review, because each was the last of its similar shots." })
    }

    private var waitingForPhotos: String? {
        Self.sentence(
            report.held.waitingForPhotos,
            one: "Photos access is off, so 1 item wasn't deleted. It's still in Review.",
            many: { "Photos access is off, so \($0) items weren't deleted. They're still in Review." })
    }

    private var waitingForComparison: String? {
        Self.sentence(
            report.held.waitingForComparison,
            one: "1 similar photo wasn't deleted, because Roomy is comparing your photos again. It's still in Review.",
            many: {
                "\($0) similar photos weren't deleted, because Roomy is comparing your photos again. "
                    + "They're still in Review."
            })
    }

    private var waitingForContacts: String? {
        Self.sentence(
            report.held.waitingForContacts,
            one: "1 contact merge didn't run, because Roomy can't find that group in your contacts right now.",
            many: {
                "\($0) contact merges didn't run, because Roomy can't find those groups in your contacts right now."
            })
    }

    private var onlyInICloud: String? {
        Self.sentence(
            report.held.onlyInICloud,
            one: "1 item kept only in iCloud wasn't deleted, because Roomy shows only this iPhone. "
                + "It's still in Review.",
            many: {
                "\($0) items kept only in iCloud weren't deleted, because Roomy shows only this iPhone. "
                    + "They're still in Review."
            })
    }

    /// Nil for nothing; otherwise the singular sentence, or the plural one with the count formatted.
    private static func sentence(_ count: Int, one: String, many: (String) -> String) -> String? {
        switch count {
        case 0: nil
        case 1: one
        default: many(count.formatted())
        }
    }
}
