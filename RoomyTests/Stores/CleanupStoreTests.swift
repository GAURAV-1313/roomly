// Why: the cleanup is the one destructive flow. These tests run it end to end against a fake cleaner:
// what gets remembered as pending, when it counts as freed and never for more than was moved, that a declined
// prompt or missing access changes nothing, and that items that weren't there are never "moved".
import XCTest

@testable import Roomy

final class CleanupStoreTests: XCTestCase {
    private let group = ContactGroup(id: "g1", primary: "a", extras: ["b"], reason: .samePhone)
    private let day: TimeInterval = 24 * 60 * 60

    @MainActor
    func testContactsMergeBeforePhotosAndRemovedSpaceIsPending() async {
        let cleaner = FakeCleaner()
        let store = makeStore(cleaner)
        let plan = CleanupPlan(assetIDs: ["x", "y"], bytesByID: ["x": 300, "y": 700], contactGroups: [group])

        let report = await store.run(plan, freeBefore: 5_000)

        XCTAssertEqual(cleaner.callLog, ["merge", "remove"])
        XCTAssertEqual(report.removedBytes, 1_000)
        XCTAssertEqual(report.mergedCount, 1)
        XCTAssertEqual(store.pending?.bytes, 1_000)
        XCTAssertEqual(store.state, .finished(report))
    }

    @MainActor
    func testDeclinedPromptLeavesNothingPending() async {
        let store = makeStore(FakeCleaner(removal: AssetRemoval(removedIDs: [], stop: .declined)))
        let report = await store.run(CleanupPlan(assetIDs: ["x"], bytesByID: ["x": 10]), freeBefore: 5_000)

        XCTAssertEqual(report.assets.stop, .declined)
        XCTAssertNil(store.pending)
        XCTAssertEqual(ResultSummary(report: report).title, "Nothing was deleted")
    }

    /// Regression: an item missing from the library was reported as moved and its size added to the pending space.
    @MainActor
    func testItemsMissingFromTheLibraryAreNeverCountedAsMoved() async {
        let store = makeStore(FakeCleaner(missing: ["gone"]))
        let plan = CleanupPlan(assetIDs: ["gone", "x"], bytesByID: ["gone": 700, "x": 300])

        let report = await store.run(plan, freeBefore: 5_000)

        XCTAssertEqual(report.assets.removedIDs, ["x"])
        XCTAssertEqual(report.assets.unavailableIDs, ["gone"])
        XCTAssertEqual(report.removedBytes, 300)
        XCTAssertEqual(store.pending?.bytes, 300)
    }

    @MainActor
    func testWithoutPhotosAccessNothingIsAskedAndTheResultSaysWhy() async {
        let cleaner = FakeCleaner()
        let store = makeStore(cleaner)
        let plan = CleanupPlan.make(
            confirmed: BasketReview(
                items: [
                    BasketItem(id: "x", kind: .video, bytes: 10), BasketItem(id: "y", kind: .screenshot, bytes: 5),
                ],
                canUsePhotos: false, canCheckSimilarGroups: true, mergeableGroupIDs: []),
            contactGroups: [:], similarGroups: [])
        let report = await store.run(plan, freeBefore: 5_000)

        XCTAssertTrue(cleaner.callLog.isEmpty, "nothing is asked of Photos without access")
        XCTAssertEqual(report.held.waitingForPhotos, 2)
        XCTAssertEqual(report.removedCount, 0)
        XCTAssertNil(store.pending)
        let summary = ResultSummary(report: report)
        XCTAssertEqual(summary.title, "Nothing changed")
        XCTAssertFalse(summary.text.contains("Moved"))
        XCTAssertTrue(summary.text.contains("Photos access is off, so 2 items weren't deleted"))
    }

    /// Regression: the keeper was deleted in Photos, and the cleanup took the last photo of the group with it.
    @MainActor
    func testTheLastPhotoOfAGroupIsNeverRemoved() async {
        let similar = SimilarGroup(id: "s1", members: ["keeper", "extra"], best: "keeper", reason: .exactDuplicate)
        let plan = CleanupPlan.make(
            items: [BasketItem(id: "extra", kind: .photo, bytes: 500)], contactGroups: [:], similarGroups: [similar])
        let store = makeStore(FakeCleaner(missing: ["keeper"]))

        let report = await store.run(plan, freeBefore: 5_000)

        XCTAssertEqual(report.assets.removedIDs, [])
        XCTAssertEqual(report.assets.sparedIDs, ["extra"])
        XCTAssertNil(store.pending)
    }

