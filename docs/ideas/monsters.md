# Đường tới hang rồng — đề xuất cho Claude mô phỏng

Nhánh `docs/monsters`, từ main `b4c61d7`. Chỉ thêm tài liệu này. **Chỉ số, kỹ năng, kinh tế và trang bị dưới đây là đề xuất, chưa được mô phỏng hoặc triển khai.** Claude cần kiểm khả năng hỗ trợ chiêu trước khi vẽ gạch/quái mới và chạy bot trên luật thật trước khi chốt số liệu. Bản vẽ vương quốc ở việc 3 có thể dùng ID/ngoại hình tại đây; không có nghĩa kỹ năng đã được duyệt.

## Luật giữ nguyên và thứ tự xử lý đề xuất

Bảng 7×8 luôn đủ 56 ô; bốn màu; nối từ 3 ô cạnh ngang/dọc, không đi chéo. Hàng thẳng từ 4 ô tự nổ. Nối 5/6/7 trở lên sinh sét/bom/sao theo luật hiện tại; không đổi điều kiện sao hoặc fusion.

Mỗi ô đỏ gây 2 sát thương, xanh hồi 1 máu, vàng cho 1 vàng, tím phá 2 điểm khiên; một lớp khiên 10 điểm, khi còn khiên sát thương bị giảm một nửa. Chuỗi x1, x2, x3… Hiệp sĩ có tối đa 100 máu. Bù nhìn 40 máu/1 khiên/không đánh; Orc Khiên 60 máu/3 khiên/đánh 12 mỗi 3 lượt: giữ nguyên.

Quy ước cho các chiêu mới, để Claude xác nhận:

1. Một **lượt hợp lệ** là đường nối được luật chấp nhận. Kéo sai/hủy không trừ countdown hay thời hạn trạng thái.
2. Hoàn tất đường nối, toàn bộ các ClearStep, rơi/lấp và dây chuyền trước khi quái phản công. Nếu quái chết, hủy chiêu đang báo và đòn đánh của nó.
3. Countdown trừ một lần mỗi lượt hợp lệ, không theo số vòng dây chuyền. Khi còn 1, báo rõ đòn và chiêu; khi về 0 mới đánh rồi hồi về countdown gốc. Trạng thái mới xuất hiện sau đòn đánh không mất tuổi ngay ở lượt sinh ra.
4. Mọi kỹ năng chọn mục tiêu sau khi bảng ổn định; không tạo lỗ. Nếu mục tiêu không hợp lệ hoặc làm mất mọi nước nối, giảm số mục tiêu hoặc bỏ chiêu. Không đổi màu/ngưỡng nối để cưỡng ép có nước đi. Xáo bảng chỉ khi không còn nước nối, giữ các đặc biệt và bỏ trạng thái của trận nếu cần để tránh kẹt; cách giữ đặc biệt cần Claude duyệt với resolver hiện tại.
5. Đóng băng/khóa là lớp phủ, ô đá là thay thế có lưu màu cũ. Không áp vào ô đặc biệt, không chặn việc kích nổ đặc biệt. Một ô chỉ mang một trạng thái. Khi thua, đổi trận hoặc rồng đổi giai đoạn, xóa trạng thái tạm. Không tặng tài nguyên khi trạng thái chỉ tự hết hạn.
6. Chiêu của quái này không được mang qua trận sau. Thứ tự áp màu tím/đỏ trong cùng ClearStep giữ theo code hiện tại; mô phỏng phải ghi rõ kết quả khi phá khiên và đánh cùng bước, tránh vô tình đổi luật.

## Bốn quái sau Orc

Các số tăng dần là giả thuyết về độ khó; hồi máu, chuỗi và nâng cấp có thể đảo thứ tự thực tế.

