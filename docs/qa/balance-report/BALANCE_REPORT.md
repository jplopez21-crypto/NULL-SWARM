# Normal-play balance observations

- Fixed-seed bot observations, not human enjoyment, retention or population win-rate estimates.
- Suites, kits, fixtures, policies and research remain separate; medians describe only the recorded seeds.
- Missing first-level/weapon events are unobserved, not zero seconds. Mutation times include reached runs only.
- Comparison covers selected balance observations. Full gameplay determinism is checked separately.
- Host CPU timings are excluded. No Android rendering, phone FPS, touch-latency or thermal claim.
- Victories, defeats and time limits are observations; valid balance changes do not fail this tool.

| Suite / build / kit / conditions | Runs | Outcomes | Survival median (s) | First weapon median (s) | Longest upgrade gap median (s) | Collected / left XP medians |
|---|---:|---|---:|---:|---:|---:|
| C01 / bot-report.json / electric / conductor / earned kit / no research / cautious / local / clean / research={} | 1 | victory: 1 | 600.02 | 21.12 | 40.70 | 15039.00 / 172.00 |
| C02 / extended-seeds.json / electric / conductor / earned kit / no research / cautious / local / clean / research={} | 1 | victory: 1 | 637.57 | 16.08 | 37.85 | 14730.00 / 986.00 |
| C03 / engineer-probe.json / engineer / engineer / earned kit / no research / cautious / local / clean / research={} | 2 | victory: 2 | 600.02 | 11.47 | 301.94 | 15848.00 / 643.50 |
| C04 / bot-report.json / halo / sentinel / earned kit / no research / cautious / local / clean / research={} | 1 | victory: 1 | 600.02 | 17.82 | 20.29 | 16423.00 / 71.00 |
| C05 / extended-seeds.json / halo / sentinel / earned kit / no research / cautious / local / clean / research={} | 1 | victory: 1 | 600.02 | 36.72 | 27.12 | 16242.00 / 80.00 |
| C06 / corruption-probe.json / kinetic / vanguard / new player / cautious / local / all / research={} | 1 | victory: 1 | 600.02 | 11.30 | 270.96 | 16361.00 / 503.00 |
| C07 / bot-report.json / arcstorm / vanguard / new player / cautious / local / clean / research={} | 2 | defeat: 2 | 530.89 | 11.89 | 318.62 | 2895.50 / 9948.00 |
| C08 / extended-seeds.json / arcstorm / vanguard / new player / cautious / local / clean / research={} | 1 | victory: 1 | 600.02 | 12.98 | 290.75 | 16223.00 / 204.00 |
| C09 / bot-report.json / electric / vanguard / new player / cautious / local / clean / research={} | 2 | victory: 2 | 600.02 | 11.89 | 69.24 | 15260.00 / 106.00 |
| C10 / extended-seeds.json / electric / vanguard / new player / cautious / local / clean / research={} | 1 | victory: 1 | 600.02 | 13.25 | 50.02 | 14974.00 / 259.00 |
| C11 / bot-report.json / engineer / vanguard / new player / cautious / local / clean / research={} | 2 | victory: 2 | 600.02 | 11.89 | 267.33 | 15751.50 / 636.50 |
| C12 / bot-report.json / halo / vanguard / new player / cautious / local / clean / research={} | 2 | defeat: 1, victory: 1 | 359.71 | 11.89 | 36.47 | 8525.50 / 356.00 |
| C13 / extended-seeds.json / halo / vanguard / new player / cautious / local / clean / research={} | 1 | defeat: 1 | 114.15 | 12.98 | 22.33 | 564.00 / 514.00 |
| C14 / bot-report.json / kinetic / vanguard / new player / cautious / local / clean / research={} | 2 | victory: 2 | 600.02 | 11.89 | 209.80 | 16249.00 / 206.00 |
| C15 / extended-seeds.json / kinetic / vanguard / new player / cautious / local / clean / research={} | 1 | victory: 1 | 600.02 | 13.25 | 201.79 | 15800.00 / 446.00 |
| C16 / bot-report.json / singularity / vanguard / new player / cautious / local / clean / research={} | 2 | victory: 2 | 600.02 | 11.89 | 235.55 | 15150.50 / 1258.00 |
| C17 / corruption-probe.json / kinetic / vanguard / new player / cautious / local / fracture / research={} | 1 | victory: 1 | 600.02 | 11.30 | 175.85 | 16594.00 / 250.00 |
| C18 / corruption-probe.json / kinetic / vanguard / new player / cautious / local / hive / research={} | 1 | victory: 1 | 600.02 | 12.48 | 271.11 | 16014.00 / 336.00 |
| C19 / corruption-probe.json / electric / vanguard / new player / cautious / local / redline / research={} | 1 | victory: 1 | 600.02 | 12.48 | 79.47 | 15276.00 / 190.00 |

| Cohort / mutation | Reached / runs | Observed median (s) | Observed range (s) |
|---|---:|---:|---|
| C01 / arcstorm | 1 / 1 | 204.27 | 204.27–204.27 |
| C01 / halo | 1 / 1 | 157.45 | 157.45–157.45 |
| C02 / arcstorm | 1 / 1 | 196.22 | 196.22–196.22 |
| C02 / halo | 1 / 1 | 95.60 | 95.60–95.60 |
| C03 / arcstorm | 2 / 2 | 322.81 | 191.33–454.30 |
| C03 / singularity | 2 / 2 | 364.45 | 186.78–542.13 |
| C04 / halo | 1 / 1 | 49.15 | 49.15–49.15 |
| C04 / singularity | 1 / 1 | 304.48 | 304.48–304.48 |
| C05 / halo | 1 / 1 | 55.85 | 55.85–55.85 |
| C05 / singularity | 1 / 1 | 277.22 | 277.22–277.22 |
| C06 / singularity | 1 / 1 | 547.22 | 547.22–547.22 |
| C07 / arcstorm | 2 / 2 | 198.28 | 196.38–200.18 |
| C08 / arcstorm | 1 / 1 | 478.42 | 478.42–478.42 |
| C08 / singularity | 1 / 1 | 481.87 | 481.87–481.87 |
| C09 / arcstorm | 2 / 2 | 200.63 | 199.40–201.87 |
| C09 / halo | 2 / 2 | 147.38 | 103.08–191.67 |
| C10 / arcstorm | 1 / 1 | 207.97 | 207.97–207.97 |
| C10 / halo | 1 / 1 | 156.15 | 156.15–156.15 |
| C11 / arcstorm | 2 / 2 | 348.48 | 238.08–458.87 |
| C11 / singularity | 2 / 2 | 512.18 | 473.88–550.48 |
| C12 / halo | 2 / 2 | 60.01 | 57.30–62.72 |
| C12 / singularity | 1 / 2 | 344.17 | 344.17–344.17 |
| C14 / singularity | 2 / 2 | 510.19 | 491.55–528.83 |
| C15 / singularity | 1 / 1 | 398.45 | 398.45–398.45 |
| C16 / arcstorm | 2 / 2 | 322.64 | 192.03–453.25 |
| C16 / singularity | 2 / 2 | 189.02 | 187.17–190.87 |
| C17 / singularity | 1 / 1 | 409.40 | 409.40–409.40 |
| C18 / singularity | 1 / 1 | 499.83 | 499.83–499.83 |
| C19 / arcstorm | 1 / 1 | 194.62 | 194.62–194.62 |
| C19 / halo | 1 / 1 | 193.42 | 193.42–193.42 |

A missing mutation row means it was never reached in that cohort. Seeds, first-level pacing and coverage counts are in balance-report.json.
