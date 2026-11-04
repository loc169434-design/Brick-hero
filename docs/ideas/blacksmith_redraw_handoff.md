# Thợ rèn vẽ lại — `art/blacksmith`

Từ `main` tại `b34f151`, theo [yêu cầu vẽ lại](blacksmith_art_request.md).
Đã ráp trực tiếp vào `ForgeView`: ba nhát búa, lau trán, món đồ bay vào bảng
và cười lóe răng. Nhánh gồm ảnh, code tích hợp và kiểm tra hồi quy.
Sáu clip, 86 ô hoạt hình, chỉ mức `fresh`. Toàn bộ nhân vật được vẽ lại
bằng công cụ tạo ảnh theo từng tư thế hoàn chỉnh. Không dựng khớp, xoay tay/chân,
ghép mặt hoặc kéo các mảnh từ ảnh đứng. Python/Pillow chỉ đọc, đăng ký điểm chân,
co đồng đều cả hình, đóng atlas, ghép ảnh kiểm tra và xuất GIF.

| Clip | Khung | FPS | Lặp | Chạm (đếm từ 0) | Xem thử | Lưới đánh số |
|---|---:|---:|---|---|---|---|
| idle | 12 | 12 | Có | — | [GIF](blacksmith_review/idle.gif) | [PNG](blacksmith_review/idle_numbered.png) |
| talk | 8 | 12 | Có | — | [GIF](blacksmith_review/talk.gif) | [PNG](blacksmith_review/talk_numbered.png) |
| hammer | 16 | 24 | Không | 9 = 0,375 s | [GIF](blacksmith_review/hammer.gif) | [PNG](blacksmith_review/hammer_numbered.png) |
| hammer_final | 20 | 24 | Không | 12 = 0,500 s | [GIF](blacksmith_review/hammer_final.gif) | [PNG](blacksmith_review/hammer_final_numbered.png) |
| cheer | 16 | 12 | Không | — | [GIF](blacksmith_review/cheer.gif) | [PNG](blacksmith_review/cheer_numbered.png) |
| grin | 14 | 12 | Không | — | [GIF](blacksmith_review/grin.gif) | [PNG](blacksmith_review/grin_numbered.png) |

Idle chớp mắt, thở và lau trán; talk có diễn miệng và tay. Hai clip búa lấy đà
qua vai bằng hai tay, có vệt vung và mồ hôi. Nhát cuối thêm tư thế nhón chân,
hét và giọt mồ hôi lớn. Cheer hạ búa, lau trán, thở phào và cười; grin chống
tay hông và có tia trắng-vàng trên răng quanh khung 5–9.

Mỗi khung 512×512 RGBA, atlas 4 cột, ô thừa trong suốt. Mọi clip dùng chung
idle 0 ở đầu/cuối; khung cuối trùng từng pixel với idle 0. Những ô giữ chung
dáng đứng là hold cel, không phải tư thế được dựng lại bằng script.
Chân khai báo (256,500); sai lệch mép giày đo sau raster hóa tối đa 4,5 px.
Các nguồn vẽ và SHA-256 được ghi trong
[drawing_provenance.json](blacksmith_review/drawing_provenance.json).

## Cân với phòng rèn

[Idle 0](blacksmith_review/forge_idle.png) và
[hammer 9](blacksmith_review/forge_hammer.png) dùng nguyên nền 1080×1920,
co cả ô còn 384×384 (người khoảng 300 px), chân đúng (790,880).
Đây là ảnh ghép kiểm tra bố cục, không phải ảnh chụp gameplay.

`rig.json` có `head`/`mouth` cho cả sáu clip, `grin.tooth = (233,193)`
theo khung 7; tâm đầu sắt tại khung chạm của cả hai clip búa là
`anchors.<clip>.hammer = (128,305)`.
Trong ảnh kiểm tra cố định chân, tâm đầu búa chiếu ra (694,733,75).
Để tâm đầu búa trùng điểm đe (650,735) ở tỷ lệ 0,75, điểm chân sẽ là
(746,881,25). Trong game, `SMITH_SCALE=1.05` nhân với tỷ lệ cơ sở
360/512 cho tỷ lệ thực 0,73828125: chân lúc đánh ở (744,5;878,96484375).
Code căn điểm búa vào (650,735) và cho ông bước về vị trí đứng sau khi rèn.
Không có đe, phòng hay bóng sàn vẽ trong các cel.

## Tích hợp vào game

