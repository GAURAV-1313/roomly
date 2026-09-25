// Why: a cleanup's report is applied to every store in one place, so the basket, the scan and the contact
// lists all agree on what is gone, what was kept and what must be read again. Review is derived here from the
// same rules the cleanup plan uses, so what Review offers is exactly what a cleanup may run.
import Foundation

extension AppState {
    /// Removed and unavailable assets leave every store. Spared photos leave the basket too: they are the last
    /// of their group, and a later cleanup must not take them.
    func apply(_ report: CleanupReport) {
        let gone = report.assets.removedIDs + report.assets.unavailableIDs
        basket.remove(gone + report.assets.sparedIDs + report.contacts.mergedGroupIDs)
        scan.remove(Set(gone), queued: Set(basket.items.keys))
        reconcilePhotoSelection()
        apply(report.contacts)
    }

    /// Merged groups disappear; refused groups are not offered again; groups whose cards changed since the
    /// scan leave Review and the address book is read again, so what is offered next matches the cards.
    func apply(_ merge: ContactMergeResult) {
        basket.remove(merge.changedGroupIDs + merge.refusedGroupIDs)
        contacts.remove(Set(merge.mergedGroupIDs + merge.changedGroupIDs))
        contacts.stopOffering(Set(merge.refusedGroupIDs))
        contactScanDidFinish()
        if !merge.changedGroupIDs.isEmpty && canScanContacts {
            contacts.scan()
        }
    }

    func review(of items: some Sequence<BasketItem>) -> BasketReview {
        BasketReview(
            items: items, canUsePhotos: photoAccess.state.canUse, canCheckSimilarGroups: scan.hasFinishedGrouping,
            mergeableGroupIDs: canScanContacts ? Set(contacts.groups.map(\.id)) : [])
    }

    /// A photo that is now its group's keeper, or in no group, is never left queued for removal.
    func reconcilePhotoSelection() {
        guard scan.phase == .done || scan.phase == .stopped else { return }
        basket.reconcile(
            libraryIDs: scan.allIDs, removablePhotos: scan.hasFinishedGrouping ? Set(scan.similarExtras) : nil)
    }
}
