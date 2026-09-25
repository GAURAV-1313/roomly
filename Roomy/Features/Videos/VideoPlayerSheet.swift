// Why: watch before deciding. AVKit's player brings its own controls (already glass on iOS 26); the sheet
// adds the facts that matter and a single button to add or remove the video from review. Loading always ends:
// in the video, or in a plain reason with Retry, and closing the sheet cancels an iCloud download.
import AVKit
import SwiftUI

struct VideoPlayerSheet: View {
    @Environment(AppState.self) private var app
    let video: AssetSnapshot
    @State private var player: AVPlayer?
    @State private var load = VideoLoadState.loading(progress: nil)
    /// Bumped by Retry; the load task restarts whenever it changes.
    @State private var attempt = 0

    private var isSelected: Bool { app.basket.contains(video.id) }

    var body: some View {
        VStack(spacing: Space.s12) {
            VideoStage(player: player, load: load) { attempt += 1 }
            VideoFactsCard(facts: VideoDetails.facts(video))
            Spacer(minLength: Space.s12)
            Button(isSelected ? "Remove from Review" : "Add to Review") {
                Haptics.success()
                app.basket.toggle(video)
            }
            .buttonStyle(isSelected ? .roomySecondary : .roomyPrimary)
        }
        .padding(.horizontal, Space.margin)
        .padding(.top, Space.s16)
        .padding(.bottom, Space.margin)
        .background(RoomyColor.sheet)
        .task(id: attempt) { await loadVideo() }
        .onDisappear { player?.pause() }
    }

    /// Runs once per attempt. The task is cancelled when the sheet closes or Retry starts a new one, which ends
    /// the stream and so cancels the Photos request; a cancelled attempt never writes state.
    private func loadVideo() async {
        player?.pause()
        player = nil
        load = .loading(progress: nil)
        for await event in app.library.video(video.id) {
            guard !Task.isCancelled else { return }
            if let item = load.apply(event) {
                player = AVPlayer(playerItem: item)
            }
        }
        // The stream promises a last word; if it ever ends without one, the sheet still says something.
        if !Task.isCancelled, case .loading = load {
            load = .failed(.unavailable)
        }
    }
}
