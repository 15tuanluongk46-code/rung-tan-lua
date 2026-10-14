extends Control
## Discovered regions and known landmarks; hidden areas stay unrevealed.
var game: Node
const Content = preload("res://scripts/world_content.gd")
const AREA: Rect2 = Rect2(22,24,300,300)

func _ready() -> void:
	custom_minimum_size = Vector2(340,324)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func map_point(point: Vector2) -> Vector2:
	return AREA.position + point/Content.SIZE * AREA.size

func _draw() -> void:
	if game.state == null: return
	var font: Font = load("res://assets/fonts/DejaVuSans.ttf")
	var font_size: int = 12 if game.settings.large_text else 10
	for region: String in Content.REGION_BOUNDS:
		var rect: Rect2 = Content.REGION_BOUNDS[region]
		var drawn := Rect2(map_point(rect.position),rect.size/Content.SIZE*AREA.size)
		var known: bool = game.state.discovered.has(region)
		draw_rect(drawn.grow(-2),Color("294c43") if known else Color("152529"))
		draw_rect(drawn.grow(-2),Color("887b53"),false,1)
		draw_string(font,drawn.position+Vector2(8,18),game.content.names[region] if known else "Chưa khám phá",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("e7be7b"))
	for road: PackedVector2Array in game.art.ROADS:
		for i: int in range(road.size()-1):
			if game.state.discovered.has(game.content.region_at(road[i])) and game.state.discovered.has(game.content.region_at(road[i+1])):
				draw_line(map_point(road[i]),map_point(road[i+1]),Color("b8a879"),2)
	for id: String in game.content.checkpoints:
		if game.state.discovered.has(id) and not game.state.known_checkpoints.has(id): draw_arc(map_point(game.content.checkpoints[id]),3,0,TAU,12,Color("9b9279"),1)
		if game.state.known_checkpoints.has(id): draw_circle(map_point(game.content.checkpoints[id]),3,Color("ffd18a"))
	for data: Dictionary in game.content.world_events():
		if game.state.landmarks.has(data.id):
			draw_rect(Rect2(map_point(data.pos)-Vector2(2,2),Vector2(4,4)),Color("a4d7d0"))
	draw_circle(map_point(game.player.position),4,Color("fff6cb"))
	if game.state.chapter == 2:
		var target: String = ["","lamp_0","well","","valve_0","boss",""][game.state.stage]
		for data: Dictionary in game.content.world_events():
			if data.id == target and game.state.landmarks.has(target):
				draw_arc(map_point(data.pos),6,0,TAU,16,Color("ffe4a0"),2)
				draw_string(font,map_point(data.pos)+Vector2(8,-5),"Mục tiêu",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe4a0"))
	draw_string(font,Vector2(22,337),"● Bạn / điểm nghỉ đã mở   ○ Chưa kích hoạt",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("d2dabc"))
	draw_string(font,Vector2(22,351),"■ Địa điểm đã biết · Đường đã khám phá",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("d2dabc"))
