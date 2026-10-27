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

The current matrix has four upgrade strategies (Halo, Arcstorm, Kinetic and Electric), seeds 101/202 on a fresh Vanguard save, plus one explicitly earned/no-research fixture for each unlocked kit. Each case runs until death/victory or a 720-second combat-time limit. A separate seed-909, 180-second pair verifies gameplay determinism.

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

## Current 0.3.1 verification

[QA workflow 40441583251](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40441583251) passed at `604013b1cee618a9b970270feebaf0cca24b6529`: 130 system checks, eight normal bot cases plus replay verification, six pickup A/B/collector cases and six synthetic stress scenarios.

- [Pickup A/B table](qa/0.3.1/XP_COMPARISON.md) / [full data](qa/0.3.1/xp-comparison.json).
- [Current bot matrix](qa/0.3.1/BOT_REPORT.md) / [full data](qa/0.3.1/bot-report.json).
- [Current CPU benchmark](qa/0.3.1/STRESS_REPORT.md) / [full data](qa/0.3.1/stress-report.json).

Legacy replay compatibility was true; both numeric baselines matched. All six A/B/collector CI traces matched local traces excluding timing fields. Correcting XP placement did not universally improve cautious-bot wins. The variant collector uses a different labelled navigation policy and cannot be used to claim an unchanged-bot balance improvement.

## 0.4 adaptive coverage

Current reports include adaptation warning/activation/expiry histories, underlying metrics, spawned types and resisted hits. The Conductor fixture now prioritizes the Electric build, explicitly labelled by profile, while other established profiles remain available. Ten normal cases run (four strategies × two fresh Vanguard seeds, plus Conductor/Sentinel fixtures). The replay extends past the first 02:00 analysis.

Synthetic fixture version 2 mixes all six regular enemy types; compare timing only within the same fixture/hardware/Godot context. The frozen 0.3 pickup numeric baseline is expected to be incompatible after these combat changes; the report states this rather than pretending it was replayed. Current-game pickup conservation and labelled collector comparisons remain enabled.

## Upgrade-gap collector probe

Run `godot --headless --script tests/run_playtests.gd -- --collector-probe` to compare Arcstorm and Kinetic on seeds 101/202, each with cautious and value-aware navigation. Combat, pickup merging, upgrade priorities and new-player stats are identical; only collector navigation differs. The eight runs write `builds/qa/collector-probe.json`, including upgrade timestamps, minute snapshots, earned/left XP and the longest upgrade gap. Invariant failures return a nonzero exit code; defeats remain observations. Use isolated XDG directories as with other scene integration tests.

This probe is explicit/manual rather than an extra mandatory build step. It does not replace the canonical cautious-bot matrix or retroactively change its reported outcomes.

## 0.4.1 memory guidance verification

165 checks passed, including locator empty/nearest/hysteresis/retarget/in-flight/attraction-range/read-only/vacuum cases. Ten normal bot case records and six pickup case records exactly matched canonical 0.4 after excluding wall/step timing fields. Six stress scenarios and 180-second replay passed. [Current reports](qa/0.4.1/BOT_REPORT.md) preserve the same seven wins/three defeats. The locator is driven by rendered UI updates, not bot decisions; these comparisons establish simulation isolation for the tested cases, not a human pacing benefit or phone UI cost.

## Continuing UI and seeded-run regression coverage

`godot --headless --script tests/run_ui_tests.gd` exercises menu, settings, combat, adaptation warning, pause, upgrades, results and Foundry at four requested window sizes: 1280×720, 1600×720, 1280×960 and 960×600. It verifies actual requested window sizes independently from the logical canvas, visible-button/panel containment, touch/dash reset, frozen simulation clock, focus-loss pause, guidance suppression/reacquisition and stale-target cleanup on restart. The project’s KEEP scaling preserves the 1280×720 logical canvas with letterboxing at other ratios; this is not coverage of four independent responsive canvas sizes.

CI runs the same suite with `--capture-ui` under Xvfb/software OpenGL and uploads 32 staged PNGs plus `ui-report.json` in the QA artifact. These captures are desktop renders, not Android safe-area, real touch, device FPS or process-death validation. Viewport PNGs omit outer letterbox bars; their pixel dimensions can differ from requested window dimensions. Synthetic lifecycle actions and seeded/staged state setup are test fixtures.

`godot --headless --script tests/run_playtests.gd -- --extended-seeds` adds six cautious-bot sessions on seeds 303/404/505 covering all four builds and both earned-kit fixtures. It retains normal combat, legal offered upgrades and all existing invariants; defeats remain valid observations. Results are separate from the canonical ten-case matrix (`extended-seeds.json`), preserving prior comparisons. Both suites now run on each QA workflow invocation.

## Daily unattended runs

The QA workflow is scheduled daily at **03:23 UTC**, in addition to push/PR/manual runs. GitHub runs this on the default branch; scheduled start times can be delayed by GitHub. QA reports, diagnostic logs and staged screenshots are retained for 14 days in `null-swarm-gameplay-qa`. This is an actual CI schedule, not a background chat process. The scheduled job does not publish or install a new APK and needs no signing credentials. A failed invariant or UI geometry check fails the job; bot defeats are retained as observations.

The first expanded run passed all checks; [recorded results and limitations](qa/0.4.1/followup/RESULTS.md).
