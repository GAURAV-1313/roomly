// Why: with the "Over 500 MB" filter on, the count and size under the title must describe the list below it,
// and a filter that hides everything must say so instead of leaving a blank screen. The size names what is only
// in iCloud ("1 GB + 3 GB in iCloud"), so a video kept in iCloud never reads "0 KB". Kept pure so it is tested.
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

    /// The line under the title: "2.4 GB · 40 videos", or "1.2 GB · 2 of 40 videos" with the filter on.
    var subtitle: String { "\(size.text) · \(countLabel)" }

    private var countLabel: String {
        guard isFiltered else { return totalCount.counted("video") }
        return "\(visible.count.formatted()) of \(totalCount.counted("video"))"
    }

    /// The filter is on and hides every video, so the list explains that instead of showing nothing.
    var isFilterHidingEverything: Bool { isFiltered && visible.isEmpty && totalCount > 0 }
}
