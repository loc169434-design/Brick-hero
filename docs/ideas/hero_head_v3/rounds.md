# Kiểm tra bộ đầu ghép lớp

Tối đa 6 vòng; tất cả kích thước tính trên canvas 512×512, neck=(262,237). Giữ đủ 9 asset mới; không sửa/xóa `heads/` cũ. Ngưỡng ngang 1,06 được áp dụng lại đầy đủ cho việc này.

Mask là bao mắt, mày và miệng nới 6 px, **dừng ở biên da theo trả lời của người dùng**. Miếng mặt đặc alpha 255, không feather alpha. Dải màu 3 px ở mép lấy từ da gốc, rồi chuyển màu trong 1 px tiếp theo. Mask được lấp kín các lỗ bên trong để nét mày không chạm vào một mép alpha ở giữa miếng mặt. Phần tai, má, cằm và cổ gốc được bảo vệ pixel khi tách đầu từ ảnh sửa; ảnh sinh nguyên bản và ảnh căn chưa bảo vệ vẫn giữ trong `raw/sources/` để đối chiếu. Không co đầu vào bề ngang cố định.

| Vòng | Nón | Rộng/đầu ≤1,06 | Đỉnh y ≥ tóc gốc | Vành ≤14 px | Cách mày ≥6 px | Mask cách vành ≥4 px | Tóc trên vành / ngoài vùng cho phép | Kết quả |
|---|---|---:|---:|---:|---:|---:|---:|---|
| 1 | leather_helmet | 107/127=0.8425 | 118/105 | 13.00 | -2.78 | 40.44 | 17 / — | CHƯA ĐẠT |
| 1 | iron_helmet | 109/127=0.8583 | 120/105 | 18.74 | -2.62 | 40.81 | 29 / — | CHƯA ĐẠT |
| 2 | leather_helmet | 112/127=0.8819 | 114/105 | 11.25 | -1.50 | 2.21 | 7 / — | CHƯA ĐẠT |
| 2 | iron_helmet | 112/127=0.8819 | 116/105 | 15.34 | 0.00 | 0.00 | 0 / — | CHƯA ĐẠT |
| 3 | leather_helmet | 112/127=0.8819 | 109/105 | 12.00 | 8.00 | 9.06 | 5 / 1337 | CHƯA ĐẠT |
| 3 | iron_helmet | 112/127=0.8819 | 112/105 | 11.36 | 6.54 | 9.00 | 1 / 1949 | CHƯA ĐẠT |
| 4 | leather_helmet | 112/127=0.8819 | 109/105 | 12.00 | 8.00 | 9.06 | 5 / 380 | CHƯA ĐẠT |
| 4 | iron_helmet | 112/127=0.8819 | 112/105 | 11.36 | 6.54 | 9.00 | 1 / 434 | CHƯA ĐẠT |
| 5 | leather_helmet | 112/127=0.8819 | 109/105 | 12.00 | 8.00 | 9.06 | 0 / 5 | CHƯA ĐẠT |
| 5 | iron_helmet | 112/127=0.8819 | 112/105 | 11.36 | 6.54 | 9.00 | 0 / 0 | ĐẠT |
| 6 | leather_helmet | 112/127=0.8819 | 109/105 | 12.00 | 8.00 | 10.00 | 0 / 0 | ĐẠT |
| 6 | iron_helmet | 112/127=0.8819 | 112/105 | 11.36 | 6.54 | 10.41 | 0 / 0 | ĐẠT |

Vòng 1: 9/9 file; mask 8 pixel; mặt phủ kín 100%; mép 3 px lệch tối đa 0/255; tai/má/cằm/cổ lệch tối đa 0/255; khe cổ ±20°: 0 pixel. Tổng: **CHƯA ĐẠT**.

