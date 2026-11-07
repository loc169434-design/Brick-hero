# Số đo và các thay đổi theo phản hồi

Giữ nguyên 8 vòng đầu. Sau phản hồi về đè layer và yêu cầu **đầu nguyên ảnh, chỉ căn kích thước**, các bản sửa được đo riêng, không ghi đè kết quả cũ.

| Vòng đầu | IoU thân | IoU da | IoU sắt | Khớp lỗi /78 | Đạt toàn bộ |
|---|---:|---:|---:|---:|---|
| 1 | 0.999359 | 0.983694 | 0.974893 | 3 | Chưa |
| 2 | 0.998187 | 0.877065 | 0.889907 | 4 | Chưa |
| 3 | 0.998187 | 0.853823 | 0.909969 | 4 | Chưa |
| 4 | 0.996304 | 0.937319 | 0.925497 | 0 | Chưa |
| 5 | 0.996304 | 0.986854 | 0.968441 | 0 | Chưa |
| 6 | 0.996317 | 0.987220 | 0.969992 | 0 | Chưa |
| 7 | 0.996317 | 0.986963 | 0.969888 | 0 | Chưa |
| 8 | 0.996504 | 0.986796 | 0.970037 | 0 | Chưa |

| Bản sửa sau phản hồi | IoU thân | IoU da | IoU sắt | Khớp lỗi /78 | Ghi chú |
|---|---:|---:|---:|---:|---|
| 1 | 0.996504 | 0.986767 | 0.969787 | 0 | Loại mặt/tai bị vẽ lại khỏi vật liệu nón |
| 2 | 0.996504 | 0.986767 | 0.969786 | 0 | Khóa vật liệu nón giữa biểu cảm |
| 3 | 0.996504 | 0.984341 | 0.970054 | 2 | Bỏ hẳn ghép mặt, dùng đầu nguyên ảnh |
| 4 | 0.996504 | 0.986466 | 0.969627 | 0 | Căn kích thước theo vùng đầu thật, bỏ ảnh hưởng của điểm alpha nhiễu |

## Tiêu chí còn áp dụng

- IoU thân ≥0.97, đồ ≥0.95; bỏ kiếm REF nới Euclidean 4px khỏi cả hai ảnh. IoU toàn REF + kiếm fixture chỉ tham khảo.
- 28 lớp đồ nằm trong alpha mảnh chủ nới Euclidean 24px. Tất cả PNG game 512×512 RGBA và không chạm mép.
- Khớp ±35°: trong bán kính 20px, không lỗ alpha kín và phải giữ tiếp xúc cha/con; nền tự nhiên ngoài người được ghi riêng. Các matrix theo đúng chuỗi cha/con, đồ đi theo mảnh chủ.
- Bộ đầu hiện tại theo chỉ dẫn mới: một ảnh hoàn chỉnh cho mỗi kiểu/biểu cảm; chỉ crop khoảng trong suốt, resize và đặt nguyên ảnh. Không còn chèn mặt/tai/cằm REF. Vì vậy **không dùng các số cổ/cằm=0 của phương pháp ghép cũ để tuyên bố bộ đầu mới trùng pixel**. Đầu mới đo kích thước/vị trí và xoay cổ.
- Kiểm tra pixel ngoài đồ vẫn giữ ngưỡng MAE≤10/255, P95≤30/255. Phần đầu mới được loại khỏi phép so mặt REF vì người dùng đã chuyển sang gen đầu hoàn chỉnh, chỉ căn kích thước.
- Mask khăn cũ từng nhận nhầm nét viền nâu của áo thành màu đỏ, làm giữ lại nét áo xuyên qua giáp. Bản hiện tại chỉ bảo vệ màu khăn trong vùng khăn thực và owner cape.

Các mask được sửa qua quá trình nên giá trị đăng ký không phải cùng một mask cố định. JSON từng vòng là số đo thực lúc chạy; `iteration_notes.md` và `corrections/baseline_after_8/` giữ lịch sử trước phản hồi.

## Bản hiện tại

- 18/18 đầu nguyên ảnh đạt kích thước/vị trí; 36/36 ảnh xoay đầu ±20° liền cổ theo kiểm tra alpha.
- 78/78 phép xoay bộ cơ bản đạt; 3 bộ giáp mới có 78/78 phép xoay không có lỗ alpha kín quanh khớp.
- leather: pixel vùng thân không mặc đồ — MAE 7.373, P95 36; **chưa đạt** ngưỡng giữ nguyên.
- iron: pixel vùng thân không mặc đồ — MAE 10.783, P95 57; **chưa đạt** ngưỡng giữ nguyên.

Các lần sửa sau ảnh phản hồi và 3 item bổ sung được ghi tách riêng, không đổi số của 8 vòng đầu, không nới ngưỡng. Chưa chứng nhận toàn bộ quy trình trùng pixel ngoài đồ.
