// Why: every screen, tile, total and "Select All" must describe the same items, so they all read the scan
// through these scoped views, filtered by `scope` in this one place (the rule itself is `LibraryScope`). The
// views are computed, never stored, so there is one copy of the results and changing the scope updates every
// screen at once, without a rescan. Only the cleanup and the basket's reconciling read the `all…` lists: a
// hidden photo is still in the library, and a group's last photo must be protected whether it is shown or not.
import Foundation

extension ScanStore {
    var screenshots: [AssetSnapshot] { scoped(allScreenshots) }
    /// Most space on this phone first; with iCloud items included, those kept only in iCloud come after.
    var videos: [AssetSnapshot] { scoped(allVideos) }
    /// Groups as the scope shows them; see `SimilarGroup.limited(to:)` for when one is hidden.
    var similarGroups: [SimilarGroup] {
        guard scope == .onThisPhone else { return allSimilarGroups }
        return allSimilarGroups.compactMap { $0.limited(to: isInScope) }
    }

    /// The group as the scope shows it; nil when it is gone or the scope hides it.
    func similarGroup(_ id: String) -> SimilarGroup? {
        guard let group = allSimilarGroups.first(where: { $0.id == id }) else { return nil }
        return scope == .onThisPhone ? group.limited(to: isInScope) : group
    }

    /// The extras Roomy suggests, leaving out any the person marked in Photos. Totals and bulk selection use it.
    var suggestedExtras: [String] { similarGroups.flatMap(\.suggestedExtras) }
    var similarBytes: Int64 { bytes(of: suggestedExtras) }
    var similarSize: SizeTotal { sizeTotal(of: suggestedExtras) }
    /// Space on this phone that the items shown can give back.
    var reclaimableBytes: Int64 { screenshots.totalBytes + videos.totalBytes + similarBytes }

    /// Every non-keeper photo across all groups, shown or not: what the basket may keep holding.
    var allSimilarExtras: [String] { allSimilarGroups.flatMap(\.extras) }

    /// An asset the scan doesn't know has no size, and an unknown size counts as on this phone.
    func isInScope(_ id: String) -> Bool {
        snapshot(id)?.isInScope(scope) ?? true
    }

    private func scoped(_ snapshots: [AssetSnapshot]) -> [AssetSnapshot] {
        scope == .onThisPhone ? snapshots.filter { $0.isInScope(scope) } : snapshots
    }
}
