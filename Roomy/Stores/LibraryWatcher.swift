// Why: people delete, add and re-pick photos outside Roomy, and every screen must follow. This store turns the
// stream of library changes into refreshes by the rules in `LibraryRefreshPolicy`: a running scan finishes
// first instead of restarting, Roomy's own cleanup never triggers one, a stopped comparison only has its index
// re-read, and automatic refreshes keep a gap so a syncing library isn't scanned without pause. Photos reports
// a cleanup's own deletion asynchronously, in no documented order with the cleanup's completion, so changes
// that arrive shortly after a cleanup ends are counted as its own too. It receives the change source as a
// protocol, so these transitions are tested with a fake.
import Foundation

final class LibraryWatcher {
    /// Photos reports changes in bursts (a sync, an import); waiting this long turns a burst into one refresh.
    static let changeDelay: Duration = .seconds(1)
    /// Photos may report a cleanup's own deletion after the cleanup returns; changes seen within this long of
    /// its end are its own. Anything later, or found on returning to the app, still refreshes.
    static let ownChangeWindow: Duration = .seconds(5)

    private let scan: ScanStore
    private let source: any LibraryChangeSource
    private let canUseLibrary: () -> Bool
    private let isCleaningUp: () -> Bool
    private let changeDelay: Duration
    private let refreshGap: Duration
    private let ownChangeWindow: Duration
    private let clock = ContinuousClock()
    private var policy = LibraryRefreshPolicy()
    private var watchTask: Task<Void, Never>?
    private var missedChangesTask: Task<Void, Never>?
    /// Covers the changes that arrive in the window after a cleanup; a change waits for it before deciding.
    private var ownChangesTask: Task<Void, Never>?

    init(
        scan: ScanStore, source: any LibraryChangeSource, canUseLibrary: @escaping () -> Bool,
        isCleaningUp: @escaping () -> Bool, changeDelay: Duration = LibraryWatcher.changeDelay,
        refreshGap: Duration = LibraryRefreshPolicy.minimumGap,
        ownChangeWindow: Duration = LibraryWatcher.ownChangeWindow
    ) {
        self.scan = scan
        self.source = source
        self.canUseLibrary = canUseLibrary
        self.isCleaningUp = isCleaningUp
        self.changeDelay = changeDelay
        self.refreshGap = refreshGap
        self.ownChangeWindow = ownChangeWindow
    }

    /// Starts following changes, in one stored task for the life of the app. Call only once Photos access is
    /// usable, because registering earlier can make Photos ask for access by itself. Later calls do nothing.
    func start() {
        guard watchTask == nil else { return }
        source.startObserving()
        watchTask = Task { [weak self, changes = source.changes, changeDelay] in
            for await generation in changes {
                // try? is deliberate: the sleep throws only on cancellation, which is checked next.
                try? await Task.sleep(for: changeDelay)
                guard !Task.isCancelled, let self else { return }
                await self.libraryDidChange(generation)
            }
        }
    }

    /// Starts a full scan. It reads the library after this moment, so it covers every change seen so far.
    func startScan() {
        policy.cover(through: source.generation)
        scan.scan()
    }

    /// Called once a cleanup's report has been applied: the changes seen so far are its own, and so are those
    /// Photos reports within `ownChangeWindow` from now.
    func coverChangesSoFar() {
        policy.cover(through: source.generation)
        ownChangesTask?.cancel()
        ownChangesTask = Task { [weak self, ownChangeWindow] in
            // try? is deliberate: the sleep throws only when a newer cleanup replaced this window.
            try? await Task.sleep(for: ownChangeWindow)
            guard !Task.isCancelled, let self else { return }
            policy.cover(through: source.generation)
        }
    }

    /// Photos normally reports changes made while Roomy was away when it returns; this asks directly.
    func checkForMissedChanges() {
        missedChangesTask?.cancel()
        missedChangesTask = Task { [source] in await source.checkForMissedChanges() }
    }

    private func libraryDidChange(_ generation: Int) async {
        await waitForOwnChanges()
        await waitWhileScanning()
        guard refresh(after: generation) != .none else { return }
        let wait = policy.wait(before: clock.now, gap: refreshGap)
        if wait > .zero {
            // try? is deliberate: the sleep throws only on cancellation, which is checked next.
            try? await Task.sleep(for: wait)
            guard !Task.isCancelled else { return }
            await waitWhileScanning()
        }
        // Asked again after waiting: a scan the person started meanwhile may already cover the change.
        switch refresh(after: generation) {
        case .none:
            return
        case .rescan:
            startScan()
        case .reindex:
            policy.cover(through: source.generation)
            scan.refreshIndex()
        }
        await scan.waitForScan()
        policy.automaticRefreshEnded(at: clock.now)
    }

    private func refresh(after generation: Int) -> LibraryRefreshPolicy.Refresh {
        policy.refresh(
            after: generation, phase: scan.phase, isCleaningUp: isCleaningUp(), canUseLibrary: canUseLibrary())
    }

    /// Waits until no cleanup's window is open, so a late report of its own deletion is covered, not rescanned.
    private func waitForOwnChanges() async {
        while let window = ownChangesTask {
            await window.value
            if ownChangesTask == window {
                ownChangesTask = nil
            }
        }
    }

    private func waitWhileScanning() async {
        while scan.isScanning {
            await scan.waitForScan()
        }
    }
}
