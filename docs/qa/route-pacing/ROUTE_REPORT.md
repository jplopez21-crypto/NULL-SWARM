# Arcstorm route observations

- Read-only per-physics-step observations; existing navigation, upgrades, RNG and combat rules are unchanged.
- Opposite command means a direction change over 120 degrees. Requests and successful cooldown transitions are separate.
- Longest-gap windows include only complete intervals between five-second samples inside the gap; boundaries are omitted.
- Low net intervals last 4–6 seconds, travel at least 5m and finish under 0.75m from their start. This can include intentional circling.
- Sampled footprint omits excursions between snapshots. Readiness is time available before dash selection, including same-tick cooldown expiry.
- Four fixed seeds describe these bots, not safe routes, human skill, balance causality or physical-device performance.

| Seed / policy | Gap (s) | Observed (s) | Travel / net (m) | Reversals | Dash requests / activated | Ready (s) | Low net intervals |
|---|---:|---:|---:|---:|---:|---:|---:|
| 101 / cautious | 319.45 | 317.63 | 2271.12 / 13.97 | 2317 | 13 / 13 | 285.60 | 61 |
| 101 / value_aware | 319.55 | 310.02 | 2170.12 / 36.12 | 2265 | 0 / 0 | 310.02 | 60 |
| 202 / cautious | 317.80 | 314.15 | 2232.06 / 0.10 | 2337 | 9 / 9 | 292.68 | 63 |
| 202 / value_aware | 249.50 | 245.02 | 1718.80 / 20.56 | 1784 | 1 / 1 | 244.13 | 46 |
| 303 / cautious | 290.75 | 285.02 | 2013.45 / 7.59 | 2114 | 5 / 5 | 272.52 | 56 |
| 303 / value_aware | 223.25 | 215.02 | 1505.12 / 0.35 | 1613 | 0 / 0 | 215.02 | 43 |
| 404 / cautious | 316.82 | 310.02 | 2177.46 / 43.63 | 2245 | 2 / 2 | 305.02 | 60 |
| 404 / value_aware | 306.52 | 300.02 | 2100.12 / 35.28 | 2209 | 0 / 0 | 300.02 | 58 |
