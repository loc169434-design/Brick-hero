# Issue #41 — gạch Cóc, phương án A và B

Tiếp trên `art/campaign-100-g2` từ **`2f51e32`**, theo hai comment về khuôn gạch Goblin/Orc và phương án B. Chỉ sửa `assets/` và `docs/ideas/`; chưa merge, chưa thay code chọn theme.

Khi bắt đầu, G2 vẫn còn bản cóc trơn không khung. Đã hoàn thiện **A theo khuôn được yêu cầu** để làm mẫu so đúng; sau đó làm **B** bỏ huy hiệu và đổi bảng màu. Cả hai đều có đủ tài nguyên, không chỉ là mockup bốn ô đứng.

## Phương án đã duyệt

Ngày 2026-11-05, người dùng chọn **B đúng như ảnh bốn ô đã gửi**, tương ứng bộ tại commit `f22f711`: san hô đeo khăn, xanh ngọc đội lá sen, mật ong đội vương miện và chàm đội mũ phù thủy. Giữ nét cóc láu cá, da sần, khung và bóng khối hiện có. Bộ đầy đủ dùng family **`swamp_b`**, đường dẫn **`assets/tiles/swamp_b/`**. Các bản thử nét dễ thương chỉ là nghiên cứu; mẫu được duyệt là B hiện có.

Claude dùng family `swamp_b` khi nối bộ gạch đầm lầy vào game. A được giữ lại để đối chiếu. Lần chốt này chỉ cập nhật bàn giao vì tài nguyên B đã đúng ảnh người dùng chọn.

## Ảnh đối chiếu

**[So sánh ba hàng đầy đủ](swamp_variants_review/comparison_3_rows.jpg)**: Goblin/Orc hiện tại → A → B. Mỗi hàng có cả **128 px màu, 46 px màu, 128 px xám, 46 px xám**; các ô giữ đúng số pixel ghi trong ảnh.

- [Bản màu 46 px gọn](swamp_variants_review/comparison_46px.jpg) · [bản xám 46 px](swamp_variants_review/comparison_gray_46px.jpg).
- Bảng **7 cột × 8 hàng**, mỗi ô 128 px: [Goblin/Orc](swamp_variants_review/board_current_128px.jpg) · [A](swamp_variants_review/board_a_128px.jpg) · [B](swamp_variants_review/board_b_128px.jpg).
- [Ba bảng ở 46 px](swamp_variants_review/boards_46px.jpg) · [ba bảng xám ở 46 px](swamp_variants_review/boards_gray_46px.jpg).

Hàng hiện tại lấy `assets/tiles/orc_shield/`, đúng bộ chuẩn được dẫn trong comment. Ba bảng dùng **cùng một cách xếp ngẫu nhiên**, seed 4102, đủ **14 ô mỗi màu**; không đổi cách xếp để làm đẹp riêng một phương án. Mỗi JPG dưới **2 MB**; ảnh lớn nhất khoảng **719 KB**. [Mục lục](swamp_variants_review/index.md).

## A — `assets/tiles/swamp/`

Khung vuông bo góc, viền mực nâu đậm, vân khắc, viền nổi sáng trên trái và bóng dưới phải theo khuôn Orc. Mặt cóc giữ da xanh rêu/nâu đầm lầy, có nốt sần, lông mày và biểu cảm mạnh. Màu ô thể hiện ở khung và phụ kiện:

- `red`: khung/khăn buộc đầu đỏ, huy hiệu kiếm.
- `green`: khung xanh, mũ lá sen, huy hiệu lá.
- `yellow`: khung vàng, vương miện đồng nhỏ, huy hiệu đồng xu.
- `purple`: khung/mũ phù thủy tím, huy hiệu khiên.

Huy hiệu tròn kem ở góc dưới phải, vị trí/kích thước theo khuôn mẫu. Đã cập nhật GIF/lưới gạch trong gallery G2 để không tiếp tục hiển thị bản cóc trơn cũ.

## B — `assets/tiles/swamp_b/`

Giữ khuôn khung, viền, ánh sáng, bóng khối và tạo hình A. **Không có huy hiệu kiếm/lá/đồng xu/khiên**; vùng góc dưới phải là má cóc/khung, không còn vòng tròn kem. Mỗi nhóm vẫn có phụ kiện đầu riêng: khăn buộc, lá sen, vương miện, mũ nhọn.

Tên file tiếp tục dùng tên ô trong code, không dùng tên màu hiển thị:

| Tên trong code/file | Vai trò | Màu B | Màu nền đích |
|---|---|---|---|
| `red` / `tile_red.png` | Sát thương | Cam san hô | `#D95F4E` |
| `green` / `tile_green.png` | Hồi máu | Xanh ngọc sáng | `#71D6CB` |
| `yellow` / `tile_yellow.png` | Vàng | Mật ong/hổ phách sáng | `#FFE59A` |
| `purple` / `tile_purple.png` | Phá khiên | Xanh chàm tối | `#27305E` |

Các mã hex là hướng màu cho ảnh vẽ; ảnh có viền/bóng/highlight nên chứa nhiều sắc độ. Da cóc giữ màu tự nhiên, không tô toàn bộ con cóc theo màu vai trò.

### Phân biệt khi nhìn xám

Đo trên ảnh thật **sau khi thu xuống 46×46**, lấy độ xám trung bình phần hình alpha ≥224, bỏ phần ngoài trong suốt và fringe:

