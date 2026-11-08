# Đợt 3 cho Gemini: hiệp sĩ mặc Bộ sắt (bậc 2), trọn 24 động tác

Claude viết. Cách làm **y hệt đợt 2 Bộ da**: [round2_leather.md](round2_leather.md). Đọc file đó trước; file này chỉ ghi những gì khác.

Nhánh mới `art/hero-iron`, tạo từ `origin/core/world-life`. Chỉ thêm file vào `assets/characters/hero_rookie/anim/iron/` và `docs/ideas/sprites/round3/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`. Không force push.

## Bộ sắt trông thế nào

Vẫn đúng cậu hiệp sĩ đó. Mặt và tóc giữ nguyên như Tân binh (`docs/ideas/sprites/round2/rookie_ref.png`, `rookie_face_ref.png`): mắt to, lông mày rậm, cười toe lộ răng, **cằm trơn, không râu**. Khăn đỏ và áo choàng đỏ vẫn giữ.

| Món | Bộ sắt |
|---|---|
| Nón | **mũ sắt tròn có thanh che mũi**, viền đinh tán; tóc nâu vẫn lòi ra hai bên và sau gáy |
| Thân | **giáp ngực thép** như `assets/ui/items/iron_armor.png`: giáp vai tròn có đinh, thắt lưng da khóa vàng, vạt áo xanh viền kem lộ dưới giáp |
| Tay | **găng sắt** che mu bàn tay và cẳng tay |
| Chân | **ủng có ốp sắt** ở ống quyển và mũi giày |
| Kiếm | **kiếm thép sáng**: lưỡi bạc có rãnh giữa, chắn tay sắt, chuôi quấn da. Cùng độ dài kiếm cũ |
| Khiên | **khiên tròn thép**, viền đinh tán, giữa có núm thép, vẽ một dải đỏ ngang |

Màu chủ đạo: thép `#B8C2CC` và `#7E8A96`, đồng `#D9A441`, da `#8B5A2B`. **Không dùng màu xanh lá.** Bộ sắt phải nhìn rõ là nặng và sáng hơn Bộ da.

## Các bước

1. **Trang mẫu** `docs/ideas/sprites/round3/iron_model_sheet.png` trên nền `#00FF00`: đứng nhìn nghiêng phải (sửa từ `rookie_ref.png`, không vẽ người mới), nhìn chính diện, sau lưng, cận cảnh kiếm và khiên.
2. **`idle`** Bộ sắt.
3. Commit, push, báo, rồi **dừng chờ duyệt mẫu**. Chỉ khi được báo "duyệt mẫu" mới làm 23 clip còn lại.
4. 23 clip còn lại: cùng danh sách 24 clip, cùng số khung, fps như bảng trong `round2_leather.md`. Mỗi clip chép đúng dáng clip Tân binh cùng tên trong `assets/characters/hero_rookie/anim/fresh_<tên>.png`.

Đường dẫn:
- Bản gốc nền xanh: `docs/ideas/sprites/round3/raw/fresh_<tên>_green.png`.
- Bản đã tách: `assets/characters/hero_rookie/anim/iron/fresh_<tên>.png`.
- Ảnh kiểm, report và `rounds.md`: `docs/ideas/sprites/round3/` (dùng `--out docs/ideas/sprites/round3`).

## Lưu ý từ đợt 2

- Mỗi khung chỉ một kiếm, một khiên. Không món nào tự biến mất hay đổi màu giữa các khung.
- `kick` khung 4, `hurt`, `knocked`, `scared`: bản da đứng thẳng hơn Tân binh. Lần này giữ đúng độ nghiêng người và chân co của Tân binh.

## Bàn giao

Cả 24 clip phải ĐẠT. Commit, push `art/hero-iron` (không force push), báo kết quả kiểm tra cả 24 clip, rồi **dừng**.
