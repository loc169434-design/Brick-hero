# Kế hoạch 100 màn – Brickbound Hero

Viết ngày 2026-11-05. Mở rộng [world_plan.md](world_plan.md) từ 15 điểm dừng thành **100 màn**, mỗi màn một thử thách riêng như Candy Crush: lúc đánh quái, lúc phá vật cản, lúc cứu người, lúc giải đố. Câu chuyện, các vùng và trận trùm của `world_plan.md` vẫn giữ, chỉ trải dài ra và thêm một vùng (Mỏ pha lê) trước hang rồng.

Mọi con số là **đề xuất ban đầu**. Mỗi màn phải chạy bot (`tests/sim_balance.gd`) đạt tỉ lệ thắng mục tiêu ở mục 8 rồi mới chốt, và chơi thử trên điện thoại theo từng vùng.

---

## 1. Hình dung chung

- **Bản đồ dọc rất dài**, cuộn từ dưới lên như Candy Crush: 8 vùng, 100 nút. Mỗi vùng một đoạn bản đồ vẽ riêng, nối liền nhau.
- **Mỗi màn có một mục tiêu**, ghi rõ trên thẻ trước khi vào: "Hạ Orc Khiên", "Phá 12 tảng băng", "Đưa 3 chú thỏ xuống đáy"… Quái vẫn đứng phía trên bàn chơi và đánh trả, trừ màn đố và màn thưởng.
- **Sao 1–3** sau mỗi màn, tính theo máu còn lại hoặc số lượt còn dư. Sao đổi được rương và sách chiêu (mục 6).
- **Nhịp răng cưa**: trong một vùng, độ khó tăng dần, có 2–3 màn khó đánh dấu đỏ trên bản đồ; sau trùm là một màn dễ hoặc màn thưởng để thở.
- **Mỗi vùng dạy một thứ mới** theo bốn bước: giới thiệu một mình → luyện cùng thứ đã biết → ghép với thứ khác → trùm dùng tất cả.

---

## 2. Tám kiểu màn chơi

| Mã | Kiểu | Thắng khi | Thua khi | Giống Candy Crush ở chỗ |
|---|---|---|---|---|
| **ĐÁNH** | Đánh quái | Quái hết máu | Hiệp sĩ hết máu | — (lõi của game) |
| **ĐỢT** | Nhiều đợt quái | Hạ hết 2–3 quái nối tiếp, máu không hồi giữa đợt | Hết máu | Màn nhiều mục tiêu |
| **LƯỢT** | Đua lượt | Hạ quái trong N lượt | Hết lượt hoặc hết máu | Giới hạn nước đi |
| **GOM** | Thu thập | Gom đủ N ô một màu hoặc N vật phẩm phủ trên ô | Hết lượt hoặc hết máu | Màn "gom kẹo" |
| **PHÁ** | Phá vật cản | Phá hết băng, đá, thùng… trên bảng | Hết lượt hoặc hết máu | Màn "thạch" |
| **CỨU** | Đưa xuống đáy | Đưa lồng, chìa khóa, xe goòng rơi xuống hàng cuối | Hết lượt hoặc hết máu | Màn "nguyên liệu" |
| **ĐỐ** | Câu đố | Đạt mục tiêu trên bảng xếp sẵn, ô mới rơi theo thứ tự cố định | Hết lượt | Màn ít lượt, có lời giải |
| **THƯỞNG** | Màn thưởng | Hết lượt (luôn thắng), càng nhiều vàng càng nhiều sao | — | Màn bonus |

Trùm là một màn **ĐÁNH** có nhiều pha. Một màn có thể kết hợp, ví dụ PHÁ + ĐÁNH: phá đủ vật cản **và** hạ quái.

---

## 3. Vật cản trên bảng

Vật cản là một lớp phủ trên ô (đã chừa sẵn chỗ "hình phủ" trong `cell.gd`). Mỗi loại có cách phá riêng để người chơi phải nghĩ.

