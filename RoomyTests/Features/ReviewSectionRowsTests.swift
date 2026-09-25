// Why: every item a cleanup will take must be visible and removable in Review. These tests pin that a long
// section always offers the rest of its rows, instead of an "and N more" that can't be opened.
import XCTest

@testable import Roomy

final class ReviewSectionRowsTests: XCTestCase {
    func testAShortSectionShowsEveryRowWithNoControl() {
        let rows = ReviewSectionRows(total: 3)
        XCTAssertEqual(rows.visibleCount, 3)
        XCTAssertNil(rows.toggleTitle)
    }

    /// Regression: after selecting 240 photos Review listed 5 and "and 235 more", and the rest could not be seen.
    func testALongSectionOffersEveryRow() {
        let collapsed = ReviewSectionRows(total: 240)
        XCTAssertEqual(collapsed.visibleCount, ReviewSectionRows.collapsedCount)
        XCTAssertEqual(collapsed.toggleTitle, "Show all 240")

        let expanded = ReviewSectionRows(total: 240, isExpanded: true)
        XCTAssertEqual(expanded.visibleCount, 240)
        XCTAssertEqual(expanded.toggleTitle, "Show fewer")
    }
}
