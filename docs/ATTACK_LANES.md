# Directional enemy attack warnings

Strikers now mark their locked charge direction with broad paired rails and two
chevrons. Sentries use a narrow sight line, two ticks and a solid arrowhead. The
different shapes supplement the existing orange/violet definition colors. They
are steady ground markings, including with reduced flashes and low FX quality.

`enemies/attack_lanes.gd` builds two cached, opaque, unshaded ArrayMeshes. Each
warning retains one existing MeshInstance3D; there are no added lights, particles,
shaders or animated material instances. Charge geometry has 12 triangles and
sentry geometry has seven, compared with the previous 12-triangle boxes. These
structural counts do not establish a device FPS improvement. Per-tint materials
are cached separately from other effects. Essential warnings remain independent
of cosmetic intensity settings.

The existing seven-metre base length, local -Z direction, centre and floor offset
are retained. Striker reach still scales with actual charge movement speed,
including corruption. Sentry markings indicate firing direction, not the full
projectile travel distance. Their widths are visual guidance, not collision
boundaries. No attack timings, damage, aiming, movement, spawn, RNG, XP, save or
boss rules change. Other enemy types retain the original hidden box warning.

The 67-check dedicated suite validates geometry, winding, mesh/material reuse,
node budgets, pooling and exact same-worker simulation pairs against hash-guarded
accepted enemy source. Twenty-four cases run 480 steps each across all six
regular enemies, normal/corrupted pace, hit/exposure reactions and both flash
settings. They compare positions, rotations, shots, charge/windup/cooldown timers,
HP, body poses, warning visibility and transforms on every step. The initial
test incorrectly required an exactly decoded UP normal and a hidden child flag:
Godot packs normals (about 0.000015 error), and the accepted inactive enemy hides
the parent. Corrected checks bound normal error and verify real tree visibility
and the accepted child state. Production behavior was not changed for those
test corrections.

Native captures are explicitly labelled staged windups, with a detail board,
ordinary-camera field view and low/reduced-flash view. Android telemetry reads
actual pooled meshes and the smoke test checks their geometry. This does not
claim an attack happened on-screen when only an inactive pool slot was sampled.
Physical phone readability, human playtesting, performance and audio remain
separate acceptance items. Current results and APK identity: TEST_RESULTS.md.

## Hosted acceptance

Verified source 0d08ac9fbb7edd41980a1b7704a9e8a614456a73 passed native 41305109935, Android 41305109895 (53 checks) and full QA 41305109940. Local/native full warning reports and 15 strict suite summaries match. Actual bounded native PNG previews were inspected at detail/ordinary/reduced-flash settings. Android checks read actual pooled geometry and retain both touch-dash orders, moving Pause, progression and lifecycle acceptance. All 26 normal QA sessions and 24 stress scenarios passed.

The execution workspace became unavailable after the local feature commit. The existing GitHub connection supplied CI execution, actual PNG preview bytes and console results. Signature verification and APK checksum are from CI; hosted artifact ZIP digests are recorded. Independent ZIP re-hashing/binary inspection and previous detailed case/fingerprint comparisons could not run. Main remains unmerged, and later CI/report commits need local synchronization when the workspace returns. Physical Mobile performance/readability and human playtesting remain open. Exact source, artifacts, checks and limitations: TEST_RESULTS.md and qa/attack-lanes/verified-ci.json.
