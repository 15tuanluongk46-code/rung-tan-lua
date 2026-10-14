extends SceneTree
## Automated real-world traversal using InputMap and UI buttons. No teleports,
## inventory grants, direct quest completion, damage injection or invulnerability.
var game: Node
var failures: int = 0
var checks: int = 0
var grid := AStarGrid2D.new()
var previous_actions: Dictionary = {}
var ticks: int = 0
var total_limit: int = 72000
var focus_pauses: int = 0

func ui_text(node: Node) -> String:
	var result: String = node.text + "\n" if node is Label else ""
	for child: Node in node.get_children(): result += ui_text(child)
	return result

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1

func button_named(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child: Node in node.get_children():
		var found: Button = button_named(child,text)
		if found != null: return found
	return null

func set_action(action: String, down: bool) -> void:
	if bool(previous_actions.get(action,false)) == down: return
	previous_actions[action] = down
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)

func release_inputs() -> void:
	for action: String in previous_actions.keys(): set_action(action,false)

func step() -> void:
	await physics_frame
	# Continue after all nodes have processed the physics tick.
	await process_frame
	ticks += 1
	if ticks > total_limit:
		printerr("FAIL: journey exceeded bounded tick budget")
		quit(2)

func tap(action: String) -> void:
	set_action(action,true)
	await step()
	await step()
	set_action(action,false)
	await step()

func click_button(text: String) -> bool:
	release_inputs()
	var button: Button = button_named(game.ui.modal,text)
	if button == null:
		print("MISSING BUTTON CONTEXT mode=",game.mode," pos=",game.player.position," prompt=",game.ui.cached_interaction," modal=",ui_text(game.ui.modal))
		check(false,"button exists: " + text)
		return false
	button.grab_focus()
	await tap("ui_accept")
	return true

func cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / 16),floori(point.y / 16))

