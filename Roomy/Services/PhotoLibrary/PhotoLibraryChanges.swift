// Why: people delete, add and re-pick photos outside Roomy — in Photos, on another device, in the limited
// selection — and a cleaner that keeps showing what is gone ends up crediting itself for it. This is the one
// Photos change observer. It turns PhotoKit's callbacks into a stream of numbered changes, so the store side
// can tell which changes a scan already covers, and it registers only once access is usable, because
// registering earlier can make Photos ask for access by itself.
import Photos
import os

nonisolated final class PhotoLibraryChanges: NSObject, PHPhotoLibraryChangeObserver, LibraryChangeSource {
    private struct State {
        var isObserving = false
        /// Counts changes seen so far; each one is yielded with its number.
        var generation = 0
        /// Photos' history position at the last change Roomy saw, to catch any change not delivered.
        var token: PHPersistentChangeToken?
    }

    /// Each element is the number of a change. Only the newest waits, so a burst while busy becomes one.
    let changes: AsyncStream<Int>
    private let continuation: AsyncStream<Int>.Continuation
    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    override init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(1))
        changes = stream
        self.continuation = continuation
        super.init()
    }

    deinit {
        if state.withLockUnchecked({ $0.isObserving }) {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
        continuation.finish()
    }

    /// The number of the newest change seen. A scan started now covers every change up to it.
    var generation: Int { state.withLockUnchecked { $0.generation } }

    /// Starts observing. Call only once Photos access is usable; later calls do nothing.
    func startObserving() {
        let library = PHPhotoLibrary.shared()
        let token = library.currentChangeToken
        let isFirstCall = state.withLockUnchecked { state in
            guard !state.isObserving else { return false }
            state.isObserving = true
            state.token = token
            return true
        }
        if isFirstCall {
            library.register(self)
        }
    }

    /// Photos normally delivers background changes when the app returns; this asks its history directly,
    /// so a change is never missed. Runs off the main actor because it reads the library's history.
    @concurrent
    func checkForMissedChanges() async {
        guard let token = state.withLockUnchecked({ $0.isObserving ? $0.token : nil }) else { return }
        do {
            let history = try PHPhotoLibrary.shared().fetchPersistentChanges(since: token)
            if history.makeIterator().next() != nil {
                recordChange()
            }
        } catch PHPhotosError.persistentChangeTokenExpired {
            // History older than the saved position is gone, so a change may be hidden: it counts as one.
            recordChange()
        } catch {
            // Other errors say nothing about changes; counting them would rescan on every return, and the
            // observer still reports what Photos delivers.
            Log.scan.error("change history unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        recordChange()
    }

    private func recordChange() {
        let token = PHPhotoLibrary.shared().currentChangeToken
        let generation = state.withLockUnchecked { state in
            state.generation += 1
            state.token = token
            return state.generation
        }
        continuation.yield(generation)
    }
}
