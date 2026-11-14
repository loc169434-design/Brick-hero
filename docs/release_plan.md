# Kế hoạch lên store – Brickbound Hero

Claude viết ngày 14/11/2026, sau khi kéo code mới về (`1487b37`): 167 test qua, test lò rèn qua.

## 1. Hiện trạng

**Đã có, chơi được:**
- Lõi nối ô, ô đặc biệt, hợp thể, dây chuyền.
- Trận đánh theo lượt, tuyệt chiêu, vật phẩm, thời tiết.
- Bản đồ, lò rèn, truyện tranh 3 chương.
- **36 màn**: mở đầu, hồi 1 Trại Orc, hồi 2 Đầm lầy (màn 1–36 của [campaign_100.md](campaign_100.md)).
- Hiệp sĩ đủ **6 bộ đồ**, mỗi bộ 24–25 động tác, mỗi bộ một chiêu riêng.
- Quái hồi 0–2 vẽ lại nhiều khung.

**Chưa có, chặn việc lên store:**

| # | Vấn đề | Mức |
|---|---|---|
| 1 | **Quá nặng.** Ảnh nén cho điện thoại khoảng **1,2 GB**; Google Play chỉ nhận gói tải về tối đa **200 MB**. Riêng hiệp sĩ 630 MB. | Chặn |
| 2 | Chưa có cấu hình xuất Android và iOS, chưa có khóa ký app. | Chặn |
| 3 | Biểu tượng app vẫn là logo Godot mặc định; chưa có màn hình khởi động. | Chặn |
| 4 | Chưa xử lý nút Back của Android, chưa lưu khi app bị ẩn, chưa tránh tai thỏ (notch). | Chặn |
| 5 | Âm thanh là tiếng tổng hợp tạm bằng code, chưa có nhạc. | Nên có |
| 6 | Chưa có màn hình Cài đặt (âm thanh, nhạc, rung). | Nên có |
| 7 | Hết màn 36 thì chưa có gì báo "còn tiếp". Bộ Hoàng Gia, Hắc Thép, Băng mở sau màn 45/65/85, tức là chưa mua được. | Nên có |
| 8 | Chưa chạy thử trên điện thoại thật (độ mượt, bộ nhớ, thời gian tải). | Chặn |
| 9 | Chưa có trang chính sách riêng tư, ảnh và chữ cho trang store. | Chặn |

**Đo dung lượng**, thử trên 1 sheet 2048×2048 của hiệp sĩ:

| Cách nén | Dung lượng | Trên máy |
|---|---|---|
| Hiện tại (VRAM, mỗi điểm ảnh 1 byte) | 4,2 MB | nhẹ bộ nhớ, nặng file |
| **Basis Universal** | **1,15 MB** (−73%) | vẫn nén VRAM, nhẹ bộ nhớ |
| WebP mất mát | 0,18 MB | file rất nhẹ, nhưng tốn bộ nhớ (16 MB mỗi sheet) |

Basis Universal + khung 384 (thay 512) thì cả game khoảng **1230 × 0,27 × 0,56 ≈ 190 MB**, sát mức trần. Nên thêm: WebP cho ảnh tĩnh lớn (nền, truyện, bản đồ) và bỏ 2 mức bầm dập của Tân binh. Mục tiêu dưới **150 MB**.

## 2. Cách phát hành: ra từng phần

Làm đủ 100 màn còn khoảng 64 màn, 35 quái mới, công chúa chơi được, 4 bộ gạch, 4 nền và 4 chương truyện. Đợi xong hết mới lên store thì quá lâu. Đề xuất:

1. **Bản thử kín** (màn 1–36) lên Google Play (closed testing) và TestFlight càng sớm càng tốt.
   - Tài khoản Google Play cá nhân mới phải có **12 người thử trong 14 ngày** mới được phát hành công khai, nên phải bắt đầu đồng hồ này sớm.
2. Trong lúc thử kín, làm tiếp **hồi 3 Rừng đen** (màn 37–58).
3. **Ra mắt công khai với màn 1–58**, kết thúc ở cú lật của ba mụ phù thủy, kèm thông báo "còn tiếp".
4. Hồi 4, 5, 6 ra dần thành các bản cập nhật.

## 3. Việc cần làm

### Giai đoạn A: bản thử kín (màn 1–36)

| Việc | Ai | Ghi chú |
|---|---|---|
| A1 Giảm dung lượng: khung 384, Basis Universal, WebP cho ảnh tĩnh, bỏ ảnh không dùng; đo bản xuất thật | Claude | Mục tiêu dưới 150 MB |
| A2 Cấu hình xuất Android (AAB, arm64, Android 7+) và iOS | Claude | Bạn tự tạo khóa ký và tài khoản nhà phát triển |
| A3 Nút Back, lưu khi app bị ẩn, vùng an toàn tai thỏ, màn tạm dừng | Claude | |
| A4 Màn hình Cài đặt: âm thanh, nhạc, rung, xóa dữ liệu chơi | Claude | |
| A5 Cuối màn 36: chương "còn tiếp"; bộ đồ chưa mở hiện "sắp có" | Claude | |
| A6 Bot chơi hết 36 màn, kiểm lỗi, cân lại vàng và độ khó | Claude | `tests/sim_balance.gd` |
| A7 Biểu tượng app, màn khởi động, ảnh và chữ trang store | ChatGPT | [store_art_request.md](ideas/store_art_request.md) |
| A8 Âm thanh và nhạc thật | Bạn chọn nguồn | Xem mục 4 |
| A9 Chính sách riêng tư (game không thu dữ liệu), xếp hạng tuổi, mục An toàn dữ liệu | Bạn, Claude viết sẵn chữ | |
| A10 Chạy thử trên điện thoại thật, đo bộ nhớ và độ mượt | Bạn cài, Claude đọc log | |

### Giai đoạn B: hồi 3 Rừng đen (màn 37–58)

| Việc | Ai |
|---|---|
| Chế độ tay không, ô gai, kẹo, lửa, khóa màu, quái tách đôi, trùm nhập ba, ô chiêu thứ hai | Claude |
| Dữ liệu màn 37–58, nút bản đồ đoạn 3 | Claude |
| 5 quái thường + 4 phù thủy, bộ gạch rừng đen/kẹo, nền nhà bánh, truyện chương 4–5 | ChatGPT |
| Hiệp sĩ tay không (đủ clip, không giáp, không kiếm) | Gemini |

### Giai đoạn C: ra mắt công khai

Ảnh chụp màn hình mới, video ngắn, mở hồ sơ phát hành sau 14 ngày thử kín.

## 4. Cần bạn chốt

1. **Tên gói app** (không đổi được sau khi lên store), ví dụ `com.<tên-bạn>.brickboundhero`.
2. **Kiếm tiền:**
   - (a) miễn phí hoàn toàn;
   - (b) trả tiền một lần;
   - (c) miễn phí, có quảng cáo xem để nhận thưởng.

   Kế hoạch 100 màn đã chốt "không có gì phải trả tiền mới qua được"; cả ba cách đều giữ được điều đó.
3. **Ngôn ngữ:** chỉ tiếng Việt, hay thêm tiếng Anh ngay từ bản đầu (thêm khoảng 1 tuần code + dịch).
4. **Âm thanh:**
   - (a) gói âm thanh miễn phí bản quyền CC0, ví dụ Kenney;
   - (b) mua gói trên itch.io hoặc Unity Asset Store;
   - (c) thuê người làm.

   Hai AI vẽ không làm được âm thanh.
