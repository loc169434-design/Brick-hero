# Issue #24 — sửa sau tích hợp

Tiếp tục nhánh `art/anim-moves`; đã merge main `17b6705`. Giữ metadata VRAM của main khi giải quyết xung đột import. So với main, chỉ đổi 18 PNG được yêu cầu cùng tài liệu/GIF mới; không sửa code, scene hoặc test. Không đưa lại bộ preview cũ không còn trên main.

## Ba sửa chữa

- **Orc throw:** chỉ frame **4–5**, cả fresh/bruised/battered. Tay phải duỗi ra phía trái, bàn tay mở vừa thả đá; đã nối phần cánh tay với vai. Frame 0–3 và 6–9 giữ nguyên từng pixel, điểm shield không đổi.
- **Mặt hiệp sĩ:** hurt frame 0–4 nghiến răng/nhắm mắt đau; knocked frame 0–4 mắt X và miệng méo/lưỡi thè. Frame 5–7 của hai clip giữ nguyên. Scared mọi frame có miệng há tròn, lông mày nhướn và mồ hôi; dizzy mọi frame có mắt xoáy, miệng mở/lưỡi thè. Có cả ba mức thương tích, giữ băng/vết bầm.
- **Drink:** frame 1–9 có động tác rút lọ, nâng lọ đỏ từ ảnh nguồn lên môi, ngửa đầu nhắm mắt uống ở 4–7 rồi cất lọ/lau miệng ở 8–9. Đã bỏ bàn tay mở dư phía sau lọ, dùng cùng phần lọ/tay nắm từ ảnh đứng uống thuốc. Frame 0, 10, 11 giữ nguyên.

Số khung, fps, impact và toàn bộ anim.json của hero/Orc không đổi. Kick/leap không nằm trong đợt sửa bắt buộc này. Không chỉnh các clip khác.

## GIF để đối chiếu

Mỗi ô có GIF động và lưới GIF đánh số, cạnh ảnh đứng yên cùng mức/clip. Không thêm PNG hoặc WebP review. Toàn bộ 36 GIF khoảng 8 MB, mỗi file dưới 2 MB; GIF động 192 px, lưới giữ ô 256 px để soi biểu cảm.

| Clip | Fresh | Bruised | Battered |
|---|---|---|---|
| orc_shield/throw | [Động](anim_fix_review/orc_shield_fresh_throw.gif) · [Lưới + ảnh nguồn](anim_fix_review/orc_shield_fresh_throw_compare.gif) | [Động](anim_fix_review/orc_shield_bruised_throw.gif) · [Lưới + ảnh nguồn](anim_fix_review/orc_shield_bruised_throw_compare.gif) | [Động](anim_fix_review/orc_shield_battered_throw.gif) · [Lưới + ảnh nguồn](anim_fix_review/orc_shield_battered_throw_compare.gif) |
| hero_rookie/hurt | [Động](anim_fix_review/hero_rookie_fresh_hurt.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_fresh_hurt_compare.gif) | [Động](anim_fix_review/hero_rookie_bruised_hurt.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_bruised_hurt_compare.gif) | [Động](anim_fix_review/hero_rookie_battered_hurt.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_battered_hurt_compare.gif) |
| hero_rookie/knocked | [Động](anim_fix_review/hero_rookie_fresh_knocked.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_fresh_knocked_compare.gif) | [Động](anim_fix_review/hero_rookie_bruised_knocked.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_bruised_knocked_compare.gif) | [Động](anim_fix_review/hero_rookie_battered_knocked.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_battered_knocked_compare.gif) |
| hero_rookie/scared | [Động](anim_fix_review/hero_rookie_fresh_scared.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_fresh_scared_compare.gif) | [Động](anim_fix_review/hero_rookie_bruised_scared.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_bruised_scared_compare.gif) | [Động](anim_fix_review/hero_rookie_battered_scared.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_battered_scared_compare.gif) |
| hero_rookie/dizzy | [Động](anim_fix_review/hero_rookie_fresh_dizzy.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_fresh_dizzy_compare.gif) | [Động](anim_fix_review/hero_rookie_bruised_dizzy.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_bruised_dizzy_compare.gif) | [Động](anim_fix_review/hero_rookie_battered_dizzy.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_battered_dizzy_compare.gif) |
| hero_rookie/drink | [Động](anim_fix_review/hero_rookie_fresh_drink.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_fresh_drink_compare.gif) | [Động](anim_fix_review/hero_rookie_bruised_drink.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_bruised_drink_compare.gif) | [Động](anim_fix_review/hero_rookie_battered_drink.gif) · [Lưới + ảnh nguồn](anim_fix_review/hero_rookie_battered_drink_compare.gif) |

## Xác minh

- [Hash từng frame trước/sau và danh sách frame giữ nguyên](anim_fix_review/pixel_checks.json), lấy bản trước sửa từ main để so.
- [Kết quả tổng hợp](anim_fix_review/validation.json): Godot import thành công; **78 passed, 0 failed**; nhịp GIF đã giải mã kiểm tra.
- Tất cả asset ngoài 18 PNG này và các file anim.json giữ như main. Các thay đổi mặt/tay/lọ được dựng offline từ ảnh nguồn bằng Pillow, không đổi mã game.

## Comment bàn giao để đăng vào #24

Đã sửa đủ ba điểm Claude yêu cầu trên `art/anim-moves`, sau khi kéo main mới: Orc throw 4–5 duỗi tay mở; mặt hurt/knocked/scared/dizzy đúng trạng thái; drink có lọ đỏ rõ ở môi và động tác cất/lau miệng. Có cả ba mức. Số khung/fps/impact và các khung không nhắc tới giữ nguyên. 36 GIF động/lưới cạnh ảnh nguồn tổng khoảng 8 MB, từng file <2 MB, không WebP. Godot: 78 đạt, 0 lỗi. [Bàn giao và GIF](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/issue24_fix_handoff.md).

## Trạng thái gửi

Đã push commit sửa `d92442f` lên `origin/art/anim-moves`. Comment #24 và lệnh mở PR sau push đều trả `Post "https://api.github.com/graphql": Forbidden`; chưa đăng comment hoặc tạo PR. Nội dung bàn giao đầy đủ được lưu ở đây theo phương án dự phòng trong yêu cầu.

### Comment đầy đủ kèm GIF

Đã sửa đủ 3 điểm phản hồi trên `art/anim-moves` sau khi merge main mới:

- Orc throw: chỉ frame 4–5 duỗi tay phải về trái, bàn tay mở.
- Hiệp sĩ hurt/knocked/scared/dizzy: bỏ nụ cười, đổi miệng và mắt đúng trạng thái.
- Drink: lọ đỏ rõ ở môi, nâng/ngửa đầu uống rồi cất lọ, lau miệng.

Áp dụng fresh/bruised/battered. Số khung, fps, impact, anim.json và các khung không nhắc tới giữ nguyên, có hash pixel đối chiếu main. 36 GIF tổng khoảng 8 MB, từng file <2 MB, không WebP; lưới cạnh ảnh nguồn tương ứng. Godot: 78 passed, 0 failed.

[Bàn giao và tất cả GIF](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/issue24_fix_handoff.md)

![Tay ném Orc](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/anim_fix_review/orc_shield_fresh_throw.gif?raw=true)

![Lọ thuốc](https://github.com/loc169434-design/Brick-hero/blob/art/anim-moves/docs/ideas/anim_fix_review/hero_rookie_fresh_drink.gif?raw=true)
