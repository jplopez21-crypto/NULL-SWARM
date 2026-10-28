# Performance stats

Open **Settings → Performance stats** from the command menu or pause screen. Resume combat to read the overlay under actual gameplay load. Desktop **F3** controls the same saved preference; holding the key does not repeatedly toggle it. The option defaults off, including for existing saves, and travels with progression backups.

The overlay refreshes four times per second while enabled:

- **FPS** comes from Godot's rendered-frame counter. Startup displays a warm-up message until a sample exists.
- **AVG FRAME** is `1000 / FPS`, an average frame interval. It is not an independent CPU/GPU timing or a percentile measurement.
- **ENEMIES / SHOTS** are the combat world's active counts.
- **DRAWS** uses the renderer's draw-call monitor; a headless/unsupported monitor may report zero.
- **ENGINE MB** is Godot's static allocation monitor, not whole-process RSS or total device RAM.

The label ignores touch input. Enabling it changes no damage, spawning, entity budgets or graphics preset, and the game sends no diagnostic data online. Paused/menu FPS and CI software rendering do not establish physical-phone gameplay performance. Record device/OS, effect preset, run time and entity counts alongside a combat screenshot when investigating performance.

The Android smoke report also records a quiet fresh-deployment observation after a two-second warm-up: five seconds without touch input or screen captures, while existing read-only telemetry, audio and rendering remain active. Its workload differs from capture-heavy combat. It diagnoses the software emulator; it is not a device benchmark or an FPS pass condition.
