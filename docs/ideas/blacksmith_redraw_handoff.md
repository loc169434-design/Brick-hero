# Thợ rèn vẽ lại — `art/blacksmith`

Từ `main` tại `b34f151`, theo [yêu cầu vẽ lại](blacksmith_art_request.md).
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
(746,881,25). Claude có thể dùng anchor này để căn vị trí lúc đánh.
Không có đe, phòng hay bóng sàn vẽ trong các cel.

## Claude cần chỉnh thời gian phát trước khi ghép

Ở `scripts/campaign/forge_view.gd`, `_strike()` hiện gọi
`_smith.react(clip, 0.32)`, nhưng khung chạm mới ở 0,375 s và 0,500 s.
`CharacterRig.react()` trả mood về idle khi timer hết, nên cú đập bị cắt
trước khi chạm. `_finish_forging()` còn gọi cheer sau 0,2 s, sớm hơn nhát cuối.

Giữ hammer ít nhất 16/24 = 0,667 s và hammer_final ít nhất 20/24 = 0,833 s;
chờ nhát cuối kết thúc rồi mới bắt đầu cheer và chuỗi món đồ bay.
Tiếp tục dùng `impact_seconds(clip)` cho tiếng đe/tia lửa.
`cheer` dài 1,333 s, `grin` dài 1,167 s; hai timer 1,4 s hiện tại đủ dài.
Code đang tự tắt tia lóe khi có clip grin. Không sửa code trong nhánh này.

## Kiểm tra

- Godot thường 4.7.2 import thành công; sáu sheet có `compress/mode=2`.
- Bộ test hiện tại: **89 passed, 0 failed**, không `SCRIPT ERROR`.
- Smoke qua `CharacterRig` thật: tải đủ sáu clip, phát sự kiện chạm đúng
  0,375/0,500 s, clip một lần giữ khung cuối. Đã tái hiện timer 0,32 s
  cắt mood của code hiện tại; do đó chưa coi gameplay ghép xong.
- Kiểm tra ảnh: số ô/FPS/impact/alpha/ô trống/khung cuối/GIF đạt;
  xem [validation.json](blacksmith_review/validation.json).
- Tất cả GIF và ảnh review dưới 2 MB; GIF lớn nhất dưới 700 KB.
- Chưa kiểm tra trên điện thoại.

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
`project.godot`, code và test giữ nguyên.
