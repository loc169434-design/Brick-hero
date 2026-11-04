# Hợp thể và tuyệt chiêu — đề xuất để duyệt

Theo [yêu cầu](specials_skills_request.md), dựa trên main `26b8800`. Đây là thiết kế, chưa thay luật hay dữ liệu game. Ảnh hợp thể và tư thế tuyệt chiêu chỉ sản xuất sau khi duyệt tài liệu này. Bộ bom/sét/sao thử riêng trên `art/specials-3d`.

## 1. Ngôn ngữ chung

- Bom, sét, sao là ô vạn năng, nối mọi màu và nối nhau. Không hiện màu ẩn, không có nền ô. Hình khối, ánh sáng trên-trái, viền mực đậm; code vẽ bóng chân.
- Bảng 7 cột × 8 hàng: x=0..6, y=0..7, góc trên-trái (0,0). Chỉ tính ô có trong bảng; cắt vùng ở biên, không cuộn sang mép đối diện. Một ô bị phủ nhiều lần chỉ xoá và tính tài nguyên một lần mỗi đợt.
- Hợp thể cần hai ô đặc biệt kề cạnh ngang/dọc, cùng được kích hoạt trong đợt. Nối được với nhau không có nghĩa hai ô cách xa tự hợp thể. Mỗi ô tham gia tối đa một cặp/đợt; xét nguồn nổ theo thứ tự giải quyết hiện có, xét bạn ghép theo trên → phải → dưới → trái. `p` là ô nguồn, `q` là bạn ghép; giữ tâm p như luật hiện tại. Đề nghị Claude chốt thứ tự này trước khi triển khai để replay ổn định.
- Dùng hợp vùng: xoá vùng + cả p,q. Ô đặc biệt khác trong vùng vẫn kích hoạt một lần; cặp đã tiêu thụ không nổ lại riêng. Chốt toàn bộ vùng trên ảnh chụp bảng trước khi rơi/bù ô.
- Chữ comic tiếng Anh cố định dưới đây, dùng Bangers hiện có, không sinh chữ trong atlas VFX. Mỗi đợt chỉ hiện một chữ chính; giảm rung/chớp nếu bật giảm chuyển động.

## 2. Đủ sáu cặp không phân biệt thứ tự

Ký hiệu: `C(p)` = hàng và cột qua p; `S(p,r)` = vuông bán kính r; `T` = tập ô thường mang màu mục tiêu trước khi nổ. Các số ví dụ chưa tính nổ dây chuyền.

