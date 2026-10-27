# Development status — 2026-10-27

## Completed implementation

- Godot 4.6.3 project with elevated 3D camera and industrial arena.
- VANGUARD movement, dash, Pulse Rifle, shields and damage invulnerability.
- Pooled crawlers, charging strikers and ranged sentries with telegraphed attacks.
- Five-minute survival schedule, XP pickups, capped upgrades, victory/defeat and restart.
- Touch/keyboard/controller input; HUD, menus, settings and safe-area margins.
- Generated audio, adjustable feedback and performance overlay.
- Versioned local settings/statistics with backup recovery.
- Source published to GitHub; Android debug CI now builds successfully.

## Latest build — successful

- Build commit: `c962acfb5c02ed261b363d45625d7738b85b43e3`.
- Workflow: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40429916577
- Artifact: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40429916577/artifacts/12700993972
- APK: `builds/android/null-swarm-m1-debug.apk`, ARM64, 27,664,697 bytes.
- SHA256: `da1d426d1e7f2e85e276dcf822df04b134faaecc9acf43c27e4e6bb08f9c2c4e`.
- Android export and apksigner verification passed in GitHub Actions.
- Downloaded artifact ZIP and contained APK integrity/checksum independently verified locally.
- Debug signing only. No release-ready AAB or production signing credentials included.

## Test results

- CI resource import: passed.
- Automated suite: 79 checks, zero failures, including five-minute lifecycle simulation, defeat/restart, pool reset, pause, cooldowns, upgrades and corrupted-save recovery.
- Scene smoke: passed with active enemies and projectiles.
- Completion harness uses invulnerability to isolate lifecycle correctness; human survivability/balance is not established.
- Android installation, touch feel, rendered visuals and S23 Ultra performance have not been tested.

## Known limitations / in progress

- Milestone 1 acceptance remains open until installed APK gameplay and physical-device performance checks pass.
- CI's test suite still emitted an intermittent ObjectDB shutdown leak warning despite audio cleanup. The scene smoke passed without that warning; further investigation is required.
- Graphics presets currently vary damage-number effects only; no measured Android performance budget yet.
- Application interruption pauses and persists settings/statistics; active-run recovery after process termination is not implemented.
- Artwork/audio remain development assets, not final commercial presentation.
- Android 10 minimum configuration and current Play policy requirements must be verified during release preparation. This non-Gradle debug export uses the engine template SDK configuration.
- No completed production release-signing workflow, billing, permanent progression or Milestone 2 content.

## Next priorities

1. Install the APK on S23 Ultra and complete a human five-minute session.
2. Validate joystick/dash multitouch, controller focus, safe areas and background/resume.
3. Profile frame time, enemy/projectile counts and rendering under heavy combat; verify Compatibility fallback.
4. Investigate intermittent CI shutdown warning and tune difficulty/readability before Milestone 2.
