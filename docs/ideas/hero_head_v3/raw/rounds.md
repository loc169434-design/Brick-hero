# Số đo từng vòng — tối đa 5 vòng sửa ảnh

Bản bàn giao dùng **vòng 5**. Hai nón chính và một biến thể da ranger đều là ảnh sửa toàn thân từ ảnh gốc. Hậu kỳ chỉ dịch/co giãn toàn ảnh theo thân (y ≥ 240). Không cắt lớp hay ghép mặt; không chép lại pixel thân để ép sai số.

Từ vòng 3, người dùng yêu cầu nón trung cổ ngầu hơn và cho phép không quá bó đầu. Vì vậy tỷ lệ ngang 1,06 vẫn được báo cáo, nhưng không còn là điều kiện đánh trượt. Vòng 4–5 sửa lại nét cho cùng phong cách nhân vật: viền nâu đậm, mảng màu lớn và bóng cel đơn giản. Các ngưỡng còn lại giữ nguyên.

Cố định từ đầu: ngang trán y=158, bề ngang đầu 127 px; đỉnh tóc y=105; đỉnh lông mày y=161; khoảng đo vành trước x=257…305. Contour nón và hai mép vành được đánh dấu thủ công trên ảnh đã căn. Chiều dày là khoảng cách vuông góc xấp xỉ giữa hai đường vành. Số đo phụ thuộc độ chính xác contour; các overlay được lưu để kiểm tra lại.

MAE ngoài vùng sửa có đơn vị **0…255**: lấy trung bình bốn kênh RGBA, với RGB nhân alpha/255. Vùng sửa bao gồm nón và phần tóc gốc cần giấu. Phép đo có cả nền trong suốt; vì vậy báo thêm MAE RGB chỉ trên foreground ngoài vùng sửa. MAE toàn vùng đạt không đồng nghĩa mặt/thân giữ nguyên từng pixel.

Ngưỡng giữ nguyên: MAE ≤ 6; đỉnh nón y ≥ 105; vành ≤ 14 px; cách lông mày ≥ 6 px; không có pixel tóc phía trên vành nằm ngoài contour nón. Khoảng cách mày âm nghĩa là đáy vành thấp hơn mốc đỉnh mày gốc.

| Vòng | Nón | MAE ngoài | MAE foreground, tham khảo | Rộng / đầu | Đỉnh y | Dày vành px | Cách mày px | Pixel gần màu tóc ngoài viền | Kết quả |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | leather | 2.034 | 10.287 | 112/127=0.8819 | 123 | 18.00 | -9.00 | 0 | CHƯA ĐẠT |
| 1 | iron | 2.223 | 10.967 | 111/127=0.8740 | 123 | 15.00 | -12.00 | 0 | CHƯA ĐẠT |
| 2 | leather | 2.433 | 12.348 | 97/127=0.7638 | 130 | 12.17 | -5.00 | 0 | CHƯA ĐẠT |
| 2 | iron | 2.486 | 12.528 | 94/127=0.7402 | 136 | 11.00 | -5.00 | 23 | CHƯA ĐẠT |
| 3 | leather | 1.800 | 8.654 | 123/127=0.9685 | 109 | 18.00 | -5.00 | 15 | CHƯA ĐẠT |
| 3 | iron | 1.707 | 8.568 | 142/127=1.1181 | 108 | 18.50 | 0.00 | 8 | CHƯA ĐẠT |
| 3 | leather_ranger | 1.696 | 8.265 | 141/127=1.1102 | 110 | 21.38 | -2.00 | 15 | CHƯA ĐẠT |
| 4 | leather | 3.272 | 17.040 | 132/127=1.0394 | 108 | 14.21 | -4.00 | 0 | CHƯA ĐẠT |
| 4 | iron | 3.570 | 18.702 | 143/127=1.1260 | 97 | 25.81 | -4.00 | 25 | CHƯA ĐẠT |
| 4 | leather_ranger | 3.196 | 16.647 | 142/127=1.1181 | 111 | 16.53 | -10.00 | 0 | CHƯA ĐẠT |
| 5 | leather | 2.490 | 12.222 | 131/127=1.0315 | 106 | 12.00 | -6.00 | 0 | CHƯA ĐẠT |
| 5 | iron | 2.572 | 13.052 | 136/127=1.0709 | 107 | 17.86 | -0.21 | 0 | CHƯA ĐẠT |
| 5 | leather_ranger | 2.600 | 13.209 | 139/127=1.0945 | 108 | 11.00 | -1.00 | 0 | CHƯA ĐẠT |

Màu tóc lấy từ tóc gốc, lượng tử 12 mức/kênh. Đếm pixel alpha > 127 phía trên đường vành, ngoài contour nón (dung sai viền AA 1 px), có khoảng cách màu RGB trung bình ≤ 18 tới bảng màu tóc. Màu tóc, mực viền và da nón có thể gần nhau: xem ảnh `sources/hair_check_*` có điểm đỏ và overlay contour. Ở vòng 5, contour được sửa để bao đúng mực viền nón từng bị nhận nhầm là tóc; giữ bản contour và số đo nháp trong `sources/*r5*draft.json`. Không sửa pixel ảnh khi chỉnh contour.

Kiểm tra neo: nón thuộc cùng thành phần alpha với nhân vật và điểm cổ (262,237) còn đục. Cả ba bản cuối đều đạt kiểm tra này; đây là kiểm tra ảnh raw, chưa phải thử gắn vào rig của game.

**Kết quả vòng cuối: CHƯA ĐẠT toàn bộ tiêu chí.** Cả ba còn chưa đạt khoảng cách vành–mày 6 px. Nón sắt còn dày vành 17,86 px, vượt 14 px. Tỷ lệ ngang nón sắt 1,0709 và ranger 1,0945 vượt giới hạn ban đầu 1,06; giới hạn này đã được người dùng nới ở vòng 3. Không nới các ngưỡng còn lại. Dừng sau đúng 5 vòng sửa ảnh theo giới hạn yêu cầu, bàn giao bản raw để duyệt hình dáng và nét vẽ.

Chạy lại phép đo vòng cuối từ thư mục repo:

```sh
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_head_v3/raw/check.py --round 5
```

Cần Python, Pillow, NumPy và SciPy. Nguồn ảnh sinh, thông số căn toàn ảnh và contour từng vòng nằm trong `sources/`; kết quả máy đọc nằm trong `metrics_r1.json` đến `metrics_r5.json`. Chạy vòng khác sẽ xuất lại ảnh bàn giao của vòng đó; chạy vòng 5 sau cùng để khôi phục bản cuối.
