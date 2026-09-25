// Why: a square tile in a group's filmstrip. The keeper shows the Best badge; others show the shared
// checkmark. A keeper that is queued (the keeper changed after it was picked) shows both, so the card never
// hides what Review would delete. Corners follow the Figma "PhotoTile v5" (Radius.row), inside a 24-point card.
import SwiftUI

nonisolated enum PhotoTileState {
    case unselected
    case selected
    case best
    /// The keeper, but queued for removal.
    case bestSelected

    var isBest: Bool { self == .best || self == .bestSelected }
    var isSelected: Bool { self == .selected || self == .bestSelected }
}

struct PhotoTile: View {
    let id: String
    let state: PhotoTileState
    var size: CGFloat = Layout.photoTileSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
        AssetThumbnail(id: id, pixelSize: CGSize(width: size * 3, height: size * 3))
            .frame(width: size, height: size)
            .clipShape(shape)
            .overlay(shape.strokeBorder(RoomyColor.accent, lineWidth: borderWidth))
            .overlay(alignment: .topLeading) {
                if state.isBest {
                    BestBadge().padding(Space.s4)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if state != .best {
                    SelectionCheck(isSelected: state.isSelected).padding(Layout.tileCheckInset)
                }
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(state.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var borderWidth: CGFloat {
        switch state {
        case .selected, .bestSelected: Layout.tileSelectedRing
        case .best: Layout.tileKeeperRing
        case .unselected: 0
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .best: "Best photo"
        case .bestSelected: "Best photo, selected for removal"
        case .selected, .unselected: "Photo"
        }
    }

    private var accessibilityHint: String {
        switch state {
        case .best: "Opens Compare"
        case .bestSelected: "Keeps it"
        case .selected, .unselected: "Selects it for removal"
        }
    }
}
