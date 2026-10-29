# Memory crystal presentation

Experience packets now use original faceted double-pyramid crystals instead of smooth round orbs. Blue (below 25 XP), mint (25–99 XP) and gold (100+ XP) retain the previous exact tint and value-dependent scale formula. Four/six/eight-sided tiers use 8/12/16 triangles, compared with the previous 80-triangle sphere. All stay within the original 0.32m envelope before value scaling. Flat opaque grayscale vertex colors make facets visible with the existing unlit tier tint.

Three cached single-surface meshes and three shared materials replace the previous single shared sphere and existing three materials. There are no additional nodes per packet, glow layers, lights, timers, textures or random calls. At 300 basic packets geometry is 2,400 triangles versus 24,000, but packet draw-instance count is unchanged. These are structural counts; no GPU draw-call, frame-rate or phone readability gain is claimed.

Local merging updates the same node to its new tier; recycled packets reset mesh, tint, scale and visibility. Drop positions, XP values, local merge radius/soft budget, magnet range, attraction speed, collection threshold/order, vacuum, locator and XP progression are unchanged. Source hashes for unchanged tick/locator/accounting functions are recorded under qa/memory-crystals.

Opening guidance now names memory crystals and keeps the cyan-arrow instruction. Desktop debug presentation captures add a paused normal-framing field and enlarged close view. Both are staged review fixtures, not earned-play evidence; Android excludes capture mode. Existing combat captures and Android gameplay remain the runtime review.

## Verification

New regressions cover all tier boundaries, cached resources, exact previous tint/scale/positions, opaque finite outward geometry, original bounds, merge tier transitions, a frame-by-frame round-orb reference comparison, exact XP conservation and recycled high-to-low reset without new nodes.

Local and hosted results, failures/fixes and exact artifact identity are recorded in TEST_RESULTS.md. Physical-phone FPS, human readability/accessibility and final commercial art review remain open.
