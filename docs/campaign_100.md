# Kế hoạch 100 màn – Brickbound Hero

Viết ngày 2026-11-05 theo câu chuyện người dùng kể, cảm hứng từ truyện cổ tích, phim *Fantaghirò* (công chúa tự cải trang làm hiệp sĩ, bà tiên thử lòng) và Perseus cưỡi Pegasus (khiên gương hạ mụ tóc rắn). Chỉ lấy tinh thần: **tên nhân vật và tình tiết là của game mình**, không dùng tên hay cốt truyện của phim.

Mở rộng [world_plan.md](world_plan.md) từ 15 điểm dừng thành **100 màn**, mỗi màn một thử thách riêng kiểu Candy Crush. Mọi con số là đề xuất ban đầu: mỗi màn phải chạy bot (`tests/sim_balance.gd`) đạt tỉ lệ thắng ở mục 10, và chơi thử trên điện thoại theo từng vùng.

---

## 1. Tinh thần của game

Kiểu game có tâm như thời Android mới ra:

1. **Có truyện từ đầu tới cuối.** Chơi xong như đọc hết một cuốn truyện tranh.
2. **Không có mạng sống chờ hồi.** Thua thì chơi lại ngay.
3. **Không có gì phải trả tiền thật mới qua được.** Vàng và vật phẩm đều kiếm trong game.
4. **Màn nào cũng có một điều mới hoặc một khoảnh khắc truyện.** Màn chỉ là "quái mạnh hơn" thì sửa hoặc bỏ.
5. **Chịu khó thì được thưởng**: cánh hoa hồng vàng mở kết thúc thật, đồ gom dọc đường giúp hạ rồng.
6. **Chăm chút chi tiết nhỏ**: thợ rèn đổ mồ hôi, Orc cười chọc, bọn trẻ nói bằng dấu tay.

Giọng kể: cổ tích nhại, vui, **không máu me**. Kẻ ác bị biến thành chuột chứ không chết thảm.

---

## 2. Câu chuyện

### Nhân vật

| Nhân vật | Vai trò |
|---|---|
| **Hiệp sĩ** | Chàng trai tân binh, người chơi điều khiển suốt game |
| **Công chúa Hồng Vàng** | Không chịu ngồi chờ: trốn khỏi rồng giữa đường, cắt tóc, đeo mặt nạ thành **Hiệp Sĩ Bí Ẩn** lén giúp hiệp sĩ. Chơi được ở vùng núi |
| **Bà Tiên Ngông** | Bà tiên bị nhà vua quên mời dự tiệc. Tính khí thất thường, hay cải trang (bà lão ăn xin, con quạ, đứa bé) để thử lòng người. Lúc giúp, lúc phá |
| **Bà Tiên Đen** | Kẻ ác thật sự đứng sau mọi chuyện. Ba mụ phù thủy là học trò của bà; con rồng bị bà điều khiển |
| **Ông già đầm lầy** và **cậu Bin** | Ông chỉ đường tới trại Goblin, nơi con trai ông bị nhốt. Cứu ra, Bin thành bạn đồng hành |
| **Người Cây** | Gác bìa rừng đen, dặn "cẩn thận nhé chàng trai" và tặng chiêu |
| **Ba đứa trẻ** | Bị ba mụ phù thủy bắt làm người hầu và yểm **phép câm**, chỉ nói được bằng dấu tay |
| **Thủ Lĩnh Cướp** | Cướp núi, sau thành bạn, tặng ngựa có cánh |
| **Pegasus** | Ngựa có cánh bị bọn cướp nhốt, đưa hiệp sĩ lên Suối Nguồn và cùng đánh rồng |

### Sợi chỉ đỏ

> Tiệc sinh nhật công chúa, nhà vua quên mời Bà Tiên Ngông → bà buông lời "bông hồng vàng sẽ bị lửa mang đi" → đêm đó rồng bắt công chúa → công chúa trốn được, thành Hiệp Sĩ Bí Ẩn → trại Orc → đầm lầy cóc → rừng đen, ba mụ phù thủy là học trò Bà Tiên Đen → núi, cướp, Mụ Tóc Rắn, công chúa lộ mặt rồi bị bắt lại → Pegasus → Suối Nguồn Tươi Trẻ → rồng → Bà Tiên Đen → đám cưới, lần này có mời Bà Tiên Ngông.

### Truyện từng hồi

**Mở đầu · Lâu đài.** Hiệp sĩ tập ở bãi tập, chuẩn bị quà sinh nhật cho công chúa. Giữa tiệc, Bà Tiên Ngông xông vào vì không được mời, buông một câu nửa đùa nửa thật. Đêm đó rồng sà xuống bắt công chúa. Trên đường bay, công chúa thả cánh hoa hồng vàng đầu tiên xuống vườn.

**Hồi 1 · Trại Orc.** Đường đi qua trại Orc. Hiệp sĩ vượt các thử thách, đánh dần vào trong và hạ Tù Trưởng Orc. Một bà lão ăn xin xin miếng bánh: ai cho thì được thưởng, vì đó là Bà Tiên Ngông cải trang. Một hiệp sĩ đeo mặt nạ thoáng xuất hiện, ném bình máu rồi biến mất.

**Hồi 2 · Đầm lầy Cóc.** Vùng của **độc rút máu theo thời gian**. Ông già bên đầm chỉ đường tới trại Goblin: con trai ông là Bin bị Goblin bắt về làm việc vặt cho Mụ Phù Thủy Cóc. Hiệp sĩ đánh vào trại, cứu Bin. Bin đưa quyển sách chiêu cậu trộm được trong nhà mụ, mở chiêu **Lôi Trảm**. Cuối vùng là Mụ Phù Thủy Cóc: mụ triệu hồi cóc phun độc, sang pha 2 thì uống thuốc biến thành **cóc khổng lồ** với bộ chiêu mạnh hơn. Thắng được **Giáp Kháng Độc**.

