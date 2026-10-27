# Memory locator — 0.4.1

A steady cyan chevron next to the operative points toward the nearest stationary memory packet outside attraction range. A dark-backed label below the operative displays horizontal world distance. It is a direction cue, not a safe route; enemies and telegraphs still take priority.

The query runs four times per rendered second. The existing target is retained while it is no more than 20% farther than the nearest alternative, preventing chatter between similar-distance packets. Packets already flying toward the player are excluded; packets within attraction range need no cue. New runs reset the target; menus, pause, upgrades and results hide guidance. No flashes or audio were added.

The system changes no pickup positions, values, attraction range, collection rules, spawn decisions, player statistics or bot movement. It consumes no gameplay RNG. The style resource is shared per UI instance instead of being allocated while drawing. Headless combat benchmarks exclude this UI work; phone overhead and human readability require device testing.

This follows the recorded collector investigation: alternative navigation helped both Arcstorm seeds survive while long upgrade gaps persisted. A human benefit remains a playtest hypothesis. The original cautious-bot matrix remains the baseline for detecting unintended simulation changes.

Asset origin: original procedural lines/chevron and engine fallback font. The staged memory_locator.png screenshot places a packet for visual QA; it is not an actual first-second progression trace.

The app installs separately as NULL SWARM Memory / com.nullswarm.game.memory, version 0.4.1 (6), to preserve older test installs while stable protected signing is unconfigured.

## Verified delivery

Android workflow 40496218606 and QA workflow 40496218604 succeeded for commit 2ed509490f70fe9bf6568ff024be6e8e81ef7e0a. All 165 system checks passed; scene smoke, 180-second deterministic replay and six stress scenarios passed. All non-timing case fields in ten bot runs and six pickup comparisons exactly match canonical 0.4, confirming simulation isolation for those cases. This does not validate human usability. The staged locator render was inspected; signing, archive integrity, checksums and package/runtime contents were verified. Full reports: [0.4.1 QA](qa/0.4.1/BOT_REPORT.md).