| id | Tên | max_hp | shield_layers | attack | countdown |
|---|---|---:|---:|---:|---:|
| frost_slime | Thạch Băng Nhút Nhát | 70 | 1 | 13 | 3 |
| goblin_thief | Goblin Móc Túi | 80 | 2 | 14 | 3 |
| stone_golem | Người Đá Gác Cầu | 100 | 4 | 18 | 4 |
| rune_witch | Phù Thủy Mực Tím | 110 | 2 | 17 | 3 |

### frost_slime — Thạch Băng Nhút Nhát

Một cục thạch đội xô, hắt hơi là cả bảng lạnh run.

**Chiêu “Hắt hơi lạnh”**: kèm mỗi đòn đánh, đóng băng tối đa 2 ô thường bất kỳ đang không có trạng thái. Lúc countdown=1, báo biểu tượng băng và số 2, chưa cố định tọa độ vì ô còn rơi. Sau đòn mới chọn ô bằng RNG có seed. Băng cấm chọn ô đó trong đường nối tay, nhưng màu gốc vẫn hiện. Một ClearStep xóa ô kề cạnh ngang/dọc sẽ làm tan băng, giữ nguyên ô và không nhận tài nguyên từ ô vừa tan. Tự nổ hàng 4 và hiệu ứng đặc biệt vẫn xóa được ô băng theo màu gốc. Hết 2 lượt hợp lệ tiếp theo thì tan; tổng cộng tối đa 2 ô băng, không làm mới tuổi ô cũ. Mô phỏng lựa chọn mục tiêu chỉ chấp nhận cấu hình vẫn có ít nhất một đường nối hợp lệ.

**Ưu tiên**: đỏ để kết thúc nhanh vì ít khiên; xanh để bù các đòn đều. Người chơi chủ động nối gần băng để mở đường dài.

**Gạch**: mặt thạch cùng một silhouette tròn lệch, viền nâu và khối phẳng như Orc. Đỏ đeo khăn đỏ; xanh đội lá; vàng đội xô đồng; tím đội mũ len vá. Màu khung chiếm diện tích đủ lớn, thêm huy hiệu kiếm/lá/đồng xu/khiên để phân biệt khi nhìn xám. Đau: má ép lệch; sợ: môi run, mắt nhỏ liếc; chế giễu: lè lưỡi; đắc thắng: phồng má cười. Không răng nhọn kinh dị.

**Nền**: bờ suối mùa lạnh, cầu gỗ thấp, lau sậy phủ sương; sàn đất rõ đường chân, tránh trắng quá sáng sau mặt thạch.

### goblin_thief — Goblin Móc Túi

Tên trộm bé người luôn đếm nhầm tiền ngay trước mặt chủ.

**Chiêu “Túi thủng”**: sau mỗi đòn, đánh dấu tối đa 2 ô vàng thường khác nhau bằng móc túi nhỏ. Đây là thay đổi bảng dạng lớp phủ, không đổi màu hay cấm nối. Dấu theo ô khi rơi. Xóa ô đánh dấu bằng bất kỳ cách nào trước đòn kế tiếp sẽ hủy dấu và nhận vàng như thường. Ở đòn kế tiếp, mỗi dấu còn lại lấy tối đa 2 vàng từ túi người chơi rồi xóa dấu, tổng tối đa 4 và không âm; không xóa ô. Sau đó mới đặt tối đa 2 dấu mới. Không có ô vàng thì không đặt dấu; không trộm dựa trên ô vừa đánh dấu. Báo trước 1 lượt cả số dấu chưa gỡ và số vàng tối đa có thể mất. Vàng trộm được giữ riêng và trả đủ khi thắng; thua mất phần đã bị trộm, số chưa bị lấy vẫn giữ. Quy tắc giữ vàng sau thua cần Claude mô phỏng.

**Ưu tiên**: vàng để gỡ dấu và mua đồ, tím phá hai lớp khiên rồi đỏ. Có thể bỏ qua dấu khi túi đang rỗng hoặc sắp kết liễu quái.

