# Rừng Tàn Lửa

Game phiêu lưu 2D top-down, tiếng Việt, Godot **4.7.2**. Hai chương, sáu vùng: mang ba tàn lửa về tế đàn, rồi khôi phục Giếng Nguồn và Tháp Lửa trong Chương II — Đường Lửa Thức Giấc.

## Bản Windows Chương II

Chạy `build/windows/RungTanLua.exe` hoặc giải nén gói `build/RungTanLua-Windows-SmoothMotion-20261014.zip`.
Đi/lướt nội suy và camera đồng bộ, map/ending/settings polish: `docs/SMOOTH_MOTION_REPORT.md`.
Sửa lỗi tổng thể combat/save/UI/atlas/world: `docs/FULL_AUDIT_REPORT.md`.
Giáo đâm phía trước; Player không có motion tay riêng ở mọi trạng thái: `docs/FRONT_SPEAR_REPORT.md`.
Khi đâm/tích lực ẩn cả hai tay nhỏ, hết thu giáo hiện lại: `docs/SPEAR_NO_HANDS_REPORT.md`.
Đâm giáo giữ nguyên thân/tay theo mẫu: `docs/SPEAR_ONLY_REPORT.md`.
Bản executable có PCK nhúng, không cần Godot/Python/mạng. Source launch vẫn dùng `CHOI-GAME.cmd`.
Chi tiết nghiệm thu: [docs/EXPANSION_REPORT.md](docs/EXPANSION_REPORT.md).
Polish tay/pose tám hướng, grip từng vũ khí và HUD tránh nhân vật:
[docs/DETAIL_POLISH_REPORT.md](docs/DETAIL_POLISH_REPORT.md).
Ảnh/crop và preview: `docs/screenshots/detail-polish/`.
Sửa che lớp áo choàng, đường/bờ suối liền và polish công trình:
[docs/WORLD_POLISH_REPORT.md](docs/WORLD_POLISH_REPORT.md).
Player giữ dáng tay theo sprite người dùng chọn: [docs/PLAYER_HANDS_REPORT.md](docs/PLAYER_HANDS_REPORT.md).
Motion Player mới từ cùng mẫu, composite pose thay tay rig:
[docs/PLAYER_MOTION_REPORT.md](docs/PLAYER_MOTION_REPORT.md).
Đợt sửa combat/save/UI: [docs/QUALITY_FIX_REPORT.md](docs/QUALITY_FIX_REPORT.md).
Chiều sâu combat/đèn/reward và save v2: [docs/GAMEPLAY_DEPTH_REPORT.md](docs/GAMEPLAY_DEPTH_REPORT.md).
Animation vũ khí tách lớp, giáo đâm thật tám hướng và contact theo AnimationPlayer:
[docs/WEAPON_POLISH_REPORT.md](docs/WEAPON_POLISH_REPORT.md).
Xem `docs/screenshots/weapons/weapon-motion-review.mp4` và `spear-eight-directions.png`.
Fix input/timing/hướng giáo: [docs/ACTION_SYNC_REPORT.md](docs/ACTION_SYNC_REPORT.md).
Preview chuyển động liên tiếp: `docs/screenshots/action-sync/spear-continuous-eight-directions.mp4`.
Ember đầu mở Shift + chuột trái tích lực; Giếng mở Né chuẩn; Tùng cho chọn Giáo/Đá/Sinh tồn.
Save v1 tự đọc qua migration, không nhân đôi phần thưởng. Công trình mở dù túi đầy,
reward được giữ chờ; M cho trở về checkpoint đã kích hoạt ngoài combat.
Trong Cài đặt → Chữ, chuyển động và hiển thị: chữ lớn, giảm flash/chuyển động,
VSync, cap 60/120 FPS. PageUp/PageDown cuộn nội dung dài.

## Chạy bản Linux

Repo Git chỉ chứa source; tải binary ở **Releases**. Hướng dẫn máy mới: [SETUP.md](SETUP.md). Quy tắc phát triển: [AGENTS.md](AGENTS.md).

Mở `build/linux/RungTanLua.x86_64`, hoặc:

```bash
chmod +x build/linux/RungTanLua.x86_64
./build/linux/RungTanLua.x86_64
```

Bản export x86_64 chứa PCK nhúng, không cần cài Godot, Python hay kết nối mạng. Cần môi trường desktop Linux và driver OpenGL 3.3. Không phải launcher gọi editor.

## Điều khiển

