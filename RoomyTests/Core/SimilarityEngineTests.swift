// Why: grouping precision is the product's hardest promise. These tests pin what may and may not be
// grouped, and the reason each group shows.
import XCTest

@testable import Roomy

final class SimilarityEngineTests: XCTestCase {
    /// A hash with ordinary structure: 32 of 64 bits set.
    private let base: UInt64 = 0x0F0F_3C3C_A5A5_F00F

    func testExactDuplicatesGroupAcrossTheWholeLibrary() {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 100_000), .fixture("c", at: 200_000)]
        let hashes = ["a": hashRecord(base), "b": hashRecord(base), "c": hashRecord(0xF0F0_F0F0_F0F0_F0F0)]
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].members), ["a", "b"])
        XCTAssertEqual(groups[0].reason, .exactDuplicate)
    }

    /// Regression: an exact copy taken in the same moment was labelled "Taken together", because the pair's
    /// weaker second link (same moment) overrode its stronger one (identical hash).
    func testAnExactCopyTakenInTheSameMomentIsStillAnExactDuplicate() {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 1)]
        let groups = SimilarityEngine.group(photos, hashes: ["a": hashRecord(base), "b": hashRecord(base)])
        XCTAssertEqual(groups.first?.reason, .exactDuplicate)
    }

    func testNearIdenticalShotsGroupOnlyWithinOneMoment() {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 5), .fixture("c", at: 5_000)]
        let hashes = ["a": hashRecord(base), "b": hashRecord(base ^ 0x3F), "c": hashRecord(base ^ 0x3F_0000)]
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].members), ["a", "b"], "c is 5,000 s away and must not join")
        XCTAssertEqual(groups[0].reason, .moment(seconds: 5))
    }

    func testDifferentOrientationsNeverGroupAsAMoment() {
        let photos: [AssetSnapshot] = [.fixture("a", width: 4000, height: 3000), .fixture("b", at: 2)]
        let hashes = ["a": hashRecord(base), "b": hashRecord(base ^ 0xFF)]
        XCTAssertTrue(SimilarityEngine.group(photos, hashes: hashes).isEmpty)
    }

    /// Regression: a group showed its strongest link, so a different shot taken 3 s after a copied photo read
    /// "Exact duplicate". The label now holds for every member.
    func testGroupShowsItsWeakestReason() {
        let photos: [AssetSnapshot] = [.fixture("c"), .fixture("a", at: 3), .fixture("b", at: 3)]
        let hashes = ["c": hashRecord(base ^ 0x3F), "a": hashRecord(base), "b": hashRecord(base)]
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].members), ["a", "b", "c"])
        XCTAssertEqual(groups[0].reason, .moment(seconds: 3))
    }

    /// Regression: a shot linked by its moment to a photo whose copy was saved a day later read "Taken 3s
    /// apart", which is false for the copy. Mixed evidence that spans more than a moment is only "similar".
    func testMixedLinksBeyondOneMomentAreOnlySimilar() {
        let photos: [AssetSnapshot] = [.fixture("c"), .fixture("a", at: 3), .fixture("b", at: 100_000)]
        let hashes = ["c": hashRecord(base ^ 0x3F), "a": hashRecord(base), "b": hashRecord(base)]
        XCTAssertEqual(SimilarityEngine.group(photos, hashes: hashes).map(\.reason), [.similar])

        let burst: [AssetSnapshot] = [.fixture("f1", burst: "B"), .fixture("f2", at: 0.5, burst: "B")]
        let copy = AssetSnapshot.fixture("copy", at: 200_000)
        let burstHashes = ["f1": hashRecord(base), "f2": hashRecord(~base), "copy": hashRecord(base)]
        XCTAssertEqual(SimilarityEngine.group(burst + [copy], hashes: burstHashes).map(\.reason), [.similar])
        XCTAssertEqual(SimilarityEngine.group(burst, hashes: burstHashes).map(\.reason), [.burst])
    }

    /// Regression: one shot every 45 s formed one run, so a walk chained into a single group spanning minutes.
    func testSlowSequenceNeverChainsIntoOneMoment() {
        let photos = (0..<12).map { AssetSnapshot.fixture("p\($0)", at: Double($0) * 45) }
        var hashes: [String: HashRecord] = [:]
        for index in 0..<12 {
            // Disjoint 5-bit changes: every pair is 10 bits apart, alike for a moment but never a duplicate.
            hashes["p\(index)"] = hashRecord(base ^ (0b11111 << UInt64(index * 5)))
        }
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.count, 6)
        XCTAssertTrue(groups.allSatisfy { $0.members.count == 2 && $0.reason == .moment(seconds: 45) })
    }

    /// Regression: only the first 40 photos of a continuous run were compared, so later look-alikes were missed.
    func testLookAlikesLateInALongRunAreGrouped() {
        let photos = (0..<50).map { AssetSnapshot.fixture("p\($0)", at: Double($0)) }
        var hashes: [String: HashRecord] = [:]
        for index in 0..<50 {
            hashes["p\(index)"] = hashRecord(UInt64(index + 1) &* 0x9E37_79B9_7F4A_7C15)
        }
        hashes["p46"] = hashRecord((hashes["p45"]?.dhash ?? 0) ^ 0x3F)
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.map { Set($0.members) }, [["p45", "p46"]])
    }

    /// Regression: flat frames all hash to about zero, so black pocket shots from different months grouped as
    /// "Exact duplicate".
    func testFlatPhotosAreNeverLinkedOnTheirHash() {
        let days = (0..<6).map { AssetSnapshot.fixture("dark\($0)", at: Double($0) * 2_000_000) }
        let noisy = [AssetSnapshot.fixture("noisy1", at: 1), .fixture("noisy2", at: 2)]
        let gradients = [AssetSnapshot.fixture("sky1", at: 90_000), .fixture("sky2", at: 90_001)]
        var hashes: [String: HashRecord] = [:]
        for photo in days { hashes[photo.id] = hashRecord(0, contrast: 1) }
        hashes["noisy1"] = hashRecord(base, contrast: 2)
        hashes["noisy2"] = hashRecord(base, contrast: 2)
        hashes["sky1"] = hashRecord(0b11, contrast: 60)
        hashes["sky2"] = hashRecord(0b11, contrast: 60)
        XCTAssertTrue(SimilarityEngine.group(days + noisy + gradients, hashes: hashes).isEmpty)
    }

    /// Regression: candidates came from four 16-bit bands, so a copy one bit off in each band was never found.
    func testDuplicateFourBitsApartAcrossEveryOldBandIsFound() {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 100_000)]
        let copy = base ^ (1 | 1 << 16 | 1 << 32 | 1 << 48)
        let groups = SimilarityEngine.group(photos, hashes: ["a": hashRecord(base), "b": hashRecord(copy)])
        XCTAssertEqual(groups.map(\.reason), [.nearDuplicate])
    }

    /// Burst frames group by the camera's burst id, and the picked frame is the keeper even when smaller.
    func testBurstFramesGroupWithThePickedFrameAsKeeper() {
        let photos: [AssetSnapshot] = [
            .fixture("f1", burst: "B", size: 900), .fixture("f2", at: 0.2, burst: "B", burstPick: .person, size: 100),
            .fixture("f3", at: 0.4, burst: "B", burstPick: .camera, size: 900),
        ]
        let hashes = [
            "f1": hashRecord(base), "f2": hashRecord(~base), "f3": hashRecord(0x5555_5555_5555_5555),
        ]
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.reason, .burst)
        XCTAssertEqual(groups.first?.best, "f2")
    }

    func testScreenshotsAndVideosAreNeverGrouped() {
        let items: [AssetSnapshot] = [.fixture("s", kind: .screenshot), .fixture("v", kind: .video, at: 1)]
        let hashes = ["s": hashRecord(base), "v": hashRecord(base)]
        XCTAssertTrue(SimilarityEngine.group(items, hashes: hashes).isEmpty)
    }

    func testWeakerReasonsOrderMomentsByTheirSpan() {
        XCTAssertTrue(SimilarityReason.moment(seconds: 2).isWeaker(than: .exactDuplicate))
        XCTAssertTrue(SimilarityReason.moment(seconds: 50).isWeaker(than: .moment(seconds: 2)))
        XCTAssertFalse(SimilarityReason.exactDuplicate.isWeaker(than: .nearDuplicate))
    }

    func testMomentClustersNeverStretchPastTheWindow() {
        let dates: [Date?] = [
            Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 40), Date(timeIntervalSince1970: 80), nil,
        ]
        var moments = MomentClusters(dates: dates)
        XCTAssertEqual(moments.join(0, 1, within: 60), 40)
        XCTAssertNil(moments.join(1, 2, within: 60), "joining would make the moment 80 s long")
        XCTAssertNil(moments.join(2, 3, within: 60), "an undated photo has no moment")
    }
}
