# Issue #24 — hoạt hình các đòn còn lại

Nhánh `art/anim-moves`, tạo từ `main` tại `8f07dfb`. Chỉ thay đổi `assets/` và `docs/ideas/`. Người dùng đã chọn dựng bằng Python/Pillow từ ảnh gốc để giữ chi tiết giữa các khung. Công cụ dựng offline ở [build_anim_moves.py](build_anim_moves.py); không phải code game.

## Đợt 1 — hiệp sĩ, fresh

Thêm 12 atlas: `throw`, `leap`, `kick`, `bash`, `drink`, `hurt`, `dizzy`, `knocked`, `scared`, `cheer`, `victory`, `defeat` vào `assets/characters/hero_rookie/anim/`. Mỗi file tên `fresh_<clip>.png`, RGBA, lưới 4 cột, ô 512×512; ô thừa trong suốt. `anim.json` bổ sung đúng số khung, fps, loop, impact của #24. Các clip và PNG có sẵn của #21 giữ nguyên.

- `throw`: từ frame 4 tay không; không có kiếm bay baked vào atlas. Theo quy định riêng của clip, khung cuối là thế thủ **tay không**, tương đương idle nhưng không thể khớp pixel với idle cầm kiếm. Cần code điều khiển việc trả kiếm; không sửa code trong nhánh này.
- `leap`: impact 10, kiếm nằm trong vệt quét ở 9–10, không còn bản lưỡi dựng ở vị trí cũ.
- `kick`: impact 3; `bash`: impact 4. Pha lấy đà, chạm, thu đòn tách biệt.
- Các clip không lặp còn lại kết thúc bằng đúng pixel `fresh_idle` frame 0; `defeat` giữ tư thế ngã. Không dùng di chuyển toàn thân để giả động tác tay/chân; game vẫn điều khiển đường lao/nhảy.

### GIF để duyệt

![Đá và phản ứng Orc](anim_moves_review/hero_rookie_kick_vs_orc_shield_hurt.gif)

![Húc khiên và phản ứng Orc](anim_moves_review/hero_rookie_bash_vs_orc_shield_hurt.gif)

![Nhảy đập và phản ứng Orc](anim_moves_review/hero_rookie_leap_vs_orc_shield_hurt.gif)

Mỗi clip có GIF đúng tốc độ trung bình, WebP lossless và ảnh lưới đánh số trên nền xanh đậm trong [anim_moves_review](anim_moves_review/). GIF lặp để dễ duyệt, độc lập với cờ loop trong game. Thời gian GIF lượng tử 10 ms được phân bổ 40/50 ms hoặc 80/90 ms; ba vòng nguồn loại sai lệch trung bình ở clip 8/10/16 khung. WebP lượng tử 1 ms.

### Kiểm tra

