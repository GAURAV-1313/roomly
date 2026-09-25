# Running Roomy on an iPhone (free Apple ID)

1. Connect the iPhone with a cable, unlock it, and tap **Trust** if asked.
2. On the iPhone: Settings → Privacy & Security → **Developer Mode** → on (the phone restarts).
3. `xcodegen generate && open Roomy.xcodeproj`
4. Select the **Roomy** target → Signing & Capabilities → Team: your **Personal Team**. If Xcode says the
   bundle id is unavailable, change `com.gauravsingh.roomy` to something unique (for example `com.<you>.roomy`).
5. Pick the iPhone as the run destination and press Run.
6. First launch only: Settings → General → VPN & Device Management → your Apple ID → **Trust**.

Free provisioning lasts 7 days and allows 3 apps per device. After that, run from Xcode again.

## Before the screen recording

- Use a throwaway album, never your real library: in Photos, choose **Limited Access** for Roomy and select
  only a test album, or record on a phone with test photos only.
- Add a few duplicate contacts (for example save the same person twice with the number written differently).
- Turn on Do Not Disturb so no notification shows a name.
- The shot list is in [RECORDING.md](RECORDING.md).
