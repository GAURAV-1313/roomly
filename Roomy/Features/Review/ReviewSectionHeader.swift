// Why: a Review section looks like the dashboard tile it came from — the same colour and glyph — so the person
// recognises what they picked. "Remove all" is a quiet capsule: it only takes items out of Review, so it is never
// red. At accessibility sizes the capsule moves under the title instead of squeezing it.
import SwiftUI

struct ReviewSectionHeader: View {
    let kind: BasketItem.Kind
    let count: Int
    let onRemoveAll: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        layout {
            HStack(spacing: Space.s8) {
                icon
                Text("\(kind.reviewTitle) · \(count.formatted())")
                    .font(RoomyFont.headline)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
            }
            Button("Remove all", action: onRemoveAll)
                .buttonStyle(.roomySecondary)
                .controlSize(.small)
                .accessibilityLabel("Remove all \(kind.reviewTitle.lowercased()) from Review")
        }
        .padding(.leading, Space.s4)
        .padding(.top, Space.s12)
        .padding(.bottom, Space.s4)
    }

    private var icon: some View {
        Image(systemName: kind.glyph)
            .font(RoomyFont.footnoteSemibold)
            // The square has a fixed size, so its glyph stops growing where it would spill out.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .foregroundStyle(kind.category.categoryTint)
            .frame(width: Layout.sectionIcon, height: Layout.sectionIcon)
            .background(
                kind.category.categoryTintSoft,
                in: RoundedRectangle(cornerRadius: Radius.iconSquare, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

extension BasketItem.Kind {
    /// The dashboard category each kind of item was picked from, for its colours.
    var category: Route {
        switch self {
        case .photo: .similarPhotos
        case .screenshot: .screenshots
        case .video: .largeVideos
        case .contactGroup: .duplicateContacts
        }
    }

    var glyph: String {
        switch self {
        case .photo: "photo.stack"
        case .screenshot: "camera.viewfinder"
        case .video: "film.stack"
        case .contactGroup: "person.2.fill"
        }
    }
}
