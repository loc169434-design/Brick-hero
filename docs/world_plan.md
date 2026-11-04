# Kế hoạch thế giới – Brickbound Hero

Viết ngày 2026-11-04, sau khi trận đánh với Orc đã có hoạt hình từng khung (PR #22, #25).
Mục tiêu giai đoạn này: **từ một trận đánh thành một chuyến phiêu lưu**. Đi qua từng vùng đất, mỗi vùng một loại quái và một kiểu combo mới. Giữa các vùng có lò rèn nâng cấp đồ, và những đoạn truyện tranh kể chuyện chính. **Cái kết (hang rồng, cứu công chúa) chưa làm**, chỉ chừa chỗ.

Các con số dưới đây là **đề xuất**. Mỗi quái mới phải chạy bot mô phỏng (`tests/sim_balance.gd`) rồi chơi thử trên điện thoại trước khi chốt.

---

## 1. Câu chuyện

Công chúa bị bắt. Hiệp sĩ tân binh cầm kiếm gỗ lên đường, đi từ bãi tập ra trại Orc, qua rừng Goblin, xuống đầm lầy của mụ phù thủy cóc. Trong rừng đen là ngôi nhà bánh của ba chị em phù thủy chuyên bắt trẻ con: hiệp sĩ cứu bọn trẻ, và một đứa biết đường lên núi. Vượt núi bằng những câu đố cổ, phía bên kia là hang rồng (để sau).

Giọng kể vui, kiểu truyện cổ tích nhại. Ba phù thủy đáng sợ nhưng **không máu me**: trẻ con bị nhốt trong lồng chờ "vỗ béo", không có cảnh ăn thịt.

**Truyện tranh:** cuối mỗi vùng, và ở đoạn ngôi nhà ba phù thủy, có một chương truyện tranh.
- Khung **dọc kiểu webtoon**, vuốt lên để đọc, hợp màn hình điện thoại dọc.
- Ảnh khung không có chữ. Bong bóng thoại do game vẽ, nên chữ tiếng Việt sửa được bất cứ lúc nào.
- Có hiệu ứng nhẹ: khung trượt vào, rung khi có tiếng động, chữ comic tiếng Anh (BOOM, CREAK…).

---

## 2. Các vùng đất

| # | Vùng | Quái | Trùm | Combo học được | Nâng cấp mở ra |
|---|---|---|---|---|---|
| 0 | **Lâu đài & bãi tập** | Bù nhìn | — | Nối 3, hàng 4 tự nổ | — |
| 1 | **Trại Orc** (đồng cỏ) | Orc Khiên, Orc Ném Đá | Tù Trưởng Orc | **Sét** (nối 5) phá khiên | Kiếm sắt, giáp da |
| 2 | **Rừng Goblin** | Goblin Móc Túi, **Goblin Cung Độc** | Goblin Đầu Đảng | **Bom** (nối 6), hợp thể sét + bom | Nón da, giáp sắt |
| 3 | **Đầm lầy Cóc** | Cóc Nhảy, Thạch Băng | **Mụ Phù Thủy Cóc** (2 mạng) | **Sao** (nối 7), hợp thể sao + bất kỳ | Kiếm thép, nón sắt |
| 4 | **Rừng đen: ngôi nhà ba phù thủy** | — | **Ba chị em phù thủy** | Hợp thể sét + sét | Rèn kiếm +1 (tăng sát thương) |
| 5 | **Vùng núi** | Người Đá Gác Cầu, Dơi Hang | Câu đố cổng núi | Bom + bom (nổ 5×5) | Ủng leo núi |
| 6 | **Hang rồng** | — | Rồng Giữ Vương Miện | — | *Để sau* |

Mỗi vùng có **3–5 điểm dừng** trên bản đồ: vài trận thường, một trận trùm, và có thể có lò rèn, rương hoặc chương truyện.

### Mỗi quái một combo khắc chế

Mỗi quái mới vừa đe dọa theo một kiểu, vừa có một cách chơi "khắc" nó. Người chơi học combo của vùng bằng chính con quái đó.

| Quái | Đe dọa | Khắc chế |
|---|---|---|
| Orc Khiên | Khiên dày giảm nửa sát thương | Tím + sét phá khiên |
| Orc Ném Đá | Đá trúng đầu, choáng 1 lượt | Nón; hạ trước khi nó đủ đếm ngược |
| **Goblin Cung Độc** | Bắn nhanh (đếm ngược 2), mũi tên **độc**: mất máu mỗi lượt trong 3 lượt | **Xanh lá giải độc**; nón chặn mũi tên đầu tiên; bom hạ nhanh vì máu ít |
| Goblin Móc Túi | Đánh dấu ô vàng, đòn sau lấy vàng | Nối ô vàng bị đánh dấu trước khi nó đánh |
| Cóc Nhảy | Nhảy lên ngồi đè ô, ô đó không nối được | Nối ô bên cạnh để cóc giật mình nhảy đi; sao quét cả bảng |
| Thạch Băng | Đóng băng 2 ô | Nối sát ô băng để làm tan |
| Người Đá | Biến ô thành đá, phải phá 2 lần | Bom, bom + bom |

**Cung thủ khó hơn:** quái cung đánh nhanh, ít máu, đứng xa nên không bị húc khiên đẩy lùi, và mũi tên gây thêm trạng thái. Người chơi buộc phải chọn: hạ gọn trước khi nó bắn, hay chịu đòn và giải độc.

---

## 3. Hai trận trùm mới

### Mụ Phù Thủy Cóc: 2 mạng

- **Mạng 1, mụ phù thủy:** 90 máu, 2 khiên, đánh 14 mỗi 3 lượt.
  - Chiêu: thả 2 con cóc lên bảng.
  - Khi hết máu: ngã, rồi uống lọ thuốc và **biến thành cóc khổng lồ**. Có chữ comic và rung màn hình.
- **Mạng 2, cóc khổng lồ:** 70 máu, không khiên, đánh 10 mỗi 2 lượt.
  - Chiêu: thè lưỡi nuốt 1 ô đặc biệt của người chơi.
  - Khi chết: phì ra lại thành mụ già bé xíu, bỏ chạy.
- Đổi mạng ở cuối lượt, theo đề xuất pha rồng trong `docs/ideas/monsters.md`: bỏ sát thương dư, mạng mới bắt đầu đủ đếm ngược, không đánh lén lúc đổi.
- Thanh máu hiện **2 vạch tim** để người chơi biết còn một mạng nữa.

### Ngôi nhà ba phù thủy

Vào nhà là một chương truyện tranh: nhà bánh gừng, lồng trẻ con, nồi cháo sôi. Sau đó đánh **ba trận liên tiếp**, máu hiệp sĩ không hồi giữa các trận. Mỗi trận thắng thì thả một lồng trẻ con.

| Chị em | Chiêu | Gợi ý cách thắng |
|---|---|---|
| Bà Cả, phù thủy lửa | Đốt 1 ô; ô cháy lan sang bên cạnh sau 2 lượt | Nối qua ô cháy để dập |
| Bà Hai, phù thủy mực tím | Khóa 1 màu trong 1 lượt (đề xuất cũ `rune_witch`) | Giữ sẵn một đường màu khác |
| Bà Út, phù thủy nồi cháo | Mỗi 3 lượt hồi máu cho chính mình, trừ khi bị đánh trúng đúng lượt đó | Dồn sát thương vào lượt nó định hồi |

Về sau có thể làm trận **cả ba cùng lúc** (bảng nhắm từng mụ). Việc đó cần sửa code trận đánh cho nhiều quái, nên để sau.

---

## 4. Vùng núi: giải đố

Vùng núi đổi nhịp: ít đánh nhau, nhiều câu đố.

- **Bảng đố:**
  - bảng xếp sẵn, giới hạn số lượt, có mục tiêu. Ví dụ: phá 4 tảng đá trong 10 lượt; đưa chìa khóa rơi xuống đáy bảng; dọn hết băng;
  - không có quái, nhưng thua thì chơi lại ngay;
  - thưởng vàng hoặc mảnh bản đồ.
- **Cổng núi:** gom đủ 3 mảnh bản đồ từ 3 câu đố thì mở đường lên hang rồng.
- **Cần gạt trên bản đồ:** chọn đường. Đường ngắn có trận khó, đường dài có rương.
- Người Đá Gác Cầu và Dơi Hang chặn giữa các câu đố để vẫn có trận đánh.

---

## 5. Trang bị và lò rèn

Bốn ô trang bị. Mỗi ô dùng món tốt nhất đang đeo. Mua ở lò rèn bằng vàng, giá đề xuất trong `docs/ideas/monsters.md`.

| Ô | Các bậc | Tác dụng |
|---|---|---|
| **Vũ khí** | Kiếm gỗ → kiếm sắt → kiếm thép | Mỗi ô đỏ gây 2 → 2.5 → 3 sát thương |
| **Rèn kiếm** | +1, +2, +3 (vùng 4 trở đi) | Mỗi bậc thêm 0.25 sát thương mỗi ô đỏ: đây là phần "tăng đame" |
| **Giáp** | Không → giáp da → giáp sắt | Mỗi đòn quái giảm 2 → 4 |
| **Nón** (mới) | Không → nón da → nón sắt | Nón da chặn mũi tên độc đầu tiên mỗi trận; nón sắt thêm chống choáng khi bị ném đá |
| **Ủng** | Ủng gia cố → ủng leo núi | Giảm thêm 1 mỗi đòn; ủng leo núi mở lối tắt trên núi |

**Hình nhân vật theo đồ:** hiện có `hero_rookie` (kiếm gỗ) và `hero_iron` (kiếm sắt, giáp sắt).
- Tránh phải vẽ mọi tổ hợp đồ: thân nhân vật đổi theo **giáp**, còn **kiếm và nón** vẽ thành lớp riêng chồng lên tay và đầu, giống cách khiên Orc đang làm.
- Mỗi lớp có tọa độ theo từng khung hoạt hình.

---

## 6. Thứ tự làm

Mỗi bước là một PR có thể chơi được. Chơi thử xong mới qua bước sau.

| Bước | Nội dung | Code (Claude) | Ảnh và chữ (ChatGPT) |
|---|---|---|---|
| **W0** | **Chơi thử trên điện thoại** | Bản web trên GitHub Pages | — |
| **W1** | Khung chiến dịch | Bản đồ bấm được, lưu tiến độ, chuỗi trận, vàng giữ lại sau trận | Bản đồ có sẵn (`world_map.png`); thêm biểu tượng vùng |
| **W2** | Lò rèn | Cảnh lò rèn, 4 ô trang bị, chỉ số đổi theo đồ | Biểu tượng nón; lớp kiếm và nón chồng lên nhân vật |
| **W3** | Truyện tranh | Trình đọc truyện dọc, bong bóng thoại, chương mở đầu | Khung truyện chương mở đầu (vua, công chúa bị bắt) |
| **W4** | Vùng 1 đủ quái | Tù Trưởng Orc, Orc Ném Đá | Hai quái mới, đủ hoạt hình |
| **W5** | Rừng Goblin | Trạng thái **độc**, quái cung, đánh dấu ô vàng | Goblin Cung Độc, Goblin Móc Túi, Goblin Đầu Đảng, nền rừng, bộ gạch goblin |
| **W6** | Đầm lầy Cóc | Ô có cóc ngồi, ô băng, **trùm 2 mạng** | Cóc Nhảy, Thạch Băng, Mụ Phù Thủy Cóc 2 dạng, nền đầm lầy |
| **W7** | Ngôi nhà ba phù thủy | Ô cháy, khóa màu, quái tự hồi máu, chuỗi 3 trận | Chương truyện tranh ngôi nhà, ba phù thủy, nền trong nhà |
| **W8** | Vùng núi | Bảng đố (bảng xếp sẵn, giới hạn lượt, mục tiêu), ô đá, cần gạt | Người Đá, Dơi Hang, nền núi, biểu tượng câu đố |
| — | Hang rồng và cái kết | *Để sau* | *Để sau* |

Đã có sẵn để dùng: ảnh bản đồ và các điểm dừng (`assets/bg/world_map.*`), sảnh vua, lò rèn, vua, công chúa, thợ rèn, `hero_iron`, biểu tượng 6 món đồ. Ngoài ra có đề xuất 4 quái và rồng ở `docs/ideas/monsters.md`. Thạch Băng, Goblin Móc Túi, Người Đá và Phù Thủy Mực Tím ở đó được xếp vào các vùng 2, 3, 4, 5 phía trên.

---

## 7. Còn để ngỏ

- Tên các vùng và nhân vật: tạm đặt, ChatGPT đề xuất tên hay hơn.
- Thua giữa vùng thì sao: chơi lại trận đó (đề xuất) hay về đầu vùng.
- Vàng có đủ mua đồ đúng nhịp không: cần bot chơi cả chiến dịch để đo.
- Trận ba phù thủy cùng lúc: làm sau, nếu ba trận liên tiếp thấy chưa đã.
