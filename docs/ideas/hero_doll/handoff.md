# Bàn giao hero_doll

Nhánh `art/hero-doll`, từ `origin/core/world-life` tại `270f7cd`. **9/9 mục đạt ở vòng 4**; chưa push trước khi đạt.

Theo chỉ dẫn mới của người dùng: “cắt lại từ ảnh gốc … đừng cắt bằng ảnh đã layer”, nguồn thân là `assets/characters/hero_rookie/anim/fresh_idle.png`, khung 0. Không dùng PNG `hero_rig/parts/`, ảnh ghép rig hoặc các đầu đã ghép làm nguồn thân. `sheet.png` là bảng 17 mảnh được cắt, bù phần khuất và đóng gói, thay cho bước sinh lại cả bộ trong yêu cầu ban đầu.

Đầu chỉ lấy phần trên đường cằm–mang tai, giữ mặt/tóc/tai gốc; cổ nằm trên torso cùng khăn quấn cổ và nút khăn. Cổ đỡ kéo vào dưới đầu để mép kín. Khớp khuất được bù mảng màu và viền khép kín; phần nhìn thấy giữ nét và texture gốc. Tay kiếm cũng cắt từ ảnh gốc, chỉnh góc −29° và tỉ lệ 0,92 để cầm icon dựng thẳng. Khiên được căn tròn từ khiên gốc, nằm trước tay cầm.

Hai bắp tay được đặt trước pelvis/torso trong `order` để thân, khăn và thắt lưng che phần bo vai/khuỷu như ảnh gốc; đầu vẫn sau torso, khiên vẫn ở lớp ngoài cùng. Đây là điều chỉnh chồng mảnh cho cách cắt mới, không sửa code. Cây cha–con kiểm tra giống game: khiên theo cẳng tay khiên, kiếm theo bàn tay kiếm; đầu/áo choàng/tay theo torso, các chân theo pelvis.

Có **16 PNG thân** trong `parts/`, **1 đầu** trong `head/bare.png`, **6 miếng mặt** trong `faces/`, và `joints.json`. Tất cả PNG là 512×512 RGBA, cùng khung, đáy chân y=500. Không sửa `hero_rig/`, không tạo trang bị hay asset kiếm.

| Mục | Số đo cuối | Kết quả |
|---|---|---|
| 1. Định dạng | 23/23 PNG đúng 512×512 RGBA, không chạm mép canvas | ĐẠT |
| 2. Mảnh liền | Mỗi mảnh 1 vùng; tổng 0 lỗ alpha | ĐẠT |
| 3. Viền | 0 điểm vượt khoảng cách 2 px tới mực; lớn nhất 0.00 px | ĐẠT |
| 4. Bụi | 0 điểm alpha 1–63 tách khỏi vùng alpha≥200 | ĐẠT |
| 5. Dáng | IoU 92.769228%; khớp lệch tối đa 6.00 px; chân y=500 | ĐẠT |
| 6. Xoay | 34 tư thế; tối đa 0 pixel trong suốt trong hull toàn thân, bán kính 24 px quanh khớp | ĐẠT |
| 7. Khiên | Phủ 100.000%; khuyết sâu 0.703 px | ĐẠT |
| 8. Kiếm | Tâm rãnh lệch 0 px; nắm tay cao 39 px; khoảng cách đốc chắn–tay 0 px; che chuôi gỗ/sắt/tôi = 99.338%, 99.525%, 99.869% | ĐẠT |
| 9. Mặt | 6 mặt phủ kín 100% mask 3645 px; ngoài mask 0 px; mép 3 px lệch tối đa 0/255 | ĐẠT |

Rãnh chuôi nằm dưới các ngón tay đặc, không khoét lỗ alpha: cách này vừa giữ bàn tay kín vừa che chuôi ≥90%. Vùng chuôi/đốc chắn dùng đo có định nghĩa trong `ICON_REGIONS` của `check_doll.py` và ảnh kiểm tra `fixtures/hilt_mask_*.png`. Không dùng phần cẳng tay để cộng vào tỉ lệ che chuôi của nắm tay.

Mép mực được chấm trên 17 mảnh thân/đầu; 6 miếng da mặt được chấm riêng theo mục 9 để không tạo viền đen quanh miếng mặt. Các biểu cảm lấy từ ảnh đầu vào thô `docs/ideas/hero_rig_v2/inputs/head_<biểu_cảm>_edit.png`, đăng ký theo tai/mũi/cằm/cổ. Chỉ tái dùng thông số căn, không cắt từ ảnh đầu đã layer.

Ảnh bàn giao: [sheet.png](sheet.png), [assembled.png](assembled.png), [rotate_test.png](rotate_test.png), [sword_test.png](sword_test.png), [faces.png](faces.png). [check.json](check.json) chứa số đo đầy đủ; [rounds.md](rounds.md) giữ các vòng; `checks/` có snapshot số đo và hình học từng vòng. `source_frame_0.png` giữ khung nguồn để đối chiếu.

Chạy lại từ thư mục repo (Pillow, NumPy, SciPy):

```sh
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_doll/build_doll.py --round 4
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_doll/check_doll.py --round 4
```

Script kiểm tra trả exit code 0 khi cả 9 mục đạt, 1 khi trượt. Kiểm tra xoay dùng canvas 768 để không cắt mất phần cơ thể ra ngoài khung; hull tính từ toàn hình ghép và cây con xoay theo cha. Chưa đổi loader hay hoạt ảnh trong game.

Bảng mảnh có 17 ô, khoảng cách bbox gần nhất 96.00 px (yêu cầu ≥12 px).
