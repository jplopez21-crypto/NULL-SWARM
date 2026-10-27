# NULL//SWARM test results

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
