// Why: Settings and onboarding (Figma v5 "SettingsRow", "PermissionRow" and the onboarding hero card) have
// measurements of their own. They live beside the shared layout tokens, in their own file, so these two
// screens can change size without touching the tokens every other screen depends on.
import SwiftUI

extension Layout {
    /// A Settings row (Figma "SettingsRow v5"): its minimum height, vertical padding and the icon square.
    static let settingsRowMinHeight: CGFloat = 52
    static let settingsRowVerticalPadding: CGFloat = 10
    static let settingsIcon: CGFloat = 30
    /// The inset hairline between rows starts under the label: the row's padding, the icon and the gap after it.
    static let settingsSeparatorInset: CGFloat = Space.s16 + settingsIcon + Space.s12
    /// The gap between a Settings section's header, card and footer.
    static let settingsSectionSpacing: CGFloat = 10
    /// The extra room above a section header, so sections read as groups.
    static let settingsHeaderTop: CGFloat = 14
    /// The room under a control that sits on its own line in a Settings card, such as the Appearance picker.
    static let settingsPickerBottom: CGFloat = 14
    /// The gap between the points of "How deletion works".
    static let deletionPointSpacing: CGFloat = 14
    /// The hairline between rows of a Settings card.
    static let hairline: CGFloat = 1

    /// An onboarding permission card (Figma "PermissionRow v5"): the icon square and the granted check.
    static let permissionIcon: CGFloat = 44
    static let permissionCheck: CGFloat = 24
    /// Roomy on the onboarding promise card.
}
