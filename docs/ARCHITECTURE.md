# Architecture

`main.gd` composes the run and owns explicit menu/playing/upgrading/paused/results transitions. Simulation advances only while playing; UI continues while paused. No gameplay autoloads are required.

CombatWorld owns pools, a spatial grid, spawn scheduling and fixed-tick combat. Enemy decisions are staggered at 10 Hz; movement/projectile collision runs at 60 Hz. Segment collision prevents fast shots tunneling. Pools grow rather than silently dropping gameplay spawns. Pickup coalescing preserves earned XP. Shared materials reduce resource churn. These choices require physical Android profiling; they are not a measured performance guarantee.

WeaponDefinition and EnemyDefinition Resources configure content. WeaponController owns cooldowns. RunProgression selects unique capped upgrades. HealthComponent enforces shield absorption and damage invulnerability. Signals connect combat to pickups, UI feedback, sound and results.

InputRouter merges keyboard/controller/touch movement. Camera movement and screen feedback stay separate from simulation. Graphics presets currently control damage-number effects; combat quantities remain identical.

SaveStore writes versioned JSON through a temporary file and retains a verified backup. Invalid or unsupported saves fall back to backup/defaults without crashing. Settings and completed/abandoned run totals persist. Mid-run recovery after process termination is not implemented; Android focus loss pauses and writes current saved data.

The completion test uses explicit invulnerability to isolate lifecycle and schedule correctness from bot skill. It is not evidence of balance or human survivability. Physical-device gameplay, touch feel, safe areas and performance remain acceptance gates.

The pause build guide queries `Arsenal.MUTATIONS`, current ranks and active combat mutations without updating the build. Slot feasibility counts all missing weapon prerequisites against remaining slots; passive ranks consume no slot. Main only opens it in the paused state. Its GUI lifecycle follows the existing deferred panel retirement, and opt-in Android telemetry reads actual visible labels for touchscreen acceptance.

## Foundry progression

Engineer adds a fourth earned starting kit. `Research.apply` enables one `FieldSentry` on its fresh combat world; other kits allocate no sentry model. Main deploys it only when `SwarmPlayer.tick` accepts a dash, using the pre-move position. CombatWorld ticks it through the same paused simulation gate and damage/spatial/effect systems as other weapons. It has independent bounded lifetime/cooldown and reuses its model on refresh. No save schema change is needed: existing Architect milestones unlock the new kit and current v2 validation already checks earned selections.

Research describes capped upgrades and starting-kit sidegrades independently of combat. SaveStore v2 migrates v1 data and owns the tokenized salvage ledger. Checkpoints award only the positive difference from the already-banked total; settlement closes a token once. Purchases persist immediately with in-memory rollback on write failure. Main composes research at deployment and checkpoints periodically and at lifecycle/encounter boundaries. Combat damage attribution records actual HP removed, excluding overkill; it is displayed in results and performs no online telemetry.

## Memory guidance

`PickupSystem.memory_target` is a read-only horizontal-distance query over stationary packets outside attraction range. `GameUI.update_memory` calls it at most four times per rendered second, with target-distance hysteresis. The UI projects the world direction into a player-relative chevron and distance label. It owns no collection or progression behavior, consumes no gameplay RNG and pauses/hides behind modal screens. The normal-rules bots retain their own unchanged navigation; bot outcome parity can validate simulation isolation, not whether humans find this cue helpful. Synthetic combat timing excludes this rendering/UI path.
