extends Node2D
## Four-facing original pixel sprites; grounded animation and legible action poses.
var sprite: Sprite2D
var kind: String = "player"
var shadow: Sprite2D
var flash: float = 0.0
var last_action: String = ""
var action_started: float = 0.0
var trail: Line2D

func setup(actor_kind: String) -> void:
	kind = actor_kind
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow = Sprite2D.new()
	var image: Image = Image.create(32, 12, false, Image.FORMAT_RGBA8)
	for y: int in range(12):
		for x: int in range(32):
			var distance: float = Vector2((float(x)-16.0)/16.0,(float(y)-6.0)/6.0).length()
			if distance < 1.0: image.set_pixel(x,y,Color(0.03,0.09,0.09,(1.0-distance)*0.5))
	shadow.texture = ImageTexture.create_from_image(image)
	shadow.position.y = -1
	shadow.scale = Vector2(1.2,1.0) if kind == "bear" else Vector2(0.7,0.65)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/%s.png" % kind)
	sprite.hframes = 6
	sprite.vframes = 4
	sprite.position = Vector2(0,-21)
	add_child(sprite)
	trail = Line2D.new()
	trail.width = 2.0
	trail.default_color = Color("f6d7a1")
	trail.visible = false
	add_child(trail)

func pose(facing: Vector2, moving: bool, action: String, elapsed: float) -> void:
	if sprite == null: return
	if action != last_action:
		action_started = elapsed
		last_action = action
	var phase: float = elapsed - action_started
	var row: int = 0
	if absf(facing.x) > absf(facing.y): row = 1 if facing.x < 0 else 2
	elif facing.y < 0: row = 3
	var frame: int = 0
	if moving: frame = 1 + int(elapsed * (12.0 if action == "flee" else 8.0)) % 3
	elif int(elapsed * 1.2) % 4 == 3: frame = 2
	sprite.rotation = 0
	sprite.scale = Vector2.ONE
	sprite.position = Vector2(0,-21)
	sprite.modulate = Color.WHITE
	trail.visible = false
	shadow.modulate.a = 1
	if action == "windup":
		frame = 4
		sprite.position -= facing * 3
		sprite.modulate = Color(1.0,0.78 + 0.15*sin(phase*25),0.66)
	elif action in ["attack","throw","work"]:
		frame = 4 if int(phase * 9) % 3 != 2 else 0
		var thrust: float = sin(minf(phase * 9,PI))
		sprite.position += facing * thrust * 3
		if action == "attack" and phase < 0.3:
			trail.visible = true
			trail.clear_points()
			var angle: float = facing.angle()
			for i: int in range(9):
				var a: float = angle - 0.65 + float(i)/8.0*1.3
				trail.add_point(Vector2(cos(a),sin(a))*25.0 + Vector2(0,-10))
			trail.modulate.a = maxf(0,1-phase/0.3)
	elif action == "dodge":
		frame = 2
		sprite.rotation = facing.x * 0.35
		sprite.position.y -= sin(minf(phase*12,PI))*5
		shadow.modulate.a = 0.5
	elif action == "hurt":
		frame = 5
		sprite.position.x += sin(phase*70)*2
	elif action == "dead":
		frame = 5
		sprite.rotation = PI*0.5
		sprite.position = Vector2(0,-7)
		sprite.modulate = Color(0.57,0.57,0.5,0.76)
		shadow.scale.x = 1.0
	if kind == "bird" and action == "flee": sprite.position.y -= 12 + sin(elapsed*5)*3
	sprite.frame = row * 6 + frame
