# Memory collection audio

Actual collected XP now triggers a quiet original synthesized memory cue. A dedicated SFX voice preserves all twelve existing combat voices and cannot repoint weapon, hit or UI playback. The same SFX/Master controls apply; no new settings or saved fields are introduced.

The ninety-millisecond mono 22,050Hz sixteen-bit PCM combines an upward 880Hz partial and a delayed 1,320Hz harmonic with a short smooth attack and zero-ended release. It is generated once per audio-system initialization, with no external assets or RNG. Collection batches below 25, 25–99 and 100+ XP select bounded pitch ratios 1.0/1.122462/1.259921 at a fixed −18 dB voice level. These thresholds describe the total XP collected in one physics tick, including multiple packets, rather than changing any packet's value.

One physics-tick call follows exact XP accounting. A shared 140 ms wall-clock gate allows at most one cue per interval across all tiers; suppressed batches are discarded from audio, never queued or deducted from XP. Batches that produce pending upgrades start no memory cue, preserving the level-up cue. Existing short one-shots may finish across pause, as other SFX do; paused gameplay never collects or enqueues memory audio. New deployment resets the counter/deadline and stops old playback. Shutdown clears the dedicated stream and cancels startup safely.

Drop/merge/attraction/collection, progression, damage, weapons, spawning, combat RNG and quality budgets are unchanged. The new cost is one reusable AudioStreamPlayer and one short PCM resource; no extra draw objects, particles or lights. No performance improvement is claimed.

## Verification

Audio tests check bounded deterministic PCM, amplitude/RMS/DC, zero-ended continuity, real playback/cooldown/pitch/routing, preserved combat voices, mute attenuation, reset/shutdown and same-frame teardown. Actual game-physics integration covers multi-packet aggregation, pause, suppressed-feedback XP conservation, no delayed queue, level overflow and restart. The strict isolated runner also scans engine errors and leaked resources.

A read-only emulator probe exposes the actual accepted playback counter. Android acceptance requires it to be positive after ordinary touchscreen combat/collection/upgrades; the probe grants nothing. This proves a playback request reached the dedicated voice, not that a person heard it: CI uses an audio-disabled emulator. The exported builds/qa/memory-cue.wav allows later human listening review. Physical phone speaker/headphone balance, perceived comfort and fun remain unverified.

Exact local/hosted counts, revision/artifact identities and limits are recorded in TEST_RESULTS.md and qa/memory-audio/.
