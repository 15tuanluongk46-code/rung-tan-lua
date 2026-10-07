# Rừng Tàn Lửa

Game phiêu lưu 2D top-down, tiếng Việt, Godot **4.7.2**. Mang ba tàn lửa từ rừng, bờ suối và phế tích về tế đàn, rồi trở lại già làng An.

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

Gặp An phía bắc lửa trại để nhận việc chính. Mai cần năm cây thuốc; túi của Lâm ở phía đông Bờ Suối. Lính canh phải bị hạ trước khi lấy tàn lửa. Gấu có thể đánh cả người chơi lẫn yêu tinh. Hãy nhìn cảnh báo trước đòn đánh và tận dụng cây/đá chắn đạn.

**Không lưu hành trình sau khi đóng game.** Trong một lần chơi, chết không mất nhiệm vụ, vật phẩm đã nhặt hay kẻ địch đã hạ; hồi sinh ở lửa trại/Bờ Suối. Cài đặt âm lượng, rung và fullscreen được lưu tại thư mục userdata Godot `Rừng Tàn Lửa/settings.cfg`.

## Nội dung

- Bốn vùng liên thông: Trại Tro, Rừng Sâu, Bờ Suối, Phế Tích.
- 28 cá thể ban đầu / 13 thiết kế: một người chơi, năm NPC riêng, 6 cận chiến, 4 cung thủ, 2 pháp sư, 2 gấu, 3 hươu, 3 thỏ, 2 chim.
- Nhiệm vụ chính và hai việc phụ, kết thúc có thống kê, chơi lại.
- Tán cây mờ khi che người chơi, y-sort, ánh sáng ấm/lạnh, gió/lá/đom đóm.
- 21 file âm thanh gốc; bốn bus âm lượng riêng.

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
