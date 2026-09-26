// Why: a similar-photo card must describe the basket as it is. These tests pin that a queued keeper is shown
// as queued and counted, so the card never says "Keeping all" while Review would take a photo from it.
import XCTest

@testable import Roomy

final class SimilarGroupSelectionTests: XCTestCase {
    private let group = SimilarGroup(id: "g", members: ["keeper", "a", "b"], best: "keeper", reason: .exactDuplicate)

    /// Regression: with its keeper queued the card said "Keeping all 3" and drew the keeper with no checkmark.
    func testAQueuedKeeperIsShownAndCounted() {
        let selection = SimilarGroupSelection(group: group) { $0 == "keeper" }

        XCTAssertTrue(selection.isKeeperQueued)
        XCTAssertEqual(selection.tileState(for: "keeper"), .bestSelected)
        XCTAssertEqual(selection.footer(queuedSize: SizeTotal(unknownCount: 1)), "Keep 2 · Remove 1 · size unavailable")
        XCTAssertFalse(selection.areAllExtrasQueued)
    }

    func testFooterNamesWhatWouldGoAndNeverAMadeUpSize() {
        let nothing = SimilarGroupSelection(group: group) { _ in false }
        XCTAssertEqual(nothing.footer(queuedSize: SizeTotal()), "Keeping all 3")
        XCTAssertEqual(nothing.tileState(for: "keeper"), .best)

        let extras = SimilarGroupSelection(group: group) { $0 != "keeper" }
        XCTAssertTrue(extras.areAllExtrasQueued)
        XCTAssertEqual(extras.tileState(for: "a"), .selected)
        let known = SizeTotal(knownBytes: 2_000_000, knownCount: 2)
        XCTAssertEqual(extras.footer(queuedSize: known), "Keep 1 · Remove 2 · \(Int64(2_000_000).byteString)")
    }

    func testGroupToggleReadsSelectExtrasUntilTheyAllAreIn() {
        let nothing = SimilarGroupSelection(group: group) { _ in false }
        XCTAssertEqual(nothing.extrasToggleTitle, "Select extras")
        XCTAssertEqual(nothing.extrasToggleState, .off)
        let oneExtra = SimilarGroupSelection(group: group) { $0 == "a" }
        XCTAssertEqual(oneExtra.extrasToggleState, .off, "the group toggle is on or off; months show the mix")
        let extras = SimilarGroupSelection(group: group) { $0 != "keeper" }
        XCTAssertEqual(extras.extrasToggleTitle, "Extras selected")
        XCTAssertEqual(extras.extrasToggleState, .on)
    }

    /// "Keep N" counts every member that stays, so a queued keeper is not counted as kept.
    func testKeptCountIsMembersLessQueued() {
        let keeperAndOne = SimilarGroupSelection(group: group) { $0 == "keeper" || $0 == "a" }
        XCTAssertEqual(keeperAndOne.keptCount, 1)
        XCTAssertEqual(
            keeperAndOne.footer(queuedSize: SizeTotal(unknownCount: 2)), "Keep 1 · Remove 2 · size unavailable")

        let everything = SimilarGroupSelection(group: group) { _ in true }
        XCTAssertEqual(everything.keptCount, 0)
    }
}
