# Development status — NULL//SWARM / 2026-10-29

## Current checkpoint

- Completed industrial deck presentation: original chamfered panels/hatches with quieter seams and one service hatch per four panels after rendered iteration. Two cached meshes/one lit material retain two batches and all 400 positions (300 plain/100 service); bounded static floor rises from 4,800 to 15,200 triangles. No combat/collision/normal-camera/rule changes. Verified source 42b53896a8a498d327bb8ece0fa1f8ff6809a118 passed native 40919707413, Android 40919707720 (33 checks), and QA 40919707425. Local/native/QA strict summaries match (896 systems/57 resources/2,244 headless UI checks); rendered suite passes 2,245 checks/160 layouts including 400 uploaded transforms. All 26 normal sessions, 24 stress/nine kernel cases and prior non-timing gameplay/XP/pacing results/fingerprints pass. Actual Android and revised native art inspected. Method: docs/INDUSTRIAL_DECK.md. Latest report checkpoint is docs/evidence only.
- Current verified APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40919707413/artifacts/12916754698. Extract android/null-swarm-development-debug.apk. CI signature and independent download/package/ARM64/QA-exclusion checks passed; evidence: docs/qa/industrial-deck/verified-ci.json. Presentation captures: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40919707413/artifacts/12917966853. Android retained exact positive earned salvage through recovery/update; logs clean. Software-emulator median 4 FPS remains below targets. Phone performance, final art/human play and stable signing remain open; preserve installs/saves. Main unmerged.

- Completed shared read-only empty buckets for spatial queries, preserving independent snapshots and unchanged CombatWorld/rules/budgets. Nested-area/piercing/ownership regressions pass. Removed the slower/mixed result-buffer experiment. Verified source cfceb77d9af881ea4fcfd493a7c1925078031d81 passed native 40896657173, Android 40896657299 (33 checks) and QA 40896657801. Ten-suite local/native/QA summaries match (878 systems/56 resources/2,244 UI checks); 26 normal sessions, 160 rendered layouts, 24 stress/nine kernel cases and six profiled scenarios passed. All prior non-timing gameplay/XP/pacing results and stress fingerprints match. Whole-combat paired timings remain mixed; no FPS improvement claim. Final report checkpoint is docs/evidence only. Method: docs/PROJECTILE_QUERIES.md.
- Previous query-cleanup APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40896657173/artifacts/12907901415. Extract android/null-swarm-development-debug.apk. CI signature and independent download/package/ARM64/QA-exclusion checks passed. Evidence: docs/qa/projectile-queries/verified-ci.json. Android retained exact positive earned progress through recovery/update; logs clean. Software-emulator median 4 FPS remains below targets; phone performance and signing remain open. Main unmerged; preserve saves.

- Implemented opt-in seven-phase CPU profiling, independent ordered-query reference and serial paired benchmarks. Narrowed nearest-bucket changes and cached exact collision radii with live invalidation. All ten local suites pass (870 systems/55 resources/2,244 UI checks); six kernel cases and all paired fingerprints match. Heavy-fixture mean timings improved locally, but smaller cases were mixed; no uniform/phone FPS claim. Verified code 738a047978ce53b61a6d64f8bfbfe89862f6bf98 passed native 40880997525, Android 40880997456 (33 checks) and QA 40880997533. All 26 normal sessions, 160 rendered layouts, 24 stress cases, six kernel cases and six profiled scenarios passed. Prior gameplay/XP/pacing results and stress fingerprints remain unchanged. Latest report checkpoint changes docs/evidence only. Method: docs/COMBAT_PROFILING.md. No gameplay budgets/rules changed.
- Previous profiling APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40880997525/artifacts/12899947548. Extract android/null-swarm-development-debug.apk. CI signature and independent download/package/ARM64/QA-exclusion checks passed; evidence: docs/qa/grid-query/verified-ci.json. Android retained exact earned salvage through recovery/update, and both game logs were clean. Software-emulator median remains 4 FPS, below targets; phone FPS and persistent signing remain open. Main unmerged; preserve existing installations/saves.