| Cặp | Tên / file hiệu ứng dự kiến | Vùng xoá trên bảng 7×8 | Cảm giác và kịch bản hiệu ứng | Chữ comic |
|---|---|---|---|---|
| Bom + bom | Đại Bộc Phá / `double_bomb.png` | `S(p,2) ∪ {q}`: 5×5, giữa bảng 25 ô; p=(0,0),q=(1,0): 9 ô | Hai bom ép vào nhau 0–0,15s; lõi trắng-vàng 0,15–0,25s; vòng xung kích và khói cuộn 0,25–0,65s. Cảm giác nặng, một tiếng trầm, rung tối đa 8px ở canvas 1080. | `MEGA BOOM!` |
| Sét + bom | Thập Tự Sấm / `thunder_cross.png` | Mọi ô có `abs(y-p.y)≤1` HOẶC `abs(x-p.x)≤1`, cộng q. 3 hàng + 3 cột giữa bảng = 21+24−9 = 36 ô; góc = 14+16−4 = 26 | Tụ điện 0–0,12s; nổ giữa 0,12–0,22s; ba luồng song song quét bốn hướng 0,22–0,55s; tia vụn tắt trước 0,75s. Giữ đường phân ô dễ nhìn. | `THUNDER BOOM!` |
| Sét + sét — **mới** | Bát Hướng Lôi / `double_lightning.png` | `C(p)` cộng hai đường chéo `abs(x-p.x)=abs(y-p.y)`, cộng q. p=(3,3),q=(4,3): 26 ô; p=(0,0),q=(1,0): 20 ô. Không xoá các ô nằm giữa tia. | Hai sét khoá thành lõi kim cương; 0,12s bắn dấu +, 0,22s bắn dấu ×; nhánh điện theo đúng ô được xoá, tắt 0,65s. Nhận ra ngay tám hướng, khác chữ thập dày. | `THUNDER STORM!` |
| Sao + bom | Mưa Bom / `star_bomb.png` | `⋃ S(t,1), t∈T`, cộng p,q. Mỗi ô màu mục tiêu biến thành bom ảo rồi nổ 3×3; tối đa 56 ô | Sao phóng các sợi sáng tới T 0–0,25s; hiện bóng bom ảo tại T; đồng nổ thành gợn nối nhau 0,25–0,70s, tắt 0,90s. Không để bom tồn tại sau đợt. | `BOMB RAIN!` |
| Sao + sét | Bão Sét / `star_lightning.png` | `⋃ C(t), t∈T`, cộng p,q. Mỗi ô mục tiêu phát một chữ thập một ô rộng; tối đa 56 ô | Nối các tâm bằng tia sao 0–0,20s; lóe sét tại T 0,20–0,30s; hàng/cột bật liên tiếp trong 0,30–0,70s. Vùng trùng không chớp lặp. | `LIGHTNING RAIN!` |
| Sao + sao | Siêu Tân Tinh / `double_star.png` | Cả 56 ô có trên bảng; không xoá lại lứa ô mới rơi xuống | Hai sao xoắn vào nhau 0–0,25s; bốn cánh bung thành quang cầu 0,25–0,40s; sóng lan từ tâm tới mép 0,40–0,85s. Một flash ngắn ≤60ms, không phủ trắng cả màn hình lâu. | `SUPERNOVA!` |

### Màu mục tiêu: nhìn được và đoán được

Đề xuất sửa sự lệ thuộc màu ẩn của sao+X: lấy màu thường của đường nối kích hoạt; nếu kích hoạt từ nổ dây chuyền hoặc đường chỉ toàn đặc biệt, lấy màu có nhiều ô thường nhất trên ảnh chụp bảng. Hoà số lượng chọn đỏ → xanh lá → vàng → tím. Nếu không còn ô thường, T rỗng, chỉ tiêu thụ p,q; các đặc biệt khác vẫn theo luật kích hoạt vùng nếu có. Khi kéo qua cặp sao+X, tô nhẹ tất cả T để báo trước; không dùng màu lưu bên trong X vì người chơi không thấy nó.

Sao + ô thường không phải cặp hợp thể thứ bảy: sao xoá toàn bộ ô thường màu đang nối, kèm các đặc biệt trong đường. Bom đơn vẫn 3×3; sét đơn vẫn một hàng+một cột (14 ô giữa bảng). Bốn loại tài nguyên của ô bị xoá vẫn tính theo màu gốc, không biến toàn bộ thành sát thương.

### Hợp thể nhiều ô

Đường có ba đặc biệt trở lên tạo các cặp rời theo thứ tự trên, phần lẻ nổ đơn; không tạo công thức ba ngôi trong bản đầu. Chỉ hiện chữ của cặp phủ nhiều ô nhất, hoà ưu tiên sao+sao → sao+sét → sao+bom → sét+bom → sét+sét → bom+bom. Tổng hiệu ứng chạy song song, không xếp hàng nhiều giây. Tính năng này là đề xuất triển khai, không khẳng định code hiện tại đã làm đủ.

## 3. Mốc cân bằng và cách dùng tuyệt chiêu

Đọc trực tiếp `data/balance.tres` ở main `26b8800`: HP anh hùng **100**; đỏ **2 sát thương/ô**, xanh lá **1 HP/ô**, tím **2 điểm khiên/ô**, vàng **1 vàng/ô**; lớp khiên **10 điểm**; còn khiên thì sát thương đỏ ×**0,5**; dây chuyền đợt n ×n; crit ×**2**, xác suất nền **5%**. Orc Khiên hiện HP **60**, 3 lớp (=30 điểm khiên), đánh **12**, đếm ngược **3 lượt**.

