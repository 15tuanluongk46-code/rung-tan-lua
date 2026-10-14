extends RefCounted
## Transient combat windows. Progression lives only in RunState.
const CHARGE_TIME: float = 0.55
const PERFECT_WINDOW: float = 0.12
var charge: float = 0.0
var charging: bool = false
var dodge_age: float = 99.0
var counter_left: float = 0.0
var rewarded_attacks: Array[String] = []

func tick(delta: float) -> void:
	dodge_age += delta
	counter_left = maxf(0,counter_left-delta)
	if charging: charge = minf(CHARGE_TIME,charge+delta)

func begin_charge() -> void:
	charging = true
	charge = 0.0

func release_charge() -> bool:
	var ready: bool = charging and charge >= CHARGE_TIME
	cancel_charge()
	return ready

func cancel_charge() -> void:
	charging = false
	charge = 0.0

func begin_dodge() -> void:
	dodge_age = 0.0
	cancel_charge()

func confirm_perfect(game: Node, attack_id: String, source: Node) -> bool:
	if not game.state.skills.has("perfect_dodge") or dodge_age > PERFECT_WINDOW or game.player.dodge_left <= 0: return false
	# Only a confirmed incoming attack, not standing in persistent fire/mud.
	if not is_instance_valid(source) or attack_id.contains("trail_") or rewarded_attacks.has(attack_id): return false
	rewarded_attacks.append(attack_id)
	if rewarded_attacks.size() > 128: rewarded_attacks.pop_front()
	counter_left = 1.2
	game.effects.burst(game.player.position,"heal")
	game.notify("Né chuẩn! Phản công trong 1,2 giây.")
	return true

func consume_counter() -> int:
	if counter_left <= 0: return 0
	counter_left = 0.0
	return 10
