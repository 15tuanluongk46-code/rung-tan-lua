extends RefCounted
## Progress authority. Only validated snapshots are persisted, never transient nodes.
const Quests = preload("res://scripts/quest_registry.gd")
const Content = preload("res://scripts/world_content.gd")
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
var chapter: int = 1
var chapter_one_complete: bool = false
var stage: int = 0
var events: Dictionary = {}
var discovered: Dictionary = {"camp":true}
var landmarks: Dictionary = {}
var memories: Dictionary = {}
var planks: int = 0
var bell_parts: int = 0
var skills: Dictionary = {}
var specialization: String = ""
var rewards_received: Dictionary = {}
var known_checkpoints: Dictionary = {"camp":true}
var encountered: Dictionary = {}

func accept(quest: String) -> void:
	if Quests.QUESTS.has(quest) and int(Quests.QUESTS[quest].chapter) <= chapter:
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
			skills.charge = true
		"potion":
			if potions >= 6: return false
			potions += 1
		"stone":
			if stones > 26: return false
			stones += 4
		"plank": planks += 1
		"bell_part": bell_parts += 1
		_: return false
	picked[id] = true
	changed.emit()
	return true

func reward(quest: String) -> bool:
	if not Quests.QUESTS.has(quest) or int(Quests.QUESTS[quest].chapter) > chapter: return false
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
		"bridge":
			if planks < 3: return false
			planks -= 3
			events.bridge = true
		"bell":
			if bell_parts < 3: return false
			bell_parts -= 3
			events.bell = true
		_: return false
	claimed[quest] = true
	if quest in ["bridge","bell"]: collect_reward(quest,false)
	changed.emit()
	return true

func collect_reward(quest: String, emit_change: bool = true) -> bool:
	if not claimed.has(quest) or rewards_received.has(quest): return false
	if quest == "bridge":
		if potions >= 6: return false
		potions += 1
	elif quest == "bell":
		if stones > 26: return false
		stones += 4
	else: return false
	rewards_received[quest] = true
	if emit_change: changed.emit()
	return true

func choose_specialization(choice: String) -> bool:
	if chapter != 2 or stage < 4 or choice not in ["spear","stone","survival"]: return false
	specialization = choice
	changed.emit()
	return true

func light_altar() -> bool:
	if altar_lit or not accepted.has("main") or embers.size() != 3: return false
	altar_lit = true
	changed.emit()
	return true

func finish_main() -> bool:
	if not altar_lit or ended: return false
	if chapter == 2 and not events.has("boss"): return false
	if chapter == 1: chapter_one_complete = true
	ended = true
	changed.emit()
	return true

func heal() -> bool:
	if hp <= 0 or hp >= 100 or potions <= 0: return false
	potions -= 1
	hp = mini(100, hp + (50 if specialization == "survival" else 40))
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
	if region in ["camp", "creek", "marsh", "ash"] and (chapter == 2 or region in ["camp","creek"]):
		checkpoint = region
		known_checkpoints[region] = true
		changed.emit()

func respawn() -> void:
	hp = 100
	deaths += 1
	changed.emit()

func objective() -> String:
	if chapter == 2:
		if ended: return "Nước nguồn và ngọn lửa đã trở về."
		return Quests.STAGES[clampi(stage,0,6)]
	if ended: return "Ngọn lửa đã trở về."
	if altar_lit: return "Trở về gặp già làng An tại Trại Tro."
	if not accepted.has("main"): return "Gặp già làng An tại Trại Tro."
	if embers.size() == 3: return "Thắp tế đàn ở Phế Tích phía đông nam."
	return "Tìm ba tàn lửa: Rừng Sâu • Bờ Suối • Phế Tích (%d/3)" % embers.size()

func continue_chapter() -> bool:
	if not chapter_one_complete or chapter != 1: return false
	chapter = 2
	ended = false
	accepted.sources = true
	stage = 0
	changed.emit()
	return true