Đề xuất 6 chiêu để lựa chọn, **chỉ trang bị một chiêu mỗi trận**, chưa phải mở cả sáu cùng lúc. Thanh Nộ 0–100; ô thường xoá lần đầu trong lượt +1 Nộ, mỗi hợp thể +12, tối đa +40/lượt. Không nạp từ ô đặc biệt, hồi máu, hoặc sát thương của chính chiêu. Đầy thanh thì sáng nút chiêu; người chơi bấm vào đầu lượt trước khi nối ô. Tiêu 100 Nộ, tối đa một lần/lượt, không tốn lượt và không giảm bộ đếm quái. Không giữ Nộ dư trên 100. Ngừng nhận input trong hoạt cảnh; hiệu lực chỉ áp một lần ở mốc chạm. Không tự động phát chiêu giữa chuỗi nổ.

Mọi số dưới đây là **bonus cố định**, cộng sau báo cáo lượt thường, không hưởng crit hoặc hệ số dây chuyền; không tạo ô đặc biệt và không gây vòng lặp Nộ. Nếu lượt thường đã kết thúc trận, không được dùng chiêu. Các số là điểm khởi đầu để thử, chưa đổi `balance.tres`.

### 3.1 Phá Giáp — `armor_breaker`

- Kích hoạt: trang bị chiêu, đủ 100 Nộ, bấm nút **Phá Giáp**.
- Tác dụng: bóc **10 điểm khiên**, sau đó gây **12 sát thương cơ bản**; nếu vẫn còn khiên, phần sát thương ×0,5. Tương đương 5 ô tím + 6 ô đỏ ở đợt 1. Ví dụ Orc đầy khiên: 30→20 khiên, HP 60→54. Khi chỉ còn 10 khiên: 10→0, HP 60→48. Khi hết khiên từ trước chỉ gây 12, không đổi phần bóc khiên thành damage.
- 0–0,35s: hạ trọng tâm, tay khiên chắn trước, kiếm rút sau vai (`brace`). 0,35–0,75s: lao vai, mũi kiếm hướng tới giáp (`thrust`), vệt hẹp màu hổ phách. **0,75s chạm**: nứt lớp khiên, vòng mảnh kim loại, comic `ARMOR BREAK!`, dừng hình 70ms, camera xê ngang ≤8px. 0,82–1,25s: bật người về, khiên vỡ rơi. 1,25–1,80s: trở lại idle; camera về vị trí cũ.

### 3.2 Lôi Trảm — `thunder_slash`

- Kích hoạt: đủ 100 Nộ, bấm **Lôi Trảm**; phù hợp người hay tạo hợp thể sét để nạp Nộ nhanh, không bắt buộc phải giữ sét trên bảng.
- Tác dụng: **16 sát thương cơ bản**, bị khiên giảm còn 8; cộng **trễ đòn quái 1 lượt** vào bộ đếm hiện tại, không cộng dồn vượt 1 lượt trễ đang chờ. Tương đương 8 ô đỏ; trễ một nhịp, không choáng vĩnh viễn.
- 0–0,40s: giơ kiếm chéo trên đầu (`charge`), điện chạy quanh lưỡi, giữ mặt/tay. 0,40–0,85s: chém xuống (`slash`), vệt cong cyan với lõi trắng. **0,85s chạm**: tia điện chạy trên giáp, `THUNDER SLASH!`, rung 5px trong 120ms, biểu tượng đếm ngược +1. 0,97–1,45s: Orc giật ngắn, điện tắt. 1,45–2,00s: anh hùng thu kiếm (`recover`), về idle. Không xoá ô trên bảng.

### 3.3 Hồi Quang — `second_wind`

