# Corruption Protocol 0.5 — first playable pass

An optional alternate level-up path unlocks at level 5. The ordinary three cards and rerolls stay available; opening the unstable-link panel consumes no RNG and returning restores the exact offered cards. Selecting a link consumes one pending level-up instead of an ordinary upgrade. The next link is available five further levels after acceptance. Each of three links can be taken once, with a hard three-link cap. A new deployment starts clean.

| Link | Gain | Advertised cost |
|---|---|---|
| Redline Sync | All weapon cooldown clocks run 30% faster, stacking multiplicatively with temporary Overclock | Maximum health falls by 20; current health is capped to the new maximum, never healed. Shields unchanged. |
| Fractured Chamber | One additional Pulse/Arcstorm rifle round per firing cycle, with its own collision and chain opportunities | Regular-enemy walking and charge movement is 15% faster. Boss movement, spawn count and telegraph duration are unchanged. |
| Parasitic Hive | One extra visible attacking escort, reaching four at drone rank 5 | Walking speed falls by 12%; ordinary dash speed/duration stay unchanged. Requires Drone Hive already equipped. |

The panel shows current/projected health, rifle interval, drone count and walking speed as applicable. Disabled cards state their prerequisite or already-linked status. Focus starts on the back button; both touch and controller can choose a card. The HUD shows link count, names and a purple meter. Corruption links remain active after ordinary upgrades and disappear on restart. No persistent progression, economy, purchase or save schema is changed.

Redline advances cooldown clocks, rather than multiplying damage or consuming extra RNG. Fracture adds a small offset second round while retaining the original aimed round. Hive adds an actual fourth pooled visual/attacking drone. Walking speed is a separate multiplier so later Servo upgrades retain the cost. The regular-enemy movement factor changes displacement only; it does not shorten warning clocks or alter boss phases. Striker lane geometry now reflects actual charge travel distance, including the movement modifier. The adaptive signature can still respond to the changed weapon mix through its normal announced rules.

`CorruptionProtocol` owns eligibility, cadence, bounded modifiers and descriptions. Main owns the paused selection transaction and HP/movement application. Combat reads the same run-local object. UI holds no entitlement or progression authority. Duplicate, unknown, unavailable, wrong-state and non-preview selection events are rejected; lethal max-HP costs are rejected defensively.

## Validation scope

Dedicated tests cover eligibility, level spacing, duplicates, limits, exact card/RNG preservation, stale input rejection, background freeze, health/shield handling, actual firing/cooldown/drone/movement effects, unchanged boss pace/warning clocks, later upgrades, HUD and fresh-run reset. Synthetic state setup isolates modifier wiring and is not a survival claim.

A separate normal-rules bot probe accepts advertised links only at legal pending-upgrade opportunities and consumes those choices. Existing clean bots decline all links and preserve their established navigation/upgrade strategy. The tests use the same effective speeds a player sees when predicting motion. Human fun, tradeoff balance, readability and phone performance still need playtesting.

Development graphics/audio remain original procedural assets, not final commercial artwork. This is the first corruption implementation, not the full planned roster or final balance.

## Verified 0.5 delivery

206 combined system/modifier checks and 504 UI checks passed in CI. Four legal-link normal sessions won, with all-links acceptance recorded across separate level gates. Existing clean bot/pickup gameplay fields matched 0.4.1 after excluding timing and new metadata. Preview/entry/HUD renders were inspected; signed APK export, hashes, archive integrity and package/module contents were verified. Full data and a separately labelled local heavy-load performance concern: [0.5 verification](qa/0.5/RESULTS.md).
