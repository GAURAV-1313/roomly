// Why: every grid and row shows photos the same way — a placeholder, then a fast image, then the final
// one — and cancels the request when the cell scrolls away. Pixels come from the library via AppState. The chip
// holds the cell's size so nothing jumps, and each image crossfades in over what was there.
import SwiftUI

struct AssetThumbnail: View {
    @Environment(AppState.self) private var app
    let id: String
    var pixelSize = CGSize(width: 300, height: 540)
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    /// Counts the images delivered, so the fast one and the final one each crossfade in.
    @State private var delivered = 0

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .id(delivered)
                    .transition(.opacity)
            } else {
                RoomyColor.chip.transition(.opacity)
            }
        }
        .animation(Motion.quick, value: delivered)
        .task(id: id) {
            for await next in app.library.thumbnails(id: id, pixelSize: pixelSize) {
                image = next
                delivered += 1
            }
        }
    }
}
