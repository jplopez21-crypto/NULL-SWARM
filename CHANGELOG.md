# Changelog

## Development — 2026-10-31 / Offline performance report

- Added bounded active-combat performance observations, read-only Settings report, honest empty/warm-up states and clipboard export with readback verification. New deployment clears history; pause/menu/upgrade frames and progression/account data are excluded.
- Added 168-layout headless coverage, actual GUI/state/ownership/finite-data tests, and a paired seeded replay proving diagnostics preserve the accepted gameplay fingerprint. Android acceptance is configured for 37 checks, including report/copy/paused return. Full hosted/rendered acceptance and APK are pending until recorded in TEST_RESULTS.md.

## Development — 2026-10-30 / Memory collection audio

- Added original quiet collection chime on a dedicated SFX voice, with aggregate-per-tick feedback, common rate limit, bounded batch pitch and level-up priority. Existing combat voices, XP rules and volume controls are retained.
- Added PCM/routing/playback/lifecycle and real-physics collection integration tests, a human-review WAV export and read-only Android acceptance counter. Verified source a64caa8f3df88f8ed4e7da1b2698102617022cea passed native APK/signature, all 34 Android checks and full gameplay/rendered QA. All prior non-timing gameplay/XP/pacing results and 24 stress fingerprints match; local/native/QA summaries and raw PCM receipts agree. Exact artifacts and hardware/listening/signing limits: TEST_RESULTS.md.

## Development — 2026-10-29 / Memory crystals

- Replaced round experience packets with original faceted blue/mint/gold crystals; retained XP tiers, exact colors/scaling and all collection/merge rules. Three cached single-surface meshes use 8/12/16 triangles versus 80 previously; draw-instance count is unchanged and no FPS gain is claimed.
- Updated opening collection guidance and added paused normal/close desktop captures plus geometry, tier, round-reference, conservation and recycling tests. Verified source f9f582967b53cfe9789eb02fa832f01e6a554903 passed native APK/signature, all 33 Android checks and full gameplay/rendered QA. Local/native/QA strict summaries match; all prior non-timing gameplay/XP/pacing results and 24 stress fingerprints match. Exact artifacts/limits: TEST_RESULTS.md.
- Reviewed Android emulator 37.2.13.0/build 16740729 after the strict version gate caught SDK drift; retained image revision 9 and the enforced version guard, and exposed the observed version in logs. No game code changes in this CI follow-up.

## Development — 2026-10-29 / Enemy chassis

- Added six original faceted regular-enemy hulls with clearer role shapes, shared cached meshes/materials and retained eye/warning cues. Bosses use their existing visual path.
- Added geometry/cache/tint/role/pooling/accessibility regressions and an enlarged desktop-only review lineup. All ten local suites pass (954 systems/58 resources); equal six-type body instances/triangles decrease structurally, without an FPS claim.
- Verified source bc54a9468c39b457d8b9623a2e67faad41f82356 passed native export/signature, all 33 Android checks and full QA (26 normal sessions, 160 rendered layouts, 24 stress/nine kernel cases). Prior gameplay/XP/pacing results and stress fingerprints match; local/native/QA strict summaries agree. Inspected native lineup/ordinary combat and actual Android scenes. Exact artifacts/limits: TEST_RESULTS.md. Enemy behavior, collision/damage/progression rules and normal camera are unchanged.

## Development — 2026-10-29 / Industrial deck

- Replaced bright checker floor with original chamfered panels, recessed hatches/grilles and restrained service/hazard paint. Two cached meshes share one lit material in the original two batches/400 placements.
- Added bounded geometry/cache/material and rendered placement validation, plus desktop-only close capture. Split full native presentation captures from the install artifact, retaining its android/ path.
- All ten local suites passed (896 systems/57 resources/2,244 headless UI checks); Revised source 42b53896a8a498d327bb8ece0fa1f8ff6809a118 passed native export/signature, all 33 Android checks and full QA (26 normal sessions, 160 layouts, 24 stress/nine kernel cases). Rendered suite validates all 400 uploaded panel positions. Prior gameplay/XP/pacing results and stress fingerprints match; local/native/QA strict summaries agree. Native/Android visuals inspected after reducing pattern density. Exact artifacts/limits: TEST_RESULTS.md. Floor triangle count intentionally increases within a 64-triangle per-panel ceiling; no FPS improvement claim. Gameplay and ordinary camera remain unchanged.

## Development — 2026-10-29 / Projectile query allocations

