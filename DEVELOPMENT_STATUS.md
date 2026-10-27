# Development status — Foundry XP 0.3.1 / 2026-10-27

## Completed features

- Six weapons, four equipment slots, mutations, Overclock, five regular enemy types, Warden and Architect encounters.
- Foundry salvage/research/kit unlock loop with versioned saves and idempotent checkpoints.
- Fixed distant FIFO XP merging: only nearby stationary packets merge, within 3m. Older XP stays put, attracted packets are excluded, and sparse drops remain separate above a soft 300-packet budget.
- Shared packet mesh, bounded size and blue/mint/gold value tiers; updated collection guidance.
- Test-only pinned legacy fixture and separate value-aware collector retain honest A/B comparisons. Neither is included in the APK.

## Latest build — successful

- Source build commit: `604013b1cee618a9b970270feebaf0cca24b6529`.
- Android workflow: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40441583372
- APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40441583372/artifacts/12707070160
- APK: `builds/android/null-swarm-foundry-0.3.1-debug.apk`, ARM64, 27,711,129 bytes.
- SHA256: `80c24b193c178c1c6ae22d5109bfec51dfe7310d87d1173aaaf6a121dac100a9`.
- Export/signature check passed. Download ZIP/APK hashes, archive integrity, manifest package, DEX and ARM64 engine independently verified locally.
- Menu capture inspected at 1280x720; game art/audio remain development assets.

## Test results

- QA workflow: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40441583251 — success.
- 130 system checks passed, including 80m legacy relocation reproduction, 3m merge bound, conservation, sparse soft-budget behavior, attraction/vacuum and pooled visual reset.
- Eight unchanged-cautious-policy normal bot cases: seven victories, one defeat. Seeded replay matched. These use normal combat rules, not injected invulnerability or forced boss kills.
- Six XP A/B/collector cases passed invariants and pinned-baseline checks; all six CI gameplay traces matched local results after timing fields were excluded.
- Cautious seed 101: legacy defeat/level24/3,045 collected XP → local victory/level54/14,864 XP.
- Cautious seed 202: legacy victory/level54/14,769 XP → local defeat/level31/4,935 XP. The separate value-aware collector won both local-merge seeds. This is a navigation finding, not a universal difficulty improvement.
- Old replay merge distances reached 48.26m; new comparisons stayed below 3m. Cautious fixed-case pickup peaks were 314–315; full matrix maximum was 318.
- Six synthetic stress scenarios retained their loads and matched selected gameplay fingerprints across low/high effects. 600 enemies/400 peak shots: p95 CPU simulation 23.719ms low / 24.200ms high on the reported CI host. This excludes rendering and is not Android FPS.
- Versioned canonical reports: docs/qa/0.3.1. QA report ZIP digest/integrity verified locally.

## Known bugs / limits / work in progress

- Owner reported earlier APKs working; 0.3.1 phone installation, packet readability and rendering performance have not been tested here.
- Cautious bot still stalls on collection in some runs; do not change combat balance solely to make it win.
- New app is NULL SWARM Foundry XP, package com.nullswarm.game.foundry.xp. It installs alongside prior test apps; Android-private saves remain separate.
- Stable protected signing remains unconfigured; ephemeral debug keys do not support reliable in-place updates. No private keys are committed.
- Active combat does not resume after process death; previously checkpointed currency/settings persist.
- Earlier CI runs intermittently reported shutdown leaks; current build/QA logs had no such warning. Virtual-display V-Sync warning remains unrelated to measured phone performance.
- Final commercial art, adaptive swarm/corruption expansion, full content roster, physical profiling and release preparation remain unfinished.

## Next development priorities

1. Validate gold-packet readability and soft-budget rendering cost on S23 Ultra.
2. Broaden collection-policy/seed comparisons before tuning weapons or progression.
3. Establish protected persistent signing before production updates and continue performance work using physical measurements.