func complete_event(id: String) -> bool:
	if id in ["bridge","bell"]: return false
	if chapter != 2 or events.has(id) or id not in Quests.EVENTS: return false
	if id.begins_with("lamp_") and stage != 1: return false
	if id == "well" and stage != 2: return false
	if id.begins_with("valve_") and stage != 4: return false
	if id == "boss" and stage != 5: return false
	events[id] = true
	if id.begins_with("lamp_") and events.has("lamp_0") and events.has("lamp_1") and events.has("lamp_2"): stage = 2
	if id == "well":
		stage = 3
		skills.perfect_dodge = true
	if events.has("valve_0") and events.has("valve_1") and stage == 4: stage = 5
	if id == "boss": stage = 6
	changed.emit()
	return true

func snapshot() -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["hp","potions","stones","herbs","bag","embers","accepted","claimed","picked","killed","checkpoint","altar_lit","ended","deaths","elapsed","damage_taken","chapter","chapter_one_complete","stage","events","discovered","landmarks","memories","planks","bell_parts","skills","specialization","rewards_received","known_checkpoints","encountered"]:
		result[key] = get(key)
	return result.duplicate(true)

static func valid_snapshot(data: Dictionary) -> bool:
	for key: String in ["hp","potions","stones","herbs","deaths","elapsed","damage_taken","chapter","stage","planks","bell_parts"]:
		if not data.has(key) or not (data[key] is int or data[key] is float) or not is_finite(float(data[key])) or float(data[key]) < 0: return false
	if data.hp > 100 or data.potions > 6 or data.stones > 30 or int(data.chapter) not in [1,2] or data.stage > 6: return false
	for key: String in ["hp","potions","stones","herbs","deaths","damage_taken","chapter","stage","planks","bell_parts"]:
		if float(data[key]) != floorf(float(data[key])): return false
	if data.get("checkpoint","") not in ["camp","creek","marsh","ash"]: return false
	if data.chapter == 1 and data.checkpoint in ["marsh","ash"]: return false
	for key: String in ["bag","altar_lit","ended","chapter_one_complete"]:
		if not data.get(key) is bool: return false
	for key: String in ["embers","accepted","claimed","picked","killed","events","discovered","landmarks","memories"]:
		if not data.get(key) is Dictionary or data[key].size() > 512: return false
		for id: Variant in data[key]:
			if not (id is String or id is StringName) or data[key][id] != true: return false
	for id: String in data.embers:
		if id not in ["forest","creek","ruins"]: return false
	for id: String in data.accepted:
		if not Quests.QUESTS.has(id): return false
	for id: String in data.claimed:
		if id not in ["herbs","bag","bridge","bell"] or not data.accepted.has(id): return false
	for id: String in data.events:
		if id not in Quests.EVENTS: return false
	if data.altar_lit and (data.embers.size() != 3 or not data.accepted.has("main")): return false
	if data.chapter == 1 and (data.stage != 0 or not data.events.is_empty()): return false
	if data.stage >= 2 and (not data.events.has("lamp_0") or not data.events.has("lamp_1") or not data.events.has("lamp_2")): return false
	if data.stage >= 3 and not data.events.has("well"): return false
	if data.stage >= 5 and (not data.events.has("valve_0") or not data.events.has("valve_1")): return false
	if data.events.has("lamp_0") and data.events.has("lamp_1") and data.events.has("lamp_2") and data.stage < 2: return false
	if data.events.has("well") and data.stage < 3: return false
	if data.events.has("valve_0") and data.events.has("valve_1") and data.stage < 5: return false
	for place: String in ["forest","creek","ruins"]:
		if data.picked.has("ember_"+place) != data.embers.has(place): return false
	if data.picked.has("hunter_bag") != (data.bag or data.claimed.has("bag")): return false
	if data.events.has("boss") != data.killed.has("guardian"): return false
	for id: String in data.discovered:
		if id not in ["camp","forest","creek","ruins","marsh","ash"]: return false
	if data.chapter == 2 and (not data.chapter_one_complete or not data.altar_lit or not data.accepted.has("sources")): return false
	if data.events.has("boss") and (data.stage != 6 or not data.events.has("well") or not data.events.has("valve_0") or not data.events.has("valve_1")): return false
	if data.stage == 6 and not data.events.has("boss"): return false
	if data.chapter_one_complete and not data.altar_lit: return false
	if data.chapter == 1 and data.chapter_one_complete != data.ended: return false
	if data.ended and (not data.altar_lit or not data.chapter_one_complete or (data.chapter == 2 and not data.events.has("boss"))): return false
	var content := Content.new()
	var allowed_kills: Dictionary = {}
	var allowed_items: Dictionary = {}
	var allowed_landmarks: Dictionary = {}
	for actor: Dictionary in content.actors(int(data.chapter)):
		if actor.kind in Content.HOSTILE_KINDS: allowed_kills[actor.id] = true
	for item: Dictionary in content.items(int(data.chapter)): allowed_items[item.id] = true
	if data.chapter == 2:
		for item: Dictionary in content.optional_items(): allowed_items[item.id] = true
	for landmark: Dictionary in content.world_events(): allowed_landmarks[landmark.id] = true
	for id: String in data.killed:
		if not allowed_kills.has(id): return false
	for id: String in data.picked:
		if not allowed_items.has(id): return false
	for id: String in data.landmarks:
		if not allowed_landmarks.has(id): return false
	for id: String in data.memories:
		if not Quests.MEMORIES.has(id): return false
	for quest: String in ["bridge","bell"]:
		if data.events.has(quest) != data.claimed.has(quest): return false
	for key: String in ["skills","rewards_received","known_checkpoints","encountered"]:
		if not data.get(key) is Dictionary: return false
		for id: Variant in data[key]:
			if not (id is String or id is StringName) or data[key][id] != true: return false
	for id: String in data.skills:
		if id not in ["charge","perfect_dodge"]: return false
	if data.skills.has("charge") != (not data.embers.is_empty()): return false
	if data.skills.has("perfect_dodge") != data.events.has("well"): return false
	for id: String in data.rewards_received:
		if id not in ["bridge","bell"] or not data.claimed.has(id): return false
	for id: String in data.known_checkpoints:
		if not content.checkpoints.has(id) or (data.chapter == 1 and id in ["marsh","ash"]): return false
	if not data.known_checkpoints.has(data.checkpoint): return false
	if data.get("specialization") not in ["","spear","stone","survival"]: return false
	if data.specialization != "" and (data.chapter != 2 or data.stage < 4): return false
	for id: String in data.encountered:
		if id not in ["forest_cover","bear_lure","creek_cover","marsh_light","ash_valve","secret_branch"]: return false
	return true

static func migrate_v1(data: Dictionary) -> Dictionary:
	for key: String in ["embers","events","claimed"]:
		if not data.get(key,{}) is Dictionary: return {}
	if data.has("checkpoint") and not data.checkpoint is String: return {}
	var result: Dictionary = data.duplicate(true)
	result.skills = {}
	if not result.get("embers",{}).is_empty(): result.skills.charge = true
	if result.get("events",{}).has("well"): result.skills.perfect_dodge = true
	result.specialization = ""
	result.rewards_received = {}
	for quest: String in ["bridge","bell"]:
		if result.get("claimed",{}).has(quest): result.rewards_received[quest] = true
	result.known_checkpoints = {"camp":true}
	if result.has("checkpoint"): result.known_checkpoints[result.checkpoint] = true
	result.encountered = {}
	return result

func restore(data: Dictionary) -> void:
	for key: String in snapshot():
		if not data.has(key): continue
		if key in ["hp","potions","stones","herbs","deaths","damage_taken","chapter","stage","planks","bell_parts"]: set(key,int(data[key]))
		else: set(key,data[key])
