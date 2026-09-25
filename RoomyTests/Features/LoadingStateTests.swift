// Why: loading screens must never show a made-up value. These tests pin that the storage card's amount is a
// skeleton until the first index has found something, that progress shows only real counts, and that the
// comparison card says what it is doing before it has any.
import XCTest

@testable import Roomy

final class LoadingStateTests: XCTestCase {
    private let roomy = VolumeStats(total: 100_000, free: 50_000)

    func testFirstIndexShowsNoAmountAndNoCounts() {
        let first = DashboardSummary(phase: .indexing, volume: roomy, canUseLibrary: true)
        XCTAssertTrue(first.isAmountPending, "\"0 KB found so far\" before anything was read is made up")
        XCTAssertFalse(first.hasProgressCounts)
        XCTAssertEqual(first.progressText, "Reading your library")
    }

    func testCountsAppearOnceTheLibrarySaysHowMany() {
        let counted = DashboardSummary(
            phase: .indexing, volume: roomy, canUseLibrary: true, indexProgress: IndexProgress(scanned: 3, total: 9))
        XCTAssertTrue(counted.hasProgressCounts)
        XCTAssertEqual(counted.progressText, "3 of 9 photos")

        let comparing = DashboardSummary(phase: .comparing, volume: roomy, canUseLibrary: true)
        XCTAssertFalse(comparing.hasProgressCounts, "no \"0 of 0\" before the comparison has a total")
        XCTAssertEqual(comparing.progressText, "Comparing photos")
        XCTAssertFalse(comparing.isAmountPending, "once indexed, zero found is a real result")
    }

    func testARescanKeepsWhatTheEarlierScanFound() {
        let shots = CategoryTotals(count: 3, bytes: 3_000)
        let rescan = DashboardSummary(
            phase: .indexing, volume: roomy, canUseLibrary: true, reclaimableBytes: 3_000, screenshots: shots)
        XCTAssertFalse(rescan.isAmountPending)
        XCTAssertEqual(rescan.heroValue, Int64(3_000).byteString)
    }

    func testComparisonCardUsesRealCountsOnly() {
        let reading = ScanProgressCopy(phase: .indexing, hashProgress: HashProgress())
        XCTAssertEqual(reading.title, "Reading your library")
        XCTAssertEqual(reading.message, "You can leave this screen.")
        XCTAssertNil(reading.fraction)
        XCTAssertEqual(reading.accessibilityLabel, "Reading your library")

        let starting = ScanProgressCopy(phase: .comparing, hashProgress: HashProgress())
        XCTAssertEqual(starting.title, "Comparing photos")
        XCTAssertNil(starting.fraction, "an empty bar before a total exists would be a made-up zero")

        let comparing = ScanProgressCopy(phase: .comparing, hashProgress: HashProgress(done: 4_208, total: 20_113))
        XCTAssertEqual(comparing.message, "4,208 of 20,113 · You can leave this screen.")
        XCTAssertEqual(comparing.fraction ?? 0, 4_208 / 20_113, accuracy: 0.000_1)
        XCTAssertEqual(comparing.accessibilityLabel, "Comparing photos, 4,208 of 20,113")
    }
}
