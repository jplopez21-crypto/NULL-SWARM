# Development status — Corruption Protocol 0.5 / 2026-10-27

## Completed features

- Ten-minute offline run, six weapons/four slots, ranked upgrades, two mutations, Warden/Architect, gated extraction/results, touch/controller/keyboard input.
- Foundry research, three starting kits, checkpointed salvage and versioned local save/backup recovery.
- Local XP packet merging with 3m relocation limit, visible value tiers and steady player-relative memory locator.
- Adaptive Swarm: first analysis 02:00, eight-second warnings, 45-second formations, capped 20% composition bias, boss quiet windows and reset. Amber Insulators resist electricity by 20%.
- Corruption: optional level-up alternative from level 5; exact ordinary-card/RNG preservation on decline, consumes one pending upgrade on acceptance, five-level spacing, three one-time links, all costs reset per deployment.
- Redline: +30% all weapon cycle rate / -20 max HP. Fracture: extra Pulse/Arcstorm round / +15% regular walking/charge pace. Hive: extra actual drone / -12% walking, requires Drone Hive. Dash/boss/warning clocks unchanged; charge lanes reflect travel distance.
- Projected power/cost panels, prerequisite/duplicate guards, purple HUD meter/names, bounded modifiers and clean-run reset.
- Pooled combat, staggered AI, quality settings, performance overlay and original procedural art/audio; development assets remain unfinished commercial art.

## Tests and latest build

- Gameplay commit 4ee60487877978c58a5f8dc48d670a5eb399a89e.
- Android workflow 40504064445 and QA workflow 40504064446 succeeded. 165 established + 41 corruption checks (206 total), scene smoke, signed export, 504 UI checks/44 captures, 20 normal-policy sessions, deterministic replay, six pickup comparisons and six clean stress scenarios passed invariants.
- Clean case fields match 0.4.1 excluding timings/new corruption telemetry. Four legal-link probes won; combined 20-case matrix retains 16 wins/4 losses. Not a human balance verdict.
- New local all-links stress fixture 3: six scenarios passed, four-drone/three-link/250-pickup floor and low/high gameplay parity asserted. Added command to daily QA; its first CI execution is pending.
- APK ZIP: https://github.com/jplopez21-crypto/NULL-SWARM/actions/runs/40504064445/artifacts/12734700412
- Extract android/null-swarm-corruption-0.5-debug.apk. CI signature verification and independently downloaded hashes/archive checks passed; package/runtime/compiled module contents checked. Preview/entry/HUD/small-window renders inspected.
- App NULL SWARM Corruption / com.nullswarm.game.corruption, version 0.5.0/code 7. Earlier installs/private saves remain separate while stable protected signing is unconfigured.
- Canonical CI and labelled local reports: docs/qa/0.5/RESULTS.md. Daily QA remains scheduled at 03:23 UTC, 14-day QA artifact retention; GitHub can delay starts.

## Known limitations / unfinished work

- All-links synthetic 600-enemy local p95 CPU time ~36.6–38.4ms, excluding rendering/UI/thermals. This needs investigation; Android 30/60 FPS targets are not verified. Normal corruption bot cases peaked at 36–59 enemies, so they do not cover that extreme.
- Phone readability, real touch/safe areas, process-death handling, performance and human tradeoff balance remain unmeasured for this version.
- Corruption is run-local and not restored after process death, like current run equipment; permanent progression is checkpointed. No save schema or entitlement changes.
- Bot navigation is cautious/geometry-based; collection gaps and close-range build bias persist. Existing Insulators keep inherent resistance after formation expiry.
- Full roster/content, final art/audio, accessibility/balance polish, persistent release signing/AAB and Play release preparation remain unfinished.

## Next priorities

1. Profile/optimize targeting and chain-query CPU work under all-links stress without changing gameplay quantities or outcomes.
2. Inspect collection-rate/distance gaps and validate guidance/corruption readability in real play.
3. Broaden build/seed coverage and character differentiation after performance and balance evidence.