- Kích hoạt: đủ 100 Nộ và thiếu HP; nút vô hiệu khi đầy HP, không tiêu Nộ.
- Tác dụng: hồi **18 HP**, chặn ở HP tối đa; tương đương 18 ô xanh đợt 1, khoảng 1,5 đòn đánh thường của Orc. Không gây sát thương hay kéo dài lượt.
- 0–0,35s: quỳ một gối, kiếm dựng đầu mũi xuống đất (`kneel`), tay đặt lên ngực. 0,35–0,90s: ánh xanh ngọc xoáy lên thân, các mảnh lá sáng chạy vào HP. **0,90s hồi**: `SECOND WIND!`, số +HP thực nhận. 0,90–1,45s: khăn bay, ngẩng đầu (`rise`). 1,45–1,90s: đứng lên và trả idle. Camera nâng nhẹ 6px, không rung, không che thanh HP.

### 3.4 Hộ Thể — `iron_guard`

- Kích hoạt: đủ 100 Nộ, chưa có buff Hộ Thể, bấm **Hộ Thể**.
- Tác dụng: đòn đánh kế tiếp của quái giảm **12 HP sát thương** sau khi tính crit, chặn ít nhất về 0, tiêu buff khi đòn đánh xảy ra; không tồn tại sang trận khác. Ví dụ Orc thường 12→0, crit 18→6. Không thêm khiên lên bảng và không cộng dồn; đánh giá lại nếu boss đánh nhiều hit (bản đầu coi cả sự kiện đánh là một đòn, giảm tổng 12).
- 0–0,30s: hai chân trụ, nâng khiên (`brace`). 0,30–0,80s: hình khiên xanh lam nổi sau khiên thật, viền sáng ép vào người. **0,80s áp buff**: `IRON GUARD!`, gợn lục giác bung nhỏ, camera push 2% tối đa. 0,80–1,30s: khiên sáng co về biểu tượng buff; 1,30–1,80s: trả idle. Khi hấp thụ đòn sau đó chỉ có flash 0,25s, không phát lại hoạt cảnh.

### 3.5 Phong Kiếm — `blade_vortex`

- Kích hoạt: đủ 100 Nộ, bấm **Phong Kiếm**.
- Tác dụng: **3 nhịp ×6 =18 sát thương cơ bản**, mỗi nhịp còn 3 nếu có khiên, tổng 9 khi bị giáp. Tương đương 9 ô đỏ, không bóc giáp. Khi mục tiêu chết ở nhịp sớm, các nhịp sau chỉ hoàn tất VFX, không đánh sang quái kế tiếp. Một lần dùng, không phải 3 lượt và không tạo 3 lần nạp Nộ.
- 0–0,30s: kiếm ngang hông, co người (`windup`). 0,30–0,65s: xoay người giữ tay/kiếm nhất quán (`spin`), vệt trắng-xanh vòng quanh thân. **0,65/0,95/1,25s**: ba nhát, comic `BLADE VORTEX!` chỉ ở nhát đầu; mỗi nhát dừng hình 35ms, camera rung 3px, tổng biên độ không cộng dồn. 1,25–1,70s: lốc tan, khăn đáp. 1,70–2,20s: chống kiếm lấy thăng bằng (`land`), về idle.

### 3.6 Tinh Kiếm — `starfall_strike`

- Kích hoạt: đủ 100 Nộ, bấm **Tinh Kiếm**. Cùng chi phí với các chiêu khác, mạnh về xuyên giáp nhưng không xoá bảng/hồi HP.
- Tác dụng: **14 sát thương xuyên khiên**, không trừ điểm khiên. Tương đương 7 ô đỏ khi không giáp; khi quái còn giáp, bằng 14 ô đỏ thường. Orc đầy khiên HP 60→46, khiên vẫn 30. Không crit hay ×n.
- 0–0,45s: ngửa kiếm đón một sao bốn cánh (`charge`), vàng/pearl. 0,45–0,95s: bật nhảy (`leap`), vệt sao kéo sau người; camera nâng 10px. **0,95s chạm**: bổ chéo xuyên lớp khiên bằng ánh sao, `STARFALL!`, vòng sáng chỉ qua thân quái; khiên không vỡ. 0,95–1,30s: mảnh sao tản, hạ người (`strike`). 1,30–1,85s: tiếp đất (`land`), camera hạ. 1,85–2,35s: trả idle.

