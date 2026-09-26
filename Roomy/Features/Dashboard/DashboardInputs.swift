// Why: the dashboard summary is computed from plain values, not from the stores, so its rules can be tested
// without a photo library. These are the per-category numbers and preview ids it is built from.
import Foundation

nonisolated struct CategoryTotals: Equatable {
    var count = 0
    var bytes: Int64 = 0
    /// How many of `count` have no known size; the total then says so instead of reading low.
    var unsizedCount = 0
    /// Known bytes kept only in iCloud, named apart so a total never reads "0 KB" beside a 3 GB row.
    var inCloudBytes: Int64 = 0
    var groups = 0
    /// Items that could not be checked, such as photos with no copy on this phone. Similar photos only.
    var unchecked = 0
    /// Up to three asset ids to show as thumbnails on the category's card.
    var previewIDs: [String] = []

    /// The size on a tile's one short line: the known bytes on this phone, the iCloud bytes when nothing found is
    /// on this phone (only with iCloud items included), or "size unavailable" when no size is known. Never a guess;
    /// "at least" and the iCloud part are left to the spoken line and the category screen.
    var shortSizeText: String {
        if bytes == 0 && inCloudBytes > 0 { return "\(inCloudBytes.byteString) in iCloud" }
        if bytes == 0 && unsizedCount > 0 { return SizeTotal.unavailable }
        return bytes.byteString
    }

    /// The whole size in words for VoiceOver: "at least 12 megabytes, plus 3 gigabytes in iCloud".
    var spokenSizeText: String {
        guard unsizedCount == 0 || count > unsizedCount else { return SizeTotal.unavailable }
        let onPhone = unsizedCount > 0 ? "at least \(bytes.spokenByteString)" : bytes.spokenByteString
        guard inCloudBytes > 0 else { return onPhone }
        let inCloud = "\(inCloudBytes.spokenByteString) in iCloud"
        return bytes > 0 ? "\(onPhone), plus \(inCloud)" : inCloud
    }
}

nonisolated struct ContactTotals: Equatable {
    var access = AccessState.notDetermined
    var phase = ContactScanPhase.idle
    var groups = 0
    var extraCards = 0
    /// First letters of up to three groups' names, shown as avatars on the card.
    var initials: [String] = []
}
