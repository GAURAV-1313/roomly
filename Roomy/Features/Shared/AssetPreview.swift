// Why: screenshots and photos often hold something people need — a ticket, a code, a receipt — so before one
// is selected for deletion it can be seen large with a long press. The preview keeps the asset's own shape.
import SwiftUI

struct AssetPreview: View {
    let id: String
    /// The asset's pixel dimensions, for its shape; zero when unknown.
    let pixelWidth: Int
    let pixelHeight: Int

    @Environment(\.displayScale) private var displayScale

    init(id: String, pixelWidth: Int = 0, pixelHeight: Int = 0) {
        self.id = id
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    init(_ snapshot: AssetSnapshot) {
        self.init(id: snapshot.id, pixelWidth: snapshot.pixelWidth, pixelHeight: snapshot.pixelHeight)
    }

    var body: some View {
        let size = PreviewSize.fitting(width: pixelWidth, height: pixelHeight, in: Layout.assetPreviewBounds)
        AssetThumbnail(
            id: id, pixelSize: CGSize(width: size.width * displayScale, height: size.height * displayScale),
            contentMode: .fit
        )
        .frame(width: size.width, height: size.height)
    }
}