- Completed clearer kill-chain/Overclock feedback: fixed pass-through row, kill progress/deadline, independent bonus duration and immediate new-run reset. Existing values/arithmetic are preserved as shared constants. Code baffa5db1aaaaf0ce11399e81a337a2d536b020e passed native 40869504087, Android 40869503951 (33 checks) and full QA 40869503856. Rules: docs/OVERCLOCK.md.
- Local/native/QA ten-suite summaries match: 455 systems, 2,244 UI checks/160 layouts plus existing Engineer/GUI/audio/probe/resource/input/corruption/smoke coverage. Full QA passed 26 normal sessions (22 victories/four valid defeats), four pacing probes, six XP comparisons, replay and 24 stress cases. All 32 prior gameplay/XP and four pacing cases match excluding timings, plus all 24 stress fingerprints. Actual Android first-kill gauge and staged native reward captures were inspected.
- Previous Overclock APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40869504087/artifacts/12895441388. Extract android/null-swarm-development-debug.apk. CI signature and independent download hash/CRC/package/ARM64/QA-exclusion checks passed. Evidence: docs/qa/overclock/verified-ci.json. Final report checkpoint is documentation only; main remains unmerged. Quiet software-emulator median remains 4 FPS, below targets; phone performance and persistent signing remain open. Preserve existing installations/saves.

- Completed fourth starting kit ENGINEER, unlocked by an Architect defeat: 80 HP/weak rifle + Drone Hive, with one reusable three-second sentry at accepted-dash takeoff. Foundry grid, passive HUD/build description, generated deployment cue and pause/quality/reset integration are implemented. No other kit's combat stats or rules changed. Mechanics: docs/ENGINEER.md.
- Verified code e7c3775e7424b7a466faad7204792ff7ed45bb4e passed native 40859434307, Android 40859434184 (32 checks) and full QA 40859434176. Local/native/QA ten-suite summaries match: 27 Engineer checks, 2,008 UI checks/140 layouts plus GUI/audio/probe/resource/input/system/corruption/smoke. Full QA: 26 normal sessions (22 victories/four valid defeats), four pacing probes, six XP comparisons, replay and 24 stress cases. All 28 prior gameplay/XP cases and four pacing cases match excluding timings; 18 old stress fingerprints and six new local/hosted Engineer fingerprints match. The two earned Engineer runs won with 94/143 sentry shots.
- Previous Engineer APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40859434307/artifacts/12890692747. Extract android/null-swarm-development-debug.apk. CI signature and independent downloaded hashes/CRCs/package/ARM64/QA-exclusion checks passed. Staged native Foundry/sentry/build and actual Android combat captures were inspected. Evidence: docs/qa/engineer/verified-ci.json. Final documentation checkpoint changes no game/test code; main remains unmerged.
- Android first retained actual earned salvage/settings through relaunch/restore/update, then restored a labelled Architect fixture through GUI for real Engineer selection/dash/firing/pause/persistence tests. It does not prove earning the unlock on-device. Separate emulator APK/evidence artifacts stay downloadable. Quiet standard software-emulator median was 4 FPS, below targets; phone ARM64 Mobile performance, Android 10, cutouts, thermals and human fun remain unverified. Preserve existing installations/saves; diagnostic signing rotates.

- Completed Pause → Build // Mutations: actual weapon slots/ranks, evolved names and all three mutation paths, including insufficient-slot warnings. Code d2320dfc3d697275ebc6362e53a3e8545a4dacf8 passed native 40795851224, Android 40795851425 (25 checks) and full QA 40795851350. All nine local/native/QA strict summaries match: 447 systems, 36 GUI, eight probe, 1,708 UI checks/120 layouts plus input/audio/resource/corruption/smoke. Mechanics: docs/BUILD_GUIDE.md. No combat or progression rule changes.
- Full QA retained 22 normal sessions (18 wins/four valid defeats), four successful pacing probes, six XP comparisons, deterministic replay and 18 stress cases. Downloaded reports preserve all 28 established gameplay/XP cases and four pacing cases excluding timings, plus all 18 stress fingerprints. Actual Android initial-build and native staged full-build captures were inspected. Evidence: docs/qa/build-guide/verified-ci.json. Final report checkpoint changes documentation only.
- Previous build-guide APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40795851224/artifacts/12863458226. Extract android/null-swarm-development-debug.apk. CI signature verification and independent downloaded hashes/CRCs/package/ARM64/probe-disabled checks passed. Android earned one salvage at 37 kills/30.53 simulated seconds; exact positive currency/settings survived relaunch, clipboard restore and same-signer update. Keep existing installations/saves; diagnostic signing rotates. Main remains unmerged.
- Current quiet software-emulator observation: median 4 FPS (4–5), about 0.416 simulation seconds/wall second. Below performance targets; unseeded SWANGLE results establish neither physical-phone FPS nor a comparative regression. Physical ARM64 Mobile performance, Android 10, cutouts, thermals and human fun remain open acceptance items.

