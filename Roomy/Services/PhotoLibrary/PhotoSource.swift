// Why: the scan depends on this protocol, not on PhotoKit, so its state machine can be unit-tested
// with a fake library. The real implementation is `PhotoLibrary`.
import Foundation

nonisolated enum IndexEvent: Sendable {
    case progress(IndexProgress)
    case finished([AssetSnapshot])
}

nonisolated protocol PhotoSource: Sendable {
    /// Streams progress while enumerating the library, then the snapshots. Cancelling the consumer stops it.
    func indexLibrary() -> AsyncStream<IndexEvent>
    /// Sizes of the given assets, with the part kept only in iCloud. Missing entries mean "size unavailable".
    func fileSizes(for ids: [String]) async -> [String: AssetSize]
    /// Grayscale tiles for hashing, or nil if the image is unavailable (for example iCloud-only).
    func hashTiles(for id: String) async -> HashTiles?
}
