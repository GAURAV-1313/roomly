// Why: a size on screen is never made up and never passes an iCloud original off as space on this phone, and
// a long-press preview keeps the asset's shape. These tests pin the words and the arithmetic behind both.
import XCTest

@testable import Roomy

final class SizeAndPreviewTests: XCTestCase {
    func testSizeLabelSaysWhenFilesAreOnlyInICloud() {
        let cloud = AssetSize(bytes: 3_000_000_000, inCloudOnly: 3_000_000_000)
        XCTAssertEqual(SizeLabel.text(cloud), "\(Int64(3_000_000_000).byteString) · in iCloud")
        XCTAssertEqual(SizeLabel.value(cloud), Int64(3_000_000_000).byteString)
        XCTAssertEqual(SizeLabel.text(AssetSize(bytes: 1_000)), Int64(1_000).byteString)
        XCTAssertEqual(SizeLabel.text(nil), "size unavailable")
    }

    /// Regression: Review said "Delete 1 item · 3 GB" for a video whose original was only in iCloud.
    func testReviewCountsOnlyThePhoneAndMentionsICloudSeparately() {
        let summary = ReviewSummary(assetCount: 1, bytes: 0, bytesInCloud: 3_000_000_000)
        XCTAssertEqual(summary.actionTitle, "Delete 1 item", "the button never shows 0 KB")
        XCTAssertEqual(
            summary.cloudNote, "Also \(Int64(3_000_000_000).byteString) kept only in iCloud, not counted above.")
        XCTAssertNil(ReviewSummary(assetCount: 1, bytes: 10).cloudNote)
    }

    func testPreviewKeepsTheAssetsShapeInsideTheBounds() {
        let bounds = CGSize(width: 360, height: 600)
        XCTAssertEqual(PreviewSize.fitting(width: 1179, height: 2556, in: bounds).height, 600, accuracy: 0.001)
        let landscape = PreviewSize.fitting(width: 4000, height: 3000, in: bounds)
        XCTAssertEqual(landscape.width, 360, accuracy: 0.001)
        XCTAssertEqual(landscape.height, 270, accuracy: 0.001)
        XCTAssertEqual(PreviewSize.fitting(width: 0, height: 0, in: bounds), bounds)
    }
}
