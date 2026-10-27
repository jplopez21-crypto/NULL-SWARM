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

A bot senses nearby geometry within 16m and reacts every 0.12s; it can see local hostile shots and artillery markers. It is not a screen-reading or human-skill model. All profiles use the same cautious collector movement, which underuses close-range weapons. Build names describe upgrade priorities, not a guarantee that that weapon dealt most damage.

Reports include outcome, survival, XP collection/leftovers, first upgrade/new weapon, minute health/level snapshots, choices, ranks, mutations, weapon damage, observed health-drop events, dash requests and entity peaks. Long gaps without upgrades flag XP-pathing/progression for investigation. `-1` means an acquisition never occurred. Timings exclude bot decision cost and rendering.

A defeat or timeout is a valid observation, not a failing test. CI fails on invalid state, illegal equipment count, impossible victory or a divergent seeded replay. Win fractions from this tiny fixed matrix are not estimates of player win rates or fun. Investigate a bot's decisions and XP path before changing balance.

## Synthetic stress benchmark

Six scenarios compare low/high effects at 100, 300 and 600 enemies, with at least 160 friendly and 160 hostile projectiles plus natural weapon/sentry fire, and replenished pickups. Normal full-build weapons/AI/collision/effects execute. Huge enemy HP and a deliberately invulnerable target maintain the load; this fixture is separate from normal-rules playtests.

After 120 warm-up steps, 600 fixed steps provide mean/p50/p95/p99/max CPU simulation times. The fixture checks enemy retention and identical low/high final gameplay fingerprints. CPU model, logical CPU count and static-memory samples provide context. It does not time rendering, GPU work, display pacing, touch latency or mobile thermals. Do not convert these values to Android FPS. Shared-runner timings are informational rather than absolute performance pass gates.

Run the benchmark sequentially for comparisons; overlapping local bot/benchmark runs distort timing. Compare the same workload on the same device/runner class. A change to fixtures, simulation code, Godot or hardware invalidates direct baseline comparisons.

## First investigation targets

Preliminary local cases completed 7/8 runs, with one Kinetic/Vanguard defeat at 08:31. First additional weapon acquisition for fresh Vanguard cases was roughly 11–16 seconds. These are bot observations, not human balance validation. Inspect the stalled Kinetic case's collected/uncollected XP and upgrade timeline; cautious pathing may explain the result. Arc/drone cases took fewer observed hits, while the same movement policy seldom put orbitals/Halo in range. Physical-device playtesting remains necessary.
