extends RefCounted
## Immutable quest definitions shared by journal, progression and save validation.
const QUESTS: Dictionary = {
	"main":{"title":"Ba tàn lửa", "chapter":1},
	"herbs":{"title":"Thuốc của Mai", "chapter":1},
	"bag":{"title":"Túi của Lâm", "chapter":1},
	"sources":{"title":"Đường Lửa Thức Giấc", "chapter":2},
	"bridge":{"title":"Cây cầu về nhà", "chapter":2},
	"bell":{"title":"Tiếng chuông dưới tro", "chapter":2}}
const STAGES: Array[String] = ["Gặp người giữ đèn Sen tại Chòi Gác Cũ.", "Thắp ba đèn dẫn đường trong Đầm Sương.", "Thanh tẩy Giếng Nguồn ở phía đông đầm.", "Gặp thợ lò Tùng tại Lò Cũ ở Đồi Than.", "Khôi phục hai van lò để mở đường Tháp Lửa.", "Đánh bại Người Giữ Than tại Tháp Lửa.", "Trở về gặp An ở Trại Tro."]
const EVENTS: Array[String] = ["lamp_0","lamp_1","lamp_2","well","valve_0","valve_1","bridge","bell","boss"]
const MEMORIES: Dictionary = {
	"memory_marsh":"Miếu Chìm: Người giữ đèn từng đưa từng gia đình qua đầm. Nước trong và ánh lửa cùng nuôi sống rừng.",
	"memory_ash":"Bia Lò Cũ: Người Giữ Than khóa tháp để ngăn lửa lan vào làng. Giờ đây lời thề cũ đã trở thành xiềng xích.",
	"memory_tower":"Tháp Lửa: Khi nước nguồn trở lại, than không còn thiêu đốt. Ngọn lửa có thể sưởi ấm thêm một lần nữa."}
