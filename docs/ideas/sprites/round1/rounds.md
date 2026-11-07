# Báo cáo kiểm tra Đợt 1 — Toàn bộ 9 động tác chiến đấu & kỹ năng (`#00FF00` Key Out)

Nhánh: `art/hero-moves-1` (cập nhật công cụ từ `origin/core/world-life`).
Tham chiếu chuẩn: `assets/characters/hero_rookie/anim/fresh_idle.png` (khung 0 cao `394 px`, chân tại `(254.5, 500.0)`).

---

## Quy trình nền xanh `#00FF00` & Tách nền chuẩn

1. **Vẽ trên nền xanh thuần `#00FF00`:**
   - Làm lại `fresh_combo` (16 khung) và `fresh_block` (8 khung) trên nền `#00FF00` giữ nguyên động tác đã duyệt ở Bước A, xử lý triệt để mọi khe hẹp giữa các lọn tóc, cổ tay giơ cao, chuôi kiếm và thân người.
   - Thực hiện tiếp 7 động tác còn lại (`fresh_dash` và 6 chiêu kỹ năng) trên nền `#00FF00`.
   - Lưu đầy đủ 9 bản gốc nền xanh tại `docs/ideas/sprites/round1/raw/fresh_<name>_green.png`.
2. **Tách nền duy nhất bằng `tools/sprites/key_out.py`:**
   - Chạy `python3 tools/sprites/key_out.py docs/ideas/sprites/round1/raw/fresh_<name>_green.png assets/characters/hero_rookie/anim/fresh_<name>.png` cho toàn bộ 9 sheet.
3. **Kiểm tra tự động bằng `tools/sprites/check_sheet.py --key 00ff00` & đối chiếu nền tối:**
   - Cả 9 sheet đều **ĐẠT** tuyệt đối cả 6 hạng mục (`grid`, `feet`, `size`, `clean`, `inside`, `key`) với `0` điểm rác (`stray`), `0` đốm rời (`specks`), `0` sương mờ (`haze`), `0` chạm mép (`edge`), `0 px` sót nền `#00ff00` (`key_left = 0`) và `0 px` viền ám xanh (`key_tint = 0`).
   - Đặt thử các khung có nhiều khe hẹp (tay giơ kiếm qua đầu, đỡ khiên, nhảy bổ từ trên cao) lên nền tối `#181A24` tại `docs/ideas/sprites/round1/dark_bg_check.png`: hoàn toàn sạch, không còn bất kỳ khe trắng hay viền xanh nào.

---

## Tổng hợp kết quả `check_sheet.py --key 00ff00` cho cả 9 sheet

| # | Sheet (`assets/characters/hero_rookie/anim/`) | Bản gốc nền xanh (`docs/ideas/sprites/round1/raw/`) | Khung | FPS | Kích thước | `grid` | `feet` (đầu / cuối) | `size` (f0 vs 394) | `clean` (stray / specks / haze) | `inside` | `key` (`#00ff00` left / tint) |
|---:|---|---|---:|---:|---|---|---|---|---|---|---|
| 1 | `fresh_combo.png` | `fresh_combo_green.png` | 16 | 24 | 2048×2048 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 2 | `fresh_block.png` | `fresh_block_green.png` | 8 | 24 | 2048×1024 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 3 | `fresh_dash.png` | `fresh_dash_green.png` | 6 | 24 | 2048×1024 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 4 | `fresh_skill_armor_breaker.png` | `fresh_skill_armor_breaker_green.png` | 14 | 24 | 2048×2048 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 5 | `fresh_skill_second_wind.png` | `fresh_skill_second_wind_green.png` | 14 | 12 | 2048×2048 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 6 | `fresh_skill_thunder_slash.png` | `fresh_skill_thunder_slash_green.png` | 14 | 24 | 2048×2048 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 7 | `fresh_skill_iron_guard.png` | `fresh_skill_iron_guard_green.png` | 10 | 12 | 2048×1536 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 8 | `fresh_skill_blade_vortex.png` | `fresh_skill_blade_vortex_green.png` | 16 | 24 | 2048×2048 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |
| 9 | `fresh_skill_starfall_strike.png` | `fresh_skill_starfall_strike_green.png` | 16 | 24 | 2048×2048 | **ĐẠT** | **ĐẠT** `(500.0, 256.0)` / `(500.0, 256.0)` | **ĐẠT** `394 px` | **ĐẠT** `0 / 0 / 0` | **ĐẠT** | **ĐẠT** `0 px / 0 px` |

