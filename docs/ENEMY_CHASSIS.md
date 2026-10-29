# Regular enemy chassis visual pass

Six original faceted hulls distinguish combat roles through shape as well as the existing definition colors: low tracked Crawler, pointed dart Striker, tall fork/turret Sentry, broad shielded Bulwark, winged floating Skimmer and twin-fork/hex-cage Insulator. Existing eye markers remain separate and unshaded. No new glow, animation, lights or textures are added.

Each hull uses one cached single-surface ArrayMesh and a lit vertex-color material shared per canonical ID, tinted by its definition. Mesh/material caches are bounded to the six registry IDs. Canonical IDs share their definition tint; configuring one ID with a different color updates that shared tint. Bosses and noncanonical IDs retain the previous primitive path, including Warden/Architect embellishments.

Hull triangle counts are Crawler 66, Striker 27, Sentry 78, Bulwark 74, Skimmer 66 and Insulator 84, below the 96-triangle ceiling. Including the unchanged eye, one of each regular type uses 12 body MeshInstances/467 triangles versus 22/747 before. Some individual hulls gain triangles; the equal six-type sample reduces totals. This is structural accounting, not a GPU/FPS measurement. Hulls omit unseen bottom caps for the fixed elevated camera.

Enemy activation, deactivation, thinking, tick/movement/attack and hit function bodies match the previous verified source exactly. Collision radii, HP, speed, damage, timers, invulnerability, targeting, RNG, spawn/FX budgets and ordinary camera are unchanged. New meshes remain children of the original body, preserving existing recoil, visual_scale, pooling/reset and reduced-intensity behavior. There are no mesh colliders.

The enlarged labelled enemy_lineup image is a desktop-debug-only presentation fixture with paused actors, not normal/earned play or a new in-game menu. Normal-framing combat/boss and actual Android captures must also be inspected. Source guards exclude capture mode from Android.

## Verification

All ten local isolated suites pass: 954 systems, 58 resources, 2,244 headless UI checks/160 layouts, 27 Engineer, 36 GUI, nine audio, eight probe, 21 input, 41 corruption and scene smoke. Added tests cover bounded caches, one surface, triangle/attribute budgets, finite geometry/winding/colors, role proportions, tint sharing, two body meshes, preserved hit/reset/accessibility and the old boss/fallback path. Raw source-function hashes and structural counts are under qa/enemy-chassis.

Hosted native/Android/rendered/full-gameplay acceptance and visual review are pending. Existing 2,245-check rendered UI coverage includes actual floor placement and remains unchanged. Compare all normal gameplay/XP/pacing reports and 24 stress fingerprints with the previously verified industrial-deck source 42b5389 before accepting the new APK. Hardware FPS, human readability/accessibility and final commercial art remain open acceptance items.
