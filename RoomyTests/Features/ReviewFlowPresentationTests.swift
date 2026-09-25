// Why: the delete flow's presentation rules are product promises too — the note that guards the red button,
// the steps a running cleanup claims as done, the initials on a merge row, and a partial result read as a list.
// These tests pin each one to the data it comes from.
import XCTest

@testable import Roomy

final class ReviewFlowPresentationTests: XCTestCase {
    /// The dock's note is the confirmation's first sentence, never new copy.
    func testDockNoteIsTheConfirmationsFirstSentence() throws {
        let photos = ReviewSummary(assetCount: 2, contactGroupCount: 1)
        let photosNote = try XCTUnwrap(photos.dockNote)
        XCTAssertEqual(photosNote, "Photos and videos move to Recently Deleted and stay there for 30 days.")
        XCTAssertTrue(photos.confirmMessage.hasPrefix(photosNote))

        let contacts = ReviewSummary(contactGroupCount: 1)
        let contactsNote = try XCTUnwrap(contacts.dockNote)
        XCTAssertTrue(contacts.confirmMessage.hasPrefix(contactsNote))
        XCTAssertNil(ReviewSummary().dockNote)
    }

    func testPlannedStepsFollowTheConfirmedItems() {
        XCTAssertEqual(
            CleanupProgress.planned(for: ReviewSummary(assetCount: 1, contactGroupCount: 1)),
            [.mergingContacts, .removingPhotos])
        XCTAssertEqual(CleanupProgress.planned(for: ReviewSummary(assetCount: 1)), [.removingPhotos])
        XCTAssertEqual(CleanupProgress.planned(for: ReviewSummary(contactGroupCount: 1)), [.mergingContacts])
    }

    func testStepsShowDoneActiveAndNext() {
        let both: [CleanupStep] = [.mergingContacts, .removingPhotos]
        let merging = CleanupProgress(planned: both, current: .mergingContacts, seen: [.mergingContacts])
        XCTAssertEqual(merging.rows.map(\.state), [.active, .upcoming])

        let photos = CleanupProgress(planned: both, current: .removingPhotos, seen: [.mergingContacts])
        XCTAssertEqual(photos.rows.map(\.state), [.done, .active])
    }

    /// A planned merge that never ran must not earn a check mark.
    func testAStepThatWasNeverSeenIsNotCalledDone() {
        let progress = CleanupProgress(
            planned: [.mergingContacts, .removingPhotos], current: .removingPhotos, seen: [])
        XCTAssertEqual(progress.rows.map(\.step), [.removingPhotos])
    }

    func testTheRunningStepAlwaysShows() {
        let progress = CleanupProgress(planned: [], current: .removingPhotos, seen: [])
        XCTAssertEqual(progress.rows, [CleanupProgress.Row(step: .removingPhotos, state: .active)])
    }

    func testInitialsComeOnlyFromTheName() {
        XCTAssertEqual(ContactInitials.of("Anna Müller"), "AM")
        XCTAssertEqual(ContactInitials.of("david"), "D")
        XCTAssertEqual(ContactInitials.of("Mary Ann van Dyke"), "MD")
        XCTAssertNil(ContactInitials.of(""))
        XCTAssertNil(ContactInitials.of("+1 555 0100"))
    }

    /// The design's partial result: the lead stays in the hero, every other sentence is a row, in order.
    func testAPartialResultReadsAsAList() {
        var report = CleanupReport(
            assets: AssetRemoval(removedIDs: ["a"], unavailableIDs: ["b"], stop: .declined), removedBytes: 10,
            held: HeldItems(waitingForContacts: 1))
        report.contacts = ContactMergeResult(mergedGroupIDs: ["g1"], failedGroupIDs: ["g2"])
        let summary = ResultSummary(report: report)

        XCTAssertEqual(summary.lead?.hasPrefix("They're in Recently Deleted"), true)
        XCTAssertEqual(summary.lines.map(\.kind), [.stopped, .notFound, .held, .merged, .contactsLeft])
        XCTAssertFalse(summary.lines.contains { $0.text == summary.lead }, "the lead is never repeated as a row")
    }

    func testAWholeResultHasNoRows() {
        let report = CleanupReport(assets: AssetRemoval(removedIDs: ["a"]), removedBytes: 10)
        XCTAssertTrue(ResultSummary(report: report, reclaimedBytes: 10).lines.isEmpty)
    }
}
