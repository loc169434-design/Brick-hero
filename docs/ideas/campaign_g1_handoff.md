# Campaign 100 — đợt ảnh G1, màn 1–18

Theo [kế hoạch Claude, bản e7839d7](https://github.com/loc169434-design/Brick-hero/blob/e7839d73bab727bea10494f56c8569e4819d48d5/docs/campaign_100.md), mục 8 và 11. Nhánh `art/campaign-100-g1`, từ `main` tại `36db7f9`. Đây là đợt G1; G2–G6 chưa sản xuất trong đợt này. Không đổi code, scene, test, balance hay dữ liệu màn của Claude.

## Xem ảnh

[Trang duyệt toàn bộ GIF, bản đồ và truyện](campaign_g1_review/index.html).

- Orc Ném Đá: [đánh](campaign_g1_review/orc_rock_attack.gif), [chiêu](campaign_g1_review/orc_rock_special.gif).
- Orc Trống Trận: [chiêu trống](campaign_g1_review/orc_drummer_special.gif).
- Kỵ Lợn Orc: [húc](campaign_g1_review/orc_boar_attack.gif).
- Tù Trưởng: [khiên](campaign_g1_review/orc_chief_special.gif), [pha nổi điên](campaign_g1_review/orc_chief_enraged_attack.gif).
- [Bản đồ 1](campaign_g1_review/map_01_nodes.jpg), [bản đồ 2](campaign_g1_review/map_02_nodes.jpg).
- [Truyện chương 1](campaign_g1_review/chapter_01.jpg), [chương 2](campaign_g1_review/chapter_02.jpg).

## Nhân vật — 31 clip, 160 ô

Đường dẫn `assets/characters/<id>/anim/fresh_<clip>.png`, ô RGBA 512×512, 4 cột, ô thừa alpha 0. JSON cùng quy cách `CharacterRig`. Điểm chân `(256,500)`; đầu/miệng trong rig là điểm gần đúng để bắt đầu tích hợp, cần căn lại theo khung nếu thêm thoại/FX chính xác.

| ID | Nội dung | Clip |
|---|---|---|
| `orc_rock` | Túi đá, ném đá nhỏ, nhấc đá lớn bằng hai tay | đủ 6 |
| `orc_drummer` | Trống đeo bụng, đánh nhịp và thúc trống | đủ 6 |
| `orc_boar` | Cả Orc lẫn lợn trong một sprite, húc, dựng chân | đủ 6 |
| `orc_chief` | Vương miện xương/đồng, áo choàng đỏ, chùy, khiên | đủ 6 |
| `orc_chief_enraged` | Pha 2, bỏ khiên, hai tay cầm chùy | idle, attack, special |
| `scarecrow_wood` | Bù nhìn gỗ có khớp, gậy tập | idle, attack |
| `scarecrow_straw_shield` | Bù nhìn có khiên rơm | idle, hurt |

Sáu clip của quái: idle **4 @8fps**, attack **6 @12fps**, hurt **4 @12fps**, special **8 @12fps**, defeat **6 @10fps**, victory **4 @8fps**. Attack chạm khung 4; special chạm khung 5 (đếm từ 0). Pha nổi điên attack **8 @16fps**, chạm khung 4; roar special **4 @8fps**, khung 2. Bù nhìn gỗ attack chạm khung 2. Idle lặp; các clip khác giữ khung cuối. GIF review lặp để dễ soi, không thay cờ loop của JSON.

Đầu/cuối attack/hurt/special về đúng pixel idle 0, idle cuối cũng khớp idle 0. Defeat giữ dáng ngồi choáng, không máu me. Các ảnh đứng và `defeat.png`/`victory.png` đi kèm để fallback. Bộ này chỉ có **fresh**; đã kiểm `CharacterRig` dùng fallback fresh ở cả ba mức máu, chưa có diễn xuất thương tích riêng. Bù nhìn biến thể giữ phạm vi clip tối thiểu theo cách hoạt động của chúng, không giả thành quái có đủ sáu clip.

Khiên Tù Trưởng nằm trong hình vẽ pha 1. Khi hết khiên, Claude chuyển sang ID pha 2; bộ này không có bốn texture khiên tách lớp để tự gỡ từng miếng. Tốc độ/chuyển pha/di chuyển lợn/đá bay vẫn do code điều khiển. Chưa có quái mới trong dữ liệu trận, nên không coi gameplay 18 màn đã xong.

## Thùng và đá

`assets/board/obstacles/`: thùng 1/2/3 lớp, đá nguyên/nứt, 256×256 RGBA; `crate_break` và `rock_break` là atlas 4 ô 512×512 @12fps, không loop, ô cuối trống hoàn toàn. Khai báo trong `obstacles.json`. Chưa áp luật nổ cạnh vào resolver.

## Hai đoạn bản đồ

`assets/bg/campaign/segment_01.png` và `segment_02.png`, mỗi đoạn 1080×1920. Đoạn 1 lâu đài/bãi tập, đoạn 2 trại Orc tới đầm lầy. Không số/khóa/trạng thái màn vẽ vào ảnh. `nodes_g1.json` có đúng **18** mức, tọa độ theo từng đoạn, thứ tự dưới lên; cờ khó 14, thưởng 15, trùm 18, cánh hoa 5. Số đỏ chỉ có trong ảnh review.

Code ghép đoạn 2 phía trên đoạn 1. Đây là hai tranh độc lập cùng bảng màu và đường giữa; mép ghép chưa được vẽ thành một dải liền pixel, cần transition/crossfade ngắn hoặc tinh chỉnh mỹ thuật khi ghép bản đồ dài. Chưa thay bản đồ 15 điểm đang dùng trên main, chưa tạo 100 node giả.

## Truyện chương 1–2

`assets/story/chapter_01/` và `chapter_02/`, mỗi chương **6 khung**, rộng 1080px, RGB, không thoại/chữ trong ảnh. `chapter.json` khai báo thứ tự và mốc sau màn 5/18. Chương 1: tập luyện → quà sinh nhật → Bà Tiên Ngông → lời thử → rồng bắt → công chúa thả cánh hoa khi vẫn trên không. Chương 2: cho bánh → lốt bà lão → Hiệp Sĩ Bí Ẩn tặng bình máu → phá khiên → Tù Trưởng thua → tới đầm lầy. Chưa lộ mặt công chúa và không thêm cánh hoa ngoài mốc kế hoạch.

`assets/ui/campaign/`: tám PNG RGBA 256×256: badge màn khó/trùm/thưởng/cánh hoa, cánh hoa vàng, cờ Orc, lồng và chìa khóa. Là overlay riêng, không vẽ vào map; code tự gắn số/trạng thái.

## Nguồn và đóng gói

Ảnh nguồn vẽ bằng công cụ tạo ảnh theo tư thế hoàn chỉnh, lưu tại `campaign_g1_sources/`, có `.gdignore`. Script chỉ cắt ô, co đồng đều cả hình, đăng ký chân, đóng atlas/GIF; không dựng khớp từ một ảnh đứng. Nguồn hiện có độ phân giải ô thấp hơn 512; 512 là cỡ canvas xuất, không phải tuyên bố mọi nét được vẽ ở độ phân giải đó. Cần đánh giá độ sắc và nhịp ngắn của clip trên điện thoại trước khi chốt chất lượng phát hành.

```sh
python docs/ideas/pack_campaign_g1.py
python docs/ideas/check_campaign_g1.py
godot --headless --editor --path . --import --quit
godot --headless --path . -s res://docs/ideas/campaign_g1_resource_smoke.gd
godot --headless --path . -s res://tests/run_tests.gd
```

Dùng Godot **4.7.2**, không dùng binary 4.6.3 mặc định của máy onboarding. Nếu HOME không ghi được, đặt XDG_DATA_HOME, XDG_CONFIG_HOME, XDG_CACHE_HOME vào thư mục writable ngoài checkout như cấu hình onboarding đã lưu.

## Kiểm tra

- [Kiểm ảnh](campaign_g1_review/validation.json): 560 điều kiện đạt, 160 ô nhân vật; alpha, ô thừa, đầu/cuối idle, số hình khác nhau, kích thước, impact, bản đồ, truyện và icon.
- [Godot resource smoke](campaign_g1_review/resource_smoke.log): **31 clip**, fallback ba mức máu, 12 khung truyện, 2 bản đồ; **0 failures**.
- [Suite hiện có](campaign_g1_review/godot_tests.log): **93 passed, 0 failed**.
- Atlas hoạt hình dùng `compress/mode=2` theo test của repo.
- Chưa tích hợp/chụp gameplay quái mới, chưa chạy bot campaign 100 màn, chưa kiểm thử điện thoại. Đó là các bước tích hợp code và nghiệm thu tiếp theo, không phải kết quả của kiểm ảnh.

## Trạng thái GitHub

Đã push commit ảnh `4b3270c` lên `origin/art/campaign-100-g1`. Lệnh mở draft PR trả `Post "https://api.github.com/graphql": Forbidden`, nên **chưa tạo được PR**, chưa merge. Claude có thể fetch trực tiếp nhánh hoặc mở PR tại [trang so sánh](https://github.com/loc169434-design/Brick-hero/compare/main...art/campaign-100-g1?expand=1).
