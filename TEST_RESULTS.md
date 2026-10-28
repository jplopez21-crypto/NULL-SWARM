# NULL//SWARM test results

## Upgrade queue clarity — 2026-10-28

Verified game/test code: `0f592f7ea0d0fad3d5a0f112820407119ebd0879`. The final report checkpoint changes documentation only; subsequent documentation-triggered CI is separate from the executed evidence here.

- [Native build 40767153218](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40767153218): all nine strict suites passed. Counts: 24 GUI, nine audio, five Android probe, 50 resources, 21 input, 430 systems, 41 corruption and 1,140 UI checks, plus scene smoke. Import, workflow lint, rendered capture, ARM64 Mobile debug export and apksigner verification passed.
- Queue tests use a real 100-XP overflow to produce three pending choices. Actual GUI events verify reroll preservation, three/two/one counts, invalid/repeated selection rejection, safe panel retirement, exact corruption consumption/decline, paused combat and final resumption. Staged geometry/render coverage expands to 100 layouts across four window sizes.
- Inspected the actual 1280×720 Godot-rendered queue screen through bounded CI log PNG chunks: the three-upgrade heading fits above the cards, with choices/reroll visible. CI emits its structured headless result and one bounded staged PNG; no player save or signing material is emitted.
- [Android runtime 40767153246](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40767153246): all 18 checks passed, including ordinary touch upgrades and exact positive earned-salvage retention through force-stop/relaunch, clipboard restore and version 7→8 same-signer update. Compound multi-choice queues are headless GUI-input coverage, not a forced Android multi-level fixture.
- [Full QA 40767153234](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40767153234): 22 standard/corruption/extended sessions, four pacing probes, six XP comparisons, deterministic replay, 100 rendered UI layouts and 18 synthetic stress cases passed their checks. All 30 printed gameplay/XP/pacing summary lines match baseline run 40685839146 exactly. This comparison does not cover unprinted JSON fields or cross-run stress fingerprints. Per-run low/high gameplay parity and the existing fixture-load assertions passed in every stress fixture.
- [Debug APK ZIP](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40767153218/artifacts/12850942138); extract `android/null-swarm-development-debug.apk`. Package `com.nullswarm.game.development`. CI/GitHub ZIP SHA256: `31858cb812317000581858d5b23627303998addd027a83e17f5a392305352651`. [Android evidence](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40767153246/artifacts/12851835173) and [full QA reports](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40767153234/artifacts/12851701040). Durable metadata: docs/qa/upgrade-queue/verified-ci.json.
- Could not run locally: the selected executor repeatedly reports “No usable execution environment is available.” Local Godot/shell checks and independent APK-byte download/hash verification were unavailable. Edits/commits used GitHub APIs; all execution above was hosted CI. Physical-phone Mobile rendering/performance, Android 10, cutouts, thermals and human fun remain unverified. Persistent owner signing is still unconfigured; diagnostic CI keys rotate. Preserve existing installations/saves.

## Current local verification — 2026-10-28

### Hosted acceptance completed

Verified game/test code: `15f5ad383dcff35fec8eb0ee2c4dea2a8b14ebe0`. This final report checkpoint only changes documentation; later CI triggered by documentation is separate from the executed evidence below.

- [Native build 40683779940](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779940): actionlint, seven signing-helper regressions, nine strict headless suites, staged renders, ARM64 Mobile export and apksigner verification passed. Downloaded archive/APK hashes and CRCs independently checked; native QA probe setting is disabled. APK SHA256: `cfc2ce702b9032f2b08d6668fa5d5ef7c2affaff562d62e91e71b7b145eaf55f`.
- [Android runtime 40683779926](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779926): all 18 checks passed. Normal gameplay banked 1 salvage after 35 kills / 30.48 simulated seconds. Exact positive balance and changed settings survived force-stop/relaunch, portable restore and same-signer APK update from version 7 to 8. Inspected the updated menu showing 1 salvage. This is x86_64 Android 35 Compatibility coverage, not ARM64 Mobile/phone validation or persistent cross-run signing.
- [Full QA 40683779992](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779992): 22 normal sessions (18 victories, four valid defeats), four successful pacing probes, six XP comparisons, deterministic replay, 924 UI checks/88 layouts and 18 synthetic stress cases passed. All 28 established gameplay/XP cases match the prior baseline excluding only timing fields; all 18 synthetic gameplay fingerprints match. Pacing traces match local results exactly excluding timings. Known collection gaps remain visible; no human-fun claim.
- [Debug APK ZIP](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779940/artifacts/12813872710), [Android evidence](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779926/artifacts/12813104672), [full QA reports](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40683779992/artifacts/12813394678). Extract `android/null-swarm-development-debug.apk`. ZIP/APK verification and concise acceptance metadata: docs/qa/upgrade-pacing/verified-ci.json.

