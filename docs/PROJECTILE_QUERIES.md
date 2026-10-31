# Projectile query allocation investigation

SpatialGrid.query uses one shared read-only empty Array as the Dictionary fallback instead of constructing a temporary Array at each visited cell. This is the only retained production change from the previously verified code. It preserves the same loops, active/radius filtering, comparison arithmetic and append order. Each query still creates its own result snapshot; callers can mutate it without altering the spatial grid or another attack's results.

Damage processing starts only after the full snapshot is built. Nested attacks/signals cannot overwrite the outer list. Integration coverage fires a real three-target piercing shot whose first impact triggers another area query, then checks a separate empty shot for stale candidates. Ownership tests cover inclusive boundaries, independent mutable empty results, nested snapshots, grid-bucket separation and the read-only fallback.

No damage, collision margins/segments, target order, piercing, RNG, spawn/XP, difficulty, visual budgets or CombatWorld code changes are retained.

## Reproducible measurements

The kernel harness covers nine cases: allocating query and nearest target against the original frozen implementation, plus query against the immediately prior verified implementation (`tests/verified_spatial_grid.gd` from source 738a047), each with zero/100/600 allocated targets. Both implementations operate on the same cells/points. Ordered prepasses and timed checksums must match. Four alternating AB/BA rounds report raw microseconds, including Callable/checksum overhead; no hardware timing pass threshold applies.

The final local query-versus-verified median ratios were 1.179× empty, 1.326× sparse and 1.008× dense. These static kernel observations do not establish whole-combat or Android FPS gains.

A caller-owned result-buffer experiment was also executed and rejected before branch publication. It passed all correctness checks but introduced helper/clear overhead and showed slower whole-combat samples in several cases. Its clean-checkout ABBA reports are retained as `rejected-buffer-*` evidence. The extra buffer API and CombatWorld changes were removed. The final candidate keeps the smaller shared-fallback change; it does not promise zero allocations or buffer-storage reuse.

The serial whole-combat runner compares against local c6cb5f0 (remote 0d61275a46ea1681759893b67207aed7449a5b9d), using six synthetic Engineer cases and opt-in seven-phase timing. Isolated process directories, clean commit IDs/hot-file hashes and exact gameplay fingerprints are recorded. Rendering is excluded, and surrounding fixture/instrumentation limits are described in COMBAT_PROFILING.md.

All ten local suites pass: 878 systems, 56 resources, 2,244 UI checks/160 layouts, 27 Engineer, 36 GUI, nine audio, eight probe, 21 input, 41 corruption and scene smoke. All nine local kernel cases pass. Final paired whole-combat fingerprints match in all four runs. Source cfceb77d9af881ea4fcfd493a7c1925078031d81 passed native export/signature, 33 Android runtime checks and full QA. Local/native/QA strict summaries match, and downloaded gameplay/XP/pacing results and all 24 stress fingerprints match the prior verified source. Hosted kernels/phases and the revision-specific receipt are preserved with the raw evidence. Raw evidence: qa/projectile-queries. TEST_RESULTS.md records the executed source and hardware/signing limits.

## Final whole-combat comparison

Candidate/baseline/baseline/candidate, two serial samples/version on the same shared local host. The source files match the published source cfceb77d9af881ea4fcfd493a7c1925078031d81 (local 15f7037); baseline local c6cb5f0 maps to remote 0d61275. Both checkouts were clean. All six case fingerprints match in all four runs. Median whole-fixture durations in milliseconds:

| Enemies | FX quality | Mean, baseline → candidate | p95, baseline → candidate |
| --- | --- | --- | --- |
| 100 | low | 2.897 → 3.006 | 4.962 → 5.779 |
| 100 | high | 3.347 → 3.439 | 5.722 → 6.537 |
| 300 | low | 4.439 → 4.423 | 11.328 → 11.810 |
| 300 | high | 4.380 → 4.981 | 12.277 → 12.884 |
| 600 | low | 7.476 → 7.753 | 25.608 → 25.432 |
| 600 | high | 8.305 → 7.874 | 26.306 → 25.008 |

Results are mixed: most mean samples were slower or roughly flat; 600/high was faster. This does not establish a whole-combat speedup or a causal regression. The retained change removes per-cell fallback Array construction without adding helper calls or modifying snapshots. The rejected buffer's extra API/CombatWorld work is absent. No FPS or allocation-free guarantee is claimed. Further frame-rate decisions require representative hardware and stronger measurements; do not infer them from these two-sample shared-host wall timings. Raw hashes/individual samples are in final-combat-comparison.json.

The rejected buffer local commit f19e0d2 maps to remote 456d1e50e5b4ab1fb6354e52a4caff2bc22b4c69 in branch history; final local 15f7037 maps to cfceb77d9af881ea4fcfd493a7c1925078031d81. Git trees were checked for equality at publication.
