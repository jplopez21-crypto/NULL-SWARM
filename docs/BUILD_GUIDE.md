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

## Upgrade card previews

A gold **MUTATES: weapon name** line means that choosing this card completes a mutation recipe. It uses the card's existing blank line, and normal cards keep their usual appearance. Gold persists when focused or pressed; the cyan outline still marks controller focus. The preview checks current ranks and slot eligibility; already completed or active recipes receive no new badge.

Previewing spends nothing and does not activate the weapon. The normal upgrade choice still applies one rank, consumes one pending choice and activates any completed mutation through the existing combat system. Rerolling and returning from corruption recompute previews without changing offered choices or consuming extra RNG. All recipes come from the same Arsenal registry used by combat. Current tests, synthetic capture scope and APK: TEST_RESULTS.md.

Verified mutation-preview source c6836def022cb5dd80e49293f7b3368230e732fd passes all 15 strict suites, 176 rendered layouts, ordinary Android controls/progression acceptance and full QA. Final labelled native cards were inspected. Near-completion rank fixtures are synthetic, not an earned-on-device mutation claim; physical readability/fun remains open. Exact source/artifacts and initial focus-color review: TEST_RESULTS.md and qa/mutation-cards/verified-ci.json.

## After deployment

After defeat, victory or **Pause → End Deployment**, choose **Run Analysis**. Voluntary endings show **Deployment Ended**; banked rewards are recorded once and redeploy clears the end reason. The report lists each recorded damage channel, sorted by effective damage, with its percentage of all valid damage and the run's actual equipped names/ranks and corruption links. Pulse Shots excludes Arcstorm Chains; Solar Halo Heat excludes orbital contact; Drone Systems combines Drone Hive and the Engineer's field sentry. Singularity Lance combines its beam and gravity-field damage. Support, slows and shields are not measured, so damage alone does not rank a weapon's overall usefulness.

The six current channels fit the standard report. Longer reports support touch swiping, mouse wheel, D-pad scrolling while the scrollbar is focused, and keyboard navigation. Controller B or Escape returns to Results from either focus target. **Back to Results** leaves combat and rewards unchanged. No historical report is persisted after redeploying or returning to Command. Current test scope and verified APK: TEST_RESULTS.md. An independent exported-assets interaction check is reproducible with `python3 docs/qa/run-analysis/check_exported_analysis.py path/to.apk --output receipt.json`; it uses isolated data and no source/test resources. This is a headless desktop fixture, not an Android earned-run or physical-performance check.


## Isolated surface recovery experiment

`.github/workflows/android-surface-investigation.yml` builds pinned Godot 4.6.3 Java control/latched variants on pull requests touching the experiment or runtime driver, or by manual workflow dispatch. It requires Java 21, Android 35 and official source templates. The rebuild tool compiles against android.jar **and unchanged official classes.jar**, runs controlled-field Java assertions, and refuses source drift/class-set mismatch or unrelated archive changes before replacing the disposable AAR.

Both variants run eighteen real emulator Home/return cycles. A control recovery failure with Surface warnings is retained as a failed driver observation; collection success must not be read as recovery success. Unexpected control failures fail collection. Candidate recovery and all 58 ordinary gameplay/save/update checks are strict gates. Diagnostic packages are `com.nullswarm.game.surfacecontrol` and `com.nullswarm.game.surfacelatched`, x86_64 Compatibility only. Do not install these on the ARM64 S23. Standard ARM64 exports continue using official engine templates; this experiment is not yet a production integration. See TEST_RESULTS.md for verified source, failed official gates and artifact paths.


## Development debug exports with the surface repair

The Android debug preset uses Gradle. After Godot import, Java 21/Android SDK setup and signing configuration, prepare the source template before exporting:

```bash
python3 tools/android_surface/prepare_development.py --android-jar "$ANDROID_HOME/platforms/android-35/android.jar" --output builds/qa/android-surface
godot --headless --export-debug Android builds/android/null-swarm-debug.apk
python3 tools/android_surface/verify_development_apk.py builds/android/null-swarm-debug.apk --receipt builds/qa/android-surface/surface-build.json --abi arm64-v8a --output builds/qa/android-surface/apk-export.json
```

Use the existing development/preview package/signing configurators when building those identities; preparation preserves their values exactly. Manual editor exports also need preparation. Keep its receipt for idempotent reuse; deleting/changing the AAR or receipt requires a clean official source-template reinstall. Generated `android/` files and keystores are ignored by Git. The native engine is unchanged; only the reviewed fifteen Java surface classes are recompiled. APK verification rejects absent repair/native/ABI/attribution drift before publication. Normal CI runs eighteen real background/foreground cycles and the independent ordinary gameplay suite. Protected stable-preview signing still requires owner-provided protected secrets. Release AAB integration/signing and physical-device clearance remain separate; do not use this debug-only command as release certification.