- Completed saved Performance stats under menu/pause Settings, synchronized F3/checkbox state, default-off legacy compatibility and 4Hz diagnostic sampling. All nine local/hosted strict suites passed: 438 systems, 30 GUI, six probe, 1,188 UI checks/104 layouts, 21 input, nine audio, 50 resources, 41 corruption and scene smoke. Usage/measurement scope: docs/PERFORMANCE_STATS.md.
- Verified follow-up code 000dd701a5ffc4dd7d6b365e23d677a302d42ab3 passed native 40783288386 and Android 40783288421 (22 checks). Android touch, combat/XP/upgrades, lifecycle, clipboard recovery and version 7→8 same-signer update retained exact positive earned salvage/settings. Downloaded APK/archive hashes, CRCs and package/ARM64/probe-disabled checks passed; CI apksigner passed. Actual Android HUD capture inspected. Evidence: docs/qa/performance-stats/verified-ci.json.
- Full QA 40783288378 also passed: 22 normal sessions (18 wins/four valid defeats), four pacing probes, six XP comparisons, deterministic replay, 104 rendered layouts and 18 stress cases. Downloaded full reports match all 28 established gameplay/XP and four pacing cases excluding timings, and all 18 stress fingerprints. Final documentation checkpoint changes no game/test code.
- Emulator observation: cached fixed display dimensions remove redundant input-targeting screenshots. Quiet five-second fresh-deployment sample measured median 5 FPS (3–5), about 0.564 simulated seconds per wall second. This software-rendered unseeded workload differs from the earlier capture-heavy 2–3 FPS smoke; no causal speedup claim. It is below performance targets and does not validate phone FPS. No gameplay/entity/difficulty budgets changed.
- Previous performance-stats APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40783288386/artifacts/12857714529. Extract android/null-swarm-development-debug.apk. Diagnostic signing still rotates; preserve existing phone installations/saves. Main remains unmerged.
- Completed queued-upgrade clarity: the heading shows actual pending choices, including the active one, with three/two/one progression. Rerolls preserve the queue; ordinary choices/accepted links consume one. Actual GUI regressions and 100-layout UI coverage passed.
- Previous queue acceptance at 0f592f7ea0d0fad3d5a0f112820407119ebd0879: native 40767153218, Android 40767153246 (18 checks), and full QA 40767153234 all passed. Nine strict suites included 24 GUI and 1,140 UI checks; gameplay/pacing/XP/replay plus 18 synthetic stress cases passed. Exact limits/results: docs/qa/upgrade-queue/verified-ci.json.
- Previous queue APK and restored-workspace evidence: docs/qa/upgrade-queue/restored-executor-verification.json. Its full report comparisons preserved 28 established non-timing cases, four pacing traces and 18 stress fingerprints.
- Playable ten-minute offline run: six base weapons, four slots, three mutations including Singularity Lance, Warden/Architect encounters, adaptive formations and optional corruption links. Foundry research and four starting kits, including the new Engineer, are integrated.
- Android touch/controller/keyboard controls, ranked upgrades, defensive feedback, portable progress backups and reliable local progression are implemented. Art/audio remain original development assets.
- Added numeric memory/next-level readout and opening collection guidance. A four-session, five-second XP trace compares the two unchanged navigation policies in recurring QA. It identifies collection stalls without modifying XP or difficulty.
- Fixed invalid runner context in the manual Preview workflow. Native CI now checks all workflow contexts with hash-pinned actionlint 1.7.12 before installing build dependencies; signing secrets remain unprovisioned.
- Android persistence acceptance requires ordinary touch play to bank positive salvage before relaunch, restore and update; all three require exact retained currency. Earlier 17-check reports sometimes retained an empty wallet. The current 22-check gate retains this requirement and adds performance-preference coverage.
- Earlier collection-guidance verification passed nine strict suites, including 430 system checks and 924 UI checks across 88 layouts. Trace outcomes/limits: docs/UPGRADE_PACING.md. Current revision evidence is listed above and in PR #1; main is not merged.
- Earlier acceptance at 15f5ad383dcff35fec8eb0ee2c4dea2a8b14ebe0 passed all three hosted gates: native 40683779940, Android 40683779926 (18 checks), QA 40683779992. Android earned 1 salvage from 35 kills and retained it exactly through relaunch/restore/update. Full QA: 22 normal sessions (18 victories/4 defeats), four pacing probes, six XP comparisons, 18 stress cases and 88 UI layouts. All 28 established gameplay/XP cases and 18 stress fingerprints match the prior baseline apart from timings. Durable evidence: docs/qa/upgrade-pacing/verified-ci.json.
- Earlier APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779940/artifacts/12813872710. Extract android/null-swarm-development-debug.apk. Signature verification and independently downloaded ZIP/APK hashes/CRCs passed. Package com.nullswarm.game.development is diagnostic. This final report checkpoint changes documentation only; verification applies to the cited game/test code.