**Gạch**: tai dài nhỏ hơn Orc, răng cửa vuông, khăn che cổ không che hết mặt. Đỏ khăn buộc đầu; xanh lá ngụy trang; vàng túi tiền làm mũ; tím bịt mắt một bên. Đau: rụt tai; sợ: mắt nhìn túi rỗng; chế giễu: nhếch một khóe miệng; đắc thắng: cười nhắm mắt ôm đồng xu. Phụ kiện vẫn nằm trong khung.

**Nền**: chợ rừng bỏ hoang, xe kéo, biển túi tiền không có chữ, dây cờ vải; khoảng đất trước rộng và ít chi tiết.

### stone_golem — Người Đá Gác Cầu

Người gác cầu rất nghiêm, chỉ quên mất mình chính là cục chắn đường.

**Chiêu “Đá lăn”**: sau mỗi đòn, thay tối đa 1 ô thường bằng đá, tổng tối đa 2 viên. Mỗi viên lưu màu gốc và vị trí trong lưới, là một ô đầy: không chọn nối, không mang màu, không tham gia hàng 4 và không sinh tài nguyên. Không thay ô đặc biệt hoặc ô đã mang trạng thái. Mỗi ClearStep có ít nhất một ô bị xóa cạnh viên đá làm mất 1 độ bền, tối đa một lần mỗi viên mỗi ClearStep; độ bền ban đầu 2. Đặc biệt quét trúng phá ngay. Khi phá, viên đá bị xóa không nhận tài nguyên, rơi/lấp bình thường; dây chuyền có thể tiếp tục. Sau 3 lượt hợp lệ mà chưa phá, trả lại màu đã lưu, không phát tài nguyên và không rơi. Thời điểm hết hạn trước kiểm nước đi tiếp theo, không giữa resolver. Nếu không thể đặt mà vẫn có nước nối thì bỏ chiêu. **Cần thêm loại ô cản và sự kiện phá đá; chưa chắc resolver hiện có hỗ trợ.**

**Ưu tiên**: tím phá bốn lớp khiên; xanh khi chờ đòn 18; sét/bom để dọn đá. Không làm đá tự biến thành ô vàng thưởng.

**Gạch**: đầu đá vuông có mũi lớn, nứt ít, không giống đầu lâu. Đỏ băng vải; xanh rêu; vàng đinh đồng; tím phiến đá phù văn. Đau: mảnh vụn nhỏ; sợ: hai lông mày dựng; chế giễu: miệng lệch; đắc thắng: hàm đá cười rộng. Khuôn mặt giữ tương phản rõ khi thu 46px.

**Nền**: cầu đá qua khe núi, lan can đổ và dây thường xuân, đá tiền cảnh nằm ngoài đường chân.

### rune_witch — Phù Thủy Mực Tím

Bà phù thủy dùng bút phép để sửa bài thi của hiệp sĩ.

**Chiêu “Gạch sai màu”**: mỗi đòn đánh xong khóa chọn tay đúng 1 màu trong 1 lượt hợp lệ tiếp theo. Khi countdown=1, chọn màu dự kiến và hiện rõ huy hiệu màu/hình tương ứng. Lúc áp chiêu kiểm lại: nếu khóa màu đó khiến không còn đường nối, chọn một màu khác theo thứ tự đỏ→xanh→vàng→tím có đường nối còn lại; nếu không có thì bỏ khóa và nói “Hết mực!”. Không cộng dồn/khóa lại tuổi cũ. Ô vẫn giữ màu, vẫn rơi; hàng tự nổ và đặc biệt vẫn xóa bình thường, sao không bị cấm chọn. Hết lượt hợp lệ sau đó mở khóa trước kiểm nước đi. Không khóa thao tác màu khác hoặc kéo sai. **Cần rule chọn tay theo màu; chưa chắc code hiện hỗ trợ.**

