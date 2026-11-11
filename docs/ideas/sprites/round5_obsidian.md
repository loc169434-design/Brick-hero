# Đợt 5 cho Gemini: Bộ Hắc Thép (bậc 4) và tuyệt kĩ HẮC TRẢM

Claude viết, 11/11/2026. Cách làm **y hệt đợt 4** ([round4_royal.md](round4_royal.md), [round2_leather.md](round2_leather.md) cho bảng clip và số khung). File này chỉ ghi những gì khác.

Song song có một AI khác vẽ Bộ Băng ([round6_frost.md](round6_frost.md)) trên nhánh `art/hero-frost`. Không đụng nhánh và thư mục của nó.

## Nhánh và thư mục

- Nhánh mới `art/hero-obsidian`, tạo từ `origin/core/world-life` (git fetch trước).
- Chỉ thêm file vào `assets/characters/hero_rookie/anim/obsidian/` và `docs/ideas/sprites/round5/`.
- Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`. Không force push.

## Trông thế nào

Vẫn đúng cậu hiệp sĩ đó. Mặt và tóc giữ nguyên như Tân binh (`docs/ideas/sprites/round2/rookie_ref.png`, `rookie_face_ref.png`):
- mắt to, lông mày rậm, cười toe lộ răng;
- **cằm trơn, không râu**;
- tóc nâu lòi ra dưới mũ.

Khăn đỏ và áo choàng đỏ vẫn giữ; áo choàng đổi sang **đỏ sẫm, viền đen**.

| Món | Bộ Hắc Thép |
|---|---|
| Nón | **mũ hở mặt thép đen**, viền bạc xám, hai bên có **vây nhọn ngắn** hướng ra sau; thấy rõ mặt và tóc |
| Thân | **giáp tấm thép đen** như `assets/ui/items/obsidian_armor.png`: vai to có gờ nhọn, viền bạc xám, **sọc đỏ**, đinh đồng; ngực có gờ chữ V; thắt lưng đỏ khóa đồng; vạt giáp xếp lớp lót đỏ |
| Tay | **găng thép đen**, đốt ngón có gờ nhọn nhỏ |
| Chân | **ủng thép đen**, ốp gối nhọn, viền bạc |
| Kiếm | **kiếm lưỡi đen ánh xám** (thép đen), sống kiếm có **rãnh đỏ**, chắn tay góc cạnh màu đồng, chuôi quấn đỏ. Dài bằng kiếm Hoàng Gia |
| Khiên | **khiên tam giác thép đen** (đầu nhọn chĩa xuống), viền bạc xám, giữa là **ngọn lửa đỏ** cách điệu. Mặt trong: thép đen tối, quai da đỏ, **không phải gỗ** |

Màu chủ đạo:
- thép đen `#2B2D33` và `#45484F`;
- bạc xám `#9AA0A8`;
- đỏ `#C0262D`;
- đồng `#D9822B`.

**Không dùng xanh lá, không dùng xanh lam** (xanh lam là của Hoàng Gia và Băng). Bộ này nhìn phải **nặng và dữ** hơn Hoàng Gia, nhưng cậu vẫn cười tươi như cũ, không thành phản diện.

## Các bước (làm một mạch, không dừng giữa chừng)

1. **Trang mẫu** `docs/ideas/sprites/round5/obsidian_model_sheet.png` trên nền `#00FF00`. Sửa từ `rookie_ref.png`, không vẽ người mới. Gồm:
   - đứng nhìn nghiêng phải;
   - nhìn chính diện;
   - sau lưng;
   - cận cảnh kiếm;
   - khiên, **cả mặt trước lẫn mặt trong**.
2. **Tự duyệt trang mẫu.** Đặt cạnh `rookie_ref.png` và `round4/royal_model_sheet.png` rồi trả lời từng câu. Câu nào "không" thì vẽ lại trang mẫu:
   - Có đúng cùng một khuôn mặt không?
   - Có râu không? Phải là không.
   - Có chỗ nào xanh lá hoặc xanh lam không? Phải là không.
   - Khiên có phải tam giác đen với ngọn lửa đỏ không?
3. **`idle`**, rồi lần lượt **23 clip còn lại**, cùng danh sách, cùng số khung, cùng fps như bảng trong `round2_leather.md`. Mỗi clip chép đúng dáng clip Tân binh cùng tên trong `assets/characters/hero_rookie/anim/fresh_<tên>.png`, kể cả:
   - độ nghiêng người;
   - chân co ở `kick`, `hurt`, `knocked`, `scared`.
4. **Clip thứ 25: tuyệt kĩ `skill_obsidian_cleave` (HẮC TRẢM)**, 16 khung, 24 fps, đòn trúng ở khung 9. Đây là clip mới, Tân binh không có, nên không có dáng để chép. Đọc kĩ dáng trong [../outfit_skills.md](../outfit_skills.md):
   - hai tay vung kiếm ra sau lưng, xoay hông;
   - bổ chéo xuống ở khung 9, mũi kiếm cắm đất;
   - rút kiếm lên;
   - khung 0 và khung 15 là dáng `idle` của bộ.

   Đòn phải nặng: lấy đà chậm (khung 1–6), chém thật nhanh (khung 7–9), giữ kiếm cắm đất 3 khung. Không vẽ vệt chém hay đá vỡ.
5. **Mỗi clip xong và ĐẠT thì commit và push ngay**, để Claude theo dõi giữa chừng. Thứ tự gợi ý: idle, attack, hurt, run, block, dash, combo, rồi các clip còn lại.

Đường dẫn:
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_<tên>_green.png`.
- Bản đã tách: `assets/characters/hero_rookie/anim/obsidian/fresh_<tên>.png`.
- Ảnh kiểm, report và `rounds.md`: `--out docs/ideas/sprites/round5`.

## Tự soát trước khi nộp mỗi clip

- Mỗi khung một kiếm, một khiên.
- Khiên, mũ, giáp không đổi màu giữa các khung, kể cả khi thấy mặt trong khiên hay nhìn sau lưng.
- Không khung nào còn đồ của bộ cũ (gỗ, da, sắt trơn, xanh vàng Hoàng Gia).
- **Cỡ người đều nhau giữa các khung**: khung nào cao hơn khung bên cạnh quá 8% (không tính kiếm giơ lên) là sai. Đợt 4 bị lỗi này ở `leap` khung 9–10.

`check_sheet.py` cho từng clip phải ĐẠT:
- tham chiếu `--ref assets/characters/hero_rookie/anim/fresh_idle.png`;
- `run` dùng `--airborne --ref assets/characters/hero_rookie/anim/fresh_run.png`.

Một clip sửa tối đa 5 vòng. Quá 5 vòng vẫn trượt thì ghi lý do vào `rounds.md` rồi làm clip tiếp theo.

## Khi xong cả 25 clip

Báo một bảng gồm tên clip, ĐẠT hay TRƯỢT, và số vòng sửa. Rồi **dừng**.
