extends RefCounted
## Session-only authority. Persistent settings are intentionally separate.
signal changed
var hp: int = 100
var potions: int = 3
var stones: int = 12
var herbs: int = 0
var bag: bool = false
var embers: Dictionary = {}
var accepted: Dictionary = {}
var claimed: Dictionary = {}
var picked: Dictionary = {}
var killed: Dictionary = {}
var checkpoint: String = "camp"
var altar_lit: bool = false
var ended: bool = false
var deaths: int = 0
var elapsed: float = 0.0
var damage_taken: int = 0

func accept(quest: String) -> void:
	if quest in ["main", "herbs", "bag"]:
		accepted[quest] = true
		changed.emit()

func pickup(id: String, kind: String, detail: String = "") -> bool:
	if picked.has(id):
		return false
	match kind:
		"herb": herbs += 1
		"bag":
			if bag: return false
			bag = true
		"ember":
			if detail not in ["forest", "creek", "ruins"] or embers.has(detail): return false
			embers[detail] = true
		"potion":
			if potions >= 6: return false
			potions += 1
		"stone":
			if stones >= 30: return false
			stones = mini(30, stones + 4)
		_: return false
	picked[id] = true
	changed.emit()
	return true

func reward(quest: String) -> bool:
	if not accepted.has(quest) or claimed.has(quest): return false
	match quest:
		"herbs":
			if herbs < 5 or potions > 4: return false
			herbs -= 5
			potions += 2
		"bag":
			if not bag or potions >= 6 or stones > 22: return false
			bag = false
			stones += 8
			potions += 1
		_: return false
	claimed[quest] = true
	changed.emit()
	return true

func light_altar() -> bool:
	if altar_lit or not accepted.has("main") or embers.size() != 3: return false
	altar_lit = true
	changed.emit()
	return true

func finish_main() -> bool:
	if not altar_lit or ended: return false
	ended = true
	changed.emit()
	return true

func heal() -> bool:
	if hp <= 0 or hp >= 100 or potions <= 0: return false
	potions -= 1
	hp = mini(100, hp + 40)
	changed.emit()
	return true

func use_stone() -> bool:
	if stones <= 0: return false
	stones -= 1
	changed.emit()
	return true

func kill_actor(id: String) -> void:
	killed[id] = true
	changed.emit()

func activate_checkpoint(region: String) -> void:
	if region in ["camp", "creek"]:
		checkpoint = region
		changed.emit()

func respawn() -> void:
	hp = 100
	deaths += 1
	changed.emit()

func objective() -> String:
	if ended: return "Ngọn lửa đã trở về."
	if altar_lit: return "Trở về gặp già làng An tại Trại Tro."
	if not accepted.has("main"): return "Gặp già làng An tại Trại Tro."
	if embers.size() == 3: return "Thắp tế đàn ở Phế Tích phía đông nam."
	return "Tìm ba tàn lửa: Rừng Sâu • Bờ Suối • Phế Tích (%d/3)" % embers.size()
