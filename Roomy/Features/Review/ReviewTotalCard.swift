// Why: the total is the first thing Review says — how much, how many, and that nothing is deleted yet. At the
// large detent it is the dashboard's hero card with Roomy perched on it; at the medium detent it shrinks to one
// row so the first section and its first row still show above the delete dock. Roomy turns serious while the
// confirmation is open. At accessibility sizes the robin drops under the number instead of squeezing it.
import SwiftUI

struct ReviewTotalCard: View {
    enum Size {
        /// The large detent: hero card with a nested white card.
        case regular
        /// The medium detent: one row with the value and a small Roomy.
        case compact
    }

    let summary: ReviewSummary
    let size: Size
    let isConfirming: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var mood: MascotMood { isConfirming ? .serious : .idle }

    var body: some View {
        Group {
            switch size {
            case .regular: regular
            case .compact: compact
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var regular: some View {
        VStack(spacing: -Layout.heroPerch) {
            header(font: RoomyFont.title1, mascotSize: MascotSize.card)
                .padding(.leading, Space.s16)
                .padding(.trailing, Space.s8)
                .zIndex(1)
            VStack(alignment: .leading, spacing: Space.s4) {
                Text(summary.totalDetail).font(RoomyFont.subheadline)
                if let cloudNote = summary.cloudNote {
                    Text(cloudNote).font(RoomyFont.footnote)
                }
            }
            .foregroundStyle(RoomyColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Space.s16)
            .padding(.vertical, Space.s12)
            .heroInnerCard()
        }
        .padding(.top, Layout.heroTopInset)
        .padding([.horizontal, .bottom], Layout.heroInset)
        .heroShell()
    }

    private var compact: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            header(font: RoomyFont.title2, mascotSize: MascotSize.compactTotal)
            Text(summary.totalDetail).font(RoomyFont.footnote)
            if let cloudNote = summary.cloudNote {
                Text(cloudNote).font(RoomyFont.caption)
            }
        }
        .foregroundStyle(RoomyColor.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.leading, Space.s16)
        .padding(.trailing, Space.s12)
        .padding(.vertical, Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .heroShell(cornerRadius: Radius.card)
    }

    /// The value and Roomy side by side; stacked at accessibility sizes so the number keeps the full width.
    private func header(font: Font, mascotSize: CGFloat) -> some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            Text(summary.totalValue)
                .contentTransition(.numericText())
                .animation(Motion.snappy, value: summary.totalValue)
                .font(font)
                .foregroundStyle(RoomyColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            MascotView(mood: mood, size: mascotSize)
        }
    }
}