| Phím | Hành động |
|---|---|
| WASD / chuột | Đi / hướng ngắm |
| Chuột trái | Đâm giáo |
| Chuột phải | Ném đá, tạo tiếng động |
| Space | Né, hồi 0,8 giây |
| E | Nói chuyện, nhặt đồ, nghỉ, tương tác tế đàn |
| Q | Thuốc hồi 40 máu |
| Esc | Tạm dừng / trở lại |
| M | Bản đồ các vùng và địa điểm đã khám phá |

Gặp An phía bắc lửa trại để nhận việc chính. Mai cần năm cây thuốc; túi của Lâm ở phía đông Bờ Suối. Lính canh phải bị hạ trước khi lấy tàn lửa. Gấu có thể đánh cả người chơi lẫn yêu tinh. Hãy nhìn cảnh báo trước đòn đánh và tận dụng cây/đá chắn đạn.

**Có autosave và Tiếp tục hành trình.** Nhiệm vụ, inventory, đồ đã nhặt, địch đã hạ, shortcut và khám phá được lưu tại mốc tiến độ/điểm nghỉ. Tiếp tục tại checkpoint; không lưu projectile/animation. `journey.json` có version và `journey.json.bak` dự phòng. Cài đặt ở `settings.cfg`. Windows: `%APPDATA%/Godot/app_userdata/Rừng Tàn Lửa/`.

## Nội dung

- Sáu vùng liên thông: Trại Tro, Rừng Sâu, Bờ Suối, Phế Tích, Đầm Sương, Đồi Than.
- 28 cá thể ban đầu / 13 thiết kế: một người chơi, năm NPC riêng, 6 cận chiến, 4 cung thủ, 2 pháp sư, 2 gấu, 3 hươu, 3 thỏ, 2 chim.
- Hai nhiệm vụ chính theo chương, bốn việc phụ; cầu/chuông thay đổi thế giới, ba ký ức tùy chọn.
- Hai NPC mới (Sen/Tùng), Kẻ Rình Sương, Lính Than và boss Người Giữ Than hai pha. Tổng 18 thiết kế; 28 actor gốc và 13 actor mở rộng trước khi tính địch đã hạ.
- Tán cây mờ khi che người chơi, y-sort, ánh sáng ấm/lạnh, gió/lá/đom đóm.
- 24 file âm thanh gốc; bốn bus âm lượng riêng.

## Mở source và kiểm thử

Import `project.godot` bằng Godot 4.7.2. Toàn bộ tài nguyên thành phẩm đã có; không phải chạy generator để chơi.

```bash
GODOT="$(command -v godot)" # hoặc đường dẫn Godot 4.7.2 trên máy của bạn
"$GODOT" --headless --path . --editor --import --quit
for suite in gameplay integration runtime delivery_regressions ui_input world_audio; do
  "$GODOT" --headless --path . --script "res://tests/test_${suite}.gd" -- --require-assets || exit 1
done
python3 -m unittest discover -s tests -p 'test_*.py'
# GPU thật, input dispatch + ảnh menu/pause/settings/gameplay:
"$GODOT" --path . --script res://tests/test_ui_input.gd
# Ảnh và benchmark ngắn từng vùng; PNG lưu ở user://captures/
"$GODOT" --path . -- --capture-region=camp
```

Python tests/generator cần Pillow; audio generator cần numpy và FFmpeg. Chỉ dùng để phát triển, không là dependency của bản Linux.

## Export lại

Preset `Linux` trong `export_presets.cfg` dùng template Godot **4.7.2-stable** tại `build/templates/linux_release.x86_64` và `linux_debug.x86_64`. Tải official export templates từ [Godot releases](https://github.com/godotengine/godot/releases/tag/4.7.2-stable); lấy đúng hai file Linux từ thư mục `templates` trong TPZ, không dùng binary editor làm template.

```bash
"$GODOT" --headless --path . --export-release Linux build/linux/RungTanLua.x86_64
```

## Bằng chứng và giới hạn

- Screenshot thực: `docs/screenshots/`.
- Báo cáo xác minh và số đo: `docs/TEST_REPORT.md`.
- Đặc tả: `docs/SPEC.md`; nguồn tài nguyên: `assets/CREDITS.md`.
- Mục tiêu 15–20 phút chưa được xác nhận bằng playthrough người thật. Test tự động không được xem là chứng minh thời lượng hoặc độ vui.
- VSync tắt, giới hạn 120 FPS: tránh stall đã đo được trên X11/NVIDIA máy phát triển. Không cam kết FPS cho máy khác.

Code/art/audio gốc: MIT. DejaVu và engine có giấy phép riêng, xem LICENSE và CREDITS.
