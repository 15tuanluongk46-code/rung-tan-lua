# Chương II — Đường Lửa Thức Giấc

Ngày 11/10/2026. Source chính thức: `C:/Users/ADMIN/AI-Home/projects/rung-tan-lua`.

## Nội dung thực hiện

- Map 2400×2400; giữ bốn vùng gốc, thêm Đầm Sương và Đồi Than ở phía nam.
- Chương I giữ 28 actor/15 pickup gốc. Chương II thêm 13 actor và 12 pickup:
  Sen, Tùng, 4 Kẻ Rình Sương, 4 Lính Than, Người Giữ Than, hươu/chim.
- 18 thiết kế actor tổng cộng. 5 sheet mới 288×192, 4 hướng, 6 frame.
- Quest Chương II: Sen → 3 đèn → Giếng Nguồn → Tùng → 2 van → boss → An.
- Hai side quest mới: 3 gỗ mở cầu shortcut, 3 mảnh chuông mở điểm nghỉ phụ.
- Ba ký ức tùy chọn. Phím M mở map khám phá, Esc đóng, journal theo chương.
- Boss 400 HP, 2 pha, quét giáo/nện đất/vệt than; telegraph khóa hướng/vị trí,
  recovery, phạm vi đấu trường; thắng được giữ sau chết/load.
- Cổng phía nam/cổng tháp/cầu gãy có collision và dấu hiệu hình ảnh; mở theo state.
- Bùn giảm tốc nhẹ, than nóng có chu kỳ cảnh báo; roads an toàn vẫn thông thoáng.
- 12 props mới, 2 terrain riêng, 3 score mới (marsh/ash/boss), lighting/mist riêng.
- Save một slot version=1, file tạm xác thực trước thay thế, backup hợp lệ trước đó,
  fallback khi primary hỏng, menu Tiếp tục và xác nhận thay save khi new game.
- Autosave gom event hoàn chỉnh; tiêu đá/mất HP/nhặt đồ/quest/checkpoint/khám phá
  đều gửi thay đổi. Test và capture không ghi đè save người dùng.

## Kiểm thử

Full headless: visual 16/16, gameplay 71/71, integration 37/37, runtime 18/18,
play regression 24/24, delivery 0 failures, UI input 18/18,
world/audio 3928/3928. Python asset/audio: 9 tests passed.
Expansion regressions: 38/38 gồm quest order, gate/shortcut, one-time reward,
boss phase/victory/no-respawn, new run, continue HP/checkpoint, snapshot validation,
invalid/fractional states và corrupt-primary backup recovery.
Hai process độc lập test save: WRITE true / READ true trên slot fixture riêng.

Journey Chương I graphical: 22/22, 0 deaths, ending/replay hợp lệ.
Journey Chương II graphical: 25/25, NPC/quest/loot/world events/boss bằng input/UI,
map và ending cuối render thực. Chương II khởi đầu bằng fixture mở chương;
không tuyên bố đó là một lượt hai chương liên tục hoặc thời lượng người chơi.

Các lỗi phát hiện và sửa: PackedVector2Array const; Array[Dictionary] thoại NPC;
StringName/JSON float validation; điểm sửa cầu nằm trong collider; journal chọn
nhầm child; bot mouse event không cập nhật absolute pointer, sửa bằng viewport
warp_mouse; boss ra ngoài court, thêm giới hạn đấu trường.

## Hiệu năng và hình ảnh

GTX 1050 Ti, Windows/OpenGL Compatibility, 180-frame samples sau 60 warmup.

| Vùng | FPS | p95 ms |
|---|---:|---:|
| Trại Tro | 120.01 | 9.96 |
| Rừng Sâu | 120.01 | 10.80 |
| Bờ Suối | 119.99 | 9.93 |
| Phế Tích | 120.00 | 9.94 |
| Đầm Sương | 119.51 | 11.77 |
| Đồi Than | 119.97 | 9.90 |

Không phải cam kết FPS dài hạn/máy khác. Baseline camp chạy lại 120.04 FPS;
mẫu cũ 74.61 không đủ chứng minh performance regression.
Screenshots: `docs/screenshots/expansion/`, gồm regions, journal/map,
3 boss telegraphs và ending. Fixtures screenshot tách biệt khỏi journey.

## Giới hạn và bàn giao

- Chưa human playthrough/cân bằng thời lượng 20–35 phút Chương II.
- Chưa stress test dài/multi-hardware; chưa nghiệm thu thẩm mỹ bởi người dùng.
- Save không checkpoint vị trí giữa combat; tiếp tục tại điểm nghỉ hợp lệ,
  giữ inventory/HP/quest, survivors khởi tạo lại theo thiết kế.
- Không commit/push/publish. Linux release cũ không đại diện bản mở rộng mới.
- Windows executable/PCK nhúng và source ZIP có SHA256 tại build/.
- Windows export task `9d13aa78-0c3b-4e12-84f3-09908b7add6d`: exit 0,
  executable 115,239,072 bytes; Windows ZIP ~43.7 MB, source ZIP ~8.6 MB.
- Final aggregate `d3818f84-7ec4-460f-866d-473face0cd1c`: all suites above
  passed, stderr empty. Initial GUI executable launch in PowerShell did not wait;
  exact exit receipt reconciled after children self-exited (no kill).
- Sequential standalone smoke `1ca8d992-87e5-4555-aa4f-282de5d33a4f`: exit 0,
  stderr empty, both captures mode=playing. Marsh 120.05 FPS/p95 9.74 ms,
  ash 120.01 FPS/p95 9.87 ms. Executable needs no editor/Python to run.
- Capture/journal follow-up `b662da19-4695-4bbc-ade1-c6a30cbbe084`: expansion
  38/38, save process WRITE/READ true, graphical chapter I 22/22; stderr empty.
- Skill/MCP Godot live-control không exposed ở phiên này; kiểm chứng qua Godot CLI,
  input runner, capture render thật và kiểm tra ảnh.
