# Yêu cầu cho ChatGPT: hoạt ảnh hiệp sĩ đổi theo giáp, kiếm gắn rời

Claude viết. Bỏ rig xương, quay về hoạt ảnh vẽ từng khung (`assets/characters/hero_rookie/anim/`, 15 clip, 156 khung, lưới 4 cột, khung 512×512, chân tại (256, 500)).

- **Giáp:** mua giáp nào thì hiệp sĩ mặc đúng bộ đó. Mỗi bộ giáp có một bộ khung riêng trong `anim/<giáp>/`.
- **Kiếm:** không vẽ vào khung nữa. Game tự gắn icon kiếm đang dùng vào nắm tay ở từng khung.
- **Nón, ủng:** chỉ cộng chỉ số, không hiện trên người.

Code đã xong (`CharacterRig.set_outfit`). Giờ chỉ cần ảnh. Làm **hai đợt**. Xong mỗi đợt thì push rồi **dừng chờ duyệt**, không tự làm tiếp.

Quy tắc chung: chỉ sửa `assets/characters/hero_rookie/anim/` và `docs/ideas/hero_sprites_gear/`. Không sửa `scripts/`, `scenes/`, `tests/`, các file `.import`. Không force push.

## Đợt 1: xóa kiếm khỏi mọi khung (nhánh `art/hero-swordless`)

Với **mọi** sheet trong `anim/*.png` (fresh_, bruised_, battered_, mọi clip). **Trừ** thư mục `anim/broom/`: chổi là đạo cụ riêng, giữ nguyên.

1. Xóa cây kiếm (gỗ, kể cả mảnh gãy ở bản battered): lưỡi, đốc chắn, quả chuôi.
2. Chỗ kiếm từng đè lên người thì vẽ lại phần người bên dưới, khớp nét và màu xung quanh. Chỗ kiếm nằm trên nền thì để trong suốt.
3. **Giữ nguyên nắm tay**, vẫn nắm chặt như đang cầm chuôi. Game sẽ đặt chuôi kiếm vào đúng giữa nắm tay đó.
4. Mọi điểm ảnh khác giữ y nguyên: cùng kích thước sheet, cùng lưới, cùng vị trí.

Ghi đè đúng tên file cũ, để file `.import` giữ nguyên.

**Tự kiểm tra** (`docs/ideas/hero_sprites_gear/check_swordless.py`, tối đa 5 vòng, ghi `rounds_swordless.md`):

- Kích thước mỗi sheet giữ nguyên.
- Ngoài vùng kiếm cũ nới 4 px (tự tô mask kiếm cho từng khung, lưu `masks/<sheet>.png`), sai khác so với bản gốc trên `origin/core/world-life` ≤ 6/255.
- Chạy `python3 tools/sword_track.py <bản gốc> <bản mới> <số khung>` cho từng sheet. Khung nào bản gốc có kiếm thì phải ra một bộ số (không `null`). Khung nào không có kiếm thì phải ra `null`. Lưu toàn bộ vào `sword_tracks.json` dạng `{"fresh_attack": [...], ...}`.
- **Ảnh duyệt** `preview_<clip>.png`: lấy khung mới, vẽ lại icon `iron_sword` theo track vừa tính. Cầm như game: điểm cầm (127, 200) trên icon, thu phóng 210/256, xoay đúng số độ của track, đặt sau thân nếu `front` = 0, trước thân nếu `front` = 1. Kiếm phải nằm gọn trong nắm tay ở mọi khung. Kèm một ảnh nhỏ đặt khung cũ cạnh khung mới để so.

## Đợt 2: bộ khung theo giáp (nhánh `art/hero-armor-sets`, làm sau khi đợt 1 được duyệt)

Năm bộ giáp, mỗi bộ vẽ lại trên **bản không kiếm của đợt 1, chỉ bản `fresh_`** (bộ giáp không có bản bầm dập):

| Thư mục | Giáp | Kiểu dáng |
|---|---|---|
| `anim/leather_armor/` | Giáp da | Áo giáp da nâu, đường khâu, vai da |
| `anim/iron_armor/` | Giáp sắt | Giáp xám bạc, đinh tán |
| `anim/royal_armor/` | Giáp Hoàng Gia | Xanh hoàng gia, viền vàng |
| `anim/obsidian_armor/` | Giáp Hắc Thép | Đen ánh tím, cạnh sắc |
| `anim/frost_armor/` | Giáp Băng | Xanh băng nhạt, hoa văn tuyết |

Màu và kiểu theo icon trong `assets/ui/items/<giáp>.png`, và theo giáp đã vẽ ở `assets/characters/hero_rig/gear/<giáp>/` để thống nhất.

- **Chỉ vẽ lại áo, vai và vạt áo.** Đầu, mặt, tóc, tay trần, nắm tay, quần, ủng, khiên và khăn giữ y nguyên từng điểm ảnh. Như vậy kiếm vẫn gắn đúng tay, mặt vẫn đồng bộ.
- Mỗi thư mục có đủ 15 file `fresh_<clip>.png`, cùng kích thước và lưới như bản gốc. Mỗi thư mục có một `anim.json` chép từ `anim/anim.json`; Claude sẽ tự thêm track kiếm vào sau.
- **Làm `leather_armor` trước, push, dừng chờ duyệt.** Duyệt xong mới làm bốn bộ còn lại.

**Tự kiểm tra** (`check_armor.py`):

- Mỗi khung: hình bóng (alpha ≥ 128) trùng bản không kiếm ≥ 92% (IoU). Giáp có thể phồng ra một chút.
- Vùng đầu, cổ, nắm tay, quần dưới đầu gối, ủng và khiên lệch ≤ 6/255 so với bản không kiếm. Tự tô mask "vùng được sửa" cho từng khung và lưu lại.
- Giáp trông giống nhau giữa các khung: cùng chi tiết, cùng màu. Không được khung có đinh tán, khung không.
- Ảnh duyệt `armor_<giáp>_<clip>.png`: khung giáp có kiếm sắt gắn theo track của đợt 1, đặt cạnh khung áo thường.

## Bàn giao mỗi đợt

Ảnh duyệt, `check.json`, `rounds_*.md` trong `docs/ideas/hero_sprites_gear/`. Commit, push đúng nhánh, báo số đo, rồi **dừng chờ duyệt**.
