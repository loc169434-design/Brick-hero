# Đợt 4 — Bộ Hoàng Gia (Bậc 3) (`art/hero-royal`)

## Trang mẫu & `idle` (chờ duyệt mẫu)

- Trang mẫu nền xanh `#00FF00`: `docs/ideas/sprites/round4/royal_model_sheet.png` (và `docs/ideas/sprites/round4/raw/royal_model_sheet_green.png`)
  - Đứng nhìn nghiêng phải (sửa trực tiếp từ `rookie_ref.png`, giữ nguyên 100% gương mặt, mắt to, lông mày rậm, cười lộ răng, cằm trơn không râu, tai và tóc mái nâu bù xù lòi ra dưới mũ).
  - Nhìn chính diện, nhìn sau lưng (áo choàng đỏ có viền vàng, chỏm lông đỏ ngắn trên đỉnh mũ).
  - Cận cảnh trường kiếm bạc sáng (dài hơn kiếm sắt ~10%, chắn tay vàng uốn cong, chuôi quấn xanh, núm chuôi đính ngọc xanh).
  - Cận cảnh khiên tròn xanh hoàng gia viền vàng **cả mặt trước (sư tử vàng giữa khiên) lẫn mặt trong (thép xanh tối viền vàng, đinh tán, quai cầm, không phải gỗ)**.
- Clip `idle`:
  - Bản gốc nền xanh: `docs/ideas/sprites/round4/raw/fresh_idle_green.png`
  - Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/royal/fresh_idle.png`
  - Kết quả `check_sheet.py --frames 8 --fps 12 --key 00ff00 --out docs/ideas/sprites/round4`: **ĐẠT** cả 6 mục (`grid`, `feet`, `size`, `clean`, `inside`, `key`).
