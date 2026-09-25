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

    var sizeText: String {
        SizeTotal(
            knownBytes: bytes, knownCount: count - unsizedCount, unknownCount: unsizedCount, inCloudBytes: inCloudBytes
        ).text
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
