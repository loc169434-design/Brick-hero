# Training + Orc: sprite, animation và FX

Nhánh `art/tiles`. Phong cách được người dùng chốt: bản khung gỗ có nẹp sắt; Orc có mũ vá/băng trán. Tất cả thay đổi nằm ở ảnh, tài nguyên ảnh và tài liệu xem thử; chưa nối vào logic game.

## Mở xem

- `/workspace/artifacts/brickbound-training-orc/preview_training_orc.html`: bản xuất HTML độc lập, đã nhúng PNG và dữ liệu; tải về mở bằng trình duyệt, không cần Internet. File xuất lớn nằm ngoài checkout để không lưu trùng ảnh trong Git.
- `docs/ideas/asset_preview/index.html`: bản xem nhẹ, tham chiếu các asset trong repo. Giữ đúng cấu trúc thư mục khi sao chép.
- `/workspace/artifacts/brickbound-training-orc/brickbound_training_orc.zip`: gói asset và trang xem thử. File ZIP đặt cạnh HTML độc lập để nút tải ZIP trong HTML hoạt động.

Chọn Training/Orc, chọn màu, chọn tình huống hoặc chạy cảnh liên tiếp. Có phát/dừng, tua từng frame, chỉnh tốc độ, chế độ lặp, xem ở kích thước game, xem 9 nét mặt gốc, xem/tải atlas và từng FX. Người bật giảm chuyển động trong hệ điều hành sẽ thấy cảnh tạm dừng khi mở trang. Nút kết quả thắng/thua luôn tính theo người chơi.

## File và kích thước

| Nội dung | Đường dẫn | Định dạng |
|---|---|---|
| Training 4 màu | `assets/tiles/training/tile_<color>.png` | RGBA 128×128 |
| Orc 4 màu | `assets/tiles/orc_shield/tile_<color>.png` | RGBA 128×128 |
| Nét mặt Orc | `assets/tiles/orc_shield/expressions/<color>_<pose>.png` | 36 PNG, 128×128 |
| Atlas nét mặt | `assets/tiles/orc_shield/expressions_<color>.png` | 3×3 ô, 384×384 |
| Chuyển động đã xuất | `assets/tiles/<family>/animations/<color>_<animation>.png` | 24 frame, 8×3 ô, ô 192×192, atlas 1536×576 |
| Godot SpriteFrames | `assets/tiles/<family>/sprite_frames_<color>.tres` | 8 tài nguyên sẵn dùng |
| FX | `assets/fx/tile_reactions/` | 8 PNG 128×128; atlas 512×256 |
| Manifest | `assets/tiles/animation_pack.json` | Rect, fps, loop, thời lượng, sự kiện |

`family`: `training` hoặc `orc_shield`. `color`: `red`, `green`, `yellow`, `purple`. Các frame đọc từ trái qua phải, trên xuống dưới, không có khoảng cách ngoài ô. PNG trong suốt; FX đã được ghép trong sheet chuyển động. Không ghép thêm FX lần nữa nếu không muốn hiệu ứng dày hơn.

Ô chuyển động có đệm để hình rung, nhảy và FX không bị cắt; gạch gốc nằm giữa, có canvas logic 128 px trong ô 192 px. Gốc Sprite2D đặt giữa ô (96,96). Khi game muốn canvas gạch 110 px, dùng scale `110/128` cho node (cả vùng đệm khi ấy rộng 165 px); không co cả ô 192 px về 110 px. Hình vẽ gốc có đệm trong suốt bên trong 128 px.

## Animation

Training có 7 cảnh: `idle`, `drop`, `land`, `combo`, `hurt`, `win`, `lose`.

Orc có 12 cảnh: các cảnh trên cộng `taunt`, `fear`, `near_miss`, `gloat`, `death`.

