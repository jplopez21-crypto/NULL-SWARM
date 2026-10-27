# NULL//SWARM

An offline sci-fi survival roguelite for Android, implemented in Godot 4.6.3 / typed GDScript. Milestone 1 foundation; development art and generated audio are not final commercial assets.

Open `project.godot` in Godot 4.6.3 and press F6 on `scenes/main.tscn` or F5. Deploy VANGUARD, survive five minutes, collect blue memory shards, and select upgrades. Weapons target automatically.

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
godot --headless --export-debug Android builds/android/null-swarm-m1-debug.apk
adb install -r builds/android/null-swarm-m1-debug.apk
```

The GitHub Actions workflow installs these dependencies, imports resources, tests, exports, verifies APK signing, and uploads `null-swarm-m1-debug-apk`. A successful Android export, test run and APK signature verification are available in [workflow run 40429916577](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40429916577). Download the `null-swarm-m1-debug-apk` artifact and extract its APK. Installation and physical-device playtesting remain unverified. Android 10 is the intended minimum; verify effective manifest SDK values before distribution. Current Play policy compliance remains a release-stage check.

The Android Release preset targets AAB through Godot's Gradle build. Install the matching Android build template and configure protected signing credentials before release export. No release credentials or live billing are included. Windows Desktop is an additional export preset; its export has not been tested.

See [development status](DEVELOPMENT_STATUS.md), [architecture](docs/ARCHITECTURE.md), and [asset manifest](docs/ASSET_MANIFEST.md).
