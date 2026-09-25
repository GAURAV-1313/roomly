// Why: one video as a card: poster with play and duration, its real filename, date and resolution, and its
// size in a right-aligned column, so the biggest files are obvious at a glance. A video kept only in iCloud
// says so, because its size is not space this phone gets back. At accessibility text sizes the row stacks —
// a full-width poster, then the words, then size and check — instead of squeezing the filename to nothing.
import SwiftUI

struct VideoRow: View {
    let video: AssetSnapshot
    let isSelected: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var checkSize = Layout.selectionCheck

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize { stacked } else { row }
        }
        .dashboardCard()
        .selectedRing(isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        // One VoiceOver element: activating it selects, and Play is offered as a named action.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(.default, onSelect)
        .accessibilityAction(named: "Play", onPlay)
    }

    private var row: some View {
        HStack(spacing: Space.s12) {
            playButton { poster }
            words(filenameLines: 1)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: Space.s8) {
                sizeLabel
                check
            }
        }
        .padding([.leading, .vertical], Space.s8)
        .padding(.trailing, Layout.videoRowTrailingInset)
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            playButton { poster }
            Group {
                words(filenameLines: 3)
                HStack {
                    sizeLabel
                    Spacer(minLength: Space.s8)
                    check
                }
            }
            .padding(.horizontal, Space.s8)
        }
        .padding([.top, .horizontal], Space.s8)
        .padding(.bottom, Space.s16)
    }

    private func playButton(@ViewBuilder _ label: () -> some View) -> some View {
        Button(action: onPlay, label: label)
            .buttonStyle(.plain)
            .accessibilityLabel("Play video")
    }

    private func words(filenameLines: Int) -> some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(video.filename ?? "Video")
                .font(RoomyFont.headline)
                .foregroundStyle(RoomyColor.textPrimary)
                .lineLimit(filenameLines)
                .truncationMode(.middle)
            Text(VideoDetails.rowLine(video))
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The size in Title 3, or "size unavailable" quietly in its place: never a made-up number.
    @ViewBuilder
    private var sizeLabel: some View {
        if video.size == nil {
            Text(SizeLabel.unavailable)
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
                .multilineTextAlignment(.trailing)
        } else {
            Text(SizeLabel.value(video.size))
                .font(RoomyFont.title3)
                .monospacedDigit()
                .foregroundStyle(RoomyColor.textPrimary)
        }
    }

    private var check: some View {
        SelectionCheck(isSelected: isSelected, surface: .card, size: checkSize)
    }

    /// Small beside the words; full width at 16:9 when the row stacks.
    @ViewBuilder
    private var posterShape: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Color.clear
                .aspectRatio(Layout.videoAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(width: Layout.videoPoster.width, height: Layout.videoPoster.height)
        }
    }

    private var poster: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        return
            posterShape
            .overlay { AssetThumbnail(id: video.id) }
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay { playMark(isLarge: isLarge) }
            .overlay(alignment: .bottomTrailing) { durationPill.padding(Space.s4) }
    }

    private func playMark(isLarge: Bool) -> some View {
        Image(systemName: "play.fill")
            .font(.system(size: isLarge ? Layout.videoPlayGlyphLarge : Layout.videoPlayGlyph, weight: .bold))
            .foregroundStyle(RoomyColor.onAccent)
            .frame(
                width: isLarge ? Layout.tapTarget : Layout.videoPlayMark,
                height: isLarge ? Layout.tapTarget : Layout.videoPlayMark
            )
            .background(RoomyColor.dim, in: Circle())
    }

    private var durationPill: some View {
        Text(Duration.seconds(video.duration).formatted(.time(pattern: .minuteSecond)))
            .font(RoomyFont.caption)
            .monospacedDigit()
            .foregroundStyle(RoomyColor.onAccent)
            .padding(Layout.durationPillPadding)
            .background(
                RoomyColor.dim, in: RoundedRectangle(cornerRadius: Layout.durationPillRadius, style: .continuous))
    }
}
