// Why: the basket is the single source of truth for selection. Every checkmark in the app reads it and
// every tap writes it, so selection survives navigation and crashes (it is saved on each change). Nothing
// here deletes anything; the Review screen is the only place a destructive action exists.
import Foundation
import Observation

@Observable
final class Basket {
    private(set) var items: [String: BasketItem]
    private let file: JSONFileStore<[BasketItem]>

    init(filename: String = "roomy-basket.json") {
        file = JSONFileStore(filename: filename)
        let saved = file.load() ?? []
        items = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }
    /// Space the selected assets use on this phone: what deleting them gives back here.
    var bytes: Int64 { items.values.reduce(0) { $0 + ($1.bytes ?? 0) } }
    /// Selected originals kept only in iCloud: shown in Review, never added to what it frees on this phone.
    var bytesInCloud: Int64 { items.values.reduce(0) { $0 + ($1.bytesInCloud ?? 0) } }

    func contains(_ id: String) -> Bool { items[id] != nil }

    func containsAll(_ ids: some Sequence<String>) -> Bool {
        var sawAny = false
        for id in ids {
            guard contains(id) else { return false }
            sawAny = true
        }
        return sawAny
    }

    func items(of kind: BasketItem.Kind) -> [BasketItem] {
        items.values.filter { $0.kind == kind }.sorted { $0.id < $1.id }
    }

    func toggle(_ snapshot: AssetSnapshot) {
        toggle(BasketItem(snapshot))
    }

    func toggle(_ group: ContactGroup) {
        toggle(BasketItem(group))
    }

    /// Adds all when any is missing; otherwise removes all. Backs every "Select all / Deselect" control.
    func toggleAll(_ snapshots: [AssetSnapshot]) {
        toggleAll(snapshots.map(BasketItem.init))
    }

    func toggleAll(_ groups: [ContactGroup]) {
        toggleAll(groups.map(BasketItem.init))
    }

    func add(_ snapshots: some Sequence<AssetSnapshot>) {
        insert(snapshots.map(BasketItem.init))
    }

    func add(_ groups: some Sequence<ContactGroup>) {
        insert(groups.map(BasketItem.init))
    }

    func remove(_ ids: some Sequence<String>) {
        for id in ids {
            items.removeValue(forKey: id)
        }
        save()
    }

    /// Drops items of the given kinds that no longer exist, for example photos deleted in the Photos app.
    func prune(keeping ids: Set<String>, of kinds: Set<BasketItem.Kind>) {
        let stale = items.values.filter { kinds.contains($0.kind) && !ids.contains($0.id) }.map(\.id)
        guard !stale.isEmpty else { return }
        remove(stale)
    }

    /// Brings the basket in line with a finished scan: drops assets that are no longer in the library and,
    /// when grouping has finished, every photo that isn't a removable extra — one that became its group's
    /// keeper, or is in no group any more — so a cleanup can never take the last copy of a moment.
    func reconcile(libraryIDs: Set<String>, removablePhotos: Set<String>?) {
        prune(keeping: libraryIDs, of: [.photo, .screenshot, .video])
        if let removablePhotos {
            prune(keeping: removablePhotos, of: [.photo])
        }
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func toggle(_ item: BasketItem) {
        if contains(item.id) {
            remove([item.id])
        } else {
            insert([item])
        }
    }

    private func toggleAll(_ newItems: [BasketItem]) {
        if containsAll(newItems.map(\.id)) {
            remove(newItems.map(\.id))
        } else {
            insert(newItems)
        }
    }

    private func insert(_ newItems: [BasketItem]) {
        for item in newItems {
            items[item.id] = item
        }
        save()
    }

    private func save() {
        file.save(Array(items.values))
    }
}
