// Why: one card answers "how full is this phone and what can go". The headline says the state first, with
// Roomy perched on the white card below it; the card shows how full in words and as a usage bar, then what
// can be cleaned up next to the one action that fits the scan (Cancel, Rescan, Resume), and the scan's
// progress while it runs. Before the first index arrives the amount is a skeleton, and the bar waits for real
// counts, so nothing made up is ever drawn. At accessibility text sizes rows stack instead of squeezing. Matches the Figma
// "StorageHeroCard v5" component.
import SwiftUI

struct StorageCard: View {
    let summary: DashboardSummary
    let onAction: (DashboardSummary.CardAction) -> Void

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
            let layout =
                isStacked
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s12))
                : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
            layout {
                amount
                if let action = summary.cardAction {
                    CardActionButton(action: action, isFullWidth: isStacked) { onAction(action) }
                }
            }
            if summary.isScanning {
                ScanProgress(
                    fraction: summary.hasProgressCounts ? summary.progressFraction : nil, text: summary.progressText)
            }
        }
        .padding(.leading, Space.s16)
        .padding(.trailing, Space.s12)
        .padding(.vertical, Space.s12)
    }

    private var amount: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            Text(summary.heroCaption)
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Resume is the one prominent action (unfinished work); Cancel and Rescan stay quiet.
private struct CardActionButton: View {
    let action: DashboardSummary.CardAction
    let isFullWidth: Bool
    let perform: () -> Void

    private var isProminent: Bool { action == .resume }

    var body: some View {
        Button(action: perform) {
            Text(action.title)
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(isProminent ? RoomyColor.onAccent : RoomyColor.accent)
                .padding(.horizontal, Space.s16)
                .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: Layout.tapTarget)
                .background(isProminent ? RoomyColor.accent : RoomyColor.accentTint, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ScanProgress: View {
    /// nil until there are real counts to fill the bar with.
    let fraction: Double?
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s8) {
            if let fraction { bar(fraction) }
            Text(text)
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
        }
        .animation(Motion.progress, value: fraction)
    }

    private func bar(_ fraction: Double) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(RoomyColor.ringTrack)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(RoomyColor.accent)
                        .frame(width: proxy.size.width * fraction)
                }
        }
        .frame(height: Layout.progressBarHeight)
        .accessibilityHidden(true)
    }
}
