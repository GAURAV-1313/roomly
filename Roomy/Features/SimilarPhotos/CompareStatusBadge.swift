// Why: over a full-screen photo each state needs its own opaque label, so it reads on any image and never
// looks like a button (Figma "CompareBadge v5"): the keeper is a light capsule with a green seal, a queued
// photo an accent capsule, one not queued a dim capsule. A queued keeper shows both, so nothing is hidden.
import SwiftUI

struct CompareStatusBadge: View {
    let page: ComparePage

    var body: some View {
        HStack(spacing: Space.s8) {
            if page.isKeeper {
                keeperLabel
            }
            if page != .keeper {
                queueLabel
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.status)
    }

    private var keeperLabel: some View {
        capsule(
            ComparePage.keeper.status, systemImage: "checkmark.seal.fill", text: RoomyColor.textPrimary,
            glyph: RoomyColor.success, fill: RoomyColor.card)
    }

    private var queueLabel: some View {
        let page = page.isQueued ? ComparePage.queued : .notQueued
        return capsule(
            page.status, systemImage: page.isQueued ? "checkmark.circle.fill" : "circle", text: RoomyColor.onAccent,
            glyph: RoomyColor.onAccent, fill: page.isQueued ? RoomyColor.accent : RoomyColor.dim)
    }

    private func capsule(_ title: String, systemImage: String, text: Color, glyph: Color, fill: Color) -> some View {
        HStack(spacing: Space.s4) {
            Image(systemName: systemImage)
                .font(.system(size: Layout.compareGlyph, weight: .semibold))
                .foregroundStyle(glyph)
            Text(title)
                .font(RoomyFont.footnoteSemibold)
                .foregroundStyle(text)
        }
        .padding(.leading, Space.s8)
        .padding(.trailing, Space.s12)
        .padding(.vertical, Space.s4)
        .background(fill, in: Capsule())
    }
}
