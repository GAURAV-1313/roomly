// Why: folded months must still say what they hold and how much of it is selected, and the fold rules (newest
// open, a "Collapse all" row only with many months) must not drift. These tests pin the month row's words, its
// toggle's three states and the fold-all row.
import XCTest

@testable import Roomy

final class MonthListPresentationTests: XCTestCase {
    private let size = SizeTotal(knownBytes: 17_000_000, knownCount: 11)

    func testSimilarMonthSummaryCountsGroupsExtrasAndSize() {
        let month = MonthSummary.similar(
            month: "August 2026", groupCount: 4, extraCount: 11, selectedCount: 0, size: size)
        XCTAssertEqual(month.summary, "4 groups · 11 extras · \(size.text)")
        let single = MonthSummary.similar(
            month: "July 2026", groupCount: 1, extraCount: 1, selectedCount: 0, size: SizeTotal(unknownCount: 1))
        XCTAssertEqual(single.summary, "1 group · 1 extra · size unavailable")
    }

    func testScreenshotsMonthSummaryIsCountAndSize() {
        let month = MonthSummary.screenshots(month: "September 2026", count: 24, selectedCount: 0, size: size)
        XCTAssertEqual(month.summary, "24 · \(size.text)")
        XCTAssertEqual(month.toggleAccessibilityLabel, "Select screenshots in September 2026")
    }

    func testToggleReadsSelectMixedOrSelected() {
        func month(_ selected: Int) -> MonthSummary {
            .similar(month: "August 2026", groupCount: 4, extraCount: 11, selectedCount: selected, size: size)
        }
        XCTAssertEqual(month(0).toggleTitle, "Select 11")
        XCTAssertEqual(month(0).toggleState, .off)
        XCTAssertEqual(month(0).toggleAccessibilityValue, "")
        XCTAssertEqual(month(7).toggleTitle, "7 of 11")
        XCTAssertEqual(month(7).toggleState, .mixed)
        XCTAssertEqual(month(7).toggleAccessibilityLabel, "Select extras in August 2026")
        XCTAssertEqual(month(7).toggleAccessibilityValue, "7 of 11 selected")
        XCTAssertEqual(month(11).toggleTitle, "11 selected")
        XCTAssertEqual(month(11).toggleState, .on)
    }

    /// A month whose extras the person all marked in Photos has nothing for its toggle to select.
    func testAMonthWithNothingToSelectHasNoToggle() {
        let month = MonthSummary.similar(month: "June 2026", groupCount: 1, extraCount: 0, selectedCount: 0, size: size)
        XCTAssertFalse(month.showsToggle)
    }

    func testFoldAllRowShowsOnlyWithMoreThanThreeMonths() {
        XCTAssertFalse(MonthFolding(ids: ["Sep", "Aug", "Jul"], collapsed: []).showsFoldAllRow)
        let four = MonthFolding(ids: ["Sep", "Aug", "Jul", "Jun"], collapsed: ["Aug", "Jul", "Jun"])
        XCTAssertTrue(four.showsFoldAllRow)
        XCTAssertEqual(four.countLabel, "4 months")
    }

    func testFoldAllCollapsesWhileAnyMonthIsOpenThenExpands() {
        let ids = ["Sep", "Aug", "Jul", "Jun"]
        let oneOpen = MonthFolding(ids: ids, collapsed: ["Aug", "Jul", "Jun"])
        XCTAssertEqual(oneOpen.foldAllTitle, "Collapse all")
        XCTAssertEqual(oneOpen.afterFoldAll, Set(ids))
        let allFolded = MonthFolding(ids: ids, collapsed: Set(ids))
        XCTAssertEqual(allFolded.foldAllTitle, "Expand all")
        XCTAssertEqual(allFolded.afterFoldAll, [])
    }

    func testTappingAMonthFoldsOrOpensOnlyThatMonth() {
        let folding = MonthFolding(ids: ["Sep", "Aug", "Jul"], collapsed: ["Aug", "Jul"])
        XCTAssertTrue(folding.isOpen("Sep"))
        XCTAssertEqual(folding.toggling("Aug"), ["Jul"])
        XCTAssertEqual(folding.toggling("Sep"), ["Sep", "Aug", "Jul"])
    }
}
