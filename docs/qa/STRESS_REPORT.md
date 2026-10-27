# Synthetic combat CPU benchmark

Headless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.

| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |
|---:|---|---:|---:|---:|---:|---:|
| 100 | low | 335 | 4.940 | 6.207 | 6.963 | 40 |
| 100 | high | 335 | 5.119 | 6.385 | 7.053 | 150 |
| 300 | low | 358 | 8.557 | 12.895 | 15.294 | 40 |
| 300 | high | 358 | 8.610 | 12.783 | 15.419 | 150 |
| 600 | low | 400 | 11.042 | 22.611 | 29.166 | 40 |
| 600 | high | 400 | 11.141 | 22.444 | 29.433 | 150 |

Low/high gameplay-state parity and fixed-load checks: passed. CPU: AMD EPYC 7763 64-Core Processor.
