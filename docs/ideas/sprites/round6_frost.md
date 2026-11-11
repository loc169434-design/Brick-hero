# Đợt 6 cho Gemini Carbon: Bộ Băng (bậc 5, bộ cuối) và tuyệt kĩ của bốn bộ

Claude viết, 11/11/2026. Cách làm **y hệt đợt 4** ([round4_royal.md](round4_royal.md), [round2_leather.md](round2_leather.md) cho bảng clip và số khung). File này chỉ ghi những gì khác.

Song song có một AI khác vẽ Bộ Hắc Thép ([round5_obsidian.md](round5_obsidian.md)) trên nhánh `art/hero-obsidian`. Không đụng nhánh và thư mục của nó.

## Nhánh và thư mục

- Nhánh mới `art/hero-frost`, tạo từ `origin/core/world-life` (git fetch trước).
- Chỉ thêm file vào:
  - `assets/characters/hero_rookie/anim/frost/`;
  - `docs/ideas/sprites/round6/`;
  - riêng Việc 2, ba file tuyệt kĩ trong `anim/leather/`, `anim/iron/`, `anim/royal/` (chỉ thêm file mới, không sửa file đã có).
- Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`. Không force push.

## Trông thế nào

Vẫn đúng cậu hiệp sĩ đó. Mặt và tóc giữ nguyên như Tân binh (`docs/ideas/sprites/round2/rookie_ref.png`, `rookie_face_ref.png`):
- mắt to, lông mày rậm, cười toe lộ răng;
- **cằm trơn, không râu**;
- tóc nâu lòi ra dưới mũ.

Khăn đổi sang **xanh băng nhạt**. Áo choàng đổi sang **trắng xanh, viền lông trắng** ở cổ.

| Món | Bộ Băng |
|---|---|
| Nón | **mũ hở mặt bạc trắng**, viền xanh băng, trên trán có **viên pha lê băng** nhỏ, hai bên có **gai băng** ngắn; thấy rõ mặt và tóc |
| Thân | **giáp tấm bạc trắng** như `assets/ui/items/frost_armor.png`: vai tròn viền xanh băng có **họa tiết tinh thể băng**, đinh xanh lam; ngực có **bông tuyết** khắc chìm; thắt lưng bạc khóa vàng gắn **ngọc băng**; vạt giáp có tinh thể băng |
| Tay | **găng bạc**, cổ tay viền xanh băng |
| Chân | **ủng bạc**, ốp gối có tinh thể băng |
| Kiếm | **kiếm pha lê băng**: lưỡi xanh băng trong, ánh trắng ở mép, chắn tay bạc hình bông tuyết, chuôi quấn xanh lam, núm chuôi ngọc băng. Dài bằng kiếm Hoàng Gia. **Không vẽ khói lạnh hay tia sáng bay quanh**: hiệu ứng do code vẽ |
| Khiên | **khiên tròn bạc trắng**, viền xanh băng, giữa là **bông tuyết** lớn. Mặt trong: bạc xám xanh, quai da xanh lam, **không phải gỗ** |

Màu chủ đạo:
- bạc trắng `#E6ECF2` và `#B9C4CF`;
- xanh băng `#8FE3F0` và `#4FB8D6`;
- xanh lam đinh `#2F6FD0`;
- vàng khóa `#E8B530`.

**Không dùng xanh lá.** Đây là bộ cuối, đắt nhất: nhìn phải **sáng, lạnh, quý**, khác hẳn xanh hoàng gia đậm của Hoàng Gia.

**Coi chừng nền trong suốt:** bộ này nhiều màu trắng và xanh nhạt, dễ bị `key_out.py` ăn mất viền hoặc để lại quầng xanh lá. Sau khi tách, xem trên cả nền tối lẫn nền sáng.

## Các bước (làm một mạch, không dừng giữa chừng)

1. **Trang mẫu** `docs/ideas/sprites/round6/frost_model_sheet.png` trên nền `#00FF00`. Sửa từ `rookie_ref.png`, không vẽ người mới. Gồm:
   - đứng nhìn nghiêng phải;
   - nhìn chính diện;
   - sau lưng;
   - cận cảnh kiếm;
   - khiên, **cả mặt trước lẫn mặt trong**.
