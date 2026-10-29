# Engineer / Dash Uplink

Defeat **The Architect once** to unlock Engineer in the Foundry. The boss reward is checkpointed; extraction is not required to keep the unlock. Existing saves with an Architect defeat qualify automatically.

Engineer starts with **80 HP**, a weak Pulse Rifle (9 damage / 0.65s), and **Drone Hive rank 1**. The rifle and hive occupy two of four weapon slots. Permanent research applies normally; shield, movement and dash rules match the other kits.

Every **accepted dash** leaves a Field Sentry at the takeoff point:

- One reusable sentry, lasting three seconds. Another successful dash moves and refreshes it; sentries cannot stack.
- A stationary 14m targeting range, firing every 0.55s while a target is available. It does not block movement or draw enemy aggression.
- Damage follows Drone Hive ranks: `17 × (1 + 0.28 × (rank − 1))`. Hits contribute to drone damage totals and ordinary Swarm adaptation analysis.
- Overclock and Redline accelerate its firing cycle. Hive's additional escort remains an orbiting drone; it does not add stationary sentries.
- Pause, upgrades and focus loss freeze it with the rest of combat. Expiry hides it without a late shot. Each deployment resets its state.

Dash placement matters: leave a firing position beside a group, then move to safety. Engineer trades health and rifle strength for its starting hive and placed support. The sentry HUD shows its lifetime; Pause → Build // Mutations explains the passive. The usual reduced-flash and effect-quality controls apply without changing damage.

The tripod model and deployment sound are original procedural development assets. They are not final commercial artwork/audio.

## Verification scope

Dedicated integration tests cover unlock/checkpoint/backup selection, real dash acceptance/rejection, takeoff anchoring, damage/ranks/cooldowns, rate bonuses, range, reuse, expiry, pause, quality parity and reset. Two fixed-seed normal-rules earned-kit sessions won; the unchanged cautious bot used 17/22 sentries and fired 94/143 shots. This is automated play, not human balance evidence.

The Engineer CPU fixture adds actual accepted dashes and a firing sentry to the explicit synthetic all-links/gravity load. It sustains 100/300/600 enemies, friendly/hostile shots and pickups. Its invulnerable player and huge enemy HP maintain workload; its timings are not Android FPS.

Android QA first completes ordinary touch combat and exact earned-salvage relaunch/backup/update checks. It then restores a **labelled synthetic Architect milestone fixture** through the normal backup UI, selects Engineer through Foundry touch input and exercises the passive. This tests mobile operation and persistence, not earning the Architect unlock on-device. The probe stays read-only; no Engineer grant switch is added to the Android game. Desktop presentation captures are debug-only and cannot launch through Android's capture argument.

Hosted verification passed all 32 Android checks, 140 rendered UI layouts, 26 normal sessions and 24 synthetic stress cases. This includes two new Vanguard drone-priority cases for broader build coverage. Downloaded old cases/fingerprints remain unchanged, and Engineer cases/fingerprints match the local reports. Exact code, build artifacts and limits are recorded in TEST_RESULTS.md and docs/qa/engineer/verified-ci.json. These passes do not establish physical-phone performance or human balance.
