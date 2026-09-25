// Why: the words on the destructive button, its confirmation and the result screen are product promises.
// These tests pin them to the counts and measurements they come from.
import XCTest

@testable import Roomy

final class ReviewSummaryTests: XCTestCase {
    func testButtonSaysExactlyWhatWillHappen() {
        let photosOnly = ReviewSummary(assetCount: 1, bytes: 2_000_000)
        XCTAssertEqual(photosOnly.actionTitle, "Delete 1 item · 2\u{00A0}MB")
        XCTAssertEqual(photosOnly.confirmButton, "Delete 1 Item")
        XCTAssertFalse(photosOnly.confirmMessage.contains("contact"))

        let contactsOnly = ReviewSummary(contactGroupCount: 2)
        XCTAssertEqual(contactsOnly.actionTitle, "Merge 2 groups")
        XCTAssertFalse(contactsOnly.confirmMessage.contains("Recently Deleted"))

        let both = ReviewSummary(assetCount: 3, contactGroupCount: 1, bytes: 10)
        XCTAssertEqual(both.confirmTitle, "Delete 3 items and merge 1 group?")
        XCTAssertTrue(both.confirmMessage.contains("Recently Deleted"))
        XCTAssertTrue(both.confirmMessage.contains("backup"))
    }

    /// Regression: the confirmation promised one iOS prompt, but every 1,000 items bring another.
    func testConfirmationSaysHowManyTimesIOSWillAsk() {
        XCTAssertTrue(ReviewSummary(assetCount: 1_000).confirmMessage.contains("iOS will ask you once more."))
        XCTAssertTrue(ReviewSummary(assetCount: 2_600).confirmMessage.contains("iOS will ask you 3 times"))
    }

    func testNoSizeIsNeverShownAsZero() {
        let unknown = ReviewSummary(items: [BasketItem(id: "clip", kind: .video, bytes: nil)])
        XCTAssertEqual(unknown.actionTitle, "Delete 1 item")
        XCTAssertEqual(unknown.totalValue, "1 item")
    }

    func testTheConfirmationSaysNotesAreNotKept() {
        XCTAssertTrue(
            ReviewSummary(contactGroupCount: 1).confirmMessage.contains("Notes"),
            "regression: notes loss was not disclosed at the last step before the merge")
    }
}

final class ResultSummaryTests: XCTestCase {
    func testMovedIsNotFreedUntilMeasured() {
        let report = CleanupReport(assets: AssetRemoval(removedIDs: ["a", "b"]), removedBytes: 3_000_000)
        let waiting = ResultSummary(report: report)
        XCTAssertEqual(waiting.stage, .waiting)
        XCTAssertEqual(waiting.title, "Moved 2 items")
        XCTAssertEqual(waiting.mood, .pleased)

        let reclaimed = ResultSummary(report: report, reclaimedBytes: 2_900_000)
        XCTAssertEqual(reclaimed.title, "Free space went up", "a measured rise, never a cause Roomy didn't see")
        XCTAssertEqual(reclaimed.mood, .success, "success only after free space was measured again")
    }

    func testFailuresAreNamedHonestly() {
        let timedOut = ResultSummary(report: CleanupReport(assets: AssetRemoval(stop: .timedOut)))
        XCTAssertEqual(timedOut.title, "Photos didn't answer")
        XCTAssertEqual(timedOut.mood, .error)

        var mergedButDeclined = CleanupReport(assets: AssetRemoval(stop: .declined))
        mergedButDeclined.contacts = ContactMergeResult(mergedGroupIDs: ["g1"])
        XCTAssertTrue(
            ResultSummary(report: mergedButDeclined).text.contains("Don't Allow"),
            "regression: a merge must not hide that the photos were declined")

        var partial = CleanupReport()
        partial.contacts = ContactMergeResult(mergedGroupIDs: ["g1"], failedGroupIDs: ["g2"])
        let summary = ResultSummary(report: partial)
        XCTAssertEqual(summary.stage, .mergedOnly)
        XCTAssertTrue(summary.text.contains("1 contact group couldn't be merged"))
        XCTAssertTrue(summary.text.contains("Each merged group is now one card"))
    }

    func testUnmergedContactGroupsSayWhy() {
        var changed = CleanupReport()
        changed.contacts = ContactMergeResult(changedGroupIDs: ["g1"])
        let changedSummary = ResultSummary(report: changed)
        XCTAssertEqual(changedSummary.title, "Couldn't finish")
        XCTAssertTrue(changedSummary.text.contains("changed after the scan"))
        XCTAssertFalse(changedSummary.text.contains("no longer there"))

        var refused = CleanupReport()
        refused.contacts = ContactMergeResult(refusedGroupIDs: ["g1", "g2"])
        XCTAssertTrue(ResultSummary(report: refused).text.contains("Contacts wouldn't save 2 contact groups"))
    }

    /// Regression: items missing from the library were reported as "Moved N items".
    func testItemsThatWereNotThereAreNeverCalledMoved() {
        let report = CleanupReport(assets: AssetRemoval(unavailableIDs: ["a", "b"]))
        let summary = ResultSummary(report: report)
        XCTAssertEqual(summary.title, "Nothing changed")
        XCTAssertTrue(summary.text.contains("2 items weren't in the photos Roomy can see"))
        XCTAssertFalse(summary.text.contains("no longer there"))
    }

    /// Regression: an unrelated rise, or one that resolved an older cleanup, was announced in full on this result.
    func testIsBackIsCappedAndOnlyForACleanupThatMovedSomething() {
        let moved = CleanupReport(assets: AssetRemoval(removedIDs: ["a"]), removedBytes: 40_000_000)
        XCTAssertEqual(ResultSummary(report: moved, reclaimedBytes: 2_000_000_000).stage, .reclaimed(40_000_000))

        let merged = CleanupReport(contacts: ContactMergeResult(mergedGroupIDs: ["g1"]))
        XCTAssertEqual(ResultSummary(report: merged, reclaimedBytes: 1_000).stage, .mergedOnly)
    }

    /// Regression: confirmed merges Roomy couldn't resolve disappeared from a mixed result without a word.
    func testMergesThatDidNotRunAreNamed() {
        let report = CleanupReport(
            assets: AssetRemoval(removedIDs: ["a"]), removedBytes: 10, held: HeldItems(waitingForContacts: 3))
        let summary = ResultSummary(report: report)
        XCTAssertEqual(summary.title, "Moved 1 item")
        XCTAssertTrue(summary.text.contains("3 contact merges didn't run"))
    }
}

extension ResultSummary {
    /// Everything the result says, lead and rows, for tests that check a sentence is there.
    var text: String { ([lead].compactMap { $0 } + lines.map(\.text)).joined(separator: " ") }
}
