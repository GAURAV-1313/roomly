// Why: the words on the one destructive button and its confirmation must say exactly what will happen —
// delete, merge, or both, and how many times iOS will ask — so they are computed here, from counts of what
// can really run, and tested.
import Foundation

nonisolated struct ReviewSummary: Equatable {
    var assetCount = 0
    var contactGroupCount = 0
    /// Space on this phone; the only bytes the total and the button claim.
    var bytes: Int64 = 0
    /// Originals kept only in iCloud, mentioned so a big file that frees little here is not a surprise.
    var bytesInCloud: Int64 = 0

    /// Counts exactly the given items: what Review lists as ready, never what is on hold.
    init(items: [BasketItem]) {
        let assetCount = items.count(where: \.kind.isAsset)
        self.init(
            assetCount: assetCount, contactGroupCount: items.count - assetCount,
            bytes: items.reduce(0) { $0 + ($1.bytes ?? 0) },
            bytesInCloud: items.reduce(0) { $0 + ($1.bytesInCloud ?? 0) })
    }

    init(assetCount: Int = 0, contactGroupCount: Int = 0, bytes: Int64 = 0, bytesInCloud: Int64 = 0) {
        self.assetCount = assetCount
        self.contactGroupCount = contactGroupCount
        self.bytes = bytes
        self.bytesInCloud = bytesInCloud
    }

    var hasAssets: Bool { assetCount > 0 }
    var hasContacts: Bool { contactGroupCount > 0 }
    /// iOS asks once per request, and a request carries at most `CleanupPlan.assetsPerPrompt` items.
    var promptCount: Int { CleanupPlan.promptCount(forAssets: assetCount) }

    /// The size when one is known; otherwise the count, because "0 KB" would be made up.
    var totalValue: String {
        if bytes > 0 { return bytes.byteString }
        return hasAssets ? assetCount.counted("item") : contactGroupCount.counted("merge")
    }

    var totalDetail: String {
        let count = (assetCount + contactGroupCount).counted("item")
        return "\(count) · nothing is deleted yet"
    }

    /// "Also 3 GB kept only in iCloud, not counted above."; nil when nothing selected is only in iCloud.
    var cloudNote: String? {
        guard hasAssets, bytesInCloud > 0 else { return nil }
        return "Also \(bytesInCloud.byteString) kept only in iCloud, not counted above."
    }

    var actionTitle: String {
        switch (hasAssets, hasContacts) {
        case (true, true): "Delete \(assetCount.formatted()) and merge \(contactGroupCount.formatted())"
        case (true, false) where bytes > 0: "Delete \(assetCount.counted("item")) · \(bytes.byteString)"
        case (true, false): "Delete \(assetCount.counted("item"))"
        case (false, true): "Merge \(contactGroupCount.counted("group"))"
        case (false, false): "Nothing selected"
        }
    }

    var confirmTitle: String {
        switch (hasAssets, hasContacts) {
        case (true, true): "Delete \(assetCount.counted("item")) and merge \(contactGroupCount.counted("group"))?"
        case (true, false): "Delete \(assetCount.counted("item"))?"
        case (false, true): "Merge \(contactGroupCount.counted("group"))?"
        case (false, false): ""
        }
    }

    var confirmMessage: String {
        var parts: [String] = []
        if hasAssets {
            parts.append("\(Self.assetsNote) \(promptNote)")
        }
        if hasContacts {
            parts.append(
                "\(Self.contactsNote) "
                    + "Notes on the removed cards can't be read by apps, so they aren't carried over or backed up.")
        }
        return parts.joined(separator: " ")
    }

    /// The line under the red button: the first sentence of the confirmation, for photos when there are any,
    /// else for contacts. It fills the Review capsule's old footprint, so a second tap there lands on text.
    var dockNote: String? {
        if hasAssets { return Self.assetsNote }
        if hasContacts { return Self.contactsNote }
        return nil
    }

    private static let assetsNote = "Photos and videos move to Recently Deleted and stay there for 30 days."
    private static let contactsNote = "Duplicate cards become one card each, and a backup of every card is saved first."

    private var promptNote: String {
        guard promptCount > 1 else { return "iOS will ask you once more." }
        let batch = CleanupPlan.assetsPerPrompt.formatted()
        return "iOS will ask you \(promptCount.formatted()) times, once for every \(batch) items."
    }

    var confirmButton: String {
        switch (hasAssets, hasContacts) {
        case (true, true): "Delete and Merge"
        case (true, false): "Delete \(assetCount.counted("Item"))"
        case (false, true): "Merge \(contactGroupCount.counted("Group"))"
        case (false, false): ""
        }
    }
}
