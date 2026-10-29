# Projectile query snapshots

Friendly projectiles share one caller-owned candidate Array per CombatWorld tick. `SpatialGrid.query_into(point, radius, scratch)` clears and fills that array in the original cell/entity order, returning the same caller-owned object. The original `query()` API still returns a separate snapshot for area attacks and other callers.

The whole candidate snapshot is built before damage processing, preserving the original membership/filtering time. A hit can trigger another query, chain, signal or area attack without overwriting the outer projectile snapshot. The scratch object is local to each tick, so it needs no run reset and a nested tick owns a different object. The next shot clears previous candidates. It must never be a spatial bucket array.

Queries use a shared read-only empty bucket as the Dictionary fallback. This avoids constructing fallback Array containers while visiting cells. Scratch reuse reduces new Array containers; Array.clear/append may still resize engine storage, so this is not a zero-allocation guarantee.

Damage, collision margins/segments, target order, inclusive query boundaries, piercing, RNG, spawn/XP, difficulty and visual budgets stay unchanged. Real collision integration tests cover three piercing hits with a nested area query on first impact, then a separate empty shot. Randomized checks compare reused buffers with the independent frozen legacy implementation, including stale/inactive entries. Ownership tests verify empty clearing, independence, boundaries and non-aliasing with buckets.

## Measurement and acceptance

The existing kernel harness now covers nine cases: allocating query, nearest target and buffered query, each with zero/100/600 allocated targets. Buffered timing includes a bound Callable argument. All paths compare ordered results/checksums with the independent legacy query. Four alternating AB/BA rounds report raw microseconds; there is no timing pass threshold or Android FPS claim.

The serial whole-combat runner compares the previous verified code with this change using the existing six-case Engineer stress fixture and opt-in seven-phase timing. It isolates process save/cache directories, records clean commit IDs/hot-file hashes and checks exact gameplay fingerprints across all four runs. Synthetic timing excludes rendering; surrounding fixture work and instrumentation limits remain as documented in COMBAT_PROFILING.md.

All ten local suites pass: 1,079 systems, 55 resources, 2,244 UI checks/160 layouts, 27 Engineer, 36 GUI, nine audio, eight probe, 21 input, 41 corruption and scene smoke. Paired whole-combat measurement and hosted APK/runtime/full-QA acceptance are pending at this implementation checkpoint. Raw evidence is under qa/projectile-queries. TEST_RESULTS.md records the final executed revision and hardware/signing limitations.
