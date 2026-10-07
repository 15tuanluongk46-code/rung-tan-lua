extends RefCounted
## Each attack ID can damage this target once; bounded history avoids leaks.
var maximum: int
var hp: int
var invulnerable: float = 0.0
var hits: Array[String] = []

func _init(value: int = 100) -> void:
	maximum = value
	hp = value

func hit(amount: int, attack_id: String) -> bool:
	if hp <= 0 or amount <= 0 or invulnerable > 0.0 or hits.has(attack_id): return false
	hits.append(attack_id)
	if hits.size() > 128: hits.pop_front()
	hp = maxi(0, hp - amount)
	invulnerable = 0.38
	return true

func tick(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)

func guard(duration: float) -> void:
	invulnerable = maxf(invulnerable, duration)

func reset() -> void:
	hp = maximum
	invulnerable = 0.0
	hits.clear()
