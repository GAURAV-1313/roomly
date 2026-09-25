// Why: a group card must describe the basket as it is. Counting only the extras let a card say "Keeping all 3"
// while its keeper was queued, so the footer and every tile are derived here, from every queued member, and
// tested.
import Foundation

nonisolated struct SimilarGroupSelection: Equatable {
    let group: SimilarGroup
    /// Members in the basket, in the group's order; the keeper too, if it is there.
    let queued: [String]

    init(group: SimilarGroup, isQueued: (String) -> Bool) {
        self.group = group
        queued = group.members.filter(isQueued)
    }

    var isKeeperQueued: Bool { queued.contains(group.best) }
    /// Whether "Select extras" would take them out again. Photos the person marked in Photos are left out of
    /// bulk selection, so only the suggested extras count.
    var areAllExtrasQueued: Bool {
        !group.suggestedExtras.isEmpty && group.suggestedExtras.allSatisfy(queued.contains)
    }
    /// A group whose every extra is marked by the person has nothing to select in bulk.
    var canSelectExtras: Bool { !group.suggestedExtras.isEmpty }

    /// Members that stay: every member not in the basket, the keeper included unless it is queued.
    var keptCount: Int { group.members.count - queued.count }

    /// "Keeping all 3" only when nothing in the group is queued; otherwise what stays, what would go and its
    /// size, which says "size unavailable" or "at least" when sizes are unknown rather than showing "0 KB".
    func footer(queuedSize: SizeTotal) -> String {
        guard !queued.isEmpty else { return "Keeping all \(group.members.count)" }
        return "Keep \(keptCount) · Remove \(queued.count) · \(queuedSize.text)"
    }

    func tileState(for id: String) -> PhotoTileState {
        let isQueued = queued.contains(id)
        if id == group.best {
            return isQueued ? .bestSelected : .best
        }
        return isQueued ? .selected : .unselected
    }
}