| Nhóm B | Độ xám trung bình, thang 0–255 |
|---|---:|
| Chàm (`purple`) | 62,3 |
| San hô (`red`) | 101,9 |
| Xanh ngọc (`green`) | 125,1 |
| Mật ong (`yellow`) | 145,9 |

Khoảng chênh gần nhất là **20,8/255**. Thứ tự tối → sáng: chàm → san hô → xanh ngọc → mật ong. Kiểm riêng vùng viền của cả chín biểu cảm vẫn giữ đúng thứ tự, chênh thấp nhất **32 mức**. Bốn hình dạng phụ kiện đầu cũng còn đọc được ở 46 px. [Số đo](swamp_variants_review/palette_metrics.json) · [kiểm đầy đủ](swamp_variants_review/validation.json). Đây là số đo của bản ảnh xuất, không chỉ lấy độ sáng từ bốn mã màu đề xuất.

## Cấu trúc và hoạt hình

Hai thư mục có cùng cấu trúc:

- Bốn `tile_<color>.png`, RGBA **128×128**.
- Bốn `expressions_<color>.png`, grid **3×3 ô 128**, cùng **36 PNG biểu cảm rời**: idle, blink, chuckle, laugh, fear, relief, scream, gloat, hurt.
- `animations/`: **48 atlas mỗi bộ**, 12 clip × bốn màu; khung **192×192**, **8 cột**, bốn cel có hình và bốn ô thừa trong suốt, cùng timing/fps/loop cũ.
- Bốn `sprite_frames_<color>.tres` mỗi bộ, đủ 12 clip; `swamp_manifest.json` ghi family/variant/palette/badge và việc dùng chung cel.

12 clip: idle, drop, land, combo, hurt, taunt, fear, near_miss, gloat, death, win, lose. Có 12 nhóm pose nguồn × bốn cel vẽ riêng mỗi màu. Giữ việc dùng chung cel đã có: taunt/lose dùng laugh; death/win dùng fear+scream rồi alpha 0; near_miss ghép fear→relief→laugh. Không tăng số khung bằng nội suy. Idle 0 khớp chính xác PNG đứng.

`assets/tiles/animation_pack.json` giữ nguyên mọi family cũ ngoài swamp, cập nhật A tại family `swamp` và thêm B tại `swamp_b`. Các tên màu/vai trò và timing A cũ giữ nguyên. Đã tải được cả hai trực tiếp qua `TileArt.new(family)`; Claude nối **B (`swamp_b`) đã được người dùng duyệt** vào `TileArt.THEMES` và logic chọn theme.

## Kiểm tra và tái xuất

- [Kiểm A/B](swamp_variants_review/validation.json): **1.330 điều kiện đạt**; đủ **184 PNG**, **96 atlas**, tám SpriteFrames; kích thước, alpha, ô thừa, tệp biểu cảm, badge B, timing, độ sáng ở 46 px, thứ tự sáng viền của chín biểu cảm, bảng 7×8, ảnh xám thật và preview dưới 2 MB.
- [Godot 4.7.2 smoke](swamp_variants_review/resource_smoke.log): **96 atlas, tám SpriteFrames, 96 animation qua TileArt, tám tile đứng**, **0 failures**. Có kiểm đường dẫn family để không vô tình dùng tile fallback.
- [Suite hiện có](swamp_variants_review/godot_tests.log): **93 passed, 0 failed**. Godot import không lỗi.
- Kiểm G2 vẫn đạt **1.163 điều kiện**; luật liên thông nhân vật vẫn quét đủ 340 ô, bắt đủ 18 ô Cá Sấu lỗi ở commit cũ. PNG nhân vật, truyện, nền, vật cản và bộ Orc/huấn luyện giữ nguyên từng byte.

**18 nguồn vẽ lớn nằm ngoài repo**, đường dẫn/SHA-256/hộp cắt ở `swamp_variants_sources.json`. Nguồn có khe trong được cắt theo khe đo được. Một số sheet B có các khung vuông chạm cạnh, đã đối chiếu trực quan lưới **4×6**, từng ô **256×256** trên canvas **1024×1536**, rồi ghi hộp cắt rõ ràng; không áp lưới đều cho các sprite cơ thể có hàng cách không đều như lỗi Cá Sấu. Công cụ chỉ cắt/co nguyên ô, đóng atlas và ghép ảnh; đổi màu/bỏ huy hiệu đều thực hiện bằng công cụ ảnh. Chuyển ảnh xám chỉ dùng cho bản so sánh được yêu cầu.

```sh
python docs/ideas/pack_swamp_variants.py
python docs/ideas/check_swamp_variants.py
python docs/ideas/check_campaign_g2.py
godot --headless --editor --path . --import --quit
godot --headless --path . -s res://docs/ideas/swamp_variants_resource_smoke.gd
godot --headless --path . -s res://tests/run_tests.gd
```

Python cần Pillow, NumPy, SciPy; Godot dùng 4.7.2 và thư mục XDG writable như onboarding. Xuất lại nhóm tiles bằng packer G2 sẽ gọi lớp A/B ở cuối, tránh ghi đè về bản cóc trơn cũ. Nguồn ngoài repo cần còn khi tái xuất; PNG/atlas production độc lập khi chơi. [Danh sách file](swamp_variants_files.json).
