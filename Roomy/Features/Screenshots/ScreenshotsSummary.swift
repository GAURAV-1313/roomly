// Why: the line under the Screenshots title shows what the dashboard tile shows: their size, then the count.
// Any part kept only in iCloud is named in the size, never counted as space on this phone. A pure value, so the
// wording has a test.
import Foundation

nonisolated struct ScreenshotsSummary: Equatable {
    let count: Int
    let size: SizeTotal

    /// "312 MB · 84 screenshots".
    var subtitle: String { "\(size.text) · \(count.counted("screenshot"))" }
}