---

## Chi tiết từng động tác

1. **`fresh_combo.png` (16 khung, 24 fps, impact: `4, 9, 14`):**
   - `0–2`: vung kiếm gỗ qua đầu lấy đà; `3`: bổ chéo xuống; `4`: **impact 1**; `5–6`: giữ thế thấp xoay cổ tay; `7–8`: chém hất ngược lên; `9`: **impact 2**; `10–12`: rút kiếm xoay vai nạp đà; `13`: lao người đâm thẳng; `14`: **impact 3**; `15`: thu về thế đứng chuẩn.
2. **`fresh_block.png` (8 khung, 24 fps):**
   - `0–1`: nâng khiên tròn trước ngực; `2`: khóa thế đỡ; `3–4`: bị đánh trúng khiên, dồn lực chịu đòn; `5–7`: hạ khiên về thế đứng chuẩn.
3. **`fresh_dash.png` (6 khung, 24 fps):**
   - `0`: khuỵu gối lấy đà; `1`: bật chân khỏi đất; `2–3`: lao vọt ngang trên không, thân chúi thấp, áo choàng bay ngang; `4–5`: đáp đất trượt nhẹ rồi đứng dậy về thế chuẩn.
4. **`fresh_skill_armor_breaker.png` (14 khung, 24 fps, impact: `9`):**
   - `0–3`: hai tay nắm chuôi kiếm vung cao qua đầu; `4–6`: nhảy bật lên giữ thế giơ kiếm ở đỉnh; `7–8`: bổ mạnh toàn thân từ trên xuống; `9`: **impact** cắm mũi kiếm xuống đất; `10`: giữ thế cắm kiếm; `11–13`: rút kiếm đứng dậy về thế chuẩn.
5. **`fresh_skill_second_wind.png` (14 khung, 12 fps):**
   - `0–2`: hạ một gối chống kiếm gỗ xuống đất; `3–5`: nhắm mắt hít sâu; `6–8`: ngẩng đầu thở mạnh hồi sức; `9–10`: mở mắt quyết tâm; `11–13`: đứng dậy nhấc kiếm về thế chuẩn.
6. **`fresh_skill_thunder_slash.png` (14 khung, 24 fps, impact: `8`):**
   - `0–4`: hạ thấp người kéo kiếm ra sau hông nạp thế; `5–6`: giữ thế nén lực; `7`: lao vọt tới chém ngang; `8`: **impact** đâm/chém ngang hết tầm; `9`: giữ thế vươn kiếm; `10–13`: thu kiếm xoay người về thế chuẩn.
7. **`fresh_skill_iron_guard.png` (10 khung, 12 fps):**
   - `0–2`: bước chân rộng, đưa khiên ra trước; `3–4`: dựng khiên lớn che kín thân; `5–7`: gồng giữ thế phòng thủ vững chắc; `8–9`: thu khiên về thế chuẩn.
8. **`fresh_skill_blade_vortex.png` (16 khung, 24 fps, impact: `4, 8, 12`):**
   - `0–2`: xoắn người lấy đà; `3–12`: xoay tròn 3 vòng liên tiếp vung kiếm ngang tầm ngực, áo choàng tung tròn (`impact` tại `4, 8, 12`); `13–15`: hãm đà xoay trở về thế chuẩn.
9. **`fresh_skill_starfall_strike.png` (16 khung, 24 fps, impact: `12`):**
   - `0–3`: khuỵu sâu tích lực; `4–6`: bật nhảy vọt lên cao, giơ kiếm qua đầu; `7–8`: lơ lửng ở đỉnh nhảy chuyển hướng mũi kiếm; `9–11`: lao thẳng từ trên cao xuống, mũi kiếm chúc đứng; `12`: **impact** cắm thẳng kiếm xuống đất; `13–15`: bật nhẹ và trở về thế đứng chuẩn.