## 4. Quy cách ảnh sau khi duyệt

- Hợp thể: sáu atlas ở `assets/fx/fusions/` theo tên trong bảng; mỗi khung 512×512, **16 khung, 24 fps, không loop**, 8 cột ×2 hàng =4096×1024. `fusions.json` có `frame_width`, `frame_height`, `frames`, `fps`, `loop`. Hạt cuối phải tắt về alpha 0. Thời gian bảng trên là nhịp cảm nhận; atlas dài 2/3s, có thể start trễ/rải emitter để kéo hiệu ứng sao tới 0,9s.
- Một khung 512 không mô tả thay cho luật vùng xoá: renderer cần instance hiệu ứng tại các ô/vùng đã tính, đồng bộ nhánh sét tới đúng ô; không kéo méo 512 thành toàn bộ bảng 7×8. Các atlas là lớp trang trí, không tự quyết định ô trúng.
- Tư thế: `assets/characters/hero_rookie/skill_<id>_<pose>.png`, 512×512, anchor chân theo bộ đang có. Chỉ bắt đầu với trạng thái fresh; khi duyệt mới mở rộng thương tích. Tái dùng cùng mặt, áo, khiên, tay cầm và texture kiếm. Tối đa 3–4 key pose/chiêu nêu ở từng mục; giữ khung giữa các pose nếu cần. Không yêu cầu sinh cả nhân vật độc lập từng frame.
- VFX chiêu: `assets/fx/skills/<id>.png`, mặc định **512×512 ×16 khung @24 fps**, 8 cột; `skills.json` theo schema trên. Nếu cần vệt ngang rộng hơn: ghi riêng frame_width=768, frame_height=512 trước khi vẽ. Cảnh chiêu 1,8–2,35s dùng timing hold, pose, emitter và camera; không kéo chậm atlas cho đủ cảnh.
- Comic: chỉ thêm khi chưa có chữ tương ứng; PNG512×320 ở `assets/fx/comic/`, Bangers. Spellings khoá theo bảng/chiêu. Không có chữ comic trong texture nhân vật hay VFX.
- Kèm GIF đúng fps, ảnh từng khung đánh số trên nền xanh đậm, manifest, trang review và danh sách file. Kiểm tra alpha bằng ghép lên xanh đậm, kiểm tra kiếm/mặt/áo không nháy. Không vẽ bóng chân baked vì code đã có.

## 5. Phạm vi bản đầu và cách duyệt

Chưa thêm ô đặc biệt mới: ba loại đã đủ sáu hợp thể; tránh xung đột ngưỡng sinh đặc biệt hiện tại. Sau khi đánh giá có thể đề xuất búa phá giáp riêng, chưa đưa vào bản này.

Ưu tiên duyệt: (1) vùng xoá sét+sét và màu mục tiêu sao+X; (2) thanh Nộ/một chiêu trang bị; (3) Phá Giáp và Hồi Quang làm thử trước, rồi bốn chiêu còn lại. Chưa có phần nào được áp vào code.

Đã tự kiểm: đối chiếu số trong balance và dữ liệu Orc; liệt kê đủ 3×4/2=6 cặp; đếm vùng ví dụ tại giữa/mép; timeline mỗi chiêu 1,8–2,35s; tên file/chữ comic thống nhất. Chưa kiểm thử trận thật, độ dễ đọc trên điện thoại, DPS dài hạn hay cân bằng boss — cần Claude tích hợp prototype sau khi người dùng duyệt.