| Vật cản | Vùng | Cách hoạt động | Cách phá | Kiểu Candy Crush |
|---|---|---|---|---|
| **Thùng gỗ** | 1 | Chiếm chỗ một ô, không nối được | Nổ ô cạnh 1 lần | Hộp đường |
| **Ô đá** (đá Orc ném) | 1 | Như thùng, rơi xuống từ đòn quái | Nổ ô cạnh 1 lần | — |
| **Mạng nhện** | 2 | Ô vẫn có màu nhưng bị dính, không rơi, không nối được | Nối ô cạnh hoặc nổ trúng | Cam thảo khóa |
| **Bom hẹn giờ** | 2 | Ô có số đếm; về 0 thì nổ vào hiệp sĩ | Nối trúng ô đó trước khi hết giờ | Bom đếm ngược |
| **Ô vàng bị đánh dấu** | 2 | Đòn sau của Goblin lấy vàng theo số ô đánh dấu còn lại | Nối các ô đó | — |
| **Băng** (1–2 lớp) | 3 | Phủ trên ô, ô bên dưới vẫn nối được | Nối hoặc nổ ô đó, mỗi lần bớt 1 lớp | Thạch |
| **Cóc ngồi** | 3 | Cóc đè ô, không nối được, nhảy sang ô khác mỗi 2 lượt | Nối ô cạnh làm cóc giật mình nhảy đi; sao quét | — |
| **Bùn lan** | 3 | Lượt nào không phá bùn thì bùn lan sang 1 ô cạnh | Nổ ô cạnh | Sô-cô-la lan |
| **Kẹo đường cứng** (1–3 lớp) | 4 | Khối kẹo quanh nhà bánh | Nổ ô cạnh, mỗi lần bớt 1 lớp | Kem trứng |
| **Lửa lan** | 4, 7 | Ô cháy, sau 2 lượt lan sang ô cạnh; mỗi ô cháy đốt 1 máu mỗi lượt | Nối qua ô cháy để dập | — |
| **Khóa màu** | 4 | Một màu không nối được trong 1 lượt | Chờ hết lượt; có màu khác để nối | — |
| **Đá nhiều lớp** (2–3 lớp) | 5 | Như thùng nhưng cứng | Bom, bom + bom | Kem trứng |
| **Pha lê** (3 lớp) | 6 | Vỡ thì bắn mảnh làm nứt ô cạnh | Nổ ô cạnh | — |
| **Sương mù** | 6 | Che màu của ô, chỉ thấy khi đã nối tới cạnh | Nối ô cạnh để xua | — |
| **Bào tử nấm** | 6 | Lan như bùn, thêm độc nếu chạm | Nổ ô cạnh | Sô-cô-la lan |
| **Trứng** (rồng/nhện) | 6, 7 | Nở sau N lượt thành quái con | Phá đủ lớp trước khi nở | Bom đếm ngược |
| **Xích** (4 lớp) | 7 | Khóa cổng hang | Nổ ô cạnh | — |

**Cấu trúc bảng** thay đổi theo màn:
- **Bảng có lỗ**: hình chữ U, đảo đôi, kim tự tháp, bàn cờ. Ô rơi vòng qua lỗ.
- **Băng chuyền** (vùng 6): cuối mỗi lượt, một hàng trượt sang ngang một ô.
- **Cổng dịch chuyển** (vùng 6): ô rơi vào cổng ở dưới thì ra ở cổng trên tại chỗ khác.
- **Màu thứ 5**: từ vùng 6 có thêm **ô xanh dương nạp Nộ** (mỗi ô +4 Nộ). Bảng 5 màu khó nối dài hơn, nên đây cũng là một nấc khó.

---

## 4. Toàn bộ 100 màn

Ký hiệu: ⚠ = màn khó (đánh dấu đỏ trên bản đồ), 👑 = trùm, 🎁 = màn thưởng, 📖 = chương truyện tranh sau màn, 🔓 = mở thứ mới.

### Vùng 0 · Lâu đài & bãi tập · màn 1–5

Dạy luật. Không ai chết, không thua được ở màn 1–3.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Dạy gì |
|---|---|---|---|---|
| 1 | ĐÁNH | Bù nhìn (không đánh) | Bảng thường | Nối 3, đỏ gây sát thương |
| 2 | ĐÁNH | Bù nhìn, hiệp sĩ bắt đầu 60/100 máu | Bảng thường | Xanh lá hồi máu |
| 3 | GOM | Gom 12 ô vàng cho bác nông dân | Bảng thường | Vàng; hàng 4 tự nổ |
| 4 | ĐÁNH | Bù nhìn gỗ: đánh 4 mỗi 4 lượt | Bảng thường | Đồng hồ đếm ngược, báo trước 1 lượt |
| 5 | ĐÁNH | Bù nhìn khiên rơm, 1 lớp khiên | Bảng thường | Tím phá khiên · 📖 Chương 1: công chúa bị bắt |

### Vùng 1 · Trại Orc · màn 6–18

