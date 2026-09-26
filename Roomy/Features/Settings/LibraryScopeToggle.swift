// Why: the Library row (Figma "SettingsRow v5" with a switch): the usual icon and label, with the switch at the
// row's end, or on its own line under the label at accessibility sizes so the label never squeezes. It writes
// the scope through `AppState`, which saves it and updates every screen at once.
import SwiftUI

struct LibraryScopeToggle: View {
    @Environment(AppState.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static let title = "Include iCloud-only items"

    var body: some View {
        @Bindable var app = app
        let toggle = Toggle(Self.title, isOn: $app.libraryScope.includesICloud)
            .toggleStyle(.switch)
            .tint(RoomyColor.accent)
            .labelsHidden()
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(spacing: 0))
        layout {
            // The switch names itself to VoiceOver, so the visible label is not read twice.
            SettingsRow(systemImage: "icloud", title: Self.title, kind: .label)
                .accessibilityHidden(true)
            toggle
                .padding(.leading, dynamicTypeSize.isAccessibilitySize ? Layout.settingsSeparatorInset : 0)
                .padding(.trailing, Space.s16)
                .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? Layout.settingsPickerBottom : 0)
        }
    }
}
