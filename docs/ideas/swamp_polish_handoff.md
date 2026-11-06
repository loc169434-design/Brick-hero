# Issue #48 — nền đầm lầy/trại Goblin và gạch Cóc B

Nhánh `art/swamp-polish`, bắt đầu từ main mới nhất lúc nhận việc: **`bc328c63fdff3b3e6df4a4e8db6d8a735c42f2af`**. Chỉ thay `assets/` và `docs/ideas/`.

Tại thời điểm bắt đầu, PR #47 vẫn chưa nhập vào main; main chưa có ảnh G2. Đã lấy đúng ba thư mục cần sửa (`assets/bg/swamp/`, `assets/bg/goblin_camp/`, `assets/tiles/swamp_b/`) từ bản B đã duyệt **`2687106`** làm bản gốc, rồi cập nhật. Không mang code, scene, dữ liệu màn chơi hoặc ảnh G2 khác sang nhánh này. Ảnh ghép Goblin lấy `fresh_idle` từ đầu PR #47 `8a05011e` chỉ để xem thử.

## Nền

Hai nền có màu vàng nâu ấm, xanh rêu đậm, tâm sáng hơn mép. Dải đất liên tục bắt đầu ở **y=380** có đường viền trên đậm; nền kín dưới cả chân `(270,405)` và `(810,405)`. Cây/chòi gần được dồn vào **x≤110** và **x≥970**; khoảng sau lưng hai nhân vật thông thoáng.

Mỗi bộ vẫn có bốn lớp **1080×660**, thứ tự `sky → far → mid → ground`. `sky` kín alpha; `mid` chỉ có cảnh ở mép, trống toàn bộ x=120–959 và bên dưới y=380; `ground` hoàn toàn trong suốt ở y<380. Giữ nguyên `layers.json` cho cấu hình parallax/hiệu ứng, bổ sung tọa độ sàn và vùng trống. Cả sáu atlas **đom đóm, bong bóng, lá sen** và thông số phát được giữ nguyên byte so với bản G2.

PR #47 vẽ nền ở `(0,-80)` trong vùng chiến đấu cao 500 px, nên chân màn hình y=405 tương ứng y=485 trên ảnh nền. Dải đất mới hỗ trợ **cả y=405 lẫn y=485**. Có hai bản ghép `fresh_idle`, scale **0,7**, đặt cạnh trại Orc để đối chiếu:

- [Bố cục trong game](swamp_polish_review/backgrounds_game_layout.jpg).
- [Canvas gốc theo tọa độ trong issue](swamp_polish_review/backgrounds_native_feet.jpg).

## Cóc B

Giữ bốn màu và phụ kiện đã duyệt: san hô/khăn đỏ, xanh ngọc/lá sen, mật ong/vương miện, chàm/mũ phù thủy; không huy hiệu. PNG đứng và **36 ảnh biểu cảm cá nhân cũ** giữ nguyên byte. Vẽ riêng **98 khung mỗi màu, 392 khung tổng**, không dùng chung cel giữa các clip, không nội suy hay nhân bản một pose để đủ khung.

| Clip | Khung | FPS | Lặp |
|---|---:|---:|---|
| idle | 12 | 10 | Có |
| taunt | 10 | 12 | Không |
| hurt | 8 | 14 | Không |
| fear | 8 | 12 | Có |
| combo | 8 | 16 | Không |
| drop, land | 6 mỗi clip | 16 | Không |
| gloat, near_miss, win, lose, death | 8 mỗi clip | 12 | Không |

Idle có túi họng phồng/xẹp, liếc hai hướng, miệng ộp; taunt có lưỡi quất vòng; hurt bẹp mặt/mắt xoáy rồi bật lại; combo nhảy khỏi khung và tan thành bọt. Các trạng thái kết thúc được vẽ riêng.

Đã cập nhật **48 atlas**, bốn `sprite_frames_<color>.tres`, `swamp_manifest.json` và các entry family **`swamp_b`** trong `assets/tiles/animation_pack.json`. Các family khác trên main giữ nguyên. Mọi entry có số khung/fps/seconds/loop mới.

