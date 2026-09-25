// Why: several system callbacks can fire more than once or never (image requests, the Photos delete prompt),
// and resuming a continuation twice crashes. Racing a callback against a timeout needs the same guarantee.
// Every continuation that could see two answers goes through this.
import os

nonisolated final class ResumeOnce<Value: Sendable>: Sendable {
    private let continuation: OSAllocatedUnfairLock<CheckedContinuation<Value, Never>?>

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = OSAllocatedUnfairLock(initialState: continuation)
    }

    /// Resumes the first time it is called; later calls do nothing.
    func resume(returning value: Value) {
        let pending = continuation.withLock { current in
            defer { current = nil }
            return current
        }
        pending?.resume(returning: value)
    }
}
