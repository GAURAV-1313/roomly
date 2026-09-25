// Why: empty, denied and "all clear" states share one layout — Roomy, a title, one calm sentence and at
// most two actions — so no screen ever dead-ends on a blank page without a way forward. It is a white card
// with Roomy in a well tinted like the screen's category (Figma "GateCard v5"), so a gate reads as part of
// the screen, not as an error page.
import SwiftUI

struct EmptyStateAction {
    let title: String
    let perform: () -> Void
}

struct EmptyStateView: View {
    let mood: MascotMood
    let title: String
    let message: String
    var primary: EmptyStateAction? = nil
    var secondary: EmptyStateAction? = nil
    /// The well behind Roomy: the screen's category tint, or a neutral chip colour.
    var tint: Color = RoomyColor.chip

    var body: some View {
        ScrollView {
            card
                .padding(.horizontal, Space.margin)
                .padding(.vertical, Space.s24)
                .containerRelativeFrame(.vertical, alignment: .center) { length, _ in length }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(RoomyColor.bg)
    }

    private var card: some View {
        VStack(spacing: Space.s16) {
            MascotView(mood: mood, size: MascotSize.emptyState)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Layout.gateWellHeight)
                .background(tint, in: RoundedRectangle(cornerRadius: Radius.well, style: .continuous))
            VStack(spacing: Space.s4) {
                Text(title)
                    .font(RoomyFont.title2)
                    .foregroundStyle(RoomyColor.textPrimary)
                Text(message)
                    .font(RoomyFont.body)
                    .foregroundStyle(RoomyColor.textSecondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Space.s16)
            actions
        }
        .padding([.top, .horizontal], Layout.tileInset)
        .padding(.bottom, Space.s20)
        .dashboardCard()
    }

    @ViewBuilder
    private var actions: some View {
        if primary != nil || secondary != nil {
            VStack(spacing: Space.s4) { actionButtons }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Group {
            if let primary {
                Button(primary.title, action: primary.perform).buttonStyle(.roomySecondary).controlSize(.small)
            }
            if let secondary {
                Button(secondary.title, action: secondary.perform).buttonStyle(.roomyText).controlSize(.small)
            }
        }
    }
}
