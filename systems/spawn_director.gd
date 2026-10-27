class_name SpawnDirector
extends RefCounted

var elapsed: float = 0.0
var debt: float = 0.0
var spawned: int = 0
const DURATION: float = 300.0

func interval() -> float:
	return maxf(0.12, 0.85 - elapsed * 0.0023)

func tick(delta: float) -> int:
	elapsed = minf(DURATION, elapsed + maxf(0.0, delta))
	debt += maxf(0.0, delta)
	var count: int = 0
	while debt >= interval() and elapsed < DURATION:
		debt -= interval()
		count += 1
	spawned += count
	return count

func archetype(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if elapsed > 65.0 and roll > 0.80:
		return 2
	if elapsed > 25.0 and roll > 0.58:
		return 1
	return 0
