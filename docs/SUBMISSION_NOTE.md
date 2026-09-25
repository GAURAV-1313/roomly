# Submission note (draft, under 150 words)

To: bharat7888@gmail.com — send it yourself after recording; replace the bracketed links.

---

Hi Bharat,

Roomy is an on-device storage cleaner for iPhone: similar photos with a best pick, screenshots, large
videos and duplicate contacts, all staged into one Review with a single delete path.

Tools: Claude Code for the code, Figma MCP for the design, Xcode 26 and the iOS Simulator, and Axiom's iOS
auditors as a second review.

Works: the whole loop on iPhone, including limited and denied access. Merges back up contacts first, and
"freed" appears only after free space is measured again.

Skipped on purpose: video compression, widget (no App Groups on a free account), vault, TestFlight.

Hardest problem: grouping similar photos at scale without false groups. Exact duplicates use LSH over
perceptual hashes; near-duplicates only within the same moment. A 20,000-photo test finds exactly the
planted groups in 0.09 s.

Repo: [link] · Video: [link]

Gaurav
