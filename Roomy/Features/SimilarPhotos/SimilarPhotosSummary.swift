// Why: the screen's numbers sit in one line under the large title (Figma "Fix 5 · C"): the size of the suggested
// extras, then the counts. Any part kept only in iCloud is named in the size ("12 MB + 3 GB in iCloud"), and an
// unknown size says so, so the line never shows a made-up value. A pure value, so the wording has a test.
import Foundation

nonisolated struct SimilarPhotosSummary: Equatable {
    let groupCount: Int
    let extraCount: Int
    /// The size of the suggested extras.
    let size: SizeTotal

    /// "48.2 MB · 12 groups · 31 extras".
    var subtitle: String {
        "\(size.text) · \(groupCount.counted("group")) · \(extraCount.counted("extra"))"
    }
}
