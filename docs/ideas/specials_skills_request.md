# Yêu cầu cho ChatGPT: ô đặc biệt nổi khối, kết hợp và tuyệt chiêu anh hùng

Claude viết, gửi ChatGPT. Bộ này gồm hai phần: **thiết kế** (`docs/ideas/hero_skills.md`) và **ảnh** (`assets/`). Mỗi phần một nhánh riêng, ví dụ `docs/hero-skills` và `art/specials-3d`, rồi mở pull request. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`; Claude ghép vào game sau khi duyệt.

## Đã đổi trong game (nhánh `core/polish-pass`)

- Bom, sét, sao giờ đều **nối được với mọi màu**, và nối được với nhau dù khác màu. Người chơi không còn thấy màu của chúng.
- Ô đặc biệt vẽ trần, **không có nền ô** phía sau. Code tự lo: bóng đổ mềm dưới chân, bom rung và dây cháy toé lửa/khói, sét chớp, sao xoay.
- Gạch Orc đang được nối dùng nét mặt `fear`, ô cuối dùng `scream`, thả ra thì `relief` (ảnh trong `assets/tiles/orc_shield/expressions/`).
- Hai ô đặc biệt cạnh nhau khi nổ thì **hợp thể**: bom+bom nổ 5×5, sét+bom thành chữ thập rộng 3 ô, sao+X biến mọi ô cùng màu thành X, sao+sao xoá cả bảng. Sét+sét chưa có hợp thể riêng.

Người chơi muốn: 2D nhưng **nhìn nổi khối**, cái nào cũng có hiệu ứng bắt mắt, kết hợp thoải mái, và anh hùng có **tuyệt chiêu**; càng nhiều, càng đẹp càng tốt.

## Phần 1: Thiết kế, viết vào `docs/ideas/hero_skills.md`

1. **Bảng hợp thể đầy đủ**, gồm mọi cặp kể cả sét+sét: tên tiếng Việt, vùng xoá (theo ô của bảng 7×8), cảm giác muốn có, và chữ comic hiện ra.
2. **Tuyệt chiêu của anh hùng**, 4–6 chiêu. Mỗi chiêu ghi:
   - tên tiếng Việt, ngắn, dễ nhớ;
   - cách kích hoạt: ví dụ nổ một hợp thể, nối từ N ô đặc biệt trở lên, hay nạp đầy một thanh năng lượng;
   - tác dụng trong trận (sát thương, phá khiên, hồi máu, làm choáng...), kèm con số đề xuất so với `data/balance.tres`;
   - kịch bản từng nhịp, khoảng 1,5–2,5 giây: tư thế anh hùng, hiệu ứng, camera, chữ comic.
3. Nếu muốn thêm ô đặc biệt mới (búa, phi tiêu, nam châm...), mô tả luật và tạo ra khi nào (ví dụ nối 8 ô).

## Phần 2: Ảnh

Quy ước chung: PNG nền trong suốt, tên viết thường không dấu, nối bằng `_`. Atlas 8 khung mỗi hàng, đọc khung i tại `(i%8*w, floor(i/8)*h)`, gốc ở tâm khung. Mỗi thư mục atlas có file json giống `assets/fx/specials/specials.json` (`frame_width`, `frame_height`, `frames`, `fps`, `loop`).

**Nổi khối:** ánh sáng từ trên-trái, có highlight, phần tối, viền sáng (rim light) và viền mực đậm, giống kiểu gạch Orc hiện tại. **Không vẽ bóng đổ dưới chân**, vì code tự vẽ bóng.

| Thư mục / file | Khung | Nội dung |
|---|---|---|
| `assets/tiles/specials/bomb.png` | 128×128 | Bom tròn nổi khối, dây ngắn, **chưa có lửa**. Ghi toạ độ đầu dây (px) vào json |
| `assets/tiles/specials/bomb_fuse.png` | 128×128, 12 khung, loop | Lửa đầu dây cháy lép bép, đặt đúng đầu dây của `bomb.png` |
| `assets/tiles/specials/lightning.png` + `lightning_idle.png` | 128×128, 8–12 khung, loop | Sét chữ thập nổi khối; idle có tia điện chạy |
| `assets/tiles/specials/star.png` + `star_idle.png` | 128×128, 8–12 khung, loop | Sao bốn cánh nổi khối, **không có nền ô**; idle lấp lánh |
| `assets/fx/fusions/<ten_hop_the>.png` | 512×512, 12–16 khung | Một hiệu ứng riêng cho mỗi hợp thể ở Phần 1 |
| `assets/characters/hero_rookie/skill_<ten>_<pose>.png` | canvas 512, như các pose hiện có | Các tư thế của từng tuyệt chiêu |
| `assets/fx/skills/<ten>.png` | tuỳ chiêu, ghi vào json | Hiệu ứng của tuyệt chiêu: chém, lốc, sóng... |
| `assets/fx/comic/<chu>.png` | 512×320 | Chữ comic mới cho hợp thể và tuyệt chiêu, nếu cần |

Ưu tiên làm trước: `bomb.png` + `bomb_fuse.png`, rồi sét, rồi sao. Hợp thể và tuyệt chiêu làm sau khi Phần 1 được duyệt.

Như các lần trước, kèm trang xem thử và danh sách file mới. Ghi rõ phần nào đã tự kiểm tra, phần nào chưa.
