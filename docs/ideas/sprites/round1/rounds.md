# Báo cáo kiểm tra Bước A — Đợt 1 (`fresh_combo` & `fresh_block`)

Nhánh: `art/hero-moves-1` (tạo từ `origin/core/world-life`).
Tham chiếu chuẩn: `assets/characters/hero_rookie/anim/fresh_idle.png` (khung 0 cao `394 px`, chân tại `(254.5, 500.0)`).

---

## Vòng 1 — Bản vẽ thô đầu tiên & đóng gói thử

- **Phát hiện qua kiểm tra mắt:**
  - `fresh_block` (bản nháp v2): Khung 1–4 bị đảo bên tay cầm khiên/kiếm (khiên nhảy sang phải, kiếm sang trái), khung 3 mất kiếm sau lưng, khung 5–6 trùng tư thế đứng với khung 7.
  - `fresh_combo` (bản nháp v2): Khung 1 bị vẽ thừa khiên ở cả hai tay; khung 7–9 mũi kiếm chém ngược về bên trái qua đầu thay vì chém hất lên về phía quái bên phải.
- **Xử lý:** Yêu cầu vẽ lại sheet `fresh_block` (v4) và `fresh_combo` (v3) giữ đúng thiết kế nhân vật Tân binh, mặt quay sang phải, khiên tròn gỗ viền sắt và kiếm gỗ đúng tay, đòn đánh hướng về phía phải, không vẽ vệt chém/bụi/bóng đất.
- **Số đo đóng gói Vòng 1 (`check_sheet.py`):**
  - `fresh_combo.png` (2048×2048, 16 khung, 24 fps): `grid` ĐẠT, `feet` ĐẠT (`(500.0, 256.0)` đầu/cuối), `size` ĐẠT (`394 px` vs `394 px`), `clean` ĐẠT (`0 stray, 0 specks, 0 haze`), `inside` ĐẠT (`none`). Tuy nhiên khe giữa hai chân ở các khung 2, 5, 7, 13, 14 còn sót mảng trắng kín chưa tách nền và thứ tự thu kiếm khung 10–12 chưa mượt.
  - `fresh_block.png` (2048×1024, 8 khung, 24 fps): `grid` ĐẠT, `feet` ĐẠT (`(500.0, 256.5)` và `(500.0, 255.5)`), `size` ĐẠT (`385 px` vs `394 px`, lệch `-2.3%`), `clean` ĐẠT (`0 stray, 0 specks, 0 haze`), `inside` ĐẠT (`none`).

---

## Vòng 2 — Xử lý tách nền vùng kín giữa hai chân & chuẩn hóa chiều cao khung đầu/cuối

- **Cải tiến:**
  - Bổ sung bộ lọc tách nền cho các vùng trắng/xám sáng khép kín bên dưới vùng đầu (`rel_y_max >= 0.43`, loại trừ mắt và răng) để làm trong suốt hoàn toàn khe giữa hai chân/ủng ở các khung `2, 5, 7, 13, 14` của `fresh_combo` và khe giữa kiếm/khiên ở khung `2, 3, 4` của `fresh_block`.
  - Sắp xếp lại nhịp thu kiếm xoay vai ở khung `10 -> 11 -> 12` của `fresh_combo` theo đúng đường đi của tay cầm kiếm: rút kiếm ra sau vai (`10`) -> hạ thấp về sau hông (`11`) -> gập khuỷu tay nạp kiếm ngang vai (`12`) trước khi đâm thẳng tới (`13–14`).
  - Chuẩn hóa chiều cao khung 0 và khung cuối của cả hai sheet khớp tuyệt đối `394 px` với `fresh_idle` khung 0.
- **Phát hiện qua kiểm tra mắt:**
  - Ở `fresh_combo` khung 13–14, thu nhỏ chiều cao xuống `344–346 px` làm cỡ đầu hơi nhỏ hơn một chút so với khung 12 (`364 px`).

---

## Vòng 3 (Chốt bàn giao) — Cân chỉnh tỉ lệ đầu/thân khung đâm kiếm & độ mượt tổng thể

- **Cải tiến:**
  - Nâng chiều cao khung `13–14` của `fresh_combo` lên `356 px` và `360 px` để cỡ đầu và thân khi chùng chân đâm thẳng khớp đồng nhất với các khung chém chéo (`358 px` ở khung 4) và khung nạp đà (`366 px` ở khung 12), đồng thời mũi kiếm vẫn nằm gọn trong khung 512×512 (`edge = 0`) và chân không trôi quá giới hạn (`x = 242.0` và `231.0`, lệch tối đa `25 px <= 40 px` so với `x = 256`).
