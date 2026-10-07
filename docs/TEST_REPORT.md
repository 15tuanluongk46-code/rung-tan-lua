# Báo cáo bàn giao — Rừng Tàn Lửa

## Bản đã triển khai

Godot 4.7.2.stable.official.ed1daf0bf, Linux x86_64. Source và asset nguyên bản
trong project; không commit/push hoặc mua tài sản. 13 thiết kế, 28 cá thể khởi tạo,
bốn khu, nhiệm vụ chính + hai nhiệm vụ phụ, combat/AI/checkpoint/menu/UI/âm thanh.

## Kiểm thử

| Kiểm tra | Kết quả |
|---|---|
| State/combat/census `test_gameplay.gd` | 71 checks, 0 failures |
| Scene/API end-to-end `test_integration.gd` | 37 checks, 0 failures |
| Physics/AI/pause/death `test_runtime.gd` | 18 checks, 0 failures |
| Delivery regressions | 6 lỗi RED trước sửa; 0 failures sau sửa |
| UI input thực `test_ui_input.gd` | 22 checks graphical; 18 headless; 0 failures |
| World/audio với asset bắt buộc | 3164 checks, 0 failures |
| Python asset/audio suites | 7 tests pass |
| Linux export release | Exit 0; template chính thức, PCK nhúng |
| Linux executable từ `/tmp/opencode` ngoài project | Chạy độc lập, capture camp status=0 |

Các test API không thay cho một lượt chơi hoàn chỉnh bằng tay. UI input test
dùng event bàn phím/chuột và slider thực; có tạm ghi cài đặt âm lượng rồi phục hồi.
Các test teardown được thêm thời gian chờ giải phóng OGG; runtime chạy lại không
còn cảnh báo resource cleanup. Không có báo cáo lỗi Critical/High mới ở re-review.

## FPS thực và screenshot

VSync mặc định gây stall trên phiên X11/NVIDIA: A/B cùng cảnh 10.56 FPS bật VSync
và 357.60 FPS uncapped khi tắt. Bản giao tắt VSync, cap 120; không bỏ nhân vật hay
đồ họa để đạt số đo. Có thể tearing trên màn hình khác.

| Chạy graphical | FPS trung bình | p95 frame time |
|---|---:|---:|
| RTX 3060 — camp | 105.03 | 22.91 ms |
| RTX 3060 — forest | 98.83 | 22.41 ms |
| RTX 3060 — creek | 107.18 | 23.83 ms |
| RTX 3060 — ruins | 108.99 | 23.27 ms |
| Standalone release — Intel UHD 770 / Mesa 25.2.8 — camp | 120.01 | 9.08 ms |

Mỗi mẫu 180 frame sau warmup 60 frame; ảnh chụp SAU thời gian đo. Các mẫu RTX
được chạy cùng lúc với bộ test, không phải benchmark dài hay cam kết khóa 60 FPS.
Standalone được chạy ngoài thư mục source và dùng Intel UHD 770 do lựa chọn GPU
của môi trường, khác phiên editor RTX. Không gộp hai máy đo thành một kết luận.

Tám PNG trong `docs/screenshots/`: camp, forest, creek, ruins, menu, pause,
settings, gameplay-input. Tất cả lấy từ viewport Godot thực, không phải concept.

## Giới hạn chưa nghiệm thu

- Chưa chạy trọn hành trình bằng người chơi thực; mục tiêu 15–20 phút chưa xác nhận.
- Chưa xác nhận chất lượng mỹ thuật đạt mức tham chiếu. Công cụ vision cho nhận xét
  ngắn và không nhất quán; không lấy các test số lượng/file làm bằng chứng đồ họa đẹp.
- Chưa có stress test dài hoặc thử trên nhiều độ phân giải/phần cứng.
- Không lưu tiến độ khi thoát là giới hạn thiết kế đã chốt, không phải lỗi save.
- Minor còn lại: hit radius projectile cố định 10 px so với gấu 12 px; thông báo
  pickup thất bại dùng chung “túi đầy”; slider ghi settings mỗi tick; pose windup
  cập nhật trễ tối đa một frame. Không che giấu những điểm này bằng nhãn “hoàn hảo”.

## Các quyết định triển khai

1. Tự tác pixel art bằng source Pillow xác định: palette/license thống nhất;
   đánh đổi là cần con người duyệt mỹ thuật, không tự chứng minh đẹp.
2. Chia module cho worker với interface cố định: tích hợp đã test; không commit.
3. Giữ `--capture-region` opt-in trong release để kiểm tra đúng binary bàn giao;
   không cấp đồ/bất tử, tự thoát. Các test khác không đưa vào bản chơi.
4. Tắt VSync/cap120 theo A/B thực: giải quyết stall ở máy này, có rủi ro tearing.

Trạng thái: bản chạy và gói bàn giao có thể kiểm tra; chưa tuyên bố hoàn thành
nghiệm thu hình ảnh hoặc thời lượng trải nghiệm bởi người dùng.
