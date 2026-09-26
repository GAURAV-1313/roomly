// Why: sizes are shown in many places and must always match Settings' base-1000 units, so formatting
// and summing live in one spot instead of being re-typed in every view.
import Foundation

nonisolated extension Int64 {
    /// "1.2 GB", "312 MB", "0 KB" — the same units Settings › iPhone Storage uses, never "Zero KB". The number
    /// and unit are joined by a no-break space, so a size never wraps as "225.05 / GB".
    var byteString: String {
        // A new formatter per call: ByteCountFormatter isn't Sendable, and it is cheap to create.
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: self).replacingOccurrences(of: " ", with: "\u{00A0}")
    }

    /// "312 megabytes": the same amount as `byteString`, its unit in full words so VoiceOver reads a sentence.
    /// A unit it doesn't know (another language's) is left as `byteString` shows it.
    var spokenByteString: String {
        let parts = byteString.split(separator: "\u{00A0}").map(String.init)
        guard parts.count == 2, let unit = Self.spokenUnits[parts[1]] else { return byteString }
        return "\(parts[0]) \(parts[0] == "1" ? unit : unit + "s")"
    }

    private static let spokenUnits = ["KB": "kilobyte", "MB": "megabyte", "GB": "gigabyte", "TB": "terabyte"]
}

nonisolated extension Sequence where Element == AssetSnapshot {
    /// Space these would give back on this phone: the sum of known bytes stored here. Originals kept only in
    /// iCloud and unavailable sizes count as zero, never as a guess.
    var totalBytes: Int64 { reduce(0) { $0 + ($1.bytesOnPhone ?? 0) } }
}
