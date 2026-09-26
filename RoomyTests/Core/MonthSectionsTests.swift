// Why: month headers must keep the order items arrive in and never split one month into two sections.
import XCTest

@testable import Roomy

final class MonthSectionsTests: XCTestCase {
    func testGroupsByMonthInFirstSeenOrder() {
        let march = Date(timeIntervalSince1970: 1_709_300_000)
        let february = Date(timeIntervalSince1970: 1_707_000_000)
        let items = [(1, march), (2, february), (3, march)]
        let sections = MonthSections.make(items) { $0.1 }
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].items.map(\.0), [1, 3])
        XCTAssertEqual(sections[1].items.map(\.0), [2])
        XCTAssertEqual(MonthSections.title(for: nil), "Undated")
    }

    func testOneOrTwoMonthsAllStartOpen() {
        XCTAssertEqual(MonthSections.defaultCollapsed([]), [])
        XCTAssertEqual(MonthSections.defaultCollapsed(["Sep"]), [])
        XCTAssertEqual(MonthSections.defaultCollapsed(["Sep", "Aug"]), [])
    }

    func testWithMoreThanTwoMonthsOnlyTheNewestStartsOpen() {
        XCTAssertEqual(MonthSections.defaultCollapsed(["Sep", "Aug", "Jul"]), ["Aug", "Jul"])
    }

    func testByteStringUsesSettingsUnits() {
        XCTAssertEqual(Int64(1_500_000_000).byteString, "1.5\u{00A0}GB")
    }
}
