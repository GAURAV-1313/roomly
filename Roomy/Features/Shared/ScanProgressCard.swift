// Why: comparing a library takes minutes, and a screen that only says "scanning" feels stuck. This card shows
// Roomy thinking in the category's well, the real counts and a bar that follows them, above skeletons in the
// shape of the results to come (Figma "ProgressCard v5"). Every word comes from ScanProgressCopy.
import SwiftUI

struct ScanProgressCard: View {
    let copy: ScanProgressCopy
    let route: Route

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s12) {
            HStack(spacing: Space.s12) {
                MascotView(mood: .thinking, size: MascotSize.resultRow)
                    .frame(width: Layout.progressWell, height: Layout.progressWell)
                    .background(
                        route.categoryTintSoft, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                VStack(alignment: .leading, spacing: Space.s2) {
                    Text(copy.title)
                        .font(RoomyFont.headline)
                        .foregroundStyle(RoomyColor.textPrimary)
                    Text(copy.message)
                        .font(RoomyFont.footnote)
                        .foregroundStyle(RoomyColor.textSecondary)
                        .contentTransition(.numericText())
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let fraction = copy.fraction {
                bar(fraction)
            }
        }
        .padding([.top, .leading], Space.s12)
        .padding([.bottom, .trailing], Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
        .animation(Motion.progress, value: copy)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(copy.accessibilityLabel)
    }

    private func bar(_ fraction: Double) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(RoomyColor.ringTrack)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(route.categoryTint)
                        .frame(width: proxy.size.width * fraction)
                }
        }
        .frame(height: Layout.progressBarHeight)
    }
}
