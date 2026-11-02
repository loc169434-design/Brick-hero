# Bộ ảnh vương quốc — bàn giao cho Claude

Nhánh `art/kingdom`, tạo độc lập từ main `b4c61d7`, không chứa commit FX hoặc thiết kế quái. Thứ tự chiến dịch, ID món và thoại dựa trên [monsters.md ở nhánh docs/monsters](https://github.com/loc169434-design/Brick-hero/blob/docs/monsters/docs/ideas/monsters.md), commit `a606d5f`. Nên duyệt tài liệu thiết kế đó cùng PR ảnh trước khi ghép UI. Chỉ thêm file trong `assets/` và `docs/ideas/`.

## Bộ game dùng — 41 PNG, 4 rig, 1 dữ liệu bản đồ

| Thư mục | PNG | Nội dung |
|---|---:|---|
| assets/characters/hero_iron/ | 17 | fresh/bruised/battered × idle/attack/hurt/scared/cheer, victory, defeat |
| assets/characters/king/ | 4 | idle, talk, cheer, worried |
| assets/characters/princess/ | 4 | idle, talk, cheer, scared |
| assets/characters/blacksmith/ | 4 | idle, talk, hammer, cheer |
| assets/bg/ | 3 | king_hall, forge, world_map |
| assets/ui/ | 3 | map_node_locked, map_node_open, map_node_done |
| assets/ui/items/ | 6 | wood_sword, iron_sword, tempered_sword, leather_armor, iron_armor, reinforced_boots |

Mỗi thư mục nhân vật có `rig.json`; bản đồ có `assets/bg/world_map.json`. [Danh sách đầy đủ file mới](kingdom_files.txt) bao gồm ảnh bằng chứng và công cụ xuất, không chỉ asset game.

## Giữ nét gốc và quy cách nhân vật

Dùng trực tiếp anh hùng gốc làm tham chiếu: người lớn, hàm dài/góc cạnh, tóc nâu hất, mắt nhỏ khi cười, nụ cười trắng rộng, khăn đỏ, áo xanh xám viền kem, quai da chéo, ủng gập. Viền nâu đậm và mảng khối đơn giản cùng họ với bộ issue #5. Không dùng lại các bản thử chibi. [So cạnh tân binh ở 360px](kingdom_review/compare.png).

`hero_iron` thay kiếm gỗ bằng lưỡi sắt xám có mặt sáng, thêm giáp ngực/vai/cẳng tay sắt; tóc và khăn vẫn nhận ra, không đội mũ che đầu. Khiên gỗ viền kim loại giữ cùng thiết kế. Ba mức: fresh sạch; bruised băng trán/má, kiếm nguyên nhưng nứt, giáp móp/xước; battered mắt bầm, khăn/áo tưa, giáp móp sâu, kiếm gãy và khiên mẻ. Các vết móp là hình lớn để đọc được khi thu nhỏ. Dáng attack dùng tư thế gọn, gối chùng và kiếm chéo ra trước, tránh sải quá rộng làm cả người bị thu nhỏ. Victory giơ kiếm nguyên và cười; defeat ngồi bệt, giáp móp/kiếm gãy, mắt xoáy; giữ cỡ đầu khi ngồi.

Vua: vương miện/râu bạc/áo choàng đỏ. Công chúa trưởng thành: tóc nâu, váy xanh cổ kín và vương miện nhỏ. Thợ rèn: áo xanh, tạp dề da, ria/râu nâu, búa sắt. Không vẽ chữ hoặc hiệu ứng bay cố định vào các dáng.

- Mọi pose: PNG RGBA **512×512**, gốc chân **(256,500)**, alpha ngoài hình bằng 0. Có khoảng trống quanh tóc, vũ khí, tay, chân; pixel thấp nhất y=500.
- Canvas được hiển thị cỡ **360×360** như CharacterRig hiện tại. Dáng đứng cao khoảng400px trong PNG, dáng ngồi thấp tự nhiên; không phóng to dáng ngồi cho đầy canvas.
- Anh hùng quay phải, ba NPC quay trái. Dáng kết trận có góc quay ra người xem như issue #5.
- Rig gồm `id`, `canvas`, `feet`, `anchors`; mỗi tên pose có `head` và `mouth` theo tọa độ PNG512. Chấm xanh/hồng trong trang xem là điểm neo, không có trong PNG.
- Vẽ với `s=display_size/512`, top-left=`vị trí chân trên cảnh − rig.feet*s`; cùng phép biến đổi cho anchors. Không flip ảnh NPC thêm lần nữa.

## Nền và điểm dừng

Ba nền **1080×1920 opaque**. `king_hall`/`forge` không có người baked vào. Có sàn trống cho chân hai nhân vật tại `(270,1250)` và `(810,1250)`. Dưới y=1350 là sàn tối ít chi tiết; trang review thử khung thoại tại y1410. Việc đổi vùng nhập thoại hoặc danh sách món do Claude quyết định theo UI thật. Nguồn nền được đăng ký lại hai vùng trên/dưới để mốc vùng tối khớp y1350, không chỉ resize theo cảm tính.

`world_map.json` là một array đúng `{id,x,y}`, tọa độ tâm trên PNG1080×1920, thứ tự dưới lên: `scarecrow`, `orc_shield`, `frost_slime`, `goblin_thief`, `stone_golem`, `rune_witch`, `royal_dragon`. Node đầu là ID quái `scarecrow`; `training_field` là ID nền, không dùng thay ID quái. Tọa độ đo trên hình cuối thay cho bố cục gợi ý trong tài liệu quái. [Ảnh overlay xác minh](kingdom_review/map.png).

Ảnh map chỉ có đường đất, các khoảng dừng trống và cảnh quan; không số/khóa/dấu hoàn thành. Ba icon128px đặt tâm tại JSON. Trạng thái 2 điểm done, 1 open và 4 locked trong review chỉ là ví dụ, không phải save hay tiến độ thật.

Icon món256px không có giá/chữ. Kiếm thép phân biệt bằng rãnh xanh xám; kiếm sắt trơn; giáp da nâu, giáp sắt bạc; đôi ủng có nẹp thép. Giá 0/45/70/30/65/35 trong review là đề xuất từ tài liệu, chưa phải số cân bằng đã chốt.

## Xem thử và kiểm tra

[Trang review](kingdom_review.html): chọn nền/NPC/dáng hero, hiện đường chân và anchors; so hero sắt với tân binh đúng cỡ360; hiển thị map theo JSON; xem cả29 pose và9 icon. Chạy qua máy chủ tĩnh ở gốc repo; không cần sửa game để xem.

- [17 dáng hero](kingdom_review/hero_iron_360.png) · [vua](kingdom_review/king_360.png) · [công chúa](kingdom_review/princess_360.png) · [thợ rèn](kingdom_review/blacksmith_360.png).
- [Sảnh vua](kingdom_review/king_hall_king.png) · [công chúa sau thắng](kingdom_review/king_hall_princess.png) · [lò rèn](kingdom_review/forge_blacksmith.png) · [các món](kingdom_review/items.png).
- [metrics.json](kingdom_review/metrics.json): mỗi41 PNG có kích thước, min/max alpha, bbox; mỗi29 pose thêm feet, đường pixel chân thực tế và hai anchors; có7 node và kích thước hiển thị.

Chạy lại `node docs/ideas/kingdom_verify.mjs` với Node, Playwright và Chromium. Đã chạy **257 kiểm tra PASS** trên bộ cuối. Kiểm tra kích thước, alpha, lề an toàn, đường chân, đủ29 anchors, đủ7 ID/đúng thứ tự và tọa độ trong ảnh; lưu ảnh bằng chứng. Đây là kiểm asset và HTML, không chạy gameplay.

`kingdom_pack.mjs` chỉ tách/đăng ký/nén raster được vẽ bằng công cụ ảnh; không tạo code game. `kingdom_sources.json` ghi sheet và thứ tự các pose; `kingdom_registration.json` ghi nguồn/scale/offset/anchors. Ảnh nguồn ngoài repo trong `/workspace/generated_images`; có thể dùng `IMAGE_SOURCE_DIR` khi tái xuất nếu còn giữ chúng. Các PNG cuối và rig độc lập, không cần công cụ xuất lúc chơi.

## Những phần còn cần duyệt

- Claude cần ghép cảnh hội thoại/shop/map và thử trên điện thoại; review chỉ dựng bố cục tĩnh, không khẳng định logic tương tác hoạt động.
- Thiết kế skill/giá đồ trong `docs/monsters` còn chờ mô phỏng. Việc này chưa vẽ bộ gạch hoặc thân bốn quái mới/rồng.
- Chỉ có bộ hero_sắt hoàn chỉnh; chưa có ảnh riêng cho mọi phối đồ lai hoặc kiếm thép. Xem đề xuất hình tạm trong tài liệu quái trước khi cho mua trang bị; UI chỉ số phải dùng món thật.
- Điểm neo được xem trực tiếp trong lưới; chuyển pose/FX miệng trong Godot vẫn cần chơi thử để chốt cảm giác. Búa `hammer` không có đe kèm sprite, nên hoạt ảnh gõ ở UI cần đặt đe/điểm va chạm riêng.
