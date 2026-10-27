# Architecture

`main.gd` composes the run and owns explicit menu/playing/upgrading/paused/results transitions. Simulation advances only while playing; UI continues while paused. No gameplay autoloads are required.

CombatWorld owns pools, a spatial grid, spawn scheduling and fixed-tick combat. Enemy decisions are staggered at 10 Hz; movement/projectile collision runs at 60 Hz. Segment collision prevents fast shots tunneling. Pools grow rather than silently dropping gameplay spawns. Pickup coalescing preserves earned XP. Shared materials reduce resource churn. These choices require physical Android profiling; they are not a measured performance guarantee.

WeaponDefinition and EnemyDefinition Resources configure content. WeaponController owns cooldowns. RunProgression selects unique capped upgrades. HealthComponent enforces shield absorption and damage invulnerability. Signals connect combat to pickups, UI feedback, sound and results.

InputRouter merges keyboard/controller/touch movement. Camera movement and screen feedback stay separate from simulation. Graphics presets currently control damage-number effects; combat quantities remain identical.

SaveStore writes versioned JSON through a temporary file and retains a verified backup. Invalid or unsupported saves fall back to backup/defaults without crashing. Settings and completed/abandoned run totals persist. Mid-run recovery after process termination is not implemented; Android focus loss pauses and writes current saved data.

The completion test uses explicit invulnerability to isolate lifecycle and schedule correctness from bot skill. It is not evidence of balance or human survivability. Physical-device gameplay, touch feel, safe areas and performance remain acceptance gates.
