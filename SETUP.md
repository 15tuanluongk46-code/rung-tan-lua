# Cài đặt và bàn giao

## Chơi bản phát hành

Repository và Release là private: cần quyền truy cập GitHub tương ứng để tải.
Tải `RungTanLua-Linux-x86_64.tar.gz` từ Releases, giải nén rồi chạy:

```bash
tar -xzf RungTanLua-Linux-x86_64.tar.gz
chmod +x RungTanLua-Linux/RungTanLua.x86_64
./RungTanLua-Linux/RungTanLua.x86_64
```

Linux x86_64, desktop và OpenGL 3.3; không cần Godot/Python/network để chơi.
Không lưu tiến độ sau khi đóng game. Cài đặt lưu trong userdata Godot.

## Chạy source trên máy khác

1. Clone repo hoặc giải nén gói Source vào một thư mục riêng.
2. Cài Godot **4.7.2 stable Standard**, không bắt buộc .NET. Binary phải đến từ nguồn Godot chính thức.
3. Mở `project.godot`, đợi import và nhấn F6/F5 phù hợp (F5 chạy cả project).

CLI dưới đây dùng biến `GODOT` là đường dẫn binary trên máy của bạn:

```bash
export GODOT="$(command -v godot)"
# Nếu binary không nằm trong PATH: export GODOT=/absolute/path/to/godot
"$GODOT" --version
"$GODOT" --headless --path . --editor --import --quit
"$GODOT" --path .
```

Tất cả PNG, OGG, font và script cần để chạy đã tracked. `.godot/` được Godot tạo lại.
Không cần API key, dịch vụ private, browser profile hay virtualenv của tác giả.

## Test offline

```bash
for suite in gameplay integration runtime delivery_regressions ui_input world_audio; do
  "$GODOT" --headless --path . --script "res://tests/test_${suite}.gd" -- --require-assets || exit 1
done
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/python -m unittest discover -s tests -p 'test_*.py'
```

Python 3.10+; FFmpeg cần có trên PATH cho các bài kiểm tra âm thanh. Cài các gói hệ điều hành từ nguồn tin cậy nếu máy chưa có. Những test Godot không cần Python. `test_ui_input.gd` thay đổi âm lượng qua slider và khôi phục khi xong; nếu bị kill giữa chừng có thể còn giá trị test trong settings.cfg. Chạy bằng user thử nghiệm nếu cần cách ly hoàn toàn cài đặt.

Chụp ảnh/đo FPS cần desktop thật, không phải headless:

```bash
"$GODOT" --path . --script res://tests/test_ui_input.gd
for region in camp forest creek ruins; do
  "$GODOT" --path . -- --capture-region="$region"
done
```

Ảnh mới ở `user://captures/`. `docs/screenshots/` chứa ảnh đã bàn giao. Benchmark ngắn có cap 120 FPS; không thay thế playthrough hoặc nghiệm thu mỹ thuật.

## Export Linux

Tải `Godot_v4.7.2-stable_export_templates.tpz` từ https://github.com/godotengine/godot/releases/tag/4.7.2-stable . Template không tracked vì kích thước lớn.

```bash
mkdir -p build/templates build/linux
unzip -j /path/to/Godot_v4.7.2-stable_export_templates.tpz \
  templates/linux_debug.x86_64 templates/linux_release.x86_64 -d build/templates
"$GODOT" --headless --path . --export-release Linux build/linux/RungTanLua.x86_64
"$GODOT" --headless --path . --script res://tools/export_licenses.gd
python3 tools/package_delivery.py
```

Gói Source không bao gồm templates, binary hay cache. Gói Linux gồm executable PCK nhúng và notices. `build/SHA256SUMS` xác minh các archive từ thư mục build; dòng `linux/RungTanLua.x86_64` áp dụng cho layout build, không phải tên thư mục giải nén Release.

## Tái tạo asset — tùy chọn

Không cần bước này để chạy game. Dùng `.venv/bin/python tools/generate_assets.py` và `.venv/bin/python tools/generate_audio.py`; bước âm thanh cần FFmpeg. Art generator hiện lấy DejaVu từ `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` và copyright từ `/usr/share/doc/fonts-dejavu-core/copyright` (gói fonts-dejavu-core trên Debian/Ubuntu). Máy không có các đường dẫn này vẫn chơi/test được bằng font bundled; chỉ việc tái tạo asset bị chặn cho tới khi cung cấp font có cùng license. Không dùng môi trường Python của dự án khác.

Xem `docs/TEST_REPORT.md` và `docs/HANDOFF_REPORT.md` để phân biệt những gì đã kiểm tra với giới hạn còn lại.
