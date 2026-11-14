# Quái đợt 3 cho ChatGPT: Rừng đen (hồi 3, màn 37–58)

Claude viết ngày 14/11/2026. Kế hoạch: [docs/release_plan.md](../../release_plan.md) giai đoạn B, [docs/campaign_100.md](../../campaign_100.md) hồi 3.

Cách làm **y hệt đợt 1 và 2**: [monsters_round1.md](monsters_round1.md):
- lưới 4 cột, khung 512, chân tại (256, 500), quay mặt sang trái;
- nền `#FF00FF`, tách bằng `key_out.py --key ff00ff`, kiểm bằng `check_sheet.py --key ff00ff`;
- không vẽ hiệu ứng.

File này chỉ ghi những gì khác.

**Làm sau [store_art_request.md](../store_art_request.md)** (ảnh store cần trước).

## Khác đợt trước: quái mới, chưa có ảnh gốc

Đợt này toàn quái **chưa từng vẽ**. Với mỗi quái:

1. Vẽ trước **trang mẫu** `docs/ideas/sprites/monsters3/<quái>_model.png`: nhìn nghiêng trái, nhìn chính diện, cận mặt.
2. Phong cách khớp với quái đã có. Đặt `assets/characters/orc_chief/anim/fresh_idle.png` và `goblin_thief/anim/fresh_idle.png` cạnh nhau để so: cùng nét viền đậm, cùng cách tô, cùng tỉ lệ chibi.
3. Clip nào cũng vẽ từ trang mẫu, để mặt và đồ không đổi giữa các khung.

Cỡ người (khung 0 `idle`, đo bằng `check_sheet.py`): quái thường khoảng 330–390 px; Sói Đen và Quạ Đen có thể thấp hơn (260–320 px). Khi kiểm, `--ref` chỉ vào chính `fresh_idle.png` của quái đó.

## Nhánh và thư mục

- Nhánh mới `art/monsters-3`, tạo từ `origin/core/world-life`.
- Chỉ thêm file vào `assets/characters/<quái>/anim/` và `docs/ideas/sprites/monsters3/`.
- Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`, `hero_rookie`. Không force push.
- Report và GIF mỗi quái để trong thư mục riêng: `--out docs/ideas/sprites/monsters3/<quái>`.

## Danh sách

Bộ chuẩn: `idle` 8/12, `attack` 12/24 impact 6, `hurt` 8/24, `special` 12/24 impact 7, `defeat` 12/12, `victory` 8/12.

| # | Thư mục | Quái | Trông thế nào | `special` | Thêm |
|---|---|---|---|---|---|
| 1 | `black_wolf` | Sói Đen | sói lông đen bóng, mắt vàng, đứng bốn chân, khăn rách đỏ quanh cổ; nhanh nhẹn, gầy | lao vồ hai chân trước, đớp | — |
| 2 | `dungeon_rat` | Chuột Ngục | chuột to bằng người lùn, đứng hai chân, mặc áo tù sọc, cầm chùm chìa khóa gỉ | quất chùm chìa khóa xoay vòng | — |
| 3 | `gingerbread_guard` | Lính Bánh Gừng | người bánh gừng cao, viền kem trắng, nút kẹo, đội mũ lính, cầm giáo kẹo gậy | đâm giáo kẹo gậy hai nhát | **`split`** 10/12: nứt đôi từ đầu xuống, hai nửa tách ra hai bên (khung cuối người đã tách hẳn) |
| 4 | `gingerbread_mini` | Bánh Gừng Nhỏ | đúng Lính Bánh Gừng thu nhỏ còn 60%, không mũ, không giáo, mặt nhăn giận | húc đầu | cỡ người khoảng 230 px |
| 5 | `black_crow` | Quạ Đen | quạ to đậu trên một cành cây khô gãy (cành cắm xuống đất), đeo một chiếc chìa khóa đồng ở cổ | xòe cánh, mổ giật về phía trước | — |
| 6 | `black_cat` | Mèo Đen | mèo đen đứng hai chân, mặc áo choàng tím có sao, đuôi cong, mắt xanh lục **nhạt** (không dùng `#FF00FF`) | giơ chân trước, vẽ một vòng phép trong không trung (không vẽ vòng sáng) | — |

**Màu cấm:** không dùng hồng tím `#FF00FF` hay màu gần nó trên quái (áo choàng tím của Mèo Đen dùng tím than `#4B2E6B`).

## Điểm dừng duyệt

1. Làm trọn **`black_wolf`**: trang mẫu và 6 động tác, tất cả ĐẠT. Commit, push, báo, rồi **dừng chờ duyệt**.
2. Được báo "duyệt quái" thì làm tiếp số 2 đến 6. Mỗi quái xong thì commit và push một lần.
3. Xong cả 6: báo kết quả từng sheet, rồi **dừng**.

Ba mụ phù thủy (Bà Cả, Bà Hai, Bà Út, Mụ Già Ba Mặt) để đợt 4, sau khi đợt này duyệt.
