// Why: hashing is the only stage that touches pixels, so it is bounded — a few requests in flight, because
// Photos serialises them internally anyway — and it skips any photo whose cached hash is still valid. A
// photo it cannot read is counted, never silently treated as compared.
import Foundation

nonisolated enum PhotoHasher {
    /// More parallel requests only queue inside Photos and cost memory.
    static let maxConcurrentRequests = 4
    /// Report progress every this many photos.
    static let progressInterval = 25

    static func hash(
        _ photos: [AssetSnapshot], cached: [String: HashRecord], source: any PhotoSource,
        onProgress: (HashProgress) -> Void
    ) async -> [String: HashRecord] {
        var results = cached
        let pending = photos.filter { needsHashing($0, cached: cached) }
        var progress = HashProgress(total: pending.count)
        onProgress(progress)
        guard !pending.isEmpty else { return results }

        await withTaskGroup(of: (photo: AssetSnapshot, record: HashRecord?).self) { group in
            var queue = pending.makeIterator()
            for _ in 0..<maxConcurrentRequests {
                guard let next = queue.next() else { break }
                group.addTask { await hashed(next, source: source) }
            }
            for await result in group {
                // A photo that can't be read loses an older hash of a different version: an edited photo must
                // not be compared by how it used to look. Without a record it counts as not compared.
                let record = result.record ?? stillValid(cached[result.photo.id], for: result.photo)
                results[result.photo.id] = record
                if record == nil {
                    progress.failed += 1
                }
                progress.done += 1
                if progress.done.isMultiple(of: progressInterval) || progress.done == progress.total {
                    onProgress(progress)
                }
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                if let next = queue.next() {
                    group.addTask { await hashed(next, source: source) }
                }
            }
        }
        return results
    }

    /// A record from before contrast was measured is hashed again once, so flat photos are recognised.
    static func needsHashing(_ photo: AssetSnapshot, cached: [String: HashRecord]) -> Bool {
        guard let record = cached[photo.id] else { return true }
        return record.modificationDate != photo.modificationDate || record.contrast == nil
    }

    /// A cached record of the photo as it is now, kept when reading it again fails: a record from before
    /// contrast was measured still describes the photo by its bits, so an update never makes a compared photo
    /// "not checked" because its image happens to be in iCloud today.
    static func stillValid(_ record: HashRecord?, for photo: AssetSnapshot) -> HashRecord? {
        guard let record, record.modificationDate == photo.modificationDate else { return nil }
        return record
    }

    private static func hashed(_ photo: AssetSnapshot, source: any PhotoSource) async -> (
        photo: AssetSnapshot, record: HashRecord?
    ) {
        guard let tiles = await source.hashTiles(for: photo.id) else {
            Log.scan.error("hash: no image for \(photo.id)")
            return (photo, nil)
        }
        let record = HashRecord(
            modificationDate: photo.modificationDate,
            dhash: PerceptualHash.dhash(gray9x8: tiles.gray9x8),
            sharpness: PerceptualHash.laplacianVariance(gray: tiles.gray32, width: 32, height: 32),
            contrast: PerceptualHash.contrast(gray: tiles.gray32))
        return (photo, record)
    }
}
