# Issue #41 — ảnh G2, đầm lầy Cóc & trại Goblin

Nhánh `art/campaign-100-g2`, tạo từ `main` mới nhất lúc bắt đầu (`36db7f9`). Theo [issue #41](https://github.com/loc169434-design/Brick-hero/issues/41). Chỉ sửa `assets/` và `docs/ideas/`.

**Người dùng đã duyệt nét V2 bằng phản hồi “Duyệt V2”.** Chương 2 đã vẽ lại đủ sáu khung và push ở `5725afb` trên `art/campaign-100-g1`; chương 3 đã hoàn thành **bảy khung** trên nhánh G2. [Đọc chương 2](https://github.com/loc169434-design/Brick-hero/blob/art/campaign-100-g1/docs/ideas/issue41_chapter2_review/webtoon.jpg) · [Đọc chương 3](issue41_chapter3_review/webtoon.jpg) · [Đối chiếu nhân vật chương 3](issue41_chapter3_review/sprite_comparison.jpg). Phần 0 G1 gồm sửa bản đồ, Tù Trưởng, Kỵ Lợn và bà lão; nét V2 chương 1 ở `46d7f0b`.

## Duyệt ảnh G2

**[Danh sách toàn bộ GIF/JPG](campaign_g2_review/index.md)** · [Gạch 128/46 px](campaign_g2_review/tiles_46px.jpg) · [Vật cản trên ô màu](campaign_g2_review/obstacles_on_tiles.jpg) · [Bản đồ 19–36](campaign_g2_review/map_03_nodes.jpg) · [Mép nối 3–2](campaign_g2_review/map_03_02_join.jpg).

## Nhân vật — 65 clip, 340 ô; thêm 5 ảnh NPC

Đủ chín quái thường/pha 1: `toad_spitter`, `swamp_leech`, `goblin_archer`, `goblin_thief`, `goblin_bomber`, `swamp_spider`, `frost_slime`, `crocodile`, `toad_witch`. Mỗi con có sáu clip như G1: idle **4@8fps**, attack **6@12fps**, hurt **4@12fps**, special **8@12fps**, defeat **6@10fps**, victory **4@8fps**. Impact attack khung 4, special khung 5. Victory bắt đầu bằng pixel idle và diễn đứng/cười, không dùng dáng ngồi choáng.

`toad_witch_giant` có idle/attack/hurt/special/defeat như trên; `special2` **4@8fps**, impact khung 2, thay cho victory. Attack quất lưỡi; special nhảy dậm; special2 mưa độc; defeat cuối là mụ già bé xíu chạy đi. Chuyển pha/giảm cỡ trong game do Claude xử lý, không thêm logic trận ở nhánh ảnh.

Goblin Cung Độc special giữ cả ba hình thả tên: `hits: [2,3,5]`, impact chính khung 5. Metadata là cue cho tích hợp, không tự tạo ba đợt sát thương. Goblin Đặt Bom châm/ngả bom; Nhện nhả tơ; Thạch Băng đội xô/hắt hơi; Đỉa phồng đỏ; Mụ Cóc có mũ lá sen, gậy nấm, cóc nhỏ trên vai.

NPC:

- `fairy_fickle`: idle/wave/laugh, mỗi clip **4@8fps**, dáng thật bà tiên già váy tím chắp vá và đũa cong, đồng nhất với lốt ăn xin G1.
- `fairy_crow`: idle/talk, **4@8fps**, quạ có lông mày bạc và nơ tím.
- `swamp_old_man`: `idle.png`, `talk.png`; `bin`: `idle.png`, `talk.png`, `cheer.png`. [Bảng năm dáng](campaign_g2_review/npc_stills.jpg).

Quy cách `assets/characters/<id>/anim/fresh_<clip>.png`, RGBA 512×512, 4 cột, chân `(256,500)`, quay trái. Đủ `anim.json`, `rig.json`, ảnh đứng và defeat/victory cho quái thường. Chỉ có fresh; đã kiểm fallback cả ba mức máu qua CharacterRig. Head/mouth cho thú thấp được đặt theo vùng hình thật thay vì ở trên đầu hình; vẫn là điểm gần đúng theo dáng idle, chưa phải track đầu/miệng từng khung cho VFX chính xác.

## Gạch cóc và vật cản

`assets/tiles/swamp/`: đủ bốn màu; tile 128×128; `expressions_<color>.png` 3×3 ô 128 và chín ảnh rời như Orc; `animations/` đủ 12 tên clip như Orc, **48 atlas**. Atlas 8 cột, ô 192×192, bốn cel vẽ độc lập cho mỗi hành động, ô thừa trong suốt. `SpriteFrames` từng màu đi kèm; thêm family `swamp` vào `animation_pack.json`, giữ nguyên mọi entry cũ.

Không tăng số hình vẽ bằng nội suy/cắt khớp. Death/win dùng chung cels fear+scream; taunt/lose dùng laugh; near_miss xếp fear→relief→laugh. Đây là tái dùng cel có chủ đích, ghi rõ trong `swamp_manifest.json`; số cel không bằng bộ 24 khung cũ. Giữ thời lượng cũ bằng fps tương ứng, cần chơi thử nhịp và độ đọc trên điện thoại. `TileArt.THEMES` vẫn do Claude thêm `swamp` khi tích hợp; nhánh ảnh không sửa script.

Vật cản trong `assets/board/obstacles/`: `poison_toad` và clip bốn khung thở/phun; `mud`, `web`, `time_bomb`, `ice_1`, `ice_2`, `gold_mark`, PNG RGBA 256. Băng có tâm trong để nhìn rõ màu bên dưới; bom chừa vòng trống cho code viết số. Thêm bảy atlas 4 ô 512 và khai báo vào `obstacles.json`; các clip vỡ kết thúc alpha 0. Giữ thùng/đá G1 trong manifest và file tương ứng để không có đường dẫn treo khi bắt đầu từ main chưa có G1.

## Nền và bản đồ

Hai nền `assets/bg/swamp/` và `assets/bg/goblin_camp/`, mỗi nền bốn lớp full canvas **1080×660**: sky, far, mid, ground. Nền sky opaque, các lớp vật thể tách alpha; một chút alpha mềm ở nền trại Goblin là sương nhẹ, không phải một tấm nền opaque. Có atlas đom đóm/bong bóng/lá sen **4@8fps**, khai báo vị trí/canvas/origin trong `layers.json` qua `ambient_effects`. Claude cần nối các effect mới vào renderer. Ảnh ghép nhân vật trong gallery là **offline art layout**, không phải gameplay đã tích hợp.

`segment_03.png` **1080×1920**, 18 node 19–36 theo `nodes_g2.json`: khó 28/34, thưởng 30, trùm 36, cánh hoa 33. Không số/UI baked vào map. `layout_g2.json` xếp từ trên xuống 3–2–1 ở y **0, 1720, 3440**, overlap **200 px**.

Để nối thực sự liền nét, đợt G2 **cập nhật cả 400 px trên của `segment_02.png`**; 1520 px còn lại giữ nguyên bản sửa G1 `8241c12`, gồm mép nối 2–1. 200 px dưới đoạn 3 bằng pixel 200 px trên đoạn 2 mới. Khi ghép nhánh, giữ `segment_02` của G2 và `segment_01` của G1; không dùng lại map2 cũ. **Tích hợp G1 trước G2**. Nhánh G2 không tự mang toàn bộ G1 vào main hoặc đổi lịch sử main.

## Truyện chương 3 — nét V2 đã duyệt

`assets/story/chapter_03/`, **7 khung** rộng 1080; cao **540, 1440, 720, 1440, 540, 720, 1440**. `chapter.json`: `after_level: 36`, `text_baked: false`, `style_revision: 2`, ghi nguồn duyệt nét “Duyệt V2”. Bút nâu mảnh có nét dò, màu phẳng tô thưa để lộ giấy, không glow/gradient/đèn điện ảnh; nền ít nét, khung cuối tràn mép.

Diễn biến: ông già báo Bin bị bắt → mở lồng cứu Bin trong trại Goblin → Bin đưa sách chiêu bìa tím có dấu sét → Mụ Cóc uống thuốc → cóc khổng lồ quất lưỡi, hiệp sĩ che cho Bin → mụ thu nhỏ bỏ chạy → nhận Giáp Kháng Độc màu xanh, cùng Bin đi về rừng đen. Giáp được cầm trên tay, hiệp sĩ vẫn mặc áo xanh khăn đỏ. Giữ đúng tóc/áo/túi của Bin, mũ ông già, mũ sen/gậy nấm/cóc vai của mụ. Không có chữ thoại trong ảnh.

[Gallery chương 3](issue41_chapter3_review/index.md) · [Kiểm truyện](issue41_chapter3_review/validation.json). Bản đọc webtoon **528.513 byte**, các preview GIF/JPG dưới 2 MB. Nguồn vẽ mới lớn nằm ngoài repo, đường dẫn và SHA-256 ở `story_chapter_03_sources.json`; script chỉ co đồng đều toàn khung và ghép ảnh đọc thử, không dựng tư thế bằng code. Người dùng đã xác nhận duyệt truyện chương 1–3 nét V2 trong lượt giao sửa atlas tiếp theo.

## Kiểm tra

- [Kiểm asset](campaign_g2_review/validation.json): **1.163 điều kiện đạt**; inventory, số ô/kích thước/alpha, VRAM import, victory về idle, manifest gạch cũ không đổi, băng nhìn xuyên tâm, overlap đúng pixel, cờ node và mọi preview dưới **2.000.000 byte**.
- [Smoke Godot 4.7.2](campaign_g2_review/resource_smoke.log): **65 clip** × ba fallback wear, **48 atlas gạch**, bốn SpriteFrames, 14 texture nền/ambient, **7 panel chương 3**; **0 failures**. Có tải cả vật cản và ảnh đứng NPC.
- [Kiểm truyện riêng](issue41_chapter3_review/validation.json): **49 điều kiện đạt**, thứ tự/kích thước/trigger/approval/source hash/preview.
- [Suite hiện có](campaign_g2_review/godot_tests.log): **93 passed, 0 failed**.
- [Smoke hai quái ưu tiên](campaign_g2_review/priority_smoke.log): 12 clip, **0 failures**.
- Chưa có gameplay màn 19–36, poison/bùn/bom/trùm hai pha, chưa chạy bot chiến dịch hoặc kiểm điện thoại. Đó là công việc tích hợp code của Claude; không dùng kiểm asset để tuyên bố các cơ chế đã chạy.

## Nguồn và tái xuất

Nguồn vẽ bằng công cụ ảnh theo từng tư thế/biểu cảm hoàn chỉnh, nằm **ngoài repo**; manifest đường dẫn và SHA-256 ở `campaign_g2_sources.json`. Không đưa PNG nguồn lớn vào nhánh. Preview mới chỉ GIF/JPG, từng file dưới 2 MB. Canvas nhân vật xuất 512, độ phân giải cel nguồn thường nhỏ hơn, cần đánh giá trên máy thật trước khi chốt phát hành.

```sh
python docs/ideas/pack_campaign_g2.py --group priority
python docs/ideas/pack_campaign_g2.py --group characters
python docs/ideas/pack_campaign_g2.py --group tiles
python docs/ideas/pack_campaign_g2.py --group world
python docs/ideas/pack_campaign_g2.py --group npcs
python docs/ideas/pack_campaign_g2.py --group story
python docs/ideas/check_issue41_story.py 3
godot --headless --editor --path . --import --quit
python docs/ideas/check_campaign_g2.py
godot --headless --path . -s res://docs/ideas/campaign_g2_resource_smoke.gd
godot --headless --path . -s res://tests/run_tests.gd
```

Dùng Godot **4.7.2**, thiết lập XDG writable như onboarding nếu cần. Khi tái xuất, cần giữ nguồn ngoài repo và Git object G1 `8241c12` (fetch `art/campaign-100-g1` nếu clone chưa có); packer chỉ cắt/co nguyên cel, đăng ký/đóng atlas, cắt overlap và xuất preview, không dựng nhân vật bằng code.

## Bàn giao GitHub

Đã push các nhóm G2: `334ce28` (hai quái ưu tiên), `27732eb` (gạch/vật cản/nền/map), `1c77f07` (quái còn lại và hai pha Mụ Cóc), `cbb0467` (NPC), `4942a02` (kiểm tra/bàn giao). Phần 0 ở nhánh G1 commit `8241c12` đã push trước đó.

Lệnh tạo draft PR G2 và comment vào #41 đều trả `Post "https://api.github.com/graphql": Forbidden`. **Chưa tạo được PR G2, chưa đăng comment, chưa merge.** [Nội dung comment lưu sẵn](campaign_g2_issue41_comment.md). Có thể mở từ [trang so sánh main…art/campaign-100-g2](https://github.com/loc169434-design/Brick-hero/compare/main...art/campaign-100-g2?expand=1). Không tự đóng issue; còn bước review/tích hợp code của Claude. Nét V2 đã được người dùng duyệt, truyện chương 2–3 đã xuất và kiểm tra.

## Sửa atlas sau duyệt — tiếp sau `10ccc4c`

Đã đóng lại đủ sáu clip Cá Sấu theo biên hàng nguồn thực tế, làm sạch attack 2–3 của Mụ Cóc. Luật mới quét **340 ô** theo phần alpha liên thông, từ chối mảnh rời **>200 pixel** trừ từng hiệu ứng có mask được đối chiếu rõ. Cùng luật bắt đủ **18 ô cá sấu lỗi ở commit cũ**. Khi chạy luật trên cả bộ, đã sửa thêm các mảnh lẫn ô cùng nguyên nhân ở Cóc Phun Độc và bốn ô của các actor khác. [Chi tiết, GIF và lệnh kiểm](issue41_atlas_repair.md) · [Kết quả liên thông](campaign_g2_review/contiguity_validation.json). Godot smoke 0 failures; suite 93/93.

## Bổ sung phương án gạch A/B theo comment #41

Đã hoàn thiện A theo khuôn Goblin/Orc trong `assets/tiles/swamp/`: khung bo góc, viền mực, bóng khối, da cóc tự nhiên, phụ kiện màu và huy hiệu vai trò. Thêm B đầy đủ cùng cấu trúc ở `assets/tiles/swamp_b/`: không huy hiệu, màu san hô/xanh ngọc/mật ong/chàm. Mỗi bộ 48 atlas và bốn SpriteFrames. Tên màu trong code và thời lượng clip giữ nguyên.

[So sánh ba hàng 128/46/xám](swamp_variants_review/comparison_3_rows.jpg) · [Bảng 7×8 A](swamp_variants_review/board_a_128px.jpg) · [Bảng 7×8 B](swamp_variants_review/board_b_128px.jpg) · [Bàn giao và số đo](swamp_variants_handoff.md). Chờ người dùng chọn A/B; không thay code chọn theme. PNG ngoài bộ swamp giữ nguyên, gồm Cá Sấu đã sửa ở `2f51e32`.
