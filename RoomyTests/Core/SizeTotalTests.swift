// Why: totals must never read "0 KB" for photos that take real space. These tests pin how unknown sizes are
// counted and worded, on their own and on the dashboard's Similar photos card.
import XCTest

@testable import Roomy

final class SizeTotalTests: XCTestCase {
    func testKnownSizesAddUp() {
        let total = SizeTotal(sizes: [1_000, 2_000])
        XCTAssertEqual(total, SizeTotal(knownBytes: 3_000, knownCount: 2, unknownCount: 0))
        XCTAssertEqual(total.text, Int64(3_000).byteString)
    }

    /// Regression: a group whose sizes were all unknown read "0 KB".
    func testUnknownSizesAreSaidNotGuessed() {
        XCTAssertEqual(SizeTotal(sizes: [nil, nil]).text, "size unavailable")
        XCTAssertEqual(SizeTotal(sizes: [1_000, nil]).text, "at least \(Int64(1_000).byteString)")
        let photos: [AssetSnapshot] = [.fixture("a", size: 1_000), .fixture("b")]
        XCTAssertEqual(photos.sizeTotal.unknownCount, 1)
    }

    func testSimilarCardSaysWhenSizesAreUnknown() {
        let unsized = CategoryTotals(count: 2, bytes: 0, unsizedCount: 2, groups: 1)
        let summary = DashboardSummary(
            phase: .done, volume: VolumeStats(total: 100, free: 50), canUseLibrary: true, similar: unsized)
        let tile = summary.tiles.first { $0.route == .similarPhotos }
        XCTAssertEqual(tile?.detail, "1 · size unavailable")
        XCTAssertEqual(tile?.accessibilityDetail, "1 group, size unavailable")
    }

    func testSpokenSizesUseTheSameAmountInFullWords() {
        XCTAssertEqual(Int64(312_000_000).spokenByteString, "312 megabytes")
        XCTAssertEqual(Int64(2_900_000).spokenByteString, "2.9 megabytes")
        XCTAssertEqual(Int64(1_000_000_000).spokenByteString, "1 gigabyte")
        XCTAssertEqual(Int64(0).spokenByteString, "0 kilobytes")
    }

    /// Regression: "at least 2.4 GB + 860 MB in iCloud" wrapped in a summary card's big number.
    func testHeadlineKeepsOnlyThePhonePartAndNamesICloudApart() {
        let mixed = SizeTotal(knownBytes: 2_400_000_000, knownCount: 3, unknownCount: 1, inCloudBytes: 860_000_000)
        XCTAssertEqual(mixed.headline, "at least \(Int64(2_400_000_000).byteString)")
        XCTAssertEqual(mixed.inCloudNote, "+ \(Int64(860_000_000).byteString) in iCloud")

        let cloudOnly = SizeTotal(inCloudBytes: 3_000_000_000)
        XCTAssertEqual(cloudOnly.headline, "\(Int64(3_000_000_000).byteString) in iCloud")
        XCTAssertNil(cloudOnly.inCloudNote)

        XCTAssertEqual(SizeTotal(unknownCount: 2).headline, "size unavailable")
        XCTAssertEqual(SizeTotal(knownBytes: 5_000, knownCount: 1).headline, Int64(5_000).byteString)
    }
}
