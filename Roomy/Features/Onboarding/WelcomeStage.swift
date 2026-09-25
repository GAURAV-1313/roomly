// Why: the Welcome stage is Roomy over a soft ground shadow, above the storage capsule. Roomy falls in once and
// lands with a small squash while his shadow darkens under him; the capsule shakes three times, with one warning
// haptic, when its fill turns red. Each of those is keyed to a counter in `WelcomeScene`, not to a flag, so jumping to the
// rest pose never replays them — and with Reduce Motion the counters never move at all.
import SwiftUI

struct WelcomeStage: View {
    let scene: WelcomeScene

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: Space.s4) {
            roomy
            WelcomeStorageCapsule(stage: scene.capsule)
                .keyframeAnimator(initialValue: CGFloat(0), trigger: scene.signals) { content, offset in
                    content.offset(x: offset)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(Motion.shakeDistance, duration: Motion.shakeStep)
                        LinearKeyframe(-Motion.shakeDistance, duration: Motion.shakeStep)
                        LinearKeyframe(Motion.shakeDistance, duration: Motion.shakeStep)
                        LinearKeyframe(-Motion.shakeDistance, duration: Motion.shakeStep)
                        LinearKeyframe(Motion.shakeDistance, duration: Motion.shakeStep)
                        LinearKeyframe(-Motion.shakeDistance, duration: Motion.shakeStep)
                        LinearKeyframe(0, duration: Motion.shakeStep)
                    }
                }
                .sensoryFeedback(.warning, trigger: scene.signals)
        }
        .accessibilityHidden(true)
    }

    private var mascotSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? Layout.welcomeMascotLarge : Layout.welcomeMascot
    }

    private var roomy: some View {
        MascotView(mood: mood, size: mascotSize)
            .keyframeAnimator(initialValue: DropPose(), trigger: scene.drops) { content, pose in
                content
                    .scaleEffect(x: 1, y: pose.squash, anchor: .bottom)
                    .offset(y: pose.offset)
                    .opacity(pose.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.offset) {
                    MoveKeyframe(-Motion.welcomeDrop)
                    SpringKeyframe(0, duration: Motion.dropDuration, spring: Motion.dropSpring)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(0)
                    LinearKeyframe(1, duration: Motion.dropFade)
                }
                KeyframeTrack(\.squash) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: Motion.dropDuration)
                    CubicKeyframe(Motion.squashScale, duration: Motion.squashIn)
                    CubicKeyframe(1, duration: Motion.squashOut)
                }
            }
            .background(alignment: .bottom) { shadow }
            .opacity(scene.isRoomyShown ? 1 : 0)
    }

    /// The shadow stays on the ground and darkens as Roomy nears it.
    private var shadow: some View {
        Ellipse()
            .fill(RoomyColor.groundShadow)
            .frame(width: Layout.welcomeShadow.width, height: Layout.welcomeShadow.height)
            .blur(radius: Layout.welcomeShadowBlur)
            .keyframeAnimator(initialValue: 1.0, trigger: scene.drops) { content, darkness in
                content.opacity(darkness)
            } keyframes: { _ in
                MoveKeyframe(0)
                CubicKeyframe(1, duration: Motion.dropDuration)
            }
            .offset(y: -Layout.welcomeShadowLift)
    }

    private var mood: MascotMood {
        switch scene.mood {
        case .concerned: .concerned
        case .curious: .curious
        case .pleased: .pleased
        }
    }
}

/// Where Roomy is in his fall: how high, how visible, how squashed. The initial value is the landed pose.
private nonisolated struct DropPose: Sendable {
    var offset: CGFloat = 0
    var opacity: Double = 1
    var squash: CGFloat = 1
}
