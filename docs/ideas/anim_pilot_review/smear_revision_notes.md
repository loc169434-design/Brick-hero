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

Đã push commit `5644e6b` lên `origin/art/anim-pilot`. Lệnh `gh issue comment 21 --repo loc169434-design/Brick-hero --body-file …` thất bại: `Post "https://api.github.com/graphql": Forbidden`. Comment chưa được đăng. Nội dung sẵn để đăng thủ công ở dưới.

### Nội dung comment

Đã sửa tiếp trên `art/anim-pilot` theo yêu cầu duyệt:

- Chỉ đổi frame 4–5 của `hero_rookie/anim/fresh_attack.png`: bỏ kiếm dựng đứng, đưa lưỡi vào vệt cong từ trên-sau xuống trước; chuôi và tay ở đầu vệt.
- Mười frame khác giữ nguyên từng pixel; tất cả `anim.json` giữ nguyên từng byte.
- Đã xuất lại GIF 24 fps (500 ms/vòng), WebP và bản ghép phản ứng.

[Ảnh phóng to frame 3–6](https://github.com/loc169434-design/Brick-hero/blob/art/anim-pilot/docs/ideas/anim_pilot_review/hero_attack_frames_03_06_zoom.png) · [GIF mới](https://github.com/loc169434-design/Brick-hero/blob/art/anim-pilot/docs/ideas/anim_pilot_review/hero_attack.gif) · [Đối chiếu pixel](https://github.com/loc169434-design/Brick-hero/blob/art/anim-pilot/docs/ideas/anim_pilot_review/smear_revision_checks.json)

![Frame 3–6](https://github.com/loc169434-design/Brick-hero/blob/art/anim-pilot/docs/ideas/anim_pilot_review/hero_attack_frames_03_06_zoom.png?raw=true)

![GIF chém mới](https://github.com/loc169434-design/Brick-hero/blob/art/anim-pilot/docs/ideas/anim_pilot_review/hero_attack.gif?raw=true)

