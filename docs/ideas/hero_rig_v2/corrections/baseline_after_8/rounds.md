# Số đo 8 vòng — giữ nguyên ngưỡng

IoU thân: ≥0.97; IoU mặc đồ: ≥0.95. Loại vùng kiếm REF nới Euclidean 4px ở **cả hai ảnh**.
IoU toàn REF với kiếm fixture chỉ tham khảo. Mỗi lớp đồ phải nằm trong alpha mảnh chủ nới Euclidean 24px.
Vùng không mặc đồ: MAE RGB ≤10/255 và P95 sai số kênh lớn nhất ≤30/255, chọn từ đầu và không nới.

| Vòng | IoU thân | IoU da | IoU sắt | Khớp lỗi /78 | MAE kiểm tra da/sắt | P95 da/sắt | Kết luận |
|---|---:|---:|---:|---:|---:|---:|---|
| 1 | 0.999359 | 0.983694 | 0.974893 | 3 | 15.674/17.474 | 85/96 | TRƯỢT |
| 2 | 0.998187 | 0.877065 | 0.889907 | 4 | 33.570/21.518 | 170/124 | TRƯỢT |
| 3 | 0.998187 | 0.853823 | 0.909969 | 4 | 33.570/21.518 | 170/124 | TRƯỢT |
| 4 | 0.996304 | 0.937319 | 0.925497 | 0 | 10.502/12.300 | 48/56 | TRƯỢT |
| 5 | 0.996304 | 0.986854 | 0.968441 | 0 | 8.541/9.601 | 45/49 | TRƯỢT |
| 6 | 0.996317 | 0.987220 | 0.969992 | 0 | 6.819/7.701 | 33/34 | TRƯỢT |
| 7 | 0.996317 | 0.986963 | 0.969888 | 0 | 8.988/11.421 | 59/91 | TRƯỢT |
| 8 | 0.996504 | 0.986796 | 0.970037 | 0 | 10.194/11.010 | 61/76 | TRƯỢT |

## Bộ đầu

| Vòng | Sai khác cổ/cằm lớn nhất /255 | Lệch landmark lớn nhất px | Xoay cổ đạt /36 |
|---|---:|---:|---:|
| 2 | 0 | 0 | 36 |
| 3 | 0 | 0 | 36 |
| 4 | 0 | 0 | 36 |
| 5 | 0 | 0 | 36 |
| 6 | 0 | 0 | 36 |
| 7 | 0 | 0 | 36 |
| 8 | 0 | 0 | 36 |

Các kiểm tra số về cổ/landmark không bắt được lỗi nền trong biểu cảm ở vòng 2–4; các vòng đó **không được duyệt hình**. Vòng 5 thay lưới bằng năm ảnh sửa biểu cảm riêng; lưới cuối đã được xem lại.

## Cách hiểu và các thay đổi qua vòng

- Vòng 1: cắt pixel REF, thử hai ảnh edit toàn thân. Vòng 2–3: thêm 18 đầu, sửa bbox nón và căn biểu cảm.
- Vòng 4: thử ảnh sửa chỉ áo/ủng; phần bù hông đã liền khi xoay, nhưng biểu cảm còn lỗi nền.
- Vòng 5: thay bằng các ảnh edit biểu cảm riêng; dùng ảnh đầu hoàn chỉnh trong WEAR cuối theo yêu cầu bổ sung. Giữ ảnh edit thân đã căn, trước thay đầu, ở `wear_*_body_registered.png`. Không sửa mặt/khiên/khăn/tay trên bản raw để giả vờ đạt.
- Vòng 6: bỏ phần đốc kiếm lẫn vào nắm tay, tối ưu dịch/co giãn theo MAE + P95.
- Vòng 7: sửa chủ của vạt áo/thắt lưng về pelvis; đo bảo toàn pixel trên WEAR cuối có đầu thay thế. Chỉ thay đối tượng đo theo yêu cầu đầu mới, không đổi ngưỡng; số raw vẫn có trong JSON. Mở rộng mask khăn.
- Vòng 8: phần bù khớp không đè lên owner đứng trước; đệm cổ dùng màu cổ. Mask bảo vệ bao gồm cả viền khiên, nắm tay và cẳng tay từ pixel cắt thật. Vẫn TRƯỢT kiểm tra pixel vùng không mặc đồ.

Các mask/thuật toán được sửa qua vòng nên không coi các giá trị đăng ký là cùng một mask cố định; mask vòng cuối nằm trong `protected_pixels.png`. `iteration_notes.md` giữ ghi chú tại thời điểm chạy. Các JSON là số thực của từng vòng; script hiện tại tái tạo vòng cuối.

## Phương pháp kiểm tra

- Alpha IoU dùng alpha >127; mask kiếm được tạo từ REF rồi nới 4px, lưu trong `fixtures/sword_exclusion_4px.png`.
- Khớp ±35°: xét đĩa bán kính 20px, không lỗ alpha kín, cha/con có phần chồng và một vùng tiếp xúc liên thông. Nền tự nhiên ngoài nét người không phải khe nối; số pixel nền được ghi riêng trong JSON. Các mảnh con kế thừa matrix cha; đồ được ghép vào mảnh chủ trước khi xoay.
- Cổ/cằm: dải biên trong 3px của cằm, trong 40px trên neck, cộng vùng cổ, **không bao gồm nội thất miệng** vì miệng phải đổi biểu cảm. Mask chính xác ở `fixtures/neck_chin_mask.png`. So cả RGBA, ngưỡng ≤6.
- Landmark: so khớp template mắt/miệng/mũi của cùng biểu cảm giữa ba kiểu đầu, tìm dịch ±3px, yêu cầu ≤2px. Mũi và đường mặt giữ theo REF; phần nón không được kéo mặt đi.
- Tóc: kiểm tra nguồn pixel tóc REF, tính bất biến phần nón trên trán giữa sáu biểu cảm, và kiểm tra bằng mắt hai ảnh edit đầu có nón. `fixtures/hair_visual_review.json` khóa SHA của hai đầu được duyệt. Đây là kiểm tra provenance + duyệt hình, **không phải bộ phân loại tóc tự động theo màu** (tóc và nón da đều nâu). Không thấy lọn tóc nhô lên hay xuyên nón trong lưới cuối.
- 16 lớp đồ là các pixel thay đổi đáng kể (sai khác RGBA >12 để loại nhiễu nhỏ), chia theo owner, cắt trong owner+24. Pixel raw ngoài đồ vẫn có độ lệch: đây là lý do không chứng nhận toàn bộ quy trình đã đạt.

Đã dùng đủ 8 vòng; không làm vòng thứ 9 hoặc hạ ngưỡng để đổi kết quả.
