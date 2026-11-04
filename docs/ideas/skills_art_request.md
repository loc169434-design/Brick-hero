# Yêu cầu cho ChatGPT: ảnh tuyệt chiêu và hợp thể, bản đầy đủ

Claude viết, gửi ChatGPT. Thiết kế gốc là [hero_skills.md](hero_skills.md), người dùng đã duyệt kèm các thay đổi bên dưới.
Làm trên nhánh `art/skills`, chỉ sửa `assets/` và `docs/ideas/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`; Claude ghép vào game.

Người dùng muốn **hoạt hình chi tiết như game hoàn chỉnh**, chấp nhận làm lâu hơn. Vì vậy bỏ cách "3–4 tư thế chính" ở mục 4 của thiết kế: mỗi tuyệt chiêu là **một clip đầy đủ từng khung**, cùng chuẩn và chất lượng với các đòn ở issue #24 (`kick`, `bash`, `leap`...).

## 1. Đã chốt

- Đủ 6 hợp thể như bảng ở mục 2 của thiết kế. Sét+sét bắn 8 hướng là hợp thể mới.
- Sao+X chọn màu mục tiêu theo đề xuất trong thiết kế (màu đường nối, nếu không có thì màu nhiều nhất trên bảng), không dùng màu ẩn.
- Đủ 6 tuyệt chiêu, kịch bản và cảm giác giữ như mục 3. Làm Phá Giáp và Hồi Quang trước.
- Con số (thanh Nộ, sát thương, máu hồi) Claude chỉnh bằng bot mô phỏng, không ảnh hưởng tới ảnh. Thời lượng cả cảnh vẫn khoảng 1,8–2,4 giây.

## 2. Clip tuyệt chiêu của anh hùng

Giống hệt quy cách các clip hiện có của `hero_rookie`:

- File `assets/characters/hero_rookie/anim/<mức>_skill_<id>.png`, `<mức>` là `fresh`, `bruised`, `battered`. **Đủ cả 3 mức**, vì chiêu hay được dùng lúc anh hùng đã bị thương; thiếu mức nào thì hình sẽ nhảy về bản lành lặn.
- Lưới **4 cột**, ô **512×512**, RGBA, ô thừa trong suốt. Cùng điểm neo chân và cỡ người như `fresh_idle`.
- Thêm vào `assets/characters/hero_rookie/anim/anim.json`, mục `clips`, tên `skill_<id>`: `frames`, `fps`, `loop: false`, `impact` (khung chạm). Chiêu nhiều nhát thêm `hits`: danh sách khung của từng nhát. Một mục dùng chung cho cả 3 mức, như #24.
- Tối đa **32 khung** mỗi clip (atlas 2048×4096). 24 fps thì được khoảng 1,3 giây; cần dài hơn thì hạ fps xuống 16–20 và ghi vào json. Phần dừng hình, camera và hiệu ứng tắt dần do code làm.
- Khung đầu và khung cuối **trùng đúng pixel với `idle` khung 0** của cùng mức.
- Clip đứng tại chỗ. Đường lao hay nhảy tới quái do code di chuyển, như `bash` và `leap`.
- Ánh sáng bám vào người hay kiếm (điện chạy trên lưỡi kiếm, kiếm phát sáng, ánh xanh trên thân) vẽ luôn vào clip. Hiệu ứng tách khỏi người (vệt chém, sóng, mảnh vỡ, vòng sáng) để ở mục 4.
- Không vẽ bóng đổ dưới chân. Bản `battered` giữ quy ước #24: kiếm sứt ngắn, băng trán, áo rách.

| `id` | Tên | Động tác (chi tiết ở thiết kế mục 3) | `impact` |
|---|---|---|---|
| `armor_breaker` | Phá Giáp | Hạ trọng tâm, khiên chắn trước, kiếm rút sau vai → lao vai, mũi kiếm đâm thẳng → bật người về | Khung mũi kiếm chạm giáp |
| `thunder_slash` | Lôi Trảm | Giơ kiếm chéo trên đầu, điện tụ dần trên lưỡi → chém xuống mạnh → thu kiếm | Khung lưỡi kiếm qua giữa người quái |
| `second_wind` | Hồi Quang | Quỳ một gối, kiếm cắm đất, tay đặt lên ngực → ánh xanh ngọc xoáy lên thân → ngẩng đầu, đứng dậy, khăn bay | Khung máu được hồi |
| `iron_guard` | Hộ Thể | Trụ hai chân, nâng khiên → khiên sáng xanh lam → hạ về thế thủ | Khung áp lớp bảo vệ |
| `blade_vortex` | Phong Kiếm | Kiếm ngang hông, co người → xoay người ba vòng chém → chống kiếm tiếp đất | `impact` = nhát đầu, `hits` = 3 nhát |
| `starfall_strike` | Tinh Kiếm | Ngửa kiếm đón ngôi sao → bật nhảy cao → bổ chéo xuống → tiếp đất | Khung bổ trúng |

Thêm một clip ngắn `guard_block` (khoảng 8 khung, đủ 3 mức): anh hùng đỡ đòn bằng khiên đang sáng, dùng khi Hộ Thể chặn đòn của quái.

## 3. Phản ứng mới của Orc Khiên

