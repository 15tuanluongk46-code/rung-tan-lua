# Báo cáo bàn giao GitHub

Ngày kiểm tra: 2026-10-08. Repository mới, chưa có starting SHA trước lần commit đầu. Tài khoản đích đã được người dùng xác nhận: `15tuanluongk46-code`; visibility private; branch main. Không có credential/API key phục vụ runtime.

## Kết quả kiểm tra mới trước xuất bản

Linux, Godot `4.7.2.stable.official.ed1daf0bf`, Python 3 và FFmpeg trên máy build.

- **PASS:** sáu suite headless theo SETUP.md: gameplay 71, integration 37, runtime 18, delivery regressions 0 failures, UI input 18, world/audio 3164; không warning cleanup ở lần chạy này.
- **PASS:** `python3 -m unittest discover -s tests -p 'test_*.py'` — 7 tests.
- **PASS:** `git diff --cached --check` sau bỏ khoảng trắng cuối dòng trong font notice; nội dung license không thay đổi.
- **PASS:** `gitleaks git --staged --redact --no-banner .` — 260 KB nội dung staged được scan, không phát hiện leak. Scan không phải bảo đảm tuyệt đối không có secret.
- Binary Linux đã export và chạy độc lập trước bàn giao; các số đo, screenshot và giới hạn ở `TEST_REPORT.md`.
- **NOT RUN:** full human playthrough, nghiệm thu mỹ thuật chuyên nghiệp và xác nhận thời lượng 15–20 phút; không suy ra từ unit test.

## Phân loại tài nguyên và portability

- Tracked input: source Godot, PNG/OGG/font thành phẩm, notices, tám screenshot thật, generator và tests.
- Generated output, không Git: `.godot/`, `build/`, virtualenv/cache. Release đính kèm gói Linux, Source và SHA256SUMS.
- External optional dependency: template export chính thức 4.7.2. Python/Pillow/numpy/FFmpeg chỉ phục vụ asset/test phát triển. Font path Debian cố định chỉ ảnh hưởng tái tạo asset, không ảnh hưởng chơi bằng font bundled.
- Package script có thể dùng ảnh mới trong userdata; máy mới không có userdata dùng ảnh đã tracked trong docs/screenshots. Không đưa profile browser, cookie, keyring, token hoặc settings cá nhân vào repo/gói.
- Một số báo cáo lịch sử có đường dẫn máy tác giả để giữ evidence; hướng dẫn chạy hiện hành trong SETUP.md dùng đường dẫn do người dùng cấu hình.
- VSync off/cap120 là quyết định từ đo đạc X11; không cam kết hiệu năng mọi máy. Capture CLI được giữ có chủ đích để tái lập benchmark, chỉ kích hoạt khi truyền flag.

Quy trình publish phải kiểm tra lại account, repository private, remote SHA và release asset digest trước báo thành công.
