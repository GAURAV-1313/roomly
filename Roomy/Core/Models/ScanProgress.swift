// Why: progress is reported as small value types so it can stream from background work to the UI.
import Foundation

nonisolated struct IndexProgress: Sendable, Equatable {
    var scanned = 0
    var total = 0
    var screenshots = 0
    var videos = 0

    var fraction: Double { total == 0 ? 0 : Double(scanned) / Double(total) }
}

nonisolated struct HashProgress: Sendable, Equatable {
    /// Photos tried so far, including those that could not be read.
    var done = 0
    var total = 0
    /// Photos with no image on this phone to compare (for example kept only in iCloud).
    var failed = 0

    /// Only photos that were actually read count as compared.
    var compared: Int { done - failed }

    var fraction: Double { total == 0 ? 0 : Double(done) / Double(total) }
}
