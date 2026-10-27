# Synthetic combat CPU benchmark

Headless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.

| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |
|---:|---|---:|---:|---:|---:|---:|
| 100 | low | 335 | 5.101 | 6.474 | 7.167 | 40 |
| 100 | high | 335 | 5.336 | 6.644 | 7.527 | 150 |
| 300 | low | 358 | 9.009 | 13.385 | 15.916 | 40 |
| 300 | high | 358 | 9.394 | 13.821 | 16.463 | 150 |
| 600 | low | 400 | 11.820 | 23.719 | 30.504 | 40 |
| 600 | high | 400 | 12.244 | 24.200 | 30.794 | 150 |

Low/high gameplay-state parity and fixed-load checks: passed. CPU: AMD EPYC 7763 64-Core Processor.
