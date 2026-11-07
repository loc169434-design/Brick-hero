# Bàn giao bộ mảnh rig hiệp sĩ v2 (`art/hero-rig-v2`)

## 1. Tóm tắt công việc
Bộ mảnh rig hiệp sĩ trong `assets/characters/hero_rig/` đã được làm lại hoàn toàn theo đúng phương pháp **cắt trực tiếp từ ảnh gốc** `assets/characters/hero_rookie/anim/fresh_idle.png` (khung 0: vùng `(0,0,512,512)`, chân đặt tại `(256,500)`, bỏ kiếm gỗ):

1. **Cắt mảnh trực tiếp & giữ nguyên pixel gốc (`assets/characters/hero_rig/parts/*.png`)**:
   - Toàn bộ 17 mảnh cơ thể (`cape`, `back_leg_upper`, `back_leg_lower`, `back_foot`, `sword_arm_upper`, `pelvis`, `front_leg_upper`, `front_leg_lower`, `front_foot`, `torso`, `head`, `sword_arm_lower`, `sword_hand`, `shield_arm_upper`, `shield_arm_lower`, `shield_hand`, `shield`) giữ nguyên 100% pixel, nét viền và màu sắc từ `fresh_idle.png` khung 0 tại vùng hiển thị.
   - Các phần khuất sau mảnh khác tại đầu khớp (`waist`, `neck`, `cape`, `shoulder_shield`, `elbow_shield`, `wrist_shield`, `shield`, `shoulder_sword`, `elbow_sword`, `wrist_sword`, `hip_back`, `knee_back`, `ankle_back`, `hip_front`, `knee_front`, `ankle_front`) được **vẽ bù (`H_p`)** bằng đĩa tròn đồng tâm quanh tâm khớp (`r = 21..40 px`), tô màu nội suy từ vùng màu kế cận của chính mảnh đó và bo viền nâu đậm (`#24130b`, dày `4 px`) nằm hoàn toàn trong vùng bị che (`occ[p]`) ở tư thế nghỉ.
   - Nhờ cấu trúc đĩa khớp đồng tâm (mảnh dưới có đĩa viền đậm lớn hơn mảnh trên), khi xoay bất kỳ khớp nào tới `±35°`, vùng bán kính `20 px` quanh khớp luôn đặc 100% và nét viền ngoài luôn nối tiếp liền mạch, không bao giờ hở hay đứt nét.

2. **Tâm xoay giải phẫu (`assets/characters/hero_rig/joints.json`)**:
   - Giữ nguyên cấu trúc JSON, danh sách tên mảnh, tên khớp và mảng `"order"`.
   - Cập nhật toạ độ 18 khớp về đúng tâm xoay giải phẫu thật trên hình bóng `fresh_idle.png`:
     - `hip`: `[262, 355]`, `waist`: `[262, 326]`, `neck`: `[258, 234]`, `cape`: `[236, 244]`
     - `shoulder_shield`: `[198, 266]`, `elbow_shield`: `[192, 290]`, `wrist_shield`: `[202, 316]`, `shield`: `[166, 348]`
     - `shoulder_sword`: `[294, 276]`, `elbow_sword`: `[311, 312]`, `wrist_sword`: `[352, 314]`, `grip`: `[356, 314]`
     - `hip_back`: `[222, 376]`, `knee_back`: `[200, 424]`, `ankle_back`: `[184, 468]`
     - `hip_front`: `[290, 377]`, `knee_front`: `[304, 424]`, `ankle_front`: `[311, 468]`

3. **Các lớp trang bị (`assets/characters/hero_rig/gear/`)**:
   - Đã căn chỉnh và vẽ khớp khít trên từng mảnh chủ mới cho cả bộ **đồ da** (`leather_armor`, `leather_helmet`, `reinforced_boots` — 9 file PNG) và bộ **đồ sắt** (`iron_armor`, `iron_helmet`, `climbing_boots` — 9 file PNG).
   - Mỗi lớp đồ nằm gọn trong phạm vi mảnh chủ (0 pixel vượt biên nới rộng `24 px`), che phủ khít phần áo/cổ ủng bên dưới và giữ nguyên 100% vùng mặt (mắt, lông mày, mũi, miệng, tai).

---

## 2. Số đo kiểm tra vòng cuối (`check_result.json`)

Chạy `python3 docs/ideas/hero_rig_v2/check_rig.py` đạt tuyệt đối cả 5 hạng mục **A–E** (`"all_passed": true`):

| Hạng mục | Tiêu chí | Kết quả đo thực tế | Trạng thái |
|---|---|---|---|
| **A. Khớp ảnh gốc** | `IoU (alpha > 32) ≥ 0.97`<br>Sai khác màu TB `≤ 6/255`<br>`0` vùng `> 3×3 px` sai `> 40/255` | `IoU = 0.996250`<br>Sai khác màu TB = `0.0904 / 255`<br>Số vùng `> 3×3 px` sai `> 40/255` = `0` | **ĐẠT** ✅ |
| **B. Không hở khi xoay** | 14 khớp × 4 góc (`-35°, -20°, +20°, +35°`), bán kính `20 px`: giữ `100%` pixel đặc (`alpha ≥ 200`) | `56 / 56` mẫu đạt (`100%`)<br>Tổng số pixel mất độ đặc = `0` | **ĐẠT** ✅ |
| **C. Nét viền liền** | 14 khớp × 4 góc: tô loang từ `(0,0)` không lọt qua viền đậm vào thân quanh khớp | `56 / 56` mẫu đạt (`100%`)<br>Tổng số pixel rò qua khe viền = `0` | **ĐẠT** ✅ |
| **D. Đồ da (& Đồ sắt)** | Nằm trong mảnh chủ nới `24 px`<br>Vùng mặt giống hệt bản không đồ | `0` pixel vượt biên `24 px` (trên cả 18 lớp đồ)<br>Sai khác vùng mặt = `0 / 255` | **ĐẠT** ✅ |
| **E. Định dạng & Canvas** | Mọi PNG `512×512` RGBA, không chạm mép canvas | `35 / 35` file PNG đạt chuẩn `512×512` RGBA<br>`0` pixel chạm 4 cạnh biên canvas | **ĐẠT** ✅ |

---

## 3. Danh mục file bàn giao trong `docs/ideas/hero_rig_v2/`
- [`check_rig.py`](check_rig.py): Script tự kiểm tra các tiêu chí A–E và xuất toàn bộ ảnh đối chiếu.
- [`rounds.md`](rounds.md): Bảng theo dõi số đo qua 4 vòng lặp chỉnh sửa.
- [`check_result.json`](check_result.json): Kết quả JSON chi tiết của 5 tiêu chí A–E.
- [`compare.png`](compare.png): Ảnh đối chiếu `ảnh gốc | bản lắp | bản đồ khác biệt (heatmap)`.
- [`onion.png`](onion.png): Bản lắp chồng mờ 50/50 lên ảnh gốc.
- [`rotation_grid.png`](rotation_grid.png): Lưới kiểm tra 14 khớp xoay ở `-35°, -20°, +20°, +35°` (không đồ và có đồ da).
- [`leather.png`](leather.png): Ảnh lắp đầy đủ bộ đồ da (`leather_armor`, `leather_helmet`, `reinforced_boots`).
- [`iron.png`](iron.png): Ảnh lắp đầy đủ bộ đồ sắt (`iron_armor`, `iron_helmet`, `climbing_boots`).