Orc hiện có `hurt`, `dizzy` thì chưa có. Thêm vào `assets/characters/orc_shield/anim/`, **đủ 3 mức**, cùng quy cách và điểm `shield` theo tay từng khung như #24:

| Clip | Dùng khi | Ghi chú |
|---|---|---|
| `knocked` | Phá Giáp, Tinh Kiếm | Bị đánh bật lùi mạnh, loạng choạng rồi đứng vững lại, về `idle` khung 0 |
| `shocked` | Lôi Trảm | Giật điện cứng người, tóc dựng, khói nhẹ; khoảng 12 khung, về `idle` khung 0 |

## 4. Hiệu ứng chiêu: `assets/fx/skills/`

Atlas **8 cột**, gốc ở tâm khung, kèm `skills.json` cùng kiểu `assets/fx/specials/specials.json` (`frame_width`, `frame_height`, `frames`, `fps`, `loop`). Mặc định 512×512, 16 khung, 24 fps, không loop. Hiệu ứng dài theo chiều ngang thì dùng 768×512 và ghi vào json. Hạt cuối tắt về alpha 0.

| File | Nội dung |
|---|---|
| `armor_break_trail.png` | Vệt lao hẹp màu hổ phách sau mũi kiếm |
| `shield_shatter.png` | Khiên kim loại nứt rồi vỡ bung thành mảnh |
| `thunder_slash_arc.png` | Vệt chém cong màu cyan, lõi trắng |
| `shock_body.png` | Điện chạy trên thân quái, loop ngắn, đặt chồng lên quái |
| `second_wind_aura.png` | Xoáy xanh ngọc kèm lá sáng bay lên quanh thân |
| `iron_guard_shield.png` | Khiên lục giác sáng nổi lên trước người rồi co lại |
| `iron_guard_block.png` | Lóe sáng khi khiên sáng đỡ một đòn |
| `blade_vortex_ring.png` | Lốc kiếm trắng-xanh quanh thân, đủ cho ba vòng |
| `starfall_charge.png` | Ngôi sao bốn cánh tụ trên mũi kiếm |
| `starfall_trail.png` | Vệt sao kéo sau người khi nhảy |
| `starfall_impact.png` | Vòng sáng sao khi bổ trúng, xuyên qua thân quái |

## 5. Giao diện

| File | Cỡ | Nội dung |
|---|---|---|
| `assets/ui/rage_bar_frame.png` | 768×42 | Khung thanh Nộ nằm ngang dưới bàn chơi, hợp với thanh máu kiểu game đối kháng đang có; phần lõi 760×34 ở giữa để trống |
| `assets/ui/rage_bar_fill.png` | 760×34 | Phần đổ đầy màu lửa, code cắt từ trái sang theo phần trăm |
| `assets/ui/skill_<id>.png` | 160×160 | Biểu tượng nút tròn của từng chiêu, vẽ trong vòng tròn đường kính khoảng 150; code làm tối khi chưa đủ Nộ và tự vẽ viền tiến độ quanh nút |
| `assets/ui/buff_iron_guard.png` | 96×96 | Biểu tượng lớp bảo vệ Hộ Thể đang chờ |

## 6. Hợp thể: `assets/fx/fusions/`

Như mục 4 của thiết kế: `double_bomb`, `thunder_cross`, `double_lightning`, `star_bomb`, `star_lightning`, `double_star`. Mỗi file 512×512, 16 khung, 24 fps, không loop, kèm `fusions.json`. Hiệu ứng là phần trang trí đặt tại ô nổ; code tự bắn tia theo đúng hàng, cột và đường chéo bằng tia sét có sẵn, nên **không vẽ tia dài hết bảng** trong atlas.

## 7. Chữ comic: `assets/fx/comic/`

Cùng cỡ, kiểu và font Bangers với các chữ đang có (`boom.png`, `zap.png`...): `armor_break`, `thunder_slash`, `second_wind`, `iron_guard`, `blade_vortex`, `starfall`, `mega_boom`, `thunder_boom`, `thunder_storm`, `bomb_rain`, `lightning_rain`, `supernova`. Chữ đúng như thiết kế, ví dụ `ARMOR BREAK!`.

## 8. Chia đợt

Mỗi đợt push lên `art/skills` rồi báo trong issue.

1. **Phá Giáp và Hồi Quang**: hai clip bản `fresh` trước, kèm GIF để người dùng duyệt nhịp và dáng; duyệt xong mới làm `bruised` và `battered`. Kèm Orc `knocked`, hiệu ứng của hai chiêu, chữ comic, thanh Nộ, hai biểu tượng, và hợp thể `double_lightning`.
2. **Bốn chiêu còn lại**, `guard_block`, Orc `shocked`, các hiệu ứng, biểu tượng và chữ còn lại.
3. **Năm hợp thể còn lại.**

## 9. Kiểm tra trước khi giao

Như #24:

- GIF đúng fps của từng clip, ảnh lưới đánh số trên nền xanh đậm, và GIF ghép anh hùng với Orc phản ứng đúng khung `impact`.
- File json kiểm tra: kích thước, số khung, alpha, ô thừa trong suốt, khung đầu và cuối trùng `idle`.
- Đặt GIF và ảnh duyệt trong `docs/ideas/skills_review/`, có file `.gdignore` để Godot không import.
- Chạy Godot 4.7.2 import, kèm kết quả bộ test như #24.
