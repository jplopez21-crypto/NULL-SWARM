# Development status — Adaptive Swarm 0.4 / 2026-10-27

## Completed implementation

- Existing six weapons/mutations, bosses, Foundry progression and local XP-packet fix retained.
- Added run-local adaptive composition driven by actual damage groups and movement, with first analysis at 02:00.
- Eight-second warnings, persistent HUD reasons/counterplay, 45-second responses and capped 20% spawn-slot bias.
- Boss quiet windows; pause/background freeze timers; restart clears the signature.
- Added amber-core Insulator with stated 20% Arc/Arcstorm-chain resistance and normal damage from other weapons.
- Spawn schedule/count and existing enemy stats remain unchanged by adaptation; enemy composition can change pressure.
- Added adaptation telemetry, electric build/kit probes, 180-second replay and a six-archetype synthetic fixture (version 2).

## Local validation

- 150 system checks passed, zero failures.
- Coverage includes first-analysis/warning timing, classification/evidence thresholds, mixed styles, expiry, boss windows, sample bounds, pause/reset, resistance and spawn-count/RNG-draw invariants.
- Preliminary historical-profile eight-case run: seven wins/one early Halo defeat. These are normal-rules bots, not invulnerable completion fixtures.
- Focused Electric probes naturally spawned Insulators. Conductor won with 338 resisted hits; Vanguard lost later. This demonstrates a viable tested countered build, not universal human balance.
- Wider ten-case normal matrix, pickup comparisons, synthetic benchmark, captures and signed APK are pending CI.

## Known limitations / in progress

- Phone performance, warning readability and 0.4 difficulty have not been measured here.
- Test app is NULL SWARM Adaptive, package com.nullswarm.game.adaptive. Prior apps/private saves remain separate because stable protected signing is still unconfigured.
- Existing Insulators keep their inherent resistance after the formation expires; expiry affects new spawn bias, not enemy stats.
- Bot movement is geometry-based and cautious; build comparisons can underuse close-range weapons. Defeats are retained as observations.
- Synthetic CPU timings exclude rendering/thermals; the expanded six-type workload is not an apples-to-apples comparison to pre-0.4 benchmarks.
- Corruption, full character/content roster, final art/audio, release signing/AAB and commercial polish remain unfinished.

## Next priorities

1. Inspect warning/active renders and complete expanded CI/APK verification.
2. Review normal-rule outcomes and composition telemetry before balance changes.
3. Validate on-device readability/performance and proceed toward informed corruption choices as the next original system.
