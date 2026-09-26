// Why: a month's toggle shows off, mixed or on from counts; an empty month must never read as selected.
import XCTest

@testable import Roomy

final class SelectionStateTests: XCTestCase {
    func testCountsMapToTheThreeStates() {
        XCTAssertEqual(SelectionState(selected: 0, of: 11), .off)
        XCTAssertEqual(SelectionState(selected: 7, of: 11), .mixed)
        XCTAssertEqual(SelectionState(selected: 11, of: 11), .on)
    }

    func testNothingToSelectIsOff() {
        XCTAssertEqual(SelectionState(selected: 0, of: 0), .off)
    }
}
