// Why: one card answers "how full is this phone and what can go". The headline says the state first, with
// Roomy perched on the white card below it; the card shows how full in words and as a usage bar, then what
// can be cleaned up and, while a scan runs, how many photos it has read in words. The card holds no action and
// no progress bar: the dashboard's bottom capsule is its one action and its one moving bar. Before the first
// index arrives the amount is a skeleton, so nothing made up is ever drawn. At accessibility text sizes rows
// stack instead of squeezing. Matches the Figma "StorageHeroCard v5" component in "Dashboard v5 — option A".
import SwiftUI

struct StorageCard: View {
    let summary: DashboardSummary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }
    private var shell: RoundedRectangle { RoundedRectangle(cornerRadius: Radius.heroCard, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: -Layout.heroPerch) {
            header.zIndex(1)
            VStack(alignment: .leading, spacing: 0) {
                usage
                if summary.showsAmount {
                    Rectangle().fill(RoomyColor.separator).frame(height: 1)
                    footer
                }
            }
            .background(RoomyColor.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .padding(.top, Layout.heroTopInset)
        .padding([.horizontal, .bottom], Layout.heroInset)
        .heroShell()
        .overlay(shell.strokeBorder(RoomyColor.glassStroke, lineWidth: 1))
    }

    private var header: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            if isStacked {
                mascot
            }
            Text(summary.cardTitle)
                .font(RoomyFont.title2)
                .foregroundStyle(RoomyColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if !isStacked {
                mascot
            }
        }
        .padding(.leading, Space.s16)
        .padding(.trailing, Space.s8)
        .padding(.bottom, isStacked ? Layout.heroPerch + Space.s12 : 0)
    }

    private var mascot: some View {
        MascotView(mood: summary.mood, size: MascotSize.card)
    }

    private var usage: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    usageTitle
                    Spacer(minLength: Space.s8)
                    usageDetail
                }
                VStack(alignment: .leading, spacing: Space.s4) {
                    usageTitle
                    usageDetail
                }
            }
            .accessibilityElement(children: .combine)
            UsageBar(usedFraction: summary.usedFraction, sweepsIn: true)
        }
        .padding(Space.s16)
    }

    private var usageTitle: some View {
        Text(summary.usageTitle).font(RoomyFont.headline).foregroundStyle(RoomyColor.textPrimary)
    }

    private var usageDetail: some View {
        Text(summary.usageDetail).font(RoomyFont.subheadline).foregroundStyle(RoomyColor.textSecondary)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            amount
            if summary.isScanning {
                Text(summary.progressText)
                    .font(RoomyFont.footnote)
                    .foregroundStyle(RoomyColor.textSecondary)
                    .contentTransition(.numericText())
                    .animation(Motion.snappy, value: summary.progressText)
            }
        }
        .padding(.leading, Space.s16)
        .padding(.trailing, Space.s12)
        .padding(.top, Space.s12)
        .padding(.bottom, Layout.heroFooterBottom)
    }

    /// The amount on the left and what it means on the right, so the footer spans the card now that the scan
    /// action lives in the bottom capsule. When the two don't fit on one line (large text) they stack.
    private var amount: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s12) {
                amountValue
                Spacer(minLength: 0)
                amountCaption.multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: 0) {
                amountValue
                amountCaption
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var amountValue: some View {
        ZStack(alignment: .leading) {
            if summary.isAmountPending {
                SkeletonShape(
                    width: Layout.heroValueSkeleton.width, height: Layout.heroValueSkeleton.height,
                    cornerRadius: Radius.grid
                )
                .transition(.opacity)
            } else {
                Text(summary.heroValue)
                    .font(RoomyFont.amount)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .contentTransition(.numericText())
                    .transition(.opacity)
            }
        }
        .animation(Motion.quick, value: summary.isAmountPending)
        .animation(Motion.snappy, value: summary.heroValue)
    }

    private var amountCaption: some View {
        Text(summary.heroCaption)
            .font(RoomyFont.subheadline)
            .foregroundStyle(RoomyColor.textSecondary)
    }
}
