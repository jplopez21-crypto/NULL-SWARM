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

## 0.3.1 — Local memory packets

- Replaced FIFO pickup merging, which could relocate XP across the arena, with nearby stationary merges limited to 3m. Sparse drops remain separate; earned XP is conserved.
- Added larger mint/gold high-value packets and a shared sphere mesh.
- Added regression tests, a pinned legacy replay fixture and a separate value-aware test collector.
- Added six-case XP A/B/collector comparison to repeatable CI; original cautious bot remains unchanged.
- No combat-stat buffs or spawn/difficulty reductions. Uses a separate Foundry XP package to preserve older test installs/saves.

### 0.3.1 verified delivery

- CI passed 130 checks, eight normal bot cases, six labelled pickup/collector comparisons and six synthetic stress scenarios.
- Reproduced pinned legacy outcomes; confirmed both local improvement and regression with the unchanged cautious bot. The alternate collector won both fixed seeds.
- Verified signed APK export, downloaded hashes/archive integrity and new manifest package; inspected the menu capture.
- Reports are preserved under docs/qa/0.3.1; phone playtesting remains pending.

## 0.4.0 — Adaptive Swarm

- Added run-local combat signature observation and announced, time-limited enemy-composition responses.
- Added eight-second warnings, persistent counterplay hints, boss quiet windows and fresh signatures on restart.
- Added amber-core Insulators with explicit 20% electrical resistance; other weapon damage is unchanged.
- Added adaptation histories/composition/resistance telemetry, electricity-focused bot coverage and a 180-second seeded replay.
- Expanded the synthetic fixture to all six regular enemy types; versioned the changed workload.
- Added staged warning/active visual captures and a separate Adaptive test package.
- Distributed each archetype across all AI update phases and added six distribution checks.

### 0.4 verified delivery

- CI passed 156 checks, scene smoke, ten normal bot cases/180-second deterministic replay, six pickup comparisons and six stress scenarios. Seven bot wins/three losses retained in reports.
- Verified signed APK export, downloaded ZIP/APK hashes, archive integrity and Adaptive package contents; inspected staged warning/active renders.
- Archived canonical reports under docs/qa/0.4. Physical-device performance and human balance remain unverified.

### 0.4 collector investigation

- Added optional eight-case Arcstorm/Kinetic navigation comparison with normal combat rules.
- Reproduced all four cautious baseline fields and documented mixed gap results; preserved full traces.
- Re-ran 156 system checks. Installed gameplay and APK unchanged.

## 0.4.1 — Memory locator

- Added a steady player-relative direction cue and distance to nearby uncollected memory, with target hysteresis and four queries per second.
- Cue ignores in-flight packets and packets within attraction range; pause/panels suppress it. It does not alter pickup positions, XP, attraction, combat, RNG or bot navigation.
- Added locator regression checks and a staged visual capture; separate Memory test package preserves prior installs.

### 0.4.1 verified delivery

- Local/CI passed 165 checks, scene smoke, ten normal bot runs/180-second replay, six pickup comparisons and six synthetic stress scenarios.
- All non-timing gameplay fields in the ten bot and six pickup cases exactly matched canonical 0.4 reports.
- Signed APK export and downloaded ZIP/APK integrity verified; staged locator render inspected. Reports archived in docs/qa/0.4.1. Human pacing/readability and phone performance remain unverified.

### Continuing QA coverage

- Added reproducible UI lifecycle/window geometry checks and software-rendered captures for eight screens at four window sizes.
- Added six separately labelled seeded sessions across builds/earned kits to recurring CI.
- Local UI suite: 352 checks / 32 layouts / zero failures. Expanded CI passed: 352 UI checks, 32 viewport captures and six extra seeded sessions (five wins/one loss), alongside the existing checks/matrix/comparisons/stress suite. Installed gameplay unchanged.
- Configured daily QA at 03:23 UTC and 14-day artifact retention; archived follow-up reports and preserved bot defeats.

## 0.5.0 — Corruption Protocol