- Reuse a read-only empty fallback during spatial-cell lookup while preserving separate result snapshots for every attack. Only the shared fallback change is retained in production.
- Added nested-area/piercing/next-shot and snapshot-ownership regressions. All ten local suites passed (878 systems/56 resources); kernels now include the immediately prior verified reference and nine ordered-parity cases. Verified source cfceb77d9af881ea4fcfd493a7c1925078031d81 passed native export/signature, all 33 Android checks and full QA (26 normal sessions, 160 layouts, 24 stress/nine kernel cases). Prior gameplay/XP/pacing results and stress fingerprints match; ten-suite local/native/QA summaries agree. Whole-combat timing remains mixed, without a general FPS gain claim. No gameplay rules, CombatWorld code or budgets changed.

## Development — 2026-10-29 / Combat profiling and grid queries

- Added opt-in seven-phase combat timing and a paired legacy/current query harness with ordered-result checks. Default gameplay does not collect timings; measured combat phases exclude rendering and surrounding fixture work.
- Avoided absent nearest-target bucket arrays and repeated radius calculations; collision caches refresh on live definition edits. Exact ordered-query/hit behavior and all paired combat fingerprints are preserved.
- All ten local suites and paired benchmarks passed. Heavy local fixture means improved while smaller cases were mixed; no uniform or phone FPS claim. Method/raw results: docs/COMBAT_PROFILING.md. Verified source 738a047978ce53b61a6d64f8bfbfe89862f6bf98 passed native export/signature, 33 Android checks and full QA (26 normal sessions, 160 layouts, 24 stress/six kernel cases). All prior non-timing gameplay/pacing/XP results and stress fingerprints match; ten-suite local/native/QA summaries agree. Exact artifacts and limits are in TEST_RESULTS.md.

## Development — 2026-10-29 / Kill-chain and Overclock feedback

- Added a compact fixed-row gauge with remaining kills/chain deadline and independent Overclock duration. Text outlines and touch pass-through preserve readability/control; no new flashes or particles.
- Shared existing combat constants and refreshed new-run HUD immediately. Damage, spawn/XP/RNG rules and 20-kill / 3s-gap / 6s-bonus / +60% cycle timing stay unchanged.
- Verified code baffa5db1aaaaf0ce11399e81a337a2d536b020e passed all ten local/hosted suites, signed ARM64 export, 33 Android checks, 160 rendered layouts, 26 normal sessions and 24 stress cases. All prior gameplay/XP/pacing results and stress fingerprints are unchanged. Inspected actual Android and staged native feedback; exact evidence and phone/signing limits are in TEST_RESULTS.md.

## Development — 2026-10-29 / Engineer and Dash Uplink

- Added Architect-earned Engineer: Drone Hive, weak rifle, 80 HP and a real dash-origin sentry passive. One model is refreshed/repositioned rather than stacked; Drone Hive ranks and normal cycle bonuses scale its attacks.
- Added passive lifetime/readiness HUD, build-guide description, original procedural tripod/deployment sound and a two-column Foundry kit layout.
- Added ten-suite local coverage, two normal Engineer sessions, a six-case sustained Engineer load fixture and mobile GUI fixture tests after ordinary persistence validation. Separated emulator APK/evidence artifacts and restricted staged capture mode to desktop debug builds.
- Verified code e7c3775e7424b7a466faad7204792ff7ed45bb4e passed all ten local/hosted suites, signed ARM64 APK export, 32 Android checks, 140 rendered layouts, 26 normal sessions and 24 synthetic stress cases. Downloaded reports preserve prior gameplay/XP/pacing results and stress fingerprints; new Engineer cases/fingerprints match local runs. Actual Android and staged native visuals were inspected. Exact evidence and phone/signing limits are in TEST_RESULTS.md.

## Development — 2026-10-29 / Build and mutation guide

- Added Pause → Build // Mutations with live equipment slots/ranks, evolved titles and all three mutation recipes from the content registry.
- Explained active/in-progress paths and blocked recipes, including the two-missing-weapons/one-free-slot edge case. Existing weapons can still evolve at full slots.
- Kept the guide read-only and combat paused, with touch/controller navigation back to pause. Added GUI/data/probe regressions, 16 more layout fixtures and three Android touch checks.
- Verified code d2320dfc3d697275ebc6362e53a3e8545a4dacf8 passed local/hosted nine-suite checks, ARM64 APK export, 25 Android checks and full gameplay QA (120 rendered layouts/18 stress cases). Prior non-timing gameplay/XP/pacing results and stress fingerprints are unchanged. Native/Android screenshots and downloaded APK/archive integrity verified; exact evidence and phone/signing limits are in TEST_RESULTS.md.

## Development — 2026-10-28 / Touch performance stats

