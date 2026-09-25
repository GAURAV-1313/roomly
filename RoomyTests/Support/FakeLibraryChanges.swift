// Why: the watcher's rules are tested by announcing library changes by hand — now, or "while the app was
// away" for the foreground check — instead of editing a real photo library.
import Foundation
import os

@testable import Roomy

final class FakeLibraryChanges: LibraryChangeSource {
    private struct State {
        var generation = 0
        var isObserving = false
        var hasMissedChange = false
    }

    let changes: AsyncStream<Int>
    private let continuation: AsyncStream<Int>.Continuation
    private let state = OSAllocatedUnfairLock(initialState: State())

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(1))
        changes = stream
        self.continuation = continuation
    }

    var generation: Int { state.withLock { $0.generation } }
    var isObserving: Bool { state.withLock { $0.isObserving } }

    func startObserving() {
        state.withLock { $0.isObserving = true }
    }

    @concurrent
    func checkForMissedChanges() async {
        let hadMissed = state.withLock { state in
            defer { state.hasMissedChange = false }
            return state.hasMissedChange
        }
        if hadMissed {
            recordChange()
        }
    }

    /// A change Photos reports right away.
    func recordChange() {
        let generation = state.withLock { state in
            state.generation += 1
            return state.generation
        }
        continuation.yield(generation)
    }

    /// A change made while Roomy was in the background, found only by `checkForMissedChanges`.
    func changeWhileAway() {
        state.withLock { $0.hasMissedChange = true }
    }
}
