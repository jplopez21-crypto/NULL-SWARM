# Combat CPU investigation

Profiling is opt-in. Ordinary gameplay does not read wall time or collect samples. `CombatWorld.profile_enabled` enables seven regions; `reset_profile()` clears their counters and `profile_snapshot()` returns frame count and mean milliseconds. An early player death records only the phases reached.

```sh
godot --headless --script tests/run_benchmark.gd -- --engineer-stress --phase-profile
godot --headless --script tests/run_grid_benchmark.gd
python3 tools/run_combat_comparison.py --baseline /path/to/baseline --candidate /path/to/candidate --output /path/to/results --order baab
```

The combat benchmark discards 120 warm-up steps, then measures 600 steps per case. Its synthetic sustained-load fixtures grant invulnerability/high enemy HP and replenish shots/pickups. They are separate from normal-policy playtests. Phase totals cover CombatWorld, including its CPU pose/effect work, but exclude player movement, pickups, replenishment, scene rendering and GPU work. Whole-fixture timing includes the first three excluded simulation tasks. Instrumentation adds overhead; neither measurement is device FPS.

## Changes and correctness

- Nearest-target scans skip absent buckets without constructing a default array. Small collision queries retain the original bucket access; their radius squared is calculated once per query.
- EnemyDefinition stores both existing squared collision radii and refreshes them whenever `radius` changes. Defaults use the exact previous arithmetic; margins, comparisons and segment geometry are unchanged.
- A frozen legacy implementation checks exact ordered query results and nearest targets, including exclusions, stale/inactive entries, boundaries and tie order. Integration checks verify actual projectile/contact collisions after live radius changes. Profiling defaults off, respects reset and does not drive gameplay.
- No enemy/projectile/FX budget, difficulty, RNG, spawn, damage, XP, pause or victory rule changes.

## Local evidence, 2026-10-29

All ten isolated suites passed (870 systems, 2,244 UI checks/160 layouts, 27 Engineer, 36 GUI, nine audio, eight probe, 55 resources, 21 input, 41 corruption and scene smoke). Strict script/engine/leak scan was clean. Reports are under [qa/grid-query](qa/grid-query).

The identical-code kernel calibration varied roughly 0.95–1.09×. The final four-round alternating kernel comparison preserved ordered parity in all six cases. Nearest-target median ratios were 1.407× empty, 1.278× sparse and 1.081× dense; collision queries were 0.942×, 0.965× and 1.034×. Callable/checksum overhead and host noise are included. The two small apparent query slowdowns and the dense nearest gain are near calibration noise, so they are not robust performance conclusions.

The first whole-combat candidate changed both bucket loops; smaller cases slowed and heavy cases had mixed tail timings. It was narrowed before publication. The retained refinement was measured serially in candidate/baseline/baseline/candidate order, two samples/version, with clean checkouts. Every case retained its exact gameplay fingerprint in all four runs. Median whole-fixture mean and p95 durations (milliseconds):

| Enemies | FX quality | Mean, baseline → candidate | p95, baseline → candidate |
| --- | --- | --- | --- |
| 100 | low | 2.726 → 2.674 | 4.973 → 4.607 |
| 100 | high | 2.607 → 3.108 | 4.385 → 5.807 |
| 300 | low | 3.706 → 4.060 | 9.700 → 11.319 |
| 300 | high | 3.990 → 4.037 | 10.457 → 10.291 |
| 600 | low | 7.324 → 6.331 | 22.815 → 21.986 |
| 600 | high | 7.740 → 6.736 | 23.979 → 20.492 |

The 600-enemy cases had approximately 14% and 13% lower mean duration in this local sample; lower loads were mixed, including slower 100/high and 300/low cases. No uniform speedup, confidence interval or phone FPS improvement is established. Timing has no hardware-dependent pass threshold. Friendly projectiles were about 60% of baseline CombatWorld work at 600 enemies; further optimization requires another measured comparison.

`refined-combat-comparison.json` records exact hot-file hashes and local commits: baseline `2fb67bdf043e64d8b6e6c3068487b2df7d0cd406`, candidate `bcc17ed5db7779e2474b9069cccba745dd11aa9e`. Git data API equivalents are respectively `11a25d2a6e6eb8beef62d20fc329c8b723a7473a` and `fde31d08dfc16b9ddd97196a83469d5c6c5f502f`; identical Git trees were verified before branch publication. The report checkpoint changes only documentation/evidence from that candidate.

## Hosted acceptance

Recurring QA runs the six-case kernel parity harness and opts the existing six-case Engineer stress suite into phase timing. Normal gameplay, replay, UI layouts and the other stress fixtures remain unchanged. Code 738a047978ce53b61a6d64f8bfbfe89862f6bf98 passed native export/signature, all 33 Android checks and the full gameplay QA matrix, including six kernel cases and six profiled Engineer scenarios with 600 measured frames/seven regions each. Downloaded normal gameplay/pacing/XP results and all 24 stress fingerprints match the prior verified code. Raw hosted kernels/phases and the acceptance receipt are preserved under qa/grid-query. Revision-specific results/APK identity and limits are recorded in TEST_RESULTS.md. Physical ARM64 Mobile rendering, phone frame times/thermals and human playtesting remain open.
