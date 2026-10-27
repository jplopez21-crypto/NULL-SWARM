# Development status — Corruption Protocol 0.5 / 2026-10-27

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

## Continuing test expansion

- Added a dedicated UI lifecycle/window suite: 352 local checks across 32 staged screen states passed. Physical window sizes are verified separately from the unchanged KEEP-scaled 1280×720 canvas.
- Added pause/focus/upgrade/results guidance checks, touch/dash reset and restart cleanup.
- CI 40500767947 passed: 352 UI checks/32 captures, six additional normal-rules sessions (five victories/one early Halo defeat), existing ten-case matrix/replay, six pickup comparisons and six stress scenarios.
- Existing bot/pickup case fields exactly match 0.4.1 excluding timings. Representative viewport captures inspected; they omit letterbox bars. Reports: docs/qa/0.4.1/followup/RESULTS.md.
- Daily unattended QA scheduled at 03:23 UTC, 14-day artifact retention. GitHub may delay starts; this is CI automation, not a background chat process.
- These additions change QA tooling only. The verified 0.4.1 APK remains the current gameplay build.

## Corruption 0.5 implementation / verification in progress

- Optional corruption panel from level 5, preserves ordinary cards and RNG on return; accepting consumes one pending upgrade. Five-level spacing, three unique links maximum, all costs end on restart.
- Redline: +30% weapon cycle rate / -20 max HP; Fracture: +1 Pulse/Arcstorm round / +15% regular-enemy walking/charge pace; Hive: +1 actual drone / -12% walking speed, requires Drone Hive. Boss/warning clocks and normal dash are unchanged.
- Added projected previews, disabled prerequisites, purple HUD meter/names, dedicated selection guards and actual modifier wiring. Striker lanes reflect charge travel distance.
- Local 165 established system checks, dedicated corruption checks and expanded 504-check/44-layout UI suite passed during development. Four preliminary legal-link bot probes won; final CI with effective-speed-aware sensors is pending.
- App NULL SWARM Corruption / com.nullswarm.game.corruption, version 0.5.0/code 7, separate from prior installs. Android build, rendered panels, canonical clean-run comparison and expanded scheduled QA pending.
