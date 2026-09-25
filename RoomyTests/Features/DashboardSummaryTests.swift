// Why: every number, word and mood on the dashboard comes from DashboardSummary, so its rules are tested
// without rendering a view.
import XCTest

@testable import Roomy

final class DashboardSummaryTests: XCTestCase {
    private let roomy = VolumeStats(total: 100_000, free: 50_000)
    private let nearlyFull = VolumeStats(total: 100_000, free: 9_000)

    func testMoodFollowsScanAndFreeSpace() {
        XCTAssertEqual(DashboardSummary(phase: .indexing, volume: roomy, canUseLibrary: true).mood, .thinking)
        XCTAssertEqual(DashboardSummary(phase: .done, volume: nearlyFull, canUseLibrary: true).mood, .concerned)
        XCTAssertEqual(DashboardSummary(phase: .idle, volume: roomy, canUseLibrary: false).mood, .concerned)
        XCTAssertEqual(DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true).mood, .resting)
        XCTAssertEqual(
            DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, reclaimableBytes: 5_000_000).mood,
            .idle)
        XCTAssertEqual(
            DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, reclaimableBytes: 200_000_000).mood,
            .pleased)
    }

    func testStorageCardSaysTheStateFirst() {
        let done = DashboardSummary(phase: .done, volume: nearlyFull, canUseLibrary: true, reclaimableBytes: 9_000)
        XCTAssertEqual(done.cardTitle, "Ready to clean up")
        XCTAssertEqual(done.usageTitle, "91% full")
        XCTAssertEqual(done.usageDetail, "\(nearlyFull.used.byteString) used · \(nearlyFull.free.byteString) free")
        XCTAssertEqual(done.heroCaption, "can be cleaned up")

        let scanning = DashboardSummary(
            phase: .indexing, volume: roomy, canUseLibrary: true, indexProgress: IndexProgress(scanned: 42, total: 90))
        XCTAssertEqual(scanning.cardTitle, "Finding space")
        XCTAssertEqual(scanning.usageTitle, "50% full", "how full the phone is stays visible while scanning")
        XCTAssertEqual(scanning.heroCaption, "found so far")
        XCTAssertEqual(scanning.progressText, "42 of 90 photos")

        let blocked = DashboardSummary(phase: .idle, volume: roomy, canUseLibrary: false)
        XCTAssertEqual(blocked.cardTitle, "Your storage")
        XCTAssertFalse(blocked.showsAmount, "without a scan there is no amount to show, not a guess")
    }

    func testUsedFractionIsWhatIsNotFree() {
        let summary = DashboardSummary(phase: .done, volume: nearlyFull, canUseLibrary: true)
        XCTAssertEqual(summary.usedFraction, 0.91, accuracy: 0.000_1)
    }

    func testCategoryCardsLoadThenShowContentOrSayWhyNot() {
        func tile(_ route: Route, _ summary: DashboardSummary) -> CategoryTile? {
            summary.tiles.first { $0.route == route }
        }
        let indexing = DashboardSummary(phase: .indexing, volume: roomy, canUseLibrary: true)
        XCTAssertEqual(tile(.screenshots, indexing)?.preview, .loading)
        XCTAssertNil(tile(.screenshots, indexing)?.detail)

        let shots = CategoryTotals(count: 7, bytes: 7_000, previewIDs: ["a", "b"])
        let comparing = DashboardSummary(phase: .comparing, volume: roomy, canUseLibrary: true, screenshots: shots)
        XCTAssertEqual(tile(.screenshots, comparing)?.detail, "7 screenshots · 7\u{00A0}KB")
        XCTAssertEqual(tile(.screenshots, comparing)?.preview, .screenshots(["a", "b"]))
        XCTAssertEqual(tile(.similarPhotos, comparing)?.preview, .loading, "groups are known only when done")

        let empty = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true)
        XCTAssertEqual(tile(.largeVideos, empty)?.detail, DashboardSummary.allClear)

        let blocked = DashboardSummary(phase: .idle, volume: roomy, canUseLibrary: false)
        XCTAssertEqual(tile(.similarPhotos, blocked)?.detail, "Needs Photos access")
        XCTAssertEqual(tile(.similarPhotos, blocked)?.preview, .status(.locked))
        XCTAssertEqual(tile(.largeVideos, empty)?.preview, .status(.clear))
    }

    func testContactCardFollowsAccessAndScan() {
        func tile(_ contacts: ContactTotals) -> CategoryTile? {
            DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, contacts: contacts)
                .tiles.first { $0.route == .duplicateContacts }
        }
        XCTAssertEqual(tile(ContactTotals(access: .notDetermined))?.detail, "Tap to allow")
        XCTAssertEqual(tile(ContactTotals(access: .limited))?.detail, "Needs full access")
        XCTAssertEqual(tile(ContactTotals(access: .authorized, phase: .scanning))?.preview, .loading)
        XCTAssertEqual(tile(ContactTotals(access: .authorized, phase: .done))?.detail, "No likely duplicates")
        let done = tile(
            ContactTotals(access: .authorized, phase: .done, groups: 2, extraCards: 3, initials: ["A", "J"]))
        XCTAssertEqual(done?.detail, "2 groups · 3 extra cards")
        XCTAssertEqual(done?.preview, .initials(["A", "J"]))
    }

    /// Regression: a comparison stopped part-way showed "All clear" for similar photos.
    func testStoppedComparisonNeverReadsAsAllClear() {
        let stopped = DashboardSummary(phase: .stopped, volume: roomy, canUseLibrary: true)
        XCTAssertEqual(stopped.cardTitle, "Comparison not finished")
        XCTAssertFalse(stopped.isScanning)
        let similar = stopped.tiles.first { $0.route == .similarPhotos }
        XCTAssertEqual(similar?.detail, "Comparison not finished")
        XCTAssertEqual(similar?.preview, .status(.paused))
        let screenshots = stopped.tiles.first { $0.route == .screenshots }
        XCTAssertEqual(screenshots?.detail, DashboardSummary.allClear, "the index finished, so screenshots are current")
    }

    /// Regression: photos that could not be read were silently left out and the card still said "All clear".
    func testUncheckedPhotosAreNotAllClear() {
        let summary = DashboardSummary(
            phase: .done, volume: roomy, canUseLibrary: true, similar: CategoryTotals(unchecked: 3))
        XCTAssertEqual(summary.tiles.first { $0.route == .similarPhotos }?.detail, "None found · 3 not checked")
    }

    /// Regression: with thousands of iCloud-only photos never compared, the storage card still said "All tidy"
    /// and the robin rested, above a tile saying photos were not checked.
    func testUncheckedPhotosKeepTheHeadlineFromCallingTheLibraryTidy() {
        let unchecked = DashboardSummary(
            phase: .done, volume: roomy, canUseLibrary: true, similar: CategoryTotals(unchecked: 3_000))
        XCTAssertEqual(unchecked.cardTitle, "Nothing found so far")
        XCTAssertEqual(unchecked.mood, .idle)

        let checked = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true)
        XCTAssertEqual(checked.cardTitle, "All tidy")
        XCTAssertEqual(checked.mood, .resting)
    }

    /// Regression: an iCloud-only video's 3 GB row sat under a tile reading "1 video · 0 KB".
    func testTotalsNameWhatIsOnlyInICloudInsteadOfZero() {
        let videos = CategoryTotals(count: 1, bytes: 0, inCloudBytes: 3_000_000_000)
        let summary = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, videos: videos)
        let detail = summary.tiles.first { $0.route == .largeVideos }?.detail
        XCTAssertEqual(detail, "1 video · \(Int64(3_000_000_000).byteString) in iCloud")
        let unsized = CategoryTotals(count: 2, unsizedCount: 2)
        let shots = DashboardSummary(phase: .done, volume: roomy, canUseLibrary: true, screenshots: unsized)
        XCTAssertEqual(shots.tiles.first { $0.route == .screenshots }?.detail, "2 screenshots · size unavailable")
    }
}