- **Kết quả chạy `tools/sprites/check_sheet.py`:**

### 1. `fresh_combo.png` (`--frames 16 --fps 24`)
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 394 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
=> ĐẠT
```

| Khung | Nhịp diễn (`impact`: 4, 9, 14) | Chân `(y, x)` | Cao (`px`) | Stray | Specks | Edge |
|---:|---|---:|---:|---:|---:|---:|
| 0 | Thủ thế chuẩn (`fresh_idle` f0) | `(500.0, 256.0)` | 394 | 0 | 0 | 0 |
| 1 | Nhích người tới, hạ nhẹ gối | `(500.0, 258.5)` | 386 | 0 | 0 | 0 |
| 2 | Vung kiếm gỗ cao qua đầu lấy đà | `(500.0, 257.0)` | 432 | 0 | 0 | 0 |
| 3 | Bắt đầu bổ chéo từ trên xuống | `(500.0, 259.0)` | 376 | 0 | 0 | 0 |
| 4 | **Impact 1:** Chém chéo xuống hết tầm | `(500.0, 262.0)` | 358 | 0 | 0 | 0 |
| 5 | Theo đà thấp, xoay cổ tay | `(500.0, 259.5)` | 356 | 0 | 0 | 0 |
| 6 | Hạ thấp trọng tâm, nạp đà cổ tay | `(500.0, 258.0)` | 340 | 0 | 0 | 0 |
| 7 | Đứng lên bắt đầu vớt kiếm lên | `(500.0, 258.5)` | 364 | 0 | 0 | 0 |
| 8 | Chém hất ngược lên ngang ngực | `(500.0, 260.0)` | 398 | 0 | 0 | 0 |
| 9 | **Impact 2:** Đỉnh nhát chém hất ngược lên | `(500.0, 262.5)` | 420 | 0 | 0 | 0 |
| 10 | Rút kiếm ra sau vai | `(500.0, 255.5)` | 384 | 0 | 0 | 0 |
| 11 | Xoay vai, kéo kiếm về sau hông | `(500.0, 253.0)` | 374 | 0 | 0 | 0 |
| 12 | Gập khuỷu tay nạp kiếm ngang vai | `(500.0, 250.5)` | 366 | 0 | 0 | 0 |
| 13 | Lao người đâm thẳng kiếm tới trước | `(500.0, 242.0)` | 356 | 0 | 0 | 0 |
| 14 | **Impact 3:** Đâm thẳng hết tầm, gầm chiến đấu | `(500.0, 231.0)` | 360 | 0 | 0 | 0 |
| 15 | Thu kiếm về thủ thế chuẩn | `(500.0, 256.0)` | 394 | 0 | 0 | 0 |

### 2. `fresh_block.png` (`--frames 8 --fps 24`)
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 394 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
=> ĐẠT
```

| Khung | Nhịp diễn | Chân `(y, x)` | Cao (`px`) | Stray | Specks | Edge |
|---:|---|---:|---:|---:|---:|---:|
| 0 | Thủ thế chuẩn (`fresh_idle` f0) | `(500.0, 256.0)` | 394 | 0 | 0 | 0 |
| 1 | Khom người, bắt đầu nâng khiên | `(500.0, 255.5)` | 389 | 0 | 0 | 0 |
| 2 | Giơ khiên che trước ngực, mắt nhìn tới | `(500.0, 253.0)` | 379 | 0 | 0 | 0 |
| 3 | Bị đánh trúng khiên: giật lùi nửa bước, nhăn mặt | `(500.0, 247.0)` | 375 | 0 | 0 | 0 |
| 4 | Giữ thế đỡ chịu lực, nhăn mặt nghiến răng | `(500.0, 245.0)` | 371 | 0 | 0 | 0 |
| 5 | Bắt đầu hạ khiên, mở mắt quyết tâm | `(500.0, 250.0)` | 381 | 0 | 0 | 0 |
| 6 | Đứng thẳng dần, đưa khiên và kiếm về vị trí | `(500.0, 254.0)` | 388 | 0 | 0 | 0 |
| 7 | Về thủ thế chuẩn | `(500.0, 256.5)` | 394 | 0 | 0 | 0 |
