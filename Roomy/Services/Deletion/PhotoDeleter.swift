// Why: the only code that deletes photos. iOS shows its own confirmation for every request, so assets go in
// as few requests as possible. Nothing is asked without Photos access; only assets that exist are sent; what
// was removed is checked against the library afterwards, never assumed from the callback; and a request
// Photos never answers is given up on instead of hanging the app. The accounting lives in `RemovalRun`.
import Photos

nonisolated enum PhotoDeleter {
    /// Generous, because the person may take their time with the system prompt.
    static let answerTimeout: Duration = .seconds(180)

    /// Off the main actor: the library fetches before and after each request are disk work.
    @concurrent
    static func remove(_ ids: [String], keepingOneOf groups: [[String]]) async -> AssetRemoval {
        // Without access every fetch comes back empty, which would read as "already gone". Ask nothing instead.
        guard PhotoPermission.current().canUse else {
            Log.cleanup.error("photos access is off; nothing was asked")
            return AssetRemoval(stop: .noAccess)
        }
        let removal = await RemovalRun.run(
            ids, keepingOneOf: groups, batchSize: CleanupPlan.assetsPerPrompt,
            existing: { existing($0) },
            delete: { await request(deleting: $0) })
        Log.cleanup.notice(
            "removed \(removal.removedIDs.count) of \(ids.count) assets; \(removal.unavailableIDs.count) unavailable"
        )
        return removal
    }

    /// Asks Photos to delete the batch; returns why it stopped, or nil on success.
    private static func request(deleting ids: [String]) async -> AssetRemoval.Stop? {
        await withCheckedContinuation { continuation in
            let once = ResumeOnce(continuation)
            let timeout = Task {
                // try? is deliberate: the sleep throws only when the answer arrived and cancelled it.
                try? await Task.sleep(for: answerTimeout)
                if !Task.isCancelled {
                    once.resume(returning: .timedOut)
                }
            }
            // @Sendable: the block runs on Photos' own queue and must not inherit the main actor.
            PHPhotoLibrary.shared().performChanges(
                { @Sendable in
                    PHAssetChangeRequest.deleteAssets(
                        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: .matchingIndex()))
                },
                completionHandler: { @Sendable isDone, error in
                    timeout.cancel()
                    once.resume(returning: isDone ? nil : stop(for: error))
                })
        }
    }

    private static func stop(for error: (any Error)?) -> AssetRemoval.Stop {
        if let error = error as? PHPhotosError, error.code == .userCancelled {
            return .declined
        }
        let message = error?.localizedDescription ?? "Photos did not delete the items."
        Log.cleanup.error("delete failed: \(message, privacy: .public)")
        return .failed(message)
    }

    private static func existing(_ ids: [String]) -> Set<String> {
        guard !ids.isEmpty else { return [] }
        var found: Set<String> = []
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: .matchingIndex()).enumerateObjects { asset, _, _ in
            found.insert(asset.localIdentifier)
        }
        return found
    }
}
