// Why: with the "Over 500 MB" filter on, the count and size above the list must describe the list below it,
// and a filter that hides everything must say so instead of leaving a blank screen. The summary card shows the
// size on this phone as its one-line value and names what is only in iCloud on the line under it, beside the
// count, so a video kept in iCloud never reads "0 KB". Kept pure so it is tested.
import Foundation

nonisolated struct VideoListSummary: Equatable {
    /// What the "Over 500 MB" filter counts as large: the video's full size, the number its row shows.
    static let largeVideoThreshold: Int64 = 500_000_000

    /// The videos the list shows, in the order given.
    let visible: [AssetSnapshot]
    let totalCount: Int
    let isFiltered: Bool
    /// The size of the visible videos: on this phone, unknown, and only in iCloud.
    let size: SizeTotal

    init(videos: [AssetSnapshot], showsLargeOnly: Bool) {
        totalCount = videos.count
        isFiltered = showsLargeOnly
        // A video whose size Photos didn't report can't be called large, so the filter leaves it out.
        visible = showsLargeOnly ? videos.filter { ($0.fileSize ?? 0) >= Self.largeVideoThreshold } : videos
        size = visible.sizeTotal
    }

    /// The card's big number: space on this phone, "at least 2.4 GB" when some sizes are unknown.
    var value: String { size.headline }

    /// Under it: what is kept only in iCloud, then the count. "+ 860 MB in iCloud · 40 videos", or
    /// "2 of 40 videos" with the filter on.
    var detail: String {
        [size.inCloudNote, countLabel].compactMap { $0 }.joined(separator: " · ")
    }

    private var countLabel: String {
        guard isFiltered else { return totalCount.counted("video") }
        return "\(visible.count.formatted()) of \(totalCount.counted("video"))"
    }

    /// The filter is on and hides every video, so the list explains that instead of showing nothing.
    var isFilterHidingEverything: Bool { isFiltered && visible.isEmpty && totalCount > 0 }
}
