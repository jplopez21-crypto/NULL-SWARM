# Changelog

## 0.1.0 — 2026-10-26

- Created the Godot 4.6.3 project and five-minute survival loop.
- Added VANGUARD movement, dash, shields, automatic Pulse Rifle, three enemy behaviors and telegraphed attacks.
- Added experience, capped upgrade choices, menu/pause/settings/results, touch/controller input and performance overlay.
- Added generated original audio, versioned local saves with backup recovery, resource definitions and reusable combat systems.
- Added automated gameplay/system checks, Android/Windows export presets and an Android debug CI workflow.
- Android installation, physical-device performance, release signing and commercial content remain unverified or deferred.

### Verification follow-up

- Fixed audio playback cleanup during shutdown.
- Re-ran 79 automated checks and the scene smoke successfully, with no leak warnings in the final runs.
- Confirmed Android dependency download and GitHub write access remain blocked; no APK produced.

## 0.1.0 Android build — 2026-10-27

- Published the complete source and build pipeline to GitHub.
- Fixed the Java action revision, enabled Android ETC2/ASTC imports and corrected CI log validation.
- GitHub Actions passed import, all 79 tests, scene smoke, debug APK export and signature verification.
- Downloaded APK and independently verified artifact and APK checksums/archive integrity.
- Physical-device installation and gameplay testing remain outstanding; CI still reports an intermittent test-shutdown leak warning.

## 0.2.0 — Reactor Zero combat pass

- Expanded to six weapons, four equipment slots, ranked weapon upgrades and two rerolls.
- Added Arcstorm Rifle and Solar Halo mutations, and a kill-chain Overclock reward.
- Added Bulwark/Skimmer enemies, the Warden mini-boss and three-phase Architect encounter.
- Extended the run to ten minutes with extraction gated by final-boss defeat.
- Added a tiled reactor arena, industrial perimeter machinery, weapon-colored effects, animated operative, revised menus/cards/HUD, boss bars and encounter announcements.
- Added distinct generated weapon sounds and an original sequenced combat loop.
- Added pooled effect budgets and rendered CI captures. This remains development artwork/audio.
- Uses a separate Reactor package so it can coexist with the owner's working original APK.

### 0.2 verification

- Passed 100 automated checks, rendered visual capture, Android debug export and APK signature verification in workflow 40432471369.
- Fixed upgrade-card feedback layering and cancelled pending boss attacks across encounter transitions.
- Independently verified downloaded artifact/APK checksums and excluded QA captures from the APK.
- Physical-device playtesting and profiling remain required; intermittent CI smoke shutdown warning remains.

## 0.3.0 — Foundry

- Added banked salvage, bounded permanent research and earned starting-kit sidegrades.
- Added version 1 → 2 save migration and an idempotent checkpoint/reward ledger; failed research writes refund cost and rank.
- Added pooled destruction debris and timed boss-core vulnerability during phase changes.
- Added actual per-weapon damage totals to results; excludes overkill and damage to dead targets.
- Narrowly reduced Solar Halo area-pulse damage and corrected Overclock threshold copy.
- Added Foundry/results CI captures and a separate Foundry debug application package.

### 0.3 verification

- Passed 121 checks, scene smoke, rendered capture, Android export and APK signature verification in workflow 40435364064.
- Inspected the Foundry/results screens and verified downloaded ZIP/APK integrity and hashes.
- Owner playtesting of 0.3 and physical-device profiling remain pending.

## Automated gameplay QA — 2026-10-27

- Added normal-rules bots with three upgrade strategies, fixed seeds, fresh/earned-kit fixtures and deterministic replay verification.
- Added survival, damage, mutation, XP collection, progression-gap and entity-count reports.
- Added low/high synthetic stress scenarios at 100/300/600 enemies with gameplay-state parity checks and CPU percentiles.
- Added a dedicated Actions workflow publishing JSON, Markdown and diagnostic logs on pushes/PRs/manual runs.
- Gameplay code and APK version remain unchanged.

### QA baseline verification

- CI passed 121 checks, eight normal-rules bot cases and replay verification, and six synthetic benchmark scenarios.
- Seven bot victories/one defeat reproduced across local and CI machines; no invariant failures.
- Committed canonical JSON/Markdown reports; retained CPU-vs-device and bot-vs-human limits.