Mới: **sét** (nối 5), **thùng gỗ**, **ô đá**, đợt quái. 🔓 Lò rèn sau màn 7, Hồi Quang sau màn 7.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 6 | ĐÁNH | Orc Khiên | Thường | Nối 5 ra sét |
| 7 | ĐÁNH | Orc Khiên (đầy khiên) | Thường | 🔓 Lò rèn, Hồi Quang |
| 8 | PHÁ + ĐÁNH | Phá 8 thùng gỗ, Orc Khiên gác | 8 thùng | Nổ cạnh để phá |
| 9 | ĐÁNH | Orc Ném Đá: đá rơi thành ô đá | Thường | Hạ trước khi bảng đầy đá |
| 10 | LƯỢT | Hạ Orc Khiên trong 12 lượt | Thường | Phá Giáp có ích |
| 11 | ĐỢT | Orc Khiên → Orc Ném Đá | Thường | Máu không hồi giữa đợt |
| 12 | CỨU | Đưa 3 lá cờ trại xuống đáy, Orc Ném Đá quấy | Cờ ở hàng trên | Nổ phía dưới để cờ rơi |
| 13 | ĐÁNH | Orc Trống Trận: mỗi 4 lượt đánh trống, đồng hồ của nó nhanh thêm 1 | Thường | Hạ nhanh |
| 14 ⚠ | ĐỢT | Orc Trống Trận + Orc Khiên: tiếng trống thúc cả con kia | 4 thùng | Màn khó đầu tiên |
| 15 🎁 | THƯỞNG | Kho báu trại Orc, 10 lượt, ô vàng ×2 | Thường | Vàng mua đồ |
| 16 | ĐÁNH | Kỵ Lợn Orc: ít máu, húc mỗi 2 lượt | Thường | Hạ trước khi bị húc nhiều |
| 17 | LƯỢT + PHÁ | Phá cổng trại trong 15 lượt | Thùng 2 lớp thành hàng | Sét quét cả hàng |
| 18 👑 | ĐÁNH | **Tù Trưởng Orc**: pha 1 tường khiên 4 lớp, pha 2 nổi điên đánh mỗi 2 lượt | Thường | 📖 Chương 2 |

### Vùng 2 · Rừng Goblin · màn 19–32

Mới: **bom** (nối 6), hợp thể sét + bom, **độc**, **mạng nhện**, **bom hẹn giờ**, **ô vàng bị đánh dấu**, **bảng có lỗ**. 🔓 Lôi Trảm sau màn 22.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 19 | ĐÁNH | Goblin Móc Túi | Ô vàng bị đánh dấu | Nối ô đánh dấu trước khi nó đánh |
| 20 | ĐÁNH | Goblin Cung Độc: độc 3 lượt | Thường | Xanh lá giải độc |
| 21 | PHÁ + ĐÁNH | Gỡ 10 ô mạng nhện, Nhện Rừng giăng thêm | 10 mạng nhện | Nối ô cạnh để gỡ |
| 22 | ĐỢT | Móc Túi → Cung Độc | Thường | 🔓 Lôi Trảm |
| 23 | GOM | Nhặt 15 nấm cho thầy lang, Cung Độc bắn | Nấm phủ trên ô | |
| 24 | ĐÁNH | Goblin Đặt Bom: thả bom hẹn giờ 5 lượt | Bom hẹn giờ | Nối trúng bom để gỡ |
| 25 | LƯỢT | Hạ Đặt Bom trước khi 3 quả nổ | 3 bom sẵn | |
| 26 🎁 | THƯỞNG | Cây vàng trong rừng | Hình cây (có lỗ) | |
| 27 | CỨU | Thả 3 chú thỏ trong lồng | Lồng ở hàng trên | |
| 28 ⚠ | ĐỢT | Móc Túi → Cung Độc → Đặt Bom | Mạng nhện | |
| 29 | ĐÁNH | Nhện Rừng Khổng Lồ (trùm nhỏ): mỗi đòn giăng 3 ô | Mạng nhện | Hợp thể sét + bom |
| 30 | PHÁ | Rễ cây đá 2 lớp, bảng chữ U | Chữ U | |
| 31 ⚠ | ĐỢT | Hai Goblin Cung Độc cùng lúc bắn so le | Thường | Độc chồng nhau |
| 32 👑 | ĐÁNH | **Goblin Đầu Đảng**: mỗi đòn trộm 1 ô đặc biệt, gọi 2 goblin đứng chắn | Mạng nhện | 📖 Chương 3 |

### Vùng 3 · Đầm lầy Cóc · màn 33–46

