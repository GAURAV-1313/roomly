# Running Roomy on an iPhone (free Apple ID)

Tested target: iPhone 16 on iOS 27. The app supports iOS 17 and later.

## Before you start

- **Xcode must know your iOS version.** An iPhone on iOS 27 needs an Xcode that supports iOS 27 (Xcode 27 or
  later). With an older Xcode, the run destination says the iOS version is not supported: update Xcode from the
  App Store, then run `scripts/check.sh` once to confirm everything still builds.
- **Your own Apple ID must be in Xcode:** Xcode → Settings → Accounts → **+** → Apple ID. Sign in yourself; this
  creates your free **Personal Team**.

## Steps

1. Connect the iPhone with a cable, unlock it, and tap **Trust** if asked.
2. On the iPhone: Settings → Privacy & Security → **Developer Mode** → on (the phone restarts).
3. Set your signing team once: `cp Signing.local.xcconfig.example Signing.local.xcconfig`, then put your team ID
   in it (Xcode → Settings → Accounts → your Apple ID shows it). This file is ignored by git and survives
   `xcodegen generate`, which would erase a team picked in Xcode's Signing tab. If Xcode says the bundle id is
   taken, set `PRODUCT_BUNDLE_IDENTIFIER = com.<you>.roomy` in the same file.
4. `xcodegen generate && open Roomy.xcodeproj`
5. Pick the iPhone as the run destination and press Run.
6. First launch only: Settings → General → VPN & Device Management → your Apple ID → **Trust**.

Free provisioning lasts 7 days and allows 3 apps per device. After that, run from Xcode again.

## Before the screen recording

- Use a throwaway album, never your real library: in Photos, choose **Limited Access** for Roomy and select
  only a test album, or record on a phone with test photos only.
- Add a few duplicate contacts (for example save the same person twice with the number written differently).
- Turn on Do Not Disturb so no notification shows a name.
- The shot list is in [RECORDING.md](RECORDING.md).
