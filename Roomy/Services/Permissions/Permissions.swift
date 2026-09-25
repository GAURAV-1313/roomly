// Why: the framework permission enums differ between Photos and Contacts, and Contacts gained `.limited`
// only in iOS 18. This file maps both onto `AccessState` so nothing else needs to know the frameworks.
import Contacts
import Photos
import PhotosUI
import UIKit

nonisolated enum PhotoPermission {
    static func current() -> AccessState {
        map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    static func request() async -> AccessState {
        map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    /// Shows the system picker for a limited selection and returns when it closes. A no-op unless limited.
    @MainActor static func presentLimitedPicker() async {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        guard var presenter = windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let once = ResumeOnce(continuation)
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter) { _ in
                once.resume(returning: ())
            }
        }
    }

    static func map(_ status: PHAuthorizationStatus) -> AccessState {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .limited: .limited
        case .authorized: .authorized
        @unknown default: .denied
        }
    }
}

nonisolated enum ContactPermission {
    static func current() -> AccessState {
        map(CNContactStore.authorizationStatus(for: .contacts))
    }

    static func request() async -> AccessState {
        do {
            _ = try await CNContactStore().requestAccess(for: .contacts)
        } catch {
            Log.permissions.error("contacts request: \(error.localizedDescription)")
        }
        return current()
    }

    static func map(_ status: CNAuthorizationStatus) -> AccessState {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        default:
            if #available(iOS 18.0, *), status == .limited { return .limited }
            return .denied
        }
    }
}

@MainActor enum SystemSettings {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Recently Deleted can only be emptied by the person, in Photos. Opening Photos is the closest an app can get.
@MainActor enum PhotosApp {
    static func open() {
        guard let url = URL(string: "photos-redirect://") else { return }
        UIApplication.shared.open(url) { didOpen in
            if !didOpen {
                Log.permissions.error("could not open Photos")
            }
        }
    }
}
