// Why: with iCloud Photos and "Optimize iPhone Storage", many originals are kept only in iCloud. Deleting one
// frees almost nothing on this phone, yet removes it from iCloud and every other device. So by default Roomy
// shows, counts and deletes only what is stored here, and the person can choose to include items kept only in
// iCloud. The rule for one asset, one saved basket item and one similar group lives here, so every screen, every
// total and the delete path decide it the same way. An unknown size counts as on this phone, as it does
// everywhere else.
// A similar group shows only its members in scope. It is hidden when fewer than two are left, because one photo
// is not a group, and when its keeper is kept only in iCloud, because another photo would then wear the Best
// badge for a pick Roomy didn't make. The group itself is unchanged: the cleanup still checks the whole group,
// so hiding members never lets it take the last photo of a moment.
import Foundation

nonisolated enum LibraryScope: String, Sendable, CaseIterable {
    /// Only photos and videos stored on this phone: the ones whose deletion frees space here.
    case onThisPhone
    /// Also items whose originals are kept only in iCloud.
    case includingICloud

    /// The UserDefaults key the choice is saved under.
    static let storageKey = "libraryScope"

    /// Whether items kept only in iCloud are shown. The Settings switch reads and writes this.
    var includesICloud: Bool {
        get { self == .includingICloud }
        set { self = newValue ? .includingICloud : .onThisPhone }
    }
}

nonisolated extension AssetSnapshot {
    func isInScope(_ scope: LibraryScope) -> Bool {
        scope == .includingICloud || size?.isInCloud != true
    }
}

nonisolated extension BasketItem {
    /// Contact merges are never outside the scope; it is about where photo files are.
    func isInScope(_ scope: LibraryScope) -> Bool {
        scope == .includingICloud || !kind.isAsset || !isInCloud
    }
}

nonisolated extension SimilarGroup {
    /// The group as the scope shows it: only members `isInScope` accepts, or nil when it can't be shown honestly.
    func limited(to isInScope: (String) -> Bool) -> SimilarGroup? {
        guard isInScope(best) else { return nil }
        let shown = members.filter(isInScope)
        guard shown.count > 1 else { return nil }
        guard shown.count < members.count else { return self }
        var group = self
        group.members = shown
        return group
    }
}
