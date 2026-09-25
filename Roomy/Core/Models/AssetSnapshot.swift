// Why: PhotoKit objects are not Sendable and never leave Services/. This value type is the copy of the
// cheap fields that crosses actor boundaries. `size` is the one expensive field, filled in lazily.
import Foundation

nonisolated struct AssetSnapshot: Sendable, Hashable, Identifiable {
    enum Kind: String, Codable, Sendable, CaseIterable {
        case photo
        case screenshot
        case video
    }

    /// Whether a burst frame was picked as the one to keep. The person's pick outranks the camera's.
    enum BurstPick: Int, Sendable {
        case none
        case camera
        case person
    }

    let id: String
    let kind: Kind
    let creationDate: Date?
    let modificationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    let burstIdentifier: String?
    let isFavorite: Bool
    var filename: String? = nil
    /// nil until measured, and when Photos reports no size ("size unavailable").
    var size: AssetSize? = nil
    var burstPick: BurstPick = .none

    var pixelCount: Int { pixelWidth * pixelHeight }
    /// Bytes of all its files, wherever they are.
    var fileSize: Int64? { size?.bytes }
    /// Bytes stored on this phone: what deleting it gives back here. Files kept only in iCloud don't count.
    var bytesOnPhone: Int64? { size?.onPhone }
}
