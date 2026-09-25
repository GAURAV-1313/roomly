// Why: glass shapes that sit close together should behave as one material, merging and pinching apart as they
// change, which iOS 26 does only inside a GlassEffectContainer and only for shapes that carry an id. This keeps
// both behind one availability check, next to `roomyGlass`. Below iOS 26 the shapes are separate materials
// and the container is a plain wrapper, so the caller's own transitions do the work.
import SwiftUI

struct RoomyGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

extension View {
    /// Names this glass shape inside a `RoomyGlassContainer`, so iOS 26 morphs it into the shape with the same
    /// id when one replaces the other. A nil namespace (Reduce Motion) leaves the shapes to crossfade.
    @ViewBuilder
    func roomyGlassID(_ id: String, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 26.0, *), let namespace {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}
