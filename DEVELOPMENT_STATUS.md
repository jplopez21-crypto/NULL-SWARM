# Development status — Memory locator 0.4.1 / 2026-10-27

## Completed features

- Ten-minute offline run, six weapons/four slots, ranked upgrades, two mutations, Warden/Architect, extraction/results, touch/controller/keyboard input.
- Foundry research, three starting kits, checkpointed salvage, versioned local save/backup recovery.
- Local memory-packet merging preserves XP and limits relocation to 3m; larger packets have mint/gold value tiers.
- Adaptive Swarm: first analysis 02:00, eight-second warnings, 45-second formations, capped 20% composition bias, boss quiet windows and restart reset. Amber Insulators resist Arc/Arcstorm by 20%; other families hit normally.
- Six-phase AI distribution per archetype, pooled combat, original procedural art/audio, quality presets and performance overlay.
- New 0.4.1 steady player-relative memory direction/distance cue: four queries per second, 20% target hysteresis, no collection/stat/RNG changes. Hidden behind modal screens, ignored in-flight/within-range packets, reset on deployment.

## Verification and latest build

- Local and Android CI: 165 system checks passed with zero failures, including nine locator cases.
- Android import, scene smoke, staged captures, debug export and apksigner verification passed for commit 2ed509490f70fe9bf6568ff024be6e8e81ef7e0a.
- Workflow: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40496218606
- APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40496218606/artifacts/12730444055
- Downloaded ZIP/APK hashes and archive integrity checked independently. ARM64/DEX/compiled resources and Memory package verified; test fixtures excluded. Locator capture visually inspected.
- QA workflow 40496218604 succeeded: ten normal bot cases, 180-second deterministic replay, six pickup comparisons and six stress scenarios. All non-timing gameplay fields in ten bot/six pickup cases exactly match canonical 0.4. Seven normal bot victories/three defeats retained.
- Canonical JSON/Markdown and APK verification metadata archived under docs/qa/0.4.1/. Synthetic low/high gameplay parity passed.

## Recorded investigation

Eight local collector comparisons passed all invariants and reproduced four cautious 0.4 baselines exactly. Alternate navigation turned both Arcstorm defeats into wins, yet 249–320-second gaps persisted; Kinetic gap changes were mixed. Full data and limits: docs/qa/0.4/COLLECTOR_PROBE.md. The cue’s human pacing benefit is a hypothesis, not a proven result.

## Known limitations / in progress

- No physical-device performance, thermals, aspect-ratio/cutout coverage or human balance measurement for this version. Synthetic CPU benchmarks exclude rendering and locator UI work.
- Bot sensing/navigation differs from human play; deaths and upgrade stalls remain observations. No universal weapon buff or difficulty reduction was justified by the collector investigation.
- Test app NULL SWARM Memory, package com.nullswarm.game.memory, version 0.4.1/code 6. Earlier apps and saves remain separate while stable protected signing is unconfigured.
- Existing Insulators keep their inherent resistance after formation expiry; expiry affects future composition.
- Development geometry/audio are original but not final commercial assets. Corruption, full roster/content, final art/audio, release signing/AAB and commercial polish remain unfinished.

## Next priorities

1. Investigate collection-rate/distance telemetry during stalled intervals if phone playtests confirm confusion.
2. Validate memory cue readability and collection pacing on a phone; inspect pickup distances/rates during stalled intervals.
3. Implement informed corruption choices with explicit power/risk previews, capped modifiers and save-safe integration.
