// Why: a similar group is held together by the links the engine found, not by its member list. Keeping the
// links lets a group that loses a photo tell whether the rest still belong together: two photos joined only
// through a deleted one are not a group.
import Foundation

nonisolated struct MemberLink: Sendable, Hashable {
    let first: String
    let second: String

    func touches(_ ids: Set<String>) -> Bool {
        ids.contains(first) || ids.contains(second)
    }
}