Atlas tám cột: **192 px/cel** cho các clip thường, **320 px/cel riêng combo** để chứa trọn đầu cóc khi nhảy. Mặt khung gạch vẫn **128×128 ở tâm cel**, nên `AnimatedSprite2D` có tâm mặc định và scale theo 128 tiếp tục dùng được. Đọc `cell` và `columns` trong từng entry, không cắt combo theo 192 cố định. `TileArt.ensure_clip` hiện tại đã hỗ trợ kích thước này và đã được chạy smoke.

Thêm **12 PNG 128×128**: `assets/tiles/swamp_b/expressions/<color>_croak.png`, `<color>_look_left.png`, `<color>_look_right.png`. Có thể gọi `TileArt.expression(color, "croak")`, `"look_left"`, `"look_right"`. Bảng `expressions_<color>.png` mở rộng thành **3×4 ô**, giữ nguyên chín biểu cảm cũ ở ba hàng đầu, ba biểu cảm mới ở hàng cuối. Manifest ghi rõ bố cục mới. Việc thêm ba tên biểu cảm vào bộ lựa chọn ngẫu nhiên thuộc code của Claude.

**[GIF bảng 7×8, idle lệch nhịp, ô 46 px](swamp_polish_review/board_7x8_idle_offset.gif)** (~1,27 MB). Bảng có 14 ô mỗi màu, seed 48, pha từng ô lưu trong JSON. [Mục lục toàn bộ ảnh/GIF](swamp_polish_review/index.md).

## Kiểm tra và tái xuất

Đã kiểm tra 392 cel: **mỗi ô phần hình liền một khối**, không có thành phần alpha rời >200 pixel (8 hướng, alpha>32), không chạm mép cel. Hai mask lỗi thật từ lần cắt cũ được giữ dưới dạng fixture JSON; luật phải từ chối cả hai. Cắt theo bounding rectangle thực tế của cả hình liền khối và khoảng trống giữa các hàng, không chia đều ảnh nguồn khi khoảng cách hàng lệch. Hai sheet combo đỏ/xanh được vẽ riêng lại vì nguồn đầu có hình chạm hàng bên cạnh.

Nguồn: 25 ảnh gốc nằm ngoài repo, đường dẫn/SHA-256/ô cắt và đăng ký khung trong `swamp_polish_sources.json`. Chỉ cắt hình vẽ trọn, chuẩn hóa kích thước khung và ghép atlas/layer; không tô lại bằng mã. Nguyên bản sinh ảnh được giữ ở `/workspace/generated_images/`.

```bash
python docs/ideas/pack_swamp_polish.py
python docs/ideas/check_swamp_polish.py --source-audit
godot --headless --path . --editor --import
godot --headless --path . --script res://docs/ideas/swamp_polish_resource_smoke.gd
godot --headless --path . --script res://tests/run_tests.gd
```

Dùng Godot **4.7.2**. Tái xuất ảnh cần nguồn ngoài repo và bản gốc G2; ảnh ghép Goblin cần ref PR #47 hoặc file `fresh_idle` đã được nhập vào main. Kiểm tra ảnh có thể chạy trên clone không có ảnh nguồn; thêm `--source-audit` để yêu cầu đủ bản gốc và đối chiếu hash.

Godot import không báo lỗi; smoke tải **48 clip qua TileArt, bốn SpriteFrames, 12 biểu cảm mới và tám lớp nền: 0 failures**. Suite main: **110 passed, 0 failed**. [Kết quả ảnh](swamp_polish_review/validation.json) · [smoke](swamp_polish_review/resource_smoke.log) · [suite](swamp_polish_review/godot_tests.log).

Khi ghép sau PR #47, giữ thêm các family G2 của PR đó trong manifest toàn cục, đồng thời dùng entry `swamp_b` mới của nhánh này. Nhánh ảnh không tự đổi code chọn theme hay bộ biểu cảm ngẫu nhiên.
