# NULL//SWARM

An offline sci-fi survival roguelite for Android, implemented in Godot 4.6.3 / typed GDScript. Memory guidance pass (0.4.1); development art and generated audio are not final commercial assets.

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
godot --headless --export-debug Android builds/android/null-swarm-memory-0.4.1-debug.apk
adb install -r builds/android/null-swarm-memory-0.4.1-debug.apk
```

The GitHub Actions workflow installs dependencies, imports resources, tests, renders staged presentation captures, exports, verifies APK signing, and uploads `null-swarm-memory-0.4.1-apk`. [Download the verified 0.4.1 APK artifact](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40496218606/artifacts/12730444055) (sign into GitHub, extract the ZIP, install the APK in `android/`). Physical-device testing and balance remain required for this new version.

The new 0.4.1 build installs separately as **NULL SWARM Memory** (`com.nullswarm.game.memory`). Debug keys are ephemeral per CI run; persistent signing must be configured before future in-place updates. See [Foundry notes](docs/FOUNDRY.md) and [combat slice notes](docs/COMBAT_SLICE.md) for weapons, mutations and playtest goals.

The Android Release preset targets AAB through Godot's Gradle build. Install the matching Android build template and configure protected signing credentials before release export. No release credentials or live billing are included. Windows Desktop is an additional export preset; its export has not been tested.

See [development status](DEVELOPMENT_STATUS.md), [architecture](docs/ARCHITECTURE.md), and [asset manifest](docs/ASSET_MANIFEST.md).

## Repeatable gameplay QA

The separate **Repeatable gameplay QA** Actions workflow runs normal-rules bot cases and a synthetic combat CPU benchmark on pushes/PRs or manual dispatch. Reports and diagnostic logs are uploaded as `null-swarm-gameplay-qa`, with tables in the workflow summary. See [QA methods and limits](docs/AUTOMATED_QA.md).

```sh
godot --headless --script tests/run_playtests.gd
godot --headless --script tests/run_benchmark.gd
```

Bots do not receive injected invulnerability or forced boss kills. Stress fixtures deliberately do; their headless CPU timings are not Android FPS. The QA drivers and their fixture overrides are excluded from Android exports.

The 0.3.1 patch fixes pickup merging across distant positions and marks valuable packets with larger mint/gold visuals. Updated CI verification passed; [pickup comparison results](docs/qa/0.3.1/XP_COMPARISON.md) retain both positive and negative bot outcomes. The separately labelled XP comparison is described in [QA methods](docs/AUTOMATED_QA.md).

Adaptive formations begin analysis at 02:00, announce eight seconds before changing the enemy mix, and offer persistent counterplay hints. See [Adaptive Swarm rules and limits](docs/ADAPTIVE_SWARM.md).

The 0.4.1 memory cue points from the operative toward stationary uncollected XP and displays distance. It does not identify a safe path or automatically collect packets. Human readability and pacing improvement remain to be tested.