Mới: **sao** (nối 7), sao + bất kỳ, **băng**, **cóc ngồi**, **bùn lan**, **hút máu**, **đảo đôi**. 🔓 Hộ Thể sau màn 37.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 33 | ĐÁNH | Cóc Nhảy | Cóc ngồi | Nối cạnh để đuổi cóc |
| 34 | PHÁ + ĐÁNH | Phá 12 băng 2 lớp, Thạch Băng | Băng | |
| 35 | ĐÁNH | Đỉa Đầm: hồi cho nó nửa đòn đánh trúng | Thường | Đánh dồn một lượt |
| 36 | GOM | Gom 20 hoa súng | Hoa phủ trên ô | |
| 37 | ĐỢT | Cóc Nhảy ×2 → Thạch Băng | Cóc, băng | 🔓 Hộ Thể |
| 38 | PHÁ | Chặn bùn lan, phá hết bùn | Bùn | Màn đố nhẹ |
| 39 🎁 | THƯỞNG | Ao cá vàng | Đảo đôi | |
| 40 | LƯỢT | Cá Sấu 180 máu, cắn chậm mà đau, trong 14 lượt | Thường | Sao + sét |
| 41 | CỨU | Đưa 4 trứng vịt về bờ, Cóc quấy | Đảo đôi | |
| 42 | PHÁ + ĐÁNH | Băng + bùn cùng lúc, Thạch Băng | Băng, bùn | |
| 43 ⚠ | ĐỢT | Đỉa → Cá Sấu | Bùn | |
| 44 | ĐÁNH | Thạch Băng Mẹ (trùm nhỏ): đóng băng cả hàng | Băng | |
| 45 | GOM | Gom 25 ô xanh lá làm thuốc giải | Cóc ngồi | |
| 46 👑 | ĐÁNH | **Mụ Phù Thủy Cóc**, 2 mạng (như `world_plan.md`) | Cóc, băng | 📖 Chương 4 |

### Vùng 4 · Rừng đen & nhà ba phù thủy · màn 47–60

Mới: hợp thể sét + sét, **kẹo đường cứng**, **lửa lan**, **khóa màu**, **quái trộm ô đặc biệt**, **quái tách đôi**. 🔓 Phong Kiếm sau màn 52, ô chiêu thứ hai sau màn 60.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 47 | ĐÁNH | Quạ Đen: trộm 1 ô đặc biệt mỗi đòn | Thường | Dùng đặc biệt ngay |
| 48 | ĐÁNH | Lính Bánh Gừng: chết thì tách thành 2 bánh nhỏ | Thường | |
| 49 | PHÁ | Kẹo đường cứng 3 lớp quanh nhà bánh | Kẹo, bảng kim tự tháp | |
| 50 🎁 | THƯỞNG | Màn 50: rương lớn | Kẹo | 📖 Chương giữa: bọn trẻ trong lồng |
| 51 | ĐÁNH | Mèo Đen: nguyền khóa 1 màu trong 1 lượt | Khóa màu | |
| 52 | CỨU | Thả 3 đứa trẻ trong lồng, Quạ quấy | Kẹo | 🔓 Phong Kiếm |
| 53 | PHÁ | Dập lửa lan trên mái nhà bánh | Lửa | |
| 54 | ĐỢT | Bánh Gừng → Quạ Đen | Kẹo | |
| 55 ⚠ | LƯỢT | Mèo Đen trong 12 lượt, kẹo chắn | Kẹo, khóa màu | |
| 56 | ĐÁNH | **Bà Cả** (phù thủy lửa) | Lửa | Trùm nhỏ |
| 57 | ĐÁNH | **Bà Hai** (phù thủy mực tím, khóa màu) | Khóa màu | Trùm nhỏ |
| 58 | ĐÁNH | **Bà Út** (nồi cháo, hồi máu mỗi 3 lượt) | Kẹo | Trùm nhỏ |
| 59 | GOM | Gom 30 kẹo làm cầu thoát ra cửa sổ | Kẹo | |
| 60 👑 | ĐÁNH | **Ba chị em cùng lúc** (bảng nhắm từng mụ); nếu chưa kịp làm trận nhiều quái thì đánh ba trận liên tiếp không hồi máu | Lửa, kẹo, khóa màu | 📖 Chương 5: đứa trẻ chỉ đường lên núi · 🔓 Ô chiêu thứ hai |

### Vùng 5 · Vùng núi · màn 61–73