- Added optional run-local Redline, Fracture and Hive links with explicit power/cost previews; selection consumes one level-up and never rerolls ordinary choices.
- Added five-level cadence, one-time links, three-link cap, prerequisites, guarded transactions, HUD meter, reset and non-persistent modifiers.
- Wired cooldown rate, real extra rifle round, regular-enemy pace, extra visible/attacking drone and separate walking multiplier. Striker warning lanes now match travel distance.
- Added dedicated modifier/transaction tests, legal-link normal bot sessions and corruption panels to recurring rendered UI QA. No billing, progression-save schema or commercial-art claims.

### 0.5 verified delivery

- CI passed 206 system/modifier checks, 504 UI checks/44 captures, 20 normal-policy sessions, deterministic replay, six pickup comparisons and six clean stress scenarios.
- Four legal corruption probes won; clean pre-existing case fields exactly match 0.4.1 excluding timing/new telemetry. Preserved all clean-bot defeats.
- Verified signed APK, downloaded integrity/package/module contents and rendered panels/HUD. Archived reports in docs/qa/0.5.
- Added separate local all-links stress fixture 3 and future daily CI step; six local scenarios passed parity/load checks. Recorded ~36.6–38.4ms p95 CPU at 600 enemies as an optimization concern, not Android FPS.

### Android validation pipeline

- Added explicit input/movement regressions, strict isolated headless orchestration and TEST_RESULTS.md.
- Added Android 35 x86_64 Compatibility emulator export, opt-in read-only telemetry and real ADB touchscreen/gameplay/lifecycle checks with diagnostic artifacts.
- Added concurrency cancellation for superseded branch/PR runs. Changes prepared on a development branch for review; Android runtime results pending.

### Android runtime verification completed

- Added real emulator touch, gameplay, rendered-frame readiness, background/relaunch and settings persistence checks; pinned SWANGLE tooling and diagnostic artifacts.
- Fixed the procedural WAV loop boundary and unsafe UI panel detachment during clicks; added six audio and eight GUI-input regressions.
- All development CI gates passed, including 12 Android runtime checks; TEST_RESULTS.md records resolved failures and untested hardware scope. Prepared on development/android-validation in PR #1.

### Mobile onboarding follow-up

- Show touch movement/dash instructions on mobile during the opening 22 seconds.
- Record owner confirmation that the development APK installs and runs.

### Target selection and rapid teardown

- Select nearest enemies directly from spatial cells; share exclusion-aware targeting with chain attacks, preserving ordering and combat outcomes.
- Add seeded targeting parity and boundary regressions and preserve before/after stress evidence.
- Cancel pending music startup when a scene shuts down immediately, fixing the intermittent probe-test WAV playback leak; add startup/cancellation audio regressions.

### Combat feedback pass

- Shared four-point impact silhouettes replace box-shaped hit sparks; shorter impacts and eased rings improve visual separation.
- Enemy visual squash/recovery now settles smoothly and pooled enemies reset their visual pose. Collision, health, movement and attack timing are unchanged.
- Elongated tumbling wreckage remains inside existing quality/pool limits. Upgrade rings rise briefly after selection.
- Upgrade confirmations name the selected weapon/passive and rank; mutation announcements retain priority. Added staged feedback.png to CI presentation captures.
- Added feedback/accessibility/pooling/announcement regressions. Procedural visuals remain development assets.

### Stable preview signing configuration

- Add manual environment-secret preview build with pinned keystore/APK certificate checks, increasing versions and temporary credential cleanup.
- New Preview package coexists with prior installs; seven real-keytool/configuration regressions pass.
- Distribution is blocked until owner environment secrets are provisioned and workflow is registered on the default branch. No stable-signed APK or upgrade test is claimed.

### APK upgrade acceptance test

- Build a second higher-version emulator APK with the same test signer; install it using adb install -r and check saved settings/salvage after relaunch.
- Keep the second APK outside uploaded artifacts; no real signing credentials or phone installation changes.

### Portable progress backups

- Added command-menu code export/paste, restore preview/confirmation and previous-save recovery.
- Added bounded checksummed versioned progression transfer, shared save validation, ledger removal and rollback on write failure.
- Added backup persistence/invalid-input checks, real GUI dispatch tests and 52 UI layouts. Android smoke covers real clipboard round-trip, confirmed restore and subsequent APK update.
- This cannot access older installed apps without export support; no signing-key or billing changes.
