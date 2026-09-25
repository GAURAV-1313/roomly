// Why: the grouping promise has to hold at the size of a real library. A year of 20,000 random photos with
// planted duplicates and bursts must produce exactly the planted groups — no false ones — and stay fast.
import XCTest

@testable import Roomy

final class SimilarityScaleTests: XCTestCase {
    func testTwentyThousandPhotosGroupExactlyThePlantedSetsQuickly() {
        var random = SplitMix64(seed: 42)
        var photos: [AssetSnapshot] = []
        var hashes: [String: HashRecord] = [:]
        for index in 0..<20_000 {
            let id = "p\(index)"
            photos.append(.fixture(id, at: Double(index) * 1_500))
            hashes[id] = hashRecord(random.next())
        }
        for plant in 0..<300 {
            let original = "p\(plant * 60)"
            let copy = "dup\(plant)"
            photos.append(.fixture(copy, at: Double(plant) * 90_000 + 7))
            hashes[copy] = hashes[original]
            let burst = "burst\(plant)"
            photos.append(.fixture(burst, at: Double(plant * 60) * 1_500 + 2))
            hashes[burst] = hashRecord((hashes[original]?.dhash ?? 0) ^ 0b1011)
        }

        let start = ContinuousClock.now
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        let elapsed = ContinuousClock.now - start

        XCTAssertEqual(groups.count, 300, "each planted set is one group, and nothing else is grouped")
        XCTAssertTrue(groups.allSatisfy { $0.members.count == 3 })
        XCTAssertLessThan(elapsed, .seconds(5), "grouping 20,600 photos took \(elapsed)")
    }
}