- `idle`: nhịp thở rất nhỏ; Orc chớp mắt. Mặc định lặp.
- `drop`: rơi tăng tốc, chạm đất nén và nảy, có bụi. Game đã tự di chuyển gạch thì chỉ gọi `land` để tránh rơi hai lần.
- `combo`: ô bị xóa; Orc chuyển sang hét, rồi biến mất trong FX vụn gỗ.
- `hurt`: bị đau nhưng sống, rung ngắn rồi bình thường.
- `taunt`: khúc khích → cười lớn sau lượt hụt/không xóa ô. Không hiện lời xúc phạm người chơi.
- `fear`: run, mắt hoảng khi dự đoán combo có thể hạ quái.
- `near_miss`: sợ 0–38% → nhẹ nhõm 38–60% → cười 60–100%. Dùng khi quái thực sự còn sống sau pha tưởng chí mạng.
- `gloat`: cười hiểm khi người chơi sắp thua.
- `death`: hoảng → hét → biến mất; chỉ dùng khi đã xác nhận bị hạ.
- `win`: người chơi thắng; Training nhảy mừng, Orc hét/biến mất, có confetti.
- `lose`: người chơi thua; Training chùng xuống, Orc cười hiểm rồi cười lớn và vẫn hiện trên sân.

Các cảnh không lặp giữ frame cuối. `combo`, `death`, và `win` phía Orc có frame cuối trong suốt. Không tự quay về `idle` sau chúng. Khi bắt đầu lượt hay trận mới, bên game quyết định reset hoặc tạo lại gạch.

## Hợp đồng sự kiện cho phần code

Manifest có `eventMap` và thứ tự ưu tiên. Bên game tính trạng thái thật rồi gửi sự kiện; trang HTML chỉ mô phỏng bằng nút bấm, chưa có nhận diện nước đi kém hoặc tính xác suất thua. Không phát `taunt` sau khi quái đã chết. Ưu tiên sự kiện kết thúc trận, tiếp đến xóa ô/chết, rồi hoảng/bị đau, sau cùng mới cười/chờ. `taunt`, `fear`, `near_miss`, `gloat`, `death` chỉ dành cho Orc, không gọi ở Training.

Không suy diễn “người chơi thua” từ một animation vừa kết thúc. Hai cảnh `death` và `win` phía Orc đều chứa đoạn bị hạ; chỉ chọn một nếu đã phát hiệu ứng kết thúc để tránh Orc xuất hiện trở lại. Nếu muốn confetti riêng sau `death`, dùng FX confetti chứ không reset gạch đã chết.

Trong Godot 4.7.2, gán `sprite_frames_<color>.tres` vào `AnimatedSprite2D.sprite_frames`, gọi `play(animation_name)`. Tốc độ và loop đã được lưu trong tài nguyên. Tài nguyên chỉ chứa ảnh và frame; script điều khiển trạng thái dành cho người phụ trách code. Không cần shader hay plugin mới.

## Xuất lại

Chạy `node docs/ideas/asset_preview/export.mjs` từ root repo. Cần Node.js, module `playwright`, ImageMagick và Chromium; biến `CHROMIUM_PATH` chọn binary khác nếu cần. Trên máy hiện tại các công cụ đã có. Script đọc các PNG gốc và dùng Canvas ghép chuyển động xác định, xuất sheet, tài nguyên Godot, manifest và HTML nhúng ảnh; không gọi lại công cụ tạo ảnh. ImageMagick chỉ nén lại PNG không mất dữ liệu. Có thể đổi thư mục bản xuất HTML bằng `ARTIFACT_DIR`.

Sau khi xuất xong, tạo ZIP với cấu trúc root gồm `assets/`, `docs/ideas/asset_preview/`, `docs/ideas/animation_pack.md`, và `preview_training_orc.html`. Chỉ cần đưa `assets/tiles/training/`, `assets/tiles/orc_shield/`, `assets/tiles/animation_pack.json`, `assets/fx/tile_reactions/` vào phần asset; bỏ `.godot/` và các file import được Godot sinh lại. Bản HTML độc lập có sẵn ảnh nên cũng có thể tải riêng.

Ảnh biểu cảm và FX được tạo bằng công cụ sinh ảnh, sau đó tách ô và chuẩn hóa kích thước; các nét mặt có thể có sai khác nhỏ giữa frame, đây chưa phải một rig nhân vật. Chuyển động được ghép từ nét mặt, biến đổi vị trí/tỉ lệ và FX vẽ sẵn. Bộ này không có giọng hét/cười thu âm hay nhạc. Cả bốn màu dùng da xanh; phân biệt bằng dáng đầu, tai, tóc/mũ, nét mặt và màu nền.