**Hồi 3 · Rừng đen** (hồi dài nhất).
1. Bìa rừng âm u. Ba đứa trẻ đứng đó, Người Cây dặn "cẩn thận nhé chàng trai" và tặng chiêu **Rễ Trói**.
2. Dọc bìa rừng gặp mấy bé gái đốn củi, gánh nước. Thấy hiệp sĩ, chúng bỏ chạy. Hiệp sĩ lần theo rồi mất dấu.
3. Đang mệt lả, ba chị em gái xinh xắn mời vào nhà nghỉ. Bữa tiệc thịnh soạn, ba đứa trẻ hầu bàn với gương mặt lo lắng. Một cô bé ra ám hiệu thì bị đuổi đi.
4. Nửa đêm hiệp sĩ mở mắt, thấy mụ phù thủy đứng sát mặt, rồi bị chụp thuốc mê.
5. Tỉnh dậy trong ngục, **mất hết trang bị và chiêu**. Hai đứa trẻ bị nhốt cạnh nói chuyện bằng dấu tay: mụ bắt chúng làm người hầu và yểm phép câm. Còn hiệp sĩ bị bắt vì **trái tim dũng cảm**, nguyên liệu cho phép trẻ mãi không già.
6. Ngoài cửa, ba chị em cãi nhau xem ai được ăn trước. Hiệp sĩ lụm được chìa khóa và trốn ra **tay không**, đánh xuyên qua lính canh tới phòng của mụ để lấy lại đồ.
7. Đánh từng mụ một. **Cú lật**: ba chị em thật ra là **một mụ già** chia làm ba, học trò của Bà Tiên Đen. Mụ sống trẻ nhờ nước Suối Nguồn mà con rồng canh giữ, đổi lại phải nộp cho rồng những trái tim dũng cảm. Công chúa cũng bị bắt vì lý do đó.
8. Thắng xong, hiệp sĩ cho bọn trẻ uống thuốc: giọng nói trở lại. Ba mụ hóa thành **ba con chuột** chạy mất.

**Hồi 4 · Vùng núi & sơn trại.** Bin bị cướp núi lấy mất túi. Hiệp sĩ đánh bọn cướp, rồi bị **Hiệp Sĩ Bí Ẩn** chặn đường thách đấu tay đôi. Lên tới sơn trại, hạ Thủ Lĩnh Cướp; hắn kể nửa sơn trại đã bị **Mụ Tóc Rắn** biến thành tượng đá. Vào hang Mụ Tóc Rắn, mụ hóa đá hiệp sĩ ngay giữa trận. Người chơi chuyển sang **điều khiển Hiệp Sĩ Bí Ẩn**, dùng **khiên gương** dội mắt mụ về chính mụ. Hiệp sĩ và đám cướp sống lại, mặt nạ rơi: là công chúa Hồng Vàng. Đúng lúc đó rồng sà xuống bắt cô lần nữa. Thủ Lĩnh Cướp kết bạn, trả ơn bằng con **Pegasus** hắn nhốt trong chuồng, và chỉ đường: muốn đánh rồng phải lên Suối Nguồn Tươi Trẻ trước.

**Hồi 5 · Suối Nguồn Tươi Trẻ.** Pegasus bay lên một hòn đảo trên mây. Ở đây thời gian chảy lung tung: ô già đi rồi vỡ, quái tua lại vết thương. Người Giữ Suối là trùm nhỏ có **phép thời gian**: lúc trẻ thì nhanh, lúc già thì hồi máu, và tua ngược đòn của hiệp sĩ. Thắng được **Nước Suối Nguồn**.

**Hồi 6 · Hang rồng.** Hàng rào hồng gai, trứng rồng, Kỵ Sĩ Đen của Bà Tiên Đen. Công chúa thả cánh hoa cuối cùng từ ngọn tháp. **Trận rồng**: rồng bay, phun lửa, hóa đá. Hạ được rồng thì rưới Nước Suối Nguồn: rồng tỉnh lại, hóa ra bị Bà Tiên Đen điều khiển. **Bà Tiên Đen** lộ mặt ở trận cuối, và Bà Tiên Ngông hiện ra giúp một tay. Kết: đám cưới, và lần này Bà Tiên Ngông được mời đầu tiên. Bà cười phá lên, thú nhận câu nguyền năm xưa chỉ là bài thử dành cho công chúa: thử xem cô có tự cứu được mình không.

**Hai kết thúc:**
- **Kết thường**: thắng mà thiếu cánh hoa.
- **Kết thật**: đủ **7 cánh hoa hồng vàng**. Công chúa cầm Hoa Hồng Vàng cùng đánh trận cuối, và có thêm một chương truyện tranh.

---

## 3. Các kiểu màn chơi

