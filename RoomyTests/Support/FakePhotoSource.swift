// Why: the scan store is tested against a fake library that returns fixed snapshots after a delay and
// stops when cancelled, so the scan state machine can be tested without a device or real photos.
import Foundation

@testable import Roomy

struct FakePhotoSource: PhotoSource {
    let snapshots: [AssetSnapshot]
    var delay: Duration = .zero
    /// How long each photo takes to hash, so a test can stop a scan while it compares.
    var tileDelay: Duration = .zero
    /// Photos with no image on the phone, like ones kept only in iCloud.
    var unreadable: Set<String> = []
    /// Identical textured tiles for every photo, so all photos are exact duplicates of each other.
    var tiles = HashTiles(gray9x8: Self.texture(count: 72), gray32: Self.texture(count: 1024))
    /// Photos whose size Photos cannot tell, as happens when no resource answers the size key.
    var unsizedIDs: Set<String> = []

    func indexLibrary() -> AsyncStream<IndexEvent> {
        AsyncStream { continuation in
            let task = Task { [snapshots, delay] in
                // try? is deliberate: the sleep only throws on cancellation, which is checked next.
                try? await Task.sleep(for: delay)
                if !Task.isCancelled {
                    continuation.yield(.progress(IndexProgress(scanned: snapshots.count, total: snapshots.count)))
                    continuation.yield(.finished(snapshots))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func fileSizes(for ids: [String]) async -> [String: AssetSize] {
        Dictionary(
            Set(ids).subtracting(unsizedIDs).map { ($0, AssetSize(bytes: 1_000)) },
            uniquingKeysWith: { first, _ in first })
    }

    func hashTiles(for id: String) async -> HashTiles? {
        // try? is deliberate: a cancelled sleep only ends the wait early, like a real request giving up.
        try? await Task.sleep(for: tileDelay)
        return unreadable.contains(id) ? nil : tiles
    }

    /// A busy, deterministic pattern: plenty of contrast and a hash with both kinds of bits.
    static func texture(count: Int) -> [UInt8] {
        (0..<count).map { UInt8(($0 * 151) % 256) }
    }
}
