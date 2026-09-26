// Why: Review may only offer what a cleanup can really do. A saved basket can hold photos while Photos access
// is off, similar photos before this session has compared them (so no one can check each group keeps a photo),
// contact merges Roomy can't resolve yet, or items kept only in iCloud selected before Roomy was set to show only
// this phone. Showing them with made-up names or counting them in the
// confirmation would promise work that can't happen safely. They wait here, outside every count, until they can.
import Foundation

nonisolated struct BasketReview: Equatable {
    /// Items a cleanup can act on now, sorted by id.
    private(set) var ready: [BasketItem] = []
    /// Photos and videos that can't be deleted because Photos access is off.
    private(set) var waitingForPhotos: [BasketItem] = []
    /// Similar photos waiting for the scan to compare the library, so each group is known to keep a photo.
    private(set) var waitingForComparison: [BasketItem] = []
    /// Contact merges whose group Roomy can't see right now (no full access, or the scan hasn't read it).
    private(set) var waitingForContacts: [BasketItem] = []
    /// Photos and videos kept only in iCloud while `scope` leaves them out, so a stale selection can't delete them.
    private(set) var onlyInICloud: [BasketItem] = []

    init(
        items: some Sequence<BasketItem>, canUsePhotos: Bool, canCheckSimilarGroups: Bool,
        mergeableGroupIDs: Set<String>, scope: LibraryScope = .onThisPhone
    ) {
        for item in items.sorted(by: { $0.id < $1.id }) {
            if item.kind.isAsset && !canUsePhotos {
                waitingForPhotos.append(item)
            } else if !item.isInScope(scope) {
                onlyInICloud.append(item)
            } else if item.kind == .photo && !canCheckSimilarGroups {
                waitingForComparison.append(item)
            } else if item.kind == .contactGroup && !mergeableGroupIDs.contains(item.id) {
                waitingForContacts.append(item)
            } else {
                ready.append(item)
            }
        }
    }

    var isEmpty: Bool { ready.isEmpty && heldCount == 0 }
    /// Sum of known sizes of the ready items; unknown sizes count as zero, never as a guess.
    var readyBytes: Int64 { ready.reduce(0) { $0 + ($1.bytes ?? 0) } }
    /// Saved items that can't run yet, whatever the reason.
    var heldCount: Int {
        waitingForPhotos.count + waitingForComparison.count + waitingForContacts.count + onlyInICloud.count
    }
    /// The Review capsule's title; nil only when the basket is empty. Held items still open Review, where their
    /// note says why they wait and offers the way out, but they are never counted as ready.
    var barTitle: String? {
        if !ready.isEmpty { return "Review \(summary)" }
        return heldCount > 0 ? "Review · \(heldCount.formatted()) on hold" : nil
    }
    /// "3 items · 1.2 GB" for the Review capsule; just "3 items" when no size is known, never "0 KB".
    var summary: String {
        let count = ready.count.counted("item")
        return readyBytes > 0 ? "\(count) · \(readyBytes.byteString)" : count
    }

    func ready(of kind: BasketItem.Kind) -> [BasketItem] {
        ready.filter { $0.kind == kind }
    }
}
