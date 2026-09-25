// Why: every Settings row has the same shape (Figma "SettingsRow v5"): a small tinted icon, a label, and what
// the row does at its end — a value, an accent label for an action, or a share glyph. The row only draws; the
// Button or ShareLink around it decides what a tap does, so a row can never act on its own.
import SwiftUI

struct SettingsRow: View {
    enum Kind {
        /// A fact, such as an access level, shown at the end of the row.
        case value(String)
        /// An action; the label is accent-coloured, like a link.
        case action
        /// A file the person can share.
        case share
        /// A quiet line that stands in for rows that do not exist yet.
        case placeholder
    }

    var systemImage: String? = nil
    let title: String
    let kind: Kind
    /// Rows after the first draw an inset hairline above themselves.
    var showsSeparator = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: Space.s12) {
            if let systemImage {
                SettingsIcon(systemImage: systemImage)
            }
            labels
            trailingGlyph
        }
        .padding(.horizontal, Space.s16)
        .padding(.vertical, Layout.settingsRowVerticalPadding)
        .frame(maxWidth: .infinity, minHeight: Layout.settingsRowMinHeight, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(alignment: .top) { separator }
    }

    /// At accessibility text sizes a value moves under its label instead of squeezing it.
    private var labels: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s2))
            : AnyLayout(HStackLayout(spacing: Space.s12))
        return layout {
            Text(title)
                .font(RoomyFont.body)
                .foregroundStyle(titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            if case .value(let value) = kind {
                Text(value)
                    .font(RoomyFont.body)
                    .foregroundStyle(RoomyColor.textSecondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var titleColor: Color {
        switch kind {
        case .value, .share: RoomyColor.textPrimary
        case .action: RoomyColor.accent
        case .placeholder: RoomyColor.textSecondary
        }
    }

    @ViewBuilder
    private var trailingGlyph: some View {
        if case .share = kind {
            Image(systemName: "square.and.arrow.up")
                .font(RoomyFont.subheadlineSemibold)
                .foregroundStyle(RoomyColor.accent)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var separator: some View {
        if showsSeparator {
            RoomyColor.separator
                .frame(height: Layout.hairline)
                .padding(.leading, Layout.settingsSeparatorInset)
        }
    }
}

/// The small accent-soft square that starts a Settings row or a point of "How deletion works".
struct SettingsIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(RoomyFont.subheadline)
            // The square has a fixed size, so its glyph stops growing where it would spill out.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .foregroundStyle(RoomyColor.accent)
            .frame(width: Layout.settingsIcon, height: Layout.settingsIcon)
            .background(RoomyColor.accentSoft, in: RoundedRectangle(cornerRadius: Radius.grid, style: .continuous))
            .accessibilityHidden(true)
    }
}