### Local checks and investigation history

- Memory readout/collection guidance: all nine isolated headless suites passed. Counts: 430 systems, 924 UI/88 layouts, 50 resources, 21 input, 12 GUI, 9 audio, 5 Android probe, 41 corruption, plus scene smoke. Strict engine/script/leak scan clean.
- Four normal-rules Singularity collector comparisons are traced at five-second intervals; both established navigation policies and combat rules remain unchanged. Pickup accounting and accumulated level costs are checked in every trace sample. Results/limits: [upgrade pacing](docs/UPGRADE_PACING.md). No claim that a bot victory proves human balance.
- An exploratory third navigation policy was rejected after worse pacing. An initial exploratory dash assertion failed because the scoring preferred walking; that experiment and assertion were removed together. Initial UI fill assertions expected fractional percentages despite ProgressBar's whole-percent step; corrected the assertion to respect half-step rounding, preserving gameplay/UI fill behavior. Only the subsequent clean run counts as passing.
- QA workflow YAML and shell syntax validated. Software-rendered layout/onboarding captures, signed ARM64 export and real Android touch/lifecycle/update checks are hosted CI gates. Their current revision results and artifacts are linked from [PR #1](https://github.com/jplopez21-crypto/NULL-SWARM/pull/1).
- Retained hosted baseline at code `25ff0b895507b1efb97eecc3fc33e45cac2f23cb`: [native export](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40631403113), [17 Android runtime checks](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40631403183), [full gameplay QA](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40631403216). It covered 22 normal-policy sessions and 18 synthetic stress cases; active gravity-field Android/physical-phone performance remains unverified.
- Persistent owner signing remains unconfigured. Debug APKs are diagnostic and may not update an existing installation with a different certificate. No Play Protect bypass, release bundle, connected-phone test or human fun validation is claimed.
- Pipeline follow-up: GitHub rejected the manual Preview definition on push because job-level `env` referenced unavailable `runner.temp`. Moved config-directory setup into a runner step using `RUNNER_TEMP`/`GITHUB_ENV`. Native CI now validates every workflow with actionlint 1.7.12, pinned archive SHA256. Local YAML/shell checks alone had not detected this context error. Local actionlint installation could not run: no Go compiler and shell networking cannot reach the proxy; hosted lint execution is the verification gate. Stable preview signing itself still requires owner secrets and has not run.
- Hosted workflow validation passed on follow-up commit `dc6e1891224662c4f25562fe0a5f0efd15ca96bf` in run 40682388320. Initial onboarding render was inspected; increased text to 15px, made both bar and text ignore input, and corrected the screenshot fixture to keep rendered guidance active while simulation is frozen. Revised captures require hosted review; physical-phone readability remains unverified.
- Revised native export at code `2c7f3ac7cb687ce4286285bf784b210fd536a438` passed in run 40682576269. Independently verified ZIP/APK hashes/CRCs, package/ARM64 contents and disabled native QA probe; inspected the revised readout/locator and real Android combat/upgrade captures. APK SHA256: `e5a21735563d277a6e59a92425d97f8bdfd64040e1158b58275b880e5dadae65`.
- Android run 40682575946 passed its 17 checks, but report review found the wallet was zero during save/restore/update checks. That run verifies settings retention and zero-wallet equality, not retention of earned nonzero currency. Strengthened the driver to continue ordinary touch play until a real checkpoint banks salvage, add an explicit nonzero check, and require exact positive currency through force-stop/relaunch, restore and update. No telemetry write, currency grant or game-stat change was added. The stronger 18-check hosted run is the acceptance gate; current result is linked in PR #1.

The sections below preserve historical results and artifact references with their original revision counts.

## Historical Android pipeline verification

Verified 2026-10-27 on development branch `development/android-validation`; [PR #1](https://github.com/jplopez21-crypto/NULL-SWARM/pull/1). Game/test code verified at `9fcd304bc232c6014ab9533bb45960bb70a992d0`. Main remains unchanged pending merge.

## Passed checks

| Coverage | Result | Evidence |
|---|---|---|
| Normal movement, diagonal speed, touch ownership/release, bounds, dash/cooldown/reset | Passed: 12 checks | `tests/run_input_tests.gd` |
| Combat/damage, enemy spawning/scaling, XP/overflow/merging, upgrades, saves/unlocks, death and victory lifecycle | Passed: 165 checks | `tests/run_tests.gd` |
| Corruption eligibility, costs/modifiers, selection, reset | Passed: 41 checks | `tests/run_corruption_tests.gd` |
| Audio format/loop bounds and 24 seconds of actual offline mixing | Passed: 6 checks | `tests/run_audio_tests.gd` |
| Actual GUI mouse dispatch and safe panel retirement | Passed: 8 checks | `tests/run_gui_input_tests.gd` |
| Read-only Android probe and disabled-by-default export | Passed: 5 checks | `tests/run_probe_tests.gd` |
| Script, scene and resource loading | Passed: 49 resources | `tests/validate_resources.gd` |
| UI geometry/lifecycle and corruption screens | Passed: 504 checks / 44 staged states | Local headless and CI software OpenGL |
| Main scene startup and automatic combat | Passed | `SCENE_SMOKE_OK`, no script errors or leak warnings |
| Nine isolated strict headless suites | Passed | Exit code + positive completion + error/leak scan; `headless-results.json` |
| Normal-rule gameplay sessions | Passed invariants: 20 cases | 16 victories / 4 defeats retained; no injected immunity or forced boss kills |
| Seeded replay | Passed | Two matching 180-second sessions |
| Pickup comparisons | Passed: 6 cases | Conservation/local-merge/collector checks; historical numeric baseline skipped when sources differ |
| Synthetic combat stress | Passed: 6 clean + 6 corrupted cases | Fixed-load and low/high gameplay parity; not a phone FPS threshold |
| ARM64 Mobile debug APK import/export/signature | Passed | [Native build](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40535254881) |
| Android 35 x86_64 Compatibility install/launch/touch/lifecycle | Passed: 12 checks | [Android runtime](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40535254515) |
| Full recurring QA pipeline | Passed | [QA run](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40535254750) |

The emulator used real ADB touch to deploy, move, dash, pause/resume, collect enemy XP, select an offered upgrade and toggle a setting. Background/resume retained pause; a new process after force-stop retained the changed setting and banked progression. Rendered state/panel synchronization plus a coarse blue/teal-frame check rejected boot-splash captures. Menu, combat, upgrade, settings and relaunched-menu screenshots were inspected. The final log scan found no Godot engine/script errors, game ANRs or native/Java fatal crashes.

## Build artifacts

[Download ARM64 Development APK ZIP](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40535254881/artifacts/12747577938). Extract `android/null-swarm-development-debug.apk`. Package: `com.nullswarm.game.development`, display name **NULL SWARM Development**; it installs separately from earlier game builds.

APK SHA256: `a35e5ca7186a937b6ed79a6b97c79453325a73d2b8c5a0f8a3241d9bbe887d45`. Downloaded ZIP/APK hashes and CRCs independently verified, with ARM64/DEX/package checks. Tests/tools are excluded and the native APK has no enabled QA probe setting. CI ran `apksigner verify`.

[Android screenshots/logcat/emulator report](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40535254515/artifacts/12747443519). Durable summaries and raw check results: [docs/qa/android-pipeline](docs/qa/android-pipeline/).

## Failures found and resolved

- Missing runner `libpulse.so.0` blocked emulator startup; added explicit Linux runtime libraries.
- Unbounded ADB cleanup could hang a cancelled pre-boot job; diagnostic commands now have deadlines and duplicate development push runs were removed.
- Fixed a GDScript loader type inference error and a JSON int/float comparison in the new probe test.
- Strict checks caught intermittent shutdown audio references. After draining audio/UI teardown, eight fresh-process smoke repetitions had zero leak warnings (before: one of eight leaked).
- Deprecated SwiftShader-indirect produced real GLES shader-link errors. Source inspection ruled out the attempted project-capacity workaround; it was reverted. Pinned SWANGLE rendering passed without reducing game light/entity budgets.
- Procedural music used a one-past-end loop sample. Corrected the inclusive endpoint and added multi-loop native mixing checks; subsequent Android runs had no AudioTrack crash.
- Immediate panel detachment during button dispatch produced `can_process` errors. A real GUI-input regression reproduced four failures; hidden/deferred panel retirement now passes all eight checks and Android log scanning.
- Telemetry could precede a visible menu, producing boot-splash screenshots. Added rendered-frame/panel synchronization and pinned Pillow image readiness checks; inspected captures now show the game menus.

## Could not run / limits

- No local Android SDK/emulator/KVM; Android runtime testing ran successfully on the KVM-enabled GitHub runner instead.
- Local editor TCP-service binding is restricted by the sandbox. Hosted import and local strict resource/headless checks passed.
- No connected ARM64 phone: primary Mobile/Vulkan renderer runtime, real touch latency, cutouts, thermals and 30/60 FPS targets remain unverified. Emulator results certify the stated x86_64 Compatibility variant only. Android 10/API 29 runtime is not in this initial emulator matrix.
- Death/victory lifecycle tests include controlled fixtures; separate normal-rule bot runs provide completion evidence, not human balance or fun guarantees. Emulator smoke does not force death/victory.
- The palette check is a startup smoke heuristic, not pixel-perfect visual QA. Host audio is muted; guest audio mixing runs, but audible quality was not assessed.
- Debug signing keys are ephemeral; stable protected signing is still required for repeat in-place development updates or release distribution. No signing keys or owner credentials are committed.

## Reproduction and automation

```sh
godot --headless --editor --import --quit
python3 tools/run_headless_checks.py
godot --headless --script tests/run_playtests.gd
godot --headless --script tests/run_playtests.gd -- --corruption-probe
godot --headless --script tests/run_benchmark.gd -- --corruption-stress
```

Godot/templates 4.6.3, Java 21, SDK API 35/build-tools 35.0.1; emulator 37.2.12.0 and Android 35 Google APIs image revision 9 are enforced, with Pillow 11.3.0 in an isolated venv. Resolved versions/logs are uploaded. Main pushes, PR updates and manual dispatch run the gates; daily QA (03:23 UTC) and Saturday emulator QA (03:53 UTC) apply on the default branch after merge. QA/runtime artifacts are retained 14 days. A failed check fails CI, including zero-exit-code script errors and leak diagnostics.

### Repeat-run touch timing regression

The documentation-tip repeat (Android runtime run 40538534378) failed its movement assertion: drag events arrived, but a timed ADB swipe moved only 0.24 units on a slow emulator. Native build and full gameplay QA passed. The driver now sends real DOWN/MOVE/UP events with a held interval, preserving the greater-than-one-unit movement assertion. Verified in Android runtime run [40540308197](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40540308197): all 12 checks passed, including unchanged movement distance and clean logcat assertions. The ARM64 build passed in run 40540308146.

### Owner device confirmation

After installing the final pipeline APK, the owner reported “Works.” This confirms a successful owner install/run, without measured frame rate, session length, device model, or thermal data. Android now shows touch movement/dash onboarding instead of keyboard instructions. All nine isolated headless suites passed locally after this UI change, including resource loading, GUI dispatch, gameplay, input, corruption, UI geometry and scene smoke. The development branch CI also validates the update.

### Targeting and immediate audio teardown follow-up

- Previous onboarding QA run 40547866604 failed strict shutdown validation: probe assertions passed, but verbose reproduction found one WAV/playback leak in 12 attempts. Native export and Android runtime checks passed at that revision.
- Music startup now waits for the first process tick; shutdown cancels pending startup. The same probe passed 40 consecutive verbose isolated runs after this fix, with no leak warning. Dedicated audio checks cover cancelled startup and normal startup.
- Nearest-target selection scans grid cells directly without a candidate array or duplicate distance calculation. Chain attacks reuse the same selector with explicit exclusions. Added 200 seeded comparisons with the previous algorithm and five boundary/tie/exclusion cases.
- Six all-links stress scenarios preserved exact before/after gameplay fingerprints and fixed loads. Reports: docs/qa/targeting/before.json and after.json. Local CPU p95 results are mixed: 600/high 46.024 → 36.405 ms; 600/low 39.019 → 43.176 ms. This is a single shared-host comparison, not a reliable overall speedup or Android FPS measurement. Baseline overlapped short probe repetitions, so timing conclusions are limited.
- Full updated branch build/runtime/QA results are linked in PR #1; all nine updated local suites passed (370 system checks, 9 audio checks, 41 corruption checks, 12 input checks, 8 GUI checks, 5 probe checks, 49 resources, 504 UI checks and scene smoke), with zero strict error/leak failures.

### Combat feedback pass

- Added 10 checks covering visual-only hit recoil, settling and pooled pose reset, reduced-flash suppression, shared impact geometry, rising upgrade rings, pool reclamation, named passive confirmation and mutation announcement priority.
- The first extended test run exposed a typed-array assignment error in the new test fixture, which was corrected using Array.assign; the failed run was not counted as a pass.
- Native presentation CI adds a deliberately staged feedback.png frame; it is visual QA, not a human gameplay capture. The Android probe continues to exercise real touchscreen upgrade selection.
- No combat damage, spawn rate, targeting, health, collision size, dash timing, effect budget or gameplay RNG changes are intended. Android phone performance and human satisfaction require device playtesting.

Local post-fix verification: all nine isolated suites passed, including 380 system checks, 9 audio checks, 41 corruption checks, 12 input checks, 8 GUI checks, 5 probe checks, 49 resource checks, 504 UI checks and scene smoke; strict error/leak scan clean. Snapshot: docs/qa/combat-feedback/headless-results.json. Final CI evidence is linked in PR #1.

First CI render review found hit impacts obscured by enemy bodies and confirmation text crossing silhouettes. Raised impacts above each enemy’s visual scale, enabled two-sided rendering only on cached impact materials, and outlined toast text. Revised staged sample separates silhouettes for inspection. The first native APK passed signature/export and downloaded integrity checks; final-tip results remain authoritative in PR #1.

Post-render correction: updated system suite passed 382 checks with a clean strict log scan; the two additional checks cover two-sided impact rendering and cached material/height reuse. Results: docs/qa/combat-feedback/visibility-regressions.json.

### Persistent preview signing configuration

- Executed `python3 -m unittest discover -s tests -p test_preview_signing.py -v`: 7/7 passed. Real keytool generated a disposable test PKCS12 key, verified its certificate, rejected wrong password/pin, and reused its identity across increasing version codes. APK signer-output rejection is a mocked unit check, not a real signed-APK validation.
- Added those regressions to native build CI. No gameplay source changed in this signing follow-up.
- Not run: real persistent-key export, physical-device in-place upgrade/save retention, and Play Protect completion. No real owner key/secrets are available through the connected tools. The prior network-permission CLI attempt was interrupted; it did not provision credentials.
- Exact owner setup and limitations: docs/android/STABLE_PREVIEW_SIGNING.md. No claim that signing solves a Play Protect scan delay.

### APK update acceptance coverage

- Added optional --upgrade-apk to the Android driver. After real play, touch settings and force-stop checks, installs a newer APK over the existing package and asserts an increased installed version, a new process, and unchanged saved settings/salvage. Captures updated-install.png.
- Emulator CI now exports two versions with one temporary signer and passes the second to the driver. Only the first APK is uploaded; the second stays in /tmp. This tests Android update/save retention, not persistent owner-key provisioning or Play Protect.
- Local verification: Python bytecode compilation, YAML parse and bash syntax check passed. Runtime results are linked in PR #1 once executed; no local emulator/KVM is available.

### Portable progress backup development

- Initial run found a duplicated parameter/local variable in shared save validation; renamed the parameter. A smoke run was also interrupted while cleaning up an older parser-failed process, so that run was not counted as passed. Subsequent clean suites passed.
- Added 12 backup system checks covering round-trip progression/settings, checksum/base64/size/schema rejection, replacement semantics, recovery copy, repeat imports, write failure and ledger stripping. Four GUI checks cover opening, preview, cancel and confirmed restore. UI geometry coverage expands to 584 checks / 52 layouts.
- Android smoke now exports a real code to the clipboard, leaves/reopens the screen, pastes, previews/confirms restore, checks exact settings/salvage and recovery existence, then runs the existing in-place APK update. Probe reports only code length, not its content.
- Final CI results and screenshots are linked in PR #1 after execution. Physical cross-app transfer, old-app export and persistent Preview signing are not claimed.

Local final verification: all nine isolated suites passed with no strict errors/leaks: 394 system, 12 GUI, 9 audio, 5 probe, 49 resources, 12 input, 41 corruption, 584 UI checks and scene smoke. Snapshot: docs/qa/progress-backup/headless-results.json.

### Boss warning readability

- Found radial warning rings were left at the wind-up origin while the moving boss fired from its current position. Updated radial marker positions and added spokes using the same direction calculation as emitted shots. Locked area locations remain unchanged.
- Eleven added checks cover ring/lane count, moving-source positions, cue states, exact firing directions/counts, fixed impact targets, exposure bonus wording and immediate hide on cancellation.
- Local clean run: all nine isolated suites pass, including 405 system and 656 UI checks / 64 layouts. Other suites: 12 GUI, 9 audio, 5 probe, 49 resources, 12 input, 41 corruption and scene smoke. No strict engine/script errors or leak warnings.
- Native captures add boss_barrage.png, boss_impact.png and boss_exposed.png. These are deliberately staged presentation QA. Final CI comparisons/runtime evidence are linked in PR #1 after execution. No claim of physical-phone boss validation.

Boss render review: first native export passed signature/integrity checks, but orange boss text needed stronger contrast against the model. Added dark outlines to both boss labels. Staged warning captures now clear transient damage text/toasts only; normal gameplay feedback remains intact. Updated UI geometry/resource verification is run before publishing the refinement.

### Dash and defensive feedback

- Found the player body blinked invisible during every invulnerability window, including dash. It now remains visible; optional short hit rings and bounded dash trails convey feedback instead. Reduced flashes suppress both.
- Preserve 27m/s dash, 0.18s dash duration, 2.5s cooldown and 0.24s protection. Constants only replace existing literals. Accepted damage records actual absorbed/hull loss as transient feedback metadata without changing shield/HP arithmetic.
- Added nine input checks, four pooled-effect checks and six HUD checks per viewport. Android probe reports body visibility/readiness and the driver asserts them after real dash input. Native captures add shield_feedback.png, hull_feedback.png and dash_feedback.png, explicitly staged for visual QA.
- Full current local suite snapshot is stored under docs/qa/defensive-feedback; final CI/runtime/comparison evidence is linked in PR #1 after execution. Human comfort, audible shield cue quality and physical ARM64 FPS remain unverified.

Final local defensive-feedback verification: all nine isolated suites passed (409 system, 21 input, 720 UI checks/72 layouts, 12 GUI, 9 audio, 5 probe, 49 resources, 41 corruption and scene smoke). Strict script/engine/leak scan clean. Python Android-driver compilation also passed.

Defensive render review: first native APK passed signing/hash/archive checks. The staged dash image showed incomplete HUD text during rapid fixture changes; added explicit post-draw waits to defensive screenshots and cleared the introductory toast only in capture fixtures. Normal gameplay timing is unchanged. Revised captures must be inspected in the final artifact.

### Singularity Lance mutation

- New Rail 3 + Tether 3 evolution integrates delayed gravity pulses, bounded pull and one-field refresh into actual rail firing. Mutation requirements/names are registered centrally. Base upgrade IDs/RNG offers are unchanged.
- First field test found a floating-point remainder at expiration; corrected expiry tolerance. Added a refresh-cadence regression so frequent rail shots cannot indefinitely postpone field pulses. Tests also cover actual shot activation, prerequisites/duplicates, anchored bosses/windups/charges, incremental grid membership/order, invalid values, expiration, pause, quality and run reset.
- Executed normal-rules Singularity probe seeds 101/202: both won, reached the mutation and exercised over 1,300 pulses each. No injected immunity or forced boss kills in those sessions. Reports: docs/qa/singularity/singularity-probe.json.
- Executed six synthetic gravity stress cases: load/parity invariants passed, actual field activations and pulses asserted. Fixture 4 explicitly sustains invulnerable high-HP enemies, projectiles/pickups and corruption links. CPU values are headless workload measurements, not Android FPS or an old-fixture speedup. Report: docs/qa/singularity/gravity-stress-report.json.
- Standard CI adds this bot profile and gravity stress; native snapshots add singularity_offer.png, singularity_field.png and singularity_upgrade.png. Final branch CI/render evidence is linked in PR #1 after execution. Physical active-field Android rendering and human balance are not claimed.

Final local Singularity verification: all nine isolated suites passed, with 430 system checks, 872 UI checks/84 layouts, 50 resource checks, 21 input, 12 GUI, 9 audio, 5 probe, 41 corruption and scene smoke. Strict errors/leak scan clean. QA workflow YAML and shell syntax validated.

Singularity render review: inspected the first native offer/field/evolved-upgrade captures and verified APK signing/integrity. Added explicit Tether rank readout so the prerequisite is directly visible; corrected staged Tether-3 attraction values to reflect all three passive ranks. Four additional UI assertions cover the rank text. These are presentation/fixture changes, not normal-run stat grants.

Post-render UI review passed 876 checks across 84 layouts with no script/engine/leak warnings; snapshot: docs/qa/singularity/ui-rank-review.json.
