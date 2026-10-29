# Industrial deck presentation

Reactor Zero uses original chamfered industrial deck panels with recessed service hatches/grilles, fastener marks, ID paint and restrained service/hazard markings. Both layouts share the same dark base palette so they do not recreate a bright checkerboard. Static detail sits below the operative and combat warning geometry; there are no new lights, textures, particles or animations.

Two cached single-surface ArrayMeshes share one rough, lit vertex-color material. The existing two MultiMesh batches still hold 200 panels each at their original positions. Panel layouts use 48 and 56 triangles: 20,800 floor triangles total versus 4,800 for the old boxes. This is a deliberate bounded geometry increase; no GPU/FPS improvement is claimed. Shadow casting is disabled for the floor batches. Cache keys clamp to two variants, and mesh/material generation happens once per process rather than per panel or frame.

Movement/collisions, camera framing, enemies, targeting, RNG, damage/XP, difficulty, effect/spawn budgets and all quality presets' gameplay remain unchanged. A desktop-debug-only staged deck_detail capture uses a closer camera; ordinary and Android cameras are unaffected. Art is original development geometry, documented in ASSET_MANIFEST.md, pending final commercial art review.

## Automated acceptance

Local strict suites cover cache bounds/reuse, one-surface/64-triangle ceiling, finite bounded geometry, clockwise winding/normals, opaque restrained colors, shared material flags, two batches/400 instances and absence of collision. Dummy headless rendering returns identity for MultiMesh transform reads, so actual uploaded placement is checked in the rendered UI suite rather than reported as a headless pass. This initial test limitation was reproduced and corrected. The rendered suite checks all 400 unique tile positions and original extent.

All ten isolated local suites passed: 896 systems, 57 resources, 2,244 headless UI checks/160 layouts, 27 Engineer, 36 GUI, nine audio, eight probe, 21 input, 41 corruption and scene smoke. The rendered UI suite adds one actual placement assertion (2,245 checks). Local visual capture was not executed; hosted native/UI and Android runtime captures must be reviewed before acceptance. Gameplay/report comparisons remain against the previous verified source cfceb77.

The native APK artifact keeps android/ contents and one overclock preview, preserving its existing extraction path. Full presentation captures have a separate artifact so richer screenshot sets cannot bloat the install download. CI artifact hashes/package/probe exclusions and rendered appearance/runtime/full-QA acceptance are pending for this checkpoint; final results belong in TEST_RESULTS.md and qa/industrial-deck/verified-ci.json.
