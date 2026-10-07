extends Node
## No autoload or scene-path dependency. Main owns settings and calls set_region.
## Eight pooled voices; attenuation is relative to Main.player, not the camera.
const REGIONS: Array[String] = ["camp", "forest", "creek", "ruins"]
const SFX_KEYS: Array[String] = ["step", "attack", "hit", "dodge", "stone", "pickup", "heal", "quest", "death", "click", "bow", "magic", "bear"]
const AMBIENCE: Dictionary = {
	"camp": {"wind":0.13, "water":0.0, "birds":0.30, "fire":0.50},
	"forest": {"wind":0.42, "water":0.0, "birds":0.62, "fire":0.0},
	"creek": {"wind":0.17, "water":0.58, "birds":0.40, "fire":0.12},
	"ruins": {"wind":0.46, "water":0.0, "birds":0.07, "fire":0.0}}
const THROTTLES: Dictionary = {"step":0.12, "attack":0.07, "hit":0.055, "dodge":0.10, "stone":0.07, "click":0.075, "quest":0.3}
var sfx_players: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var music_streams: Dictionary = {}
var ambient_streams: Dictionary = {}
var sfx_streams: Dictionary = {}
var ambient_players: Dictionary = {}
var listener: Node2D
var region: String = ""
var _last_played: Dictionary = {}
var _voice_priority: Array[int] = []
var _voice_serial: int = 0
var _voice_started: Array[int] = []
var _music_target: int = 0
var _music_mix: float = 0.0
var _ambient_mix: Dictionary = {"wind":0.0, "water":0.0, "birds":0.0, "fire":0.0}
var _clock: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	_ensure_buses()
	for key: String in REGIONS:
		var stream: AudioStreamOggVorbis = _load_ogg("res://assets/music/%s.ogg" % key, true)
		if stream != null: music_streams[key] = stream
	for key: String in _ambient_mix:
		var stream: AudioStreamOggVorbis = _load_ogg("res://assets/ambient/%s.ogg" % key, true)
		if stream != null: ambient_streams[key] = stream
		var voice: AudioStreamPlayer = _player("Ambient_" + key, "Ambient")
		voice.stream = stream
		voice.volume_db = -80
		ambient_players[key] = voice
	for key: String in SFX_KEYS:
		var stream: AudioStreamOggVorbis = _load_ogg("res://assets/sfx/%s.ogg" % key, false)
		if stream != null: sfx_streams[key] = stream
	for index: int in range(2):
		var voice: AudioStreamPlayer = _player("Music_" + str(index), "Music")
		voice.volume_db = -80
		music_players.append(voice)
	for index: int in range(8):
		sfx_players.append(_player("SFX_" + str(index), "SFX"))
		_voice_priority.append(0)
		_voice_started.append(0)
	_initialized = true
	set_region("camp")

func _ensure_buses() -> void:
	for bus: String in ["Music", "Ambient", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")

func _player(node_name: String, bus: String) -> AudioStreamPlayer:
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.name = node_name
	voice.bus = bus
	add_child(voice)
	return voice

func _load_ogg(path: String, looping: bool) -> AudioStreamOggVorbis:
	var stream: AudioStreamOggVorbis = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStreamOggVorbis
	elif FileAccess.file_exists(path):
		# Development before the first editor import; exports use ResourceLoader.
		stream = AudioStreamOggVorbis.load_from_file(path)
	if stream != null:
		stream.loop = looping
		stream.loop_offset = 0.0
	else:
		push_warning("Audio asset absent: " + path + "; run tools/generate_audio.py")
	return stream

func set_volume(bus: String, value: float) -> void:
	if bus not in ["Master", "Music", "Ambient", "SFX"]: return
	_ensure_buses()
	var index: int = AudioServer.get_bus_index(bus)
	var amount: float = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.0001)))
	AudioServer.set_bus_mute(index, amount <= 0.0)

func set_listener(node: Node2D) -> void:
	listener = node

