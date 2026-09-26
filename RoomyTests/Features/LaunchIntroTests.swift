// Why: the launch intro must stay short (about two to two and a half seconds with its crossfade), play full → red
// with the shake → green as Roomy lands, never show onboarding's promise or truths, and appear only on launches
// after onboarding and never under Reduce Motion.
import XCTest

@testable import Roomy

final class LaunchIntroTests: XCTestCase {
    func testBeatsPlayRedThenGreenAsRoomyLands() {
        XCTAssertEqual(LaunchIntroBeat.beats, [.signal, .drop, .sweep, .pleased, .finish])
        let landing = LaunchIntroBeat.drop.start + .milliseconds(Int(Motion.dropDuration * 1_000))
        XCTAssertGreaterThan(landing, LaunchIntroBeat.sweep.start, "Roomy lands while the fill is cleaned down")
        XCTAssertLessThanOrEqual(landing, LaunchIntroBeat.pleased.start)
    }

    func testTheIntroLastsAboutTwoSeconds() {
        let total = LaunchIntroBeat.finish.start + .milliseconds(Int(Motion.introFade * 1_000))
        XCTAssertGreaterThanOrEqual(total, .milliseconds(2_000))
        XCTAssertLessThanOrEqual(total, .milliseconds(2_500))
        XCTAssertEqual(LaunchIntroBeat.beats.last, .finish, "the hand-off is the last beat")
    }

    func testTheStoryEndsCalmWithoutOnboardingText() {
        var scene = WelcomeScene.start
        var sawRed = false
        for beat in LaunchIntroBeat.beats {
            guard let welcomeBeat = beat.welcomeBeat else { continue }
            scene.apply(welcomeBeat)
            sawRed = sawRed || scene.capsule.redAmount > 0
        }
        XCTAssertTrue(sawRed)
        XCTAssertEqual(scene.capsule, .low)
        XCTAssertEqual(scene.mood, .pleased)
        XCTAssertTrue(scene.isRoomyShown)
        XCTAssertFalse(scene.isPromiseShown)
        XCTAssertFalse(scene.areTruthsShown)
        XCTAssertEqual(scene.signals, 1, "one shake")
        XCTAssertEqual(scene.drops, 1)
    }

    func testOnboardingOnceThenTheIntroOnEveryLaunch() {
        XCTAssertEqual(LaunchRoot(didOnboard: false, isIntroDue: false, reduceMotion: false), .onboarding)
        XCTAssertEqual(
            LaunchRoot(didOnboard: true, isIntroDue: false, reduceMotion: false), .dashboard,
            "finishing onboarding goes straight to the dashboard")
        XCTAssertEqual(LaunchRoot(didOnboard: true, isIntroDue: true, reduceMotion: false), .intro)
        XCTAssertEqual(LaunchRoot(didOnboard: true, isIntroDue: true, reduceMotion: true), .dashboard)
        XCTAssertEqual(LaunchRoot(didOnboard: false, isIntroDue: false, reduceMotion: true), .onboarding)
    }
}
