# Deployment build guide

During a deployment, open **Pause → Build // Mutations**. Combat remains paused. **Back to pause** returns to the pause menu; **Resume** continues the run. The pause shortcut also resumes directly, matching the other pause screens.

The left column shows the four weapon slots with actual equipped names and ranks. Pulse's separate Amplified Pulse rank is named explicitly. Evolved weapons keep their original slot; mutations do not remove the other prerequisite weapon.

The right column reads all recipes from `Arsenal.MUTATIONS`:

| Mutation | Requirements |
| --- | --- |
| Arcstorm Rifle | Amplified Pulse 3 + Arc Emitter 3 |
| Solar Halo | Plasma Orbitals 3 + Thermal Burst 3 |
| Singularity Lance | Rail Lance 3 + Memory Tether 3 |

Ranks are current/required, so `2/3` means one more rank is needed. **Active** reflects the combat system's actual active mutations. **In progress** means more ranks are needed. **Slots blocked** means the missing prerequisite weapons no longer all fit: Solar Halo needs two empty slots if neither of its weapons is owned, even if one slot remains. There is no weapon replacement during this run. Upgrading an already equipped weapon or a passive uses no additional slot.

The guide is read-only. It spends no rerolls, chooses no upgrades, activates no mutations, changes no save data and consumes no gameplay RNG. Closing and reopening reads the current build. This screen explains available content; it does not add new recipes or change combat balance. Graphics presets and reduced-flash settings remain in Settings.
