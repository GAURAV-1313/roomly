// Why: draws the robin one body part at a time, in the same order and proportions as the Flutter painter
// it was ported from. Every coordinate is a fraction of `unit` (the shorter side), so the bird scales to any size.
import SwiftUI

struct MascotPainter {
    let pose: MascotPose
    let blink: Double
    let unit: CGFloat

    private var eyeY: CGFloat { -unit * 0.13 }
    private var eyeSpacing: CGFloat { unit * 0.13 }

    func draw(in context: inout GraphicsContext, size: CGSize) {
        var canvas = context
        canvas.translateBy(x: size.width / 2, y: size.height / 2 + unit * 0.04)
        canvas.rotate(by: .radians(pose.tilt))
        canvas.scaleBy(x: pose.scaleX, y: pose.scaleY)
        drawCrest(in: canvas)
        drawWings(in: canvas)
        drawBody(in: canvas)
        drawBeak(in: canvas)
        drawEyes(in: canvas)
        drawBrows(in: canvas)
    }

    /// Drawn first, so the body covers its base. The dot follows the app accent.
    private func drawCrest(in canvas: GraphicsContext) {
        let tipY = -unit * 0.42 - pose.crestLift * unit
        var crest = Path()
        crest.move(to: point(-0.06, -0.34))
        crest.addQuadCurve(to: point(0, -0.32), control: CGPoint(x: -unit * 0.03, y: tipY))
        crest.addQuadCurve(to: point(0.06, -0.34), control: CGPoint(x: unit * 0.03, y: tipY))
        crest.closeSubpath()
        canvas.fill(crest, with: .color(MascotColor.dark))
        let dotRadius = unit * 0.028
        let dot = CGRect(x: -dotRadius, y: tipY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
        canvas.fill(Path(ellipseIn: dot), with: .color(RoomyColor.accent))
    }

    private func drawWings(in canvas: GraphicsContext) {
        let color = pose.wingAccent > 0.5 ? RoomyColor.accent : MascotColor.dark
        for side: CGFloat in [-1, 1] {
            var wingCanvas = canvas
            wingCanvas.translateBy(x: unit * 0.32 * side, y: unit * 0.02)
            wingCanvas.rotate(by: .radians(pose.wingAngle * Double(side)))
            var wing = Path()
            wing.move(to: point(0, -0.06))
            wing.addQuadCurve(to: point(0.1 * side, 0.22), control: point(0.16 * side, 0.02))
            wing.addQuadCurve(to: point(0, 0.18), control: point(0.02 * side, 0.14))
            wing.closeSubpath()
            wingCanvas.fill(wing, with: .color(color))
        }
    }

    private func drawBody(in canvas: GraphicsContext) {
        let body = CGRect(x: -unit * 0.38, y: -unit * 0.32, width: unit * 0.76, height: unit * 0.72)
        canvas.fill(Path(roundedRect: body, cornerRadius: unit * 0.34), with: .color(MascotColor.body))
        let breast = CGRect(x: -unit * 0.23, y: -unit * 0.06, width: unit * 0.46, height: unit * 0.4)
        canvas.fill(Path(roundedRect: breast, cornerRadius: unit * 0.22), with: .color(MascotColor.breast))
    }

    /// A closed triangle, or an open "V" when the pose has a beak gap.
    private func drawBeak(in canvas: GraphicsContext) {
        var beak = Path()
        beak.move(to: point(-0.07, -0.03))
        if pose.beakGap > 0.002 {
            beak.addLine(to: point(0, -0.03 + pose.beakGap))
            beak.addLine(to: point(0.07, -0.03))
            beak.addLine(to: point(0, -0.01))
        } else {
            beak.addLine(to: point(0.07, -0.03))
            beak.addLine(to: point(0, 0.015))
        }
        beak.closeSubpath()
        canvas.fill(beak, with: .color(MascotColor.beak))
    }

    private func drawEyes(in canvas: GraphicsContext) {
        let openness = pose.eyeOpenness * (1 - blink)
        for centerX in [-eyeSpacing, eyeSpacing] {
            if openness > 0.12 {
                drawOpenEye(at: centerX, openness: openness, in: canvas)
            } else {
                drawClosedEye(at: centerX, in: canvas)
            }
        }
    }

    private func drawOpenEye(at centerX: CGFloat, openness: Double, in canvas: GraphicsContext) {
        let squash = max(openness, 0.12)
        let eyeRadius = unit * pose.eyeRadius
        let eye = CGRect(
            x: centerX - eyeRadius, y: eyeY - eyeRadius * squash, width: eyeRadius * 2, height: eyeRadius * 2 * squash)
        canvas.fill(Path(ellipseIn: eye), with: .color(MascotColor.face))
        let pupilRadius = unit * pose.pupilRadius
        let pupilX = centerX + unit * pose.pupilOffsetX - pupilRadius
        let pupilY = eyeY + unit * pose.pupilOffsetY - pupilRadius * squash
        let pupil = CGRect(x: pupilX, y: pupilY, width: pupilRadius * 2, height: pupilRadius * 2 * squash)
        canvas.fill(Path(ellipseIn: pupil), with: .color(MascotColor.eye))
    }

    /// A lid curve. Mid-blink on an open-eyed pose uses a neutral lid.
    private func drawClosedEye(at centerX: CGFloat, in canvas: GraphicsContext) {
        let isPoseClosed = pose.eyeOpenness < 0.5
        let halfWidth = unit * (isPoseClosed ? pose.lidHalfWidth : 0.05)
        let lidY = eyeY + unit * (isPoseClosed ? pose.lidOffsetY : 0)
        let curve = unit * (isPoseClosed ? pose.lidCurve : 0.01)
        var lid = Path()
        lid.move(to: CGPoint(x: centerX - halfWidth, y: lidY))
        lid.addQuadCurve(
            to: CGPoint(x: centerX + halfWidth, y: lidY), control: CGPoint(x: centerX, y: lidY + curve * 2))
        canvas.stroke(lid, with: .color(MascotColor.eye), style: stroke)
    }

    private func drawBrows(in canvas: GraphicsContext) {
        drawBrow(pose.leftBrow, centerX: -eyeSpacing, in: canvas)
        drawBrow(pose.rightBrow, centerX: eyeSpacing, in: canvas)
    }

    private func drawBrow(_ brow: Brow, centerX: CGFloat, in canvas: GraphicsContext) {
        guard brow.opacity > 0.02 else { return }
        var line = Path()
        line.move(to: CGPoint(x: centerX - unit * 0.045, y: eyeY + unit * brow.startY))
        line.addLine(to: CGPoint(x: centerX + unit * 0.045, y: eyeY + unit * brow.endY))
        canvas.stroke(line, with: .color(MascotColor.eye.opacity(brow.opacity)), style: stroke)
    }

    private var stroke: StrokeStyle { StrokeStyle(lineWidth: unit * 0.028, lineCap: .round) }

    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: unit * x, y: unit * y) }
}
