// Why: the plan must match what Review showed and never empty a group of similar photos, and sizes must read
// the way Settings does. These tests pin both rules in the pure models, where they are cheap to check.
import XCTest

@testable import Roomy

final class CleanupPlanTests: XCTestCase {
    func testPlanSplitsAssetsFromMergesAndSkipsVanishedGroups() {
        let group = ContactGroup(id: "g1", primary: "a", extras: ["b"], reason: .samePhone)
        let items = [
            BasketItem(id: "clip", kind: .video, bytes: 900),
            BasketItem(id: "shot", kind: .screenshot, bytes: nil),
            BasketItem(id: "g1", kind: .contactGroup, bytes: nil),
            BasketItem(id: "gone", kind: .contactGroup, bytes: nil),
        ]
        let plan = CleanupPlan.make(items: items, contactGroups: ["g1": group])
        XCTAssertEqual(plan.assetIDs, ["clip", "shot"])
        XCTAssertEqual(plan.assetBytes, 900, "an unknown size counts as zero, never a guess")
        XCTAssertEqual(plan.contactGroups, [group])
        XCTAssertEqual(plan.sparedIDs, [], "screenshots and videos are never held back")
    }

    /// Regression: a queued keeper (the keeper changed after a rescan) went into the plan with its extras, so
    /// "Select extras" deleted every copy of the moment.
    func testPlanNeverEmptiesAGroupOfSimilarPhotos() {
        let full = SimilarGroup(id: "g1", members: ["k", "a", "b"], best: "k", reason: .exactDuplicate)
        let kept = SimilarGroup(id: "g2", members: ["k2", "c"], best: "k2", reason: .exactDuplicate)
        let items =
            ["a", "b", "k", "c", "lone"].map { BasketItem(id: $0, kind: .photo, bytes: 100) }
            + [BasketItem(id: "shot", kind: .screenshot, bytes: 100)]

        let plan = CleanupPlan.make(items: items, contactGroups: [:], similarGroups: [full, kept])

        XCTAssertEqual(plan.assetIDs, ["a", "b", "c", "shot"])
        XCTAssertEqual(plan.sparedIDs, ["k", "lone"], "the keeper stays, and so does a photo in no group")
        XCTAssertEqual(plan.assetBytes, 400, "spared photos are not counted as going")
        XCTAssertEqual(plan.similarGroups, [["k", "a", "b"], ["k2", "c"], ["lone"]], "keeper first")
    }

    func testEveryThousandAssetsTakesOneMorePrompt() {
        XCTAssertEqual(CleanupPlan.promptCount(forAssets: 0), 0)
        XCTAssertEqual(CleanupPlan.promptCount(forAssets: 1_000), 1)
        XCTAssertEqual(CleanupPlan.promptCount(forAssets: 1_001), 2)
        XCTAssertEqual(CleanupPlan.promptCount(forAssets: 2_600), 3)
    }

    func testCountedPluralises() {
        XCTAssertEqual(1.counted("item"), "1 item")
        XCTAssertEqual(3.counted("item"), "3 items")
    }
}

final class ByteCountTests: XCTestCase {
    func testSizesUseSettingsUnitsAndNeverSpellOutZero() {
        XCTAssertEqual(Int64(0).byteString, "0\u{00A0}KB")
        XCTAssertEqual(Int64(26_000).byteString, "26\u{00A0}KB")
        XCTAssertEqual(Int64(2_100_000_000).byteString, "2.1\u{00A0}GB")
    }
}
