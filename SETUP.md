# Cài đặt và bàn giao

## SmoothMotion — 14/10/2026

Latest: `build/RungTanLua-Windows-SmoothMotion-20261014.zip`.
Report: `docs/SMOOTH_MOTION_REPORT.md`; timing/native evidence:
`docs/screenshots/SmoothMotion-20261014/`. Settings has explicit60Hz smooth preset,
independent hitstop level. Existing user FPS/VSync retained, save v2 unchanged.

## FullAudit — 13/10/2026

Latest: `build/RungTanLua-Windows-FullAudit-20261013.zip`.
Report: `docs/FULL_AUDIT_REPORT.md`; native evidence `docs/screenshots/FullAudit-20261013/`.
Asset regeneration: `py -3.10 -X utf8 tools/regenerate_assets.py` through managed
ops task; stages then validates/publishes. Legacy base/expansion generators refuse
direct execution. Baseline sources are in `assets/source_props/` (not exported).

## FrontSpear — 13/10/2026

Latest: `build/RungTanLua-Windows-FrontSpear-20261013.zip`.
Preview: `docs/screenshots/front-spear/`; report `docs/FRONT_SPEAR_REPORT.md`.

## SpearOnlyNoHands — 13/10/2026

Latest: `build/RungTanLua-Windows-SpearOnlyNoHands-20261013.zip`.
Ẩn hai tay nhỏ lúc đâm/tích lực, thu xong hiện lại. Report:
`docs/SPEAR_NO_HANDS_REPORT.md`; preview `docs/screenshots/spear-only-no-hands/`.

## SpearOnly — 13/10/2026

Latest: `build/RungTanLua-Windows-SpearOnly-20261013.zip`.
Đâm thường/tích lực giữ nguyên thân/tay, chỉ giáo chuyển động.
Report: `docs/SPEAR_ONLY_REPORT.md`. Preview: `docs/screenshots/spear-only/`.

## PlayerMotion — 13/10/2026

Latest: `build/RungTanLua-Windows-PlayerMotion-20261013.zip`.
Report/evidence: `docs/PLAYER_MOTION_REPORT.md`, `docs/screenshots/player-motion/`.
Player action assets: `assets/player_motion/`; developer generator
`tools/generate_player_motion.py`. Timing/combat/save vẫn như bản trước.

## PlayerHands — 13/10/2026

Latest: `build/RungTanLua-Windows-PlayerHands-20261013.zip`.
Report: `docs/PLAYER_HANDS_REPORT.md`; reference/render sheets:
`docs/screenshots/player-hands/`. Original `assets/sprites/player.png` now owns
Player rest/walk hands, active weapons remain layered/contact-synchronized.

## WorldPolish — 13/10/2026

Latest: `build/RungTanLua-Windows-WorldPolish-20261013.zip`.
Report/evidence: `docs/WORLD_POLISH_REPORT.md`, `docs/screenshots/world-polish/`.
Routes source: `assets/world_routes.json`; terrain/material generator:
`tools/generate_world_polish.py`. Added `test_world_polish.py` and
`capture_world_polish.gd`. Save v2 unchanged; tests never use player journey slot.

## DetailPolish — 13/10/2026

Latest: `build/RungTanLua-Windows-DetailPolish-20261013.zip`.
Report: `docs/DETAIL_POLISH_REPORT.md`; thêm `test_detail_polish.gd`,
`capture_detail_polish.gd`. SHA256: `build/SHA256SUMS-DetailPolish-20261013.txt`.
Preview/crop: `docs/screenshots/detail-polish/`. Save vẫn v2.

## ActionSync — 12/10/2026

Latest: `build/RungTanLua-Windows-ActionSync-20261012.zip`.
Report: docs/ACTION_SYNC_REPORT.md. New regression test_action_sync.gd;
capture_action_sync.gd outputs sequential frames; package_action_preview.py encodes
preview. Save stays v2, source launch still CHOI-GAME.cmd.

## Weapon Polish — 12/10/2026

Latest Windows package: `build/RungTanLua-Windows-WeaponPolish-20261012.zip`.
Report: `docs/WEAPON_POLISH_REPORT.md`. Added test `test_weapon_animation.gd`,
capture `capture_weapon_animation.gd` and Python `test_weapon_layers.py`.
Assets finished in `assets/layers/`; generator optional, not needed to play.

## Gameplay Depth — 12/10/2026

Latest: `build/RungTanLua-Windows-GameplayDepth-20261012.zip`.
Reports: GAMEPLAY_DEPTH_REPORT.md và PLAYTEST_GUIDE.md trong docs/.
Save envelope v2, đọc v1 bằng migration. Test thêm `test_gameplay_depth.gd`,
`test_depth_input.gd` (graphical InputMap/captures). Không cần generate assets lại.

## Quality Fix Windows — 12/10/2026

Latest package: `build/RungTanLua-Windows-QualityFix-20261012.zip`.
Report: `docs/QUALITY_FIX_REPORT.md`. Additional isolated tests:
`test_quality_regressions.gd`, `test_autosave_pipeline.gd`, `test_accessibility.gd`.

## Chương II Windows — 11/10/2026

Giải nén `build/RungTanLua-Windows-ChapterII-20261011.zip`, chạy `RungTanLua.exe`.
Không cần Godot/Python/network. M mở map; journey được autosave vào userdata Godot.
Source: Godot 4.7.2, `CHOI-GAME.cmd`. Nghiệm thu: `docs/EXPANSION_REPORT.md`.
Các đoạn Linux/no-save dưới đây là hướng dẫn lịch sử của bản gốc.

Test mới (test slot riêng, không dùng save người chơi):
```powershell
game-godot --headless --path . --script res://tests/test_expansion.gd
game-godot --headless --path . --script res://tests/test_save_restart.gd -- --write-fixture
game-godot --headless --path . --script res://tests/test_save_restart.gd
game-godot --path . --script res://tests/test_chapter_two_journey.gd --fixed-fps 60
game-godot --path . --script res://tests/capture_expansion.gd
```

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

Windows regression/input journey bổ sung sau audit 08/10/2026:

```powershell
game-godot --headless --path . --script res://tests/test_play_regressions.gd
game-godot --path . --script res://tests/test_user_journey.gd --fixed-fps 60
```

Journey điều khiển qua InputMap và nút UI, có giới hạn số tick, không cấp đồ/bất tử
hay teleport. Chạy từng test riêng, giữ cửa sổ game hiển thị khi chụp ảnh. Xem
`docs/WINDOWS_PLAY_AUDIT.md` để biết giới hạn và bằng chứng mới nhất.

```bash
for suite in gameplay integration runtime delivery_regressions ui_input world_audio; do
  "$GODOT" --headless --path . --script "res://tests/test_${suite}.gd" -- --require-assets || exit 1
done
python3 -m venv .venv
.venv/bin/pip install --require-hashes -r requirements-dev.lock
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

Dependency Python tùy chọn được khóa trong `requirements-dev.lock`; không cần chúng để chơi bản Linux.
Lock resolve cho Python 3.10, cài kiểm tra trên Linux/Python 3.10.21; không khóa Godot/FFmpeg/export templates.
Khi chủ động cập nhật: `uv pip compile requirements-dev.txt --python-version 3.10 --generate-hashes -o requirements-dev.lock`, rồi cài và chạy lại tests.

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
