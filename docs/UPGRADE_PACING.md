# Upgrade pacing and collection guidance

The memory bar now displays recovered XP, the current threshold and the next level. The opening HUD teaches movement/dash for ten seconds, then explains collecting blue memory and following the cyan locator until 22 seconds. The hint clears before the existing charge warning. The readout ignores touch input; pause, upgrades and results use the existing HUD lifecycle. No audio or flashing cue was added.

## Investigation

Run `godot --headless --script tests/run_playtests.gd -- --pacing-probe` with writable XDG directories. It runs Singularity upgrade preferences with seeds 101/202 under both established collectors. Combat, upgrade selection and progression rules are identical. Reports are written to `builds/qa/pacing-probe.json` and `PACING_REPORT.md`; recurring QA uploads both.

Every five simulated seconds the optional trace records XP dropped/recovered, stationary/in-flight XP, stationary XP within the bot's 16m sensor, nearest packet distance, player position, magnet radius and current level/threshold. Each sample checks pickup conservation and recovered XP against accumulated level costs. Tracing consumes no game RNG and does not move or attract packets. Ordinary sessions do not run this additional query.

Local results:

| Seed | Collector | Outcome | Final level | Longest upgrade gap |
|---:|---|---|---:|---:|
| 101 | Cautious | Victory | 53 | 220.70s |
| 101 | Value-aware | Victory | 56 | 22.30s |
| 202 | Cautious | Victory | 56 | 250.40s |
| 202 | Value-aware | Victory | 56 | 129.45s |

For cautious seed 101, between 240s and 360s the bot repeats positions around (31, -16). Recovered XP stays at 2,821 while stationary XP rises from 587 to 3,384. The nearest packet is about 6.6m away, just outside its 6.2m attraction radius. Seed 202 similarly circles near (6, 34), leaving thousands of XP on the field. The long gaps coincide with collection navigation stalls. Boss cache vacuums can later produce bursts of upgrades.

An exploratory locator-aware collector produced longer gaps than the established value-aware policy in both seeds (257.00s / 210.52s). That policy was discarded; the two established collectors remain unchanged. Its results are an exploratory observation, not a maintained regression fixture.

## Scope and limits

The shipped change explains collection and exposes actual progress. XP amounts, thresholds, spawn quantities, damage, attraction, boss rewards and established bot policies are unchanged. The original cautious baseline remains visible in CI, including its pacing flags. Numeric replay comparisons exclude only CPU timings and the optional new trace.

These are fixed-seed geometric bots with privileged sensors. They do not establish human collection difficulty, safety of a route, retention or fun. A 129-second gap persists in one alternate-collector run. Human playtesting and physical-phone readability are still required before changing global XP balance. The staged onboarding image deliberately grants fixture XP for visual review; normal-rules trace sessions grant none.
