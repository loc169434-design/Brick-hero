# Bàn giao bộ đầu ghép lớp

Nhánh `art/hero-head-v3`, từ `origin/core/world-life` tại `0f77e55`. **Đạt ở vòng 6**. Có 4 lượt sửa ảnh nón; vòng 5–6 hoàn thiện cắt lớp, mask và mép nối. Chỉ thay trong `assets/characters/hero_rig/` và thư mục bàn giao này.

Bộ mới có 3 đầu gốc tại `head/`: `bare.png`, `leather_helmet.png`, `iron_helmet.png`; 6 miếng mặt tại `faces/`: `normal.png`, `blink.png`, `angry.png`, `hurt.png`, `happy.png`, `scared.png`. Tất cả 512×512 RGBA, cùng canvas `parts/`, neck=[262,237]. `heads/` cũ và `joints.json` giữ nguyên.

Vẽ `head/<kiểu>.png` trước, rồi `faces/<biểu_cảm>.png` trên cùng tọa độ. Cho cả hai cùng đi theo xương neck; xoay cả cặp quanh [262,237]. Không co đầu hoặc mặt theo bbox của kiểu nón. Không gắn thêm lớp nón cũ.

`bare.png` giữ pixel từ `heads/bare_normal.png`, chỉ bỏ 1.182 pixel alpha nhiễu ngoài đầu. `normal.png` lấy RGB trực tiếp từ bare và đặt alpha=255 trong mask. Năm biểu cảm còn lại lấy đúng các ảnh `docs/ideas/hero_rig_v2/inputs/head_<biểu_cảm>_edit.png`, căn theo tai/mũi/cằm/cổ, rồi cắt cùng mask. Không sinh riêng biểu cảm cho từng nón.

Nón được sửa trên ảnh toàn thân, giữ góc 3/4 quay phải và nét chibi gốc. Ảnh sinh và ảnh đã căn theo thân còn nguyên trong `raw/sources/`. Ảnh cuối `raw/*_raw.png` khóa thân/khung mặt/tai/cằm/cổ bằng pixel gốc khi cắt; vùng trán mới lộ dưới nón dùng ảnh sửa để không chép đường tóc cũ thành một vệt rời. Phần sau nón che gọn tóc, tai vẫn lộ. Không vẽ kiếm.

Mask nới 6 px, dừng ở biên da theo trả lời của người dùng. Miếng mặt đặc alpha 255: mép 3 px giữ RGB da gốc, chuyển màu trong 1 px tiếp theo. Các lỗ nhỏ bên trong mask được lấp kín, không để tạo thêm mép alpha giữa nét mày.

| Số đo cuối | Nón da | Nón sắt | Yêu cầu |
|---|---:|---:|---|
| Rộng nón / rộng đầu | 0.8819 | 0.8819 | ≤1,06 |
| Đỉnh nón y | 109 | 112 | ≥105 |
| Dày vành px | 12.00 | 11.36 | ≤14 |
| Cách mày px | 8.00 | 6.54 | ≥6 |
| Mask cách vành px | 10.00 | 10.41 | ≥4 |
| Tóc trên vành ngoài nón | 0 | 0 | 0 |
| Tóc ngoài vùng được phép | 0 | 0 | 0 |

Đủ **9/9** file; mask **3.618 px**, phủ kín **100%** ở cả 6 mặt; mép 3 px lệch tối đa **0/255** trên cả 3 đầu. Tai/má/cằm/cổ lệch tối đa **0/255**. Cả 6 ca xoay ±20° không có khe trong bán kính 10 px quanh neck (alpha≥240); cả 3 đầu không có lỗ alpha bên trong.

[grid.png](grid.png) là 18 tổ hợp đặt trên thân. [rotate.png](rotate.png) là kiểm tra cổ. [face_mask.png](face_mask.png) là mask cố định. [check.json](check.json) chứa toàn bộ số đo máy đọc; [rounds.md](rounds.md) ghi cả 6 vòng. `fixtures/` có ảnh căn biểu cảm và contour đo để xem lại. Việc phân biệt tóc với mực viền dùng cả màu và vùng giải phẫu; các ảnh kiểm tra tóc cuối không còn điểm đỏ/tím.

Chạy lại từ thư mục repo:

```sh
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_head_v3/prepare_faces.py
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_head_v3/prepare_hats.py --round 6
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_head_v3/build_layers.py --round 6
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_head_v3/check_heads.py --round 6
```

Lệnh cuối trả exit code 0 khi đạt, 1 khi trượt. Script dựng ảnh kiểm tra trên thân từ `parts/`; chưa thay code tải ảnh hay chạy tích hợp trong game. `source_manifest.json` lưu hash nguồn và 9 asset cuối.
