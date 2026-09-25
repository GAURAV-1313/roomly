// Why: the README promises that every copy within Hamming 4 is found anywhere in the library. That is a
// pigeonhole guarantee, so it is tested against brute force, including a crowded band that used to be skipped.
import XCTest

@testable import Roomy

final class NearHashIndexTests: XCTestCase {
    func testEveryPairWithinFourBitsIsFound() {
        var random = SplitMix64(seed: 7)
        var hashes: [UInt64] = []
        for _ in 0..<600 {
            let original = random.next()
            hashes.append(original)
            hashes.append(flipping(original, bits: 1 + random.next(below: 4), random: &random))
        }
        XCTAssertEqual(indexedPairs(hashes), bruteForcePairs(hashes))
    }

    /// Regression: a band value shared by more than 60 photos was skipped, so pairs whose only shared band it
    /// was were missed.
    func testPairsWhoseOnlySharedBandIsCrowdedAreFound() {
        var random = SplitMix64(seed: 11)
        let bands = NearHashIndex.split(.max, into: 5)
        var hashes: [UInt64] = []
        for _ in 0..<200 {
            let original = random.next() & ~bands[0]
            var copy = original
            for band in bands.dropFirst() {
                copy ^= band & (1 << UInt64(band.trailingZeroBitCount))
            }
            hashes.append(contentsOf: [original, copy])
        }
        let found = indexedPairs(hashes)
        for pair in stride(from: 0, to: hashes.count, by: 2) {
            XCTAssertTrue(found.contains(Pair(pair, pair + 1)), "pair \(pair) shares only the crowded band")
        }
        XCTAssertEqual(found, bruteForcePairs(hashes))
    }

    func testIdenticalHashesAreReportedAtDistanceZero() {
        var distances: [Int] = []
        NearHashIndex.forEachPair(in: [5, 5, 5], within: 4) { _, _, distance in distances.append(distance) }
        XCTAssertEqual(distances, [0, 0])
    }

    func testBandsCoverEveryBitOnce() {
        let bands = NearHashIndex.split(.max, into: 5)
        XCTAssertEqual(bands.reduce(0, |), .max)
        XCTAssertEqual(bands.map(\.nonzeroBitCount).reduce(0, +), 64)
    }

    // MARK: - Helpers

    private struct Pair: Hashable {
        let low: Int
        let high: Int

        init(_ first: Int, _ second: Int) {
            low = min(first, second)
            high = max(first, second)
        }
    }

    private func indexedPairs(_ hashes: [UInt64]) -> Set<Pair> {
        var pairs = Set<Pair>()
        NearHashIndex.forEachPair(in: hashes, within: 4) { first, second, _ in pairs.insert(Pair(first, second)) }
        // Identical hashes are reported against the first copy only; close them the way union-find would.
        return closedUnderEqualHashes(pairs, hashes: hashes)
    }

    private func bruteForcePairs(_ hashes: [UInt64]) -> Set<Pair> {
        var pairs = Set<Pair>()
        for first in hashes.indices {
            for second in hashes.indices
            where second > first && PerceptualHash.hamming(hashes[first], hashes[second]) <= 4 {
                pairs.insert(Pair(first, second))
            }
        }
        return pairs
    }

    private func closedUnderEqualHashes(_ pairs: Set<Pair>, hashes: [UInt64]) -> Set<Pair> {
        var closed = pairs
        for pair in pairs {
            for other in hashes.indices where other != pair.high && hashes[other] == hashes[pair.high] {
                closed.insert(Pair(pair.low, other))
            }
        }
        return closed.filter { $0.low != $0.high }
    }

    private func flipping(_ hash: UInt64, bits: Int, random: inout SplitMix64) -> UInt64 {
        var result = hash
        var flipped = Set<Int>()
        while flipped.count < bits {
            flipped.insert(random.next(below: 64))
        }
        for bit in flipped {
            result ^= 1 << UInt64(bit)
        }
        return result
    }
}