| Mã | Kiểu | Thắng khi | Thua khi |
|---|---|---|---|
| **ĐÁNH** | Đánh quái | Quái hết máu | Hiệp sĩ hết máu |
| **ĐỢT** | Nhiều đợt quái | Hạ hết 2–3 quái nối tiếp, máu không hồi giữa đợt | Hết máu |
| **LƯỢT** | Đua lượt | Hạ quái trong N lượt | Hết lượt hoặc hết máu |
| **GOM** | Thu thập | Gom đủ N ô hoặc vật phẩm | Hết lượt hoặc hết máu |
| **PHÁ** | Phá vật cản | Phá hết vật cản đã chỉ định | Hết lượt hoặc hết máu |
| **CỨU** | Đưa xuống đáy | Đưa lồng, chìa khóa, cánh hoa… xuống hàng cuối | Hết lượt hoặc hết máu |
| **ĐỐ** | Câu đố | Đạt mục tiêu trên bảng xếp sẵn, ô mới rơi theo thứ tự cố định | Hết lượt |
| **THƯỞNG** | Màn thưởng | Luôn thắng; càng nhiều vàng càng nhiều sao | — |
| **ĐẤU** | Đấu tay đôi | Hạ đối thủ cũng có thanh Nộ và tung chiêu | Hết máu |
| **CÔNG CHÚA** | Chơi bằng Hiệp Sĩ Bí Ẩn | Như ĐÁNH hoặc ĐỢT, với thanh Nộ và chiêu của công chúa | Hết máu |
| **TAY KHÔNG** | Không trang bị | Như ĐÁNH, ĐỐ hoặc CỨU, nhưng không có đồ, chiêu và Nộ, mỗi ô đỏ chỉ gây 1 sát thương | Như kiểu gốc |

Trùm là màn ĐÁNH có nhiều pha. Một màn có thể ghép hai kiểu, ví dụ PHÁ + ĐÁNH.

---

## 4. Vật cản và cấu trúc bảng

Vật cản là một lớp phủ trên ô (`cell.gd` đã chừa chỗ cho "hình phủ").

| Vật cản | Vùng | Cách hoạt động | Cách phá |
|---|---|---|---|
| Thùng gỗ (1–3 lớp) | 1, 4 | Chiếm ô, không nối được | Nổ ô cạnh, mỗi lần bớt 1 lớp |
| Ô đá | 1 | Đá Orc ném rơi xuống bảng | Nổ ô cạnh |
| **Cóc độc** | 2 | Cóc ngồi đè ô; mỗi lượt không bị đuổi thì phun độc lên hiệp sĩ | Nối ô cạnh để đuổi; sao quét |
| Bùn lan | 2 | Lượt nào không phá bùn thì bùn lan sang 1 ô cạnh | Nổ ô cạnh |
| Mạng nhện / lưới | 2, 4 | Ô dính, không rơi, không nối được | Nối ô cạnh hoặc nổ trúng |
| Bom hẹn giờ | 2 | Đếm ngược, về 0 thì nổ vào hiệp sĩ | Nối trúng trước khi hết giờ |
| Ô vàng bị đánh dấu | 2 | Đòn sau của Goblin lấy vàng theo số ô còn lại | Nối các ô đó |
| Băng (1–2 lớp) | 2, 5 | Phủ trên ô, ô bên dưới vẫn nối được | Nối hoặc nổ, mỗi lần bớt 1 lớp |
| Rễ cây | 3 | Như đá 2 lớp | Bom |
| Gai | 3, 6 | Mỗi lượt mọc thêm 1 ô; nối đi qua thì mất máu | Nổ ô cạnh |
| Kẹo đường cứng (1–3 lớp) | 3 | Khối kẹo trong nhà bánh | Nổ ô cạnh |
| Lửa lan | 3, 6 | Sau 2 lượt lan sang ô cạnh; mỗi ô cháy đốt 1 máu mỗi lượt | Nối qua để dập |
| Khóa màu | 3 | Một màu không nối được trong 1 lượt | Có sẵn đường màu khác |
| **Ô tượng đá** | 4 | Mụ Tóc Rắn nhìn tới đâu, ô hóa đá tới đó (2 lớp) | Bom |
| **Ô gương** | 4 | Nổ ô gương thì dội mắt Mụ Tóc Rắn về chính mụ: mụ choáng và mất máu | Nổ ô cạnh |
| Mây | 5 | Che màu ô | Nối ô cạnh để xua |
| **Ô héo** | 5 | Đếm ngược; về 0 thì vỡ và làm ô cạnh già đi | Nối trước khi héo hết |
| **Đồng hồ cát** | 5 | Còn trên bảng thì Người Giữ Suối tua lại được sát thương lượt trước | Phá hết trước lượt tua |
| Trứng rồng (3 lớp) | 6 | Nở sau 5 lượt thành Rồng Con | Phá đủ lớp trước khi nở |
| Xích (4 lớp) | 6 | Khóa cổng hang | Nổ ô cạnh |

**Bảng nhiều hình dạng**: chữ U, đảo đôi, kim tự tháp, cầu treo hẹp 5 cột, bảng trên mây có lỗ. Ô rơi vòng qua lỗ.

---

## 5. Toàn bộ 100 màn

Ký hiệu: ⚠ màn khó (đánh dấu đỏ trên bản đồ) · 👑 trùm · 🎁 màn thưởng · 📖 chương truyện tranh sau màn · 🔓 mở thứ mới · 🌹 cánh hoa hồng vàng · 🧚 Bà Tiên Ngông xuất hiện.

### Mở đầu · Lâu đài & bãi tập · màn 1–5

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 1 | ĐÁNH | Bù nhìn (không đánh) | Thường | Nối 3, đỏ gây sát thương |
| 2 | ĐÁNH | Bù nhìn, hiệp sĩ bắt đầu 60/100 máu | Thường | Xanh lá hồi máu |
| 3 | GOM | Gom 12 ô vàng mua quà sinh nhật cho công chúa | Thường | Vàng; hàng 4 tự nổ |
| 4 | ĐÁNH | Bù nhìn gỗ: đánh 4 mỗi 4 lượt | Thường | Đồng hồ đếm ngược |
| 5 | ĐÁNH | Bù nhìn khiên rơm, 1 lớp | Thường | Tím phá khiên · 📖 Ch.1 tiệc sinh nhật, lời nguyền, rồng bắt công chúa · 🌹 1 rơi trong vườn |

