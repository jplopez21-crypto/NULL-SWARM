# NULL//SWARM test results

## Development pipeline — in progress

Branch: `development/android-validation`. Production `main` is unchanged until review/merge.

| Check | Status | Evidence / limitation |
|---|---|---|
| Movement, diagonal normalization, touch ownership/release, bounds, dash/cooldown | Passed locally | 12 checks in `tests/run_input_tests.gd` |
| Combat, spawning, XP, upgrades, saves, death/victory lifecycle | Passed locally | 165 checks in `tests/run_tests.gd` |
| Corruption modifiers/transactions/reset | Passed locally | 41 checks in `tests/run_corruption_tests.gd` |
| UI geometry, lifecycle, focus, input reset | Passed locally | 504 checks / 44 staged states in `tests/run_ui_tests.gd` |
| Main-scene startup/combat smoke | Passed locally | `SCENE_SMOKE_OK` |
| Strict headless orchestration | Passed locally | Input, systems, corruption, UI and smoke suites passed; resource validation also passed separately and is integrated into the same runner |
| Resource/script validation | Passed locally | All loadable scripts/scenes/resources, including the dormant Android probe |
| Debug probe isolation | Passed locally | Snapshot preserves health, position, simulation time and progression; default export disables the probe |
| Android ARM64 Mobile export/signature | Pending development CI | Existing main build passed; new branch must be verified separately |
| Android emulator install/launch/touch/gameplay/lifecycle | Pending CI | New x86_64 Compatibility export, real ADB input, read-only opt-in telemetry |
| Local Android emulator | Could not run | Android SDK/adb/emulator absent; `/dev/kvm` unavailable. Runtime job installs dependencies on an Ubuntu GitHub runner |
| Physical ARM64 device / Mobile renderer performance | Could not run | No connected phone; emulator Compatibility results do not validate this backend/ABI |

## Reproduction

```sh
godot --headless --editor --import --quit
python3 tools/run_headless_checks.py
godot --headless --script tests/run_playtests.gd
godot --headless --script tests/run_playtests.gd -- --corruption-probe
godot --headless --script tests/run_benchmark.gd -- --corruption-stress
```

`builds/qa/headless-results.json` and suite logs record exact local/CI outcomes. The Android runtime workflow uploads APK, screenshots, telemetry report, logcat, emulator version and system-image revision. A failure fails the job; missing KVM is an explicit infrastructure blocker.

## Honest scope

Death/victory lifecycle integration includes deliberately controlled fixtures to exercise state transitions; those do not establish human survivability. Separate normal-rule bots complete real runs without injected immunity or forced boss kills. Emulator smoke uses touch for deployment, walking, dash, pause/resume and ordinary upgrade selection; it does not award XP or force outcomes. Background/relaunch checks concern checkpointed permanent progression, not mid-run restoration. Headless/software-rendered timing is not phone FPS.

## Issues found during setup

- Fixed an inferred GDScript type in the new opt-in probe loader; strict local headless suites subsequently passed.
- Local editor import also reports inability to bind its TCP service in the sandbox. This is distinct from project parse errors; hosted CI import remains a required gate.

- Found and fixed a CI cleanup hang when a superseded emulator job was cancelled before boot. Every ADB diagnostic/cleanup command now has a bounded timeout. Emulator runs use main pushes and PR updates to avoid redundant development push jobs.

- First Android runtime job failed before boot because the Ubuntu runner lacked libpulse.so.0. Added explicit Linux emulator dependencies; rerun pending.
- Added a real touchscreen settings toggle and process-death persistence assertion; ARM64 development APK now has an isolated application ID.

- Probe unit test initially failed on strict dictionary equality after JSON converted integer numeric values to floats. Corrected the comparison to validate numeric values semantically while preserving boolean types; reran the full probe checks.

- Strict CI detected an intermittent smoke shutdown leak despite a success marker. Verbose local repetition identified AudioStreamWAV/AudioStreamPlaybackWAV references; shutdown drain increased before engine exit, retaining strict leak failure checks.
- Emulator boot and Android Compatibility initialization passed. First gameplay touch was blocked by Android fullscreen onboarding and a Pixel Launcher ANR; added explicit OS-only dialog handling, activity-focus checks and emulator settling. Game ANRs remain failures. Rerun pending.

- Post-fix shutdown repetition: eight fresh-process smoke runs passed with zero leak warnings (before fix: one of eight leaked audio playback references). Full hosted rerun pending.

- Android logcat revealed real GLES shader-link failures: the emulator exceeded its fragment uniform limit. Configured Compatibility rendering for eight renderable lights/two lights per object; the current arena has one directional light, so no existing lighting or gameplay quantities are removed. Mobile/Vulkan settings remain unchanged. Runtime now fails on Godot engine errors as well as script/native crashes. Hosted rerun pending.

- Further emulator testing reached gameplay but exposed a native AudioTrack crash and remaining shader failures. Corrected the eight-second WAV loop end from frame count to the last valid sample; added a 24-second offline mixing regression test. Reduced the unused global shader variable capacity to fit minimum GLES limits; no custom shader globals are currently used. Hosted verification pending.

- Source inspection showed the GLES global uniform array is hardcoded in this Godot renderer, so project light/buffer limits do not solve the legacy emulator driver bug. Reverted those capacity changes; switched the emulator from deprecated SwiftShader-indirect to SWANGLE and enforced observed emulator/image version pins. Game rendering budgets remain unchanged.
- Audio regression passed six checks, including 24 seconds of real offline WAV mixing across multiple loop boundaries. Hosted AudioTrack validation remains pending.

- Latest Android run passed all nine functional touch/lifecycle checks, including persistent settings, with no shader-link failure or audio crash. Its final engine-log gate correctly failed on four `can_process` errors from panels detached inside synchronous button callbacks. Added a GUI-input regression reproducing four failures, changed panel retirement to hidden/deferred free, and reran it. Final hosted verification pending.
- Native and full-QA push triggers now target main plus PR updates, avoiding redundant branch push runs; manual dispatch remains available.
