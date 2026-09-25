// Why: the result shows the space a cleanup moved as a marker on the same tick bar as the dashboard, not as an arc.
// The last used tick rises into a taller marker at the real used/free boundary, and a plain caption under the bar
// states the amount: its position is real, its size is not a proportion, so 2 GB of 245 GB is as plain to see as
// 40 GB. Pending space is an amber outline (removed, not freed); only a measured rise fills it green and adds a
// check, so the two states differ in shape and words, not colour alone. The marker drops in once, just after the
// card shows, and fills with a slow crossfade — never on a timer. Matches the Figma "Premium details" marker tick.
import SwiftUI

/// What the marker on the bar says, if anything.
nonisolated enum StorageMarker: Equatable {
    /// Moved to Recently Deleted, still on the phone.
    case pending(Int64)
    /// Measured as free again.
    case freed(Int64)

    /// The amount, set in bold in the caption.
    var amount: String {
        switch self {
        case .pending(let bytes), .freed(let bytes): bytes.byteString
        }
    }

    /// What the amount means, after it in the caption.
    var words: String { isPending ? "in Recently Deleted" : "now free" }

    var text: String { "\(amount) \(words)" }

    var isPending: Bool {
        if case .pending = self { return true }
        return false
    }
}

struct StorageBar: View {
    let usedFraction: Double
    var marker: StorageMarker? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s8) {
            UsageBar(usedFraction: usedFraction)
                .overlay(alignment: .topLeading) {
                    if let marker { markerTick(marker).modifier(drop) }
                }
                // Room above the bar for the marker's rise, so it never overlaps the row above.
                .padding(.top, marker == nil ? 0 : Layout.markerRise)
            if let marker {
                CaptionLayout(
                    usedFraction: usedFraction, tickWidth: Layout.usageTickWidth, pitch: Layout.usageTickPitch
                ) { caption(marker) }
                .modifier(drop)
            }
        }
        .animation(reduceMotion ? nil : Motion.reward, value: marker)
        .accessibilityHidden(true)
        .onAppear { isShown = true }
    }

    private var drop: MarkerDrop { MarkerDrop(isShown: isShown, reduceMotion: reduceMotion) }

    /// A taller capsule centred on the last used tick: outlined amber while pending, solid green once freed.
    private func markerTick(_ marker: StorageMarker) -> some View {
        GeometryReader { proxy in
            let ticks = UsageTicks(
                width: proxy.size.width, usedFraction: usedFraction, tickWidth: Layout.usageTickWidth,
                pitch: Layout.usageTickPitch)
            let height = proxy.size.height + Layout.markerRise
            Capsule()
                .fill(marker.isPending ? RoomyColor.card : RoomyColor.success)
                .overlay {
                    if marker.isPending {
                        Capsule().strokeBorder(RoomyColor.warning, lineWidth: Layout.markerLine)
                    }
                }
                .frame(width: Layout.markerWidth, height: height)
                .position(x: ticks.lastUsedCenterX, y: height / 2 - Layout.markerRise)
        }
    }

    private func caption(_ marker: StorageMarker) -> some View {
        HStack(spacing: Space.s4) {
            if !marker.isPending {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(RoomyColor.success)
            }
            Text(marker.amount).fontWeight(.semibold).foregroundStyle(RoomyColor.textPrimary)
                + Text(" \(marker.words)").foregroundStyle(RoomyColor.textSecondary)
        }
        .font(RoomyFont.footnote)
    }
}

/// The marker and its caption fall `Motion.pinDrop` into place and fade in, a moment after the card; with Reduce
/// Motion they only fade.
private struct MarkerDrop: ViewModifier {
    let isShown: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : -Motion.pinDrop)
            .animation(reduceMotion ? Motion.quick : Motion.settle.delay(Motion.pinDelay), value: isShown)
    }
}

/// Places the caption so its trailing edge lines up with the marker, kept inside the bar's edges.
private struct CaptionLayout: SwiftUI.Layout {
    let usedFraction: Double
    /// The bar's tick metrics, passed in because layout runs outside the main actor where the tokens live.
    let tickWidth: CGFloat
    let pitch: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.first?.sizeThatFits(.unspecified).width ?? 0
        let size = subviews.first?.sizeThatFits(ProposedViewSize(width: width, height: nil)) ?? .zero
        return CGSize(width: width, height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let caption = subviews.first else { return }
        let size = caption.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
        let width = min(size.width, bounds.width)
        let ticks = UsageTicks(width: bounds.width, usedFraction: usedFraction, tickWidth: tickWidth, pitch: pitch)
        let markerEdge = ticks.lastUsedCenterX + tickWidth
        let x = min(max(markerEdge - width, 0), bounds.width - width)
        caption.place(
            at: CGPoint(x: bounds.minX + x, y: bounds.minY),
            proposal: ProposedViewSize(width: width, height: size.height))
    }
}
