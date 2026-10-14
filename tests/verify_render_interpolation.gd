extends SceneTree
## Separate raster diagnostic; readbacks never contaminate the timing benchmark.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	create_timer(35).timeout.connect(func() -> void: quit(2))
	Engine.max_fps = 120
	var mover := Node2D.new();mover.position=Vector2(90,160);root.add_child(mover)
	var square := Polygon2D.new()
	square.polygon=PackedVector2Array([Vector2.ZERO,Vector2(8,0),Vector2(8,8),Vector2(0,8)])
	square.color=Color(1,0,1);mover.add_child(square)
	var clock: Callable = func() -> void: mover.position.x += 1.8
	physics_frame.connect(clock)
	for enabled: bool in [false,true]:
		physics_interpolation=enabled;mover.position=Vector2(90,160);mover.reset_physics_interpolation()
		for i: int in range(8):await process_frame
		var positions: Array[float] = []
		for i: int in range(80):
			await RenderingServer.frame_post_draw
			var im: Image = root.get_texture().get_image();var count: int = 0;var total: float = 0
			for y: int in range(155,175):
				for x: int in range(70,400):
					var c: Color = im.get_pixel(x,y)
					if c.r>.9 and c.b>.9 and c.g<.1:total+=x;count+=1
			if count>0:positions.append(total/count)
		var repeats: int = 0
		for i: int in range(1,positions.size()):
			if absf(positions[i]-positions[i-1])<.01:repeats+=1
		print("RASTER MOTION interpolation=",enabled," samples=",positions.size()," repeated_positions=",repeats)
	physics_frame.disconnect(clock);quit()
