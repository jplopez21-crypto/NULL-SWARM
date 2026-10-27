# Upgrade-gap investigation — 2026-10-27

Eight normal-rules local simulations; only collector navigation differs. Both collectors use the same offered-upgrade priorities, combat, local pickup merging and fresh Vanguard stats. All invariants passed. Cautious cases reproduced the canonical 0.4 outcomes, levels, XP totals and longest gaps exactly.

| Build | Seed | Collector | Result | Level | XP collected | XP left | Longest gap |
|---|---:|---|---|---:|---:|---:|---:|
| arcstorm | 101 | cautious | defeat | 23 | 2837 | 9916 | 319.45s |
| arcstorm | 101 | value_aware | victory | 56 | 16233 | 99 | 319.55s |
| arcstorm | 202 | cautious | defeat | 24 | 2954 | 9980 | 317.80s |
| arcstorm | 202 | value_aware | victory | 56 | 16152 | 171 | 249.50s |
| kinetic | 101 | cautious | victory | 56 | 15927 | 132 | 215.43s |
| kinetic | 101 | value_aware | victory | 56 | 16400 | 78 | 113.44s |
| kinetic | 202 | cautious | victory | 57 | 16440 | 257 | 204.16s |
| kinetic | 202 | value_aware | victory | 57 | 16486 | 85 | 204.78s |

The cautious Arcstorm bot leaves roughly 10,000 XP behind and loses. The alternate navigation collects most drops and wins both seeds, showing collection policy materially changes these outcomes. Long upgrade gaps nevertheless remain (249–320 seconds). Kinetic improves in one seed and has a similar gap in the other. This evidence does not support a universal pacing fix or weapon buff.

Existing boss-core recovery vacuums pickups and grants a bonus upgrade, so late level bursts are part of the current reward loop; long pre-recovery stalls deserve further investigation. Both bots limit pickup sensing to 16m and use privileged geometric enemy sensors. A human can behave differently. These are two fixed seeds, not human balance or fun measurements.

Next experiment: record player-to-pickup distances and collection rates during stalled intervals, then evaluate a visible memory-location cue or explicit recovery opportunity. Keep the established matrix unchanged when assessing a gameplay change. No installed gameplay, economy, save data or APK changed in this investigation.

Reproduce: `godot --headless --script tests/run_playtests.gd -- --collector-probe` with isolated XDG directories. Full data: [collector-probe.json](collector-probe.json).
