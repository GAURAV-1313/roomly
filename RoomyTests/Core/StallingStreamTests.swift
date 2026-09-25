// Why: the video sheet spun forever when Photos never answered. The stall guard is what turns silence into a
// stated failure, so these tests pin that it fires on silence, never on a slow stream that keeps talking, and
// that ending early cancels the work behind the stream.
import XCTest
import os

@testable import Roomy

final class StallingStreamTests: XCTestCase {
    /// Regression: a request that never answers used to leave the sheet on a spinner.
    func testSilenceEndsWithTheStalledElement() async {
        let terminated = OSAllocatedUnfairLock(initialState: false)
        let silent = AsyncStream<Int> { continuation in
            continuation.onTermination = { _ in terminated.withLock { $0 = true } }
        }
        var received: [Int] = []
        for await element in silent.endingWhenStalled(after: .milliseconds(50), with: -1) {
            received.append(element)
        }
        XCTAssertEqual(received, [-1])
        try? await Task.sleep(for: .milliseconds(50))  // try?: only cancellation throws, and nothing cancels it.
        XCTAssertTrue(terminated.withLock { $0 }, "ending early cancels the request behind the stream")
    }

    func testAStreamThatKeepsReportingIsNeverCutOff() async {
        let chatty = AsyncStream<Int> { continuation in
            let task = Task {
                for step in 1...6 {
                    try? await Task.sleep(for: .milliseconds(40))  // try?: the stream is never cancelled here.
                    continuation.yield(step)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
        var received: [Int] = []
        for await element in chatty.endingWhenStalled(after: .milliseconds(200), with: -1) {
            received.append(element)
        }
        XCTAssertEqual(received, [1, 2, 3, 4, 5, 6])
    }

    func testAnAnswerBeforeTheTimeoutPassesThroughUnchanged() async {
        let quick = AsyncStream<Int> { continuation in
            continuation.yield(7)
            continuation.finish()
        }
        var received: [Int] = []
        for await element in quick.endingWhenStalled(after: .seconds(5), with: -1) {
            received.append(element)
        }
        XCTAssertEqual(received, [7])
    }
}
