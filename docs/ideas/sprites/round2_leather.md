# Đợt 2 cho Gemini: hiệp sĩ mặc Bộ da (bậc 1), trọn 24 động tác

Claude viết. Kế hoạch chung: [docs/sprite_plan.md](../../sprite_plan.md). Cách vẽ nền xanh và tách nền giữ y như đợt 1: [round1_moves.md](round1_moves.md).

Làm trên nhánh mới `art/hero-leather`, tạo từ `origin/core/world-life`. Nhánh này đã có 9 động tác đợt 1. Chỉ thêm hoặc sửa file trong `assets/characters/hero_rookie/anim/` và `docs/ideas/sprites/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`. Không force push.

## Việc 0: sửa 1 khung của đợt 1

`fresh_skill_blade_vortex.png` khung **6** (nhìn từ sau lưng) bị vẽ **hai cái khiên**, hai bên người, mà không thấy kiếm. Sửa lại thành một khiên ở một tay, kiếm ở tay kia, đúng nhịp xoay giữa khung 5 và khung 7.

Cách sửa: sửa bản gốc `docs/ideas/sprites/round1/raw/fresh_skill_blade_vortex_green.png`, tách nền lại bằng `key_out.py`, rồi chạy lại `check_sheet.py` như đợt 1.

## Bộ da trông thế nào

Vẫn **đúng cậu hiệp sĩ đó**: mặt, tóc nâu bù xù, khăn đỏ, áo choàng đỏ, tỉ lệ chibi, nét viền và cách tô bóng y như Tân binh. Chỉ thay đồ:

| Món | Tân binh | Bộ da |
|---|---|---|
| Nón | không có | **mũ da khâu chỉ** có quai cài cằm như `assets/ui/items/leather_helmet.png`; tóc vẫn lòi ra hai bên và sau gáy |
| Thân | áo vải xanh viền kem | **giáp ngực da nâu** như `assets/ui/items/leather_armor.png`: đệm vai, khóa vàng ở vai và thắt lưng, vạt da dưới bụng; áo xanh vẫn lộ ở tay áo và vạt dưới |
| Tay | cổ tay vải | **bao tay da** đến khuỷu, có dây buộc |
| Chân | ủng nâu trơn | **ủng da cao** có hai dây cài và mũi bọc |
| Kiếm | kiếm gỗ | **kiếm sắt ngắn**: lưỡi xám bạc, chuôi quấn da, chắn tay bằng đồng. Cùng độ dài kiếm gỗ |
| Khiên | khiên tròn gỗ viền sắt | **khiên tròn bọc da**, viền sắt, 4 đinh tán đồng, giữa có núm đồng |

Màu chủ đạo: nâu da `#8B5A2B` và `#A86B35`, đồng `#D9A441`, sắt `#9AA3AD`. **Không dùng màu xanh lá** (vì tách nền xanh).

Trước khi vẽ động tác, vẽ **1 trang mẫu** `docs/ideas/sprites/round2/leather_model_sheet.png`: đứng thẳng nhìn nghiêng phải, nhìn chính diện và nhìn sau lưng, kèm cận cảnh kiếm và khiên. Mọi khung sau phải khớp trang mẫu này: đồ không được tự đổi chi tiết giữa các khung.

## Cách vẽ: chép dáng Tân binh, thay đồ

Mỗi clip Bộ da **chép đúng dáng, đúng số khung, đúng thứ tự** của clip Tân binh cùng tên trong `assets/characters/hero_rookie/anim/fresh_<tên>.png`. Đầu, tay, chân, kiếm ở cùng vị trí. Chỉ thay quần áo và vũ khí. Nhờ vậy nhịp đánh và số khung `impact` giữ nguyên, game không phải chỉnh gì.

Định dạng giữ như đợt 1:
- Lưới 4 cột, khung 512×512.
- Quay mặt sang phải, chân chạm đất tại (256, 500).
- Không vẽ hiệu ứng.
- Vẽ trên nền `#00FF00`, tách nền chỉ bằng `key_out.py`.

