# Issue #41 — sửa lỗi cắt ô sau khi duyệt G2

Tiếp sau `10ccc4c`, trên `art/campaign-100-g2`. Người dùng đã duyệt truyện chương 1–3 V2; đợt sửa này chỉ xử lý atlas và kiểm tra ảnh.

## Cá Sấu và Mụ Cóc

Nguồn cá sấu có bốn cột nhưng các hàng không cách đều. Chia chiều cao thành tám phần bằng nhau đã cắt mất chân/đuôi ở đáy hình, rồi lấy lẫn phần chân/đuôi hàng trước vào đầu ô sau. Đã đo lại **32 hộp cắt cho đủ sáu clip**, lấy toàn bộ hình vẽ nguyên vẹn, co đồng đều và đăng ký chân tại `(256,500)`. Cập nhật atlas, ảnh đứng và anchor theo hình mới; giữ nguyên số khung, fps và impact.

`toad_witch` attack 2–3 dùng hộp cắt riêng cho hình nguồn 6–7: giữ đủ gậy và áo, loại phần gậy của cột bên cạnh. Bốn ô attack còn lại và năm clip còn lại giữ nguyên từng pixel. Kiểm tra hai ô đã sửa không còn đảo alpha nhìn thấy lớn hơn hai pixel.

GIF cập nhật, tất cả dưới 2 MB:

- Cá Sấu: [idle](campaign_g2_review/crocodile_idle.gif), [attack](campaign_g2_review/crocodile_attack.gif), [hurt](campaign_g2_review/crocodile_hurt.gif), [special](campaign_g2_review/crocodile_special.gif), [defeat](campaign_g2_review/crocodile_defeat.gif), [victory](campaign_g2_review/crocodile_victory.gif).
- [Mụ Cóc attack](campaign_g2_review/toad_witch_attack.gif).

Gallery có sẵn được tái xuất theo atlas mới để không giữ ảnh xem thử lỗi cũ. Không thêm nguồn PNG lớn vào repo. Nguồn gốc giữ nguyên SHA-256; hộp cắt được lưu trong `campaign_g2_sources.json` để lần xuất sau không khôi phục lỗi.

## Luật “mỗi ô phần hình liền một khối”

`check_campaign_g2.py` gọi `check_issue41_contiguity.py` trên **toàn bộ 340 ô / 65 clip / 12 dạng nhân vật G2**. Luật dùng liên thông tám hướng, alpha từ 32/255 để bỏ fringe rất mờ do resample. Ngoài khối thân chính, **mảnh rời lớn hơn 200 pixel phải báo lỗi**. Hạt nhỏ/đường tia được phép; riêng hai ô attack Mụ Cóc có kiểm tra chấm lạc chặt hơn như trên.

Hiệu ứng vẽ có chủ đích như tên/bom bay, khói tím, giọt độc, tia cười và vòng choáng được đối chiếu bằng ảnh, rồi ghi trong `issue41_intentional_fx.json`: lý do, diện tích, hộp bao và SHA-256 của **từng mask thành phần**. Có 174 thành phần hiệu ứng ở 67 ô. Không miễn trừ cả nhân vật, cả clip hoặc cả ô. Mảnh chân/đuôi mới phát sinh không trùng mask hiệu ứng sẽ bị từ chối; ngoại lệ không còn khớp cũng làm kiểm tra thất bại.

Luật mới còn phát hiện cùng lỗi lẫn ô ở Cóc Phun Độc và bốn ô riêng lẻ. Đã cắt lại đúng nguồn, không vẽ lại hay ghép bộ phận:

- `toad_spitter`: đo lại các khoảng trống giữa tám hàng và giữ đủ luồng độc ở special 5, xuất lại sáu clip và ảnh đứng.
- `goblin_bomber` special 4: bỏ phần bom của ô bên cạnh ở mép phải.
- `swamp_spider` special 4: bỏ nét của ô bên cạnh ở mép phải.
- `fairy_fickle` wave 1: bỏ mảnh đũa của ô bên cạnh ở mép phải.
- `toad_witch_giant` defeat 5: lấy đủ dáng mụ chạy, bỏ nét sát đáy thuộc ô kế tiếp; đồng bộ ảnh `defeat.png`.

Với năm actor chỉ sửa ô riêng lẻ (gồm Mụ Cóc), đã đối chiếu rằng các hình nguồn ngoài danh sách override không đổi sau đăng ký. Không sửa truyện, code game, lịch màn hay chỉ số chiến đấu.

## Bằng chứng kiểm tra

- [Kiểm liên thông](campaign_g2_review/contiguity_validation.json): **340 ô đạt**, không có mảnh lớn chưa được đối chiếu. Cùng luật từ chối đủ **18 ô cá sấu lỗi thật ở `10ccc4c`**: attack 1–4, hurt 1–2, special 1–6, defeat 0–5. Dùng ảnh cũ từ Git làm fixture, không chép PNG lỗi vào repo.
- [Kiểm G2](campaign_g2_review/validation.json): **1.163 điều kiện đạt**, gồm inventory, alpha, số khung, overlap bản đồ, preview và luật mới.
- Godot 4.7.2 import không có lỗi; smoke tải 65 clip, 48 atlas gạch, bốn SpriteFrames, 14 texture nền/ambient, bảy panel chương 3: **0 failures**.
- Suite hiện có: **93 passed, 0 failed**. Log smoke và suite trong gallery G2 được chạy lại sau sửa.

Tái xuất và kiểm tra (Python cần Pillow, NumPy, SciPy):

```sh
python docs/ideas/repair_issue41_atlas.py
python docs/ideas/check_issue41_contiguity.py
python docs/ideas/check_campaign_g2.py
```

`pack_campaign_g2.py` cũng đọc các hộp cắt đo lại khi xuất nhóm `priority`, `characters`, `npcs`. Các script chỉ cắt hình nguyên vẹn, co đồng đều, đăng ký và đóng atlas; không xóa mask bằng code, không dựng tư thế hay vá chân/đuôi bằng code.