Mới: **câu đố**, **đá nhiều lớp**, bom + bom, **quái né đòn**, **quái xáo hàng**. 🔓 Tinh Kiếm sau màn 66. Gom 3 mảnh bản đồ ở màn 61, 64, 70 để mở cổng núi.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 61 | ĐỐ | Phá 4 tảng đá trong 10 lượt | Bảng xếp sẵn | Mảnh bản đồ 1 |
| 62 | ĐÁNH | Người Đá: biến ô thành đá 2 lớp | Đá | Bom |
| 63 | ĐÁNH | Dơi Hang: né đòn nếu chuỗi dưới 2 vòng | Thường | Phải tạo dây chuyền |
| 64 | ĐỐ | Đưa chìa khóa xuống đáy trong 8 lượt | Bảng xếp sẵn | Mảnh bản đồ 2 |
| 65 | ĐÁNH | Dê Núi: húc xáo trộn cả một hàng | Thường | |
| 66 🎁 | THƯỞNG | Hang đá quý | Bàn cờ | 🔓 Tinh Kiếm |
| 67 | ĐỐ | Dọn hết băng trên bảng kim tự tháp | Kim tự tháp | |
| 68 | ĐỢT | Ba con Dơi Hang nhanh, ít máu | Thường | |
| 69 | ĐÁNH | Người Tuyết: ném cầu tuyết thành băng, đánh 20 | Băng | |
| 70 | ĐỐ | Bom + bom phá tảng đá khổng lồ 3 lớp | Bảng xếp sẵn | Mảnh bản đồ 3 |
| 71 ⚠ | ĐỢT | Người Đá → Dê Núi | Đá 3 lớp | |
| 72 | LƯỢT | Hạ Người Đá Gác Cầu trong 12 lượt trên cầu treo | Bảng hẹp 5 cột | |
| 73 👑 | ĐÁNH | **Người Khổng Lồ Gác Cổng**: chỉ đau khi nổ ô "mắt" trên bảng | Đá, ô mắt | 📖 Chương 6 |

### Vùng 6 · Mỏ pha lê · màn 74–87 (vùng mới)

Mỏ bỏ hoang dưới lòng núi, lối duy nhất sang hang rồng. Mới: **băng chuyền**, **cổng dịch chuyển**, **sương mù**, **pha lê**, **bào tử**, **trứng nhện**, **màu thứ 5**. 🔓 Băng Ấn sau màn 80.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 74 | ĐÁNH | Lùn Đào Mỏ: đẩy xe goòng, hàng 4 thành băng chuyền | Băng chuyền | |
| 75 | ĐÁNH | Rắn Pha Lê: vảy phản nửa sát thương đỏ khi còn khiên | Thường | Tím trước |
| 76 | PHÁ | Pha lê 3 lớp, vỡ bắn mảnh | Pha lê | |
| 77 | ĐÁNH | Ma Đèn Lồng: sương mù che 6 ô | Sương mù | |
| 78 | CỨU | Đưa 3 xe goòng quặng xuống đáy theo băng chuyền | Băng chuyền | |
| 79 | GOM | Gom 25 ô xanh dương | 5 màu | Màu thứ 5 nạp Nộ |
| 80 🎁 | THƯỞNG | Mỏ vàng | Cổng dịch chuyển | 🔓 Băng Ấn |
| 81 | ĐÁNH | Nấm Độc: bào tử lan + độc | Bào tử | |
| 82 | PHÁ | Hai nửa bảng nối bằng cổng, pha lê | Cổng, pha lê | |
| 83 | ĐỢT | Lùn → Rắn Pha Lê | Băng chuyền | |
| 84 ⚠ | LƯỢT | Ma Đèn Lồng trong 12 lượt | Sương mù dày | |
| 85 ⚠ | ĐỢT | Ma Đèn Lồng → Nấm Độc | Sương mù, bào tử | |
| 86 | ĐÁNH | Golem Pha Lê (trùm nhỏ): mỗi đòn bọc 2 ô thành pha lê | Pha lê | |
| 87 👑 | ĐÁNH | **Nữ Hoàng Nhện Pha Lê**: giăng tơ, đẻ trứng nở sau 3 lượt | Mạng nhện, trứng | 📖 Chương 7 |

### Vùng 7 · Núi lửa & hang rồng · màn 88–100

Mới: **dung nham**, **trứng rồng**, **xích**, **đối thủ có thanh Nộ**, trùm 3 pha. 🔓 Long Trảm sau màn 97.

| Màn | Kiểu | Mục tiêu / quái | Bảng, vật cản | Ghi chú |
|---|---|---|---|---|
| 88 | ĐÁNH | Thằn Lằn Lửa: đốt ô, lửa lan | Lửa | |
| 89 | PHÁ | Đá dung nham nguội 2 lớp | Đá, lửa | |
| 90 | ĐÁNH | **Kỵ Sĩ Hắc Ám**: cũng có thanh Nộ, tung chiêu phá giáp hiệp sĩ 3 lượt | Thường | Đối thủ ngang tài |
| 91 | CỨU | Cứu 3 dân làng bị trói | Lửa | |
| 92 | ĐỢT | Thằn Lằn ×2 → Kỵ Sĩ Hắc Ám | Lửa | |
| 93 🎁 | THƯỞNG | Kho báu rồng | 5 màu | |
| 94 | ĐÁNH | Ổ trứng rồng: mỗi trứng nở sau 5 lượt | Trứng 3 lớp | Phá trứng trước |
| 95 | ĐỢT | Hai Rồng Con: bay, chỉ trúng bằng ô đặc biệt hoặc dây chuyền | Thường | |
| 96 ⚠ | LƯỢT | Golem Dung Nham trong 14 lượt | Lửa, đá | |
| 97 ⚠ | ĐÁNH | Kỵ Sĩ Hắc Ám trở lại, mạnh hơn | Xích | 🔓 Long Trảm |
| 98 | PHÁ | Phá xích 4 lớp ở cổng hang | Xích | |
| 99 | ĐỢT | Golem Dung Nham → Rồng Con | Lửa, trứng | |
| 100 👑 | ĐÁNH | **Rồng Giữ Vương Miện**, 3 pha: bay (chỉ trúng bằng ô đặc biệt) → đáp đất đốt ô → nổi giận đánh mỗi 2 lượt | Lửa, trứng | 📖 Kết: cứu công chúa |

