# Bàn giao ứng viên hero rig v2 — CHƯA ĐẠT TOÀN BỘ

Nhánh `art/hero-rig-v2`, tạo từ `core/world-life` tại `70abdb7`. Đã đọc yêu cầu ở nhánh đó.
Chỉ sửa `assets/characters/hero_rig/` và `docs/ideas/`. Không sửa code, scene, tests, project hoặc icon.

## Kết quả vòng 8

| Kiểm tra | Kết quả | Ngưỡng |
|---|---:|---:|
| IoU thân, bỏ kiếm REF+4px | 0.99650404 — đạt | ≥0.97 |
| IoU thân+đồ da so WEAR cuối | 0.98679561 — đạt | ≥0.95 |
| IoU thân+đồ sắt so WEAR cuối | 0.97003734 — đạt | ≥0.95 |
| IoU toàn REF + kiếm fixture, chỉ tham khảo | 0.99682030 | Không chấm |
| Đồ ngoài owner nới 24px | 0 px — đạt | 0 px |
| Xoay 13 khớp × 2 góc × 3 bộ | 78/78 — đạt | Không hở vùng nối 20px |
| 18 đầu: sai khác cổ/cằm lớn nhất | 0/255 — đạt | ≤6/255 |
| 18 đầu: lệch landmark cùng biểu cảm | 0 px — đạt | ≤2 px |
| Xoay 18 đầu ±20° | 36/36 — đạt | Không hở cổ |
| Bảo toàn pixel WEAR da | MAE 10.194; P95 61 — **trượt** | MAE≤10; P95≤30 |
| Bảo toàn pixel WEAR sắt | MAE 11.010; P95 76 — **trượt** | MAE≤10; P95≤30 |

**Chưa đủ điều kiện coi là bộ rig hoàn thiện.** Các ảnh edit vẫn đổi một số pixel khiên, khăn và tay trần sau phép dịch/co giãn. Đã tạo lại ảnh mặc đồ nhiều lần và đo đủ 8 vòng; không nới tiêu chí. IoU chỉ là hình bóng, không chứng minh màu và đường nét trùng pixel. Việc tách diff còn dùng ngưỡng 12 để tránh nhiễu, nên không khẳng định mọi pixel khác REF đã được trích nguyên vẹn thành đồ.

## 51 ảnh game

- 17 mảnh thân trong `parts/`: cắt trực tiếp REF, giữ pixel phần thấy được; phần khớp bo tròn được bù dưới mảnh đứng trước, không dùng atlas cũ.
- 16 lớp đồ: mỗi bộ armor 4 lớp, mỗi bộ boots 4 lớp. Đồ được tách từ **ảnh sửa nhân vật mặc đồ**, không vẽ item đứng riêng rồi co vào người.
- 18 đầu hoàn chỉnh trong `heads/`: `bare`, `leather_helmet`, `iron_helmet` × `normal`, `blink`, `angry`, `hurt`, `happy`, `scared`. `bare_normal.png` bằng pixel mảnh `parts/head.png`.
- Tất cả 51 ảnh 512×512 RGBA, không chạm mép canvas; xem `asset_validation.json`.
- Đã bỏ `gear/leather_helmet/head.png` và `gear/iron_helmet/head.png`. Đầu có nón thay **toàn bộ** head, không chồng thêm lên tóc. Mọi đầu dùng cùng khớp `neck=[262,237]`.
- `joints.json` giữ nguyên 18 tên và mảng `order`. `grip=[354,318]` nằm giữa nắm tay. `sword_hand` chỉ giữ nắm tay, không có phần đốc/chắn kiếm lộ ra.

Không vẽ kiếm mới, không thêm `parts/sword.png`. Kiếm cắt REF chỉ ở `fixtures/ref_sword.png`; dùng cho review tại slot `sword`, nằm sau nắm tay. Trong game dùng icon có sẵn.

## Ảnh review

- [compare_bare.png](compare_bare.png): REF | lắp thân + kiếm fixture. Điểm đạt/trượt vẫn chỉ dùng thân ngoài mask kiếm+4px.
- [compare_leather.png](compare_leather.png), [compare_iron.png](compare_iron.png): WEAR cuối | lắp thân + đồ + đầu normal tương ứng, kèm kiếm fixture.
- [compare_ingame_sword.png](compare_ingame_sword.png): REF | icon `wood_sword`, điểm `(128,186)` trùng grip, scale chính xác `210/256`, không thêm phép xoay. Không chấm điểm ảnh này.
- [rotation_grid.png](rotation_grid.png): 13 khớp ±35°, ba trạng thái bare/leather/iron; không có kiếm.
- [icon_vs_rig.png](icon_vs_rig.png): icon gốc chỉ đặt bên cạnh để đối chiếu, không dùng làm layer đồ.
- [heads_grid.png](heads_grid.png): đúng 3 hàng kiểu nón × 6 cột biểu cảm.
- [heads_neck_rotation.png](heads_neck_rotation.png): cả 18 đầu ±20°.
- [rounds.md](rounds.md): toàn bộ số đo, các vòng trượt và giới hạn kiểm tra.

## Nguồn và tái tạo

REF là vùng `(0,0,512,512)` của sprite idle gốc, đối chiếu pixel lại từ asset thật. Các input image edit nguyên bản nằm trong `inputs/`, không chỉnh chúng để làm giả chỉ số. Lưới biểu cảm cũ là thử nghiệm lỗi đã lưu để truy vết; bản cuối dùng năm file `head_*_edit.png` riêng. Cổ/cằm, mũi và khung mặt giữ từ REF; chỉ chuyển nội thất mắt/mày/miệng từ ảnh sửa. Hai nón được sửa từ đầu bare và giữ tóc gọn bên trong.

`wear_*_body_registered.png` là ảnh edit thân đã căn, trước thay đầu. `wear_*.png` là WEAR cuối sau khi bỏ đầu cũ và gắn ảnh đầu hoàn chỉnh theo yêu cầu bổ sung. Số đo raw và cuối đều có trong JSON. Sự thay đầu này không sửa pixel khiên/khăn/tay trần để che lỗi; các lỗi đó vẫn làm kết quả cuối trượt.

```sh
OPENBLAS_NUM_THREADS=1 python3 docs/ideas/hero_rig_v2/build_v2.py --round 8
python3 docs/ideas/hero_rig_v2/write_report.py
```

Cần Pillow, NumPy, SciPy, font DejaVu Sans. Script không gọi imagegen/network; dùng các input đã lưu. Tái tạo vòng 8 không phải một vòng vẽ thứ 9. Các vòng lịch sử đã dùng phiên bản phân vùng khác, được giữ trong JSON và ghi chú; không dùng script cuối để thay số cũ.

## Ghép vào nhánh code

Nhánh ảnh không sửa `HeroRig`. Bên code cần chọn **một** `heads/<helmet>_<expression>.png` thay head skin, giữ neck và toàn bộ bone transform; không tải nón theo đường overlay cũ. Chọn đúng bộ armor/boots cho mỗi slot, không cộng da và sắt cùng lúc. Đồ phải dùng cùng matrix với mảnh chủ, giữ nguyên canvas. Chưa xác nhận tích hợp gameplay hoặc animation trong Godot.

Phần còn lại cần làm riêng: sửa chính xác vùng bị đổi ngoài đồ trong ảnh WEAR, rồi tách lại lớp và kiểm tra lại toàn bộ; bản hiện tại được push để xem và tiếp tục, **không phải dấu duyệt đạt toàn bộ tiêu chí**.
