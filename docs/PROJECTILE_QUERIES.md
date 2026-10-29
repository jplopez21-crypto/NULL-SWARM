# Projectile query allocation investigation

SpatialGrid.query uses one shared read-only empty Array as the Dictionary fallback instead of constructing a temporary Array at each visited cell. This is the only retained production change from the previously verified code. It preserves the same loops, active/radius filtering, comparison arithmetic and append order. Each query still creates its own result snapshot; callers can mutate it without altering the spatial grid or another attack's results.

Damage processing starts only after the full snapshot is built. Nested attacks/signals cannot overwrite the outer list. Integration coverage fires a real three-target piercing shot whose first impact triggers another area query, then checks a separate empty shot for stale candidates. Ownership tests cover inclusive boundaries, independent mutable empty results, nested snapshots, grid-bucket separation and the read-only fallback.

No damage, collision margins/segments, target order, piercing, RNG, spawn/XP, difficulty, visual budgets or CombatWorld code changes are retained.

## Reproducible measurements

The kernel harness covers nine cases: allocating query and nearest target against the original frozen implementation, plus query against the immediately prior verified implementation (`tests/verified_spatial_grid.gd` from source 738a047), each with zero/100/600 allocated targets. Both implementations operate on the same cells/points. Ordered prepasses and timed checksums must match. Four alternating AB/BA rounds report raw microseconds, including Callable/checksum overhead; no hardware timing pass threshold applies.

The final local query-versus-verified median ratios were 1.179× empty, 1.326× sparse and 1.008× dense. These static kernel observations do not establish whole-combat or Android FPS gains.

A caller-owned result-buffer experiment was also executed and rejected before branch publication. It passed all correctness checks but introduced helper/clear overhead and showed slower whole-combat samples in several cases. Its clean-checkout ABBA reports are retained as `rejected-buffer-*` evidence. The extra buffer API and CombatWorld changes were removed. The final candidate keeps the smaller shared-fallback change; it does not promise zero allocations or buffer-storage reuse.

The serial whole-combat runner compares against local c6cb5f0 (remote 0d61275a46ea1681759893b67207aed7449a5b9d), using six synthetic Engineer cases and opt-in seven-phase timing. Isolated process directories, clean commit IDs/hot-file hashes and exact gameplay fingerprints are recorded. Rendering is excluded, and surrounding fixture/instrumentation limits are described in COMBAT_PROFILING.md.

All ten local suites pass: 878 systems, 56 resources, 2,244 UI checks/160 layouts, 27 Engineer, 36 GUI, nine audio, eight probe, 21 input, 41 corruption and scene smoke. All nine local kernel cases pass. Final paired whole-combat and hosted APK/runtime/full-QA acceptance are pending at this checkpoint. Raw evidence: qa/projectile-queries. TEST_RESULTS.md records the executed source and hardware/signing limits.
