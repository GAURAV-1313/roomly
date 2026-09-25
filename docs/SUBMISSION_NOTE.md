# Submission note (under 150 words)

To: bharat7888@gmail.com. Send it yourself after recording on the iPhone, with the two links filled in.
The repository is private: add the reviewer as a collaborator, or make it public, before sending.

---

Hi Bharat,

Roomy is an on-device storage cleaner for iPhone: similar photos with a best pick, screenshots, large videos
and duplicate contacts, all staged into one Review with a single delete path.

Tools: Claude Code for the code, Figma (through its MCP) for every screen first, Xcode 27 and the iOS 27
simulator.

Works: the full loop on iPhone, with limited and denied access, light and dark mode. Contacts are merged, never
lost, after a backup. "Freed" appears only once free space is measured again.

Skipped on purpose: video compression, widget, vault, TestFlight (paid account).

Hardest problem: grouping similar photos at scale without false groups. Exact copies use LSH over perceptual
hashes; near-duplicates only within one moment. A 20,000-photo test finds exactly the planted groups.

Repo: [link] · Video: [link]

Gaurav
