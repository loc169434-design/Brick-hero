# Số đo từng vòng

Ngưỡng cố định: IoU thân không kiếm ≥0.97; IoU mặc đồ ≥0.95; lớp đồ ngoài mảnh chủ +24px =0.
Vùng kiếm REF được nới Euclidean 4px ở cả hai ảnh trước khi chấm IoU.
Giữ nguyên pixel vùng không mặc đồ: MAE RGB ≤10/255 và P95 sai số kênh lớn nhất ≤30/255.
Khớp: xét bán kính 20px, không lỗ alpha kín, cha/con phải có diện tích chồng >0 và một thành phần tiếp xúc. Nền ngoài cơ thể không được gọi là khe hở; số pixel nền vẫn ghi riêng.

| Vòng | Thân IoU | Da IoU | Sắt IoU | MAE da/sắt | Khớp lỗi /78 | Ngoài chủ+24 | Kết luận |
|---|---:|---:|---:|---:|---:|---:|---|
| 8 | 0.996504 | 0.986466 | 0.969627 | 7.373/10.783 | 0/78 | 0 | TRƯỢT |

Bản sửa — đầu nguyên ảnh: 18/18 đúng kích thước/vị trí; không ghép khuôn mặt. Xoay cổ: 36/36.
