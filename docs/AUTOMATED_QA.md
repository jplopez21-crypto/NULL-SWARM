# Repeatable gameplay QA

The `Repeatable gameplay QA` GitHub Actions workflow runs on pushes, pull requests and manual dispatch. It installs Godot 4.6.3, imports resources, runs the existing system suite, then runs normal-rules bot cases and a separate synthetic CPU benchmark. JSON, Markdown and diagnostic logs are uploaded as `null-swarm-gameplay-qa`; tables also appear in the workflow summary. There is no unattended calendar schedule or claim of continuous work outside these workflow runs.

## Run locally

```sh
godot --headless --editor --import --quit
godot --headless --script tests/run_tests.gd
godot --headless --script tests/run_playtests.gd
godot --headless --script tests/run_benchmark.gd
```

Use an isolated writable XDG_DATA_HOME for sandboxed runs. Reports are written under `builds/qa/`, which is excluded from APK resources. QA save filenames have their own prefixes; the bot suite removes its files and does not write the normal player save.

## Normal-rules bots

The matrix has three upgrade strategies (Halo, Arcstorm and Kinetic), seeds 101/202 on a fresh Vanguard save, plus one explicitly earned/no-research fixture for each unlocked kit. Each case runs until death/victory or a 720-second combat-time limit. A separate seed-909, 90-second pair verifies gameplay determinism.

Bots use normal input movement and dash requests, automatic weapons, offered upgrades and available rerolls. They never inject invulnerability, teleport, grant stats during a run or force boss kills. Normal damage/dash invulnerability and earned upgrades remain enabled. Starting-kit fixtures grant only the documented prerequisite milestone before deployment, not research/currency.

A bot senses nearby geometry within 16m and has a 0.12s reaction timer (about 0.133s after fixed-tick quantization); it can see local hostile shots and artillery markers. It is not a screen-reading or human-skill model. All profiles use the same cautious collector movement, which underuses close-range weapons. Build names describe upgrade priorities, not a guarantee that that weapon dealt most damage.

Reports include outcome, survival, XP collection/leftovers, first upgrade/new weapon, minute health/level snapshots, choices, ranks, mutations, weapon damage, observed health-drop events, dash requests and entity peaks. Long gaps without upgrades flag XP-pathing/progression for investigation. `-1` means an acquisition never occurred. Timings exclude bot decision cost and rendering.

A defeat or timeout is a valid observation, not a failing test. CI fails on invalid state, illegal equipment count, impossible victory or a divergent seeded replay. Win fractions from this tiny fixed matrix are not estimates of player win rates or fun. Investigate a bot's decisions and XP path before changing balance.

## Synthetic stress benchmark

Six scenarios compare low/high effects at 100, 300 and 600 enemies, with at least 160 friendly and 160 hostile projectiles plus natural weapon/sentry fire, and replenished pickups. Normal full-build weapons/AI/collision/effects execute. Huge enemy HP and a deliberately invulnerable target maintain the load; this fixture is separate from normal-rules playtests.

After 120 warm-up steps, 600 fixed steps provide mean/p50/p95/p99/max CPU simulation times. The fixture checks enemy retention and identical low/high final selected-gameplay fingerprints. The fingerprint covers enemy/shot counts, kills, aggregate damage by weapon, player position, collected XP and combat RNG state; it is not a byte-for-byte actor dump. CPU model, logical CPU count and static-memory samples provide context. It does not time rendering, GPU work, display pacing, touch latency or mobile thermals. Do not convert these values to Android FPS. Shared-runner timings are informational rather than absolute performance pass gates.

Run the benchmark sequentially for comparisons; overlapping local bot/benchmark runs distort timing. Compare the same workload on the same device/runner class. A change to fixtures, simulation code, Godot or hardware invalidates direct baseline comparisons.

## First investigation targets

Preliminary local cases completed 7/8 runs, with one Kinetic/Vanguard defeat at 08:31. First additional weapon acquisition for fresh Vanguard cases was roughly 11–16 seconds. These are bot observations, not human balance validation. Inspect the stalled Kinetic case's collected/uncollected XP and upgrade timeline; cautious pathing may explain the result. Arc/drone cases took fewer observed hits, while the same movement policy seldom put orbitals/Halo in range. Physical-device playtesting remains necessary.

## Verified CI baseline

[Workflow 40437672314](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40437672314) passed at source commit `d6206ffff31f6e521bd507c4e483c571535de7c6`. It passed 121 system checks, all bot invariants/deterministic replay and all six synthetic load/selected-gameplay consistency checks. All eight gameplay outcomes/traces matched the local results after excluding timing fields.

- [Bot summary](qa/BOT_REPORT.md) and [full bot data](qa/bot-report.json).
- [Sequential CI CPU benchmark](qa/STRESS_REPORT.md) and [full stress data](qa/stress-report.json).
- [Download reports/logs](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40437672314/artifacts/12705035805).

At 600 synthetic enemies/400 peak shots, p95 simulation-step time was 22.611ms low and 22.444ms high on the recorded CI host. This is a CPU baseline, not proof of Android 30/60 FPS. Small low/high timing differences are shared-runner noise. Normal bot runs peaked at 41–79 active enemies depending on build/seed, a different workload.

## Pickup A/B regression

`godot --headless --script tests/run_playtests.gd -- --xp-comparison` runs Kinetic/Vanguard seeds 101 and 202 through the test-only legacy pickup fixture, the local-merge game with the original cautious bot, and the local-merge game with a separately labelled value-aware collector. The alternate collector uses visible packet tiers, target hysteresis and legal proactive dashes; it grants no stats or immunity. Its outcomes must not be conflated with the unchanged-bot A/B.

Legacy numeric results are checked against the frozen Foundry 0.3 fixture when combat/bot source hashes match. If those inputs intentionally change in future, the report explicitly skips that numeric comparison while still running the same-current-combat A/B and conservation checks. Local merges must stay within 3m and all modes must conserve XP. A defeat remains a valid bot observation.

Local diagnosis: unchanged-bot outcomes were mixed (seed 101 improved, seed 202 worsened); the alternate collector won both with local merging. The merge-distance bug is real, but this is not evidence of a universal difficulty improvement or a required weapon buff.
