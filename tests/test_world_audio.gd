extends SceneTree
## Detects missing interfaces, blocked routes/spawns, wrong collision/sort roots,
## non-looping streams, unbounded sound allocation and broken bus isolation.
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for path: String in ["res://scripts/world_art.gd", "res://scripts/audio_director.gd"]:
		check(ResourceLoader.exists(path), "implemented module " + path)
	if failures > 0:
		quit(1)
		return
	var world: Node2D = Node2D.new()
	root.add_child(world)
	var art: Node2D = load("res://scripts/world_art.gd").new()
	world.add_child(art)
	art.build(world)
	check(world.y_sort_enabled, "props and actors share a y-sort parent")
	check(art.position == Vector2.ZERO, "art preserves world coordinate contract")
	var count: int = world.get_child_count()
	art.build(world)
	check(world.get_child_count() == count, "build is idempotent")
	var trees: int = 0
	var scatter: int = 0
	var terrains: int = 0
	var bodies: int = 0
	var landmarks: Dictionary = {}
	for node: Node in world.get_children():
		if node.get_meta("category", "") == "tree": trees += 1
		if node.get_meta("category", "") == "scatter": scatter += 1
		if node.get_meta("category", "") == "landmark":
			var kind: String = node.get_meta("kind", "")
			landmarks[kind] = int(landmarks.get(kind,0))+1
		if node.get_meta("category", "") == "terrain":
			terrains += 1
			check(node.z_index == -20, "terrain never obscures actors")
			if node.texture != null:
				check(node.texture.get_size() == Vector2(1200,800), "terrain quadrants are unscaled 1200x800")
			elif "--require-assets" in OS.get_cmdline_user_args():
				check(false,"required terrain texture present " + node.name)
		if node.has_node("Art") and "--require-assets" in OS.get_cmdline_user_args():
			check(node.get_node("Art").texture != null,"required prop texture present " + node.name)
		for child: Node in node.get_children():
			if child is StaticBody2D:
				bodies += 1
				check(child.collision_layer == 1, "solid props block gameplay layer1")
	check(trees >= 190 and trees <= 210, "approximately 200 varied trees")
	check(scatter >= 240 and scatter <= 260, "approximately 250 bushes/rocks")
	check(terrains == 4, "all terrain quadrants instantiated")
	print("Layout census: trees=%d scatter=%d solids=%d landmarks=%s" % [trees,scatter,bodies,str(landmarks)])
	check(int(landmarks.get("tent",0)) >= 4,"shelters for camp NPCs and creek gatherer")
	check(int(landmarks.get("forge",0)) == 1,"smith has a forge")
	check(int(landmarks.get("table",0)) >= 2,"camp/creek work tables")
	check(int(landmarks.get("column",0)) >= 4 and int(landmarks.get("wall",0)) >= 4,"ruins have authored pillars and walls")
	check(bodies == art.obstacles.size() and bodies >= 220, "obstacle rectangles match solid prop bodies")
	var content: RefCounted = load("res://scripts/world_content.gd").new()
	for data: Dictionary in content.actors() + content.items():
		check(not art.is_blocked(data.pos,18), "safe authored spawn " + str(data.id))
	for point: Vector2 in content.centers.values() + content.checkpoints.values():
		check(not art.is_blocked(point,24), "clear region/checkpoint " + str(point))
	var roads: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(420,340),Vector2(430,470),Vector2(760,465),Vector2(1060,375),Vector2(1380,380),Vector2(1740,390),Vector2(1980,450)]),
		PackedVector2Array([Vector2(445,470),Vector2(410,720),Vector2(550,960),Vector2(530,1190),Vector2(760,1200),Vector2(1010,1160),Vector2(1420,1190),Vector2(1830,1190)]),
		PackedVector2Array([Vector2(1770,400),Vector2(1840,720),Vector2(1730,940),Vector2(1830,1190)]),
		PackedVector2Array([Vector2(830,1160),Vector2(830,1390)])]
	for road: PackedVector2Array in roads:
		for i: int in range(road.size()-1):
			for step: int in range(41):
				check(not art.is_blocked(road[i].lerp(road[i+1],step/40.0),24), "connected road has actor-width clearance")
	for rect: Rect2 in art.obstacles:
		check(art.is_blocked(rect.get_center()), "solid center query")
		check(art.is_blocked(rect.position-Vector2(2,2),3), "query expands for actor margin")
	# Every item/NPC gets an open connector to its nearest painted road.
	for data: Dictionary in content.actors()+content.items():
		var nearest: Vector2 = Vector2.ZERO
		var best: float = INF
		for road: PackedVector2Array in roads:
			for i: int in range(road.size()-1):
				var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(data.pos,road[i],road[i+1])
				if candidate.distance_squared_to(data.pos) < best:
					best = candidate.distance_squared_to(data.pos)
					nearest = candidate
		for step: int in range(21):
			check(not art.is_blocked(data.pos.lerp(nearest,step/20.0),18),"spawn connector " + str(data.id))
	var second_world: Node2D = Node2D.new()
	root.add_child(second_world)
	var second_art: Node2D = load("res://scripts/world_art.gd").new()
	second_world.add_child(second_art)
	second_art.build(second_world)
	check(art.obstacles == second_art.obstacles, "layout is deterministic across runs")
	second_world.queue_free()
	var listener: Node2D = Node2D.new()
	world.add_child(listener)
	var camera: Camera2D = Camera2D.new()
	listener.add_child(camera)
	art.set_listener(listener)
	var first_tree: Node2D
	for node: Node in world.get_children():
		if node.get_meta("category", "") == "tree":
			first_tree = node
			break
	listener.position = first_tree.position-Vector2(0,50)
	camera.make_current()
	await process_frame
	art.set_process(false)
	for i: int in range(25): art._process(0.02)
	var canopy: Sprite2D = first_tree.get_node("Art") as Sprite2D
	check(canopy.modulate.a < 0.4 and canopy.modulate.a > 0.2,"canopy fades behind player without hiding trunk")
	listener.position = first_tree.position+Vector2(0,35)
	for i: int in range(25): art._process(0.02)
	check(is_equal_approx(canopy.modulate.a,1.0),"canopy restores when player is in front")
	await physics_frame
	await physics_frame
	var solid: Rect2 = art.obstacles[0]
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(solid.get_center()-Vector2(60,0),solid.get_center()+Vector2(60,0),1)
	check(not world.get_world_2d().direct_space_state.intersect_ray(query).is_empty(),"real physics ray hits authored solid prop")
	var audio: Node = load("res://scripts/audio_director.gd").new()
	root.add_child(audio)
	audio.set_listener(listener)
	await process_frame
	for bus: String in ["Master","Music","Ambient","SFX"]:
		check(AudioServer.get_bus_index(bus) >= 0, "bus available " + bus)
	audio.set_volume("Music",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "zero volume mutes")
	audio.set_volume("Music",2)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "nonzero unmutes")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),0), "volume clamps to unity")
	for region: String in ["camp","forest","creek","ruins"]:
		audio.set_region(region)
		await process_frame
	check(audio.sfx_players.size() == 8, "SFX pool is exactly eight reusable voices")
	var streams_present: bool = FileAccess.file_exists("res://assets/music/camp.ogg")
	if streams_present:
		for stream: AudioStreamOggVorbis in audio.music_streams.values():
			check(stream.loop and stream.get_length() >= 24 and stream.get_length() <= 32.01, "music loop/duration contract")
		for stream: AudioStreamOggVorbis in audio.ambient_streams.values():
			check(stream.loop, "ambient loops in resource")
		for key: String in ["step","attack","hit","dodge","stone","pickup","heal","quest","death","click","bow"]:
			check(audio.sfx_streams.has(key), "required SFX loaded: " + key)
		audio.play_sfx("click")
		audio.play_sfx("click")
		var voices: int = 0
		for voice: AudioStreamPlayer in audio.sfx_players:
			if voice.playing: voices += 1
		check(voices == 1, "duplicate same-frame UI sounds are throttled")
		for voice: AudioStreamPlayer in audio.sfx_players: voice.stop()
		audio.play_sfx("hit",listener.global_position+Vector2(800,0))
		voices = 0
		for voice: AudioStreamPlayer in audio.sfx_players:
			if voice.playing: voices += 1
		check(voices == 0,"out-of-range sound is culled before voice allocation")
		audio.play_sfx("attack",listener.global_position+Vector2(300,0))
		var distant_db: float = audio.sfx_players[0].volume_db
		audio.sfx_players[0].stop()
		audio.play_sfx("stone",listener.global_position)
		check(distant_db < audio.sfx_players[0].volume_db-5,"SFX attenuates relative to explicit listener")
		audio.set_process(false)
		audio.set_region("camp")
		for i: int in range(32): audio._process(0.1)
		audio.set_region("forest")
		for i: int in range(14): audio._process(0.1)
		check(audio.music_players[0].playing and audio.music_players[1].playing,"region switch overlaps two music decks")
		check(absf(audio.music_players[0].volume_db-audio.music_players[1].volume_db) < 1,"mid-crossfade is equal power")
		for i: int in range(20): audio._process(0.1)
		var active_decks: int = 0
		for voice: AudioStreamPlayer in audio.music_players:
			if voice.playing: active_decks += 1
		check(active_decks == 1,"silent music deck stops after transition")
		check(audio.ambient_players.water.bus == "Ambient" and audio.ambient_players.water.volume_db <= -70,"forest fades creek water independently of Music")
	else:
		if "--require-assets" in OS.get_cmdline_user_args():
			check(false,"required audio assets present")
		else:
			print("SKIP: audio asset assertions; run tools/generate_audio.py first")
	audio.play_sfx("unknown-key")
	check(audio.sfx_players.size() == 8, "unknown SFX never allocates voices")
	audio.queue_free()
	world.queue_free()
	await process_frame
	# AudioServer owns decoder releases until its next mix quantum, not frame.
	await create_timer(0.15).timeout
	print("WORLD/AUDIO TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
