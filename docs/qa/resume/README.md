# Android resume diagnostics

The Android workflow uses isolated gameplay and lifecycle matrix workers. The lifecycle worker runs `python tools/android_runtime_smoke.py --lifecycle-only` after installing its opt-in emulator APK. It performs six Home/launcher returns with 0.25, 1 and 3 second background dwell, twice each. It does not restart a failed app, grant stats, or relax the existing 30-second capture gate.

`tools/lifecycle_observation.py` requires a later frame/sample and a foreground generation rendered after the return. A cached paused snapshot cannot pass. Actual screencaps must still contain the readable game palette. Run state must remain frozen while paused, then advance after touch Resume. Returned PNGs and complete before/returned/frozen/resumed observations are uploaded as `null-swarm-android-lifecycle`; regular acceptance retains `null-swarm-android-runtime`. Neither diagnostic APK is the distributed ARM64 Mobile build.

Run host predicate/signing tests with `python3 -m unittest discover -s tests -p 'test_*.py' -v`; run project checks with `python3 tools/run_headless_checks.py`. Local headless observations cannot establish actual Android recovery.

GLThread EGL_BAD_SURFACE warnings are counted once per app PID, separately from the matching driver error. Warning occurrence and persistent black output are different observations: a warning alone does not establish failed recovery, and a readable bounded run does not prove the engine issue is fixed. The initial persistent black-screen failure remains in `docs/qa/end-results/initial-android-resume-failure.json`. Current results and limits: TEST_RESULTS.md.
