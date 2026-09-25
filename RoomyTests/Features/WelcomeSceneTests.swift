// Why: the Welcome story must play in the storyboard's order and time, end calm — low, green, Roomy pleased, all
// text shown, no red — and land there from any moment when the person taps, without replaying the drop, the shake
// or the haptic. The wash's drift must stay within its few percent.
import XCTest

@testable import Roomy

final class WelcomeSceneTests: XCTestCase {
    func testBeatsPlayInStoryboardOrderWithinAboutTwoAndAHalfSeconds() {
        XCTAssertEqual(WelcomeScene.beats, [.drop, .signal, .sweep, .promise, .truths, .pleased])
        XCTAssertEqual(WelcomeScene.beats.first?.start, .milliseconds(300))
        XCTAssertLessThanOrEqual(WelcomeScene.beats.last?.start ?? .zero, .milliseconds(4000))
    }

    func testTheStoryStartsFullAndEndsAtRest() {
        XCTAssertEqual(WelcomeScene.start.capsule, .full)
        XCTAssertFalse(WelcomeScene.start.isRoomyShown)

        var scene = WelcomeScene.start
        for beat in WelcomeScene.beats {
            scene.apply(beat)
        }
        XCTAssertTrue(scene.isAtRest)
        XCTAssertEqual(scene.drops, 1)
        XCTAssertEqual(scene.signals, 1)
    }

    func testRedAppearsOnlyDuringTheSignal() {
        var scene = WelcomeScene.start
        scene.apply(.drop)
        scene.apply(.signal)
        XCTAssertEqual(scene.capsule.redAmount, 1)
        XCTAssertEqual(scene.capsule.fill, WelcomeCapsuleStage.full.fill)
        scene.apply(.sweep)
        XCTAssertEqual(scene.capsule.redAmount, 0)
        XCTAssertEqual(scene.capsule.greenAmount, 1)
        XCTAssertLessThan(scene.capsule.fill, WelcomeCapsuleStage.full.fill)
        XCTAssertEqual(WelcomeScene.rest.capsule.redAmount, 0)
    }

    func testSettlingMidStoryLandsAtRestWithoutReplayingTheDropOrSignal() {
        var scene = WelcomeScene.start
        scene.apply(.drop)
        scene.settle()
        XCTAssertTrue(scene.isAtRest)
        XCTAssertEqual(scene.drops, 1)
        XCTAssertEqual(scene.signals, 0)
        XCTAssertEqual(WelcomeScene.rest.drops, 0)
    }

    func testDriftStaysWithinItsAmplitudeAndLoops() {
        for second in stride(from: 0.0, through: WelcomeDrift.period, by: 0.5) {
            let ends = WelcomeDrift.ends(at: second)
            XCTAssertLessThanOrEqual(abs(ends.start.y), WelcomeDrift.amplitude + 0.000_1)
            XCTAssertLessThanOrEqual(abs(ends.end.y - 1), WelcomeDrift.amplitude + 0.000_1)
        }
        let start = WelcomeDrift.ends(at: 0)
        let later = WelcomeDrift.ends(at: WelcomeDrift.period)
        XCTAssertEqual(start.start.x, later.start.x, accuracy: 0.000_1)
    }
}
