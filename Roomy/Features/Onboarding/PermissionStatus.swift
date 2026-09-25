// Why: a permission card shows its state quietly and offers exactly the one fix that can work: Allow before the
// first ask, Change selection for limited Photos, Open Settings when access is off (and for limited Contacts,
// because duplicates hide across the whole address book). Restricted access is managed on the phone and nothing
// in Settings can change it, so it offers no button at all. Nothing here is red or amber; red stays reserved for
// the final delete. The mapping is pure so it is tested, and VoiceOver hears the same state the eye sees.
import Foundation

/// The two things onboarding asks for.
nonisolated enum PermissionKind: Sendable {
    case photos
    case contacts

    var title: String {
        switch self {
        case .photos: "Photos"
        case .contacts: "Contacts"
        }
    }

    var tag: String {
        switch self {
        case .photos: "Required"
        case .contacts: "Optional"
        }
    }

    var purpose: String {
        switch self {
        case .photos: "Scans your library on this phone to find what can go."
        case .contacts: "Finds duplicate cards so you can merge them."
        }
    }

    var systemImage: String {
        switch self {
        case .photos: "photo.stack"
        case .contacts: "person.crop.rectangle.stack"
        }
    }
}

/// What a card's button does.
nonisolated enum PermissionAction: Sendable, Equatable {
    case allow
    case changeSelection
    case openSettings

    var title: String {
        switch self {
        case .allow: "Allow"
        case .changeSelection: "Change selection"
        case .openSettings: "Open Settings"
        }
    }
}

nonisolated struct PermissionStatus: Sendable, Equatable {
    /// The quiet word on the right; nil before the first ask, where the Allow button stands instead.
    let label: String?
    let isGranted: Bool
    /// The line under a separator that explains a state needing attention.
    let footer: String?
    let action: PermissionAction?

    init(_ state: AccessState, kind: PermissionKind) {
        switch state {
        case .notDetermined:
            self.init(label: nil, footer: nil, action: .allow)
        case .authorized:
            self.init(label: "Allowed", isGranted: true, footer: nil, action: nil)
        case .limited where kind == .photos:
            self.init(label: "Limited", footer: "Roomy sees only the photos you picked.", action: .changeSelection)
        case .limited:
            self.init(label: "Limited", footer: "Duplicates hide across the whole address book.", action: .openSettings)
        case .denied:
            self.init(label: "Off", footer: "Turn on \(kind.title) for Roomy in Settings.", action: .openSettings)
        case .restricted:
            self.init(label: "Restricted", footer: "Access is managed on this phone.", action: nil)
        }
    }

    private init(label: String?, isGranted: Bool = false, footer: String?, action: PermissionAction?) {
        self.label = label
        self.isGranted = isGranted
        self.footer = footer
        self.action = action
    }

    /// The Allow button sits where the label goes; every other button sits in the footer.
    var isActionInline: Bool { action == .allow }

    var accessibilityValue: String { label ?? "Not asked yet" }
}
