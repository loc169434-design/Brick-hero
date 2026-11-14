# Ảnh cho store, cho ChatGPT

Claude viết. Kế hoạch chung: [docs/release_plan.md](../release_plan.md).

Nhánh mới `art/store`, tạo từ `origin/core/world-life`. Chỉ thêm file vào `assets/ui/store/` và `docs/ideas/store/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, các file `.import`. Không force push.

## Nhân vật và phong cách

Dùng đúng hiệp sĩ Tân binh đang có, giữ nguyên mặt, tóc nâu bù xù, khăn đỏ, áo choàng đỏ, nét viền và cách tô của game. Ảnh gốc:
- `docs/ideas/sprites/round2/rookie_ref.png`
- `docs/ideas/sprites/round2/rookie_face_ref.png`

Sửa từ các ảnh đó, không vẽ nhân vật mới từ chữ. Phong cách cổ tích vui, sáng, không máu me. **Không có chữ trong ảnh** trừ khi ghi rõ bên dưới.

## Danh sách

| File | Cỡ | Nội dung |
|---|---|---|
| `app_icon_1024.png` | 1024×1024, **nền đặc, không trong suốt**, không bo góc | Mặt hiệp sĩ cười toe đội mũ Tân binh, cầm kiếm gỗ chếch lên, phía sau là vài ô gạch màu đỏ, xanh lá, vàng, tím. Nhìn rõ ở cỡ 48×48: hình to, ít chi tiết, viền đậm |
| `adaptive_fg_432.png` | 432×432, **nền trong suốt** | Riêng hiệp sĩ của icon trên, nằm gọn trong vòng tròn giữa đường kính 264 px (Android cắt bớt mép) |
| `adaptive_bg_432.png` | 432×432, nền đặc | Riêng phần nền ô gạch của icon, không có nhân vật |
| `splash_1080x1920.png` | 1080×1920, nền đặc | Màn khởi động: hiệp sĩ đứng trước lâu đài, bầu trời sáng. **Chừa trống phần giữa trên** (khoảng y 300–700) để game tự đặt tên game bằng chữ |
| `feature_1024x500.png` | 1024×500, nền đặc | Ảnh bìa Google Play: hiệp sĩ vung kiếm bên trái, Tù Trưởng Orc bên phải, giữa là các ô gạch đang nổ tung. Chừa trống phần giữa trên để Claude đặt tên game |
| `logo_title.png` | khoảng 900×360, nền trong suốt | **Chữ "Brickbound Hero"** kiểu logo game: chữ to, nổi khối, viền đậm, màu vàng-cam, có một thanh kiếm gỗ chéo sau chữ. Đúng chính tả, không thêm chữ khác |

## Cách làm và tự kiểm

1. Mỗi ảnh lưu bản gốc vào `docs/ideas/store/raw/`. Ảnh cần nền trong suốt thì vẽ trên nền `#00FF00` rồi tách bằng:
   ```sh
   python3 tools/sprites/key_out.py <ảnh nền xanh> <ảnh đích>
   ```
2. Ảnh xong để vào `assets/ui/store/`, đúng tên và đúng cỡ như bảng.
3. Tự xem lại:
   - thu `app_icon_1024.png` về 48×48 vẫn nhận ra hiệp sĩ;
   - `adaptive_fg_432.png` cắt tròn đường kính 264 px vẫn còn đủ mặt;
   - `logo_title.png` đúng chữ "Brickbound Hero".
4. Ghi vào `docs/ideas/store/notes.md`: mỗi file đã kiểm thế nào.

Commit, push `art/store` (không force push), báo, rồi **dừng**.