Sau màn 100: chế độ vô tận hoặc vùng mới, để sau.

---

## 5. Quái

**42 quái**: 2 đã có (Bù nhìn, Orc Khiên), 33 bộ mới, và **7 biến thể** cùng dáng của quái khác (đổi màu, đổi cỡ, thêm phụ kiện) để đỡ việc vẽ.

| Vùng | Quái thường | Trùm nhỏ / trùm |
|---|---|---|
| 0 | Bù nhìn ✅, Bù nhìn gỗ *(biến thể)*, Bù nhìn khiên rơm *(biến thể)* | — |
| 1 | Orc Khiên ✅, Orc Ném Đá, Orc Trống Trận, Kỵ Lợn Orc | Tù Trưởng Orc (2 pha) |
| 2 | Goblin Móc Túi, Goblin Cung Độc, Goblin Đặt Bom | Nhện Rừng Khổng Lồ, Goblin Đầu Đảng |
| 3 | Cóc Nhảy, Thạch Băng, Đỉa Đầm, Cá Sấu | Thạch Băng Mẹ *(biến thể)*, Mụ Phù Thủy Cóc (2 dạng) |
| 4 | Quạ Đen, Lính Bánh Gừng (+ bánh nhỏ *biến thể*), Mèo Đen | Bà Cả, Bà Hai, Bà Út |
| 5 | Người Đá, Dơi Hang, Dê Núi, Người Tuyết | Người Khổng Lồ Gác Cổng |
| 6 | Lùn Đào Mỏ, Rắn Pha Lê, Ma Đèn Lồng, Nấm Độc | Golem Pha Lê *(biến thể Người Đá)*, Nữ Hoàng Nhện Pha Lê |
| 7 | Thằn Lằn Lửa, Kỵ Sĩ Hắc Ám, Rồng Con *(biến thể)* | Golem Dung Nham *(biến thể Người Đá)*, Rồng Giữ Vương Miện (3 pha) |

**Mỗi quái thường** cần các clip: `idle`, `attack`, `hurt`, `special` (chiêu riêng, ví dụ ném đá, giăng tơ), `defeat`, `victory`; vẽ mức `fresh`, riêng trùm thêm mức `battered` cho pha sau. Mỗi quái một bộ gạch biểu cảm là quá nhiều: dùng **một bộ gạch cho mỗi vùng** (mục 7).

**Luật quái mới cần code** (gom theo khả năng, quái nào cũng chọn từ đây):
- Trạng thái lên hiệp sĩ: độc, choáng, phá giáp tạm thời.
- Tác động lên bảng: thả vật cản, khóa màu, trộm ô đặc biệt, xáo hàng, đóng băng hàng.
- Tự thân: hút máu, hồi máu theo nhịp, né khi chuỗi ngắn, bay (chỉ trúng bằng đặc biệt), tách đôi khi chết, thúc quái khác.
- Trùm: nhiều pha, nhiều mạng, điểm yếu trên bảng, nhiều quái cùng lúc.

---

## 6. Tuyệt chiêu, trang bị và vật phẩm

### Tuyệt chiêu: 8 chiêu, mở dần

| Chiêu | Mở sau màn | Tác dụng (đề xuất, chỉnh bằng bot) |
|---|---|---|
| Phá Giáp ✅ | 1 | Bóc 1 lớp khiên rồi đánh như 8 ô đỏ |
| Hồi Quang ✅ | 7 | Hồi 25 máu |
| Lôi Trảm | 22 | Đánh như 8 ô đỏ, quái chậm 1 lượt |
| Hộ Thể | 37 | Đòn kế tiếp của quái nhẹ đi 12 |
| Phong Kiếm | 52 | 3 nhát, mỗi nhát như 3 ô đỏ |
| Tinh Kiếm | 66 | Như 7 ô đỏ, xuyên khiên |
| **Băng Ấn** (mới) | 80 | Đóng băng đồng hồ quái 2 lượt, phá hết băng/sương trên bảng |
| **Long Trảm** (mới) | 97 | Đánh như 15 ô đỏ, gấp đôi lên quái bay và rồng |

