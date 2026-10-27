# Continuing regression results — 2026-10-27

Tested commit: `419ad1387fcecebc6b30cde3aae4e8dec19afdf6`.

[Successful QA run](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40500767947) / [reports, logs and 32 viewport captures](https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40500767947/artifacts/12733281314).

- 165 system checks passed; Android build gate and scene smoke passed again.
- 352 UI checks / 32 staged screen states passed in local headless testing and CI software OpenGL. Menu, settings, combat, adaptation warning, pause, upgrade selection, results and Foundry tested across four requested window sizes.
- Pause/focus loss reset touch/dash; paused time freezes; modal screens hide the memory cue; resume reacquires it; restarting clears old packet references.
- Ten established bot runs and six pickup comparisons exactly match canonical 0.4.1 case fields after excluding wall/step timings. The 180-second deterministic replay passed.
- Six additional fixed-seed sessions completed without invariant failures: five victories, one defeat. Combined normal-bot matrix: 12 victories / 4 defeats, not a human balance verdict.
- Six synthetic stress scenarios passed fixed-load and low/high gameplay parity checks. Timings exclude UI/rendering and do not predict Android FPS.

## Additional cases

| Seed | Build | Kit | Outcome | Seconds | Level | Longest upgrade gap |
|---:|---|---|---|---:|---:|---:|
| 303 | halo | vanguard | defeat | 114.15 | 10 | 22.33s |
| 303 | arcstorm | vanguard | victory | 600.02 | 56 | 290.75s |
| 404 | kinetic | vanguard | victory | 600.02 | 56 | 201.79s |
| 404 | electric | vanguard | victory | 600.02 | 54 | 50.02s |
| 505 | electric | conductor | victory | 637.57 | 53 | 37.85s |
| 505 | halo | sentinel | victory | 602.03 | 54 | 27.12s |

Halo/Vanguard seed 303 dies at 114.15 seconds, before first adaptation at 120 seconds; this particular loss cannot be attributed to an active adaptive formation. Cautious geometric collection and close-range build biases remain limitations. Late victories require actually defeating the Architect; there are no forced kills or injected immunity in these normal-rule runs.

## Window/capture limits

The requested window sizes are verified independently from logical canvas size. Current KEEP scaling preserves the 1280×720 logical canvas at all four ratios. Viewport PNGs omit outer letterbox bars: 1280×720 captures for larger windows, 960×540 for the 960×600 window. These are not four responsive-canvas layouts or Android cutout tests. Representative menu, small-window upgrade, tablet-window combat and settings captures were visually inspected. Full UI report records every requested/observed window and canvas size.

## Unattended regression

Daily CI is configured at 03:23 UTC with 14-day report/screenshot retention, in addition to push/PR/manual runs. GitHub can delay scheduled starts. No background chat process or phone hardware is involved. No gameplay, save format or installed APK changed in this QA checkpoint.
