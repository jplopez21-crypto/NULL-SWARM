# Kill chains and Overclock

Each destruction keeps a chain alive for **three seconds**. Every **20 chained kills** grants or refreshes **six seconds of Overclock**, accelerating automatic weapon cycles by **60%**. This includes Engineer sentry firing; it does not increase damage per hit or change dash cooldown.

The compact HUD row has two states:

- **Cyan chain gauge:** progress through the current group of 20 kills. The text shows remaining kills and the actual time before the chain breaks. After an earlier bonus expires, a surviving chain of 25 needs 15 more kills for the next reward.
- **Green Overclock gauge:** remaining bonus time. The text shows the cycle-rate benefit and, while a chain remains alive, its count and next milestone.

Breaking a chain does **not** cancel an already earned bonus. The bonus keeps counting down independently; another completed group of 20 refreshes its six-second duration. Pause, level-up selection and Android focus loss freeze both combat clocks.

The row keeps its space to avoid moving other HUD elements when a chain begins or ends. Idle text and gauge disappear. Both controls pass touch input through. The feedback uses text plus colour, with no new flashing, shake or particle effects.

This pass exposes existing rules. Their values are shared constants in CombatWorld; damage, spawn rates, XP, RNG and reward timing are unchanged. New deployments refresh the HUD immediately so no prior reward is displayed.

Automated coverage exercises actual twentieth/fortieth destruction, duplicate-hit rejection, retained bonus after chain expiry, pause, expiry and reset. Staged layout cases cover early/near-complete chains, full/retained bonuses and later milestones with boss cues present. Android QA observes the live gauge after ordinary kills; it does not inject a chain or force a mobile Overclock activation. Exact revision-specific evidence is recorded in TEST_RESULTS.md.