- [Đợt 1: kích thước, số khung, fps, impact, alpha, checksum từng khung, khung hồi](anim_moves_review/batch1_checks.json).
- [Bộ thử #21 giữ nguyên](anim_moves_review/pilot_preservation.json).
- [Timeline GIF ghép](anim_moves_review/batch1_timing.json): Orc bắt đầu hurt đúng frame impact của mỗi đòn.
- Đây là bàn giao ảnh để duyệt hình và nhịp; không tuyên bố đã tích hợp các đòn mới vào game.

### Comment đợt 1 để đăng vào #24

Đợt 1 hiệp sĩ fresh đã có trên nhánh `art/anim-moves`: 12 clip mới và metadata, giữ nguyên bộ thử #21. Kèm GIF từng clip, ảnh lưới đánh số và GIF ghép kick/bash/leap với Orc hurt đúng impact. [Bàn giao và GIF](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/issue24_handoff.md).

API GitHub đọc issue qua cả GraphQL và REST trả `Forbidden`; trang issue và Git HTTPS vẫn đọc được. Đợt 1 đã push commit `54bd992`; lệnh `gh issue comment 24 --body-file …` sau push trả `Post "https://api.github.com/graphql": Forbidden`. Comment chưa đăng; dùng nội dung bàn giao này theo phương án dự phòng trong #24.

## Đợt 2 — Orc, fresh

Thêm 9 clip được yêu cầu: `throw`, `charge`, `dodge`, `windup`, `scared`, `cheer`, `bald`, `victory`, `defeat`. Thêm luôn `fresh_attack` 12 khung / 24 fps / impact 6 làm bản gốc cho các mức bầm dập của đợt 3 (Orc trước đó mới có idle/hurt động; không thay clip attack nào có sẵn).

- Thân không có khiên baked. Mỗi frame có điểm `shield` tính từ đúng phép biến đổi nắm tay trái, kể cả chuyển động nghiêng thân; `bald` và `defeat` không có trường này.
- `throw`: đá chỉ có trong tay ở frame 0–3; frame 4 thả, code lo vật bay.
- `bald`: dùng ảnh gốc không mũ, hai tay ôm đầu; không chồng khiên.
- `idle` và `hurt` của #21 không đổi. Clip không lặp hồi về đúng pixel idle frame 0, trừ defeat.
- [Kiểm tra đợt 2](anim_moves_review/batch2_checks.json), [timeline charge/knocked](anim_moves_review/batch2_timing.json), [danh sách atlas](anim_moves_review/batch2_files.txt).

![Orc húc, hiệp sĩ bị đánh văng](anim_moves_review/orc_shield_charge_vs_hero_rookie_knocked.gif)

### Comment đợt 2 để đăng vào #24

Đợt 2 Orc fresh đã có trên `art/anim-moves`: throw/charge/dodge/windup/scared/cheer/bald/victory/defeat, thêm attack làm gốc cho mức bầm dập. Mỗi clip có GIF/WebP và lưới đánh số. Thân không có khiên, tọa độ shield theo tay từng frame; giữ nguyên idle/hurt đã duyệt. [GIF charge canh đúng frame 4 với hiệp sĩ knocked](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/anim_moves_review/orc_shield_charge_vs_hero_rookie_knocked.gif). [Bàn giao](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/issue24_handoff.md).

Đợt 2 đã push commit `d1052c8`. Comment sau push tiếp tục bị chặn: `Post "https://api.github.com/graphql": Forbidden`; nội dung ở trên chưa được đăng lên issue.

## Đợt 3 — bù nhìn và mọi mức thương tích

- Bù nhìn có `fresh_idle` (8 khung / 12 fps / lặp), `fresh_hurt` (8 khung / 24 fps), `anim.json`, cùng đầy đủ `bruised_` và `battered_`.
- Hiệp sĩ: đủ 14 clip × 3 mức = 42 atlas. Orc: đủ 12 clip × 3 mức = 36 atlas. Bù nhìn: 2 clip × 3 mức = 6 atlas. Tổng 84 atlas, trong đó 4 atlas fresh của bộ #21 giữ nguyên từng byte; 80 atlas mới.
- Đã xuất ưu tiên idle/attack/hurt trước, sau đó các clip còn lại. Mỗi biến thể dùng cùng timeline và các điểm xoay với fresh; vết bầm, băng trán, rách áo và kiếm sứt đi theo bộ phận. Kiếm battered ngắn/gãy, vệt kiếm leap cũng ngắn theo; bù nhìn battered mất tay rơm phải như ảnh đứng nguồn.
- `anim.json` dùng chung metadata clip cho cả ba mức theo loader có sẵn; không thêm tên clip giả `bruised_idle` vào dictionary.
- Tinh chỉnh thêm khung lau miệng của drink, biên kiếm lúc bắt đầu ngã defeat, và bước chân ăn mừng victory; các bản wear áp dụng cùng chỉnh sửa. Không đổi bất kỳ clip pilot nào.
- Thêm `.gdignore` cho thư mục review để Godot không import các bản GIF/lưới dùng duyệt. Các `.png.import` mới chỉ nằm trong assets.

### Xem và kiểm tra

- [Mục lục GIF và lưới của toàn bộ 84 atlas](anim_moves_review/README.md).
- [So tư thế giữa ba mức thương tích](anim_moves_review/wear_pose_comparison.png).
- [Danh sách atlas và preview](anim_moves_review/files.json).
- [Kiểm tra tất cả atlas: alpha, ô thừa, biên không cắt ảnh, frame/fps/impact, điểm shield, khung hồi và checksum](anim_moves_review/batch3_checks.json).
- [Thời lượng đọc lại từ 84 GIF và 84 WebP](anim_moves_review/preview_timing.json). Bản preview pilot giữ nguyên; mỗi file chứa một hoặc ba vòng nguồn. Các preview mới chứa ba vòng cho GIF, một vòng cho WebP. Tất cả đúng fps trung bình trong sai số lượng tử định dạng.
- [Xác nhận PNG và metadata clip pilot không đổi](anim_moves_review/pilot_preservation.json).
- [Godot import, smoke và kết quả suite](anim_moves_review/runtime_validation.json).

### Lưu ý tích hợp: test cũ về bù nhìn

Godot 4.7.2 import thành công; smoke test qua chính `CharacterRig` đã tải đủ 84 biến thể, chọn đúng file theo wear (không rơi về fresh), và truy cập được frame cuối. Main scene chạy headless 120 frame không báo script/resource error.

Suite hiện có: **60 passed, 1 failed**. `tests/test_character_clips.gd:76`, `test_no_anim_file_no_clips`, dùng `rig.setup("scarecrow", 1)` rồi đòi `has_clip("idle") == false` và `_clip == ""`. #24 yêu cầu bù nhìn có idle/hurt nên giả định này đã lỗi thời. Không sửa, tắt, bỏ qua hoặc thay test để báo xanh. Phần tích hợp code cần đổi fixture của test sang nhân vật thực sự chưa có anim (ví dụ blacksmith). Các kiểm tra tải/chọn 84 atlas mới đều đạt.

### Comment đợt 3 để đăng vào #24

Đợt 3 hoàn tất trên `art/anim-moves`: bù nhìn idle/hurt và đủ bruised/battered cho mọi clip hiệp sĩ, Orc, bù nhìn. Tổng 84 atlas / 3 nhân vật / 3 mức, giữ nguyên 4 atlas pilot. Có GIF, WebP và lưới đánh số cho từng biến thể. [Mục lục xem thử](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/anim_moves_review/README.md) · [So tư thế ba mức](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/anim_moves_review/wear_pose_comparison.png) · [Bàn giao](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/issue24_handoff.md).

Godot import, chọn wear và đọc frame cuối của cả 84 atlas đều đạt. Suite 60 đạt / 1 lỗi vì test cũ giả định bù nhìn chưa có anim; không sửa code/test theo phạm vi công việc. Chi tiết trong bàn giao.

Đợt 3 đã push commit `3e0a70b`. Sau push, `gh issue comment 24 --body-file …` tiếp tục trả `Post "https://api.github.com/graphql": Forbidden`. Lệnh mở PR từ `art/anim-moves` vào `main` theo AGENTS.md cũng trả cùng lỗi. **Chưa tạo được comment nào của ba đợt và chưa tạo PR**; nội dung comment từng đợt đã lưu đầy đủ ở file này theo phương án dự phòng của issue #24. Git push cả ba đợt thành công; không merge, không sửa code game hoặc test.
