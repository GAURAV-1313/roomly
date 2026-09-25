// Why: the keeper must be predictable and defensible. What the person marked wins first — a favourite, then
// the frame they or the camera picked from a burst — then resolution, then sharpness in coarse steps, and
// only then file size, which otherwise decides almost every pick (a Live Photo's movie inflates it). An
// unknown size ranks lowest but never removes a photo from its group. A pure function, so it is unit-tested.
import Foundation

nonisolated enum BestPicker {
    /// Sharpness scores in the same step of this ratio count as equally sharp, so noise in the score never
    /// decides and file size breaks the tie instead.
    static let sharpnessStep = 1.25

    static func pick(_ members: [AssetSnapshot], hashes: [String: HashRecord]) -> AssetSnapshot? {
        members.max { rank($0, hashes: hashes) < rank($1, hashes: hashes) }
    }

    /// Re-picks each group's keeper once file sizes are known, and puts the keeper first. Every member stays,
    /// including ones missing from `snapshots`.
    static func refreshed(
        _ groups: [SimilarGroup], snapshots: [String: AssetSnapshot], hashes: [String: HashRecord]
    ) -> [SimilarGroup] {
        groups.map { group in
            guard let best = pick(group.members.compactMap { snapshots[$0] }, hashes: hashes) else { return group }
            return group.withKeeper(best.id)
        }
    }

    /// Higher is a better keeper. Compared left to right.
    private static func rank(_ photo: AssetSnapshot, hashes: [String: HashRecord])
        -> (Int, Int, Int, Int, Int64)
    {
        (
            photo.isFavorite ? 1 : 0,
            photo.burstPick.rawValue,
            photo.pixelCount,
            sharpnessLevel(hashes[photo.id]?.sharpness ?? 0),
            photo.fileSize ?? -1
        )
    }

    static func sharpnessLevel(_ sharpness: Double) -> Int {
        guard sharpness > 1 else { return 0 }
        return Int((log(sharpness) / log(sharpnessStep)).rounded(.down))
    }
}
