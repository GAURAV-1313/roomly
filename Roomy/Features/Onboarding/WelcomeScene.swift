// Why: the Welcome story (Figma storyboard 147:12369) is told once: a nearly full capsule warms into red, is
// cleaned down to calm green while Roomy lands, and the promise and truths rise in. What the screen shows at each
// moment is plain data here, and the beats and their times are a pure list, so the order, the timing and "any tap
// lands on the rest pose" are unit-tested. The view only runs the list and animates each change.
import Foundation

/// The "iPhone storage" capsule tells a story, not a measurement: full, a short red signal, then low.
nonisolated enum WelcomeCapsuleStage: Sendable, Equatable {
    case full
    case signal
    case low

    /// How much of the capsule is filled.
    var fill: Double {
        switch self {
        case .full, .signal: 0.95
        case .low: 0.35
        }
    }

    /// How far the fill has warmed into red: only during the signal, never at rest.
    var redAmount: Double { self == .signal ? 1 : 0 }
    /// How far the fill has settled into green.
    var greenAmount: Double { self == .low ? 1 : 0 }
}

/// One step of the story, and when it starts after the page appears.
nonisolated enum WelcomeBeat: Sendable, Equatable, CaseIterable {
    case drop
    case signal
    case sweep
    case promise
    case truths
    case pleased

    var start: Duration {
        switch self {
        // Paced so the full, red, shaking capsule is on screen long enough to read before it is cleaned down.
        case .drop: .milliseconds(300)
        case .signal: .milliseconds(1200)
        case .sweep: .milliseconds(2600)
        case .promise: .milliseconds(3000)
        case .truths: .milliseconds(3500)
        case .pleased: .milliseconds(3800)
        }
    }
}

nonisolated struct WelcomeScene: Sendable, Equatable {
    enum Mood: Sendable, Equatable {
        case concerned
        case curious
        case pleased
    }

    var capsule = WelcomeCapsuleStage.full
    var mood = Mood.concerned
    var isRoomyShown = false
    var isPromiseShown = false
    var areTruthsShown = false
    /// Counted, not flagged, so jumping to the rest pose never replays the drop, the shake or the haptic.
    private(set) var drops = 0
    private(set) var signals = 0

    /// The first frame: the capsule is already nearly full, nothing else is on screen yet.
    static let start = WelcomeScene()

    /// The pose the story ends on, and what Reduce Motion shows at once.
    static var rest: WelcomeScene {
        var scene = WelcomeScene.start
        scene.settle()
        return scene
    }

    /// The beats in the order they play.
    static let beats = WelcomeBeat.allCases.sorted { $0.start < $1.start }

    var isAtRest: Bool {
        capsule == .low && mood == .pleased && isRoomyShown && isPromiseShown && areTruthsShown
    }

    mutating func apply(_ beat: WelcomeBeat) {
        switch beat {
        case .drop:
            isRoomyShown = true
            drops += 1
        case .signal:
            capsule = .signal
            signals += 1
        case .sweep:
            capsule = .low
            mood = .curious
        case .promise: isPromiseShown = true
        case .truths: areTruthsShown = true
        case .pleased: mood = .pleased
        }
    }

    /// A tap, Skip or Continue lands here from any moment of the story.
    mutating func settle() {
        capsule = .low
        mood = .pleased
        isRoomyShown = true
        isPromiseShown = true
        areTruthsShown = true
    }
}
