# Thời tiết và ngày đêm – Brickbound Hero

Viết ngày 2026-11-06 theo ý người chơi: nền trận đánh phải động, có sáng, trưa, chiều, tối, mưa, sấm sét. Thời tiết làm trận khó đoán hơn và thưởng cho người biết tận dụng, nhưng **không đổi luật gốc**. Mọi con số là đề xuất, chạy bot (`tests/sim_balance.gd`) trước khi chốt.

---

## 1. Hai lớp: giờ trong ngày và thời tiết

Mỗi trận có **một giờ** và **một kiểu trời**. Màn chơi khai báo những gì có thể xảy ra, game bốc ngẫu nhiên khi vào trận, nên chơi lại cùng một màn có thể gặp trời khác.

| Giờ | Nhìn thế nào | Ảnh hưởng |
|---|---|---|
| **Sáng** | Nắng sớm vàng nhạt, sương mỏng, chim bay | Bình thường |
| **Trưa** | Sáng rõ, bóng ngắn | Bình thường |
| **Chiều** | Hoàng hôn cam, bóng dài | Ô vàng ra **+50% vàng** |
| **Tối** | Trăng, sao, đom đóm; thỉnh thoảng **một đôi mắt đỏ** sáng lên trong bụi rậm rồi tắt | Quái chí mạng sớm hơn 1 đòn. Ô ở mép bảng chìm trong bóng tối: thấy hình nhưng mờ màu, ô sét làm sáng một vùng quanh nó |

| Trời | Nhìn thế nào | Ảnh hưởng |
|---|---|---|
| **Quang** | — | Bình thường |
| **Mưa** | Mưa xiên rơi trước nền, vũng nước gợn, nhân vật ướt nhẹ | Ô xanh lá hồi **+50%**. **Ô sét mạnh hơn**: quét thêm một hàng và một cột kề bên |
| **Giông** | Mưa nặng hạt, chớp lóe sáng cả màn hình, sấm rền | Như mưa, cộng: mỗi 4 lượt **một tia sét đánh xuống bảng**, biến một ô thường thành ô sét. **Tuyệt chiêu hệ sét** (Lôi Trảm) mạnh **×1,5**, có hiệu ứng tia điện quanh kiếm |
| **Sương mù** (vùng núi, Suối Nguồn) | Sương trôi ngang qua nền và bảng | Một vài ô bị sương che, chỉ thấy viền; sương tan dần theo lượt |

**Buff có hiệu ứng:** khi trời đang giúp người chơi, biểu tượng thời tiết cạnh thanh máu sáng lên, và ô hoặc chiêu được tăng có viền sáng riêng (ô sét lấp lánh điện khi mưa, ô vàng ánh cam lúc chiều). Người chơi nhìn là biết nên nối gì.

## 2. Trận đánh theo vùng

| Vùng | Trời có thể gặp |
|---|---|
| Bãi tập (màn 1–5) | Sáng, trưa. Luôn quang, để học chơi |
| Trại Orc | Sáng, trưa, chiều; đôi khi mưa |
| Đầm lầy | Chiều, tối; hay mưa, đôi khi giông |
| Rừng đen | Gần như luôn tối; mắt đỏ nhiều hơn |
| Vùng núi | Sáng, chiều; sương mù, giông |
| Suối Nguồn | Giờ đổi ngay trong trận (theo chủ đề thời gian) |
| Hang rồng | Tối, giông; ánh lửa |

Trùm và màn đố có thể **khóa** một kiểu trời cho đúng truyện (ví dụ Mụ Phù Thủy Cóc luôn đánh lúc chập tối có mưa).

## 3. Cách làm

**Code (Claude):**
- `LevelData.times`, `LevelData.weathers`: danh sách có thể bốc; `BattleState.time_of_day`, `weather`.
- Hệ số trong `BattleRules` cho từng buff, để bot đo.
- Hiển thị:
  - đổi màu cả cảnh theo giờ (lớp phủ màu, bóng nhân vật dài ngắn theo giờ);
  - hạt mưa, chớp và sấm;
  - đôi mắt đỏ chớp tắt ngẫu nhiên ở các điểm nền khai báo;
  - bóng tối và sương trên bảng;
  - biểu tượng thời tiết trên thẻ màn và cạnh thanh máu.
- Tia sét đánh xuống bảng dùng lại hiệu ứng sét có sẵn.

**Ảnh (ChatGPT):**
- Với mỗi nền: lớp `sky` cho 4 giờ (`sky_morning`, `sky_noon`, `sky_dusk`, `sky_night`), cùng bố cục, chỉ đổi trời, ánh sáng và màu.
- Danh sách điểm đặt **mắt đỏ** trong `layers.json`, và ảnh đôi mắt (6 khung: mở, chớp, nhắm).
- Mưa xiên (lặp được), vệt chớp, tia sét đánh xuống, sương trôi, biểu tượng 6 kiểu trời.
- Nền mới cho các vùng sau theo `docs/campaign_100.md`, vẽ đúng quy tắc mặt đất ở mục 4.

## 4. Quy tắc vẽ nền trận đánh (áp cho mọi nền mới)

Rút ra từ góp ý "nhân vật đứng lơ lửng" ở nền đầm lầy và trại Goblin:
- Canvas 1080×660. Chân hiệp sĩ tại (270, 405), chân quái tại (810, 405).
- **Có mặt đất phẳng liền mạch** ở dải y 380–480, nhìn hơi chếch từ trên xuống (thấy mặt sàn), có viền đậm ở mép trên.
- Không có vật cao ngay sau lưng hai nhân vật; chòi, cây, cột đẩy ra mép hoặc ra xa.
- Màu đậm, ấm như trại Orc; sáng nhất ở giữa sàn, tối dần ra mép.
- Giữ nguyên phong cách và nhân vật của game, chỉ vẽ lại nền.

## 5. Thứ tự

1. Code khung thời tiết với hình tạm (đổi màu theo giờ, mưa, chớp), bật cho vùng đầm lầy, đo bằng bot.
2. ChatGPT vẽ trời 4 giờ và mắt đỏ cho các nền đã có, sửa nền đầm lầy và trại Goblin theo mục 4.
3. Bật dần cho các vùng sau, cùng lúc với nền mới của vùng đó.

Trạng thái 2026-11-07: bước 2 xong (issue #49), phần hình đã ghép cho cả bốn nền hiện có. Giờ và trời được bốc theo bảng mục 2 (`Weather.REGIONS`), màn 36 khóa chiều mưa. Chưa có: các buff ở mục 1, bóng tối và sương trên bảng, tia sét biến ô thành ô sét.
