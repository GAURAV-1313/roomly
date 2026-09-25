// Why: the whole scan — index, hash, group, size — runs off the main actor and reports as one ordered
// stream of events. The store only applies events; cancelling the consumer cancels every stage, but keeps
// the hashes already computed.
import Foundation

nonisolated enum ScanEvent: Sendable {
    case indexing(IndexProgress)
    case indexed([AssetSnapshot])
    case comparing(HashProgress)
    /// `unchecked` holds photos that could not be compared, for example because they are only in iCloud.
    case grouped([SimilarGroup], sizes: [String: AssetSize], unchecked: Set<String>)
}

nonisolated struct ScanPipeline: Sendable {
    let source: any PhotoSource
    let cache: HashCache

    func run() -> AsyncStream<ScanEvent> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                await execute { continuation.yield($0) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func execute(emit: @Sendable (ScanEvent) -> Void) async {
        let clock = ContinuousClock()
        let start = clock.now
        let ticket = await cache.beginScan()
        let snapshots = await index(emit: emit)
        Log.scan.notice("indexed \(snapshots.count) assets in \(Self.seconds(clock.now - start), privacy: .public)")
        guard !Task.isCancelled else { return }
        emit(.indexed(snapshots))

        let photos = snapshots.filter { $0.kind == .photo }
        let allHashes = await PhotoHasher.hash(photos, cached: await cache.load(), source: source) {
            emit(.comparing($0))
        }
        // Only photos still in the library are kept, so the cache never grows with deleted ones. A stopped
        // scan stores what it hashed too, so resuming starts where it left off; its ticket keeps a late store
        // from overwriting a newer scan's hashes or a cleared cache.
        let current = Set(photos.map(\.id))
        let hashes = allHashes.filter { current.contains($0.key) }
        await cache.store(hashes, from: ticket)
        Log.scan.notice("hashed \(hashes.count) of \(photos.count) photos")
        guard !Task.isCancelled else { return }

        let groups = SimilarityEngine.group(photos, hashes: hashes)
        let sizes = await source.fileSizes(for: groups.flatMap(\.members))
        let sized = sizedSnapshots(photos, sizes: sizes)
        let unchecked = Set(photos.lazy.map(\.id).filter { hashes[$0] == nil })
        emit(
            .grouped(BestPicker.refreshed(groups, snapshots: sized, hashes: hashes), sizes: sizes, unchecked: unchecked)
        )
        Log.scan.notice(
            "scan done: \(groups.count) groups from \(photos.count) photos in \(Self.seconds(clock.now - start), privacy: .public)"
        )
    }

    private static func seconds(_ duration: Duration) -> String {
        duration.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow))
    }

    private func index(emit: @Sendable (ScanEvent) -> Void) async -> [AssetSnapshot] {
        var snapshots: [AssetSnapshot] = []
        for await event in source.indexLibrary() {
            switch event {
            case .progress(let progress): emit(.indexing(progress))
            case .finished(let result): snapshots = result
            }
        }
        return snapshots
    }

    /// Every photo, with its size where Photos gave one. A photo without a size stays in its group.
    private func sizedSnapshots(_ photos: [AssetSnapshot], sizes: [String: AssetSize]) -> [String: AssetSnapshot] {
        var byID: [String: AssetSnapshot] = [:]
        for var photo in photos {
            photo.size = sizes[photo.id]
            byID[photo.id] = photo
        }
        return byID
    }
}