### Hồi 1 · Trại Orc · màn 6–18

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 6 | ĐÁNH | Orc Khiên | Thường | Nối 5 ra sét |
| 7 | ĐÁNH | Orc Khiên đầy khiên | Thường | 🔓 Lò rèn, Hồi Quang |
| 8 | PHÁ + ĐÁNH | Phá 8 thùng gỗ, Orc Khiên gác | Thùng | |
| 9 | ĐÁNH | Orc Ném Đá: đá rơi thành ô đá | Thường | |
| 10 | ĐỐ | 🧚 Bà lão ăn xin: phá 6 thùng trong 8 lượt | Xếp sẵn | Giúp bà thì 🔓 Hộ Thể |
| 11 | ĐỢT | Orc Khiên → Orc Ném Đá | Thường | Hiệp Sĩ Bí Ẩn ném bình máu khi máu dưới 30% |
| 12 | CỨU | Đưa 3 lá cờ trại xuống đáy | Cờ trên cao | |
| 13 | ĐÁNH | Orc Trống Trận: mỗi 4 lượt đánh trống, đồng hồ nhanh thêm 1 | Thường | |
| 14 ⚠ | ĐỢT | Orc Trống Trận → Orc Khiên (bị trống thúc) | Thùng | |
| 15 🎁 | THƯỞNG | Kho báu trại Orc, ô vàng ×2 | Thường | |
| 16 | ĐÁNH | Kỵ Lợn Orc: ít máu, húc mỗi 2 lượt | Thường | |
| 17 | LƯỢT + PHÁ | Phá cổng trại trong 15 lượt | Thùng 2 lớp | |
| 18 👑 | ĐÁNH | **Tù Trưởng Orc**: pha 1 tường khiên 4 lớp, pha 2 nổi điên đánh mỗi 2 lượt | Thường | 📖 Ch.2 · 🧚 vòng quay |

### Hồi 2 · Đầm lầy Cóc & trại Goblin · màn 19–36

Chủ đề: **độc rút máu theo lượt**. Xanh lá để giải độc. Mới: bom (nối 6), sao (nối 7), hợp thể.

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 19 | ĐÁNH | Cóc Phun Độc: độc 3 lượt | Cóc độc | Gặp ông già đầm lầy |
| 20 | PHÁ + ĐÁNH | Chặn bùn lan, Đỉa Đầm hút máu | Bùn | |
| 21 | GOM | Gom 20 thảo dược giải độc cho ông già | Thường | |
| 22 | ĐÁNH | Goblin Cung Độc: bắn nhanh, độc chồng độc | Thường | Nối 6 ra bom |
| 23 | ĐÁNH | Goblin Móc Túi | Ô vàng đánh dấu | |
| 24 | ĐỢT | Cung Độc → Móc Túi | Thường | |
| 25 | PHÁ + ĐÁNH | Gỡ 10 mạng nhện, Nhện Đầm giăng thêm | Mạng nhện | |
| 26 | ĐỐ | 🧚 Con quạ nói tiếng người: hợp thể sét + bom phá cửa trại | Xếp sẵn | |
| 27 | ĐÁNH | Goblin Đặt Bom | Bom hẹn giờ | |
| 28 ⚠ | ĐỢT | Móc Túi → Cung Độc → Đặt Bom, ngay trong trại | Mạng nhện | |
| 29 | CỨU | Thả **Bin** trong lồng, Goblin canh | Lồng | 📖 Bin tặng sách · 🔓 Lôi Trảm |
| 30 🎁 | THƯỞNG | Kho đồ trộm của Goblin | Chữ U | |
| 31 | ĐÁNH | Thạch Băng | Băng | Nối 7 ra sao |
| 32 | PHÁ | Băng 2 lớp và cóc độc | Băng, cóc độc | |
| 33 | CỨU | 🌹 2 mắc trên cành cây giữa đầm; Cá Sấu quấy | Đảo đôi | |
| 34 ⚠ | LƯỢT | Cá Sấu 180 máu trong 14 lượt | Thường | Sao + sét |
| 35 | ĐỢT | Cóc Phun Độc ×2 → Đỉa Đầm | Cóc độc, bùn | |
| 36 👑 | ĐÁNH | **Mụ Phù Thủy Cóc**: pha 1 triệu hồi cóc phun độc; pha 2 **cóc khổng lồ** (lưỡi nuốt ô đặc biệt, mưa độc cả bảng, nhảy dậm xáo trộn bảng) | Cóc độc | Thưởng **Giáp Kháng Độc** · 📖 Ch.3 · 🧚 vòng quay |

