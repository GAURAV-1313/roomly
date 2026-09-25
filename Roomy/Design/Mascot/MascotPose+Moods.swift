// Why: the pose for each mood, written as named changes from the neutral pose so each line reads as a
// design decision ("raise the right brow") rather than a row of numbers.
import SwiftUI

extension MascotPose {
    static func pose(for mood: MascotMood) -> MascotPose {
        var pose = MascotPose()
        switch mood {
        case .idle:
            break
        case .thinking:
            pose.pupilOffsetX = 0.012
            pose.crestLift = 0.012
        case .curious:
            pose.eyeRadius = 0.065
            pose.pupilRadius = 0.03
            pose.pupilOffsetX = 0.018
            pose.pupilOffsetY = 0.01
            pose.rightBrow = Brow(opacity: 1, startY: -0.09, endY: -0.12)
            pose.tilt = -0.14
        case .concerned:
            pose.eyeRadius = 0.055
            pose.pupilRadius = 0.03
            pose.pupilOffsetY = 0.006
            pose.leftBrow = Brow(opacity: 1, startY: -0.07, endY: -0.095)
            pose.rightBrow = Brow(opacity: 1, startY: -0.095, endY: -0.07)
            pose.tilt = 0.035
            pose.scaleY = 0.985
        case .pleased:
            pose.closeEyes(halfWidth: 0.05, offsetY: 0.02, curve: -0.10)
            pose.tilt = -0.05
        case .resting:
            pose.closeEyes(halfWidth: 0.045, offsetY: 0, curve: 0.025)
            pose.scaleY = 0.98
        case .serious:
            pose.pupilRadius = 0.036
            pose.leftBrow = Brow(opacity: 1, startY: -0.085, endY: -0.085)
            pose.rightBrow = Brow(opacity: 1, startY: -0.085, endY: -0.085)
        case .success:
            pose.closeEyes(halfWidth: 0.05, offsetY: 0.02, curve: -0.10)
            pose.beakGap = 0.05
            pose.wingAngle = -0.35
            pose.wingAccent = 1
        case .error:
            pose.eyeRadius = 0.05
            pose.pupilRadius = 0.026
            pose.pupilOffsetY = 0.012
            pose.leftBrow = Brow(opacity: 1, startY: -0.075, endY: -0.045)
            pose.rightBrow = Brow(opacity: 1, startY: -0.045, endY: -0.075)
            pose.beakGap = 0.03
            pose.wingAngle = 0.3
            pose.tilt = 0.05
            pose.scaleX = 1.02
            pose.scaleY = 0.96
        }
        return pose
    }

    private mutating func closeEyes(halfWidth: Double, offsetY: Double, curve: Double) {
        eyeOpenness = 0
        lidHalfWidth = halfWidth
        lidOffsetY = offsetY
        lidCurve = curve
    }
}
