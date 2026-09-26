// Why: a long list of months meant scrolling past every older photo to select one month. Each month is now a
// plain disclosure row (Figma "MonthDisclosureHeader v5"): chevron, month and a one-line summary fold or open
// the month, and its own SelectToggle selects it. They are two targets split by a hairline, because selecting
// must never expand and expanding must never select — a DisclosureGroup's single label button would swallow the
// toggle. The chevron turns as the month opens; with Reduce Motion it swaps with a fade. At accessibility text
// sizes the row stacks: title, summary, a hairline, then the toggle on its own row.
import SwiftUI

struct MonthDisclosureHeader: View {
    let title: String
    let summary: String
    let isOpen: Bool
    let onToggleOpen: () -> Void
    /// The month's own select toggle; nil when it has nothing to select.
    var toggle: SelectToggle? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s8))
        layout {
            disclosure
            if let toggle {
                divider
                toggle
            }
        }
        .padding(.vertical, Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoomyColor.bg)
    }

    private var disclosure: some View {
        Button(action: onToggleOpen) {
            HStack(alignment: isStacked ? .firstTextBaseline : .center, spacing: Layout.monthChevronGap) {
                chevron
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(RoomyFont.headline)
                        .foregroundStyle(RoomyColor.textPrimary)
                    Text(summary)
                        .font(RoomyFont.footnote)
                        .foregroundStyle(RoomyColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Layout.tapTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
        .accessibilityHint(isOpen ? "Folds this month" : "Shows this month")
    }

    /// Turns with the month; with Reduce Motion the two chevrons swap with a fade instead.
    @ViewBuilder
    private var chevron: some View {
        Group {
            if reduceMotion {
                Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                    .contentTransition(.opacity)
                    .animation(Motion.quick, value: isOpen)
            } else {
                Image(systemName: "chevron.right")
                    .rotationEffect(isOpen ? Motion.chevronOpenAngle : .zero)
                    .animation(Motion.chevronTurn, value: isOpen)
            }
        }
        .font(RoomyFont.footnoteSemibold)
        .foregroundStyle(RoomyColor.textSecondary)
        .frame(width: Layout.monthChevron, height: Layout.monthChevron)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var divider: some View {
        if isStacked {
            RoomyColor.separator.frame(height: Layout.hairline)
        } else {
            RoomyColor.separator.frame(width: Layout.hairline, height: Layout.monthDividerHeight)
        }
    }
}
