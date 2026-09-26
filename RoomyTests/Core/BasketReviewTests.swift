// Why: Review may only offer and count what a cleanup can really do. These tests pin which saved items wait —
// photos without Photos access, similar photos before the library is compared, merges Roomy can't see — and
// that the counts and the confirmation leave them out.
import XCTest

@testable import Roomy

final class BasketReviewTests: XCTestCase {
    private let items = [
        BasketItem(id: "photo", kind: .photo, bytes: 100),
        BasketItem(id: "shot", kind: .screenshot, bytes: 200),
        BasketItem(id: "clip", kind: .video, bytes: nil),
        BasketItem(id: "merge", kind: .contactGroup, bytes: nil),
        BasketItem(id: "stale", kind: .contactGroup, bytes: nil),
    ]

    /// Regression: with Photos access off, a saved basket still offered its photos for deletion.
    func testPhotosWaitWhilePhotosAccessIsOff() {
        let review = BasketReview(
            items: items, canUsePhotos: false, canCheckSimilarGroups: false, mergeableGroupIDs: ["merge"])

        XCTAssertEqual(review.waitingForPhotos.map(\.id), ["clip", "photo", "shot"])
        XCTAssertEqual(review.ready.map(\.id), ["merge"])
        XCTAssertEqual(ReviewSummary(items: review.ready).assetCount, 0)
        XCTAssertEqual(review.summary, "1 item", "a size that can't be deleted isn't counted, and 0 KB isn't shown")
    }

    func testSimilarPhotosWaitUntilTheLibraryHasBeenCompared() {
        let comparing = BasketReview(
            items: items, canUsePhotos: true, canCheckSimilarGroups: false, mergeableGroupIDs: ["merge"])
        XCTAssertEqual(comparing.waitingForComparison.map(\.id), ["photo"])
        XCTAssertEqual(comparing.ready.map(\.id), ["clip", "merge", "shot"], "screenshots and videos can go now")

        let compared = BasketReview(
            items: items, canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: ["merge"])
        XCTAssertEqual(compared.ready.map(\.id), ["clip", "merge", "photo", "shot"])
        XCTAssertEqual(compared.summary, "4 items · \(Int64(300).byteString)", "known sizes only")
    }

    /// Regression: merges Roomy couldn't resolve were listed as "Contact — Merge 2 cards into 1" and counted in
    /// "Merge 3 groups?".
    func testMergesRoomyCannotSeeAreNeverCountedOrConfirmed() {
        let review = BasketReview(
            items: items, canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: ["merge"])
        XCTAssertEqual(review.waitingForContacts.map(\.id), ["stale"])
        XCTAssertEqual(review.ready(of: .contactGroup).map(\.id), ["merge"])

        let summary = ReviewSummary(items: review.ready)
        XCTAssertEqual(summary.contactGroupCount, 1)
        XCTAssertEqual(summary.confirmTitle, "Delete 3 items and merge 1 group?")
    }

    /// Regression: an item kept only in iCloud could be selected and deleted, removing it from iCloud and every
    /// device while freeing nothing here. Selected before the scope changed, it now waits and is never deleted.
    func testICloudOnlyItemsWaitAndNeverReachTheCleanup() {
        let saved = [
            BasketItem(id: "cloud", kind: .video, bytes: 0, bytesInCloud: 3_000),
            BasketItem(id: "local", kind: .screenshot, bytes: 100),
        ]
        let review = BasketReview(
            items: saved, canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: [], scope: .onThisPhone)
        XCTAssertEqual(review.onlyInICloud.map(\.id), ["cloud"])
        XCTAssertEqual(review.ready.map(\.id), ["local"])
        XCTAssertEqual(review.heldCount, 1)

        let plan = CleanupPlan.make(confirmed: review, contactGroups: [:], similarGroups: [])
        XCTAssertEqual(plan.assetIDs, ["local"])
        XCTAssertEqual(plan.held.onlyInICloud, 1)

        let included = BasketReview(
            items: saved, canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: [],
            scope: .includingICloud)
        XCTAssertEqual(included.ready.map(\.id), ["cloud", "local"])
    }

    func testNothingWaitsOnceEverythingCanRun() {
        let review = BasketReview(
            items: items, canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: ["merge", "stale"])
        XCTAssertEqual(review.ready.count, items.count)
        XCTAssertFalse(review.isEmpty)
        XCTAssertTrue(
            BasketReview(items: [], canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: []).isEmpty)
    }

    /// Regression: with every saved item on hold the Review capsule vanished, so the hold notes and their
    /// "Remove from Review", "Scan now" and "Allow" actions could not be reached.
    func testReviewStaysReachableWhenEverythingIsOnHold() {
        let held = BasketReview(
            items: items, canUsePhotos: false, canCheckSimilarGroups: false, mergeableGroupIDs: [])
        XCTAssertTrue(held.ready.isEmpty)
        XCTAssertEqual(held.heldCount, 5)
        XCTAssertEqual(held.barTitle, "Review · 5 on hold", "held items are never counted as ready")

        let mixed = BasketReview(
            items: items, canUsePhotos: true, canCheckSimilarGroups: false, mergeableGroupIDs: ["merge"])
        XCTAssertEqual(mixed.barTitle, "Review \(mixed.summary)")
        XCTAssertNil(
            BasketReview(items: [], canUsePhotos: true, canCheckSimilarGroups: true, mergeableGroupIDs: []).barTitle)
    }
}
