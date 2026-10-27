# Adaptive Swarm 0.4 — first playable implementation

This pass implements a bounded run-local adaptive composition system. It changes future enemy types, not the base spawn schedule or existing enemies' statistics. It is not the complete commercial content/AI roster.

## What the player sees

The first analysis occurs at 02:00, then approximately every minute. A persistent HUD line and a sound/text announcement give eight full gameplay seconds of warning. For 45 seconds afterward, 20% of regular spawn decisions are biased toward a named formation. Remaining decisions use the normal distribution. A mixed build or insufficient evidence may produce no response. Existing units retain their inherent properties after the formation window ends.

- Direct fire dominates: more Bulwarks. Piercing and area coverage help with armored crowds.
- Electrical damage dominates: amber-core Insulators. They resist Arc Emitter/Arcstorm chain damage by 20%; other weapon families hit normally. They are never electrically immune.
- Close-range damage dominates: more evasive Skimmers; ranged coverage helps.
- Prolonged stationary fire: more violet Sentries; move out of their firing lanes.

No new adaptation warning starts during a live boss encounter, around the Warden introduction or in the final approach to the Architect. Pausing or backgrounding pauses the gameplay clock and warning timer. Each deployment resets the signature; permanent progression does not create cross-run punishment.

## Evidence and implementation

A bounded roughly 45-second window samples actual HP damage by weapon and player displacement. At least 20 seconds and 400 damage are required. Stationary share >=70% takes precedence; otherwise electrical >=50%, close-range >=45% or direct-fire >=65% selects a response. Below those thresholds there is no forced counter. Samples update about twice a second, not independently per enemy.

Composition selection uses the existing single spawn RNG draw, with a capped bias and a renormalized normal distribution. Spawn counts/debt/intervals are untouched; stronger or faster compositions can still change combat pressure. Boss summoning remains its separate existing system. Enemy pools grow instead of dropping scheduled spawns. Independent per-archetype phase cursors spread AI decisions across six batches, preserving each unit’s update frequency without synchronizing a whole enemy type. Insulator resistance is a data resource property and actual damage attribution records the reduced HP damage.

## Validation and limits

Local system checks cover signature classification, insufficient evidence, mixed builds, no early adaptation, warning delay, activation/expiry, boss windows, bounded samples, spawn-count/RNG-draw invariants, pause/reset and actual resistance behavior.

Verified CI passed 156 checks and ten normal-rules bot cases: seven victories and three defeats (one early Halo Vanguard loss, two late Arcstorm Vanguard losses). Electric Vanguard won both seeds and Conductor won; the matrix recorded 1,140 resisted hits, 17 Insulator warnings and 36 Bulwark warnings. This shows viable tested electrical builds under resistance, not universal human balance. Long upgrade gaps in Arcstorm and Kinetic cases remain explicit collector/path investigation leads. Full canonical reports live in `docs/qa/0.4/`.

The replay check extends to 180 seconds to cover the first response. The stress fixture now uses all six regular archetypes (fixture version 2); its timing baseline is not directly comparable to the old five-type mix. Legacy pickup A/B numeric comparisons correctly skip when combat-source hashes no longer match Foundry 0.3, while current-game A/B/conservation tests still run.

Warning/active captures use deliberately staged presentation fixtures and clock setup; they do not represent a real first-seconds run. Phone readability, difficulty and rendering performance still require physical playtesting.

## Delivery

The debug app installs separately as **NULL SWARM Adaptive**, package `com.nullswarm.game.adaptive`, because prior CI signing keys were ephemeral. Prior apps/saves remain intact and separate. Stable protected signing remains a production update prerequisite; no private keys are committed.