    @MainActor
    func testPendingSurvivesARelaunchAndClearsOnceSpaceIsBack() async {
        let filename = temporaryFilename()
        let store = CleanupStore(cleaner: FakeCleaner(), filename: filename)
        _ = await store.run(CleanupPlan(assetIDs: ["x"], bytesByID: ["x": 1_000]), freeBefore: 5_000)

        let relaunched = CleanupStore(cleaner: FakeCleaner(), filename: filename)
        XCTAssertEqual(relaunched.pending?.bytes, 1_000)

        relaunched.measure(freeNow: 5_100)
        XCTAssertNotNil(relaunched.pending, "a small rise is not the cleanup")
        relaunched.measure(freeNow: 6_050)
        XCTAssertEqual(relaunched.reclaimedBytes, 1_000, "never more than the cleanup moved")
        XCTAssertNil(relaunched.pending)
    }

    /// Regression: an unrelated 2 GB rise (a game deleted) cleared the "40 MB in Recently Deleted" reminder and
    /// was announced as the cleanup's space, though the items were still there.
    @MainActor
    func testAnUnrelatedRiseNeverClearsTheReminder() async {
        let filename = temporaryFilename()
        let store = CleanupStore(cleaner: FakeCleaner(), filename: filename)
        _ = await store.run(CleanupPlan(assetIDs: ["x"], bytesByID: ["x": 40_000_000]), freeBefore: 10_000_000_000)

        store.measure(freeNow: 12_000_000_000)
        XCTAssertNil(store.reclaimedBytes, "a rise far bigger than what was moved names no cause")
        XCTAssertEqual(store.pending?.bytes, 40_000_000, "the reminder stays")
        XCTAssertEqual(store.pending?.isUncertain, true, "the rise may have included emptying Recently Deleted")
        let relaunched = CleanupStore(cleaner: FakeCleaner(), filename: filename).pending
        XCTAssertEqual(relaunched?.freeBefore, 12_000_000_000)
        XCTAssertEqual(relaunched?.isUncertain, true)

        store.measure(freeNow: 12_041_000_000)
        XCTAssertEqual(store.reclaimedBytes, 40_000_000, "emptying Recently Deleted later is measured from there")
        XCTAssertNil(store.pending)
    }

    @MainActor
    func testACleanupWithNoKnownSizeIsNotRemembered() async {
        let store = makeStore(FakeCleaner())
        let report = await store.run(CleanupPlan(assetIDs: ["x"]), freeBefore: 5_000)

        XCTAssertEqual(report.removedCount, 1)
        XCTAssertNil(store.pending)
        store.measure(freeNow: 90_000)
        XCTAssertNil(store.reclaimedBytes, "no rise is credited to a cleanup of unknown size")
    }

    /// Regression: a second cleanup kept the first one's date, so its reminder vanished 30 days after the first.
    @MainActor
    func testANewerCleanupKeepsItsOwnThirtyDays() async {
        let store = makeStore(FakeCleaner())
        let first = CleanupPlan(assetIDs: ["x"], bytesByID: ["x": 2_000])
        let second = CleanupPlan(assetIDs: ["y"], bytesByID: ["y": 3_000])
        _ = await store.run(first, freeBefore: 10_000, at: Date(timeIntervalSince1970: 0))
        _ = await store.run(second, freeBefore: 9_000, at: Date(timeIntervalSince1970: 28 * day))

        store.measure(freeNow: 11_000, at: Date(timeIntervalSince1970: 31 * day))
        XCTAssertNil(store.reclaimedBytes, "iOS emptying the first cleanup is not the second one's space")
        XCTAssertEqual(store.pending?.bytes, 3_000)

        store.measure(freeNow: 11_000, at: Date(timeIntervalSince1970: 59 * day))
        XCTAssertNil(store.pending)
    }

    @MainActor
    func testDismissingNeverInterruptsARunningCleanup() async {
        let store = makeStore(FakeCleaner())
        store.dismissResult()
        XCTAssertEqual(store.state, .idle)
        _ = await store.run(CleanupPlan(contactGroups: [group]), freeBefore: 0)
        store.dismissResult()
        XCTAssertEqual(store.state, .idle)
    }

    @MainActor
    private func makeStore(_ cleaner: FakeCleaner) -> CleanupStore {
        CleanupStore(cleaner: cleaner, filename: temporaryFilename())
    }

    private func temporaryFilename() -> String {
        let filename = "test-pending-\(UUID().uuidString).json"
        addTeardownBlock { JSONFileStore<PendingReclaim>(filename: filename).delete() }
        return filename
    }
}
