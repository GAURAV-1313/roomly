// Why: the entry point. Roomy is hub-and-spoke (Dashboard → category screens → one Review sheet), so the
// root is a single NavigationStack. `AppRoot` picks onboarding (once), the launch intro or the dashboard; state is
// re-read whenever the app returns. The Appearance choice from Settings is applied here, at the root, so every
// screen, sheet, the intro and onboarding follow it.
import SwiftUI

@main
struct RoomyApp: App {
    @State private var appState = AppState()
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(appState)
                .tint(RoomyColor.accent)
                .preferredColorScheme(appearance.colorScheme)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        appState.refreshOnForeground()
                    }
                }
        }
    }
}