### Hồi 3 · Rừng đen & nhà ba phù thủy · màn 37–58

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 37 | ĐỐ | Mở lối vào rừng: dọn rễ cây trong 10 lượt | Rễ cây | Gặp ba đứa trẻ, Người Cây · 🔓 Rễ Trói |
| 38 | ĐÁNH | Sói Đen: nhanh, đánh mỗi 2 lượt | Thường | |
| 39 | GOM | Lần theo các bé gái: gom 15 dấu chân trong 12 lượt | Dấu chân | Quạ quấy |
| 40 | PHÁ | Bụi gai mọc kín lối, mất dấu | Gai | |
| 41 | ĐỢT | Sói Đen ×2, mệt lả | Gai | |
| 42 🎁 | THƯỞNG | **Bữa tiệc**: ô món ăn cho vàng ×2; gom 3 ô "mặt lo lắng" (ám hiệu) mở thêm một khung truyện | Kim tự tháp | 📖 Ch.4 bị chuốc thuốc, tỉnh dậy trong ngục |
| 43 | TAY KHÔNG · ĐỐ | Lụm chìa khóa: đưa chìa khóa xuống đáy | Xếp sẵn | Mất hết đồ, chiêu, Nộ |
| 44 | TAY KHÔNG · ĐÁNH | Chuột Ngục | Thường | Đánh bằng nắm đấm |
| 45 | TAY KHÔNG · CỨU | Thả hai đứa trẻ khỏi lồng | Lồng | Bọn trẻ đưa 🌹 3 nhặt được trong ngục |
| 46 | TAY KHÔNG · LƯỢT | Lẻn qua Lính Bánh Gừng trong 10 lượt, lúc ba chị em đang cãi nhau ai ăn trước | Kẹo | |
| 47 ⚠ | TAY KHÔNG · ĐÁNH | Lính Bánh Gừng Gác Cửa: chết thì tách đôi | Kẹo | |
| 48 | ĐÁNH | Quạ Đen giữ chìa phòng đồ, trộm ô đặc biệt | Thường | Thắng thì **lấy lại toàn bộ trang bị** (hoạt cảnh mặc đồ) |
| 49 | PHÁ | Kẹo đường cứng 3 lớp ở hành lang | Kẹo | |
| 50 🎁 | THƯỞNG | Kho của ba mụ: rương màn 50 | Kẹo | |
| 51 | ĐÁNH | Mèo Đen: nguyền khóa màu | Khóa màu | |
| 52 | CỨU | Thả cô bé ra ám hiệu bị nhốt trong bếp | Lửa | 🔓 Phong Kiếm |
| 53 | PHÁ | Dập lửa lan trên mái nhà bánh | Lửa | |
| 54 | ĐỢT | Lính Bánh Gừng → Quạ Đen | Kẹo | |
| 55 | ĐÁNH | **Bà Cả** (lửa) | Lửa | Trùm nhỏ |
| 56 | ĐÁNH | **Bà Hai** (mực tím, khóa màu) | Khóa màu | Trùm nhỏ |
| 57 ⚠ | ĐÁNH | **Bà Út** (nồi cháo, hồi máu mỗi 3 lượt) | Kẹo | Trùm nhỏ |
| 58 👑 | ĐÁNH | **Mụ Già Ba Mặt**: ba chị em nhập làm một, dùng cả ba chiêu | Lửa, kẹo, khóa màu | 📖 Ch.5 cú lật, trả giọng nói, ba con chuột · 🔓 ô chiêu thứ hai · 🧚 vòng quay |

### Hồi 4 · Vùng núi & sơn trại · màn 59–74

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 59 | ĐÁNH | Cướp Dao | Thường | Bin bị cướp mất túi |
| 60 | ĐÁNH | Cướp Ném Lưới: lưới khóa ô | Lưới | |
| 61 | ĐỐ | 🧚 Bà lão trên đèo: phá 4 tảng đá trong 10 lượt | Xếp sẵn | |
| 62 | ĐỢT | Cướp Dao → Cướp Cung | Thường | |
| 63 | ĐÁNH | Dê Núi: húc xáo trộn một hàng | Thường | |
| 64 | CỨU | Giành lại túi của Bin | Cầu treo 5 cột | |
| 65 ⚠ | ĐẤU | **Hiệp Sĩ Bí Ẩn** chặn đường: đối thủ có thanh Nộ và chiêu | Thường | Thua thì người đó vẫn bỏ chạy, để lại 🌹 4 |
| 66 🎁 | THƯỞNG | Mỏ vàng bỏ hoang trên núi | Bàn cờ | 🔓 Tinh Kiếm |
| 67 | PHÁ | Cổng sơn trại: thùng gỗ 3 lớp | Thùng | |
| 68 | ĐỢT | Ba tên cướp | Lưới | |
| 69 | ĐÁNH | Phó Tướng Cướp | Thường | Trùm nhỏ |
| 70 👑 | ĐÁNH | **Thủ Lĩnh Cướp** | Lưới | 📖 hắn kể về Mụ Tóc Rắn |
| 71 | ĐÁNH | Rắn Đá, tay sai của mụ | Tượng đá | |
| 72 👑 | ĐÁNH | **Mụ Tóc Rắn** pha 1: tới nửa máu thì mụ hóa đá hiệp sĩ | Tượng đá | Chuyển sang công chúa |
| 73 | CÔNG CHÚA · ĐỢT | Hiệp Sĩ Bí Ẩn đánh hai Rắn Đá để tới gần mụ | Tượng đá | Người chơi điều khiển công chúa |
| 74 👑 | CÔNG CHÚA · ĐÁNH | **Mụ Tóc Rắn** pha 2: nổ ô gương để dội mắt mụ | Tượng đá, ô gương | Thưởng **Khiên Gương** · 📖 Ch.6 mặt nạ rơi, rồng bắt lại công chúa, Thủ Lĩnh Cướp tặng **Pegasus** · 🧚 vòng quay |

### Hồi 5 · Suối Nguồn Tươi Trẻ · màn 75–88

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 75 | ĐÁNH | Chim Bão: bay, chỉ trúng bằng ô đặc biệt hoặc dây chuyền | Trên mây | Cưỡi Pegasus lên đảo |
| 76 | PHÁ | Xua mây che ô | Mây | |
| 77 | ĐÁNH | Tiên Nhỏ Tinh Nghịch: đổi chỗ 2 ô mỗi lượt | Thường | |
| 78 | GOM | Gom 20 giọt sương cho Pegasus | Trên mây | |
| 79 | ĐỐ | 🧚 Đứa bé trên mây: dọn ô héo trước khi chúng vỡ | Ô héo | |
| 80 🎁 | THƯỞNG | Vườn trên mây | Đảo đôi | 🔓 Ngưng Thời |
| 81 | ĐÁNH | Rùa Đá Già: máu trâu, tua lại sát thương nếu chuỗi chưa tới 2 vòng | Thường | |
| 82 | CỨU | 🌹 5 trôi trên suối | Ô héo | |
| 83 | ĐỢT | Chim Bão → Tiên Nhỏ | Mây | |
| 84 ⚠ | LƯỢT | Mây Giông trong 12 lượt: sét đánh vỡ ô ngẫu nhiên | Mây | |
| 85 | PHÁ | Phá đồng hồ cát | Đồng hồ cát | |
| 86 | ĐÁNH | Nhện Đồng Hồ: thả ô héo | Ô héo | |
| 87 ⚠ | ĐỢT | Rùa Đá Già → Nhện Đồng Hồ | Đồng hồ cát | |
| 88 👑 | ĐÁNH | **Người Giữ Suối**: đổi qua lại pha trẻ (đánh mỗi 2 lượt) và pha già (hồi máu); còn đồng hồ cát thì tua lại đòn của hiệp sĩ | Đồng hồ cát, ô héo | Thưởng **Nước Suối Nguồn** · 📖 Ch.7 · 🧚 vòng quay |

