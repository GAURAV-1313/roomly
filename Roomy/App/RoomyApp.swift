// Why: the entry point. Roomy is hub-and-spoke (Dashboard → category screens → one Review sheet), so the
// root is a single NavigationStack. Onboarding shows once; state is re-read whenever the app returns. The
// Appearance choice from Settings is applied here, at the root, so every screen, sheet and onboarding follow it.
import SwiftUI

@main
struct RoomyApp: App {
    @State private var appState = AppState()
    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                // Onboarding animates the flag, so the two roots crossfade (motion row 5).
                if didOnboard {
                    DashboardView().transition(.opacity)
                } else {
                    OnboardingView { didOnboard = true }.transition(.opacity)
                }
            }
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
