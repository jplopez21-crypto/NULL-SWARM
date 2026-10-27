# NULL//SWARM

An offline sci-fi survival roguelite for Android, implemented in Godot 4.6.3 / typed GDScript. Foundry progression and feedback pass (0.3); development art and generated audio are not final commercial assets.

Open `project.godot` in Godot 4.6.3 and press F6 on `scenes/main.tscn` or F5. Deploy VANGUARD, survive ten minutes and destroy The Architect, collect blue memory shards, and select upgrades. Weapons target automatically.

- Move: WASD/arrows, controller left stick, or touch the left side and drag.
- Dash: Space, controller A, or the onscreen button.
- Pause: Escape, controller Start, or onscreen Pause.
- Performance overlay: F3.

## Verification

```sh
godot --headless --editor --import --quit
godot --headless --script tests/run_tests.gd
godot --headless -- --smoke
```

Use writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` locations in sandboxed environments. Tests use their own save filename, but the scene integration harness records test runs in the current Godot user-data directory; point XDG_DATA_HOME at an isolated test directory.

## Android debug build

Install matching Godot 4.6.3 export templates, Java 21 and Android SDK platform-tools, platform 35 and build-tools 35.0.1. Set Android SDK, Java SDK and debug keystore paths in Godot Editor Settings → Export → Android. Export with:

```sh
mkdir -p builds/android
godot --headless --export-debug Android builds/android/null-swarm-foundry-0.3-debug.apk
adb install -r builds/android/null-swarm-foundry-0.3-debug.apk
```

The GitHub Actions workflow installs dependencies, imports resources, tests, renders staged presentation captures, exports, verifies APK signing, and uploads `null-swarm-foundry-0.3-apk`. The [verified 0.3 APK artifact](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40435364064/artifacts/12703736664) contains its APK under `android/` and staged QA captures under `screenshots/`. All 121 checks and APK signature verification passed. Physical-device testing and balance remain required for this new version.

This build installs alongside the original as **NULL SWARM Foundry** (`com.nullswarm.game.foundry`). Debug keys are ephemeral per CI run; persistent signing must be configured before future in-place updates. See [Foundry notes](docs/FOUNDRY.md) and [combat slice notes](docs/COMBAT_SLICE.md) for weapons, mutations and playtest goals.

The Android Release preset targets AAB through Godot's Gradle build. Install the matching Android build template and configure protected signing credentials before release export. No release credentials or live billing are included. Windows Desktop is an additional export preset; its export has not been tested.

See [development status](DEVELOPMENT_STATUS.md), [architecture](docs/ARCHITECTURE.md), and [asset manifest](docs/ASSET_MANIFEST.md).
