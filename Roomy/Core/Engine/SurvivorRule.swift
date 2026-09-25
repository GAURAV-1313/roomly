// Why: deleting from Similar photos must always leave at least one photo of each group. The screen can be
// out of date — the keeper changed after a rescan, or was deleted in Photos — so the rule runs twice: on the
// plan, against the groups the scan found, and again just before the delete, against what is really in the
// library. A stale screen can never empty a group.
import Foundation

nonisolated enum SurvivorRule {
    /// The queued photos to keep so that every group still has a photo in the library. For each group whose
    /// remaining photos are all queued, the first one still there is kept: the keeper, when it is there.
    /// - Parameters:
    ///   - groups: member ids of each group, keeper first. A photo alone is the last of its moment.
    ///   - existing: which ids are in the library.
    static func spared(queued: Set<String>, groups: [[String]], existing: Set<String>) -> Set<String> {
        var spared: Set<String> = []
        for members in groups {
            let present = members.filter(existing.contains)
            guard let first = present.first, present.allSatisfy(queued.contains) else { continue }
            spared.insert(first)
        }
        return spared
    }
}
