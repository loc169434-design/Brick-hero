# Bom, sét, sao nổi khối — đợt đầu

Theo `docs/ideas/specials_skills_request.md`. Nhánh `art/specials-3d` từ main `26b8800`. Phần thiết kế đủ sáu hợp thể và sáu chiêu nằm riêng trên `docs/hero-skills`, file `docs/ideas/hero_skills.md`; chờ duyệt thiết kế trước khi vẽ hợp thể/tư thế chiêu.

## Xem thử

- [Trang review](index.html): phát/dừng, nền xanh đậm/caro/sáng, 128 px/phóng to/46 px.
- [GIF 12 fps, mỗi vòng một giây](specials_idle.gif).
- [Ba ảnh tĩnh trên xanh đậm](static_dark_blue.png), [trên nền sáng](static_light.png), [kích thước 46 px](static_game_size_46.png).
- [Đủ 12 khung trên xanh đậm](all_frames_dark_blue.png).
- [Thông số và kiểm tra](checks.json), [danh sách file mới](files.txt).

## Dành cho Claude tích hợp

Thư mục `assets/tiles/specials/` có ba ảnh tĩnh 128×128 RGBA8, ba atlas 1024×256 RGBA8 và `specials.json`.

| File | Dùng |
|---|---|
| `bomb.png` | Bom chưa có lửa, không có bóng đổ/nền ô. Đầu dây `(88,28)` px tính từ góc trên-trái khung. |
| `bomb_fuse.png` | 12 khung lửa/khói/tia lửa, 12 fps, loop. **Chỉ là overlay**, đặt chồng cùng khung 128×128 với bom, không đặt tâm texture vào đầu dây lần nữa. Tâm sáng chân lửa đã đăng ký tại đầu dây. |
| `lightning.png` | Sét chữ thập vàng tĩnh. |
| `lightning_idle.png` | 12 khung, 12 fps, loop; **đã gồm sét gốc**, thay ảnh tĩnh, không chồng cả hai. Tia điện chạy quanh, glint giữa. |
| `star.png` | Sao vàng bốn cánh tĩnh. |
| `star_idle.png` | 12 khung, 12 fps, loop; **đã gồm sao gốc**, hai điểm lóe thay phiên. |

Atlas **8 cột**, vị trí frame i = `(i%8*128, floor(i/8)*128)`. Khung 0–7 ở hàng đầu, 8–11 ở hàng sau; bốn ô còn lại trống alpha 0. Gốc vẽ tâm `(64,64)`. JSON cùng kiểu manifest hiện có, bổ sung `fuse_tip`, `overlay_on`, `includes_base` để bàn giao; các ảnh tĩnh có frames=1, fps=1, loop=false.

Giữ bóng chân/rung/rotation của code nếu phù hợp, nhưng **tắt lửa/khói/tia lửa thủ tục cũ khi dùng bomb_fuse**, và tránh vẽ thêm điện/glint trùng idle mới. Không đổi logic màu/vạn năng. Không ghi đè ảnh cũ hoặc manifest FX hiện tại. Không có code game nào được sửa trong nhánh này.

## Đã kiểm và chưa kiểm

Đã kiểm kích thước, 8-bit RGBA, số khung, ô đệm trong suốt, alpha biên từng frame, không có nền vuông; ghép xem trực tiếp trên nền xanh đậm và sáng. Chân lửa được đặt theo đầu dây trên cùng hệ toạ độ. Các vật thể giữ cùng silhouette giữa các frame; điện và glint là lớp hiệu ứng. GIF có 12 frame, tổng 1000 ms, dùng bảng màu chung.

Chưa kiểm trong Godot hoặc trên thiết bị thật, chưa thay lửa/điện của game, chưa xác nhận cảm giác nhìn ở 46 px bằng chơi thật. Trang HTML cần mở trong trình duyệt; chưa tự kiểm bằng trình duyệt tự động. Không có ảnh hợp thể/tư thế tuyệt chiêu ở đợt này vì yêu cầu gốc chờ duyệt thiết kế trước.

## Trạng thái bàn giao

Đang chuẩn bị commit/push và PR; sẽ cập nhật kết quả thực tế sau khi gửi.
