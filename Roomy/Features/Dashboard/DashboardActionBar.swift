// Why: the dashboard's one bottom action, drawn from DashboardBottomAction (Figma "Dashboard v5 — option A").
// It is always there, so it never rises in; it changes in place. When Review and a scan action both apply, the
// capsule splits: on iOS 26 the round scan button pinches off the capsule's leading end inside one glass
// container, below it the button scales in beside a capsule that narrows. The label crossfades when the action
// changes and its count rolls when only the number does. With Reduce Motion everything only crossfades.
import SwiftUI

struct DashboardActionBar: View {
    let model: DashboardBottomAction
    let onScan: (DashboardBottomAction.Scan) -> Void
    let onReview: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glass

    /// The morph needs a namespace; without one (Reduce Motion) the shapes simply crossfade.
    private var morphSpace: Namespace.ID? { reduceMotion ? nil : glass }

    var body: some View {
        RoomyGlassContainer(spacing: Space.s8) {
            HStack(spacing: Space.s8) {
                if let scan = model.roundScan {
                    roundButton(scan)
                        .roomyGlassID("scan", in: morphSpace)
                        .transition(roundTransition)
                }
                if let capsule = model.capsule {
                    capsuleButton(capsule).roomyGlassID("capsule", in: morphSpace)
                }
            }
        }
        .padding(.horizontal, Space.margin)
        .padding(.bottom, Space.s12)
        .animation(reduceMotion ? Motion.quick : Motion.standard, value: model.arrangement)
    }

    private func roundButton(_ scan: DashboardBottomAction.Scan) -> some View {
        RoundActionButton(
            title: scan.title, systemImage: scan.systemImage, progress: model.progress,
            accessibilityValue: model.progressValue, showsTrack: scan == .cancel
        ) {
            onScan(scan)
        }
    }

    private func capsuleButton(_ capsule: DashboardBottomAction.Capsule) -> some View {
        ActionCapsule(
            title: capsule.title, systemImage: capsule.systemImage, isProminent: capsule.isProminent,
            progress: isScanCapsule(capsule) ? model.progress : nil,
            accessibilityValue: isScanCapsule(capsule) ? model.progressValue : nil
        ) {
            if case .scan(let scan) = capsule {
                onScan(scan)
            } else {
                onReview()
            }
        }
        // A new action crossfades its label inside the same glass; a new count within one action rolls instead.
        .id(capsule.kind)
        .transition(.opacity)
    }

    private func isScanCapsule(_ capsule: DashboardBottomAction.Capsule) -> Bool {
        if case .scan = capsule { return true }
        return false
    }

    /// iOS 26 glass morphs on its own, so only the icon fades; below it the button grows out of the gap.
    private var roundTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        if #available(iOS 26.0, *) {
            return .opacity
        }
        return .scale.combined(with: .opacity)
    }
}