Vòng 2: 9/9 file; mask 3654 pixel; mặt phủ kín 100%; mép 3 px lệch tối đa 214/255; tai/má/cằm/cổ lệch tối đa 0/255; khe cổ ±20°: 0 pixel. Tổng: **CHƯA ĐẠT**.

Vòng 3: 9/9 file; mask 3654 pixel; mặt phủ kín 100%; mép 3 px lệch tối đa 0/255; tai/má/cằm/cổ lệch tối đa 0/255; khe cổ ±20°: 0 pixel. Tổng: **CHƯA ĐẠT**.

Vòng 4: 9/9 file; mask 3654 pixel; mặt phủ kín 100%; mép 3 px lệch tối đa 0/255; tai/má/cằm/cổ lệch tối đa 0/255; khe cổ ±20°: 0 pixel. Tổng: **CHƯA ĐẠT**.

Vòng 5: 9/9 file; mask 3654 pixel; mặt phủ kín 100%; mép 3 px lệch tối đa 0/255; tai/má/cằm/cổ lệch tối đa 0/255; khe cổ ±20°: 0 pixel. Tổng: **CHƯA ĐẠT**.

Vòng 6: 9/9 file; mask 3618 pixel; mặt phủ kín 100%; mép 3 px lệch tối đa 0/255; tai/má/cằm/cổ lệch tối đa 0/255; khe cổ ±20°: 0 pixel. Tổng: **ĐẠT**.

Vòng 5–6 hoàn thiện đường cắt: loại phần khăn lẫn trong crop đầu, giữ vùng trán mới từ ảnh sửa thay cho đường tóc cũ, khép đường cắt vành–mái, giữ tai/khung mặt/cổ gốc. Vòng 6 kiểm tra thêm không có lỗ alpha bên trong cả ba đầu. Bộ nón cuối dùng ảnh sửa vòng 4, không sinh thêm nón ở vòng 5–6.

Vòng 1 phát hiện mask ban đầu chỉ có 8 pixel: alpha của ảnh gốc chủ yếu 253–254, không phải 255. Từ vòng 2, lấy vùng da có alpha>240 từ ảnh gốc, bổ sung kiểm tra đủ landmark mắt/mày/miệng và biểu cảm thật sự khác normal. Alpha đầu ra của **mọi miếng mặt vẫn bắt buộc 255**, không nới tiêu chí phủ kín.

Kiểm tra tóc xét phía trên vành và mọi vùng ngoài nón không thuộc phần tóc được phép: mái ngắn tối đa 12 px dưới vành và hai vùng tóc mai ở thái dương, trước tai. Phần tai/mặt/cổ gốc được bảo vệ và vùng mắt/mày/miệng (mực vẽ cùng màu nâu đậm) loại khỏi phân loại màu tóc; đây là vùng mặt đã được kiểm tra phủ kín bằng miếng da đặc. Tóc sau gáy dài hoặc tua ở sau đầu không được miễn kiểm tra. Bảng màu lấy từ tóc gốc, lượng tử 12 mức/kênh; ứng viên cách màu trung bình ≤18/255 ngoài contour (dung sai AA 1 px) được đánh dấu đỏ (trên vành) và tím (ngoài vùng tóc được phép) ở `fixtures/hair_check_*.png`. Cần xem ảnh cùng contour vì mực viền và da nón có thể gần màu tóc. Contour chỉ dùng đo, không xuất thành trang bị rời.

Sai khác tai/má/cằm/cổ và dải mép mặt là **max từng kênh RGB**, đồng thời kiểm tra alpha ở phần đầu, không lấy trung bình cả nền trong suốt. Cổ xoay được đo bằng số pixel alpha<240 trong bán kính 10 px quanh neck, trên thân thật lắp từ `parts/`.

Chạy lại: `python docs/ideas/hero_head_v3/check_heads.py --round N` (1≤N≤6). Kết quả vòng cuối ở `check.json`; từng vòng và contour ở `checks/`. Script chỉ cần Pillow, NumPy, SciPy.
