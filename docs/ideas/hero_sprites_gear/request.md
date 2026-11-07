# Yêu cầu cho ChatGPT: hoạt ảnh hiệp sĩ đổi theo giáp, kiếm gắn rời

Claude viết. Bỏ rig xương, quay về hoạt ảnh vẽ từng khung (`assets/characters/hero_rookie/anim/`, 15 clip, 156 khung, lưới 4 cột, khung 512×512, chân tại (256, 500)).

- **Bộ giáp là một bộ trang phục trọn gói:** nón, áo giáp, khiên và giày vẽ đồng bộ. Mua bộ nào thì cả người đổi theo bộ đó. Mỗi bộ có một bộ khung riêng trong `anim/<giáp>/`.
- **Kiếm:** không vẽ vào khung nữa. Game tự gắn icon kiếm đang dùng vào nắm tay ở từng khung.

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

Năm bộ trang phục, mỗi bộ vẽ lại trên **bản không kiếm của đợt 1, chỉ bản `fresh_`** (bộ giáp không có bản bầm dập). Mỗi bộ gồm **nón + áo giáp + khiên + giày**, cùng chất liệu, cùng màu:

| Thư mục | Bộ | Nón | Áo giáp | Khiên | Giày |
|---|---|---|---|---|---|
| `anim/leather_armor/` | Da | Mũ da ôm đầu, đường khâu | Áo da nâu, vai da | Khiên gỗ bọc da | Ủng da cổ cao |
| `anim/iron_armor/` | Sắt | Mũ sắt tròn có vành | Giáp xám bạc, đinh tán | Khiên tròn viền sắt | Ủng bọc sắt |
| `anim/royal_armor/` | Hoàng Gia | Mũ xanh viền vàng, chóp nhỏ | Xanh hoàng gia, viền vàng | Khiên xanh, huy hiệu vàng | Ủng xanh, viền vàng |
| `anim/obsidian_armor/` | Hắc Thép | Mũ đen ánh tím, cạnh sắc | Đen ánh tím, cạnh sắc | Khiên đen viền gai | Ủng đen có gai |
| `anim/frost_armor/` | Băng | Mũ băng xanh nhạt | Xanh băng, hoa văn tuyết | Khiên băng hoa tuyết | Ủng băng |

Màu và kiểu lấy theo icon trong `assets/ui/items/` (giáp, nón, ủng có icon) và theo đồ đã vẽ ở `assets/characters/hero_rig/gear/<giáp>/` để thống nhất. Vẽ trước một tấm `set_<giáp>.png` gồm 4 món của bộ, đứng cạnh nhau, rồi bám đúng tấm đó cho mọi khung.

- **Được vẽ lại:** nón (che phần đỉnh tóc), áo, vai, vạt áo, khiên, giày.
- **Giữ y nguyên từng điểm ảnh:** mặt (mắt, mày, mũi, miệng, má, tai), cổ, tay trần, **nắm tay cầm kiếm**, quần từ đùi tới cổ giày, khăn. Nhờ vậy kiếm vẫn gắn đúng tay và biểu cảm không đổi.
- **Nón ôm sát đầu**, rút kinh nghiệm từ đợt đầu ghép: bề ngang nón ≤ 1,06 lần đầu ở ngang trán, đỉnh nón không cao hơn đỉnh tóc gốc quá 6 px, vành nằm trên lông mày, không che mắt hay tai. Tóc không lọn nào lòi ra ngoài viền nón.
- **Khiên** giữ đúng chỗ, đúng cỡ và đúng góc của khiên gốc trong từng khung (tâm lệch ≤ 3 px, bán kính lệch ≤ 5%). Chỉ đổi chất liệu và hoa văn.
- Mỗi thư mục có đủ 15 file `fresh_<clip>.png`, cùng kích thước và lưới như bản gốc. Mỗi thư mục có một `anim.json` chép từ `anim/anim.json`; Claude sẽ tự thêm track kiếm vào sau.
- **Làm `leather_armor` trước, push, dừng chờ duyệt.** Duyệt xong mới làm bốn bộ còn lại.

**Tự kiểm tra** (`check_armor.py`):

- Mỗi khung: hình bóng (alpha ≥ 128) trùng bản không kiếm ≥ 90% (IoU). Nón và giáp có thể phồng ra một chút.
- Vùng mặt, cổ, tay trần, nắm tay, quần và khăn lệch ≤ 6/255 so với bản không kiếm. Tự tô mask "vùng được sửa" cho từng khung và lưu lại.
- Số đo nón (rộng, đỉnh, vành) và khiên (tâm, bán kính) đạt ở **mọi** khung.
- Bốn món trông giống nhau giữa các khung và giống `set_<giáp>.png`: cùng chi tiết, cùng màu. Không được khung có đinh tán, khung không.
- Ảnh duyệt `armor_<giáp>_<clip>.png`: khung mặc bộ đồ có kiếm sắt gắn theo track của đợt 1, đặt cạnh khung áo thường.

## Bàn giao mỗi đợt

Ảnh duyệt, `check.json`, `rounds_*.md` trong `docs/ideas/hero_sprites_gear/`. Commit, push đúng nhánh, báo số đo, rồi **dừng chờ duyệt**.
