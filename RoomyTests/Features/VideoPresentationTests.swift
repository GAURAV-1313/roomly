// Why: what the Large Videos screen and its player sheet say is decided by two small pure types. These tests
// pin the regressions: a filter that hid everything under an unfiltered total, and a sheet that spun forever.
import XCTest

@testable import Roomy

final class VideoPresentationTests: XCTestCase {
    private let videos: [AssetSnapshot] = [
        .fixture("big", kind: .video, size: 900_000_000),
        .fixture("small", kind: .video, size: 100_000_000),
        .fixture("unknown", kind: .video),
    ]

    func testUnfilteredSummaryCountsEveryVideo() {
        let summary = VideoListSummary(videos: videos, showsLargeOnly: false)
        XCTAssertEqual(summary.visible.map(\.id), ["big", "small", "unknown"])
        XCTAssertEqual(summary.value, "at least \(Int64(1_000_000_000).byteString)")
        XCTAssertEqual(summary.detail, "3 videos")
        XCTAssertFalse(summary.isFilterHidingEverything)
    }

    /// Regression: with the filter on, the summary still counted and sized the unfiltered list.
    func testFilteredSummaryDescribesTheFilteredList() {
        let summary = VideoListSummary(videos: videos, showsLargeOnly: true)
        XCTAssertEqual(summary.visible.map(\.id), ["big"])
        XCTAssertEqual(summary.value, Int64(900_000_000).byteString)
        XCTAssertEqual(summary.detail, "1 of 3 videos")
    }

    /// Regression: a filter matching nothing left a blank list with no explanation.
    func testAFilterThatMatchesNothingSaysSo() {
        let small: [AssetSnapshot] = [.fixture("small", kind: .video, size: 100_000_000)]
        let summary = VideoListSummary(videos: small, showsLargeOnly: true)
        XCTAssertTrue(summary.isFilterHidingEverything)
        XCTAssertEqual(summary.value, Int64(0).byteString)
        XCTAssertEqual(summary.detail, "0 of 1 video")
        XCTAssertFalse(VideoListSummary(videos: [], showsLargeOnly: true).isFilterHidingEverything)
    }

    /// Regression: an iCloud-only 3 GB video listed as "3 GB" sat under a summary reading "1 of 1 video · 0 KB".
    func testSizeKeptOnlyInICloudIsNamedNotZero() {
        let cloud: [AssetSnapshot] = [.fixture("cloud", kind: .video, size: 3_000_000_000, inCloud: 3_000_000_000)]
        let summary = VideoListSummary(videos: cloud, showsLargeOnly: true)
        XCTAssertEqual(summary.visible.map(\.id), ["cloud"], "the filter goes by the size its row shows")
        XCTAssertEqual(summary.value, "\(Int64(3_000_000_000).byteString) in iCloud")
        XCTAssertEqual(summary.detail, "1 of 1 video")
    }

    /// The value stays one line — the size on this phone — and the iCloud part moves to the detail line,
    /// before the count.
    func testICloudPartOfAMixedListLeadsTheDetailLine() {
        let mixed: [AssetSnapshot] = [
            .fixture("here", kind: .video, size: 1_000_000_000),
            .fixture("cloud", kind: .video, size: 3_000_000_000, inCloud: 3_000_000_000),
        ]
        let summary = VideoListSummary(videos: mixed, showsLargeOnly: false)
        XCTAssertEqual(summary.value, Int64(1_000_000_000).byteString)
        XCTAssertEqual(summary.detail, "+ \(Int64(3_000_000_000).byteString) in iCloud · 2 videos")
    }

    /// Regression: a list where Photos reported no size read "40 videos · 0 KB".
    func testUnknownSizesSaySoInsteadOfZero() {
        let unknown: [AssetSnapshot] = [.fixture("a", kind: .video), .fixture("b", kind: .video)]
        let summary = VideoListSummary(videos: unknown, showsLargeOnly: false)
        XCTAssertEqual(summary.value, "size unavailable")
        XCTAssertEqual(summary.detail, "2 videos")
    }

    func testLoadingShowsDownloadProgressThenTheVideo() {
        var state = VideoLoadState.loading(progress: nil)
        XCTAssertNil(state.progressLabel)
        XCTAssertNil(state.apply(VideoLoadEvent<String>.downloading(0.42)))
        XCTAssertEqual(state.progressLabel, "Downloading from iCloud · 42%")
        XCTAssertEqual(state.apply(VideoLoadEvent.ready("item")), "item")
        XCTAssertEqual(state, .ready)
        XCTAssertNil(state.failureTitle)
    }

    /// Regression: a video that couldn't load left the sheet on an endless spinner with no way forward.
    func testFailuresExplainThemselvesAndOfferRetryWhenItCanHelp() {
        for failure in [VideoLoadFailure.unavailable, .timedOut] {
            var state = VideoLoadState.loading(progress: nil)
            XCTAssertNil(state.apply(VideoLoadEvent<String>.failed(failure)))
            XCTAssertNotNil(state.failureTitle)
            XCTAssertNotNil(state.failureMessage)
            XCTAssertTrue(state.canRetry)
        }
        var missing = VideoLoadState.loading(progress: nil)
        _ = missing.apply(VideoLoadEvent<String>.failed(.missing))
        XCTAssertEqual(missing.failureTitle, "This video is gone")
        XCTAssertFalse(missing.canRetry, "a video deleted in Photos can't come back")
    }
}