- **Ô chiêu thứ hai** mở sau màn 60. Hai chiêu dùng chung một thanh Nộ.
- **Cấp chiêu 1–3**: nâng bằng **sách chiêu** lấy từ rương sao. Cấp 2 mạnh hơn khoảng 25%, cấp 3 thêm hiệu ứng phụ (ví dụ Hồi Quang cấp 3 giải độc).

### Trang bị: kéo dài các bậc, thêm ô bùa

| Ô | Các bậc theo vùng |
|---|---|
| Vũ khí | Kiếm gỗ → sắt (1) → thép (2) → bạc (4) → pha lê (6) → kiếm rồng (7) |
| Rèn kiếm | +1 … +5, mở dần từ vùng 3 |
| Giáp | Da (1) → sắt (2) → bạc (4) → vảy rồng (7) |
| Nón | Da (1) → sắt (2) → mũ sừng (5): chống choáng |
| Ủng | Gia cố (1) → leo núi (4) → ủng chịu lửa (7): miễn đốt từ ô cháy |
| **Bùa** (ô mới, vùng 2) | Chọn 1 trong 8 bùa: Bùa Giải Độc, Bùa Nộ (vào trận có sẵn 30 Nộ), Bùa Vàng (+15% vàng), Bùa Sét (sét quét rộng 2 hàng), Bùa Bom (bom nổ 5×5 thay 3×3), Bùa Sao, Bùa Thép (giảm thêm 1 mỗi đòn), Bùa Đuổi Cóc |

Ô bùa cho người chơi tự chọn lối chơi, giống chọn bùa trợ giúp trước màn trong Candy Crush. Mỗi bùa mua một lần ở lò rèn, đổi được trước mỗi màn.

**Hình nhân vật theo giáp**: `hero_rookie` (da), `hero_iron` (sắt) đã có; thêm `hero_silver`, `hero_dragon`. Kiếm và nón là lớp chồng (như `world_plan.md`).

### Vật phẩm dùng một lần (mua bằng vàng)

| Vật phẩm | Dùng | Giống Candy Crush |
|---|---|---|
| Búa Đập Ô | Trong màn: phá 1 ô hoặc 1 lớp vật cản, không tốn lượt | Kẹo mút búa |
| Bình Nộ | Trước màn: bắt đầu với 50 Nộ | Trợ giúp trước màn |
| Tim Thêm | Trước màn: +20 máu tối đa trong màn này | — |
| Sao Khởi Đầu | Trước màn: bảng có sẵn 1 ô sao | Kẹo bọc sẵn |
| Thêm 5 Lượt | Khi thua màn có giới hạn lượt | +5 nước |

### Kinh tế

- Vàng mỗi màn tăng dần theo vùng (khoảng 20 ở vùng 1, 60 ở vùng 7), cộng ô vàng gom được trong trận.
- **Rương sao** mỗi 15 sao: vàng, sách chiêu, đôi khi vật phẩm.
- **Rương mốc** ở màn 25, 50, 75, 100.
- Không có mạng sống chờ hồi như Candy Crush: game chơi offline, thua thì chơi lại ngay (chốt ở mục 10).
- Bot đo vàng cả chiến dịch để giá đồ khớp nhịp: mua được món mới khoảng mỗi 4–6 màn.

---

## 7. Ảnh cần vẽ (ChatGPT)

Ước lượng khối lượng để chia đợt. Mọi clip **vẽ tay từng khung**, không dựng bằng Python từ ảnh đứng (như yêu cầu thợ rèn).

| Hạng mục | Số lượng | Ghi chú |
|---|---|---|
| Quái mới | 33 bộ, + 7 biến thể | 6 clip mỗi bộ; trùm thêm pha sau |
| Bộ gạch theo vùng | 6 bộ mới (goblin, đầm lầy, kẹo, núi, pha lê, núi lửa) | 4 màu (+ xanh dương từ vùng 6), biểu cảm, clip nổ/rơi như `orc_shield` |
| Nền trận đánh | 6 nền mới | Đã có bãi tập, trại Orc |
| Đoạn bản đồ | 8 đoạn dọc nối liền, ~100 nút | Thay `world_map.png` hiện tại; nút thường, nút khó, nút trùm, nút thưởng |
| Vật cản | ~17 loại | Mỗi lớp một hình, kèm clip vỡ |
| Hiệp sĩ | 2 bộ giáp mới, lớp kiếm và nón | Đủ 3 mức thương tích |
| Chiêu, bùa, vật phẩm | 8 chiêu, 8 bùa, 5 vật phẩm | Biểu tượng; clip chiêu theo `skills_art_request.md` |
| Truyện tranh | 8 chương + chương giữa, khoảng 6–10 khung mỗi chương | Khung dọc, không chữ |

