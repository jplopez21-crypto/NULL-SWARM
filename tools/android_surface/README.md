# Experimental Compatibility surface recovery

This is a diagnostic engine-Java experiment, not a production template change. Ordinary Android and Windows presets continue using the official Godot templates.

The pinned Godot 4.6.3 `GLSurfaceView.java` has Git blob `8b25fdfeceb6dcc273646005137a92f161755558`. The same file/blob is present in 4.7.2; an upgrade alone does not change this code. Its `surfaceDestroyed`/`surfaceCreated` callbacks update a boolean without waiting for the render thread. If both callbacks occur while a swap is in flight, the GL thread can miss the false state. A failed old swap may then set `mSurfaceIsBad` after the new surface exists; `readyToDraw` stays false until another lifecycle event. This is a source-derived hypothesis consistent with the retained black-screen evidence, now supported by the bounded controlled-field and emulator comparison below; it is not production/physical-device clearance.

The candidate latches a surface change in both callbacks. The render thread consumes it before deciding readiness, releases the old EGL surface and clears its stale bad flag. It does not restore removed UI-thread wait loops, reset the EGL context, restart the process, unpause gameplay, suppress errors or retry an unrelated invalid surface.

`rebuild_surface_aar.py` validates the exact upstream source, compiles only its Java class family at the original bytecode level and runs `SurfaceLatchHarness` against controlled fields. The control demonstrates the coalesced-edge stall; the candidate must clear it while retaining pause/context and refusing a missing or unrelated bad surface. This host test does not invoke a real GPU. Every other Java class, AAR resource and native library remains byte-identical; failures leave the disposable input AAR unchanged.

The experimental workflow builds both a recompiled control and the candidate with the same Gradle pipeline, Godot/native version, emulator, image and driver. Each runs 18 real Home/return cycles. A control may record the known Surface failure; this is explicitly recorded as a failed recovery observation, not a pass. The candidate must pass every strict recovery check and an independent normal gameplay/save/update suite. A disposable diagnostic package is cleared only between those independent suites; no real player package is touched. Production templates are not modified.

Upstream GLSurfaceView is Copyright (C) 2008 The Android Open Source Project, Apache-2.0. Its original header is preserved. The modified diagnostic source carries a change notice; diagnostic APKs include the full Apache license and attribution. See `Apache-2.0.txt`. No other Godot native/source component is replaced.

## Verified bounded comparison (2026-11-07)

Source `3824e19a7fd530c8f947faeb7a59bd5f31bd3081`, investigation run `42398894125`: the control recovers seven times and stalls on cycle eight with an all-black capture; the candidate passes all eighteen cycles/56 checks, recovering eleven logged failed swaps, then all 58 ordinary gameplay/save/update checks. Host logic passes both expected control/candidate outcomes. Initial compilation missed EGLLogWrapper; the unchanged official classes.jar is now on the compiler/host classpath. Fifteen class-family entries are rebuilt, 220 unrelated classes and all nonclass AAR entries are preserved. Both diagnostic APKs have identical native libraries and unchanged game modules.

The ordinary official-engine Android workers remain failed; a green control **collection** job is not a passing control recovery test. No production preset/template is changed. Repeat/stress and deliberate export integration remain the next steps. See TEST_RESULTS.md and docs/qa/surface-recovery/verified-ci.json for provenance, exact archives and retained failures.
