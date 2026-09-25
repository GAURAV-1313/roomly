// Why: the result's pin is a claim about the person's phone — "in Recently Deleted" until a measured rise, then
// "now free" — and its usage row must read exactly like the dashboard's, so both are pinned here.
import XCTest

@testable import Roomy

final class StorageResultTests: XCTestCase {
    func testThePinSaysRemovedUntilFreeSpaceIsMeasured() {
        let pending = StorageMarker.pending(2_100_000_000)
        XCTAssertEqual(pending.text, "\(Int64(2_100_000_000).byteString) in Recently Deleted")
        XCTAssertTrue(pending.isPending)
        let freed = StorageMarker.freed(2_100_000_000)
        XCTAssertEqual(freed.text, "\(Int64(2_100_000_000).byteString) now free")
        XCTAssertFalse(freed.isPending)
    }

    func testUsageReadsTheSameOnTheResultAsOnTheDashboard() {
        let volume = VolumeStats(total: 100_000, free: 8_000)
        let usage = StorageUsage(volume: volume)
        let dashboard = DashboardSummary(phase: .done, volume: volume, canUseLibrary: true)
        XCTAssertEqual(usage.title, "92% full")
        XCTAssertEqual(usage.title, dashboard.usageTitle)
        XCTAssertEqual(usage.detail, dashboard.usageDetail)
        XCTAssertEqual(usage.usedFraction, 0.92, accuracy: 0.000_1)
    }
}
