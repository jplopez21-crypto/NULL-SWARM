class_name SpawnDirector
extends RefCounted

var elapsed: float = 0.0
var debt: float = 0.0
var spawned: int = 0
const DURATION: float = 600.0

func interval() -> float:
	# Assaults have breathing room between them; final boss stops new regular waves.
	var base := maxf(0.18, 0.70 - elapsed * 0.0010)
	return base * (1.45 if fmod(elapsed, 60.0) > 47.0 else 1.0)

func tick(delta: float) -> int:
	elapsed += maxf(0.0, delta)
	if elapsed >= DURATION:
		return 0
	debt += maxf(0.0, delta)
	var count: int = 0
	while debt >= interval():
		debt -= interval()
		count += 1
	spawned += count
	return count

func archetype(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if elapsed > 240.0 and roll > 0.90:
		return 4
	if elapsed > 120.0 and roll > 0.78:
		return 3
	if elapsed > 65.0 and roll > 0.62:
		return 2
	if elapsed > 25.0 and roll > 0.40:
		return 1
	return 0