- Reduced emulator smoke overhead by caching fixed display dimensions instead of capturing a PNG for each input coordinate. Added a quiet fresh-deployment observation without input/screencaps; it has no phone-FPS acceptance gate.
- Added a saved default-off Performance stats toggle to menu/pause settings; F3 uses the same preference and ignores held-key repeats.
- Added checkbox/HUD synchronization, optional-setting compatibility for old saves, and portable-backup retention.
- Samples FPS/average frame interval, entities, draw calls and engine memory at 4Hz while enabled. The HUD passes touch through and changes no combat or effect budgets.
- Expanded local coverage to 104 UI layouts and added Android touch/persistence/update acceptance checks. Execution/build evidence is tracked in TEST_RESULTS.md.
- Follow-up native export and all 22 Android checks passed. Quiet software-emulator observation measured median 5 FPS (3–5); this remains below targets and is not phone performance validation. APK identity/integrity and revision-specific evidence are recorded under docs/qa/performance-stats.
- Full QA passed with unchanged gameplay/XP/pacing results and 18 stress fingerprints. All 104 rendered UI layouts passed; local/native/QA strict-suite summaries match. Final report records executed code 000dd701a5ffc4dd7d6b365e23d677a302d42ab3.

## Development — 2026-10-28 / Queued upgrade clarity

- Upgrade headings show how many choices are ready, including the current choice, with correct singular wording for the last one.
- Rerolls keep the count; normal upgrades and accepted corruption links consume one choice. Combat resumes after the queue is empty. Existing progression/combat rules are unchanged.
- Added real GUI-dispatch regressions and expanded staged UI coverage to 100 layouts. Native CI emits a bounded staged preview and structured results for remote verification.
- Verified code 0f592f7ea0d0fad3d5a0f112820407119ebd0879 passed all three hosted gates, including 24 GUI checks, 1,140 UI checks, 18 Android checks and the full gameplay/stress matrix. After executor recovery, all nine local suites and independent APK/archive checks also passed; full QA comparisons preserve 28 established cases, four pacing cases and 18 stress fingerprints. Current evidence is in TEST_RESULTS.md.

## Development — 2026-10-28 / Memory collection clarity

- Added numeric memory/next-level readout and a brief opening collection hint, with touch input passing through the readout.
- Added optional five-second XP traces and four fixed-seed navigation comparisons to recurring QA. Preserved both established bot policies and all combat/progression rules.
- Expanded UI coverage to 88 layouts and added staged onboarding capture. Current local check evidence and pacing limits are documented in TEST_RESULTS.md and docs/UPGRADE_PACING.md.
- Fixed Preview workflow runner-context validation and added hash-pinned actionlint checks for all workflows in native CI.
- Strengthened Android lifecycle/restore/update acceptance to earn and retain exact nonzero salvage through normal gameplay, rather than accepting an empty wallet.
- Verified game/test code 15f5ad383dcff35fec8eb0ee2c4dea2a8b14ebe0 passed native export, 18 Android checks and full QA. Preserved 28 existing non-timing gameplay/XP results and 18 synthetic gameplay fingerprints. Final documentation records the exact build artifacts and verification limits.

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

### Boss warning readability

- Radial barrage markers follow the firing source and show a lane for each existing projectile direction. Area circles remain locked to their selected locations.
- Added explicit barrage/impact/recharge/exposure HUD cues, steady warning-thickness progression and immediate marker hiding on cancellation.
- Preserved attack deadlines, damage, counts, radii, phases and reward rules. Added eleven warning/shot/counterplay regressions and twelve boss UI layout captures.

### Dash and defensive feedback

- Keep the operative visible during dash/hit protection; replace blinking with brief shield-blue/hull-orange damage feedback rings.
- Add pooled narrowing dash trails, an always-interactive cooldown gauge and explicit shield recharge status. Reduced flashes suppress trails and hit rings.
- Add an original generated shield-absorption sound; hull damage retains its existing sound. Preserve damage, shield recharge, dash speed/cooldown/protection and collision rules.
- Add defensive input/effect/HUD regressions and staged shield/hull/dash captures.

### Singularity Lance mutation

- Rail Lance 3 + Memory Tether 3 now unlocks a third evolution: piercing rail impacts leave a single refreshing gravity field with periodic damage and small-enemy pull. Bosses and committed attack lanes remain anchored.
- Centralized mutation requirements/names; added evolved cards/HUD/results/SFX, incremental spatial reindexing and projectile-style adaptation accounting.
- Added new normal-rules bot profile, field-clock/pull/refresh/reset tests, UI captures and synthetic gravity workload fixture 4. Two local mutation runs won; six local stress cases passed invariants. Human balance and device performance remain unverified.
