extends Node2D
## Local marker animation, independent from interaction/quest authority.
var game: Node
var kind: String = "ember"
var clock: float = 0.0
var flame: Sprite2D
var refresh: float = 0.0

func _ready() -> void:
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit
	if kind == "altar":
		flame = Sprite2D.new()
		flame.texture = preload("res://assets/props/ember.png")
		flame.position = Vector2(0,-36)
		add_child(flame)

func _process(delta: float) -> void:
	if game.mode not in ["playing","test"]: return
	if game.player != null and global_position.distance_to(game.player.global_position) > 550: return
	clock += delta
	refresh -= delta
	if refresh > 0: return
	refresh = 0.08
	if flame != null:
		flame.visible = game.state != null and game.state.altar_lit
		flame.position.y = -37 if game.settings.reduced_motion else -37+sin(clock*2.7)*2
		flame.scale = Vector2(1.25 if game.settings.reduced_motion else 1.25+sin(clock*4)*0.06,1.45)
	queue_redraw()

func _draw() -> void:
	var lit: bool = kind == "ember" or (game.state != null and game.state.altar_lit)
	if not lit: return
	var origin := Vector2(0,-36 if kind == "altar" else -12)
	for radius: int in [22,16,10]:
		draw_circle(origin,radius,Color(1,0.55,0.15,0.025))
	for i: int in range(6):
		var phase: float = fposmod(clock*0.45+i/6.0,1.0)
		var point: Vector2 = origin + Vector2(sin(i*2.4+clock)*10,-phase*24)
		draw_rect(Rect2(point.round(),Vector2(1,2)),Color(1,0.76,0.35,(1-phase)*0.7))
	if kind == "ember" and game != null and game.player != null:
		var distance: float = global_position.distance_to(game.player.global_position)
		if distance < 76:
			var proximity: float = 1.0 - distance/76.0
			draw_arc(origin,14+sin(clock*5.0)*2.0,0,TAU,24,Color(1.0,0.78,0.35,0.18+proximity*0.32),1)
