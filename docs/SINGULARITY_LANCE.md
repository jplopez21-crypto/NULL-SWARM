# Singularity Lance

Rail Lance rank 3 + Memory Tether rank 3 automatically mutates the existing Rail slot. It consumes no additional weapon slot. Both upgrade cards advertise the combination; the equipped name, mutation announcement, result damage accounting, beam color and firing sound identify the evolved weapon.

The piercing shot retains its existing damage/range/cooldown rules. Its target impact creates one 4.5m gravity field lasting 1.5 seconds. Small enemies within its radius are pulled toward its center at 3m/s. Bosses and enemies committed to a wind-up or charge remain anchored, preserving attack telegraphs; they can still take field damage.

An unrefreshed field delivers five pulses, one every 0.3 seconds, each at 9% of the current ranked rail shot damage. The first pulse is delayed until its deadline. Subsequent rail shots replace the center and extend this single field, retaining pulse cadence so attack-speed bonuses do not starve periodic damage. Fields never stack. Upgrading the mutated rail increases both direct and field damage, shown on the card.

Strengths: groups small machines for piercing/chain weapons; adds sustained pressure near an impact. Costs: six rank investments including a collection passive, only one active field, delayed periodic damage, limited radius, no displacement of bosses or committed attack lanes. Swarm style accounting treats this evolved rail as projectile-derived damage and keeps the existing announced/capped adaptations.

One reusable field node has two original procedural meshes. Pulls update only changed spatial cells, maintaining index ordering. Pausing freezes its clock; a fresh deployment resets it. Reduced flashes keep the gameplay boundary visible while suppressing core pulsation. It does not alter enemy spawns, saves, purchases or run reward ledgers.

Local normal-rule bot seeds 101 and 202 reached the evolution and won; both use legal upgrades and normal damage/death rules. This is not human balance/retention evidence. Synthetic fixture 4 uses invulnerability/high enemy HP deliberately to sustain 100/300/600 targets and all corruption links, and checks low/high-quality gameplay parity. Its CPU timings exclude rendering/UI/phone thermals and are not comparable directly to older fixtures.

Reproduce:

```sh
python3 tools/run_headless_checks.py
godot --headless --script tests/run_playtests.gd -- --singularity-probe
godot --headless --script tests/run_benchmark.gd -- --gravity-stress
```

The standard bot matrix now includes the Singularity profile; all existing upgrade IDs and random offer ordering are retained. Final native captures show the advertised combination, active field and evolved upgrade card. Active-field rendering on physical Android hardware and human balance remain acceptance work.
