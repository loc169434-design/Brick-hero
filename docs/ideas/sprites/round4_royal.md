# Đợt 4 cho Gemini: sửa khiên Bộ sắt, rồi Bộ Hoàng Gia (bậc 3)

Claude viết. Cách làm **y hệt đợt 2 và đợt 3**: [round2_leather.md](round2_leather.md), [round3_iron.md](round3_iron.md). File này chỉ ghi những gì khác.

## Việc 0: sửa khiên Bộ sắt (nhánh `art/hero-iron`)

Bộ sắt đã đạt hết các mục kiểm. Còn một lỗi: ở những khung thấy **mặt trong** của khiên (tay nắm quai, hoặc nhìn sau lưng), khiên bị vẽ thành **khiên gỗ nâu** của Tân binh. Chạy 24 khung/giây thì khiên nhấp nháy xám rồi nâu.

Sửa: mặt trong khiên sắt là **thép xám tối, viền thép sáng, đinh tán**, quai cầm bằng da. Không còn chỗ nào màu gỗ nâu.

Các clip cần soát (đã thấy lỗi ở nhiều khung):
- `combo`
- `skill_second_wind`
- `skill_blade_vortex`
- `skill_starfall_strike`

Soát luôn 20 clip còn lại; khung nào thấy mặt trong khiên thì sửa cùng kiểu.

Cách sửa: sửa bản gốc nền xanh trong `docs/ideas/sprites/round3/raw/`, tách lại bằng `key_out.py`, chạy lại `check_sheet.py`. Commit và push `art/hero-iron` (không force push).

Sửa nhỏ thêm nếu kịp: `kick` khung 1–2 Bộ sắt đang đứng thẳng; chép đúng dáng lấy đà của Tân binh.

## Việc 1: Bộ Hoàng Gia (nhánh mới `art/hero-royal`, tạo từ `origin/core/world-life`)

Chỉ thêm file vào `assets/characters/hero_rookie/anim/royal/` và `docs/ideas/sprites/round4/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`. Không force push.

### Trông thế nào

Vẫn đúng cậu hiệp sĩ đó. Mặt và tóc giữ nguyên như Tân binh (`docs/ideas/sprites/round2/rookie_ref.png`, `rookie_face_ref.png`): mắt to, lông mày rậm, cười toe lộ răng, **cằm trơn, không râu**, tóc nâu lòi ra dưới mũ. Khăn đỏ và áo choàng đỏ vẫn giữ; áo choàng thêm **viền vàng**.

| Món | Bộ Hoàng Gia |
|---|---|
| Nón | **mũ hở mặt màu xanh hoàng gia**, viền vàng, trên đỉnh có **chỏm lông đỏ** ngắn; thấy rõ mặt và tóc |
| Thân | **giáp tấm xanh lam viền vàng** như `assets/ui/items/royal_armor.png`: vai tròn có đinh vàng, ngực có **huy hiệu sư tử vàng**, thắt lưng xanh khóa vàng, vạt giáp xếp lớp |
| Tay | **găng giáp xanh viền vàng** |
| Chân | **ủng giáp xanh**, ốp gối và mũi giày viền vàng |
| Kiếm | **trường kiếm bạc sáng**: chắn tay vàng uốn cong, chuôi quấn xanh, núm chuôi có **ngọc xanh**. Dài hơn kiếm sắt khoảng 10% |
| Khiên | **khiên tròn xanh lam**, viền vàng, giữa là **sư tử vàng**. Mặt trong: thép xanh tối viền vàng, **không phải gỗ** |

Màu chủ đạo: xanh hoàng gia `#2343A8` và `#3A5FD0`, vàng `#E8B530` và `#B8861B`, bạc `#C9D2DC`, đỏ áo choàng giữ nguyên. **Không dùng màu xanh lá.** Bộ này phải nhìn rõ sang trọng nhất trong ba bộ đã có.

### Các bước

1. **Trang mẫu** `docs/ideas/sprites/round4/royal_model_sheet.png` trên nền `#00FF00`: đứng nhìn nghiêng phải (sửa từ `rookie_ref.png`, không vẽ người mới), nhìn chính diện, sau lưng, cận cảnh kiếm, khiên **cả mặt trước lẫn mặt trong**.
2. **`idle`** Bộ Hoàng Gia.
3. Commit, push, báo, rồi **dừng chờ duyệt mẫu**. Chỉ khi được báo "duyệt mẫu" mới làm 23 clip còn lại.
4. 23 clip còn lại: cùng danh sách, cùng số khung, fps như bảng trong `round2_leather.md`. Mỗi clip chép đúng dáng clip Tân binh cùng tên trong `assets/characters/hero_rookie/anim/fresh_<tên>.png`, kể cả độ nghiêng người và chân co ở `kick`, `hurt`, `knocked`, `scared`.

Đường dẫn:
- Bản gốc nền xanh: `docs/ideas/sprites/round4/raw/fresh_<tên>_green.png`.
- Bản đã tách: `assets/characters/hero_rookie/anim/royal/fresh_<tên>.png`.
- Ảnh kiểm, report và `rounds.md`: `--out docs/ideas/sprites/round4`.

### Tự soát trước khi nộp

- Mỗi khung một kiếm, một khiên.
- Khiên, mũ, giáp không đổi màu giữa các khung, kể cả khi thấy mặt trong khiên hay nhìn sau lưng.
- Không khung nào còn đồ của bộ cũ (gỗ, da, sắt trơn).

Cả 24 clip phải ĐẠT (`run` thêm `--airborne --ref assets/characters/hero_rookie/anim/fresh_run.png`). Commit, push `art/hero-royal` (không force push), báo kết quả cả 24 clip, rồi **dừng**.
