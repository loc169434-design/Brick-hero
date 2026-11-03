# Issue #21 — sửa vệt kiếm frame 4–5

Theo [comment duyệt và yêu cầu sửa](https://github.com/loc169434-design/Brick-hero/issues/21#issuecomment-6600276527), tiếp tục trên `art/anim-pilot`.

- Chỉ thay frame 4–5 (đánh số từ 0) của `assets/characters/hero_rookie/anim/fresh_attack.png`.
- Bỏ lưỡi kiếm thẳng đứng. Lưỡi nằm trong vệt cong trắng-vàng từ trên-sau xuống trước, nối vào chuôi ở tay cầm. Frame 5 dài hơn frame 4.
- Mười frame còn lại giữ nguyên từng pixel; tất cả anim.json giữ nguyên từng byte. Vùng mặt có sẵn, khiên và chân được đối chiếu pixel.
- Atlas vẫn 2048×1536, 12 frame 512×512, RGBA 8-bit, nền trong suốt.

## Review

- [Phóng to 2× frame 3–6 trên nền xanh đậm](hero_attack_frames_03_06_zoom.png).
- [GIF chém mới, 24 fps, mỗi vòng 500 ms](hero_attack.gif).
- [WebP lossless](hero_attack.webp).
- [So sánh trước/sau frame 4–5](hero_attack_smear_before_after.png).
- [GIF ghép đòn chém/phản ứng đã cập nhật](attack_vs_hurt.gif).
- [Kết quả đối chiếu pixel](smear_revision_checks.json).

## Đăng issue

Đang chờ kết quả gửi comment sau khi push.