## Active priorities and blockers

1. Continue player-facing combat readability and build polish with bounded effects and reduced-intensity settings. The targeted CPU investigation is recorded; further performance decisions need representative hardware and stronger measurements. Preserve the cautious-bot/pacing baseline before global balance changes.
2. Measure actual ARM64 Mobile rendering, active gravity-field performance, touch comfort, cutouts and phone thermals. Local SDK/emulator/KVM and a connected physical phone are unavailable; CI supplies x86_64 Compatibility runtime coverage.
3. Provision persistent Preview signing through the documented protected owner secrets. Current diagnostic keys rotate, so in-place updates across builds are not guaranteed. Preserve existing phone installations/saves. No owner key was provisioned; no release AAB is claimed.
4. Continue commercial content, character differentiation, accessibility and human balance work after verified milestones. Final artwork/audio and Google Play preparation remain unfinished.

TEST_RESULTS.md records local checks and retained hosted evidence; PR #1 links the newest workflow artifacts. The following sections preserve earlier milestone history and their then-current counts/packages.

## Historical milestone notes

## Completed features

- Ten-minute offline run, six weapons/four slots, ranked upgrades, two mutations, Warden/Architect, gated extraction/results, touch/controller/keyboard input.
- Foundry research, three starting kits, checkpointed salvage and versioned local save/backup recovery.
- Local XP packet merging with 3m relocation limit, visible value tiers and steady player-relative memory locator.
- Adaptive Swarm: first analysis 02:00, eight-second warnings, 45-second formations, capped 20% composition bias, boss quiet windows and reset. Amber Insulators resist electricity by 20%.
- Corruption: optional level-up alternative from level 5; exact ordinary-card/RNG preservation on decline, consumes one pending upgrade on acceptance, five-level spacing, three one-time links, all costs reset per deployment.
- Redline: +30% all weapon cycle rate / -20 max HP. Fracture: extra Pulse/Arcstorm round / +15% regular walking/charge pace. Hive: extra actual drone / -12% walking, requires Drone Hive. Dash/boss/warning clocks unchanged; charge lanes reflect travel distance.
- Projected power/cost panels, prerequisite/duplicate guards, purple HUD meter/names, bounded modifiers and clean-run reset.
- Pooled combat, staggered AI, quality settings, performance overlay and original procedural art/audio; development assets remain unfinished commercial art.

## Tests and latest build

