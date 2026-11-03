# Bản chơi thử đấu trường và khán giả

Nhánh: `core/arena-juice`. Đã ghép bản sửa alpha #17 và crowd #19 vào phần game Claude đã tích hợp, theo yêu cầu gắn tiếp của người dùng.

## Chơi thử

Lấy nhánh `core/arena-juice`, mở `project.godot` bằng **Godot 4.7.2**, rồi nhấn **F5**. Có thể [tải ZIP của nhánh](https://github.com/loc169434-design/Brick-hero/archive/refs/heads/core/arena-juice.zip), giải nén rồi mở project.

Trận đầu là bãi tập; thắng rồi chạm để sang Orc. Kéo nối các ô cùng màu để chơi.

## Đã gắn

- Mây, cỏ, chim và đuốc dùng PNG đã sửa alpha.
- Mỗi nền có ba khán giả ở vị trí xa, scale 0.55 theo crowd.json, nằm dưới lớp fighters và cùng parallax với mid. Không có overlay rào riêng.
- Khán giả nhún nhẹ khi chờ; reo khi nối từ 6 ô, dây chuyền từ 3 vòng, chí mạng hoặc thắng. Khi hiệp sĩ trúng đòn/thua, nông dân la ó còn Orc con cười/chỉ trỏ theo ảnh boo.
- Hết phản ứng về idle; bắt đầu lại trận hoặc đổi nền cũng về idle.

## Kiểm tra

Godot 4.7.2 import sạch. Bộ test: **57 passed, 0 failed**.

```sh
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/smoke_arena_crowd.gd
```

Smoke test mở chính scenes/main.tscn, kiểm tra cả hai nền, combo, critical, hero hit, hết hiệu ứng, bắt đầu lại/đổi trận và thắng/thua. Kiểm tra không có SCRIPT ERROR hoặc ERROR trong log, ngoài exit code. Việc kiểm tra tích hợp chạy headless; cảm nhận chuyển động và bố cục trong cửa sổ game chờ lượt chơi review.
