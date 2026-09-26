// Why: the storage card's headline, number and robin must agree with the category tiles below them. These
// tests cover the cases where the bytes on this phone are zero but something was found.
import XCTest

@testable import Roomy

final class DashboardHeroTests: XCTestCase {
    private let roomy = VolumeStats(total: 100_000, free: 50_000)

    /// Regression: with only an iCloud-only video found, the card read "0 KB · can be cleaned up · All tidy"
    /// with a resting robin, above a tile saying "1 video · 3 GB in iCloud".
    func testICloudOnlyFindsAreNamedInsteadOfZero() {
        let videos = CategoryTotals(count: 1, bytes: 0, inCloudBytes: 3_000_000_000)
        let summary = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, videos: videos)
        XCTAssertEqual(summary.heroValue, Int64(3_000_000_000).byteString)
        XCTAssertEqual(summary.heroCaption, "in iCloud")
        XCTAssertEqual(summary.heroSpokenLabel, "3 gigabytes in iCloud, not on this phone")
        XCTAssertEqual(summary.cardTitle, "Ready to clean up")
        XCTAssertEqual(summary.mood, .idle)
    }

    /// Regression: screenshots with no known size gave "0 KB · can be cleaned up · All tidy".
    func testUnsizedFindsAreCountedInsteadOfZero() {
        let shots = CategoryTotals(count: 2, unsizedCount: 2)
        let summary = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, screenshots: shots)
        XCTAssertEqual(summary.heroValue, "2 items")
        XCTAssertEqual(summary.heroCaption, "size unavailable")
        XCTAssertEqual(summary.heroSpokenLabel, "2 items, size unavailable")
        XCTAssertEqual(summary.cardTitle, "Ready to clean up")
        XCTAssertNotEqual(summary.mood, .resting)

        let scanning = DashboardSummary(phase: .comparing, volume: roomy, canUseLibrary: true, screenshots: shots)
        XCTAssertEqual(scanning.heroCaption, "size unavailable")
        XCTAssertEqual(scanning.heroSpokenLabel, "2 items found so far, size unavailable")
    }

    func testBytesOnThePhoneStillLead() {
        let videos = CategoryTotals(count: 2, bytes: 5_000, inCloudBytes: 3_000_000_000)
        let summary = DashboardSummary(
            phase: .done, volume: roomy, canUseLibrary: true, reclaimableBytes: 5_000, videos: videos)
        XCTAssertEqual(summary.heroValue, Int64(5_000).byteString)
        XCTAssertEqual(summary.heroCaption, "to clean up")
    }

    /// With iCloud items shown, the storage card names what its amount leaves out, like the category cards.
    func testTheCardNamesWhatIsKeptOnlyInICloud() {
        let videos = CategoryTotals(count: 2, bytes: 5_000, inCloudBytes: 3_000_000_000)
        let summary = DashboardSummary(
            phase: .done, volume: roomy, canUseLibrary: true, reclaimableBytes: 5_000, videos: videos)
        XCTAssertEqual(summary.heroCloudNote, "+ \(Int64(3_000_000_000).byteString) in iCloud")

        let cloudOnly = CategoryTotals(count: 1, bytes: 0, inCloudBytes: 3_000_000_000)
        XCTAssertNil(
            DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, videos: cloudOnly).heroCloudNote,
            "the amount already is the iCloud bytes")
        XCTAssertNil(DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true).heroCloudNote)
    }

    func testAnEmptyScanStillReadsZeroAndTidy() {
        let summary = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true)
        XCTAssertEqual(summary.foundAmount, .onPhone(0))
        XCTAssertEqual(summary.heroValue, Int64(0).byteString)
        XCTAssertEqual(summary.cardTitle, "All tidy")
        XCTAssertEqual(summary.mood, .resting)
    }

    /// Regression: groups whose extras were all favourites made the Similar tile say "All clear" while Similar
    /// Photos still listed them.
    func testGroupsWithNothingSuggestedAreNotAllClear() {
        let similar = CategoryTotals(count: 0, groups: 2, previewIDs: ["a", "b"])
        let summary = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, similar: similar)
        let tile = summary.tiles.first { $0.route == .similarPhotos }
        XCTAssertEqual(tile?.detail, "All kept")
        XCTAssertEqual(tile?.accessibilityDetail, "2 groups, nothing suggested")
        XCTAssertEqual(tile?.preview, .photos(["a", "b"]))

        let unchecked = CategoryTotals(count: 0, groups: 1, unchecked: 4)
        let withUnchecked = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, similar: unchecked)
        XCTAssertEqual(
            withUnchecked.tiles.first { $0.route == .similarPhotos }?.detail, "All kept")
    }
}