- Gameplay commit 4ee60487877978c58a5f8dc48d670a5eb399a89e.
- Android workflow 40504064445 and QA workflow 40504064446 succeeded. 165 established + 41 corruption checks (206 total), scene smoke, signed export, 504 UI checks/44 captures, 20 normal-policy sessions, deterministic replay, six pickup comparisons and six clean stress scenarios passed invariants.
- Clean case fields match 0.4.1 excluding timings/new corruption telemetry. Four legal-link probes won; combined 20-case matrix retains 16 wins/4 losses. Not a human balance verdict.
- New local all-links stress fixture 3: six scenarios passed, four-drone/three-link/250-pickup floor and low/high gameplay parity asserted. Added command to daily QA; its first CI execution is pending.
- APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40504064445/artifacts/12734700412
- Extract android/null-swarm-corruption-0.5-debug.apk. CI signature verification and independently downloaded hashes/archive checks passed; package/runtime/compiled module contents checked. Preview/entry/HUD/small-window renders inspected.
- App NULL SWARM Corruption / com.nullswarm.game.corruption, version 0.5.0/code 7. Earlier installs/private saves remain separate while stable protected signing is unconfigured.
- Canonical CI and labelled local reports: docs/qa/0.5/RESULTS.md. Daily QA remains scheduled at 03:23 UTC, 14-day QA artifact retention; GitHub can delay starts.

## Known limitations / unfinished work

- All-links synthetic 600-enemy local p95 CPU time ~36.6–38.4ms, excluding rendering/UI/thermals. This needs investigation; Android 30/60 FPS targets are not verified. Normal corruption bot cases peaked at 36–59 enemies, so they do not cover that extreme.
- Phone readability, real touch/safe areas, process-death handling, performance and human tradeoff balance remain unmeasured for this version.
- Corruption is run-local and not restored after process death, like current run equipment; permanent progression is checkpointed. No save schema or entitlement changes.
- Bot navigation is cautious/geometry-based; collection gaps and close-range build bias persist. Existing Insulators keep inherent resistance after formation expiry.
- Full roster/content, final art/audio, accessibility/balance polish, persistent release signing/AAB and Play release preparation remain unfinished.

## Next priorities

1. Profile/optimize targeting and chain-query CPU work under all-links stress without changing gameplay quantities or outcomes.
2. Inspect collection-rate/distance gaps and validate guidance/corruption readability in real play.
3. Broaden build/seed coverage and character differentiation after performance and balance evidence.

## Android pipeline development branch

- Work isolated on development/android-validation; main preserved pending merge.
- Added strict isolated headless runner, 12 movement/input checks, central TEST_RESULTS.md and an Android 35 emulator workflow with actual ADB touch, screenshots, gameplay and lifecycle checks.
- Emulator-only x86_64 Compatibility export opts into read-only debug telemetry; native ARM64 Mobile export remains separate. All three development CI gates passed at 9fcd304bc232c6014ab9533bb45960bb70a992d0.

## Android validation verified

- PR #1 / development/android-validation: strict nine-suite headless checks, 49 resources, 504 UI checks, 20 normal-policy sessions, replay, pickup comparisons, 12 stress scenarios and signed ARM64 debug export passed.
- Real Android emulator passed 12 touch/render/lifecycle/persistence checks. Inspected actual rendered menus/combat/upgrades/settings; logs contain no game errors or crashes.
- Fixed unsafe music loop endpoint and synchronous UI panel detachment discovered through Android testing. Added audio multi-loop and GUI-dispatch regressions.
- Native development package installs separately; read-only telemetry is off in it. Full results, failures/fixes and hardware limits: TEST_RESULTS.md.
- Main remains untouched pending merge. Physical ARM64/Mobile performance and stable signing remain open acceptance items.

## Owner installation confirmation

- Owner reports the development APK works. Installation/run is confirmed by owner feedback; quantitative device performance remains unmeasured.
- Mobile opening HUD now explains dragging the left side and tapping Dash. Desktop keyboard/controller instructions remain available.

## Targeting and teardown follow-up

- Removed nearest-target candidate arrays and shared exclusion-aware cell scanning with chains. Added 205 targeting parity/boundary checks.
- Six all-links stress scenarios retain exact gameplay fingerprints; local timings are mixed, so heavy-combat performance remains an open priority. Evidence under docs/qa/targeting.
- Fixed immediate startup/shutdown audio playback leak reproduced by strict CI; 40 repeated isolated probes passed after cancellable first-tick music startup.