2. **Tự duyệt trang mẫu.** Đặt cạnh `rookie_ref.png` và `round4/royal_model_sheet.png` rồi trả lời từng câu. Câu nào "không" thì vẽ lại trang mẫu:
   - Có đúng cùng một khuôn mặt không?
   - Có râu không? Phải là không.
   - Có chỗ nào xanh lá không? Phải là không.
   - Có dễ phân biệt với Hoàng Gia khi thu nhỏ không?
3. **`idle`**, rồi lần lượt **23 clip còn lại**, cùng danh sách, cùng số khung, cùng fps như bảng trong `round2_leather.md`. Mỗi clip chép đúng dáng clip Tân binh cùng tên trong `assets/characters/hero_rookie/anim/fresh_<tên>.png`, kể cả:
   - độ nghiêng người;
   - chân co ở `kick`, `hurt`, `knocked`, `scared`.
4. **Clip thứ 25: tuyệt kĩ `skill_frost_nova` (BĂNG PHONG)**, 16 khung, 24 fps, đòn trúng ở khung 7. Đây là clip mới, Tân binh không có, nên không có dáng để chép. Đọc kĩ dáng trong [../outfit_skills.md](../outfit_skills.md):
   - nhảy nhẹ;
   - hai tay cắm kiếm xuống đất ở khung 7;
   - quỳ một gối giữ kiếm 4 khung;
   - đứng dậy;
   - khung 0 và khung 15 là dáng `idle` của bộ.

   Không vẽ băng lan hay khói lạnh.
5. **Mỗi clip xong và ĐẠT thì commit và push ngay**, để Claude theo dõi giữa chừng. Thứ tự gợi ý: idle, attack, hurt, run, block, dash, combo, rồi các clip còn lại.

Đường dẫn:
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_<tên>_green.png`.
- Bản đã tách: `assets/characters/hero_rookie/anim/frost/fresh_<tên>.png`.
- Ảnh kiểm, report và `rounds.md`: `--out docs/ideas/sprites/round6`.

## Tự soát trước khi nộp mỗi clip

- Mỗi khung một kiếm, một khiên.
- Khiên, mũ, giáp không đổi màu giữa các khung, kể cả khi thấy mặt trong khiên hay nhìn sau lưng.
- Không khung nào còn đồ của bộ cũ (gỗ, da, sắt trơn, xanh vàng Hoàng Gia).
- **Cỡ người đều nhau giữa các khung**: khung nào cao hơn khung bên cạnh quá 8% (không tính kiếm giơ lên) là sai. Đợt 4 bị lỗi này ở `leap` khung 9–10.

`check_sheet.py` cho từng clip phải ĐẠT:
- tham chiếu `--ref assets/characters/hero_rookie/anim/fresh_idle.png`;
- `run` dùng `--airborne --ref assets/characters/hero_rookie/anim/fresh_run.png`.

Một clip sửa tối đa 5 vòng. Quá 5 vòng vẫn trượt thì ghi lý do vào `rounds.md` rồi làm clip tiếp theo.

## Việc 2: tuyệt kĩ cho ba bộ đã có (làm sau khi xong 25 clip Bộ Băng)

Mỗi bộ một clip, 16 khung, 24 fps. Dáng xem [../outfit_skills.md](../outfit_skills.md). Vẽ **đúng đồ của bộ đó**: mở `fresh_idle.png` của bộ ra mà chép mặt, giáp, kiếm, khiên.

| Bộ | File | Đòn trúng | Dáng |
|---|---|---|---|
| Bộ da | `anim/leather/fresh_skill_tumble_cut.png` | khung 10 | lộn nhào về trước, bật dậy chém hất từ dưới lên |
| Bộ sắt | `anim/iron/fresh_skill_shield_charge.png` | khung 8 | cúi thấp, khiên chắn trước, lao tới húc, lùi về |
| Hoàng Gia | `anim/royal/fresh_skill_royal_rally.png` | khung 8 | cắm khiên, giơ kiếm thẳng lên trời, hô to, giữ 3 khung, hạ kiếm |

- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/<bộ>_fresh_<clip>_green.png`.
- `check_sheet.py`: `--ref` là `fresh_idle.png` của chính bộ đó. `skill_tumble_cut` thêm `--airborne`.
- Mỗi clip ĐẠT thì commit và push ngay.

## Khi xong hết (25 clip Bộ Băng và 3 tuyệt kĩ)

Báo một bảng gồm tên clip, ĐẠT hay TRƯỢT, và số vòng sửa. Rồi **dừng**.
