// Why: Screenshots now opens with the same summary card as every category, showing what the dashboard tile
// already shows: the count and their size. The size on this phone is the one-line value; any iCloud part joins
// the count underneath. Month headers keep their count and size on a detail line under the month. Pure values,
// so the wording has a test.
import Foundation

nonisolated struct ScreenshotsSummary: Equatable {
    let count: Int
    let size: SizeTotal

    var value: String { size.headline }

    var detail: String {
        let counted = count.counted("screenshot")
        guard let inCloudNote = size.inCloudNote else { return counted }
        return "\(inCloudNote) · \(counted)"
    }

    /// The line under a month's title: "24 · 36 MB".
    static func monthDetail(count: Int, size: SizeTotal) -> String {
        "\(count) · \(size.text)"
    }
}