**Ưu tiên**: tím trước, đỏ ngay khi mở khóa; chuẩn bị đường xanh/vàng thay thế. Không bắt người chơi chọn một màu đang bị cấm để gỡ chính nó.

**Gạch**: mặt phù thủy trưởng thành vui tính, mũ méo ngắn, không nanh/răng kinh dị. Đỏ lông vũ; xanh nấm lá; vàng kính tròn đồng; tím mũ vá có ngôi sao. Đau: kính lệch; sợ: mím môi; chế giễu: cười một bên; đắc thắng: cười tít mắt giơ bút trong góc khung.

**Nền**: thư viện cây cổ thụ, lọ mực và sách lớn, sàn rễ cây phẳng ở vùng nhân vật, tránh chữ giả trên sách.

## royal_dragon — Rồng Giữ Vương Miện

Rồng thích sưu tầm vương miện; công chúa đang bắt nó xếp lại kho.

Một trận gồm 3 thanh máu nối tiếp, không phải 3 quái trên bản đồ. Hiệp sĩ không tự hồi đầy, vàng giữ nguyên và bảng giữ lại. Mỗi giai đoạn bắt đầu có bộ khiên mới theo bảng; không cộng khiên của giai đoạn cũ.

| phase | max_hp | shield_layers | attack | countdown | Chiêu sau đòn |
|---|---:|---:|---:|---:|---|
| 1 — canh cửa | 70 | 2 | 17 | 4 | Hai ô băng, cùng luật frost_slime |
| 2 — nổi cáu | 80 | 1 | 19 | 3 | Một ô đá, cùng luật stone_golem, max 2 |
| 3 — giữ của | 90 | 0 | 21 | 3 | Khóa một màu 1 lượt, cùng luật rune_witch |

Đủ 240 HP tổng nhưng có ngắt giai đoạn. **Đề xuất chuyển pha tại cuối lượt**: khi HP pha về 0, dừng nhận sát thương vào quái cho phần còn lại của lượt, vẫn giải quyết hồi máu/vàng/rơi, bỏ sát thương dư, không tăng thêm chuỗi cho pha sau. Xóa mọi trạng thái của pha trước, đặt HP/khiên/countdown pha mới; không phản công hoặc giảm countdown trong lượt chuyển pha. Báo tên pha, rồi người chơi có lượt tiếp theo bình thường. Tránh nhiều pha chết trong một lượt hay rồng đánh lén khi đổi pha. Claude cần mô phỏng tradeoff bỏ sát thương dư; nếu đổi chính sách phải ghi lại trước khi làm UI.

Pha 1 thở hơi lạnh, ưu tiên tím/đỏ. Pha 2 nghiêng thân húc đá, ưu tiên đặc biệt/xanh. Pha 3 hết khiên, vương miện nghiêng, ưu tiên đỏ, giữ một đường thay thế khi màu bị khóa. Tất cả đòn/chiêu đều báo trước khi countdown=1; pha mới luôn bắt đầu đủ countdown. Chiêu bị hủy nếu HP pha hết trong lượt chặn đòn.

Thắng pha 3: kết trận, xóa trạng thái, trả phần vàng đang bị giữ nếu có, công chúa bước ra và cười; không còn đòn hậu tử. Thua: HP hiệp sĩ về 0, rồng ôm kho báu cười, không chạy tiếp resolver/đồng hồ trận.

**Bộ gạch**: cùng một đầu rồng tròn góc, mõm ngắn vừa phải, viền nâu, sừng ngắn; đỏ khăn, xanh lá, vàng mũ miện nhỏ, tím mũ vá. Đau há miệng méo; sợ mắt liếc xuống HP; chế giễu cười hếch mõm; đắc thắng cười ôm vương miện. Khi thoát chết: run trước, thở phào rồi mới cười; chết: há miệng la, mắt mở to, không máu me. Đổi mức trầy xước theo pha, không đổi silhouette/mã màu.

