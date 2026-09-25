// Why: the result shows the space a cleanup moved as a labelled pin on the same tick bar as the dashboard, not as
// an arc. Its position is real — where used space ends — but its size is not a proportion, so 2 GB of 245 GB is as
// plain to see as 40 GB, and nothing is drawn to a made-up scale. Pending space is amber and dashed (removed, not
// freed); only a measured rise turns it solid green. The pin drops onto the bar once, just after the card shows,
// and turns green with a slow crossfade — never on a timer, only when the marker changes. Matches the Figma
// "StorageHero v6" bar.
import SwiftUI

/// What the pin on the bar says, if anything.
nonisolated enum StorageMarker: Equatable {
    /// Moved to Recently Deleted, still on the phone.
    case pending(Int64)
    /// Measured as free again.
    case freed(Int64)

    var text: String {
        switch self {
        case .pending(let bytes): "\(bytes.byteString) in Recently Deleted"
        case .freed(let bytes): "\(bytes.byteString) now free"
        }
    }

    var isPending: Bool {
        if case .pending = self { return true }
        return false
    }
}

struct StorageBar: View {
    let usedFraction: Double
    var marker: StorageMarker? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPinned = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.pinStem) {
            if let marker, !dynamicTypeSize.isAccessibilitySize {
                PinnedTagLayout(
                    usedFraction: usedFraction, tickWidth: Layout.usageTickWidth, pitch: Layout.usageTickPitch
                ) { tag(marker) }
                .modifier(pinDrop)
            }
            UsageBar(usedFraction: usedFraction)
                .overlay(alignment: .topLeading) {
                    if let marker { pin(marker).modifier(pinDrop) }
                }
            if let marker, dynamicTypeSize.isAccessibilitySize {
                tag(marker).modifier(pinDrop)
            }
        }
        .animation(reduceMotion ? nil : Motion.reward, value: marker)
        .accessibilityHidden(true)
        .onAppear { isPinned = true }
    }

    private var pinDrop: PinDrop { PinDrop(isPinned: isPinned, reduceMotion: reduceMotion) }

    private func color(_ marker: StorageMarker) -> Color {
        marker.isPending ? RoomyColor.warning : RoomyColor.success
    }

    private func tag(_ marker: StorageMarker) -> some View {
        HStack(spacing: Space.s4) {
            dot(marker).frame(width: Layout.pinDot, height: Layout.pinDot)
            Text(marker.text)
                .font(RoomyFont.footnoteSemibold)
                .foregroundStyle(RoomyColor.textPrimary)
        }
        .padding(.leading, Space.s8)
        .padding(.trailing, Space.s12)
        .padding(.vertical, Space.s4)
        .background(
            marker.isPending ? RoomyColor.warningSoft : RoomyColor.successSoft,
            in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
    }

    @ViewBuilder
    private func dot(_ marker: StorageMarker) -> some View {
        if marker.isPending {
            Circle().strokeBorder(color(marker), lineWidth: Layout.pinLine)
        } else {
            Circle().fill(color(marker))
        }
    }

    /// A stem from the tag down to a head on the bar's top edge, at the boundary between used and free.
    private func pin(_ marker: StorageMarker) -> some View {
        GeometryReader { proxy in
            let x = UsageTicks.boundary(width: proxy.size.width, usedFraction: usedFraction)
            Path { path in
                path.move(to: CGPoint(x: x, y: -Layout.pinStem))
                path.addLine(to: CGPoint(x: x, y: 0))
            }
            .stroke(
                color(marker),
                style: StrokeStyle(
                    lineWidth: Layout.pinLine, dash: marker.isPending ? [Layout.pinDash, Layout.pinDash] : []))
            dot(marker)
                .frame(width: Layout.pinHead, height: Layout.pinHead)
                .background(RoomyColor.card, in: Circle())
                .position(x: x, y: 0)
        }
    }
}

/// The pin and its tag fall `Motion.pinDrop` onto the bar and fade in, a moment after the card; with Reduce
/// Motion they only fade.
private struct PinDrop: ViewModifier {
    let isPinned: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isPinned ? 1 : 0)
            .offset(y: isPinned || reduceMotion ? 0 : -Motion.pinDrop)
            .animation(reduceMotion ? Motion.quick : Motion.settle.delay(Motion.pinDelay), value: isPinned)
    }
}

/// Places the tag centred over the used/free boundary, kept inside the bar's edges.
private struct PinnedTagLayout: SwiftUI.Layout {
    let usedFraction: Double
    /// The bar's tick metrics, passed in because layout runs outside the main actor where the tokens live.
    let tickWidth: CGFloat
    let pitch: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        return CGSize(width: proposal.width ?? size.width, height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let tag = subviews.first else { return }
        let size = tag.sizeThatFits(.unspecified)
        let width = min(size.width, bounds.width)
        let ticks = UsageTicks(width: bounds.width, usedFraction: usedFraction, tickWidth: tickWidth, pitch: pitch)
        let boundary = ticks.boundaryX
        let x = min(max(boundary - width / 2, 0), bounds.width - width)
        tag.place(
            at: CGPoint(x: bounds.minX + x, y: bounds.minY),
            proposal: ProposedViewSize(width: width, height: size.height))
    }
}
