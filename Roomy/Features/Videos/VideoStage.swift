// Why: the top of the player sheet always shows something true (Figma "VideoStage v5"): the stock AVKit
// player once the video is ready, download progress while Photos fetches it from iCloud, or a plain reason it
// can't play, with Try Again only when trying again can help. It is opaque content; the only glass is AVKit's.
import AVKit
import SwiftUI

struct VideoStage: View {
    let player: AVPlayer?
    let load: VideoLoadState
    let onRetry: () -> Void

    var body: some View {
        stage
            .aspectRatio(Layout.videoAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }

    @ViewBuilder
    private var stage: some View {
        if let player, load == .ready {
            VideoPlayer(player: player)
        } else {
            RoomyColor.chip.overlay { placeholder }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let title = load.failureTitle {
            VStack(spacing: Space.s8) {
                Text(title).font(RoomyFont.headline).foregroundStyle(RoomyColor.textPrimary)
                Text(load.failureMessage ?? "")
                    .font(RoomyFont.footnote)
                    .foregroundStyle(RoomyColor.textSecondary)
                if load.canRetry {
                    Button("Try Again", action: onRetry)
                        .buttonStyle(.roomySecondary)
                        .controlSize(.small)
                }
            }
            .multilineTextAlignment(.center)
            .padding(Space.s16)
        } else {
            VStack(spacing: Space.s8) {
                ProgressView()
                if let label = load.progressLabel {
                    Text(label).font(RoomyFont.footnote).foregroundStyle(RoomyColor.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
