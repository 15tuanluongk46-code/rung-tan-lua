extends SceneTree
const State = preload("res://scripts/run_state.gd")
const Save = preload("res://scripts/save_manager.gd")
func _initialize() -> void:
	var store := Save.new()
	store.path = "user://save-restart-fixture.json"
	if "--write-fixture" in OS.get_cmdline_user_args():
		var state := State.new()
		state.accept("main")
		state.pickup("herb_0","herb")
		state.kill_actor("melee_0")
		state.activate_checkpoint("creek")
		state.stones = 8
		state.hp = 64
		var ok: bool = store.save_state(state)
		print("SAVE RESTART WRITE ",ok)
		quit(0 if ok else 1)
	else:
		var state = store.load_state()
		var ok: bool = state != null and state.hp == 64 and state.stones == 8 and state.checkpoint == "creek" and state.picked.has("herb_0") and state.killed.has("melee_0")
		print("SAVE RESTART READ ",ok,"; independent process, isolated fixture")
		quit(0 if ok else 1)
