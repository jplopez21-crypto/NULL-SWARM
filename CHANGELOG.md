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
