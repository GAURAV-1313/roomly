// Why: a rise is reported only after free space is measured again, never for more than a cleanup moved, and
// never when it is far bigger than what was moved. These tests pin that rule, the 30 days each cleanup keeps on its own, and that a file saved by an older
// version of Roomy still loads.
import XCTest

@testable import Roomy

final class PendingReclaimTests: XCTestCase {
    private let day: TimeInterval = 24 * 60 * 60

    private func date(day number: Double) -> Date {
        Date(timeIntervalSince1970: number * day)
    }

    private func makePending(_ bytes: Int64, freeBefore: Int64) -> PendingReclaim {
        PendingReclaim(entries: [.init(bytes: bytes, itemCount: 3, date: date(day: 0))], freeBefore: freeBefore)
    }

    func testSpaceCountsAsFreedOnlyAfterFreeSpaceRisesEnough() {
        let pending = makePending(1_000, freeBefore: 10_000)
        XCTAssertEqual(pending.reading(freeNow: 10_000), .waiting, "moved is not freed")
        XCTAssertEqual(pending.reading(freeNow: 10_400), .waiting, "too small a rise to credit to the cleanup")
        XCTAssertEqual(pending.reading(freeNow: 10_600), .reclaimed(600), "the measured rise, not the estimate")
        XCTAssertEqual(pending.reading(freeNow: 11_400), .reclaimed(1_000), "never more than was moved")
    }

    /// Regression: deleting a 2 GB app after moving 40 MB (or 3 GB after 500 MB) cleared the reminder and was
    /// announced as the cleanup's space.
    func testARiseFarBeyondWhatWasMovedIsNotTheCleanups() {
        let small = makePending(40_000_000, freeBefore: 10_000_000_000)
        XCTAssertEqual(small.reading(freeNow: 12_000_000_000), .unexplained)
        let large = makePending(500_000_000, freeBefore: 10_000_000_000)
        XCTAssertEqual(large.reading(freeNow: 13_000_000_000), .unexplained)

        let rebased = small.rebased(freeNow: 12_000_000_000)
        XCTAssertEqual(rebased.entries, small.entries, "the cleanup is still waiting")
        XCTAssertEqual(rebased.reading(freeNow: 12_040_000_000), .reclaimed(40_000_000))
    }

    /// Regression: after an unexplained rise the reminder kept saying the space "still uses space", although
    /// that rise may have been Recently Deleted being emptied.
    func testAnUnexplainedRiseMakesTheWaitingSpaceUncertain() {
        let pending = makePending(40_000_000, freeBefore: 10_000_000_000)
        XCTAssertFalse(pending.isUncertain)
        let rebased = pending.rebased(freeNow: 10_140_000_000)
        XCTAssertTrue(rebased.isUncertain)
        XCTAssertEqual(rebased.expiring(at: date(day: 1))?.isUncertain, true, "stays uncertain as days pass")
        let next = rebased.adding(.init(bytes: 1_000, itemCount: 1, date: date(day: 2)), freeBefore: 9_000)
        XCTAssertTrue(next.isUncertain, "a newer cleanup doesn't prove the older ones are still there")
        XCTAssertEqual(try JSONDecoder().decode(PendingReclaim.self, from: JSONEncoder().encode(next)), next)
    }

    func testACleanupThatMovedNoKnownSizeIsNeverCredited() {
        XCTAssertEqual(makePending(0, freeBefore: 10_000).reading(freeNow: 90_000), .waiting)
    }

    /// Regression: a second cleanup kept the first one's date, so its reminder vanished when the first expired.
    func testEachCleanupExpiresThirtyDaysAfterItself() {
        let first = PendingReclaim.Entry(bytes: 2_000, itemCount: 1, date: date(day: 0))
        let second = PendingReclaim.Entry(bytes: 3_000, itemCount: 2, date: date(day: 28))
        let pending = PendingReclaim(entries: [first], freeBefore: 10_000).adding(second, freeBefore: 9_000)

        let afterFirstExpired = pending.expiring(at: date(day: 31))
        XCTAssertEqual(afterFirstExpired?.entries, [second])
        XCTAssertEqual(afterFirstExpired?.bytes, 3_000)
        XCTAssertEqual(
            afterFirstExpired?.reading(freeNow: 11_000), .waiting,
            "iOS emptying the first cleanup on its own is not credited to the second")
        XCTAssertNil(pending.expiring(at: date(day: 59)), "gone once every cleanup is past its 30 days")
    }

    func testAFileSavedWithOneCleanupStillLoads() throws {
        let saved = Data(#"{"bytes":1000,"itemCount":3,"freeBefore":10000,"date":0}"#.utf8)
        let loaded = try JSONDecoder().decode(PendingReclaim.self, from: saved)

        XCTAssertEqual(
            loaded.entries, [.init(bytes: 1_000, itemCount: 3, date: Date(timeIntervalSinceReferenceDate: 0))])
        XCTAssertEqual(loaded.freeBefore, 10_000)
        XCTAssertFalse(loaded.isUncertain)
        XCTAssertEqual(try JSONDecoder().decode(PendingReclaim.self, from: JSONEncoder().encode(loaded)), loaded)
    }
}
