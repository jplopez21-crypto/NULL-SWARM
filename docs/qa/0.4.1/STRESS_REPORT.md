# Synthetic combat CPU benchmark

Headless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.

| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |
|---:|---|---:|---:|---:|---:|---:|
| 100 | low | 333 | 3.768 | 4.626 | 4.988 | 40 |
| 100 | high | 333 | 3.844 | 4.764 | 5.247 | 150 |
| 300 | low | 354 | 7.754 | 12.059 | 13.872 | 40 |
| 300 | high | 354 | 8.290 | 12.229 | 14.112 | 150 |
| 600 | low | 387 | 9.846 | 18.142 | 23.297 | 40 |
| 600 | high | 387 | 9.901 | 19.078 | 23.631 | 150 |

Low/high gameplay-state parity and fixed-load checks: passed. CPU: AMD EPYC 9V74 80-Core Processor.
