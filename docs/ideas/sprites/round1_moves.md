# Đợt 1 cho Gemini: 9 động tác mới của hiệp sĩ (bậc Tân binh)

Claude viết. Kế hoạch chung: [docs/sprite_plan.md](../../sprite_plan.md).

Làm trên nhánh `art/hero-moves-1`, tạo từ `origin/core/world-life`. Chỉ thêm file vào `assets/characters/hero_rookie/anim/` và `docs/ideas/sprites/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, `anim.json`, các file `.import`. Không force push.

## Nhân vật

Đúng hiệp sĩ Tân binh đang có, **giống hệt** `assets/characters/hero_rookie/anim/fresh_idle.png` và `fresh_attack.png`:
- Tóc nâu bù xù, khăn đỏ, áo xanh viền kem, dây đeo chéo, thắt lưng khóa vàng, quần nâu, ủng nâu, áo choàng đỏ.
- **Kiếm gỗ** cầm tay phải, **khiên tròn gỗ viền sắt** tay trái.
- Cùng nét viền, cùng cách tô bóng, cùng tỉ lệ chibi.

## Định dạng (bắt buộc, có script kiểm)

- Mỗi động tác một sheet PNG nền trong suốt, **lưới 4 cột**, mỗi khung **512×512**, đọc từ trái sang phải, từ trên xuống dưới.
- **Quay mặt sang phải.**
- **Chân chạm đất tại (256, 500)** ở khung đầu và khung cuối. Người cao khoảng 390 px như `fresh_idle` khung 0 (lệch tối đa 8%).
- **Diễn tại chỗ:** chân không trôi ngang quá 40 px khỏi x = 256. Game tự di chuyển nhân vật khi lướt, nhảy hay lùi. Với động tác nhảy, vẽ tư thế trên không ngay tại chỗ, không vẽ cao lên; game tự nâng nhân vật.
- Không phần nào bị cắt bởi mép khung.
- **Không vẽ hiệu ứng:** không vệt chém, sét, ánh sáng, bụi, bóng dưới đất. Game tự vẽ hiệu ứng, để mọi bậc trang bị dùng chung.
- Khung đầu và khung cuối gần giống tư thế đứng (`fresh_idle` khung 0), để nối mượt với các động tác khác.
- Không bụi, không viền mờ lem nhem quanh người.

## Xóa nền: vẽ trên nền xanh, không vẽ trên nền trắng

Bản bước A bị lỗi **khe trắng**: vẽ trên nền trắng rồi xóa nền loang từ mép vào, nên các khe bị viền bao kín vẫn trắng (giữa các lọn tóc, giữa tay và kiếm, dưới nách). Mắt và răng cũng trắng nên máy không tách ra được. Từ nay làm thế này:

1. Vẽ mọi khung trên **nền xanh lá thuần #00FF00**, phẳng một màu, không đổ bóng, không chuyển màu. Nhân vật không được có màu xanh lá nào.
2. Lưu bản gốc nền xanh vào `docs/ideas/sprites/round1/raw/fresh_<tên>_green.png` (cùng lưới 4 cột × 512).
3. Tách nền bằng công cụ có sẵn (không tự xóa nền kiểu khác):
   ```sh
   python3 tools/sprites/key_out.py docs/ideas/sprites/round1/raw/fresh_<tên>_green.png assets/characters/hero_rookie/anim/fresh_<tên>.png
   ```
   Công cụ xóa mọi điểm màu xanh ở khắp nơi, kể cả khe kín, làm mềm mép và khử quầng xanh.
4. Nếu sau khi tách thấy mép bị khuyết hay còn quầng, **sửa bản gốc nền xanh** rồi tách lại. Không sửa tay trên bản đã tách.

## Danh sách

`impact` là số khung (đếm từ 0) mà đòn chạm quái. Game dùng số này để rung màn hình và trừ máu.

| File | Khung | fps | impact | Diễn |
|---|---|---|---|---|
| `fresh_combo.png` | 16 | 24 | 4, 9, 14 | 0–2 thủ thế, nhích tới · 3–4 chém chéo từ trên xuống · 5–7 xoay cổ tay lấy đà · 8–9 chém hất ngược lên · 10–12 rút kiếm ra sau, xoay vai · 13–14 đâm thẳng tới · 15 về thủ thế |
| `fresh_block.png` | 8 | 24 | — | 0–2 giơ khiên che trước ngực, khom người · 3–4 bị đánh trúng khiên: giật lùi nửa bước, nhăn mặt · 5–7 hạ khiên về thủ thế |
| `fresh_dash.png` | 6 | 24 | — | 0–1 hạ thấp người, chân sau đạp · 2–4 lao người về trước, khăn và áo choàng bay ra sau, kiếm chĩa tới · 5 dừng lại, sẵn sàng chém |
| `fresh_skill_armor_breaker.png` | 14 | 24 | 9 | Phá Giáp: 0–3 khuỵu gối lấy đà, hai tay nắm kiếm giơ cao quá đầu · 4–7 tư thế bật lên (tại chỗ), kiếm sau đầu · 8–9 bổ dọc xuống hết sức · 10–13 kiếm chạm đất, đứng dậy |
| `fresh_skill_second_wind.png` | 14 | 12 | — | Hồi Quang: 0–3 quỳ một gối, chống kiếm, thở dốc · 4–8 ngẩng đầu, nhắm mắt, ngực ưỡn · 9–13 đứng dậy, siết khiên, mặt quyết tâm |
| `fresh_skill_thunder_slash.png` | 14 | 24 | 8 | Lôi Trảm: 0–3 lùi nửa bước, kiếm kéo ra sau hông · 4–7 phóng người tới, thân gần nằm ngang · 8 chém ngang một nhát · 9–13 trượt dừng, quay về thủ thế |
| `fresh_skill_iron_guard.png` | 10 | 12 | — | Hộ Thể: 0–3 bước chân rộng, hạ trọng tâm · 4–6 cắm vành khiên xuống đất trước mặt, vai tì vào khiên · 7–9 giữ thế thủ, mắt nhìn tới |
| `fresh_skill_blade_vortex.png` | 16 | 24 | 4, 8, 12 | Phong Kiếm: 0–2 vặn người lấy đà · 3–14 xoay tròn ba vòng tại chỗ, kiếm dang ngang, mỗi vòng một nhát (khung 4, 8, 12 kiếm quét qua phía trước) · 15 dừng, chóng mặt nhẹ |
| `fresh_skill_starfall_strike.png` | 16 | 24 | 12 | Tinh Kiếm: 0–3 ngồi sâu lấy đà · 4–9 tư thế bay lên cao (tại chỗ), kiếm giơ thẳng trời, người duỗi · 10–12 chúc xuống, kiếm đâm thẳng xuống đất · 13–15 quỳ một gối, rút kiếm đứng dậy |

## Phạm vi đợt này

Bước A (`combo`, `block`) đã duyệt về dáng và nhịp, nhưng phải **làm lại trên nền xanh** vì lỗi khe trắng. Giữ nguyên động tác, chỉ đổi cách vẽ nền.

Làm luôn **cả 9 động tác** trong bảng trên (2 động tác làm lại + 7 động tác mới), trong một lần, trên cùng nhánh `art/hero-moves-1`.

## Tự kiểm tra

Với mỗi sheet, chạy:

```sh
python3 tools/sprites/check_sheet.py assets/characters/hero_rookie/anim/fresh_<tên>.png --frames <số khung> --fps <fps> --key 00ff00 --out docs/ideas/sprites/round1
```

Lệnh in ĐẠT hoặc TRƯỢT cho từng mục (lưới, chân, cỡ người, sạch, trong khung, nền khóa), và ghi kèm ảnh khung đánh số và file GIF. Claude sẽ tự chạy lại `key_out.py` trên bản nền xanh để đối chiếu, nên bản gốc nền xanh là bắt buộc. **Tất cả phải ĐẠT** mới push, tối đa 5 vòng sửa. Ghi số đo từng vòng vào `docs/ideas/sprites/round1/rounds.md`.

Ngoài script, tự xem GIF: động tác phải liền mạch, không giật, không khung nào người đổi cỡ hay đổi màu áo. Đặt thử một khung lên nền tối để chắc không còn khe trắng hay quầng sáng quanh người.

## Bàn giao

- 9 sheet đã tách nền trong `anim/`.
- 9 bản gốc nền xanh trong `docs/ideas/sprites/round1/raw/`.
- GIF và report trong `docs/ideas/sprites/round1/`.

Commit, push `art/hero-moves-1` (không force push), báo kết quả kiểm tra cả 9 sheet, rồi **dừng**.
