# Development status — Corruption Protocol 0.5 / 2026-10-27

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