**Nền**: sân trước hang rồng, cột đá và kho vàng phía sau; ban công/lối thoát cho công chúa ở bên phải, không vẽ nhân vật cố định vào nền.

## Thứ tự bản đồ dùng cho việc 3

| Thứ tự | id node = id quái | Cảnh trận | Điểm gợi ý trên ảnh 1080×1920 |
|---:|---|---|---|
| 1 | scarecrow | training_field | (540,1700) |
| 2 | orc_shield | orc_camp | (300,1460) |
| 3 | frost_slime | frost_stream | (720,1210) |
| 4 | goblin_thief | forest_market | (330,980) |
| 5 | stone_golem | stone_bridge | (730,760) |
| 6 | rune_witch | tree_library | (350,510) |
| 7 | royal_dragon | dragon_lair | (550,260) |

`training_field` là ID nền, còn node đầu dùng `scarecrow` để ID trùng quái như yêu cầu. Tọa độ trên là bố cục mục tiêu; việc 3 giao `world_map.json` theo đúng tâm điểm trên ảnh cuối. Đường từ lâu đài phía dưới đi qua đúng 7 điểm lên hang phía trên, không thêm điểm giả. Không vẽ sẵn số, khóa hoặc dấu hoàn thành trên map; ba trạng thái là icon UI rời.

## Lò rèn — 6 món và giá thử nghiệm

Một ô vũ khí, một ô giáp, một ô ủng. Sở hữu không đồng nghĩa cộng tất cả chỉ số; dùng đúng món cao nhất đã trang bị trong mỗi ô. Giá là tiền mua bước đó, không phải tổng tiền đã chi; không hoàn tiền, không bán lại. Kiếm thép cần kiếm sắt, giáp sắt cần giáp da; tân binh bắt đầu có kiếm gỗ. Các món còn lại mua độc lập sau Orc. Mua/trang bị ngoài trận, không đổi chỉ số giữa resolver.

| id món / tên icon | Tên | Giá vàng | Ô | Tác dụng chính xác |
|---|---|---:|---|---|
| wood_sword | Kiếm gỗ | 0 | vũ khí | Đỏ 2.0 sát thương/ô (cơ bản) |
| iron_sword | Kiếm sắt | 45 | vũ khí | Đỏ 2.5/ô, thay kiếm gỗ; +0.5 so cơ bản |
| tempered_sword | Kiếm thép | 70 | vũ khí | Đỏ 3.0/ô, thay kiếm sắt; +1.0 so cơ bản |
| leather_armor | Giáp da | 30 | giáp | Giảm 2 sát thương mỗi đòn quái |
| iron_armor | Giáp sắt | 65 | giáp | Giảm 4 mỗi đòn, thay giáp da |
| reinforced_boots | Ủng gia cố | 35 | ủng | Giảm thêm 1 mỗi đòn quái |

Sát thương đỏ = số ô × giá trị vũ khí × hệ số chuỗi, rồi áp giảm do khiên theo code hiện tại. Không làm tròn riêng từng ô; giữ float cho đến bước code đang quyết toán để không làm +0.5 biến mất. Không tăng vàng/hồi máu/phá khiên theo vũ khí. Giáp/ủng là giảm phẳng sau attack, không nhân theo số ô hay chuỗi: đòn nhận = max(1, attack − giảm giáp − giảm ủng). Tổng giảm tối đa 5; không biến đòn thành hồi máu. Chiêu bảng vẫn áp nếu đòn chỉ còn 1 sát thương.

Mục tiêu tạm: mua một món sau Orc, nâng cấp dần trước rồng; **chưa có số đo thu nhập vàng để bảo đảm giá này phù hợp**. Đề xuất giữ vàng chưa tiêu sau thua, không nhân thêm thưởng vượt trận trong bản đầu; hồi về 100 HP khi bắt đầu một trận mới, riêng chuyển pha rồng không hồi. Chưa có save/shop nên cần Claude chốt vòng đời chiến dịch, chống mua trùng và kiểm giao dịch âm tiền trước khi dùng.

