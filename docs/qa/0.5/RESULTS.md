# Corruption 0.5 verification — 2026-10-27

Gameplay commit: `4ee60487877978c58a5f8dc48d670a5eb399a89e`.

[Android build](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40504064445) / [APK ZIP](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40504064445/artifacts/12734700412) / [QA run](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40504064446) / [QA artifact](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40504064446/artifacts/12734461784).

- CI passed 165 established system checks plus 41 dedicated corruption checks (206 total), scene smoke, import and signed debug export.
- Dedicated checks exercise selection/cadence/caps/guards, exact declined-card/RNG preservation, background freeze, health/shield costs, real cooldown/round/drone/walking effects, unchanged dash/boss pace/warning times, lane geometry, later upgrades and clean restart. Direct synthetic setup isolates mechanics; it is not a survival claim.
- 504 UI checks across 44 staged screen states passed locally and in software-rendered CI. The new optional offer, preview and active HUD were added at four requested window sizes. Representative normal/small-window corruption panels, entry button and active HUD were inspected.
- Ten established normal cases and six pickup cases match every pre-existing 0.4.1 gameplay field after excluding wall/step timings. New `corruption` and `link_policy` fields are recorded explicitly; clean runs have no links. The 180-second deterministic replay passed. Historic Foundry numeric baseline remains intentionally incompatible after source changes.
- Six additional clean seeded cases and four legal corruption cases passed invariants. Normal-policy total: 20 cases, 16 victories / 4 defeats. Bot losses remain valid observations, not test failures; bots are not human balance evidence.
- Six clean synthetic CPU scenarios passed their fixed-load/quality-parity checks in CI.
- Signed APK download independently passed ZIP/APK hashes/CRC; new manifest package, DEX/ARM64 and compiled corruption module verified; tests/build captures excluded from the game.

## Legal corruption sessions

| Link policy | Actual links | Outcome | Seconds | Level | Peak enemies | Peak shots |
|---|---|---|---:|---:|---:|---:|
| redline | redline | victory | 600.02 | 54 | 55 | 28 |
| fracture | fracture | victory | 600.02 | 57 | 56 | 35 |
| hive | hive | victory | 600.02 | 56 | 59 | 29 |
| all | redline, fracture, hive | victory | 600.02 | 54 | 36 | 22 |

Bots accept only advertised eligible links during pending upgrades and pay the ordinary level-up cost. No stat grants, forced boss kills or injected invulnerability occur in these sessions; normal dash invulnerability is preserved. All-links acceptance happened over separate legal level gates, not as a preloaded fixture. This small set shows tested viable runs, not universal balance or an established benefit over clean builds.

## Local all-links stress fixture

Separate fixture version 3 uses a legal four-slot Pulse/Arcstorm + Arc + Rail + Drone build with all three links, four actual escorts, 100/300/600 immortal regular enemies, at least 160 friendly + 160 hostile projectiles, and an asserted floor of 250 pickups after refill. Synthetic player immunity and huge target HP sustain work. Six scenarios passed fixed-load and low/high gameplay parity locally; metadata and CPU measurements are in local-corruption-stress-report.json. The new command is added to recurring CI, but this first result was executed locally, not in the cited CI run.

At 600 enemies local p95 CPU step time was 36.57ms (low) / 38.41ms (high), excluding UI, rendering and phone thermals. This is a performance concern to investigate, not Android FPS or proof of a 30/60 FPS target. Fixture 3 has a different weapon mix and refill rule from clean fixture 2; their raw times are not a controlled comparison. No difficulty, spawn count or damage was silently reduced to improve timing.

## Capture/device limits

Window sizes are checked separately from the KEEP-scaled 1280×720 canvas. Viewport PNGs omit outer letterbox bars; they are staged desktop/software OpenGL captures, not Android safe-area or real touch tests. Physical-device performance, readability, lifecycle process death and human tradeoff balance remain unverified. Development artwork/audio are original procedural assets.
