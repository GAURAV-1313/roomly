// Why: the amount on the storage card counts only bytes on this phone, because that is what cleaning up gives back
// here. When everything found is kept only in iCloud or has no known size, that count is zero, and "0 KB can be
// cleaned up" above a tile listing a 3 GB video is a made-up value. The number then names what is really
// there: the iCloud bytes, or how many items have no size. Before the first index arrives nothing is known at all,
// so the amount is a skeleton rather than "0 KB". With iCloud items included, the card names what its amount
// leaves out, in the same words as the category cards.
import Foundation

nonisolated extension DashboardSummary {
    /// What the storage card's amount describes once a scan has started.
    enum FoundAmount: Equatable {
        /// Known bytes on this phone; also used when nothing was found, so an empty scan reads "0 KB".
        case onPhone(Int64)
        /// Nothing found takes space on this phone, but these known bytes are kept in iCloud.
        case inCloud(Int64)
        /// Nothing found has a known size.
        case unsized(Int)
    }

    /// Items in the photo categories: suggested similar photos, screenshots and videos.
    var foundCount: Int { similar.count + screenshots.count + videos.count }

    var foundAmount: FoundAmount {
        if reclaimableBytes > 0 || foundCount == 0 { return .onPhone(reclaimableBytes) }
        return foundInCloudBytes > 0 ? .inCloud(foundInCloudBytes) : .unsized(foundCount)
    }

    /// "+ 3 GB in iCloud" under an amount on this phone; nil when nothing found is kept only in iCloud, or when
    /// the amount already is the iCloud bytes.
    var heroCloudNote: String? {
        guard case .onPhone(let bytes) = foundAmount else { return nil }
        return SizeTotal(knownBytes: bytes, inCloudBytes: foundInCloudBytes).inCloudNote
    }

    private var foundInCloudBytes: Int64 {
        similar.inCloudBytes + screenshots.inCloudBytes + videos.inCloudBytes
    }

    /// While the library is read for the first time nothing has been found or counted, so there is no amount
    /// yet; a rescan keeps showing what the earlier scan found.
    var isAmountPending: Bool { phase == .indexing && foundCount == 0 && reclaimableBytes == 0 }

    /// Only once a scan has started is there an amount to show; before that the card shows usage alone.
    var showsAmount: Bool { canUseLibrary && phase != .idle }

    /// What can go, as a size, or as a count when no size is known.
    var heroValue: String {
        switch foundAmount {
        case .onPhone(let bytes), .inCloud(let bytes): bytes.byteString
        case .unsized(let count): count.counted("item")
        }
    }

    var heroCaption: String {
        switch foundAmount {
        case .onPhone: phase == .done ? "can be cleaned up" : "found so far"
        case .inCloud: "in iCloud, not on this phone"
        case .unsized: phase == .done ? "size unavailable" : "found so far, size unavailable"
        }
    }
}
