# Hướng dẫn làm việc

- Game Godot 4.7.2, GDScript 2.0, UI tiếng Việt. Đọc README.md, SETUP.md, docs/SPEC.md trước khi sửa.
- Giữ 13 thiết kế/28 cá thể ban đầu, bốn vùng và ba nhiệm vụ. Không giảm scope hoặc thay art thành placeholder mà không có chấp thuận.
- Mỗi script có trách nhiệm riêng; logic tiến độ ở run_state, combat ở combat_health/actors, art ở world_art/actor_visual, âm thanh ở audio_director. Input dùng InputMap.
- Asset thành phẩm tracked; generator là công cụ phát triển tùy chọn. Giữ nguồn/license trong assets/CREDITS.md và font notice.
- Sau thay đổi: import headless rồi chạy các suite trong SETUP.md. Lỗi gameplay thêm regression test trước. Thay đổi mỹ thuật cần screenshot thật; không coi headless pass là visual QA.
- Không claim 15–20 phút hoặc FPS máy khác nếu chưa đo. Test UI có thể ghi settings; chú ý cách ly khi kiểm tra.
- Không commit .godot, build, templates, binary, virtualenv, credentials. Binary/Source archives thuộc Release.
- Chỉ commit/push/publish khi được yêu cầu. Repo private; không đổi visibility. Kiểm tra account/remote trước thao tác GitHub, không hardcode credential.
- Trước bàn giao cập nhật tài liệu liên quan, test report, package và SHA256; xác minh remote SHA và release assets.
