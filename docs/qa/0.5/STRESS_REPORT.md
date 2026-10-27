# Synthetic combat CPU benchmark

Headless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.

| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |
|---:|---|---:|---:|---:|---:|---:|
| 100 | low | 333 | 2.680 | 3.357 | 3.642 | 40 |
| 100 | high | 333 | 2.800 | 3.490 | 3.713 | 150 |
| 300 | low | 354 | 5.260 | 7.658 | 9.711 | 40 |
| 300 | high | 354 | 5.388 | 8.529 | 10.052 | 150 |
| 600 | low | 387 | 7.084 | 13.153 | 16.780 | 40 |
| 600 | high | 387 | 7.693 | 14.330 | 17.873 | 150 |

Low/high gameplay-state parity and fixed-load checks: passed. CPU: AMD EPYC 9V45 96-Core Processor.
