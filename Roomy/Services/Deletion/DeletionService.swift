// Why: the single entry point for anything destructive. Stores depend on the `Cleaner` protocol, so the
// cleanup flow is tested with a fake that deletes nothing; this type is the only real implementation.
import Foundation

nonisolated protocol Cleaner: Sendable {
    /// Backs up, then merges each group into its kept card.
    func merge(_ groups: [ContactGroup]) async -> ContactMergeResult
    /// Moves assets to Recently Deleted after the system prompt, keeping one photo of every similar group
    /// (member ids, keeper first); reports what is really gone.
    func removeAssets(_ ids: [String], keepingOneOf groups: [[String]]) async -> AssetRemoval
    /// Contact backups on this phone, newest first.
    func backups() -> [URL]
}

nonisolated struct DeletionService: Cleaner {
    func merge(_ groups: [ContactGroup]) async -> ContactMergeResult {
        await ContactMerger.merge(groups)
    }

    func removeAssets(_ ids: [String], keepingOneOf groups: [[String]]) async -> AssetRemoval {
        guard !ids.isEmpty else { return AssetRemoval() }
        return await PhotoDeleter.remove(ids, keepingOneOf: groups)
    }

    func backups() -> [URL] {
        VCardBackup.all()
    }
}
