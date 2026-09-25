// Why: the Appearance row (Figma "SettingsRow v5 · Kind=picker"): the usual icon and label, with the segmented
// control on its own line under the label, so its three segments fit at every text size. The system control
// slides its selection; the choice is written straight to UserDefaults and the app root re-reads it.
import SwiftUI

struct AppearancePicker: View {
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The picker names itself to VoiceOver, so the visible label is not read twice.
            SettingsRow(systemImage: "circle.lefthalf.filled", title: "Appearance", kind: .label)
                .accessibilityHidden(true)
            Picker("Appearance", selection: $appearance) {
                ForEach(Appearance.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.leading, Layout.settingsSeparatorInset)
            .padding(.trailing, Space.s16)
            .padding(.bottom, Layout.settingsPickerBottom)
        }
    }
}
