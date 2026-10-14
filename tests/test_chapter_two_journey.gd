extends "res://tests/test_user_journey.gd"
## Fixture begins at unlocked chapter II; subsequent progress uses input/UI.
func use_event(id: String) -> bool:
	if not await travel(game.world_events.nodes[id].position,8): return false
	# Allow the visible 80ms interaction selection to settle before pressing E.
	for i: int in range(8): await step()
	await tap("interact")
	if id.begins_with("memory_"):
		check(game.state.memories.has(id),"read memory "+id)
		await tap("pause")
	else: check(game.state.events.has(id),"event via E "+id)
	if not game.state.events.has(id) and not game.state.memories.has(id):
		print("EVENT DIAGNOSTIC id=",id," pos=",game.player.position," closest=",game.closest_interaction()," stage=",game.state.stage," mode=",game.mode," toast=",game.ui.toast.text," input_buffer=",game.player.buffered_actions," killed=",game.state.killed)
	return game.state.events.has(id) or game.state.memories.has(id)

func take_item(id: String) -> bool:
	if not game.item_nodes.has(id): return game.state.picked.has(id)
	if not await travel(game.item_nodes[id].position,16): return false
	for i: int in range(8): await step()
	await tap("interact")
	check(game.state.picked.has(id),"pickup via E "+id)
	return game.state.picked.has(id)

func run():
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await step()
	game.autosave_enabled = false
	game.start_game()
	# Targeted chapter fixture, distinct from a full two-chapter playthrough.
	game.state.accept("main")
	for id: String in ["forest","creek","ruins"]: game.state.pickup("ember_"+id,"ember",id)
	game.state.light_altar()
	game.state.finish_main()
	game.ui.ending()
	await click_button("Tiếp tục Chương II")
	total_limit = 200000
	check(game.state.chapter == 2 and game.mode == "playing","chapter II button opens expanded world")
	build_grid()
	if not await travel(game.content.checkpoints.marsh): return await finish()
	await tap("interact")
	check(game.state.checkpoint == "marsh","activate marsh checkpoint")
	if not await visit_npc("sen","Nhận việc: Cây cầu về nhà"): return await finish()
	for id: String in ["lamp_0","plank_0","lamp_1","plank_1","plank_2","lamp_2"]:
		if id.begins_with("lamp"):
			if not await use_event(id): return await finish()
		elif not await take_item(id): return await finish()
	if not await use_event("well"): return await finish()
	if not await use_event("bridge"): return await finish()
	build_grid()
	if not await use_event("memory_marsh"): return await finish()
	if not await visit_npc("tung","Nhận việc: Tiếng chuông dưới tro"): return await finish()
	if not await travel(game.content.checkpoints.ash): return await finish()
	await tap("interact")
	check(game.state.checkpoint == "ash","activate ash checkpoint")
	for id: String in ["bell_part_0","bell_part_1","bell_part_2"]:
		if not await take_item(id): return await finish()
	if not await use_event("bell"): return await finish()
	for id: String in ["valve_0","valve_1"]:
		if not await use_event(id): return await finish()
	build_grid()
	if not await use_event("memory_ash"): return await finish()
	if not await travel(game.content.checkpoints.ash): return await finish()
	await tap("interact")
	if not await travel(Vector2(1960,2140)): return await finish()
	check(game.state.events.has("boss"),"boss victory via real combat input")
	if not game.state.events.has("boss"): return await finish()
	if not await use_event("memory_tower"): return await finish()
	await tap("map")
	check(game.mode == "map","M opens discovered map")
	await tap("pause")
	check(game.mode == "playing","Esc closes map")
	if not await visit_npc("chief"): return await finish()
	check(game.state.ended and game.mode == "ending","chapter II final ending via An")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://captures")
		check(root.get_texture().get_image().save_png("user://captures/chapter-two-ending.png") == OK,"capture final ending")
	await finish()