### Hồi 6 · Hang rồng · màn 89–100

| Màn | Kiểu | Mục tiêu / quái | Bảng | Ghi chú |
|---|---|---|---|---|
| 89 | PHÁ | Hàng rào hồng gai quanh hang | Gai | |
| 90 | ĐÁNH | Thằn Lằn Lửa | Lửa | |
| 91 | ĐẤU | Kỵ Sĩ Đen, tay sai Bà Tiên Đen | Thường | |
| 92 | CỨU | 🌹 6 công chúa thả từ ngọn tháp | Gai | |
| 93 🎁 | THƯỞNG | Kho báu rồng | Bàn cờ | |
| 94 | ĐÁNH | Ổ trứng rồng | Trứng | |
| 95 | ĐỢT | Hai Rồng Con (bay) | Thường | |
| 96 ⚠ | LƯỢT | Golem Dung Nham trong 14 lượt | Lửa, đá | |
| 97 ⚠ | ĐẤU | Kỵ Sĩ Đen trở lại, mạnh hơn | Xích | 🔓 Long Trảm · 🌹 7 rơi từ mũ của hắn |
| 98 | PHÁ | Phá xích 4 lớp ở cổng hang | Xích, gai | |
| 99 👑 | ĐÁNH | **Rồng**, 3 pha: bay (cưỡi Pegasus) → hóa đá (Khiên Gương dội lại) → thiêu đốt (giáp kháng lửa) | Lửa, trứng | Kết trận: rưới Nước Suối Nguồn, rồng tỉnh lại |
| 100 👑 | ĐÁNH | **Bà Tiên Đen**; Bà Tiên Ngông giúp mỗi 3 lượt; đủ 7 cánh hoa thì công chúa cùng đánh | Gai, lửa | 📖 Kết thường hoặc kết thật |

Sau màn 100: chế độ vô tận hoặc hồi mới, để sau.

---

## 6. Món đồ của truyện và trận rồng

Mỗi hồi để lại một món dùng được về sau. Trận rồng thắng được nhờ chính những món ấy.

| Món | Lấy ở | Tác dụng |
|---|---|---|
| Sách Lôi Trảm | Bin, màn 29 | Mở chiêu Lôi Trảm |
| **Giáp Kháng Độc** | Mụ Cóc, màn 36 | Miễn độc. Lò rèn nâng thành **giáp kháng lửa** (sau màn 88) |
| Chiêu Rễ Trói | Người Cây, màn 37 | Trói quái 1 lượt, kéo quái bay xuống đất 2 lượt |
| **Khiên Gương** | Mụ Tóc Rắn, màn 74 | Dội lại chiêu hóa đá: quái tự choáng |
| **Pegasus** | Thủ Lĩnh Cướp, màn 74 | Bay tới Suối Nguồn; trong trận rồng mở **pha trên không**: đánh được rồng đang bay |
| **Nước Suối Nguồn** | Người Giữ Suối, màn 88 | Một lần mỗi trận: hồi đầy máu và giải mọi phép. Rưới lên rồng để phá phép điều khiển |
| **Hoa Hồng Vàng** | Đủ 7 cánh | Cứu hiệp sĩ một lần khi hết máu, công chúa cùng đánh màn 100, mở kết thật |

| Rồng làm gì | Thiếu món giải thì | Có món giải thì |
|---|---|---|
| Bay | Chỉ đánh được bằng ô đặc biệt | Pegasus: pha trên không đánh bình thường |
| Hóa đá | Bị choáng 1 lượt, 4 ô thành đá | Khiên Gương dội lại, rồng tự choáng |
| Thiêu đốt | Lửa lan, mất máu mỗi lượt | Giáp kháng lửa: lửa vẫn lan nhưng không mất máu |

Thiếu món nào vẫn thắng được, nhưng khó hẳn. Đó là phần thưởng cho người chơi kỹ.

---

## 7. Bà Tiên Ngông và cánh hoa hồng vàng

**Bà Tiên Ngông cải trang** ở màn 10 (bà lão ăn xin), 26 (con quạ), 61 (bà lão trên đèo) và 79 (đứa bé). Trước màn, bà xin giúp một việc nhỏ:
- Giúp bà (chọn "cho bánh") thì màn đó thành câu đố của bà, giải xong được thưởng.
- Từ chối thì gặp một lời nguyền vui ở màn sau.

**Vòng quay may rủi** sau mỗi trùm (màn 18, 36, 58, 74, 88). Kết quả áp vào màn kế tiếp:
- Phúc: bắt đầu có 1 sao trên bảng, máu tối đa +20, vàng ×2, Nộ khởi đầu 50.
- Họa vui: **kiếm hóa củ cà rốt** (đỏ còn nửa sát thương, vàng gấp đôi), hiệp sĩ hóa ếch 3 lượt (chỉ nối được 3 ô), Bà Tiên hát dở làm quái ngủ gật (đồng hồ quái +1).

