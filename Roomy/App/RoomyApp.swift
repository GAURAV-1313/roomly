// Why: the entry point. Roomy is hub-and-spoke (Dashboard → category screens → one Review sheet), so the
// root is a single NavigationStack. Onboarding shows once; state is re-read whenever the app returns.
import SwiftUI

@main
struct RoomyApp: App {
    @State private var appState = AppState()
    @AppStorage("didOnboard") private var didOnboard = false
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
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    appState.refreshOnForeground()
                }
            }
        }
    }
}
