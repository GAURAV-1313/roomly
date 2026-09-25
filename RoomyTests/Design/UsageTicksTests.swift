// Why: the usage bar is the dashboard's picture of how full the phone is, so its tick counts must follow the
// real share and never hide the last bit of free space or the first bit of use.
import XCTest

@testable import Roomy

final class UsageTicksTests: XCTestCase {
    private func ticks(_ usedFraction: Double, width: CGFloat = 305) -> UsageTicks {
        UsageTicks(width: width, usedFraction: usedFraction, tickWidth: 3, pitch: 6)
    }

    func testTicksFillTheWidthExactly() {
        let bar = ticks(0.5)
        XCTAssertEqual(bar.count, 51)
        XCTAssertEqual(CGFloat(bar.count) * 3 + CGFloat(bar.count - 1) * bar.spacing, 305, accuracy: 0.001)
    }

    func testUsedTicksFollowTheShare() {
        XCTAssertEqual(ticks(0.92).used, 47)
        XCTAssertEqual(ticks(0).used, 0)
        XCTAssertEqual(ticks(1).used, 51)
    }

    func testANearlyFullPhoneStillShowsFreeSpaceAndANearlyEmptyOneShowsUse() {
        XCTAssertEqual(ticks(0.999).used, 50)
        XCTAssertEqual(ticks(0.001).used, 1)
    }

    func testUsedTicksDeepenTowardFreeSpace() {
        let bar = ticks(0.5)
        XCTAssertEqual(bar.opacity(at: 0), UsageTicks.faintestUsed, accuracy: 0.001)
        XCTAssertEqual(bar.opacity(at: bar.used - 1), 1, accuracy: 0.001)
        XCTAssertEqual(bar.opacity(at: bar.used), UsageTicks.freeOpacity)
    }

    func testThePinSitsBetweenTheLastUsedTickAndTheFirstFreeOne() {
        let bar = ticks(0.5)
        let lastUsedEnd = CGFloat(bar.used - 1) * (3 + bar.spacing) + 3
        let firstFreeStart = CGFloat(bar.used) * (3 + bar.spacing)
        XCTAssertEqual(bar.boundaryX, (lastUsedEnd + firstFreeStart) / 2, accuracy: 0.001)
        XCTAssertEqual(ticks(0).boundaryX, 0)
        XCTAssertEqual(ticks(1).boundaryX, 305, accuracy: 0.001)
    }

    func testTheMarkerStandsOnTheLastUsedTick() {
        let bar = ticks(0.5)
        XCTAssertEqual(bar.lastUsedCenterX, CGFloat(bar.used - 1) * (3 + bar.spacing) + 1.5, accuracy: 0.001)
        XCTAssertEqual(ticks(0).lastUsedCenterX, 1.5, accuracy: 0.001)
    }
}
