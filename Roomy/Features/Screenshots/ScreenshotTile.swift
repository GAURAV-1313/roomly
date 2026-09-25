// Why: screenshots keep their 9:16 shape because people recognise them by shape. Many are mostly white, so an
// unselected tile keeps a hairline edge to stay distinct on the parchment; selection swaps it for the accent
// ring and the shared checkmark (Figma "ScreenshotTile v5").
import SwiftUI

struct ScreenshotTile: View {
    let id: String
    let isSelected: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.grid, style: .continuous)
        Color.clear
            .aspectRatio(9 / 16, contentMode: .fit)
            .overlay(AssetThumbnail(id: id))
            .background(RoomyColor.card)
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    isSelected ? RoomyColor.accent : RoomyColor.separator,
                    lineWidth: isSelected ? Layout.tileSelectedRing : Layout.tileHairline)
            )
            .overlay(alignment: .bottomTrailing) {
                SelectionCheck(isSelected: isSelected).padding(Layout.tileCheckInset)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Screenshot")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
