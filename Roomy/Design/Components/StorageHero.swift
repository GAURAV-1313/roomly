// Why: the cleanup result speaks the dashboard's language: the amount with Roomy beside it, then the same white
// card with how full the phone is and the tick bar. What was moved is a labelled pin on that bar, never an arc
// drawn to a made-up scale (see StorageBar). At accessibility text sizes the rows stack and the value wraps.
// When the space is measured as freed, the amount turns from grey to ink as the pin turns green, and its digits
// roll. Matches the Figma "StorageHero v6" component; it replaced the storage ring.
import SwiftUI

struct StorageHero: View {
    let value: String
    let label: String
    let mood: MascotMood
    let usageTitle: String
    let usageDetail: String
    let usedFraction: Double
    var marker: StorageMarker? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }
    private var isPending: Bool { marker?.isPending ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s8) {
            header
            usageCard
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var header: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(RoomyFont.hero)
                    .foregroundStyle(isPending ? RoomyColor.textSecondary : RoomyColor.textPrimary)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : Motion.reward, value: isPending)
                    .animation(Motion.snappy, value: value)
                Text(label)
                    .font(RoomyFont.subheadline)
                    .foregroundStyle(RoomyColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            MascotView(mood: mood, size: MascotSize.resultRow)
        }
        .padding(.leading, Space.s16)
        .padding(.trailing, Space.s8)
        .padding(.top, Space.s4)
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    usageTitleText
                    Spacer(minLength: Space.s8)
                    usageDetailText
                }
                VStack(alignment: .leading, spacing: Space.s4) {
                    usageTitleText
                    usageDetailText
                }
            }
            StorageBar(usedFraction: usedFraction, marker: marker)
        }
        .padding(Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoomyColor.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var usageTitleText: some View {
        Text(usageTitle).font(RoomyFont.headline).foregroundStyle(RoomyColor.textPrimary)
    }

    private var usageDetailText: some View {
        Text(usageDetail).font(RoomyFont.subheadline).foregroundStyle(RoomyColor.textSecondary)
    }

    private var accessibilityText: String {
        let marked = marker.map { ", \($0.text)" } ?? ""
        return "\(value) \(label)\(marked). Phone \(usageTitle)."
    }
}

#Preview {
    VStack(spacing: Space.s24) {
        StorageHero(
            value: "2.1\u{00A0}GB", label: "not freed yet", mood: .pleased, usageTitle: "92% full",
            usageDetail: "225\u{00A0}GB used · 20\u{00A0}GB free", usedFraction: 0.92,
            marker: .pending(2_100_000_000))
        StorageHero(
            value: "2.1\u{00A0}GB", label: "more free space", mood: .success, usageTitle: "91% full",
            usageDetail: "223\u{00A0}GB used · 22\u{00A0}GB free", usedFraction: 0.91, marker: .freed(2_100_000_000))
    }
    .padding()
    .heroShell()
    .padding()
}
