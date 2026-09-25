// Why: Settings is white cards on the parchment, like the dashboard (Figma v5), not a system grouped list. One
// view draws a section — a header, one card, an optional footnote — so every section is spaced the same.
import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let footer: String?
    let content: Content

    init(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.settingsSectionSpacing) {
            Text(title)
                .font(RoomyFont.title3)
                .foregroundStyle(RoomyColor.textPrimary)
                .padding(.top, Layout.settingsHeaderTop)
                .padding(.bottom, Space.s2)
                .padding(.leading, Space.s4)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .dashboardCard()
            if let footer {
                Text(footer)
                    .font(RoomyFont.footnote)
                    .foregroundStyle(RoomyColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.s4)
            }
        }
    }
}
