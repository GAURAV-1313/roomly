// Why: iOS 26 lists use title-case section headers with an optional trailing action; one view keeps them
// identical across screens. Month sections on the photo screens (Figma "MonthHeader v5") add a detail line and
// put the bulk action in a small quiet capsule, which moves under the title at accessibility text sizes.
import SwiftUI

struct SectionHeader: View {
    enum Style {
        /// Headline title with an accent action, for lists inside a screen.
        case standard
        /// Large title with a quiet secondary action, for the top-level sections of the dashboard.
        case prominent
        /// Headline title, optional detail line and a small quiet capsule, for month sections of a photo grid.
        case month
    }

    let title: String
    /// A secondary line under the title, such as a count and size; shown by the month style only.
    var detail: String? = nil
    var action: String? = nil
    var style = Style.standard
    var onAction: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if style == .month {
            monthBody
        } else {
            listBody
        }
    }

    private var listBody: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(style == .prominent ? RoomyFont.title1 : RoomyFont.headline)
                .foregroundStyle(RoomyColor.textPrimary)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(style == .prominent ? RoomyFont.subheadline : RoomyFont.subheadlineSemibold)
                    .foregroundStyle(style == .prominent ? RoomyColor.textSecondary : RoomyColor.accent)
            }
        }
        .padding(.vertical, Space.s8)
    }

    private var monthBody: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(RoomyFont.headline)
                    .foregroundStyle(RoomyColor.textPrimary)
                if let detail {
                    Text(detail)
                        .font(RoomyFont.footnote)
                        .foregroundStyle(RoomyColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            if let action, let onAction {
                Button(action, action: onAction)
                    .buttonStyle(.roomySecondary)
                    .controlSize(.small)
            }
        }
        .padding(.leading, Space.s4)
        .padding(.top, Space.s12)
        .padding(.bottom, Space.s4)
    }
}
