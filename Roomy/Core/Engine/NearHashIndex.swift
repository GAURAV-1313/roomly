// Why: duplicates must be found across the whole library without comparing every pair, and without missing
// any. By pigeonhole, two hashes that differ in at most `limit` bits agree exactly on at least one of
// `limit + 1` bands, so bucketing by each band finds every such pair. A bucket that grows large (many skies
// share an empty top band) is split again on the bits its members do not share yet, so the guarantee holds
// at any size instead of skipping the crowded bucket.
import Foundation

nonisolated enum NearHashIndex {
    /// A bucket larger than this is split on further bits instead of compared pair by pair.
    static let bucketSplitThreshold = 60

    /// Calls `body(first, second, distance)` for every pair of positions in `hashes` whose Hamming distance is
    /// at most `limit`. Identical hashes are reported against the first photo with that hash. A pair may be
    /// reported more than once; linking is idempotent, so callers need not care.
    static func forEachPair(in hashes: [UInt64], within limit: Int, _ body: (Int, Int, Int) -> Void) {
        var byHash: [UInt64: [Int]] = [:]
        for (index, hash) in hashes.enumerated() {
            byHash[hash, default: []].append(index)
        }
        var representatives: [Int] = []
        for positions in byHash.values {
            representatives.append(positions[0])
            for position in positions.dropFirst() {
                body(positions[0], position, 0)
            }
        }
        representatives.sort()
        search(representatives, hashes: hashes, freeBits: .max, limit: limit, body)
    }

    // MARK: - Private

    private static func search(
        _ indices: [Int], hashes: [UInt64], freeBits: UInt64, limit: Int, _ body: (Int, Int, Int) -> Void
    ) {
        let bands = split(freeBits, into: limit + 1)
        guard bands.allSatisfy({ $0 != 0 }) else {
            compareAll(indices, hashes: hashes, limit: limit, body)
            return
        }
        for band in bands {
            var buckets: [UInt64: [Int]] = [:]
            for index in indices {
                buckets[hashes[index] & band, default: []].append(index)
            }
            for bucket in buckets.values where bucket.count > 1 {
                if bucket.count <= bucketSplitThreshold {
                    compareAll(bucket, hashes: hashes, limit: limit, body)
                } else {
                    search(bucket, hashes: hashes, freeBits: freeBits & ~band, limit: limit, body)
                }
            }
        }
    }

    /// Splits the set bits of `mask` into `count` contiguous bands of nearly equal width.
    static func split(_ mask: UInt64, into count: Int) -> [UInt64] {
        let positions = (0..<64).filter { mask & (1 << UInt64($0)) != 0 }
        return (0..<count).map { band in
            let start = positions.count * band / count
            let end = positions.count * (band + 1) / count
            return positions[start..<end].reduce(UInt64(0)) { $0 | (1 << UInt64($1)) }
        }
    }

    private static func compareAll(
        _ indices: [Int], hashes: [UInt64], limit: Int, _ body: (Int, Int, Int) -> Void
    ) {
        for firstPosition in indices.indices {
            for secondPosition in indices.indices where secondPosition > firstPosition {
                let first = indices[firstPosition]
                let second = indices[secondPosition]
                let distance = PerceptualHash.hamming(hashes[first], hashes[second])
                if distance <= limit {
                    body(first, second, distance)
                }
            }
        }
    }
}
