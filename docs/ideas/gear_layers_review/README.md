# Xem thử lớp trang bị — bản nháp chưa đủ kiếm attack

Xem [bàn giao và phần còn thiếu](../gear_layers_handoff.md) trước khi ghép.

| Mức | idle, 12 fps | attack, 24 fps — chưa có kiếm |
|---|---|---|
| fresh | [GIF](fresh_idle_comparison.gif) | [GIF](fresh_attack_comparison.gif) |
| bruised | [GIF](bruised_idle_comparison.gif) | [GIF](bruised_attack_comparison.gif) |
| battered | [GIF](battered_idle_comparison.gif) | [GIF](battered_attack_comparison.gif) |

Mỗi GIF <2 MB. Thứ tự từ trái sang phải: không đồ / đồ da với kiếm sắt / đồ sắt với kiếm thép. Các ô attack có nhãn `sword missing`, không phải bộ đồ đầy đủ. GIF làm tròn thời gian theo chuẩn 1/100 giây: idle 670 ms/vòng, attack 500 ms/vòng.

[Kiếm gỗ idle ở ba mức](wood_sword_idle_wear.gif): xem riêng việc chuôi nằm sau ngón tay và lưỡi gỗ gãy ở battered.

Lưới đánh số: `<mức>_<clip>_<bộ>_frames.png`, với `<bộ>` là `none`, `leather`, `iron`. Mỗi khung xem thử 256×256, cùng tỷ lệ; số khung bắt đầu từ 00. Đây là ảnh xuất từ alpha-composite các lớp, không phải ảnh mẫu vẽ lại để che lỗi.

[Kết quả kỹ thuật](technical_checks.json) / [hash và ghi chú nguồn](validation.json). Kiểm tra kỹ thuật không thay cho duyệt viền, mặt, góc nón, mép ủng hay cảm giác động tác.

`compose_frame.py` là helper ngoài game: chỉ crop cel rồi chồng PNG tại (0,0). `validate_layers.py` kiểm tra cả sự đầy đủ và báo lỗi cho những lớp còn thiếu. Không thay đổi game hoặc test hiện có.
