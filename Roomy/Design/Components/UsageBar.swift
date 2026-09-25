// Why: a row of thin ticks reads as "how full" at a glance, like Settings' storage bar, without a ring that
// needs a number inside it. It shows used against free only: what can be cleaned up is far smaller than one
// tick, so drawing it would be a made-up value. Used ticks deepen toward the edge of free space. On the
// dashboard's first appearance they light up once, left to right, in under half a second.
import SwiftUI

struct UsageBar: View {
    /// Share of the phone in use, 0...1.
    let usedFraction: Double
    /// On its first appearance the used ticks light up once, left to right; with Reduce Motion they are drawn
    /// filled at once.
    var sweepsIn = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLit = false

    var body: some View {
        GeometryReader { proxy in
            let ticks = UsageTicks(
                width: proxy.size.width, usedFraction: usedFraction, tickWidth: Layout.usageTickWidth,
                pitch: Layout.usageTickPitch)
            HStack(spacing: ticks.spacing) {
                ForEach(0..<ticks.count, id: \.self) { index in
                    tick(index, of: ticks)
                }
            }
        }
        .frame(height: Layout.usageBarHeight)
        .accessibilityHidden(true)
        .onAppear { isLit = true }
    }

    /// A used tick is an accent layer over a free grey one: before it lights up only the grey shows, so an unlit
    /// bar reads as all free, never as empty.
    private func tick(_ index: Int, of ticks: UsageTicks) -> some View {
        let isUsed = ticks.isUsed(index)
        let isShowingUsed = isUsed && (isLit || !sweepsIn)
        return Capsule()
            .fill(RoomyColor.ringUsed)
            .opacity(isShowingUsed ? 0 : UsageTicks.freeOpacity)
            .overlay {
                if isUsed {
                    Capsule()
                        .fill(RoomyColor.accent)
                        .opacity(isShowingUsed ? ticks.opacity(at: index) : 0)
                }
            }
            .frame(width: Layout.usageTickWidth)
            .animation(sweep(index, used: ticks.used), value: isLit)
    }

    private func sweep(_ index: Int, used: Int) -> Animation? {
        guard sweepsIn, !reduceMotion else { return nil }
        return Motion.quick.delay(Motion.tickDelay(at: index, of: used))
    }
}

/// How many ticks fit, how many are used, and how strong each one is.
nonisolated struct UsageTicks: Equatable {
    /// The faintest used tick; the last used tick is fully opaque.
    static let faintestUsed = 0.25
    /// Free ticks are a quiet grey.
    static let freeOpacity = 0.45

    let count: Int
    let used: Int
    let spacing: CGFloat
    let tickWidth: CGFloat

    /// Ticks `tickWidth` wide, as many as fit at about `pitch` apart, spread to fill `width` exactly.
    init(width: CGFloat, usedFraction: Double, tickWidth: CGFloat, pitch: CGFloat) {
        self.tickWidth = tickWidth
        let fitting = Int((width + tickWidth) / pitch)
        count = max(fitting, 2)
        spacing = max((width - CGFloat(count) * tickWidth) / CGFloat(count - 1), 0)
        let share = min(max(usedFraction, 0), 1)
        let rounded = Int((share * Double(count)).rounded())
        // Some use always shows, and so does some free space, unless the phone is completely full or empty.
        let lowest = share > 0 ? 1 : 0
        let highest = share < 1 ? count - 1 : count
        used = min(max(rounded, lowest), highest)
    }

    func isUsed(_ index: Int) -> Bool { index < used }

    /// The x position between the last used tick and the first free one: where a pin marks the boundary.
    var boundaryX: CGFloat {
        guard used > 0 else { return 0 }
        guard used < count else { return CGFloat(count) * tickWidth + CGFloat(count - 1) * spacing }
        return CGFloat(used) * (tickWidth + spacing) - spacing / 2
    }

    func opacity(at index: Int) -> Double {
        guard isUsed(index) else { return Self.freeOpacity }
        guard used > 1 else { return 1 }
        return Self.faintestUsed + (1 - Self.faintestUsed) * Double(index) / Double(used - 1)
    }
}

extension UsageTicks {
    /// The used/free boundary for a bar of `width` drawn with the standard tick metrics.
    static func boundary(width: CGFloat, usedFraction: Double) -> CGFloat {
        UsageTicks(
            width: width, usedFraction: usedFraction, tickWidth: Layout.usageTickWidth, pitch: Layout.usageTickPitch
        ).boundaryX
    }
}

#Preview {
    VStack(spacing: Space.s16) {
        UsageBar(usedFraction: 0.92)
        UsageBar(usedFraction: 0.4)
    }
    .padding()
}