Nhân vật đội mũ nên sẽ cao hơn Tân binh một chút; vẫn trong giới hạn 8% của bước kiểm.

## Danh sách 24 clip

Bản gốc nền xanh: `docs/ideas/sprites/round2/raw/fresh_<tên>_green.png`.
Bản đã tách: `assets/characters/hero_rookie/anim/leather/fresh_<tên>.png` (thư mục `leather/` mới).

| Tên | Khung | fps | Tên | Khung | fps |
|---|---|---|---|---|---|
| `idle` | 8 | 12 | `run` | 8 | 16 |
| `attack` | 12 | 24 | `combo` | 16 | 24 |
| `throw` | 10 | 24 | `block` | 8 | 24 |
| `leap` | 16 | 24 | `dash` | 6 | 24 |
| `kick` | 8 | 24 | `skill_armor_breaker` | 14 | 24 |
| `bash` | 10 | 24 | `skill_second_wind` | 14 | 12 |
| `drink` | 12 | 12 | `skill_thunder_slash` | 14 | 24 |
| `hurt` | 8 | 24 | `skill_iron_guard` | 10 | 12 |
| `dizzy` | 12 | 12 | `skill_blade_vortex` | 16 | 24 |
| `knocked` | 8 | 24 | `skill_starfall_strike` | 16 | 24 |
| `scared` | 8 | 12 | | | |
| `cheer` | 12 | 12 | | | |
| `victory` | 12 | 12 | | | |
| `defeat` | 12 | 12 | | | |

Không vẽ các mức `bruised_` hay `battered_` cho Bộ da; chỉ `fresh_`.

Thứ tự làm: trang mẫu, `idle`, `attack`, rồi các clip còn lại theo bảng. Nếu `idle` và `attack` chưa đẹp thì sửa xong hai cái này rồi mới làm tiếp, vì mọi clip sau chép theo chúng.

## Tự kiểm tra

Với mỗi clip:

```sh
python3 tools/sprites/key_out.py docs/ideas/sprites/round2/raw/fresh_<tên>_green.png assets/characters/hero_rookie/anim/leather/fresh_<tên>.png
python3 tools/sprites/check_sheet.py assets/characters/hero_rookie/anim/leather/fresh_<tên>.png --frames <khung> --fps <fps> --key 00ff00 --out docs/ideas/sprites/round2
```

Riêng `run`: khung cuối đang ở trên không và dáng chạy thấp hơn dáng đứng, nên thêm `--airborne --ref assets/characters/hero_rookie/anim/fresh_run.png`.

**Cả 24 clip phải ĐẠT hết các mục**, tối đa 5 vòng sửa mỗi clip. Ghi số đo vào `docs/ideas/sprites/round2/rounds.md`.

Tự xem thêm:
- Đặt GIF Bộ da cạnh GIF Tân binh cùng tên: dáng phải trùng khớp.
- Xem trên nền tối: không khe trắng, không quầng xanh.
- Trong một clip, mũ, giáp, kiếm và khiên không đổi màu, không đổi cỡ, không biến mất. Khiên chỉ được khuất sau người khi dáng Tân binh cũng khuất.
- Mỗi khung chỉ một kiếm, một khiên.

## Bàn giao

- Bản sửa `fresh_skill_blade_vortex` (việc 0).
- Trang mẫu Bộ da.
- 24 sheet trong `anim/leather/`.
- 24 bản gốc nền xanh trong `docs/ideas/sprites/round2/raw/`.
- GIF, report và `rounds.md` trong `docs/ideas/sprites/round2/`.

Commit, push `art/hero-leather` (không force push), báo kết quả kiểm tra cả 24 clip, rồi **dừng**. Claude sẽ viết `anim/leather/anim.json` và gắn vào game.
