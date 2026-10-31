# Offline performance report

Settings → PERFORMANCE REPORT previews a read-only JSON record. Enable Performance stats, resume combat, then pause and open Settings again to inspect the observations. COPY REPORT writes to the system clipboard and verifies readback; unsupported platforms disable it and never claim success. Back returns to Settings without resuming play. Nothing is uploaded or sent online.

One per-run PerformanceHistory object stores at most 120 observations, no faster than every 250 ms, only while diagnostics are enabled and the game is PLAYING. Pause, upgrades, menus and results cannot add samples. The last run remains inspectable from the command menu; a new deployment clears it. History is volatile and does not alter the save schema or progression.

Each observation records a monotonic wall timestamp, positive Godot engine FPS, actual enemies/projectiles, draw-call monitor, Godot static allocation bytes, simulated run time and current effect preset. Quality 0/1/2 maps to low/medium/high. Zero startup FPS is omitted; positive readings below 1 FPS are retained. Summary min/median/max describe sampled engine FPS-window values, not individual rendered frames, frame-time percentiles, CPU/GPU timings, a time-weighted overall score or a device acceptance verdict. Gaps can include pause, upgrades, disabled diagnostics and slow frames. Static allocations are not process RSS; zero draws can indicate an unsupported monitor.

The context whitelist includes platform, non-unique model description, OS/engine versions, renderer and window/canvas dimensions. It excludes account data, device serials, save paths, salvage and backup codes. The report is a bounded snapshot; mutating exported dictionaries cannot alter stored observations. Recording changes no RNG, combat, XP, difficulty, quality setting or enemy budget.

## Tests and review

Local strict suites cover finite values, startup/slow FPS, exact sampling gate, bounded retention, correct median, snapshot ownership, context/metric whitelists, preference/state gating, actual world counters, save/RNG non-interference, retained menu history, restart, real GUI navigation and unsupported clipboard feedback. Eight new staged UI layouts bring the headless matrix to 168. Synthetic metric fixtures used for geometry are not phone measurements.

A reproducible --diagnostics-parity playtest runs seed 909/Halo/Vanguard for 180 simulated seconds with the sampler off and on. Supplied synthetic 60 FPS forces the production sampler path; it is not measured FPS. Both normal-rules cases preserve the accepted a64caa8 gameplay fingerprint, including upgrade choices, XP, enemies and outcomes, apart from excluded timing fields. Full QA includes this pair.

Android acceptance adds real report/sample inspection, clipboard write/readback and paused return checks. The read-only probe exposes the actual visible report; its TextEdit is not advertised as a progression-backup input. Desktop debug capture includes an explicitly marked synthetic report image.

Current executed counts, pending Android/render/build results, exact revisions and artifact identities are recorded in TEST_RESULTS.md. Physical S23 Ultra FPS, thermals, cutouts, human readability and final commercial UI review remain open.
