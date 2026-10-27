# Synthetic combat CPU benchmark

Headless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.

| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |
|---:|---|---:|---:|---:|---:|---:|
| 100 | low | 333 | 2.512 | 3.146 | 3.793 | 40 |
| 100 | high | 333 | 2.650 | 3.273 | 3.823 | 150 |
| 300 | low | 354 | 4.714 | 7.196 | 8.534 | 40 |
| 300 | high | 354 | 4.869 | 7.364 | 8.675 | 150 |
| 600 | low | 387 | 6.272 | 12.236 | 14.975 | 40 |
| 600 | high | 387 | 6.490 | 13.099 | 16.614 | 150 |

Low/high gameplay-state parity and fixed-load checks: passed. CPU: AMD EPYC 9V45 96-Core Processor.
