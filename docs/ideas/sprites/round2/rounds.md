# Kết quả kiểm tra Đợt 2 (Điểm dừng duyệt: Trang mẫu Bộ da & `idle`)

## Việc 0: Sửa khung 6 của `fresh_skill_blade_vortex` (Đợt 1)

- Sửa khung 6 (nhìn từ sau lưng) trong `docs/ideas/sprites/round1/raw/fresh_skill_blade_vortex_green.png`: bỏ khiên thừa bên phải, thay bằng kiếm gỗ cầm ở tay phải, tay trái mang một khiên tròn, khớp nhịp xoay giữa khung 5 và khung 7.
- Tách nền bằng `tools/sprites/key_out.py` ra `assets/characters/hero_rookie/anim/fresh_skill_blade_vortex.png`.
- Chạy `tools/sprites/check_sheet.py --frames 16 --fps 24 --key 00ff00 --out docs/ideas/sprites/round1`:
  - `grid`: ĐẠT (`2048x2048`, `empty frames: []`)
  - `feet`: ĐẠT (`(500.0, 256.0)` ở khung 0 và khung 15)
  - `size`: ĐẠT (`398 px` vs `394 px`)
  - `clean`: ĐẠT (`0 stray pixels, 0 specks, 0 haze`)
  - `inside`: ĐẠT (`none`)
  - `key`: ĐẠT (`#00ff00 left: 0 px; rim tinted by it: 0 px`)

## Trang mẫu Bộ da (`docs/ideas/sprites/round2/leather_model_sheet.png`)

- Sửa trực tiếp từ `docs/ideas/sprites/round2/rookie_ref.png` trên nền `#00FF00`, đối chiếu cận mặt `docs/ideas/sprites/round2/rookie_face_ref.png`:
  - Giữ nguyên 100% gương mặt Tân binh (mắt to viền đen, lông mày rậm nhíu, miệng cười toe lộ răng, cằm vuông, tai) và tóc nâu bù xù lòi ra nhiều ở mái trước trán dưới vành mũ, hai bên thái dương và sau gáy.
  - Đội mũ da khâu chỉ có quai cài cằm (`leather_helmet.png`) lên trên đầu sẵn có.
  - Thay áo bằng giáp ngực da nâu (`leather_armor.png`: đệm vai, khóa đồng ở vai và thắt lưng, vạt da dưới bụng; lộ tay áo xanh và vạt áo xanh bên dưới), bao tay da buộc dây đến khuỷu, ủng da cao 2 dây cài có mũi bọc, kiếm sắt ngắn (cùng độ dài kiếm gỗ), khiên tròn bọc da viền sắt đinh tán đồng và núm đồng.

## Clip `idle` Bộ da (`assets/characters/hero_rookie/anim/leather/fresh_idle.png`)

| Clip | Khung | FPS | Grid | Feet (K0 / KCuối) | Size (K0 / Ref) | Clean | Inside | Key (`#00ff00`) | Kết quả | Số vòng |
|---|---:|---:|---|---|---|---|---|---|---|---:|
| `fresh_idle` | 8 | 12 | `2048x1024` ĐẠT | `(500, 256)` / `(500, 256)` ĐẠT | `412 px` / `394 px` (`+4.6%`) ĐẠT | `0 stray, 0 specks` ĐẠT | `none` ĐẠT | `0 left, 0 tint` ĐẠT | **ĐẠT** | 1 |
