// Why: what a delete really did must be measured, not assumed. Asking only for assets that exist, and counting
// as removed only those that existed before and are gone after, means a failed or refused request can never
// read as "moved". The steps are pure over two injected calls, so the accounting is unit-tested without Photos.
import Foundation

nonisolated enum RemovalRun {
    /// Deletes `ids` in batches, keeping one photo of every similar group, and reports what is really gone.
    /// - Parameters:
    ///   - groups: member ids of the similar groups the ids belong to, keeper first.
    ///   - existing: which of the given ids are in the library right now.
    ///   - delete: asks for one batch to be deleted; returns why it stopped, or nil when it went through.
    static func run(
        _ ids: [String], keepingOneOf groups: [[String]], batchSize: Int,
        existing: ([String]) async -> Set<String>,
        delete: ([String]) async -> AssetRemoval.Stop?
    ) async -> AssetRemoval {
        var removal = AssetRemoval()
        let before = await existing(Array(Set(ids + groups.flatMap { $0 })))
        removal.unavailableIDs = ids.filter { !before.contains($0) }
        let queued = ids.filter(before.contains)
        let spared = SurvivorRule.spared(queued: Set(queued), groups: groups, existing: before)
        removal.sparedIDs = queued.filter(spared.contains)
        let requested = queued.filter { !spared.contains($0) }

        let size = max(batchSize, 1)
        for start in stride(from: 0, to: requested.count, by: size) {
            let batch = Array(requested[start..<min(start + size, requested.count)])
            let stop = await delete(batch)
            let remaining = await existing(batch)
            removal.removedIDs += batch.filter { !remaining.contains($0) }
            if let stop {
                removal.stop = stop
                break
            }
        }
        return removal
    }
}
