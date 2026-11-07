# Bàn giao rig hiệp sĩ — đợt 1 + 2 / issue #30 phần 2

Nhánh: `art/hero-rig`, tạo từ `main` tại `6604efa9bcc9a9515537b02fac87776e82adb875`.
Đã đọc `AGENTS.md` trên main và `docs/ideas/hero_rig_request.md` tại nhánh
`core/world-life`, commit `fe570208151329eefc2d243e8b3cc5f645a2d22a`.
Đợt 2 đã đọc lại cả yêu cầu và bàn giao trên `core/world-life` tại
`70abdb7` trước khi vẽ đồ sắt.
Chỉ bổ sung `assets/` và `docs/ideas/`; không sửa code, scene, tests hay project.

## Nội dung

- `assets/characters/hero_rig/parts/`: đủ 17 PNG mảnh cơ thể theo danh sách yêu cầu.
- `gear/leather_armor/`: torso, hai vai, pelvis (4 lớp).
- `gear/leather_helmet/head.png`: nón da mở mặt, không phủ mắt/mũi/miệng.
- `gear/reinforced_boots/`: hai ống chân và hai bàn chân (4 lớp).
- `gear/iron_armor/`: torso, shield_arm_upper, sword_arm_upper, pelvis (4 lớp).
- `gear/iron_helmet/head.png`: nón thép xám bạc, mở mặt.
- `gear/climbing_boots/`: back_leg_lower, back_foot, front_leg_lower, front_foot (4 lớp).
- Tổng cộng **35 PNG 512×512 RGBA**, không có kiếm. Không chỉnh icon kiếm có sẵn.
- `joints.json`: 18 tọa độ khớp và thứ tự chồng lớp. Tọa độ tuyệt đối trong canvas,
  trục x sang phải, y xuống dưới, gốc trái trên; chân y=500, gốc mặt đất (256,500).
  Điểm (256,500) là gốc giữa hai chân, không phải một pixel phải có màu.

Các mảnh được vẽ thành bộ rời theo thiết kế khung 0 của `fresh_idle.png`, rồi đóng gói
vào canvas chung. Giữ tóc nâu, mặt cười, áo xanh, dây đeo chéo, khăn đỏ và khiên gỗ.
Đây là bản vẽ lại cho cut-out, không phải phép phân rã pixel khớp tuyệt đối ảnh idle gốc.
Đầu mảnh tay/chân được vẽ bo tròn và chồng sâu vào mảnh bên cạnh.
Ảnh nguồn phục vụ tái tạo là `hero_rig_review/source_atlas.png` và
`equipment_atlas.png`; đồ sắt đợt 2 dùng `iron_equipment_atlas.png`. Các ô không dùng trong atlas không phải asset bàn giao.

## Ảnh tự kiểm tra

Trong [hero_rig_review/](hero_rig_review/):

- [assembled_bare.png](hero_rig_review/assembled_bare.png): chồng 17 mảnh, không đồ.
- [assembled_leather.png](hero_rig_review/assembled_leather.png): đủ giáp da, nón da, ủng gia cố.
- [assembled_iron.png](hero_rig_review/assembled_iron.png): giáp sắt, nón sắt và ủng leo núi.
- [joints_overlay.png](hero_rig_review/joints_overlay.png): đủ 18 chấm đỏ, tên và tọa độ.
- [rotation_test.png](hero_rig_review/rotation_test.png): bản mặc đồ **sắt** mới nhất, 13 khớp tay/chân/cổ,
  mỗi khớp −35° và +35°. Khớp con đi theo cha; đồ đi theo mảnh chủ.
- [rotation_test_iron.png](hero_rig_review/rotation_test_iron.png): bản có tên riêng của review đồ sắt.
- [rotation_test_leather.png](hero_rig_review/rotation_test_leather.png): giữ review đồ da đợt 1.
- [rotation_test_bare.png](hero_rig_review/rotation_test_bare.png): cùng phép xoay,
  bỏ đồ để nhìn rõ chỗ nối bên dưới.
- `validation.json`: kích thước, mode và alpha bounding box của từng PNG.
- `joint_contact_checks.json`: 117 kiểm tra tiếp xúc cục bộ (13 khớp × 3 góc × 3 trạng thái: bare/leather/iron).
  Mỗi kiểm tra lấy 49 mẫu trong đĩa bán kính 4 px tại tâm khớp; alpha <200 là khe hở.
  Kiểm tra này chỉ chứng minh vùng tiếp xúc nhỏ quanh tâm, không thay cho xem toàn nét viền.

