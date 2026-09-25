// Why: a hash is cached per asset and keyed by its modification date, so an edited photo is hashed
// again and an untouched one never is. Tiles are the raw pixels the hashes are computed from. A hash alone
// cannot tell two black pocket shots apart, so the record also says whether the photo has enough detail
// for its hash to mean anything.
import Foundation

nonisolated struct HashRecord: Codable, Sendable, Equatable {
    var modificationDate: Date?
    var dhash: UInt64
    var sharpness: Double
    /// Brightness spread of the 32×32 tile (`PerceptualHash.contrast`). Optional so caches written before it
    /// existed still load; such records are hashed again on the next scan.
    var contrast: Double?
}

nonisolated extension HashRecord {
    /// Below this brightness spread a tile is flat (dark, white or a blank wall) and its hash is noise.
    static let minimumContrast = 8.0
    /// A hash with fewer set bits than this, or fewer clear bits, comes from a smooth gradient or a flat frame.
    static let minimumMixedBits = 8

    /// Whether the hash describes real structure. Photos without it are never linked as duplicates or as the
    /// same moment on their hash alone: precision first.
    var hasDetail: Bool {
        let setBits = dhash.nonzeroBitCount
        guard setBits >= Self.minimumMixedBits, 64 - setBits >= Self.minimumMixedBits else { return false }
        guard let contrast else { return true }
        return contrast >= Self.minimumContrast
    }
}

/// Deterministic grayscale tiles: 9×8 for the difference hash, 32×32 for sharpness.
nonisolated struct HashTiles: Sendable {
    let gray9x8: [UInt8]
    let gray32: [UInt8]
}
