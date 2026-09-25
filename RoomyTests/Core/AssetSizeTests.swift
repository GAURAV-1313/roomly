// Why: with "Optimize iPhone Storage", Photos reports full sizes for originals kept only in iCloud. These tests
// pin the rule that only bytes on the phone count as space this phone gets back, everywhere a total is made.
import XCTest

@testable import Roomy

final class AssetSizeTests: XCTestCase {
    func testFilesPhotosMarksAsNotOnThePhoneCountAsInCloudOnly() {
        let size = AssetSize.measure([
            AssetSize.File(bytes: 3_000_000_000, isOnPhone: false),
            AssetSize.File(bytes: 2_000_000, isOnPhone: true),
        ])
        XCTAssertEqual(size?.bytes, 3_002_000_000)
        XCTAssertEqual(size?.onPhone, 2_000_000)
        XCTAssertEqual(size?.isInCloud, true)
    }

    func testUnknownAvailabilityCountsAsOnThePhone() {
        let size = AssetSize.measure([AssetSize.File(bytes: 500, isOnPhone: nil)])
        XCTAssertEqual(size?.onPhone, 500)
        XCTAssertEqual(size?.isInCloud, false)
    }

    func testNoKnownSizeIsUnavailableNotZero() {
        XCTAssertNil(AssetSize.measure([AssetSize.File(bytes: nil, isOnPhone: true)]))
        XCTAssertNil(AssetSize.measure([]))
    }

    /// Regression: the dashboard's Reclaimable and each category total added iCloud-only originals.
    func testTotalsCountOnlyBytesOnThePhone() {
        let videos: [AssetSnapshot] = [
            .fixture("cloud", kind: .video, size: 3_000_000_000, inCloud: 3_000_000_000),
            .fixture("local", kind: .video, size: 40_000_000),
            .fixture("unknown", kind: .video),
        ]
        XCTAssertEqual(videos.totalBytes, 40_000_000)
    }

    /// Regression: Review and the Recently Deleted check used the full size of an iCloud-only video.
    func testBasketItemAndPlanCarryOnlyBytesOnThePhone() {
        let item = BasketItem(.fixture("cloud", kind: .video, size: 3_000_000_000, inCloud: 2_900_000_000))
        XCTAssertEqual(item.bytes, 100_000_000)
        XCTAssertEqual(item.bytesInCloud, 2_900_000_000)
        XCTAssertEqual(item.size, AssetSize(bytes: 3_000_000_000, inCloudOnly: 2_900_000_000))

        let plan = CleanupPlan.make(items: [item], contactGroups: [:])
        XCTAssertEqual(plan.assetBytes, 100_000_000)
    }

    func testBasketItemOnThePhoneHasNoCloudPart() {
        let item = BasketItem(.fixture("local", kind: .video, size: 1_234))
        XCTAssertEqual(item.bytes, 1_234)
        XCTAssertNil(item.bytesInCloud)
        XCTAssertEqual(item.size?.isInCloud, false)
    }

    func testBasketItemSavedBeforeCloudSizesStillDecodes() throws {
        let saved = Data(#"{"id":"old","kind":"video","bytes":42}"#.utf8)
        let item = try JSONDecoder().decode(BasketItem.self, from: saved)
        XCTAssertEqual(item.bytes, 42)
        XCTAssertNil(item.bytesInCloud)
    }
}