Đã xem ảnh ghép và ảnh xoay. Không có nền, bóng đổ hay phần chạm mép canvas trong
35 lớp bàn giao; cả ba bản ghép chạm đường đất y=500.
Đợt 2 hoàn thành đủ 9 lớp đồ sắt/ủng leo núi. Giáp và nón theo icon có mặt thép
xám bạc, mép đinh tán; ủng theo icon là da nâu, dây đan sáng, khóa và móc bám
kim loại xám bạc. Mỗi lớp là trang bị riêng, không chứa cơ thể hay kiếm.
Không đổi `joints.json`, 17 mảnh thân hoặc 9 lớp đồ đợt 1; chỉ thêm đồ vào
đúng canvas và cùng transform với mảnh chủ.
Đợt ảnh không bổ sung animation hay sửa tích hợp gameplay.

## Ghép bên nhánh code

Giữ nguyên canvas mỗi lớp, không trim ảnh khi import. Đặt texture lệch âm tọa độ khớp
của bone tương ứng; đọc `joints.json` thay vì dùng tọa độ placeholder mặc định.
Thứ tự `order` có slot `sword` để rig gắn icon sẵn có; không có `parts/sword.png`.
Trang bị cần chồng **ngay trên mảnh chủ**, cùng transform, trước mảnh kế tiếp.
Các khớp vai/khuỷu/gối đã được đặt theo nét vẽ mới, không sao chép nguyên placeholder.

Tái tạo ảnh đóng gói và báo cáo từ root repo:

```sh
python3 docs/ideas/hero_rig_review/build_review.py
```

Helper dùng Pillow, NumPy, SciPy và font DejaVu Sans của hệ thống; chỉ đóng gói ảnh
nguồn, ghép lớp, xoay để kiểm tra và xuất báo cáo. Không sinh clip hay thay đổi code game.

## Nội dung comment đợt 1 để đăng vào issue #30 (lưu lịch sử)

> Bàn giao phần 2 “đồ hiện lên người hiệp sĩ” theo yêu cầu rig xương tại
> `docs/ideas/hero_rig_request.md` trên `core/world-life`.
>
> Nhánh **art/hero-rig** từ main: đủ **17 mảnh cơ thể + 9 lớp đồ da/ủng**, toàn bộ
> PNG RGBA 512×512 nền trong suốt, dùng chung canvas, chân tại gốc (256,500).
> Có `joints.json` đủ 18 khớp và thứ tự chồng lớp. Không vẽ kiếm.
>
> Review tại `docs/ideas/hero_rig_review/`: `assembled_bare.png`,
> `assembled_leather.png`, `joints_overlay.png`, `rotation_test.png` và
> `rotation_test_bare.png`. Đã kiểm tra 26 lớp và 78 phép thử tiếp xúc cục bộ tại khớp.
> Bộ sắt và `assembled_iron.png` dành đợt sau. Đây là bản vẽ lại cho rig,
> chưa tích hợp gameplay; Claude đọc tọa độ thực trong JSON và gắn đồ lên từng bone.
>
> Chi tiết và cách tái tạo review: `docs/ideas/hero_rig_handoff.md`.

GitHub API bị chính sách mạng trả `Forbidden` trước khi ghi comment. Theo chỉ dẫn của
người dùng, không thử lại API; giữ nội dung comment tại đây để người dùng đăng vào
[issue #30](https://github.com/loc169434-design/Brick-hero/issues/30).

## Ghi chú bàn giao đợt 2

Đồ sắt đợt 2 nằm trên cùng nhánh `art/hero-rig`. Nhánh code chỉ cần nhận ba thư mục
`iron_armor`, `iron_helmet`, `climbing_boots` dưới `assets/characters/hero_rig/gear/`.
Các file cùng tên mảnh chủ được gắn lên cùng bone như đồ da. Không cộng dồn cả
lớp da lẫn lớp sắt: chọn một món cho mỗi slot, như các ảnh ghép trong review.

Ảnh xoay là kiểm tra hình học từng khớp tại ±35°, không phải hoạt ảnh gameplay.
Chưa kiểm tra trực tiếp trong rig của nhánh code; phạm vi nhánh ảnh không thay đổi.
