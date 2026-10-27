# Foundry 0.3 — progression and combat feedback

The owner confirmed Reactor Zero 0.2 works on their device. This iteration adds a bounded reason to replay and instruments build damage before broader balance changes.

## Salvage and research

A run earns one salvage per 45 seconds (up to 900 seconds), one per 20 kills, eight for the Warden, twenty for the Architect and fifteen for victory. Defeat and intentional withdrawal retain earned salvage. Empty restarts earn nothing. A tokenized ledger checkpoints every thirty seconds, on pause/backgrounding, at boss recovery and at results. Repeating or replaying a checkpoint cannot duplicate rewards. Previously banked salvage survives a process interruption; the active combat scene itself does not resume after process death.

Research has small caps:

- Chassis: +5 HP per rank, three ranks, costs 8/16/24.
- Tether: +0.25m attraction per rank, three ranks, costs 8/16/24.
- Logistics: one extra reroll, one rank, cost 12.

Purchases write immediately; failed writes refund the wallet and rank in memory and report failure. Version 1 saves migrate to version 2, keeping settings/statistics and crediting historical kills toward kit requirements. Migration grants no invented currency or purchases. Corrupt data still falls back to a verified backup.

## Starting kit unlocks

All six weapon choices remain available; these are starting-loadout sidegrades, not gates on the existing arsenal.

- Vanguard: balanced rifle, 100 HP, speed 7, one slot occupied.
- Conductor: 150 lifetime kills. Starts Arc Emitter plus a weaker/slower rifle, 85 HP, two slots occupied.
- Sentinel: defeat the Warden. Starts orbitals plus a weaker/slower rifle, 110 HP, speed 6.5, two slots occupied.

Research modifies the selected kit; maximum research adds only 15 HP, 0.75m attraction and one reroll. New kit notifications appear during checkpointing and on results when earned in that run.

## Feedback and balance

- Pooled debris augments destruction; fewer debris pieces render at low quality, and reduced flashes suppress debris/sparks. Cosmetic quality never changes combat quantities or damage.
- Boss phase changes cancel pending attacks and expose the core for 1.2 seconds: the boss stops moving and receives +25% damage, with a HUD countdown.
- Damage totals are attributed to each weapon/mutation and exclude overkill and dead targets. Results show the three largest contributors. These are player-visible telemetry, not claims of perfect balance.
- Solar Halo's repeated area pulse changes from 45% to 35% of orbital damage; orbitals themselves are unchanged. Physical playtests must validate this narrow adjustment.
- Lethal contact damage stops the combat tick before further friendly damage can alter already-recorded results.

## Delivery and limits

This debug build installs separately as **NULL SWARM Foundry** (`com.nullswarm.game.foundry`). Earlier test APKs and their saves are untouched. Their signing keys were ephemeral CI keys, so this new package cannot migrate their Android-private save files automatically. Stable protected signing is still required for future in-place upgrades; no signing credentials are committed.

CI captures are staged desktop Compatibility renders for layout/readability checks. The Android build uses Mobile rendering. The ten-minute test harness uses invulnerability and explicit boss damage for lifecycle validation, not a human difficulty evaluation. Physical-device profiling and playtesting of this version remain outstanding.
