# Roomy engineering rules

These rules are not suggestions. `scripts/check.sh` enforces every rule marked **[checked]**; the rest
are enforced in review. Code that breaks a rule is not finished, however well it works.

## 1. Architecture: layers and the direction of dependencies

Roomy uses Apple's native SwiftUI pattern (`@Observable` stores + views), a pure core, and a thin
service layer around the system frameworks. Dependencies point one way only:

```
App ──► Features ──► Stores ──► Services ──► Core
            │                                  ▲
            └──────────► Design ───────────────┘ (Design uses Core value types only)
```

| Folder | Holds | May import | Must not |
|---|---|---|---|
| `App/` | Composition root (`RoomyApp`, `AppState`, `Route`) | anything | contain screen UI |
| `Features/<Screen>/` | One folder per screen: its views and its pure presentation types | SwiftUI, AVKit | import Photos/Contacts; call PhotoKit **[checked]** |
| `Features/Shared/` | Views reused by several screens | SwiftUI | same as Features |
| `Design/` | Tokens, generic components, the Roomy mascot | SwiftUI, UIKit | know about stores, services or `AppState` **[checked]** |
| `Stores/` | `@Observable` app state the screens read | Foundation, Observation | import SwiftUI, UIKit, Photos, Contacts **[checked]** |
| `Services/` | The only code that touches Photos, Contacts, AVFoundation, the file system | system frameworks | import SwiftUI **[checked]** |
| `Core/` | Value types and pure algorithms (hashing, grouping, formatting) | Foundation, CoreGraphics, os | import anything else **[checked]** |

- Features talk to state through `AppState` (`@Environment(AppState.self)`); they never build services.
- Stores receive their services through `init` (protocols such as `PhotoSource`), so they can be tested with fakes.
- Only `Services/Deletion/` may call `PHAssetChangeRequest.deleteAssets` or `CNSaveRequest` **[checked]**.

## 2. State
- **One source of truth.** A fact lives in exactly one place. Selection is the `Basket`; screens do not
  keep their own copy of it.
- Views own only ephemeral UI state (`@State private var`), such as which sheet is open.
- Business rules live in Core or Stores, never in a view. Derived presentation (labels, fractions, moods)
  goes in a small pure struct next to the view (for example `DashboardSummary`) and gets a unit test.

## 3. Concurrency
- UI code runs on the main actor (the project default). Heavy work never does: it runs in an `actor`,
  a detached task inside a service, or a `@concurrent` function.
- Types in `Core/` and `Services/` are `nonisolated`, and so are their extensions: write
  `nonisolated extension`, because the project default would make a plain extension main-actor.
- Only `Sendable` value types cross actor boundaries. PhotoKit and Contacts objects never leave `Services/`.
- A closure handed to a system framework that may call it on another thread (a `UIColor` light/dark
  provider, `performChanges`, a completion handler) is written in a `nonisolated` context or marked
  `@Sendable`. Written inside main-actor code it inherits the main actor, and the runtime traps when the
  framework calls it from elsewhere — a warning-free build that crashes. Never silence this with
  `nonisolated(unsafe)` or `@preconcurrency`.
- Long-running work reports progress through an `AsyncStream`, consumed with `for await`. No
  fire-and-forget `Task { @MainActor in }` hops for state updates.
- Every `Task` that can be superseded is stored and cancelled, and checks `Task.isCancelled` before it
  writes state.

## 4. Size and shape
- One primary type per file; the file is named after it. Small private helpers may share the file.
- A file is at most **200 lines** **[checked]**. A function is at most about 40 lines. A view's `body` is
  at most about 30 lines: extract subviews or computed properties with names.
- Folders mirror the layers above. A type used by two screens moves to `Features/Shared/` or `Design/`.

## 5. Readability
- One statement per line. No semicolons **[checked]**. Lines at most 120 characters **[checked]**.
- Names say what a thing is, in full words: `extras`, not `others`; `keptMembers`, not `deselected`.
  Single letters only for `$0`, loop indices and maths formulas.
- Booleans read as questions (`isSelected`, `canUseLibrary`). Prefer an `enum` to two related booleans.
- No nested ternaries. No force unwraps or `try!` **[checked]**. `try?` only where failure is expected and
  harmless, with a comment saying why; otherwise log the error.
- No magic numbers in views: spacing, sizes, radii and colours come from `Design/Tokens`. Tuning
  constants are named `static let` values with a doc comment.
- Imports are sorted; formatting is whatever `swift-format` produces **[checked]**.

## 6. Comments and copy
- Every file starts with a `// Why:` comment explaining the decision it embodies, not what the code does.
- Comments explain *why*. No comments that restate code, and no time-bound notes ("Day 2", "for now").
- User-facing text is product copy. No developer notes, build days or `TODO`s on screen **[checked]**.
- No `print`; use the `Log` loggers **[checked]**.

## 7. Safety and honesty (product rules that shape code)
- One delete path, reached only from the Review confirmation.
- Never show a made-up value: unknown sizes read "size unavailable", filenames come from the library.
- "Removed" is not "freed" until free space is measured again.

## 8. Tests
- Every Core algorithm and every Store state transition has unit tests. New logic ships with its test.
- Bugs get a regression test that fails before the fix.
- Tests use fakes (`FakePhotoSource`) instead of the real photo library.
- Tests that create a main-actor store are `@MainActor func test…() async`. A synchronous main-actor
  test that lets a store deallocate crashes the test host on the iOS 26 runtime.

## 9. Definition of done
1. `scripts/check.sh` passes: architecture rules, `swift-format` lint, build with zero warnings, all tests.
2. The change is verified in the simulator when it touches UI.
3. The file headers, this document and the Figma file still describe the code.
