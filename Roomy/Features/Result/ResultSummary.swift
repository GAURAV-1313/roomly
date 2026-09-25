// Why: the result is where cleaner apps usually overclaim. Every word and mood here follows from what the
// report measured: moved is not freed, declined is not failed, items that weren't there are never "moved",
// anything confirmed but left alone is named with its reason (`ResultNotes`), and a rise in free space appears
// only on a cleanup that moved something, once free space was measured again and rose by about that much —
// never for more than it moved, and never as the cleanup's doing. The words come as a lead and a list of lines,
// so a partial result reads as a list instead of one paragraph.
import Foundation

nonisolated struct ResultSummary: Equatable {
    enum Stage: Equatable {
        /// Free space was measured again and rose by about what was moved; the amount is capped at that.
        case reclaimed(Int64)
        /// Items are in Recently Deleted and still use space.
        case waiting
        /// Only contacts changed; no space was involved.
        case mergedOnly
        /// Nothing changed; `stop` says why.
        case unchanged(AssetRemoval.Stop?)
    }

    let report: CleanupReport
    var reclaimedBytes: Int64? = nil

    var stage: Stage {
        if report.removedBytes > 0, let reclaimedBytes {
            return .reclaimed(min(reclaimedBytes, report.removedBytes))
        }
        if report.removedCount > 0 { return .waiting }
        if report.mergedCount > 0 { return .mergedOnly }
        return .unchanged(report.assets.stop)
    }

    var mood: MascotMood {
        switch stage {
        case .reclaimed: .success
        case .waiting, .mergedOnly: .pleased
        case .unchanged(.declined): .idle
        case .unchanged(.noAccess): .concerned
        case .unchanged(nil) where report.contacts.failedGroupIDs.isEmpty: .concerned
        case .unchanged: .error
        }
    }

    var title: String {
        switch stage {
        case .reclaimed: "Free space went up"
        case .waiting: "Moved \(report.removedCount.counted("item"))"
        case .mergedOnly: "Merged \(report.mergedCount.counted("contact group"))"
        case .unchanged(.declined), .unchanged(.noAccess): "Nothing was deleted"
        case .unchanged(.timedOut): "Photos didn't answer"
        case .unchanged(nil) where report.contacts.unmergedCount == 0: "Nothing changed"
        case .unchanged: "Couldn't finish"
        }
    }

    /// The sentence under the title, in the hero's white card; nil when the title says it all.
    var lead: String? { stageMessage }

    /// Every other sentence, one row each, so a partial result reads as a list: why Photos stopped, what was left
    /// alone and why (`ResultNotes`), then the contacts.
    var lines: [ResultLine] {
        let stop = stopMessage.map { ResultLine(kind: .stopped, text: $0) }
        return [stop].compactMap { $0 } + notes.lines + contactLines
    }

    private var notes: ResultNotes { ResultNotes(report: report) }

    private var stageMessage: String? {
        switch stage {
        case .reclaimed:
            "Measured again just now: at least this much more is free, about what the cleanup moved to "
                + "Recently Deleted."
        case .waiting where report.removedBytes > 0:
            "They're in Recently Deleted and still use \(report.removedBytes.byteString) for 30 days. "
                + "Empty Recently Deleted in Photos to get the space back now."
        case .waiting:
            "They're in Recently Deleted and still use space for 30 days. "
                + "Empty Recently Deleted in Photos to get the space back now."
        case .unchanged(nil) where report.contacts.unmergedCount == 0 && notes.isEmpty:
            "The selected items were no longer there, so nothing needed changing."
        case .mergedOnly, .unchanged:
            nil
        }
    }

    /// Said whenever Photos stopped early, even if contacts were merged, so a partial result never looks whole.
    private var stopMessage: String? {
        switch report.assets.stop {
        case .declined: "You chose Don't Allow for the photos, so they're still in Review."
        case .timedOut:
            "Photos didn't answer. If you approved, the items are in Recently Deleted and Roomy will "
                + "catch up on the next scan."
        case .failed(let reason): "Photos said: \(reason) The photos are still in Review."
        case .noAccess: "Photos access is off, so no photos or videos were deleted. They're still in Review."
        case nil: nil
        }
    }

    /// Every group that was not merged is accounted for, with the reason, next to the ones that were.
    private var contactLines: [ResultLine] {
        let contacts = report.contacts
        var lines: [ResultLine] = []
        if report.mergedCount > 0 {
            lines.append(
                ResultLine(
                    kind: .merged,
                    text: "Each merged group is now one card. The original cards are backed up in Settings."))
        }
        if !contacts.changedGroupIDs.isEmpty {
            lines.append(
                ResultLine(
                    kind: .contactsLeft,
                    text: "Cards in \(contacts.changedGroupIDs.count.counted("contact group")) changed after the scan, "
                        + "so they were left as they are and Roomy is checking them again."))
        }
        if !contacts.refusedGroupIDs.isEmpty {
            lines.append(
                ResultLine(
                    kind: .contactsLeft,
                    text: "Contacts wouldn't save \(contacts.refusedGroupIDs.count.counted("contact group")), often "
                        + "because a card is in a read-only account. Those cards won't be suggested again."))
        }
        if !contacts.failedGroupIDs.isEmpty {
            lines.append(
                ResultLine(
                    kind: .contactsLeft,
                    text: "\(contacts.failedGroupIDs.count.counted("contact group")) couldn't be merged and stayed in "
                        + "Review."))
        }
        return lines
    }
}