---

## 8. Độ khó và kiểm tra bằng bot

Mỗi màn có tỉ lệ thắng mục tiêu cho bot "chơi khôn" (`BattleSim` mở rộng thêm mục tiêu và vật cản):

| Loại màn | Bot chơi khôn thắng | Bot ngẫu nhiên thắng |
|---|---|---|
| Màn dạy (giới thiệu thứ mới) | 98–100% | ≥ 80% |
| Màn thường | 85–95% | 40–70% |
| Màn khó ⚠ | 60–75% | 10–30% |
| Trùm 👑 | 65–80% | 15–35% |
| Màn đố | Có ít nhất một lời giải trong số lượt cho phép (bot tìm kiếm đủ sâu) | — |

- Bot chạy **cả 100 màn** theo đúng thứ tự, mang theo trang bị mua được bằng số vàng kiếm được, để kiểm tra kinh tế và đường cong khó.
- Kết quả in thành một bảng, lưu vào `docs/` mỗi lần cân bằng lại.

---

## 9. Code cần làm (Claude) và thứ tự giai đoạn

Mỗi giai đoạn là một hoặc vài PR chơi được ngay. Đi kèm là một đợt ảnh của ChatGPT.

| Giai đoạn | Code | Màn chơi được | Ảnh cần trước |
|---|---|---|---|
| **G1 Nền tảng** | Dữ liệu màn (`data/levels/level_###.tres`: quái hoặc các đợt, kiểu màn, mục tiêu, số lượt, hình bảng, vật cản đặt sẵn, phần thưởng); hệ mục tiêu ĐÁNH/ĐỢT/LƯỢT/GOM/PHÁ/CỨU/THƯỞNG; lớp vật cản (thùng, đá, băng); bảng có lỗ; sao theo mục tiêu; thẻ mục tiêu trước màn; bản đồ 100 nút | 1–18 | Orc Ném Đá, Orc Trống Trận, Kỵ Lợn, Tù Trưởng; thùng, đá; đoạn bản đồ vùng 0–1 |
| **G2 Rừng Goblin** | Trạng thái độc; mạng nhện, bom hẹn giờ, ô đánh dấu; quái trộm ô đặc biệt và gọi quân; ô bùa | 19–32 | 5 quái goblin, bộ gạch goblin, nền rừng |
| **G3 Đầm lầy** | Cóc ngồi, băng 2 lớp, bùn lan, hút máu, trùm 2 mạng; vật phẩm dùng một lần | 33–46 | 6 quái, bộ gạch đầm lầy, nền đầm lầy |
| **G4 Rừng đen** | Lửa lan, khóa màu, quái tách đôi, trận nhiều quái cùng lúc, ô chiêu thứ hai, cấp chiêu | 47–60 | 6 quái, bộ gạch kẹo, nền nhà bánh, truyện tranh chương giữa |
| **G5 Vùng núi** | Màn đố (ô rơi theo thứ tự cố định, bot tìm lời giải), đá nhiều lớp, né đòn, xáo hàng, ô điểm yếu của trùm | 61–73 | 5 quái, bộ gạch núi, nền núi |
| **G6 Mỏ pha lê** | Băng chuyền, cổng dịch chuyển, sương mù, pha lê bắn mảnh, bào tử, trứng nở, màu thứ 5 | 74–87 | 6 quái, bộ gạch pha lê, nền mỏ |
| **G7 Hang rồng** | Đối thủ có thanh Nộ, quái bay, trùm 3 pha, màn kết | 88–100 | 6 quái, bộ gạch núi lửa, nền hang, chương kết |

Truyện tranh (W3 trong `world_plan.md`) làm song song từ G1, vì chương 1 nằm sau màn 5.

**Việc ngay sau khi duyệt kế hoạch:** bắt đầu G1. Phần code không cần chờ ảnh: vật cản và quái mới dùng hình tạm cho tới khi có ảnh thật.

---

## 10. Cần người dùng chốt

1. **Mạng sống**: không có (thua chơi lại ngay, đề xuất) hay có 5 mạng hồi theo thời gian như Candy Crush?
2. **Cổng sao**: có bắt buộc đủ số sao mới qua vùng tiếp theo không? Đề xuất: không bắt buộc, sao chỉ đổi rương.
3. **Màu thứ 5** (xanh dương nạp Nộ) từ vùng 6: giữ hay bỏ?
4. **Vùng 6 Mỏ pha lê**: vùng mới chèn trước hang rồng, có đồng ý không?
5. **Ba phù thủy cùng lúc** ở màn 60 cần code trận nhiều quái. Làm luôn ở G4, hay tạm dùng ba trận liên tiếp?
