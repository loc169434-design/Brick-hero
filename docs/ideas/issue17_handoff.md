# Issue #17 — nền bảng và lớp đấu trường

Nhánh: `art/arena-layers`, tạo từ `origin/main` tại `aeefd30e367f3e87c6533d85285d72495aa7068c`.

GitHub API trả `Forbidden` khi đọc issue. Bàn giao tại đây theo yêu cầu; chưa đăng được comment hay tạo PR bằng API.

## Xem thử

![Training](issue17_review/board_training_360.png)
![Orc](issue17_review/board_orc_shield_360.png)
![Training: gốc bên trái, ghép lớp bên phải](issue17_review/training_field_compare.png)
![Orc: gốc bên trái, ghép lớp bên phải](issue17_review/orc_camp_compare.png)

## Tích hợp

- Backdrop đặt (0,660), panel đặt (20,660); panel có lỗ alpha chính xác x=30..1009, y=30..1149, tức 980×1120. Slot 140×140, gạch 128×128 căn giữa. Không vẽ lại gạch.
- Thứ tự nền: sky → far → mid → ground. Bốn lớp ở (0,0), canvas 1080×660. Mặt đất bắt đầu y=470. Bản ghép tĩnh khớp từng pixel với gốc (xem metrics.json).
- Sky không có mây. Các dải mây xa gốc được giữ trong far để bảo toàn bản ghép; cloud_1..3 là chi tiết trôi bổ sung, không phải những mảnh mây gốc đã bóc. Atlas mới và cỏ có alpha nền trong suốt.
- layers.json ghi vị trí gốc và sprite_origins theo canvas con. Dùng tọa độ origin khi đặt điểm chân. Bird 4 khung; flag, torch, smoke 6 khung, một hàng ngang. Khói đặt đáy tại miệng lều; cờ đặt chân cột.
- Lưu ý parallax: các lớp tĩnh bảo toàn ảnh nguồn bằng mặt nạ và phân vùng chiều sâu, chưa có phần vẽ bù bị che phía sau vật thể. Cần thử độ lệch nhỏ trong engine; dịch tương đối lớn có thể lộ đường cắt. Không khẳng định đã kiểm tra parallax trong game.
- Particle và shine dùng RGB trắng, code tô màu. Ring và glow_outline có lỗ alpha. Bụi cỏ/mây phụ không baked vào bản ghép kiểm định.

## Kiểm tra

Backdrop đục; độ sáng trung bình 83.1% (Orc), 89.0% (training). Slot 89–90%. Cả hai phép so sánh pixel bản ghép đều đúng hoàn toàn. Các ảnh xem thử dùng gạch hiện có, không đổi source code. Chỉ assets/ và docs/ideas/ được đưa vào commit.

## Danh sách file

- `assets/ui/board_backdrop_orc_shield.png` — 1080×1260
- `assets/ui/board_backdrop_training.png` — 1080×1260
- `assets/ui/board_panel_orc_shield.png` — 1040×1180
- `assets/ui/board_panel_training.png` — 1040×1180
- `assets/ui/board_slot_orc_shield.png` — 140×140
- `assets/ui/board_slot_training.png` — 140×140
- `assets/bg/training_field/bird.png` — 384×64
- `assets/bg/training_field/cloud_1.png` — 320×128
- `assets/bg/training_field/cloud_2.png` — 320×128
- `assets/bg/training_field/cloud_3.png` — 320×128
- `assets/bg/training_field/far.png` — 1080×660
- `assets/bg/training_field/flag.png` — 768×128
- `assets/bg/training_field/grass.png` — 160×96
- `assets/bg/training_field/ground.png` — 1080×660
- `assets/bg/training_field/layers.json`
- `assets/bg/training_field/mid.png` — 1080×660
- `assets/bg/training_field/sky.png` — 1080×660
- `assets/bg/orc_camp/bird.png` — 384×64
- `assets/bg/orc_camp/cloud_1.png` — 320×128
- `assets/bg/orc_camp/cloud_2.png` — 320×128
- `assets/bg/orc_camp/cloud_3.png` — 320×128
- `assets/bg/orc_camp/far.png` — 1080×660
- `assets/bg/orc_camp/grass.png` — 160×96
- `assets/bg/orc_camp/ground.png` — 1080×660
- `assets/bg/orc_camp/layers.json`
- `assets/bg/orc_camp/mid.png` — 1080×660
- `assets/bg/orc_camp/sky.png` — 1080×660
- `assets/bg/orc_camp/smoke.png` — 768×192
- `assets/bg/orc_camp/torch.png` — 384×128
- `assets/fx/particles/glow.png` — 128×128
- `assets/fx/particles/ring.png` — 256×256
- `assets/fx/particles/shard.png` — 64×64
- `assets/fx/particles/spark.png` — 64×64
- `assets/fx/particles/star.png` — 64×64
- `assets/tiles/shine.png` — 128×128
- `assets/tiles/glow_outline.png` — 192×192
