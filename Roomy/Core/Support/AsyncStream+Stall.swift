// Why: a system request can stop answering without ever failing — Photos fetching a video from iCloud with no
// connection, for example — and a screen waiting on it would spin forever. Guarding its stream ends it with a
// stated event once nothing has arrived for too long. Every event, progress included, restarts the clock, so
// a slow download that keeps reporting is never cut off.
import Foundation
import os

nonisolated extension AsyncStream where Element: Sendable {
    /// Passes every element through. When none arrives for `timeout`, yields `stalled` and ends. Ending early,
    /// for any reason, stops iterating this stream, which runs its termination handler and so cancels the work
    /// behind it.
    func endingWhenStalled(after timeout: Duration, with stalled: Element) -> AsyncStream<Element> {
        let upstream = self
        return AsyncStream { continuation in
            let task = Task {
                let clock = ContinuousClock()
                let watch = OSAllocatedUnfairLock(initialState: StallWatch(lastEvent: clock.now))
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await element in upstream {
                            let now = clock.now
                            guard watch.withLock({ $0.admitsEvent(at: now) }) else { return }
                            continuation.yield(element)
                        }
                    }
                    group.addTask {
                        while !Task.isCancelled {
                            let now = clock.now
                            guard let wake = watch.withLock({ $0.nextCheck(after: timeout, now: now) }) else {
                                continuation.yield(stalled)
                                return
                            }
                            // try? is deliberate: the sleep throws only when cancelled, and the loop checks that.
                            try? await Task.sleep(until: wake, clock: clock)
                        }
                    }
                    // Whichever ends first, the events or the watchdog, ends the other.
                    await group.next()
                    group.cancelAll()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// When the last event arrived, and whether the watchdog has already ended the stream. Both are decided under
/// one lock, so an event and the stalled event can never both get through.
private nonisolated struct StallWatch: Sendable {
    var lastEvent: ContinuousClock.Instant
    var hasStalled = false

    /// Restarts the clock; false once the stream has ended as stalled, so the late event is dropped.
    mutating func admitsEvent(at now: ContinuousClock.Instant) -> Bool {
        lastEvent = now
        return !hasStalled
    }

    /// When to look again, or nil once `timeout` has passed without an event, which marks the stream stalled.
    mutating func nextCheck(after timeout: Duration, now: ContinuousClock.Instant) -> ContinuousClock.Instant? {
        let deadline = lastEvent + timeout
        guard now >= deadline else { return deadline }
        hasStalled = true
        return nil
    }
}
