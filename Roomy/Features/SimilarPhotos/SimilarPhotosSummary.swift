// Why: the summary card's big value must stay on one line, so it shows only the size on this phone; any part
// kept only in iCloud goes on the line under it, before the counts. Splitting the old one-line summary this
// way is a presentation rule, so it is a pure value with a test.
import Foundation

nonisolated struct SimilarPhotosSummary: Equatable {
    let groupCount: Int
    let extraCount: Int
    /// The size of the suggested extras.
    let size: SizeTotal

    var value: String { size.headline }

    var detail: String {
        let counts = "\(groupCount) groups · \(extraCount) extras"
        guard let inCloudNote = size.inCloudNote else { return counts }
        return "\(inCloudNote) · \(counts)"
    }
}
