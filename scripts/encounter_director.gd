extends Node2D
## Authored encounter hints and optional light-revealed treasure, no forced waves.
var game: Node
const ENCOUNTERS: Array[Dictionary] = [
	{"id":"forest_cover","point":Vector2(1470,360),"hint":"Cung thủ sau lính giáo: vòng qua đá hoặc dụ lính ra trước."},
	{"id":"bear_lure","point":Vector2(1470,600),"hint":"Gấu không đứng cùng phe yêu tinh. Ném đá vào địch để kéo tiếng động tới gấu."},
	{"id":"creek_cover","point":Vector2(820,1300),"hint":"Pháp sư khóa hướng đạn. Chờ đạn chạm đá rồi đổi góc tiếp cận."},
	{"id":"marsh_light","point":Vector2(680,1930),"hint":"Đèn làm lộ Kẻ Rình Sương và cho bạn thêm nhịp đọc đòn lao."},
	{"id":"ash_valve","point":Vector2(1760,1930),"hint":"Dụ Lính Than nện xa van. Đâm tích lực có thể ngắt đòn chuẩn bị."},
	{"id":"secret_branch","point":Vector2(760,2050),"hint":"Dấu đường dưới ánh đèn dẫn tới tiếp tế; bạn có thể đi vòng thay vì đánh."}]
var secret: Node2D
var clock: float = 0.0
func _ready() -> void:
	z_index = -2
func _process(delta: float) -> void:
	if game.mode != "playing" or game.player == null: return
	clock -= delta
	if clock > 0: return
	clock = 0.25
	for encounter: Dictionary in ENCOUNTERS:
		if game.state.chapter == 1 and encounter.point.y > 1600: continue
		if encounter.point.distance_to(game.player.position) < 130 and not game.state.encountered.has(encounter.id):
			game.state.encountered[encounter.id] = true
			game.state.changed.emit()
			game.notify(encounter.hint)
	if game.state.chapter == 2 and game.world_events.is_lit(Vector2(860,2130)) and not game.state.picked.has("light_cache") and not game.item_nodes.has("light_cache"):
		game.spawn_item({"id":"light_cache","kind":"potion","pos":Vector2(1030,2150)})
	queue_redraw()
func _draw() -> void:
	if game.state == null or game.state.chapter != 2 or not game.world_events.is_lit(Vector2(860,2130)): return
	for i: int in range(8):
		var point := Vector2(870+i*20,2130+i*2)
		draw_line(point,point+Vector2(4,0),Color("c5d6a1"),1)
