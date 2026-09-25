// Why: every category screen opens with the same card, so moving between them feels like one app. The
// screen's colour lives here quietly — the same tinted well as the dashboard tile the person tapped — with the
// total on one line and what it counts under it. The footer holds the one bulk action, filter or honest note
// the screen needs. Matches the Figma "SummaryHeader v5" component.
import SwiftUI

struct CategorySummaryCard<Footer: View>: View {
    let route: Route
    let systemImage: String
    let value: String
    let detail: String
    @ViewBuilder var footer: Footer

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            well
            footerContent
        }
        .padding([.top, .horizontal], Layout.tileInset)
        .padding(.bottom, Layout.tileInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    private var well: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            Image(systemName: systemImage)
                .font(RoomyFont.title3)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundStyle(route.categoryTint)
                .frame(width: Layout.tapTarget, height: Layout.tapTarget)
                .background(RoomyColor.card, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(RoomyFont.amount)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                    .animation(Motion.snappy, value: value)
                Text(detail)
                    .font(RoomyFont.subheadline)
                    .foregroundStyle(RoomyColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .padding(.leading, Space.s12)
        .padding(.trailing, Space.s16)
        .padding(.vertical, Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(route.categoryTintSoft, in: RoundedRectangle(cornerRadius: Radius.well, style: .continuous))
    }

    /// The footer sits under the well, inset like the well's text; an empty footer adds no space.
    @ViewBuilder
    private var footerContent: some View {
        if Footer.self != EmptyView.self {
            VStack(alignment: .leading, spacing: Space.s8) { footer }
                .padding(.horizontal, Space.s8)
                .padding(.bottom, Space.s8)
        }
    }
}

extension CategorySummaryCard where Footer == EmptyView {
    init(route: Route, systemImage: String, value: String, detail: String) {
        self.init(route: route, systemImage: systemImage, value: value, detail: detail) { EmptyView() }
    }
}