`ForgeView` phát trọn `hammer` (0,667 s) và `hammer_final` (0,833 s),
khóa bấm/đếm nhát tiếp theo đến hết hồi đòn. Tiếng đe, tia lửa và giọt mồ hôi
được phát một lần từ `CharacterRig.clip_impact`, đúng khung 9/12.
Sau khi nhát cuối kết thúc mới chạy cheer, món đồ bay vào ô trang bị và grin.
Nếu thiếu clip cuối, dùng trọn hammer thường; nếu chỉ có ảnh đứng, vẫn có
nhịp chạm/hồi đòn và tự đánh sau thời gian chờ.

`CharacterRig.clip_seconds()` đọc thời lượng từ metadata, `react()` bắt đầu
clip ngay để đồng bộ đồng hồ, `point(key, pose)` cho phép căn búa trước khi
phát đòn. Riêng thợ rèn tắt thở co giãn và nhảy ăn mừng bằng code để giữ
nguyên diễn xuất trong hình vẽ; các nhân vật khác giữ hành vi mặc định.
Tia răng dùng hình vẽ sẵn, không vẽ thêm tia bằng code.

## Ảnh chụp game chạy thật

[Xem trọn chuỗi rèn — GIF](blacksmith_review/forge_gameplay.gif) (1,42 MB).
Ảnh chụp từ `Game.open_forge()` thật, bản lưu xem thử riêng trong `/tmp`,
không ghi đè tiến trình người chơi:

- [Đầu game](blacksmith_review/game_early.png), [sau khi qua Orc](blacksmith_review/game_mid.png).
- [Chạm nhát 1](blacksmith_review/game_impact_1_hammer.png), [nhát 2](blacksmith_review/game_impact_2_hammer.png), [nhát cuối](blacksmith_review/game_impact_3_hammer_final.png).
- [Món đồ đang bay](blacksmith_review/game_item_flying.png), [cười lóe răng](blacksmith_review/game_grin.png), [trang bị đã nhận](blacksmith_review/game_equipped.png).

## Kiểm tra

- Godot thường 4.7.2 import thành công; sáu sheet có `compress/mode=2`.
- Bộ test hiện tại: **93 passed, 0 failed**, không `SCRIPT ERROR`.
- `tests/forge_flow_smoke.gd`: **PASS, 0 failures**. Chạy một lần mua thật,
  đủ ba nhát theo thứ tự, bấm dồn không cắt đòn, chạm đúng khung, đe khớp
  anchor, cheer sau nhát cuối, món đồ vào bảng, grin rồi idle. Có kiểm tra
  thiếu clip cuối, thiếu clip búa và tự đánh sau thời gian chờ.
- Đã chạy và chụp bằng OpenGL Compatibility/llvmpipe trên màn hình X11 ảo.
  Thử renderer Mobile/Vulkan trong môi trường này thiếu `VK_KHR_surface`,
  Godot tự chuyển OpenGL. Chưa xác nhận Vulkan trên thiết bị thật.
- Kiểm tra ảnh: số ô/FPS/impact/alpha/ô trống/khung cuối/GIF đạt;
  xem [validation.json](blacksmith_review/validation.json).
- Tất cả GIF và ảnh review dưới 2 MB; GIF từng clip dưới 700 KB, GIF gameplay 1,42 MB.
- Chưa kiểm tra trên điện thoại.

Chạy kiểm tra Godot (bản thường 4.7.2):

```sh
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/forge_flow_smoke.gd
```

Chạy lại kiểm tra ảnh:

```sh
python docs/ideas/check_blacksmith_redraw.py
```

Đóng lại atlas từ ảnh vẽ nguồn đầy đủ (manifest ngoài repo ánh xạ các tên
clip và `swing_pair`/`impact_pair` sang đường dẫn ảnh):

```sh
python docs/ideas/pack_blacksmith_redraw.py /path/to/source_manifest.json
```

Thư mục review có `.gdignore`, không đưa GIF/ảnh kiểm tra vào tài nguyên game.
`project.godot` giữ nguyên; không thêm phần `[dotnet]`.

## Trạng thái bàn giao GitHub

Nhánh `art/blacksmith` có cả ảnh (commit ảnh `e9d00a8`) và code tích hợp.
Tạo PR, tạo issue vẽ lại và
comment vào issue #30 đều bị GitHub API trả `Forbidden` trong môi trường này,
nên chưa có PR/issue/comment mới. Có thể mở PR từ nhánh đã push tại
[đường dẫn so sánh](https://github.com/loc169434-design/Brick-hero/compare/main...art/blacksmith?expand=1).
Nội dung và GIF cần bàn giao nằm đầy đủ ở tài liệu này.
