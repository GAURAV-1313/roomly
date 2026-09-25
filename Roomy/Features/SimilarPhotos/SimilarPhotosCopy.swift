// Why: a photo Roomy could not read (for example one kept only in iCloud) was never compared, so "your
// library is tidy" would claim more than was checked. The Similar screen's words come from the counts here,
// as a pure value, so that promise has a test.
import Foundation

nonisolated struct SimilarPhotosCopy: Equatable {
    /// Photos the last comparison could not read.
    let uncheckedCount: Int

    var emptyTitle: String { uncheckedCount > 0 ? "No similar shots found" : "All clear" }

    var emptyMessage: String {
        guard let uncheckedNote else { return "No similar shots found. Your library is tidy." }
        return "None among the photos Roomy could compare. " + uncheckedNote
    }

    /// Said whenever some photos were not compared; nil when every photo was.
    var uncheckedNote: String? {
        guard uncheckedCount > 0 else { return nil }
        let reason = uncheckedCount == 1 ? "it's stored only in iCloud" : "they're stored only in iCloud"
        return "\(uncheckedCount.counted("photo")) couldn't be compared, usually because \(reason)."
    }
}