**7 cánh hoa hồng vàng** ở màn 5, 33, 45, 65, 82, 92, 97. Màn có cánh hoa đánh dấu trên bản đồ; cánh nào đã lấy thì sáng lên.

---

## 8. Quái và nhân vật cần vẽ

### Quái

| Hồi | Quái thường | Trùm nhỏ / trùm |
|---|---|---|
| Mở đầu | Bù nhìn ✅, Bù nhìn gỗ *(biến thể)*, Bù nhìn khiên rơm *(biến thể)* | — |
| 1 | Orc Khiên ✅, Orc Ném Đá, Orc Trống Trận, Kỵ Lợn Orc | Tù Trưởng Orc (2 pha) |
| 2 | Cóc Phun Độc, Đỉa Đầm, Goblin Cung Độc, Goblin Móc Túi, Goblin Đặt Bom, Nhện Đầm, Thạch Băng, Cá Sấu | Mụ Phù Thủy Cóc (2 dạng) |
| 3 | Sói Đen, Chuột Ngục, Lính Bánh Gừng (+ bánh nhỏ *biến thể*), Quạ Đen, Mèo Đen | Bà Cả, Bà Hai, Bà Út, Mụ Già Ba Mặt |
| 4 | Cướp Dao, Cướp Ném Lưới, Cướp Cung, Dê Núi, Rắn Đá | Phó Tướng Cướp, Thủ Lĩnh Cướp, Mụ Tóc Rắn |
| 5 | Chim Bão, Tiên Nhỏ Tinh Nghịch, Rùa Đá Già, Mây Giông, Nhện Đồng Hồ | Người Giữ Suối (2 dạng trẻ/già) |
| 6 | Thằn Lằn Lửa, Rồng Con, Golem Dung Nham | Kỵ Sĩ Đen, Rồng (3 pha), Bà Tiên Đen |

**47 quái**: 2 đã có, 3 là biến thể cùng dáng (đổi màu, đổi cỡ), còn lại 42 bộ mới. Mỗi quái thường cần các clip `idle`, `attack`, `hurt`, `special`, `defeat`, `victory`. Trùm vẽ thêm pha sau.

### Nhân vật

| Nhân vật | Cần vẽ |
|---|---|
| **Công chúa / Hiệp Sĩ Bí Ẩn** | Nhân vật chơi được: đủ clip như hiệp sĩ (`idle`, `attack`, `hurt`, chiêu…), bản đeo mặt nạ và bản lộ mặt, 3 mức thương tích |
| Hiệp sĩ | Đã có; thêm bản **tay không** (không giáp, không kiếm) cho hồi 3, bản hóa đá, bản cưỡi Pegasus |
| Bà Tiên Ngông | Dáng thật + 4 lốt cải trang, vẫy đũa, cười |
| Pegasus | Bay, đậu, cùng hiệp sĩ cưỡi |
| Ông già, Bin, ba đứa trẻ, Người Cây | Chủ yếu cho truyện tranh; thêm ảnh đứng để hiện trên bản đồ |
| Ba con chuột | Cảnh kết hồi 3 |

### Ảnh khác

- **Bộ gạch theo vùng**: 5 bộ mới (đầm lầy, rừng đen/kẹo, núi, trên mây, núi lửa).
- **Nền trận đánh**: 5 nền mới.
- **Bản đồ**: 7 đoạn dọc nối liền, 100 nút; nút khó, nút trùm, nút thưởng, nút có cánh hoa.
- **Vật cản**: khoảng 20 loại, mỗi lớp một hình, kèm clip vỡ.
- **Biểu tượng**: chiêu, bùa, vật phẩm, món đồ truyện.
- **Truyện tranh**: 7 chương + chương giữa + 2 kết, khoảng 6–10 khung dọc mỗi chương, không chữ.

Mọi clip **vẽ tay từng khung**, không dựng bằng Python từ một ảnh đứng.

---

## 9. Chiêu, trang bị, vật phẩm

### Tuyệt chiêu của hiệp sĩ

| Chiêu | Mở ở | Tác dụng (đề xuất) |
|---|---|---|
| Phá Giáp ✅ | Màn 1 | Bóc 1 lớp khiên rồi đánh như 8 ô đỏ |
| Hồi Quang ✅ | Màn 7 | Hồi 25 máu |
| Hộ Thể | Màn 10 (giúp Bà Tiên) | Đòn kế tiếp của quái nhẹ đi 12 |
| Lôi Trảm | Màn 29 (sách của Bin) | Đánh như 8 ô đỏ, quái chậm 1 lượt |
| Rễ Trói | Màn 37 (Người Cây) | Quái không đánh được 1 lượt; quái bay rơi xuống đất 2 lượt |
| Phong Kiếm | Màn 52 | 3 nhát, mỗi nhát như 3 ô đỏ |
| Tinh Kiếm | Màn 66 | Như 7 ô đỏ, xuyên khiên |
| Ngưng Thời | Màn 80 | Đóng băng đồng hồ quái 2 lượt, phá hết ô héo |
| Long Trảm | Màn 97 | Như 15 ô đỏ, gấp đôi lên rồng và quái bay |

- **Ô chiêu thứ hai** mở sau màn 58.
- **Cấp chiêu 1–3** nâng bằng sách chiêu lấy từ rương sao.
- **Công chúa** có thanh Nộ riêng và 3 chiêu riêng: Kiếm Mảnh (đánh nhanh nhiều nhát), Khiên Gương (dội đòn kế tiếp), Hoa Hồng (hồi máu, giải độc).

