// Why: the dashboard's one bottom action decides between scanning and Review, and whether they split. Each
// Figma state (option A, A1–A9) is pinned here, so a rule change can never hide Review or leave no action.
import XCTest

@testable import Roomy

final class DashboardBottomActionTests: XCTestCase {
    private let volume = VolumeStats(total: 100_000, free: 50_000)
    private let reviewTitle = "Review 128 items · 2.1 GB"

    private func action(
        _ phase: ScanPhase, canUseLibrary: Bool = true, review: String? = nil, isReady: Bool = true,
        index: IndexProgress = IndexProgress()
    ) -> DashboardBottomAction {
        let summary = DashboardSummary(
            phase: phase, volume: volume, canUseLibrary: canUseLibrary, indexProgress: index)
        return DashboardBottomAction(summary: summary, reviewTitle: review, isReviewReady: isReady)
    }

    func testWithNothingSavedTheCapsuleIsTheScanAction() {
        XCTAssertEqual(action(.idle).capsule, .scan(.start))
        XCTAssertEqual(action(.indexing).capsule, .scan(.cancel))
        XCTAssertEqual(action(.comparing).capsule, .scan(.cancel))
        XCTAssertEqual(action(.stopped).capsule, .scan(.resume))
        XCTAssertEqual(action(.done).capsule, .scan(.again))
        XCTAssertNil(action(.done).roundScan, "one action, so nothing splits")
    }

    func testStartAndResumeAreProminentWhileCancelAndRescanStayQuiet() {
        XCTAssertEqual(action(.idle).capsule?.title, "Scan for space")
        XCTAssertTrue(action(.idle).capsule?.isProminent == true)
        XCTAssertEqual(action(.stopped).capsule?.title, "Resume scan")
        XCTAssertTrue(action(.stopped).capsule?.isProminent == true)
        XCTAssertEqual(action(.indexing).capsule?.title, "Cancel scan")
        XCTAssertTrue(action(.indexing).capsule?.isProminent == false)
        XCTAssertEqual(action(.done).capsule?.title, "Scan again")
        XCTAssertTrue(action(.done).capsule?.isProminent == false)
    }

    func testSavedItemsTakeTheCapsuleAndTheScanActionMovesBesideIt() {
        let savedDone = action(.done, review: reviewTitle)
        XCTAssertEqual(savedDone.capsule, .review(title: reviewTitle, isProminent: true))
        XCTAssertEqual(savedDone.capsule?.systemImage, "checklist")
        XCTAssertEqual(savedDone.roundScan, .again)

        let savedScanning = action(.comparing, review: reviewTitle)
        XCTAssertEqual(savedScanning.roundScan, .cancel, "Review never hides Cancel, and Cancel never hides Review")
        XCTAssertEqual(action(.stopped, review: reviewTitle).roundScan, .resume)
    }

    func testOnlyHeldItemsKeepReviewQuiet() {
        let held = action(.done, review: "Review · 3 on hold", isReady: false)
        XCTAssertEqual(held.capsule, .review(title: "Review · 3 on hold", isProminent: false))
    }

    func testWithoutPhotosAccessThereIsNoScanAction() {
        XCTAssertNil(action(.idle, canUseLibrary: false).capsule, "the notice's Settings is the action")
        let savedContacts = action(.idle, canUseLibrary: false, review: reviewTitle)
        XCTAssertEqual(savedContacts.capsule, .review(title: reviewTitle, isProminent: true))
        XCTAssertNil(savedContacts.roundScan)
    }

    func testProgressFillsOnlyWithRealCountsWhileScanning() {
        XCTAssertNil(action(.indexing).progress, "no counts yet, so no bar at a made-up zero")
        let counted = action(.indexing, index: IndexProgress(scanned: 21, total: 100))
        XCTAssertEqual(counted.progress ?? -1, 0.21, accuracy: 0.000_1)
        XCTAssertTrue(counted.progressValue?.contains("21") == true)
        XCTAssertNil(action(.done, index: IndexProgress(scanned: 100, total: 100)).progress)
    }

    func testArrangementIgnoresProgressAndCountsSoTheMorphRunsOnlyOnRealChanges() {
        let early = action(.indexing, review: "Review 1 item", index: IndexProgress(scanned: 1, total: 100))
        let later = action(.indexing, review: "Review 2 items", index: IndexProgress(scanned: 50, total: 100))
        XCTAssertEqual(early.arrangement, later.arrangement)
        XCTAssertNotEqual(action(.indexing).arrangement, action(.done).arrangement)
    }
}
