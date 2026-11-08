# Kế hoạch sprite: bậc trang bị, động tác mới, game nhẹ

Claude viết, ngày 07/11/2026. Thay cho hướng rig xương, 3D và kiếm gắn rời. Mọi nhân vật dùng **hoạt ảnh vẽ từng khung** như cũ. **Gemini vẽ**, Claude viết code và kiểm ảnh bằng script.

## 1. Trang bị: nâng cấp là đổi cả bộ

- **Gộp kiếm và giáp thành một chuỗi "Bậc trang bị".** Mỗi bậc là một bộ trọn gói: kiếm + nón + áo giáp + khiên + giày, vẽ thẳng vào khung hình. Không còn gắn kiếm rời.
- Mua bậc mới thì cả chỉ số lẫn ngoại hình lên bậc đó.
- **Tủ đồ:** được chọn mặc lại bất kỳ bậc nào đã mua, chỉ đổi ngoại hình. Chỉ số luôn lấy theo bậc cao nhất.
- **Rèn kiếm +1/+2/+3** giữ riêng: chỉ cộng sát thương, không cần vẽ.

| Bậc | Mở sau màn | Giá | Sát thương ô đỏ | Giảm mỗi đòn | Đỡ chí mạng |
|---|---|---|---|---|---|
| 0. Tân binh (kiếm gỗ, áo vải) | có sẵn | 0 | 2,0 | 0 | 0% |
| 1. Bộ da | 5 | 70 | 2,25 | 3 | 25% |
| 2. Bộ sắt | 18 | 140 | 2,5 | 5 | 75% |
| 3. Hoàng Gia | 45 | 190 | 3,0 | 7 | 100% |
| 4. Hắc Thép | 65 | 210 | 3,0 | 8 | 100% |
| 5. Băng | 85 | 240 | 3,0 | 9 | 100% |

Tổng giá cả chuỗi là 850 vàng, xấp xỉ 840 vàng của kiếm + giáp trước đây. Đây là số đề xuất, chơi thử rồi chỉnh.

Bản lưu cũ: quy đổi kiếm và giáp đã mua sang bậc tương ứng, phần dư hoàn lại bằng vàng.

## 2. Động tác (hiệp sĩ)

Có sẵn 15 clip: idle, attack, throw, leap, kick, bash, drink, hurt, dizzy, knocked, scared, cheer, victory, defeat, run.

**Thêm mới (đợt 1, vẽ trên bậc 0):**

| Clip | Dùng khi | Khung |
|---|---|---|
| `combo` | Nối dây dài: 3 nhát chém liên hoàn | 16 |
| `block` | Quái đánh, giáp đỡ được: giơ khiên đỡ, lùi nửa bước | 8 |
| `dash` | Lướt tới quái trước đòn đánh | 6 |
| `skill_armor_breaker` | Phá Giáp: nhảy lên, bổ dọc bằng hai tay | 14 |
| `skill_second_wind` | Hồi Quang: quỳ một gối, bừng sáng, đứng dậy | 14 |
| `skill_thunder_slash` | Lôi Trảm: lùi lấy đà, phóng tới chém ngang | 14 |
| `skill_iron_guard` | Hộ Thể: cắm khiên xuống đất, thủ thế | 10 |
| `skill_blade_vortex` | Phong Kiếm: xoay người chém 3 vòng | 16 |
| `skill_starfall_strike` | Tinh Kiếm: nhảy cao, lao xuống đâm | 16 |

Hiệu ứng (sét, ánh sáng, vệt chém) **do code vẽ**, không vẽ vào khung. Như vậy mỗi bậc dùng chung hiệu ứng, khung nhẹ hơn.

## 3. Quái (cả hai phe đều phải đẹp)

- Bổ sung cho đủ bộ chuẩn: `idle, attack, hurt, special, defeat, victory` (trùm thêm `rage`). Còn thiếu: bù nhìn (chỉ có idle/hurt), `orc_chief_enraged`, một số quái phụ.
- Làm lại những clip đánh trông yếu. Danh sách duyệt sau khi xem chạy thử.

## 4. Giữ game nhẹ

- **Khung 384 thay vì 512.** Nhân vật hiện trên màn chỉ cao 360 px, nên 384 là đủ nét, mà bớt 44% điểm ảnh. Gemini vẫn vẽ ở 512, script thu nhỏ khi nhập. Code đọc `frame_size` từ `anim.json`.
- **Bỏ ba mức bầm dập** cho hiệp sĩ ở các bậc mới. Bị đánh nặng thì code thể hiện: thở dốc, đỏ người, mồ hôi. Riêng phần này bớt 2/3 số ảnh.
- **Nén VRAM** (ASTC/ETC2 trên điện thoại) như các sheet hiện tại.
- 12 khung/giây cho động tác chậm, 24 cho đòn đánh. Mỗi clip không quá 16 khung.
- Chỉ nạp sheet của clip đang chạy, đổi bậc thì giải phóng sheet cũ (code đã làm vậy).
- **Dọn đồ cũ:** `hero_rig/`, cảnh rig, poser, sandbox, `hero_doll` chuyển sang nhánh lưu trữ, không nằm trong bản build.

Ước tính mỗi bậc khoảng 25 clip, khoảng 300 khung ở cỡ 384. Mỗi bậc nặng khoảng 10–15 MB trên đĩa, và chỉ những clip đang chạy chiếm bộ nhớ.

## 5. Quy trình với Gemini

1. Claude viết **yêu cầu từng đợt** vào `docs/ideas/sprites/`, Gemini đọc file rồi vẽ.
2. Gemini đẩy lên nhánh `art/...` và **dừng**.
3. Claude chạy `tools/sprites/check_sheet.py`:
   - đúng lưới, đúng số khung;
   - chân đứng đúng điểm (256, 500) ở mọi khung, lệch ≤ 6 px;
   - cỡ người khớp `fresh_idle` (±8%);
   - nền trong suốt, không bụi;
   - không trôi ngang ngoài ý muốn.
4. Claude render ảnh GIF xem trước. Bạn duyệt bằng mắt.
5. Đạt thì Claude gắn vào trận đánh và merge.

## 6. Thứ tự làm

| Đợt | Ai | Việc |
|---|---|---|
| 0 | Claude | Code bậc trang bị + tủ đồ, khung 384, `check_sheet.py`, dọn rig; hủy đợt "xóa kiếm" của ChatGPT. **Xong 07/11.** |
| 1 | Gemini | 9 động tác mới cho bậc 0 (bảng mục 2). **Xong 07/11** |
| 1b | Claude | Gắn động tác vào trận: combo theo độ dài dây, đỡ khiên, lướt tới, kĩ năng |
| 2 | Gemini | Bậc 1 (Bộ da): vẽ lại toàn bộ clip của bậc 0 theo bộ da ([round2_leather.md](ideas/sprites/round2_leather.md)). **Xong 08/11**. Tiếp bậc 2 Bộ sắt ([round3_iron.md](ideas/sprites/round3_iron.md)), rồi bậc 3–5 |
| 3 | ChatGPT | Quái: làm lại 10 quái với bộ 6–7 động tác nhiều khung, nền #FF00FF ([monsters_round1.md](ideas/sprites/monsters_round1.md)). Chạy song song với Gemini |
| 4 | Claude | Đo dung lượng, nén, dọn |