### Trang bị

| Ô | Các bậc |
|---|---|
| Vũ khí | Kiếm gỗ → sắt → thép → bạc (hồi 3) → kiếm trời (hồi 5) → kiếm rồng (hồi 6) |
| Rèn kiếm | +1 … +5, mở dần từ hồi 2 |
| Giáp | Da → sắt → **Giáp Kháng Độc** (truyện) → kháng lửa (nâng ở lò rèn) |
| Nón | Da → sắt → mũ tàng hình (hồi 5: quái đánh trượt khi hiệp sĩ vừa tung chiêu) |
| Ủng | Gia cố → leo núi → **ủng có cánh** (hồi 5: né đòn đầu tiên mỗi trận) |
| **Bùa** (ô mới, hồi 2) | Chọn 1 trong 8: Giải Độc, Nộ (vào trận có 30 Nộ), Vàng (+15%), Sét (quét 2 hàng), Bom (nổ 5×5), Sao, Thép (giảm thêm 1 mỗi đòn), Đuổi Cóc |

Trang bị hiện trên người hiệp sĩ: thân đổi theo giáp, kiếm và nón là lớp chồng.

### Vật phẩm dùng một lần (mua bằng vàng)

Búa Đập Ô (phá 1 ô, không tốn lượt), Bình Nộ (vào trận có 50 Nộ), Tim Thêm (+20 máu tối đa trong màn), Sao Khởi Đầu (bảng có sẵn 1 sao), Thêm 5 Lượt (khi thua màn giới hạn lượt).

### Kinh tế

- Vàng mỗi màn tăng dần theo hồi, cộng ô vàng gom được trong trận.
- **Rương sao** mỗi 15 sao: vàng, sách chiêu, vật phẩm.
- **Rương mốc** ở màn 25, 50, 75, 100.
- Bot đo vàng cả chiến dịch để mua được món mới khoảng mỗi 4–6 màn.

---

## 10. Độ khó và kiểm tra bằng bot

| Loại màn | Bot chơi khôn thắng | Bot ngẫu nhiên thắng |
|---|---|---|
| Màn dạy (giới thiệu thứ mới) | 98–100% | ≥ 80% |
| Màn thường | 85–95% | 40–70% |
| Màn khó ⚠ | 60–75% | 10–30% |
| Trùm 👑 | 65–80% | 15–35% |
| Màn tay không | 80–90% | ≥ 40% |
| Màn đố | Có ít nhất một lời giải trong số lượt cho phép | — |

Bot chạy **cả 100 màn liền**, mang theo đồ mua được bằng vàng kiếm được, có và không có các món đồ truyện, để kiểm tra trận rồng thắng được khi thiếu món nhưng khó hơn hẳn.

---

## 11. Thứ tự làm

Mỗi giai đoạn là một hoặc vài PR chơi được ngay, đi kèm một đợt ảnh của ChatGPT. Code chạy trước với hình tạm, không chờ ảnh.

| Giai đoạn | Code (Claude) | Màn | Ảnh (ChatGPT) |
|---|---|---|---|
| **G1 Nền tảng** | Dữ liệu màn (`data/levels/level_###.tres`); các kiểu mục tiêu; lớp vật cản (thùng, đá); bảng có lỗ; sao theo mục tiêu; thẻ mục tiêu trước màn; bản đồ 100 nút; **trình đọc truyện tranh**; cánh hoa | 1–18 | Quái hồi 1, thùng, đá, đoạn bản đồ 1–2, truyện Ch.1–2 |
| **G2 Đầm lầy** | Độc; cóc độc, bùn, mạng nhện, bom hẹn giờ, băng; trùm 2 pha; ô bùa; Bà Tiên Ngông cải trang | 19–36 | 9 quái, bộ gạch đầm lầy, nền, Ch.3, Bà Tiên Ngông |
| **G3 Rừng đen** | Chế độ tay không; gai, kẹo, lửa, khóa màu; quái tách đôi; trùm nhập ba; ô chiêu thứ hai | 37–58 | 9 quái, bộ gạch rừng đen, nền, hiệp sĩ tay không, Ch.4–5 |
| **G4 Vùng núi** | Đối thủ có Nộ (ĐẤU); lưới, tượng đá, ô gương; **nhân vật công chúa chơi được**; vòng quay | 59–74 | 8 quái, công chúa đủ clip, bộ gạch núi, nền, Pegasus, Ch.6 |
| **G5 Suối Nguồn** | Quái bay; mây, ô héo, đồng hồ cát, tua sát thương; trùm đổi pha qua lại | 75–88 | 6 quái, bộ gạch trên mây, nền, Ch.7 |
| **G6 Hang rồng** | Pha trên không cưỡi Pegasus; trứng, xích; rồng 3 pha; trận Bà Tiên Đen có đồng minh; hai kết thúc | 89–100 | 6 quái, bộ gạch núi lửa, nền hang, 2 kết |

---

## 12. Đang tạm chọn, cần người dùng chốt

1. **Tên công chúa**: tạm là **Hồng Vàng**.
2. **Con rồng**: tạm là **thú bị Bà Tiên Đen điều khiển**, được giải phép rồi chở hai người về. Phương án khác: rồng là hoàng tử bị yểm phép.
3. **Chơi bằng công chúa** ở màn 73–74 (và có thể thêm về sau): tạm là **có**. Đây là điểm nhấn lớn nhất, nhưng tốn ảnh một nhân vật mới.
4. **Màu thứ 5** (ô xanh dương nạp Nộ): tạm bỏ, để dành nếu cần thêm nấc khó.
5. **Trận nhiều quái cùng lúc** (ba mụ): tạm thay bằng ba trận liên tiếp rồi nhập làm một (màn 55–58).
