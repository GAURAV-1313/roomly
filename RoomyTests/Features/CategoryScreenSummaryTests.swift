// Why: a summary card's big value is one line, so the size on this phone stands alone and any iCloud part moves
// to the detail line before the counts. These tests pin that split for Similar Photos and Screenshots, and that
// no count or size the old one-line summaries showed is lost.
import XCTest

@testable import Roomy

final class CategoryScreenSummaryTests: XCTestCase {
    private let phoneOnly = SizeTotal(knownBytes: 48_200_000, knownCount: 31)
    private let mixed = SizeTotal(knownBytes: 2_000_000, knownCount: 2, inCloudBytes: 860_000_000)

    func testSimilarSummaryKeepsEveryCount() {
        let summary = SimilarPhotosSummary(groupCount: 12, extraCount: 31, size: phoneOnly)
        XCTAssertEqual(summary.value, Int64(48_200_000).byteString)
        XCTAssertEqual(summary.detail, "12 groups · 31 extras")
    }

    func testSimilarSummaryPutsICloudOnTheDetailLine() {
        let summary = SimilarPhotosSummary(groupCount: 2, extraCount: 3, size: mixed)
        XCTAssertEqual(summary.value, Int64(2_000_000).byteString)
        XCTAssertEqual(summary.detail, "+ \(Int64(860_000_000).byteString) in iCloud · 2 groups · 3 extras")
    }

    func testSimilarSummaryNeverShowsAMadeUpSize() {
        let summary = SimilarPhotosSummary(groupCount: 1, extraCount: 2, size: SizeTotal(unknownCount: 2))
        XCTAssertEqual(summary.value, "size unavailable")
    }

    func testScreenshotsSummaryCountsLikeTheDashboardTile() {
        XCTAssertEqual(ScreenshotsSummary(count: 84, size: phoneOnly).detail, "84 screenshots")
        XCTAssertEqual(ScreenshotsSummary(count: 1, size: phoneOnly).detail, "1 screenshot")
        let cloud = ScreenshotsSummary(count: 3, size: mixed)
        XCTAssertEqual(cloud.value, Int64(2_000_000).byteString)
        XCTAssertEqual(cloud.detail, "+ \(Int64(860_000_000).byteString) in iCloud · 3 screenshots")
    }

    func testMonthDetailKeepsCountAndSize() {
        XCTAssertEqual(ScreenshotsSummary.monthDetail(count: 24, size: phoneOnly), "24 · \(phoneOnly.text)")
        XCTAssertEqual(
            ScreenshotsSummary.monthDetail(
                count: 2, size: SizeTotal(knownBytes: 1_000, knownCount: 1, unknownCount: 1)),
            "2 · at least \(Int64(1_000).byteString)")
    }
}
