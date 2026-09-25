// Why: a total that silently counts unknown sizes as zero reads "0 KB" for photos that take real space, and so
// does one that counts only this phone's bytes next to rows showing a video kept in iCloud. A total therefore
// remembers how many sizes it could not count and how much is kept only in iCloud, and says so instead of
// showing a made-up value.
import Foundation

nonisolated struct SizeTotal: Equatable, Sendable {
    /// Known bytes on this phone.
    var knownBytes: Int64 = 0
    var knownCount = 0
    var unknownCount = 0
    /// Known bytes kept only in iCloud: deleting frees them there, not on this phone.
    var inCloudBytes: Int64 = 0

    init(knownBytes: Int64 = 0, knownCount: Int = 0, unknownCount: Int = 0, inCloudBytes: Int64 = 0) {
        self.knownBytes = knownBytes
        self.knownCount = knownCount
        self.unknownCount = unknownCount
        self.inCloudBytes = inCloudBytes
    }

    init(sizes: some Sequence<Int64?>) {
        for size in sizes {
            if let size {
                knownBytes += size
                knownCount += 1
            } else {
                unknownCount += 1
            }
        }
    }

    /// "12 MB"; "at least 12 MB" when some sizes are unknown; "size unavailable" when none is known. Bytes kept
    /// only in iCloud are named apart: "12 MB + 3 GB in iCloud", or "3 GB in iCloud" when nothing is here.
    var text: String {
        guard unknownCount == 0 || knownCount > 0 else { return "size unavailable" }
        let onPhone = unknownCount > 0 ? "at least \(knownBytes.byteString)" : knownBytes.byteString
        guard inCloudBytes > 0 else { return onPhone }
        let inCloud = "\(inCloudBytes.byteString) in iCloud"
        return knownBytes > 0 ? "\(onPhone) + \(inCloud)" : inCloud
    }

    /// The big number on a summary card: the size on this phone only, so it fits on one line. When nothing is
    /// on this phone, the iCloud amount itself.
    var headline: String {
        guard knownBytes > 0 || inCloudBytes == 0 else { return "\(inCloudBytes.byteString) in iCloud" }
        guard unknownCount == 0 || knownCount > 0 else { return "size unavailable" }
        return unknownCount > 0 ? "at least \(knownBytes.byteString)" : knownBytes.byteString
    }

    /// What the headline leaves out: "+ 860 MB in iCloud", or nil.
    var inCloudNote: String? {
        guard knownBytes > 0, inCloudBytes > 0 else { return nil }
        return "+ \(inCloudBytes.byteString) in iCloud"
    }
}

nonisolated extension Sequence where Element == AssetSnapshot {
    /// Space on this phone, like `totalBytes`, remembering which sizes are unknown and what is only in iCloud.
    var sizeTotal: SizeTotal {
        var total = SizeTotal(sizes: map(\.bytesOnPhone))
        total.inCloudBytes = reduce(0) { $0 + ($1.size?.inCloudOnly ?? 0) }
        return total
    }
}
