# Tuyệt kĩ riêng của từng bộ giáp

Claude viết, 11/11/2026. Đây là đề xuất, sẽ chỉnh sau khi chơi thử.

## Luật

- Mỗi bộ giáp (trừ Tân binh) có **một tuyệt kĩ riêng**, chỉ dùng được khi đang mặc bộ đó.
- Ở lò rèn vẫn chọn một kĩ năng như cũ. Tuyệt kĩ của bộ đang mặc là **một lựa chọn thêm** trong danh sách đó, hiện có viền màu của bộ.
- Tuyệt kĩ dùng chung thanh nộ với kĩ năng thường. Không có thanh thứ hai, nên giao diện không phải thay đổi.
- Mặc lại bộ cũ trong tủ đồ thì dùng được tuyệt kĩ của bộ đó. Vì thế mua bộ mới vẫn có lý do giữ bộ cũ.
- Tuyệt kĩ **chỉ vẽ trên đúng bộ của nó**: mỗi bộ thêm 1 clip, không phải 5.

## Năm tuyệt kĩ

| Bộ | Clip | Tên | Làm gì trong trận | Dáng (16 khung, 24 fps) |
|---|---|---|---|---|
| Bộ da | `skill_tumble_cut` | LỘN CHÉM | Đánh như 6 ô đỏ, rồi **giải hết độc** | Lộn nhào về trước một vòng, bật dậy chém hất từ dưới lên ở khung 10, rồi về thế đứng |
| Bộ sắt | `skill_shield_charge` | KHIÊN PHÁ | Đánh như 4 ô đỏ, **phá 2 lớp khiên** của quái, đẩy đòn quái lùi 1 lượt | Cúi thấp, khiên chắn trước, lao tới húc ở khung 8, lùi về |
| Hoàng Gia | `skill_royal_rally` | HIỆU LỆNH | **Hồi 8 máu**, và 3 lượt tới ô đỏ mạnh thêm 50% | Cắm khiên xuống, giơ kiếm thẳng lên trời, há miệng hô to ở khung 8, giữ 3 khung, hạ kiếm |
| Hắc Thép | `skill_obsidian_cleave` | HẮC TRẢM | Đánh như 12 ô đỏ, **xuyên khiên**, nhưng mất 3 máu | Hai tay vung kiếm ra sau lưng, xoay hông, bổ chéo xuống ở khung 9, mũi kiếm cắm đất, rút lên |
| Bộ Băng | `skill_frost_nova` | BĂNG PHONG | Đánh như 4 ô đỏ, **đóng băng quái 2 lượt** (đòn quái lùi 2 lượt) | Nhảy nhẹ, hai tay cắm kiếm xuống đất ở khung 7, quỳ một gối giữ kiếm 4 khung, đứng dậy |

Hiệu ứng (vệt chém, băng lan, hào quang, đá vỡ) **do code vẽ**, không vẽ vào khung.

## Vẽ

- Vẽ cùng cỡ, cùng điểm chân (256, 500) như các clip khác của bộ. Khung đầu và khung cuối là dáng `idle` của bộ.
- Đặt file vào thư mục của bộ: `assets/characters/hero_rookie/anim/<bộ>/fresh_<clip>.png`.
- Hắc Thép: Gemini, trong đợt 5 ([sprites/round5_obsidian.md](sprites/round5_obsidian.md)).
- Băng, cùng ba clip bù cho da, sắt, Hoàng Gia: Gemini Carbon, trong đợt 6 ([sprites/round6_frost.md](sprites/round6_frost.md)).

## Code (Claude, sau khi có ảnh)

- Thêm 5 tuyệt kĩ vào `BattleState.SKILLS` và `Gear.ITEMS[<bộ>]["skill"]`.
- Lò rèn hiện tuyệt kĩ của bộ đang mặc.
- Gắn clip và hiệu ứng vào trận.
- Viết test cho từng hiệu ứng.
