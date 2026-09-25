// Why: a notice is one more card on the dashboard, not an alarm: the same white card as the category tiles, a
// small ink icon on a neutral chip, one line of explanation and the way to act on it at the end. The whole row is
// the button, so it stays short. Colour is only a small status dot on the chip — amber for "finish the job", green
// for space measured as free — so the icon never outshouts the title or reads as a warning.
import SwiftUI

struct NoticeRow: View {
    enum Tone {
        case info
        case warning
        case success

        var tint: Color {
            switch self {
            case .info: RoomyColor.accent
            case .warning: RoomyColor.warning
            case .success: RoomyColor.success
            }
        }

        /// Info notices carry no status dot; the others show their colour only there.
        var hasStatusDot: Bool { self != .info }
    }

    enum Accessory {
        /// The row is a button; the title names what it does.
        case action(String, () -> Void)
        case dismiss(() -> Void)
        case none
    }

    let tone: Tone
    let systemImage: String
    let title: String
    let message: String
    var hint: String? = nil
    var accessory = Accessory.none

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        switch accessory {
        case .action(let label, let action):
            Button(action: action) { card(trailing: actionLabel(label)) }
                .buttonStyle(.plain)
                .accessibilityHint(hint ?? "")
        case .dismiss(let dismiss):
            card(trailing: dismissButton(dismiss))
        case .none:
            card(trailing: EmptyView())
        }
    }

    /// At accessibility text sizes the accessory moves under the text instead of squeezing it.
    private func card(trailing: some View) -> some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Space.s12))
        return layout {
            HStack(alignment: isStacked ? .top : .center, spacing: Space.s12) {
                icon
                text
            }
            trailing
        }
        .padding(.horizontal, Space.s16)
        .padding(.vertical, Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(RoomyFont.subheadlineSemibold)
            // The chip has a fixed size, so its glyph stops growing where it would spill out.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .foregroundStyle(RoomyColor.textPrimary)
            .frame(width: Layout.noticeIcon, height: Layout.noticeIcon)
            .background(RoomyColor.chip, in: RoundedRectangle(cornerRadius: Radius.grid, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if tone.hasStatusDot {
                    Circle()
                        .fill(tone.tint)
                        .frame(width: Layout.noticeDot, height: Layout.noticeDot)
                        .padding(Space.s2)
                        .background(RoomyColor.card, in: Circle())
                        .offset(x: Space.s4, y: -Space.s4)
                }
            }
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(title)
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.textPrimary)
            Text(message)
                .font(RoomyFont.footnote)
                .foregroundStyle(RoomyColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func actionLabel(_ label: String) -> some View {
        HStack(spacing: Space.s2) {
            Text(label)
            Image(systemName: "chevron.right").font(RoomyFont.footnoteSemibold)
        }
        .font(RoomyFont.subheadlineSemibold)
        .foregroundStyle(RoomyColor.accent)
    }

    private func dismissButton(_ dismiss: @escaping () -> Void) -> some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.textSecondary)
                .frame(width: Layout.tapTarget, height: Layout.tapTarget)
        }
        .accessibilityLabel("Dismiss")
    }
}

#Preview {
    VStack(spacing: Space.s12) {
        NoticeRow(
            tone: .warning, systemImage: "trash", title: "4.9\u{00A0}MB in Recently Deleted",
            message: "Empty it in Photos to free it.", accessory: .action("Open", {}))
        NoticeRow(
            tone: .success, systemImage: "checkmark", title: "2.1\u{00A0}GB more free space",
            message: "Measured just now.", accessory: .dismiss({}))
        NoticeRow(
            tone: .info, systemImage: "lock.fill", title: "Photos access is restricted",
            message: "Access is managed on this phone.")
    }
    .padding()
    .background(RoomyColor.bg)
}
