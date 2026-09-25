// Why: runs an approved cleanup through the one `Cleaner`, then keeps the honest part of the story: how much
// each cleanup left waiting in Recently Deleted (saved, so it survives a relaunch) and, once free space is
// measured again and has risen by about that much, the rise — never more than was moved. A rise far larger
// than what was moved has a cause Roomy didn't see, so it never clears the reminder, but it may have included
// Recently Deleted being emptied, so from then on the reminder is kept as uncertain.
import Foundation
import Observation

nonisolated enum CleanupStep: Sendable, Equatable {
    case mergingContacts
    case removingPhotos
}

nonisolated enum CleanupState: Sendable, Equatable {
    case idle
    case working(CleanupStep)
    case finished(CleanupReport)
}

@Observable
final class CleanupStore {
    private(set) var state: CleanupState = .idle
    /// Space moved to Recently Deleted and not yet seen as free.
    private(set) var pending: PendingReclaim?
    /// The measured rise in free space once it matched the pending space, capped at what was moved.
    private(set) var reclaimedBytes: Int64?
    private(set) var backups: [URL] = []

    private let cleaner: any Cleaner
    private let file: JSONFileStore<PendingReclaim>

    init(cleaner: any Cleaner, filename: String = "roomy-pending-reclaim.json") {
        self.cleaner = cleaner
        file = JSONFileStore(filename: filename)
        pending = file.load()
        backups = cleaner.backups()
    }

    var isWorking: Bool {
        if case .working = state { return true }
        return false
    }

    func run(_ plan: CleanupPlan, freeBefore: Int64, at date: Date = .now) async -> CleanupReport {
        reclaimedBytes = nil
        // What the plan held back is reported, never run: nothing is asked of Photos or Contacts for it.
        var report = CleanupReport(held: plan.held)
        if !plan.contactGroups.isEmpty {
            state = .working(.mergingContacts)
            report.contacts = await cleaner.merge(plan.contactGroups)
            backups = cleaner.backups()
        }
        if !plan.assetIDs.isEmpty {
            state = .working(.removingPhotos)
            report.assets = await cleaner.removeAssets(plan.assetIDs, keepingOneOf: plan.similarGroups)
            report.removedBytes = report.assets.removedIDs.reduce(0) { $0 + (plan.bytesByID[$1] ?? 0) }
        }
        report.assets.sparedIDs = plan.sparedIDs + report.assets.sparedIDs
        // With every size unavailable there is nothing to measure a rise against, so nothing is remembered.
        if report.removedBytes > 0 {
            remember(report, freeBefore: freeBefore, at: date)
        }
        state = .finished(report)
        return report
    }

    /// Clears a finished result. A running cleanup is never interrupted by this.
    func dismissResult() {
        guard case .finished = state else { return }
        state = .idle
    }

    /// Called with a fresh free-space reading whenever the app comes back to the foreground. Cleanups iOS has
    /// emptied on its own are dropped first, so their space is never credited to a newer one.
    func measure(freeNow: Int64, at date: Date = .now) {
        guard let saved = pending else { return }
        guard let current = saved.expiring(at: date) else {
            forgetPending()
            return
        }
        switch current.reading(freeNow: freeNow) {
        case .reclaimed(let credited):
            reclaimedBytes = credited
            forgetPending()
        case .unexplained:
            // Something else freed space, perhaps along with Recently Deleted; the reminder stays as uncertain, and
            // the next reading starts from here.
            keepPending(current.rebased(freeNow: freeNow))
        case .waiting where current != saved:
            keepPending(current)
        case .waiting:
            break
        }
    }

    func dismissReclaimed() {
        reclaimedBytes = nil
    }

    /// A second cleanup before the first is reclaimed becomes its own entry, with its own 30 days.
    private func remember(_ report: CleanupReport, freeBefore: Int64, at date: Date) {
        let entry = PendingReclaim.Entry(bytes: report.removedBytes, itemCount: report.removedCount, date: date)
        let next =
            pending?.adding(entry, freeBefore: freeBefore)
            ?? PendingReclaim(entries: [entry], freeBefore: freeBefore)
        keepPending(next)
    }

    private func keepPending(_ next: PendingReclaim) {
        pending = next
        file.save(next)
    }

    private func forgetPending() {
        pending = nil
        file.delete()
    }
}
