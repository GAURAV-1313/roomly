// Why: a pose is a bag of numbers (fractions of the mascot's size), so SwiftUI can animate between any two
// moods by interpolation. Values are a 1:1 port of the original Flutter painter.
import SwiftUI

struct Brow: Equatable {
    var opacity = 0.0
    var startY = 0.0
    var endY = 0.0
}

struct MascotPose: Equatable {
    /// 1 = open eyes, 0 = closed lids.
    var eyeOpenness = 1.0
    var eyeRadius = 0.06
    var pupilRadius = 0.032
    var pupilOffsetX = 0.0
    var pupilOffsetY = 0.0
    var lidHalfWidth = 0.045
    var lidOffsetY = 0.0
    /// Positive curves down (calm), negative curves up (happy).
    var lidCurve = 0.025
    var leftBrow = Brow()
    var rightBrow = Brow()
    /// 0 = closed; 0.05 for success, 0.03 for error.
    var beakGap = 0.0
    /// Radians; negative raises the wings.
    var wingAngle = 0.0
    /// 0 = dark wings, 1 = accent wings.
    var wingAccent = 0.0
    var tilt = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var crestLift = 0.0

    private static let animatedValues: [WritableKeyPath<MascotPose, Double>] = [
        \.eyeOpenness, \.eyeRadius, \.pupilRadius, \.pupilOffsetX, \.pupilOffsetY, \.lidHalfWidth, \.lidOffsetY,
        \.lidCurve, \.leftBrow.opacity, \.leftBrow.startY, \.leftBrow.endY, \.rightBrow.opacity,
        \.rightBrow.startY, \.rightBrow.endY, \.beakGap, \.wingAngle, \.wingAccent, \.tilt, \.scaleX, \.scaleY,
        \.crestLift,
    ]

    var vector: AnimatableVector {
        get { AnimatableVector(values: Self.animatedValues.map { self[keyPath: $0] }) }
        set {
            for (keyPath, value) in zip(Self.animatedValues, newValue.values) {
                self[keyPath: keyPath] = value
            }
        }
    }
}

/// A vector of doubles SwiftUI can interpolate. Missing trailing values count as zero.
struct AnimatableVector: VectorArithmetic {
    var values: [Double]

    static var zero: AnimatableVector { AnimatableVector(values: []) }

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector { combine(lhs, rhs, +) }
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector { combine(lhs, rhs, -) }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }

    private static func combine(
        _ lhs: AnimatableVector, _ rhs: AnimatableVector, _ operation: (Double, Double) -> Double
    ) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        let result = (0..<count).map { index in
            operation(lhs.values.element(at: index), rhs.values.element(at: index))
        }
        return AnimatableVector(values: result)
    }
}

extension [Double] {
    fileprivate func element(at index: Int) -> Double { index < count ? self[index] : 0 }
}
