// Why: tests build snapshots and hashes in one line each, so every test reads as its scenario.
import Foundation

@testable import Roomy

extension AssetSnapshot {
    /// A snapshot created `seconds` after a fixed reference date. `inCloud` is the part of `size` kept only in
    /// iCloud.
    static func fixture(
        _ id: String, kind: Kind = .photo, at seconds: TimeInterval = 0, width: Int = 3000, height: Int = 4000,
        burst: String? = nil, burstPick: BurstPick = .none, favorite: Bool = false, size: Int64? = nil,
        inCloud: Int64 = 0
    ) -> AssetSnapshot {
        AssetSnapshot(
            id: id, kind: kind, creationDate: Date(timeIntervalSince1970: 1_700_000_000 + seconds),
            modificationDate: nil, pixelWidth: width, pixelHeight: height, duration: kind == .video ? 10 : 0,
            burstIdentifier: burst, isFavorite: favorite,
            size: size.map { AssetSize(bytes: $0, inCloudOnly: inCloud) }, burstPick: burstPick)
    }
}

/// A hash record for a photo with ordinary detail unless `contrast` says it is flat.
func hashRecord(_ hash: UInt64, sharpness: Double = 10, contrast: Double? = 40) -> HashRecord {
    HashRecord(modificationDate: nil, dhash: hash, sharpness: sharpness, contrast: contrast)
}
