// Why: a keeper the person chose in Compare must win over the automatic pick for as long as the photo is in a
// group, across rescans and launches. The choices are saved here, beside the scan store that owns the groups.
// A choice is forgotten only once its photo leaves the library or is compared and found in no group, so it
// cannot resurface in a later group — but a scan that merely couldn't read the photo this time (a timeout, an
// image only in iCloud) never erases it.
import Foundation

struct KeeperChoices {
    private var chosen: Set<String>
    private let file: JSONFileStore<[String]>

    init(filename: String) {
        file = JSONFileStore(filename: filename)
        chosen = Set(file.load() ?? [])
    }

    /// `group` with `id` as its keeper, replacing any earlier choice in that group.
    mutating func choose(_ id: String, in group: SimilarGroup) -> SimilarGroup {
        chosen.subtract(group.members)
        chosen.insert(id)
        file.save(chosen.sorted())
        return group.withKeeper(id)
    }

    /// Fresh groups with every saved choice applied. `unchecked` holds photos this scan could not compare;
    /// their choices wait for a scan that can.
    mutating func applied(
        to groups: [SimilarGroup], libraryIDs: Set<String>, unchecked: Set<String>
    ) -> [SimilarGroup] {
        let grouped = Set(groups.flatMap(\.members))
        let kept = chosen.filter { grouped.contains($0) || (libraryIDs.contains($0) && unchecked.contains($0)) }
        if kept != chosen {
            chosen = kept
            file.save(chosen.sorted())
        }
        return groups.map { group in
            group.members.first(where: kept.contains).map(group.withKeeper) ?? group
        }
    }
}
