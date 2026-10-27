# Reactor Zero — 0.2 playtest

The owner confirmed the original APK runs. This iteration tests whether a more expressive arsenal, clearer encounter pacing and stronger feedback improve the experience. Fun and retention remain playtest questions.

## Build decisions

Pulse Rifle is always equipped. Three additional slots hold Plasma Orbitals, Arc Emitter, Rail Lance, Thermal Burst or Drone Hive. New weapon offers are guaranteed while eligible; acquired weapons can reach rank 5. Two rerolls are available per deployment.

- Amplified Pulse rank 3 + Arc Emitter rank 3: Arcstorm Rifle. Rifle impacts chain to two nearby enemies.
- Plasma Orbitals rank 3 + Thermal Burst rank 3: Solar Halo. Faster orbitals also radiate repeated area damage.
- 20 kills chained with no gap longer than three seconds trigger six seconds of +60% weapon fire rate. Maintaining the streak can trigger subsequent Overclocks.

The Warden arrives at 03:00 and The Architect at 09:00. Health thresholds change their attack patterns. Warning rings precede radial projectile attacks and marked artillery. Boss cores grant repair, pickup vacuum and a bonus upgrade. Extraction requires both ten minutes elapsed and a destroyed Architect; a living boss extends the encounter rather than granting automatic victory.

## Mobile delivery

This APK installs as **NULL SWARM Reactor**, package `com.nullswarm.game.slice`, alongside the original build. It deliberately keeps the already-working APK and its saved stats intact. Debug signing is currently ephemeral per workflow; a persistent protected signing configuration is still needed for future in-place updates.

## Verification boundaries

Headless tests cover all five new weapon behaviors, slot limits, mutations, Overclock, the ten-minute lifecycle and boss completion. The simulation uses invulnerability and explicit final-boss damage to test lifecycle behavior, not human survivability.

Rendered captures use a staged rank-3 loadout for visual QA under desktop Compatibility rendering. They are not phone performance measurements. The Android build uses the Mobile renderer. Physical S23 Ultra profiling and human balance testing remain required.

## Questions to answer by playing

1. Is the first new weapon acquired quickly enough to make minute one interesting?
2. Can every weapon combination clear the Warden without relying on a specific mutation?
3. Are artillery circles and radial projectile gaps readable with three active weapon effects?
4. Does Overclock reward aggressive collection without encouraging unavoidable contact damage?
5. Does the Architect feel like a satisfying climax rather than a health sponge?
