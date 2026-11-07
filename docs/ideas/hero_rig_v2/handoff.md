# Hero rig v2 — đầu nguyên ảnh và giáp bổ sung

Nhánh `art/hero-rig-v2` từ `core/world-life` tại `70abdb7`. Chỉ thay `assets/characters/hero_rig/` và `docs/ideas/`; không sửa code, scenes, tests, project hay icon có sẵn.

## Theo phản hồi mới nhất

**Không ghép mặt REF vào đầu có nón nữa.** Mỗi đầu là một ảnh liền nét: lấy kết quả image edit hoàn chỉnh, chỉ bỏ khoảng trong suốt rồi resize/đặt nguyên ảnh cho vừa vị trí đầu. Không cắt mắt/mũi/tai/cằm để dán lên ảnh khác. `bare_normal` vẫn là mảnh head cắt REF. 17 biến thể còn lại là 17 ảnh sửa nguyên đầu.

- `heads/<bare|leather_helmet|iron_helmet>_<normal|blink|angry|hurt|happy|scared>.png`: đủ 18 ảnh, cùng canvas 512×512.
- Khung đặt đầu thật được lấy từ vùng alpha chính của REF, không tính các điểm alpha nhiễu ở xa. Đầu không bị kéo ngang do nhiễu nền như bản sửa 3.
- Không có `gear/leather_helmet/head.png` hay `gear/iron_helmet/head.png`; khi chọn đầu mới phải **thay head texture**, không vẽ thêm lên head cũ.
- Nét áo cũ xuyên giáp được sửa bằng mask khăn đúng vùng, và đưa vạt áo/thắt lưng về owner pelvis. Giữ nguyên mảng `order` và tên 18 khớp.

## Item giáp mới

| ID | Tên | Asset |
|---|---|---|
| `royal_armor` | Giáp Hoàng Gia | 4 lớp rig + icon riêng |
| `obsidian_armor` | Giáp Hắc Thép | 4 lớp rig + icon riêng |
| `frost_armor` | Giáp Băng | 4 lớp rig + icon riêng |

Mỗi bộ trong `gear/<id>/` có `torso`, `shield_arm_upper`, `sword_arm_upper`, `pelvis`. Icon ở `item_icons/<id>.png`, cũng 512×512 RGBA. **Rig được tách từ ảnh sửa nhân vật mặc giáp 3/4**, không lấy icon đứng riêng để ghép lên người. Các icon inventory được tạo sau cùng, chỉ dùng cho danh mục item.

`new_items.json` kê đường dẫn và slot `armor`. Chưa đặt giá, chỉ số hay mốc mở khóa; chưa đăng ký vào danh mục game vì phạm vi nhánh chỉ ảnh/docs. Preview dùng chung đầu sắt normal và ủng leo núi.

## Review

- [heads_grid.png](heads_grid.png): 3 hàng kiểu đầu × 6 biểu cảm, tất cả là đầu nguyên ảnh.
- [new_items_grid.png](new_items_grid.png): icon và dáng mặc của ba item mới.
- [compare_bare.png](compare_bare.png), [compare_leather.png](compare_leather.png), [compare_iron.png](compare_iron.png): REF/WEAR cuối đặt cạnh bản lắp.
- [head_layer_detail.png](head_layer_detail.png): phóng tai/gáy trước và sau, không còn hai mặt/tai chồng nhau.
- [armor_layer_detail.png](armor_layer_detail.png): phóng giáp và vạt, không còn áo xanh che vạt giáp như ảnh phản hồi cũ.
- [rotation_grid.png](rotation_grid.png), [new_items_rotation_grid.png](new_items_rotation_grid.png): bộ cơ bản và ba item mới xoay ±35° theo bone cha/con.
- [heads_neck_rotation.png](heads_neck_rotation.png): 18 đầu ±20°.
- [compare_ingame_sword.png](compare_ingame_sword.png): icon gốc, điểm (128,186) trùng grip, scale 210/256, không thêm phép xoay. Chỉ xem, không chấm điểm.

## Số đo hiện tại và giới hạn

- IoU thân bỏ kiếm+4px: **0.996504**, ngưỡng ≥0.97.
- IoU da: **0.986466**; sắt: **0.969627**, ngưỡng ≥0.95.
- 66 PNG game: 17 mảnh thân, 28 lớp đồ, 18 đầu hoàn chỉnh, 3 icon item; tất cả RGBA 512×512. 0 pixel đồ ngoài owner+24px.
- Các kiểm tra pixel vùng thân không mặc đồ **vẫn chưa đạt đầy đủ**; không dùng IoU hình bóng để khẳng định màu/viền trùng pixel. Xem [rounds.md](rounds.md) và JSON raw/cuối. Bộ đầu mới không ép pixel cổ/mặt bằng REF theo chỉ dẫn mới nhất của người dùng.
- Asset item đã có; chưa xác nhận tích hợp gameplay hoặc chạy animation thực trong Godot. Giá/chỉ số và việc load đầu mới cần bên code tích hợp.

Không có kiếm mới trong assets. Kiếm cắt REF chỉ ở `fixtures/ref_sword.png`, sau nắm tay ở slot sword; mask kiếm được nới 4px khi chấm. `grip=[354,318]`, `neck=[262,237]`.

## Tái tạo

```sh
OPENBLAS_NUM_THREADS=1 python3 docs/ideas/hero_rig_v2/build_v2.py --round 8 --correction 4
OPENBLAS_NUM_THREADS=1 python3 docs/ideas/hero_rig_v2/build_new_items.py
python3 docs/ideas/hero_rig_v2/write_report.py
```

Cần Pillow, NumPy, SciPy, DejaVu Sans. Các script dùng input image edit đã lưu, không gọi network. Nguồn cũ và 8 vòng đầu được giữ để truy vết, không dùng số 0 cổ/cằm của cách ghép cũ để duyệt ảnh mới.

Bên code: thay đúng một head texture theo kiểu nón/biểu cảm; giữ nguyên offset neck, không thêm sprite đầu lên đầu cũ. Mỗi item armor gắn bốn lớp vào đúng bone; không cộng hai bộ armor cùng lúc. Map icon mới và đăng ký ba ID trong catalog theo cân bằng do người dùng/bên code quyết định.
