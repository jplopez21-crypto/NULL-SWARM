# Operative armor

The shared operative model replaces seven primitive body boxes with an original faceted torso, pale helmet, shoulder plates, backpack, two animated shin/boot pieces and a shaped energy rifle. The front visor, crown stripe and rifle spine/muzzle use static mint/white energy color; armor stays lit. No extra lights, textures, skeletons, shaders or per-frame mesh generation are used.

Four cached ArrayMeshes share two vertex-colored materials. Five body MeshInstance3Ds use six surface instances (the rifle has separate armor/energy surfaces), versus seven boxes/seven surface instances previously. Body triangles rise from 84 to 296 for one operative. Existing ground identity and damage rings remain. This is a bounded visual change, not an FPS optimization claim.

Leg pivots at (+/-0.25, 0.28, 0) and rifle pivot at (0.5, 1.0, -0.5) are preserved. Player tick/aim/damage and normal game physics/camera source bodies remain byte-identical. A fixed 2,400-frame trace recorded from accepted code f1d3de7 covers movement, bounds, dash/cooldown/protection, health/shield timers, aiming, stride, body lean/bob and recoil. Its fingerprint is 3d80f9759422f3aac28f99d8e12fff51e628fb5f871bc8d2267ebc41f8258c74 (13 accepted dashes/14 accepted damage events); it is synthetic simulation parity, not measured FPS.

`godot --headless --script tests/run_operative_tests.gd` validates sharing/independent poses, triangle/surface budgets, finite nondegenerate geometry/unit normals/opaque colors, material lighting, bounds/pivots and the accepted trace. Existing touch dash tests remain part of the strict runner. New read-only Android telemetry counts actual instantiated geometry; its smoke gate requires five body instances/six surfaces/296 triangles. QA helpers are excluded from the distributed APK.

The existing desktop-debug capture mode adds labelled front/rear art references and an ordinary-framing field reference. It cannot be entered on Android and does not change the production camera. Physical S23 readability, human art acceptance and Mobile GPU performance remain open. Asset origin/status is in ASSET_MANIFEST.md; current executed tests/artifacts are in TEST_RESULTS.md.
