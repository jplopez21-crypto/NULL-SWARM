# Development status — Memory locator 0.4.1 / 2026-10-27

## Completed implementation

- Existing six weapons/mutations, bosses, Foundry progression and local XP-packet fix retained.
- Added run-local adaptive composition driven by actual damage groups and movement, with first analysis at 02:00.
- Eight-second warnings, persistent HUD reasons/counterplay, 45-second responses and capped 20% spawn-slot bias.
- Boss quiet windows; pause/background freeze timers; restart clears the signature.
- Added amber-core Insulator with stated 20% Arc/Arcstorm-chain resistance and normal damage from other weapons.
- Spawn schedule/count and existing enemy stats remain unchanged by adaptation; enemy composition can change pressure.
- Distributed each enemy archetype across all six AI update phases to avoid type-synchronized workloads and volleys.
- Added adaptation telemetry, electric build/kit probes, 180-second replay and a six-archetype synthetic fixture (version 2).

## Local validation

- 156 system checks passed, zero failures.
- Coverage includes first-analysis/warning timing, classification/evidence thresholds, mixed styles, expiry, boss windows, sample bounds, pause/reset, resistance, spawn-count/RNG-draw invariants and per-archetype AI phase distribution.
- GitHub CI passed all 156 checks, scene smoke, ten normal-rules bot cases and deterministic 180-second replay.
- Seven bot victories/three defeats: Halo Vanguard seed 202 lost at 119.4s; both Arcstorm Vanguard seeds lost near 528–534s. Electric Vanguard (both seeds), Conductor and Sentinel fixtures won. These are observations, not human balance guarantees.
- Recorded 36 Bulwark warnings, 17 Insulator warnings and 1,140 resisted electrical hits across the matrix. Arcstorm and Kinetic reports flag long upgrade gaps for collector/path inspection.
- Six current-combat pickup comparisons and six synthetic CPU scenarios passed; low/high gameplay parity holds. Historic Foundry numeric replay is skipped because source inputs changed.
- Android workflow 40446641740 and QA workflow 40446641895 succeeded for code commit 2b3d42de6832d2f35e9c7bd95da960db00a363cb.
- APK signature verified by CI; downloaded ZIP/APK hashes and archive integrity independently checked. Warning/active renders inspected. Reports: docs/qa/0.4/; APK metadata: docs/qa/0.4/apk-verification.json.

## Known limitations / in progress

- Phone performance, warning readability and 0.4 difficulty have not been measured here.
- Test app is NULL SWARM Adaptive, package com.nullswarm.game.adaptive. Prior apps/private saves remain separate because stable protected signing is still unconfigured.
- Existing Insulators keep their inherent resistance after the formation expires; expiry affects new spawn bias, not enemy stats.
- Bot movement is geometry-based and cautious; build comparisons can underuse close-range weapons. Defeats are retained as observations.
- Synthetic CPU timings exclude rendering/thermals; the expanded six-type workload is not an apples-to-apples comparison to pre-0.4 benchmarks.
- Corruption, full character/content roster, final art/audio, release signing/AAB and commercial polish remain unfinished.

## Next priorities

1. Instrument pickup distances/collection rates during stalled intervals; evaluate readable collection guidance.
2. Review normal-rule outcomes and composition telemetry alongside phone playtests.
3. Validate on-device readability/performance and proceed toward informed corruption choices as the next original system.

## Follow-up collector investigation

- Added explicit eight-case `--collector-probe`; full data and analysis in docs/qa/0.4/COLLECTOR_PROBE.md.
- All eight local runs completed with zero invariant failures. Four cautious cases exactly reproduced canonical outcome/level/XP/gap fields. All 156 system checks passed again.
- Alternate Arcstorm collector won both seeds but still stalled for 249–320 seconds; Kinetic gap changes were mixed. Collection affects outcomes, but a universal pacing improvement is not established.
- Gameplay and the verified 0.4 APK are unchanged; this checkpoint adds reproducible diagnostic tooling.

## Memory locator implementation

- Added a steady cyan player-relative arrow and distance label for uncollected memory. Queries nearest eligible packet at 4 Hz with 20% distance hysteresis; attracted/within-range packets are excluded.
- Locator is UI guidance only and does not affect simulation, XP, combat or normal-bot navigation. Its human pacing benefit is unproven.
- Reused label backing style; no per-frame style allocation. Added query regression checks and staged locator screenshot.
- Version 0.4.1 / code 6, app NULL SWARM Memory / com.nullswarm.game.memory; separate saves/install for ephemeral test signing. Verification pending.