func build_grid() -> void:
	grid.region = Rect2i(0,0,int(game.content.SIZE.x/16),int(game.content.SIZE.y/16))
	grid.cell_size = Vector2(16,16)
	grid.offset = Vector2(8,8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y: int in range(int(game.content.SIZE.y/16)):
		for x: int in range(150):
			var point := Vector2(x*16+8,y*16+8)
			grid.set_point_solid(Vector2i(x,y),game.point_blocked(point,12))

func closest_enemy(radius: float) -> Node:
	var best: Node = null
	for actor: Node in game.actors:
		if actor.dead or actor.faction not in ["goblin","bear"]: continue
		var distance: float = game.player.position.distance_to(actor.position)
		if actor.kind == "guardian" and distance < 155 and game.state.stage == 5: distance *= 0.5
		if distance < radius and game.line_clear(game.player.position,actor.position):
			best = actor
			radius = distance
	return best

func aim(point: Vector2) -> void:
	# Virtual world-space pointer goes through the player's ordinary aim calculation.
	# No OS mouse movement and no mutation of facing/damage/quest state.
	game.player.set_test_aim(point)

func move_towards(point: Vector2) -> void:
	var delta: Vector2 = point-game.player.position
	set_action("move_left",delta.x < -3)
	set_action("move_right",delta.x > 3)
	set_action("move_up",delta.y < -3)
	set_action("move_down",delta.y > 3)

func travel(destination: Vector2, tolerance: float = 20) -> bool:
	var path: PackedVector2Array = []
	var repath: int = 0
	var target_actor: Node = null
	for actor: Node in game.actors:
		if actor.faction in ["goblin","bear"] and actor.position.distance_to(destination) < 1:
			target_actor = actor
			break
	for attempt: int in range(14000):
		if game.mode == "dying":
			release_inputs()
			await step()
			continue
		if is_instance_valid(target_actor) and target_actor.dead:
			release_inputs()
			await step()
			return true
		if game.mode == "dead":
			print("JOURNEY: death at ",game.player.position,"; recovering via UI")
			await click_button("Đứng dậy")
			path.clear()
		if game.mode == "paused":
			# Desktop focus changes legitimately auto-pause. Resume through the UI,
			# recording the interruption instead of disabling production focus handling.
			focus_pauses += 1
			print("JOURNEY: auto-pause; resume via UI, window_focus=",root.has_focus())
			if focus_pauses > 10 or not await click_button("Tiếp tục"):
				check(false,"bounded focus interruptions")
				return false
		if game.mode != "playing":
			check(false,"travel remains in playing mode: " + game.mode)
			return false
		if game.state.hp <= 60 and game.state.potions > 0:
			await tap("heal")
		var enemy: Node = closest_enemy(100)
		if enemy != null:
			aim(enemy.position)
			if attempt%1000 == 0: print("COMBAT DIAGNOSTIC ",enemy.actor_id," dist=",game.player.position.distance_to(enemy.position)," facing_dot=",game.player.facing.dot((enemy.position-game.player.position).normalized())," action=",game.player.action," hp=",enemy.health.hp," mouse=",game.player.get_global_mouse_position())
			var offset: Vector2 = game.player.position-enemy.position
			var distance: float = offset.length()
			set_action("spear",true)
			var ranged: bool = enemy.kind in ["archer","shaman"]
			var desired: Vector2 = enemy.position + offset.normalized()*(24 if ranged else 30)
			if enemy.kind == "guardian":
				desired = enemy.position + offset.normalized()*27
				if enemy.ai_state == "windup":
					set_action("spear",false)
					desired = enemy.position + offset.normalized()*105
					if enemy.attack_kind == 1: desired = game.player.position + (game.player.position-enemy.target_point).normalized()*80 if game.player.position.distance_to(enemy.target_point) > 2 else game.player.position+offset.orthogonal().normalized()*80
					if enemy.timer < 0.23 and game.player.dodge_cooldown <= 0:
						move_towards(desired)
						await tap("dodge")
				elif enemy.ai_state == "recover" and game.state.stones > 0 and game.player.throw_cooldown <= 0:
					await tap("throw")
			if ranged and distance < 42:
				# Circle inside spear range instead of endlessly retreating from windups.
				desired = enemy.position + offset.normalized().rotated(0.5)*28
			if enemy.kind != "guardian" and enemy.ai_state == "windup" and distance < 50:
				desired = game.player.position + (offset.orthogonal().normalized() if ranged else offset.normalized())*45
				if enemy.ai_state == "windup" and game.player.dodge_cooldown <= 0:
					move_towards(desired)
					await tap("dodge")
			if ranged and game.state.stones > 0 and game.player.throw_cooldown <= 0 and distance > 50:
				await tap("throw")
			if game.point_blocked(desired,10):
				for angle: float in [0.7,-0.7,1.4,-1.4,2.2,-2.2,PI]:
					var alternative: Vector2 = game.player.position + (desired-game.player.position).normalized().rotated(angle)*24
					if not game.point_blocked(alternative,12):
						desired = alternative
						break
			move_towards(desired)
			path.clear()
		else:
			set_action("spear",false)
			if game.player.position.distance_to(destination) <= tolerance:
				release_inputs()
				await step()
				return true
			repath -= 1
			if path.is_empty() or repath <= 0:
				var start: Vector2i = cell(game.player.position)
				var end: Vector2i = cell(destination)
				# Moving enemies can occupy the conservative grid clearance around cover.
				# Pick a reachable approach cell; never alter production collision.
				if grid.is_point_solid(end):
					var original_end: Vector2i = end
					var best: float = INF
					for y: int in range(-4,5):
						for x: int in range(-4,5):
							var candidate := original_end+Vector2i(x,y)
							if not grid.region.has_point(candidate) or grid.is_point_solid(candidate): continue
							var score: float = Vector2(x,y).length_squared()
							if score < best:
								best = score
								end = candidate
				if grid.is_point_solid(start):
					move_towards(destination)
					await step()
					continue
				path = grid.get_point_path(start,end)
				repath = 90
				if path.is_empty():
					check(false,"reachable route to " + str(destination))
					return false
			while path.size() > 1 and game.player.position.distance_to(path[0]) < 12: path.remove_at(0)
			move_towards(path[0])
		await step()
	var remaining: Array[String] = []
	for actor: Node in game.actors:
		if not actor.dead and actor.faction in ["goblin","bear"]: remaining.append("%s hp=%d pos=%s" % [actor.actor_id,actor.health.hp,actor.position])
	print("REMAINING: ",remaining)
	check(false,"travel deadline at %s to %s hp=%d" % [game.player.position,destination,game.state.hp])
	release_inputs()
	return false

func visit_npc(kind: String, option: String = "") -> bool:
	if not await travel(game.actor_by_id(kind).position): return false
	await tap("interact")
	if not option.is_empty(): return await click_button(option)
	return true

func run():
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await step()
	await step()
	await click_button("Bắt đầu hành trình")
	check(game.mode == "playing" and game.actors.size() == 28,"menu starts 28-actor session")
	build_grid()
	if not await visit_npc("chief","Tôi sẽ mang lửa về"): return await finish()
	if not await visit_npc("healer","Nhận việc: năm cây thuốc"): return await finish()
	if not await visit_npc("hunter","Nhận việc: tìm túi của Lâm"): return await finish()
	check(game.state.accepted.size() == 3,"all three quests accepted via dialogue buttons")
	for id: String in ["herb_0","herb_1","ember_forest","herb_2","herb_3","herb_4","hunter_bag","ember_creek","ember_ruins"]:
		if not game.item_nodes.has(id):
			check(false,"expected pickup available " + id)
			return await finish()
		var data: Dictionary = game.item_nodes[id].get_meta("data")
		for guard_id: String in data.get("guards",[]):
			var guard: Node = game.actor_by_id(guard_id)
			if guard != null and not guard.dead:
				if not await travel(guard.position): return await finish()
		if not await travel(game.item_nodes[id].position): return await finish()
		await tap("interact")
		check(game.state.picked.has(id),"collected through E: " + id)
		if not game.state.picked.has(id):
			print("PICKUP DIAGNOSTIC mode=",game.mode," prompt=",game.closest_interaction()," toast=",game.ui.toast.text," killed=",game.state.killed)
			return await finish()
		print("JOURNEY: ",id," hp=",game.state.hp," kills=",game.state.killed.size()," deaths=",game.state.deaths)
	# Make reward room only by throwing actual stones and using actual healing.
	while game.state.stones > 22:
		await tap("throw")
		for i: int in range(36): await step()
	if not await visit_npc("healer","Trao dược thảo"): return await finish()
	check(game.state.claimed.has("herbs"),"Mai reward delivered once")
	if not await visit_npc("hunter","Trả túi cho Lâm"): return await finish()
	check(game.state.claimed.has("bag"),"Lam reward delivered once")
	if not await travel(Vector2(1810,1190)): return await finish()
	await tap("interact")
	check(game.state.altar_lit,"three embers light altar via E")
	if not await visit_npc("chief"): return await finish()
	check(game.mode == "ending" and game.state.ended,"return to An opens ending")
	check(game.state.claimed.size() == 2 and game.state.embers.size() == 3,"ending retains completed main and both side quests")
	var summary: String = ui_text(game.ui.modal)
	check(("Kẻ địch đã hạ: %d · Số lần ngã: %d" % [game.state.killed.size(),game.state.deaths]) in summary and ("Tổng sát thương đã nhận: %d" % game.state.damage_taken) in summary and "Nhiệm vụ phụ hoàn thành: 2/2" in summary and game.time_text() in summary,"ending visible statistics match authoritative run state")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://captures")
		check(root.get_texture().get_image().save_png("user://captures/journey-ending.png") == OK,"save actual ending screenshot")
	print("JOURNEY RESULT: elapsed=%s kills=%d deaths=%d damage=%d focus_pauses=%d" % [game.time_text(),game.state.killed.size(),game.state.deaths,game.state.damage_taken,focus_pauses])
	await click_button("Một hành trình mới")
	check(game.mode == "playing" and game.state.hp == 100 and game.state.potions == 3 and game.state.stones == 12,"replay resets player and inventory")
	check(game.state.accepted.is_empty() and game.state.claimed.is_empty() and game.state.picked.is_empty() and game.state.killed.is_empty() and not game.state.ended,"replay clears all progression")
	check(game.actors.size() == 28 and game.item_nodes.size() == 15,"replay restores actors and all pickups")
	check(game.state.deaths == 0 and game.state.damage_taken == 0 and not game.state.altar_lit and game.state.checkpoint == "camp" and game.state.elapsed < 2,"replay resets statistics altar and checkpoint")
	await finish()

func finish() -> void:
	release_inputs()
	game.queue_free()
	await process_frame
	# --fixed-fps runs simulated seconds faster than the audio driver's wall clock.
	var audio_deadline: int = Time.get_ticks_msec() + 350
	while Time.get_ticks_msec() < audio_deadline: await process_frame
	print("USER JOURNEY: %d checks, %d failures; InputMap + UI-driven bot, not human visual QA" % [checks,failures])
	quit(1 if failures else 0)
