# Nhật ký các vòng tự kiểm tra (`hero_rig_v2`)

Bảng dưới đây ghi lại số đo thực tế từ `docs/ideas/hero_rig_v2/check_rig.py` qua từng vòng chỉnh sửa cho đến khi đạt toàn bộ tiêu chí **A–E**.

| Vòng | IoU (`alpha > 32`) | Sai khác màu TB (`/255`) | Vùng `> 3×3 px` sai `> 40/255` | Số mẫu hở (B) | Lỗi viền (C) | Đồ da / Mặt (D) | Khung 512×512 (E) | Sửa gì |
|---:|---:|---:|---:|---:|---:|---|---|---|
| **1** *(Baseline)* | `0.8743` ❌ | `40.7715` ❌ | `133` ❌ | `23 / 56` (`901 px`) ❌ | `0 / 56` ✅ | Lệch mặt `111/255` ❌ | `26/26` ✅ | Bộ mảnh cũ vẽ lại từ đầu nên lệch hình bóng và màu so với `fresh_idle.png`; khớp xoay chưa có đầu tròn vẽ bù đủ bán kính `20 px`; nón da lấn xuống vùng trán/lông mày. |
| **2** | `0.9842` ✅ | `2.1400` ✅ | `2` ❌ | `4 / 56` (`38 px`) ❌ | `6 / 56` (`47 px`) ❌ | Lệch mặt `0/255` ✅ | `35/35` ✅ | Cắt trực tiếp 17 mảnh từ `fresh_idle.png` khung 0 `(0,0,512,512)` (bỏ kiếm gỗ) theo vùng màu liên thông + đường viền chung; cập nhật toạ độ tâm khớp giải phẫu trong `joints.json`. Còn rò màu nhẹ qua pixel có `alpha` gốc `234..254` và hở nhẹ tại `wrist_sword`, `hip_front`, `ankle_back`. |
| **3** | `0.9986` ✅ | `0.2413` ✅ | `4` ❌ | `0 / 56` (`0 px`) ✅ | `0 / 56` (`0 px`) ✅ | `0 px` tràn, mặt `0/255` ✅ | `35/35` ✅ | Chuẩn hoá `alpha = 255` cho vùng đặc (`alpha >= 230`) của phần nhìn thấy `V[p]`; mở rộng đĩa vẽ bù `H[p]` có viền đậm `4 px` quanh 14 khớp (`r = 23..40 px` cho mảnh dưới, đồng tâm `r = 20..22 px` cho mảnh trên). Gia cố viền `sword_hand` bằng màu viền đậm làm 4 cụm nhỏ tại rìa nắm tay vượt ngưỡng `40/255`. |
| **4** *(Đạt A–E)* | **`0.9963`** ✅ | **`0.0904`** ✅ | **`0`** ✅ | **`0 / 56` (`0 px`)** ✅ | **`0 / 56` (`0 px`)** ✅ | **`0 px` tràn, mặt `0/255`** ✅ | **`35/35`** ✅ | Tinh chỉnh đa giác tách kiếm gỗ ôm sát rìa nắm tay phải (`sword_hand`), giữ nguyên pixel gốc trong vùng chung và đặt lớp viền bịt mối cắt sang phía vùng kiếm đã tách; cắt gọn `y <= 500` để chân đặt chuẩn tại `(256, 500)`; hoàn thiện bộ đồ da (`leather_armor`, `leather_helmet`, `reinforced_boots`) và đồ sắt (`iron_armor`, `iron_helmet`, `climbing_boots`) khớp khít mảnh chủ. |

## Kết luận vòng cuối (Vòng 4)
- **Tiêu chí A (Khớp ảnh gốc)**: Đạt (`IoU = 0.99625 ≥ 0.97`, sai khác màu trung bình `0.0904/255 ≤ 6/255`, `0` vùng `> 3×3 px` có sai khác `> 40/255`).
- **Tiêu chí B (Không hở khi xoay ±35°)**: Đạt `56/56` mẫu (`100%`, `0` pixel mất độ đặc trong bán kính `20 px` quanh khớp).
- **Tiêu chí C (Nét viền liền khi xoay ±35°)**: Đạt `56/56` mẫu (`100%`, `0` pixel loang từ ngoài vào trong thân qua khe khớp).
- **Tiêu chí D (Đồ da & Đồ sắt)**: Đạt (`0` pixel vượt vùng mảnh chủ nới rộng `24 px`; vùng mặt mắt/mũi/miệng giống hệt `100%` so với bản không đồ, sai khác tối đa `0/255`).
- **Tiêu chí E (Canvas & Định dạng)**: Đạt (`35/35` file PNG `512×512` RGBA nền trong suốt, `0` pixel chạm mép canvas).
