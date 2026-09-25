// Why: a similar group must stay true to its photos: its label holds for every pair, it splits when the photo
// that joined the rest is deleted, and a favourite or a burst frame the person picked is never queued in bulk.
// These tests pin each of those promises.
import XCTest

@testable import Roomy

final class SimilarGroupIntegrityTests: XCTestCase {
    /// A hash with ordinary structure: 32 of 64 bits set.
    private let base: UInt64 = 0x0F0F_3C3C_A5A5_F00F

    /// Regression: a chain of 2-bit links read "Near-duplicate" though its ends were 6 bits apart.
    func testADuplicateLabelHoldsForTheWidestPair() {
        let photos: [AssetSnapshot] = [
            .fixture("a"), .fixture("b", at: 100_000), .fixture("c", at: 200_000), .fixture("d", at: 300_000),
        ]
        let hashes = [
            "a": hashRecord(base), "b": hashRecord(base ^ 0b11), "c": hashRecord(base ^ 0b1111),
            "d": hashRecord(base ^ 0b11_1111),
        ]
        let groups = SimilarityEngine.group(photos, hashes: hashes)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.members.count, 4)
        XCTAssertEqual(groups.first?.reason, .similar, "a and d are 6 bits apart: no duplicate label holds")
        XCTAssertEqual(SimilarityEngine.widestDistance([base, base ^ 0b11]), 2)
    }

    /// Regression: deleting the photo that joined a copy saved a day later to a shot 3 s after it left the two
    /// unrelated photos grouped, with one offered as an extra of the other.
    func testDeletingTheLinkingPhotoSplitsTheGroup() throws {
        let photos: [AssetSnapshot] = [.fixture("a"), .fixture("b", at: 100_000), .fixture("c", at: 100_003)]
        let hashes = ["a": hashRecord(base), "b": hashRecord(base), "c": hashRecord(base ^ 0xFF)]
        let group = try XCTUnwrap(SimilarityEngine.group(photos, hashes: hashes).first)
        XCTAssertEqual(Set(group.members), ["a", "b", "c"])

        XCTAssertTrue(SimilarGroupPruning.groups([group], without: ["b"], queued: []).isEmpty)
        let withoutC = SimilarGroupPruning.groups([group], without: ["c"], queued: [])
        XCTAssertEqual(withoutC.map { Set($0.members) }, [["a", "b"]])
        XCTAssertEqual(withoutC.first?.id, group.id, "one surviving part keeps the group's id")
    }

    func testAGroupSplitIntoTwoPartsKeepsBoth() {
        let links = [("k", "a"), ("a", "b"), ("b", "x"), ("x", "y")].map { MemberLink(first: $0.0, second: $0.1) }
        let group = SimilarGroup(
            id: "g", members: ["k", "a", "b", "x", "y"], best: "k", reason: .similar, links: links)
        let parts = SimilarGroupPruning.groups([group], without: ["b"], queued: ["x"])
        XCTAssertEqual(parts.map(\.members), [["k", "a"], ["y", "x"]], "a queued photo is not made the keeper")
        XCTAssertEqual(parts.map(\.best), ["k", "y"])
        XCTAssertEqual(Set(parts.map(\.id)).count, 2)
        XCTAssertEqual(parts.last?.links, [MemberLink(first: "x", second: "y")])

        let handMade = SimilarGroup(id: "h", members: ["k", "a", "b"], best: "k", reason: .exactDuplicate)
        XCTAssertEqual(SimilarGroupPruning.groups([handMade], without: ["a"], queued: []).first?.members, ["k", "b"])
    }

    /// Regression: with two favourites in one group, "Select extras" queued the favourite that wasn't the keeper.
    func testFavouritesAndPickedBurstFramesAreNeverSuggested() throws {
        let photos: [AssetSnapshot] = [
            .fixture("fav1", favorite: true), .fixture("fav2", at: 100_000, favorite: true),
            .fixture("plain", at: 200_000),
        ]
        let hashes = ["fav1": hashRecord(base), "fav2": hashRecord(base), "plain": hashRecord(base)]
        let group = try XCTUnwrap(SimilarityEngine.group(photos, hashes: hashes).first)
        XCTAssertTrue(["fav1", "fav2"].contains(group.best))
        XCTAssertEqual(group.suggestedExtras, ["plain"])
        XCTAssertEqual(group.extras.count, 2, "the other favourite can still be removed by hand")

        let burst: [AssetSnapshot] = (0..<5).map { index in
            .fixture("f\(index)", at: Double(index) / 10, burst: "B", burstPick: index < 3 ? .person : .none)
        }
        let burstHashes = Dictionary(uniqueKeysWithValues: burst.map { ($0.id, hashRecord(base)) })
        let burstGroup = try XCTUnwrap(SimilarityEngine.group(burst, hashes: burstHashes).first)
        XCTAssertEqual(Set(burstGroup.suggestedExtras), ["f3", "f4"], "every frame the person picked is kept out")
    }

    func testTheCardSelectsOnlySuggestedExtras() {
        var group = SimilarGroup(id: "g", members: ["keeper", "fav", "a"], best: "keeper", reason: .exactDuplicate)
        group.markedByPerson = ["fav"]
        XCTAssertTrue(SimilarGroupSelection(group: group) { $0 == "a" }.areAllExtrasQueued)
        XCTAssertTrue(SimilarGroupSelection(group: group) { _ in false }.canSelectExtras)

        group.markedByPerson = ["fav", "a"]
        let allMarked = SimilarGroupSelection(group: group) { _ in false }
        XCTAssertFalse(allMarked.canSelectExtras)
        XCTAssertFalse(allMarked.areAllExtrasQueued)
    }
}
