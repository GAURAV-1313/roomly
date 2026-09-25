// Why: the motion spec promises calm, bounded timing: the dashboard's fade-up never waits on more than six
// blocks, and the usage bar's sweep never takes longer than half a second however many ticks are used.
import XCTest

@testable import Roomy

final class MotionTimingTests: XCTestCase {
    func testStaggerIsEvenlySpacedAndCapped() {
        XCTAssertEqual(Motion.staggerDelay(for: 0), 0)
        XCTAssertEqual(Motion.staggerDelay(for: 2), 0.1, accuracy: 0.000_1)
        XCTAssertEqual(Motion.staggerDelay(for: 40), Motion.staggerDelay(for: Motion.staggerLimit))
        XCTAssertEqual(Motion.staggerDelay(for: -3), 0)
    }

    func testTickSweepStartsAfterTheCardAndStaysUnderItsLimit() {
        XCTAssertEqual(Motion.tickDelay(at: 0, of: 50), Motion.sweepDelay)
        XCTAssertEqual(Motion.tickDelay(at: 10, of: 50), Motion.sweepDelay + 10 * Motion.tickStep, accuracy: 0.000_1)

        let used = 200
        let lastTick = Motion.tickDelay(at: used - 1, of: used) - Motion.sweepDelay
        XCTAssertLessThanOrEqual(lastTick, Motion.sweepLimit, "a long bar squeezes its steps, never its limit")
    }
}