func set_region(next_region: String) -> void:
	if not _initialized or next_region not in REGIONS or next_region == region: return
	region = next_region
	if not music_streams.has(region): return
	var stream: AudioStreamOggVorbis = music_streams[region]
	# Reverse an in-flight transition without restarting either side.
	for index: int in range(2):
		if music_players[index].stream == stream:
			_music_target = index
			if not music_players[index].playing: music_players[index].play()
			return
	# Replace the quieter deck when a third region is crossed during a fade.
	_music_target = 0 if _music_mix >= 0.5 else 1
	var voice: AudioStreamPlayer = music_players[_music_target]
	voice.stream = stream
	voice.volume_db = -80
	voice.play(fmod(_clock, 28.0))

func _listener_position() -> Vector2:
	if is_instance_valid(listener): return listener.global_position
	var parent: Node = get_parent()
	if parent != null:
		# The integration contract provides Main.player; no hardcoded node path.
		for property: Dictionary in parent.get_property_list():
			if property.name == "player":
				var candidate: Node2D = parent.get("player") as Node2D
				if is_instance_valid(candidate): return candidate.global_position
	return Vector2(430, 450)

func play_sfx(key: String, world_position: Vector2 = Vector2.ZERO) -> void:
	if not sfx_streams.has(key) or sfx_players.is_empty(): return
	var now: float = Time.get_ticks_msec() * 0.001
	var gap: float = float(THROTTLES.get(key, 0.065))
	if now - float(_last_played.get(key, -100.0)) < gap: return
	var gain: float = 1.0
	if world_position != Vector2.ZERO:
		var distance: float = _listener_position().distance_to(world_position)
		if distance >= 620: return
		gain = pow(clampf(1.0 - maxf(0, distance - 35) / 585.0, 0, 1), 1.65)
	var priority: int = 2 if key in ["quest", "death", "heal"] else (0 if key == "step" else 1)
	var selected: int = -1
	var oldest: int = 2147483647
	for index: int in range(sfx_players.size()):
		if not sfx_players[index].playing:
			selected = index
			break
		if _voice_priority[index] <= priority and _voice_started[index] < oldest:
			selected = index
			oldest = _voice_started[index]
	if selected < 0: return
	var voice: AudioStreamPlayer = sfx_players[selected]
	voice.stop()
	voice.stream = sfx_streams[key]
	voice.pitch_scale = 1.0 + sin(float(_voice_serial) * 2.399) * (0.05 if key in ["step", "hit", "attack"] else 0.0)
	voice.volume_db = linear_to_db(maxf(0.0001, gain)) - (8.0 if key == "step" else 2.0)
	voice.play()
	_last_played[key] = now
	_voice_priority[selected] = priority
	_voice_serial += 1
	_voice_started[selected] = _voice_serial

func _process(delta: float) -> void:
	if not _initialized: return
	_clock += delta
	_music_mix = move_toward(_music_mix, float(_music_target), delta / 2.8)
	for index: int in range(2):
		var gain: float = sqrt(_music_mix if index == 1 else 1.0 - _music_mix) * 0.63
		music_players[index].volume_db = linear_to_db(maxf(0.0001, gain))
		if gain < 0.0001 and index != _music_target: music_players[index].stop()
	var targets: Dictionary = AMBIENCE.get(region, AMBIENCE.camp)
	for key: String in ambient_players:
		var voice: AudioStreamPlayer = ambient_players[key]
		var gain: float = move_toward(float(_ambient_mix[key]), float(targets[key]), delta * 0.22)
		_ambient_mix[key] = gain
		voice.volume_db = linear_to_db(maxf(0.0001, gain))
		if gain > 0.001 and voice.stream != null and not voice.playing:
			voice.play(fmod(_clock, 28.0))
		elif gain <= 0.001 and voice.playing:
			voice.stop()

func _exit_tree() -> void:
	# Release decoders as well as child nodes when Main is replaced/replayed.
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	music_streams.clear()
	ambient_streams.clear()
	sfx_streams.clear()