**Hình món cho việc 3**: kiếm gỗ nâu không cạnh thép; kiếm sắt lưỡi xám thẳng/chuôi vàng; kiếm thép lưỡi sáng dài với rãnh xanh xám; giáp da áo nâu có khóa đồng; giáp sắt ngực thép mảng lớn/đinh tán; ủng da nâu có nẹp thép. Không chữ hay giá baked vào icon.

**Giới hạn hình trang bị**: việc 3 chỉ yêu cầu bộ `hero_iron` (kiếm sắt + giáp sắt cùng lúc). Không có bộ lai “kiếm sắt + giáp da”, hoặc kiếm thép riêng. Tạm đề xuất đổi sang `hero_iron` khi có cả kiếm sắt và giáp sắt, còn các phối đồ khác dùng hình tân binh; UI phải phản ánh chỉ số món thật. Claude/người dùng cần duyệt cách hiển thị tạm này hoặc đặt thêm ảnh trước khi phát hành, không ghép pixel đổi màu thay cho asset chưa có.

## Lời thoại

Mỗi dòng dưới 60 ký tự Unicode, không tính nhãn người nói.

### Sảnh nhà vua — 8 câu

| Người nói | Câu |
|---|---|
| Vua | Ai ghi danh đi cứu công chúa? |
| Hiệp sĩ | Thần ạ! Kiếm gỗ cũng được tính chứ? |
| Vua | Được. Miễn con đừng dùng để nhóm lửa. |
| Hiệp sĩ | Thần đã vượt bài thi đánh bao rơm! |
| Vua | Tốt. Bao rơm có viết thư giới thiệu không? |
| Hiệp sĩ | Nó chỉ rơi ra một nắm rơm, thưa bệ hạ. |
| Vua | Qua lò rèn rồi đi. Cứu người trước, khoe sau. |
| Hiệp sĩ | Tuân lệnh! Thần xin giữ lại nắm rơm làm tin. |

### Lò rèn — 3 câu

| Người nói | Câu |
|---|---|
| Thợ rèn | Kiếm gỗ à? Ta sửa được… thành củi. |
| Hiệp sĩ | Vậy cho tôi thanh kiếm chịu được tiếng Orc cười. |
| Thợ rèn | Kiếm sắt đây. Tiếng cười thì dùng giáp đỡ nhé! |

Không vẽ lời thoại trong PNG. King `worried` dùng khi nhắc công chúa, `talk` khi giao nhiệm vụ, `cheer` chúc đi đường; thợ `hammer` trong lúc xem hàng; công chúa `scared` trước đòn rồng, `cheer` sau chiến thắng.

## Việc cần Claude xác minh trước khi triển khai

- Chạy từng quái và rồng bằng 3 bot như B5: thắng, lượt, HP còn, vàng kiếm/tiêu, mức trang bị; có/không skill để đo chênh lệch. Không coi bảng số trên là kết quả cân bằng.
- Kiểm trạng thái khi ô rơi, hàng 4, special đi qua, hai special cùng nổ, đá nứt qua nhiều ClearStep, timeout và xáo bảng không làm kẹt. Chọn mục tiêu theo seed để tái hiện.
- Xác nhận đơn vị countdown và thứ tự tím/đỏ với code thật. Thử kết liễu đúng lượt đòn/đổi pha, chết cùng lượt, phần sát thương dư và hoàn vàng chỉ một lần.
- Kiểm font/UI màu khóa ở 46px và ảnh xám; giảm số overlay nếu che mặt gạch. Chưa vẽ bộ gạch cho bốn quái/rồng trong việc này.
- Chốt giá/shop/save và hình các phối trang bị còn thiếu. Nếu chiêu đá/khóa chưa hỗ trợ thì hoãn quái đó hoặc xin duyệt thay chiêu, không tự đổi luật lõi.
