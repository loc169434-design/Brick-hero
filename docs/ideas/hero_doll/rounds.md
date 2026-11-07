# Kiểm tra bộ mảnh hiệp sĩ

Theo trả lời mới, cắt trực tiếp từ `fresh_idle.png`, khung 0; không dùng ảnh rig đã ghép. Đầu cắt theo cằm–mang tai, cổ thuộc torso; khiên ở lớp trước tay cầm. `sheet.png` là bảng đóng gói 17 mảnh cắt/bù khớp, không phải ảnh sinh mới. Thay đổi quy trình nguồn này đến từ chỉ dẫn mới của người dùng, không tự nhận đã thực hiện bước sinh 17 mảnh một lần trong yêu cầu cũ.

Giữ nguyên ngưỡng của 9 mục. Riêng hốc chuôi là khoảng nằm dưới ngón tay đặc, không khoét alpha: mảnh phải liền và chuôi bị che ≥90%. Khung mặt nới theo vùng da, mép 3 px giữ RGB đầu gốc. Xoay kiểm tra cả cây con trên canvas 768, hull lấy từ toàn bộ hình ghép, không dùng hull cục bộ hay lấp pixel trong phép đo.

| Vòng | 1 Định dạng | 2 Liền | 3 Viền | 4 Bụi | 5 Dáng | 6 Xoay | 7 Khiên | 8 Kiếm | 9 Mặt | Tổng |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ĐẠT | ĐẠT | ĐẠT | ĐẠT | TRƯỢT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | TRƯỢT |
| 2 | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT |
| 3 | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT |
| 4 | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT | ĐẠT |

Vòng 1: IoU 0.922451; độ lệch khớp tối đa 6.00px; đáy chân y502; khe tối đa 0px; phủ tròn khiên 100.000000%; khuyết khiên 0.703px; chuôi bị che wood/iron/tempered = 99.338%/99.525%/99.869%; mép mặt lệch 0/255.

Vòng 2: IoU 0.924880; độ lệch khớp tối đa 6.00px; đáy chân y500; khe tối đa 0px; phủ tròn khiên 100.000000%; khuyết khiên 0.703px; chuôi bị che wood/iron/tempered = 99.338%/99.525%/99.869%; mép mặt lệch 0/255.

Vòng 3: IoU 0.927692; độ lệch khớp tối đa 6.00px; đáy chân y500; khe tối đa 0px; phủ tròn khiên 100.000000%; khuyết khiên 0.703px; chuôi bị che wood/iron/tempered = 99.338%/99.525%/99.869%; mép mặt lệch 0/255.

Vòng 4: IoU 0.927692; độ lệch khớp tối đa 6.00px; đáy chân y500; khe tối đa 0px; phủ tròn khiên 100.000000%; khuyết khiên 0.703px; chuôi bị che wood/iron/tempered = 99.338%/99.525%/99.869%; mép mặt lệch 0/255.

Các số đo từng mảnh, từng tư thế và icon nằm trong `check.json`, lịch sử từng vòng ở `checks/`. Các vùng hilt/guard dùng để chấm nằm trong `ICON_REGIONS` của script và có ảnh kiểm tra ở `fixtures/hilt_mask_*.png`. Sai khác màu dùng max từng kênh, không lấy trung bình cả nền.
