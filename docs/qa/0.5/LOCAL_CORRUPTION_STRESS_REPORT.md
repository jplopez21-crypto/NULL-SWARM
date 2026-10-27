# Synthetic combat CPU benchmark

Headless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.

| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |
|---:|---|---:|---:|---:|---:|---:|
| 100 | low | 337 | 4.759 | 7.071 | 9.852 | 40 |
| 100 | high | 337 | 4.507 | 5.730 | 6.536 | 150 |
| 300 | low | 358 | 14.775 | 20.099 | 23.902 | 40 |
| 300 | high | 358 | 14.340 | 19.560 | 23.743 | 150 |
| 600 | low | 396 | 26.135 | 36.567 | 41.285 | 40 |
| 600 | high | 396 | 27.244 | 38.407 | 49.034 | 150 |

Low/high gameplay-state parity and fixed-load checks: passed. CPU: AMD EPYC 9V74 80-Core Processor.