## Combat feedback pass

- Implemented shared impact star mesh, smooth visual hit recoil, elongated wreckage, eased expanding rings and rising upgrade feedback.
- Applied upgrades receive named confirmation; mutation announcements override ordinary confirmations.
- Existing 40/85/150 effect limits and 160-mesh pool are unchanged. Reduced flashes suppress impact stars, debris and hit recoil; ordinary rings remain visible.
- Added staged feedback screenshot and automated cosmetic-only/pool/accessibility/notice coverage. Current branch verification is linked in PR #1.

## Stable preview signing

- Prepared secret-only manual Preview build, separate install identity, certificate pinning before/after export, increasing versions and cleanup.
- Seven local signing regressions passed using disposable test credentials. Existing installs/private saves remain separate.
- Blocker: connected GitHub tools cannot write environment secrets; CLI permission attempt did not complete. No real persistent key was provisioned. Setup: docs/android/STABLE_PREVIEW_SIGNING.md. Stable APK and actual update/save-retention test remain pending.

## APK update acceptance coverage

- Added actual in-place emulator update and changed-settings/salvage retention checks (two additional runtime checks). Python compilation and workflow YAML/shell syntax validated locally; Android execution is through CI.
- Uses one disposable test signer for two successive APK versions in the same run. Persistent cross-run Preview signing still requires owner environment secrets.

## Portable progress backups

- Implemented offline progression/settings codes, checksum/size/schema validation, main-menu-only preview/confirmation and one-level pre-import recovery. No current-run equipment or ledger transfer.
- Added 12 backup system checks, four GUI-dispatch checks and eight UI layouts (52 total / 584 checks). Android driver adds clipboard and restore checks before its update test.
- Documentation: docs/android/PROGRESS_BACKUPS.md. Older installed APKs without this feature cannot export through it; owner key provisioning remains blocked.

## Boss warning readability

- Implemented moving-source radial warning lanes, fixed-target area circles and explicit HUD attack/recharge/exposed cues. Removed rapid vertical warning oscillation; danger radii stay fixed.
- Local nine-suite validation passed: 405 system checks and 656 UI checks across 64 layouts, plus established GUI/input/audio/save/corruption/smoke coverage. Snapshot: docs/qa/boss-readability/headless-results.json.
- Added staged barrage/impact/exposed captures. CI/build verification is linked in PR #1; physical-device readability and frame time still require testing. No attack-stat or pattern scheduling changes.

## Dash and defensive feedback

- Operative silhouette stays visible throughout invulnerability. Shield and hull feedback use one shared-material ring per operative; dash trails use existing bounded pooled beam geometry.
- Dash readiness gauge stays non-blocking; shield HUD shows online, waiting and recharging states. Shield-only hits have a distinct generated SFX.
- Local checks cover dash timing/protection, actual shield/hull metadata, feedback expiration/accessibility, trail reclamation and gauge/status values. Expanded UI capture matrix: 72 layouts.
- Android test now verifies visible operative and actual readiness after touch dash. Device results and comparative QA are linked in PR #1 after execution; physical phone frame rate/comfort remain unmeasured.

## Singularity Lance / build diversity

- Implemented Rail 3 + Tether 3 mutation with one 4.5m/1.5s field, delayed 0.3s pulses, 3m/s small-enemy pull, anchored bosses/committed lanes and preserved refresh cadence.
- Upgrades, HUD, damage accounting, warning-preserving movement, synthesized firing cue, Swarm style tracking and fresh-run reset integrated. Only changed spatial cells are reindexed.
- Added Singularity profile to normal bot coverage (22 combined sessions total), new fixture 4 stress and three evolution UI states at four sizes (84 layouts total). Local two-seed mutation and six synthetic workload reports are in docs/qa/singularity.
- Mechanics/limits: docs/SINGULARITY_LANCE.md. Physical-device active-field rendering/performance and human tradeoff balance still need testing; persistent signing remains blocked on owner environment secrets.
