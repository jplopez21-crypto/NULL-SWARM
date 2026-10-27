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
| Resource/script validation | Passed locally | 46 loadable scripts/scenes/resources, including the dormant Android probe |
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
