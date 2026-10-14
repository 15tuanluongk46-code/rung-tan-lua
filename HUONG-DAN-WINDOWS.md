# Chạy Rừng Tàn Lửa trên máy Windows này

## Hình ảnh mới: Rừng huyền bí — ánh lửa ấm

Đã áp dụng màu riêng bốn vùng, môi trường chuyển động nhẹ, nhân vật có viền/rim,
dấu cảnh báo đòn đánh, HUD gọn với ba biểu tượng tàn lửa, chân dung hội thoại,
hiệu ứng nhặt đồ/tế đàn và ảnh nền menu/kết thúc. Mở `CHOI-GAME.cmd` để xem.
Chi tiết và số đo: [docs/MYSTIC_ART_DIRECTION.md](docs/MYSTIC_ART_DIRECTION.md).

## Cập nhật sửa lỗi 08/10/2026

Đã sửa lỗi hội thoại nhận nhiệm vụ, thoát/hồi sinh, đạn và tương tác qua vật cản,
nhật ký nhiệm vụ và túi đá gần đầy. Bộ kiểm tra mới đạt 24/24; hành trình graphical
đạt 22/22, bao gồm kết thúc, đối chiếu thống kê và chơi lại. Ba lượt UI input Windows
liên tiếp đạt 23/23. Chi tiết: [docs/WINDOWS_PLAY_AUDIT.md](docs/WINDOWS_PLAY_AUDIT.md).
Các kết quả lỗi ở mục xác minh ban đầu bên dưới đã được điều tra/sửa trong báo cáo mới.

## Mở game

- Bấm đúp `CHOI-GAME.cmd`, rồi chọn **Bắt đầu hành trình**.
- Muốn mở mã nguồn trong Godot: bấm đúp `MO-GODOT.cmd`, nhấn **F5**.
- Godot đã có: `4.7.2.stable.official.ed1daf0bf`. Game dùng OpenGL Compatibility.
- Không cần Python, API key hoặc Internet để chơi. Launcher chạy source bằng Godot đã cài trên máy; đây không phải bản Windows export độc lập.
- Thư mục chính: `C:\Users\ADMIN\AI-Home\projects\rung-tan-lua`.

## Điều khiển

WASD di chuyển; chuột để ngắm; chuột trái đâm giáo; chuột phải ném đá; Space né; E tương tác; Q hồi máu; Esc tạm dừng. Gặp già làng An phía bắc lửa trại để nhận nhiệm vụ.

**Game không lưu hành trình sau khi đóng.** Cài đặt được lưu riêng trong userdata Godot.

## Nguồn tải và xác minh ngày 08/10/2026

- Tải ZIP nhánh `main` bằng Chrome Profile `15tuanluongk46@gmail.com` từ repo private `15tuanluongk46-code/rung-tan-lua`.
- Commit mới nhất hiển thị lúc tải: `33e3537c31c61dc926c67484aa3b2eb1a2dc45b5`.
- ZIP: `C:\Users\ADMIN\Downloads\rung-tan-lua-main.zip`.
- SHA256 ZIP: `86558BD2E5C9463CA05301112A2120E3747D1684A26328349B2FC1167CC4606C`.
- Bản giải nén không có lịch sử `.git`. GitHub CLI hiện chưa đăng nhập tài khoản có quyền đọc repo này.
- Import headless: exit 0, stderr trống. Smoke chạy scene chính 60 frame: exit 0.
- Gameplay: 71 checks, 0 failures; runtime: 18 checks, 0 failures; delivery regressions: 0 failures; UI input headless: 18 checks, 0 failures; world/audio: 3164 checks, 0 failures.
- Integration: 37 checks, 1 failure (`survivor position resets on death`). Chưa xác định đây là lỗi gameplay hay thời điểm kiểm tra sau khi AI tiếp tục chạy. Có cảnh báo tài nguyên còn dùng khi thoát trong đợt kiểm thử.
- UI input có cửa sổ: đã khởi tạo OpenGL 3.3 / GTX 1050 Ti và ghi 4 PNG; 22 checks, 4 failures liên quan throw/dodge/pause. Chưa xác định ảnh hưởng của focus cửa sổ. Không coi đây là UI QA đạt.
- Ảnh kiểm thử ở `%APPDATA%\Godot\app_userdata\Rừng Tàn Lửa\captures\`; chưa đánh giá hình ảnh trong phiên hỗ trợ này.
- Chưa chạy Python tests/generator hoặc playthrough hoàn chỉnh; không thay đổi gameplay để che lỗi kiểm thử.

## Lệnh chạy thủ công (PowerShell)

```powershell
game-godot --path "C:\Users\ADMIN\AI-Home\projects\rung-tan-lua"
```
