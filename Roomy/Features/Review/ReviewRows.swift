// Why: every row in Review can be taken out with one tap, and shows what it is — the real filename and size
// for media, the person and card count for a merge — so the list can be checked item by item. Nothing here
// is invented: a card with no name says so. At accessibility sizes the name wraps to two lines while the
// thumbnail and the remove control stay at the ends.
import SwiftUI

struct AssetReviewRow: View {
    let item: BasketItem
    let snapshot: AssetSnapshot?
    let onRemove: () -> Void

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ReviewRowLayout(
            title: snapshot?.filename ?? item.kind.itemTitle,
            detail: SizeLabel.text(item.size), onRemove: onRemove
        ) {
            // Sized before it is clipped: a filled image is larger than its frame until then.
            AssetThumbnail(id: item.id, pixelSize: thumbnailPixels)
                .frame(width: Layout.reviewThumbnail, height: Layout.reviewThumbnail)
                .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        }
    }

    private var thumbnailPixels: CGSize {
        let side = Layout.reviewThumbnail * displayScale
        return CGSize(width: side, height: side)
    }
}

struct ContactReviewRow: View {
    let name: String
    let cardCount: Int
    let onRemove: () -> Void

    var body: some View {
        ReviewRowLayout(
            title: name.isEmpty ? "No name" : name, detail: "Merge \(cardCount) cards into 1", onRemove: onRemove
        ) {
            avatar
        }
    }

    private var avatar: some View {
        Group {
            if let initials = ContactInitials.of(name) {
                Text(initials).font(RoomyFont.footnoteSemibold)
            } else {
                Image(systemName: "person.crop.circle").font(RoomyFont.title3)
            }
        }
        // The circle has a fixed size, so its letters stop growing where they would spill out.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .foregroundStyle(RoomyColor.contacts)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoomyColor.contactsSoft, in: Circle())
    }
}

private struct ReviewRowLayout<Leading: View>: View {
    let title: String
    let detail: String
    let onRemove: () -> Void
    @ViewBuilder let leading: Leading

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Space.s12) {
            leading
                .frame(width: Layout.reviewThumbnail, height: Layout.reviewThumbnail)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(RoomyFont.body)
                    .foregroundStyle(RoomyColor.textPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .truncationMode(.middle)
                Text(detail).font(RoomyFont.footnote).foregroundStyle(RoomyColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            removeButton
        }
        .padding(.leading, Space.s4)
        .padding(.vertical, Space.s4)
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "minus.circle")
                .font(RoomyFont.title3)
                .foregroundStyle(RoomyColor.textSecondary)
                .frame(width: Layout.tapTarget, height: Layout.tapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(title) from Review")
    }
}

extension BasketItem.Kind {
    var reviewTitle: String {
        switch self {
        case .photo: "Similar photos"
        case .screenshot: "Screenshots"
        case .video: "Videos"
        case .contactGroup: "Duplicate contacts"
        }
    }

    var itemTitle: String {
        switch self {
        case .photo: "Photo"
        case .screenshot: "Screenshot"
        case .video: "Video"
        case .contactGroup: "Contact merge"
        }
    }
}
