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
- Final GitHub Actions run passed all 121 checks, scene smoke, rendered captures, Android debug export and APK signature verification.
- Inspected menu, Foundry and results captures: controls/requirements/costs and damage/salvage totals are visible.
- Downloaded artifact/APK digests and archive integrity independently verified locally.
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

1. Playtest earning/spending salvage, starting kit tradeoffs, Halo adjustment and core-exposure feedback on Android.
2. Use damage reports and physical frame-time measurements to guide further balance/performance work.

## Verified APK

- Workflow: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40435364064
- Download: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40435364064/artifacts/12703736664
- Build commit: `82a45e9a6649807af819b8a3fe4bdc1fa2656d32`.
- APK: `builds/android/null-swarm-foundry-0.3-debug.apk`, ARM64, 27,711,129 bytes.
- SHA256: `e1fa5e937ebd073fc4b16dc7ddf80803a80bdd2c301b09788e58cbf508e2eefc`.
- CI rendered capture still reported an ObjectDB shutdown warning and unsupported V-Sync setting on the virtual display. The pipeline passed; these are not physical-device performance measurements.
- 0.3 installation, progression pacing and combat balance await owner playtesting.

## Repeatable gameplay QA — verified in CI

- Added normal-rules bot playtests: three strategies × two seeds on fresh Vanguard, plus Conductor/Sentinel earned-kit fixtures, all without research.
- Local eight-case matrix: seven victories, one Kinetic/Vanguard defeat at 511.05s. A 90-second seeded replay matched exactly; no invariant failures.
- Fresh Vanguard acquired its first additional weapon in approximately 11–16s.
- Kinetic seed 101 collected 3,045 XP and left 7,505 XP uncollected; investigate bot collection path/progression before changing weapon balance.
- Local synthetic benchmark completed six low/high scenarios at 100/300/600 enemies, retaining the requested loads and identical gameplay fingerprints across effect qualities.
- Sequential CI benchmark completed: 600 enemies/400 peak shots measured p95 CPU simulation steps of 22.611ms low and 22.444ms high on the reported CI host. No Android FPS claim is made.
- Dedicated QA workflow now runs on pushes/PRs/manual dispatch and uploads reports. No unattended calendar schedule was configured.
- No gameplay changes or new APK are needed for these test tools; phone input/rendering/thermals and human enjoyment still require device playtesting.

### QA delivery

- Workflow https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40437672314 succeeded: 121 system checks, eight normal-rules bot scenarios plus repeatability pair, six synthetic stress scenarios.
- All eight CI gameplay outcomes/traces matched local results, excluding timing fields.
- Report artifact: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40437672314/artifacts/12705035805 — ZIP digest/integrity verified locally.
- Canonical report snapshots and methods are in docs/qa and docs/AUTOMATED_QA.md.
- Android regression build also passed: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40437670838. The earlier 0.3 artifact remains the installed-game reference; gameplay was not changed by this QA pass.

## 0.3.1 pickup investigation — local checks passed, CI pending

- Confirmed FIFO merging could move old XP 80m in a regression fixture and up to 48.26m in the original Kinetic seed-101 replay.
- Local merging preserves existing packet locations, moves newly merged XP at most 3m, skips attracted/in-flight packets, and conserves all XP. A soft 300-packet budget permits sparse drops rather than teleporting them.
- Shared packet geometry and bounded blue/mint/gold value visuals implemented.
- 130 system checks passed; six local A/B/collector scenarios passed invariants and reproduced the old numeric baseline.
- Cautious bot: seed 101 changed from defeat/level24 to victory/level54; seed 202 changed from victory/level54 to defeat/level31.
- Separately labelled value-aware test collector won both local-merge seeds. No combat buffs or bot-policy substitution are hidden in the A/B.
- Local packet peaks were 314–315 for the cautious-bot fixed cases, versus the old 300. Physical rendering cost remains unmeasured.
- Full updated bot matrix, synthetic benchmark, visual captures and signed debug APK are pending CI.
- New test package is com.nullswarm.game.foundry.xp (NULL SWARM Foundry XP) to avoid signature conflicts and preserve existing installs; Android-private saves remain separate until stable protected signing is configured.
