# Development status — Foundry 0.3 / 2026-10-27

## Confirmed baseline

The owner reports that Milestone 1 and Reactor Zero 0.2 APKs work on their Android device. This is not a measured frame-rate or balance result.

## Completed in 0.3

- Salvage earned from survival, kills, bosses and victory; defeat retains earned salvage.
- Checkpoint ledger every 30 seconds and on pause/background/core recovery/results; repeated checkpoints/settlement cannot duplicate rewards.
- Foundry research: bounded HP, attraction and reroll upgrades, with immediate purchase persistence and failure rollback.
- Conductor and Sentinel starting-kit unlocks with explicit tradeoffs; Vanguard remains available.
- Version 1 → 2 save migration, existing backup recovery, results/unlock feedback.
- Pooled destruction debris, brief exposed boss cores and exact per-weapon damage totals on results.
- Narrow Solar Halo area-pulse adjustment and corrected Overclock threshold HUD copy.

## Verification

- Local automated suite: 121 checks passed, zero failures.
- Includes migration, corruption recovery, checkpoint/settlement idempotency, currency/purchase/rank caps, failed-write refund, kit unlocks/tradeoffs, damage attribution and exposed-core bonus, plus the ten-minute lifecycle.
- Scene smoke passed during development. Final CI export/captures are pending.
- Lifecycle harness uses invulnerability and explicit boss damage; human survivability and balance are unverified.

## Delivery / known limitations

- New package: com.nullswarm.game.foundry, display name NULL SWARM Foundry, installs alongside older test APKs.
- Ephemeral debug signing still prevents reliable in-place test updates. Stable protected signing must be configured before production upgrades; no keys/passwords are committed.
- Android-private saves in older differently signed packages cannot be automatically transferred by this new package.
- Currency already checkpointed persists after interruption, but the active combat run does not resume after process death.
- Procedural artwork/generated audio remain development assets. Android performance and reduced-effects readability require physical validation.
- Previous CI smoke runs reported an intermittent ObjectDB shutdown warning; investigate before commercial acceptance.
- Adaptive swarm/corruption, full permanent-progression content, final art and commercial release work remain deferred.

## Next priorities

1. Inspect Foundry/results renders and verify a signed debug APK.
2. Playtest earning/spending salvage, starting kit tradeoffs, Halo adjustment and core-exposure feedback on Android.
3. Use damage reports and physical frame-time measurements to guide further balance/performance work.
