# Issue #5 — nhân vật, nền và FX trận đánh

Nguồn yêu cầu: [issue #5](https://github.com/loc169434-design/Brick-hero/issues/5). Nhánh `art/characters` được tạo từ `main` tại `0d24119f2dbd84ed024c46fd460f728549a68599`. Chỉ thêm ảnh/tài liệu trong `assets/` và `docs/ideas/`; không thay code, scene, tests hoặc `project.godot`. Không cập nhật `gh-pages`.

## Chuẩn hình ảnh đã sửa theo phản hồi người dùng

**Ảnh anh hùng gốc người dùng gửi là chuẩn trực tiếp**: người lớn, hàm rộng/dài, nụ cười lộ răng, tóc nâu, áo vải xanh xám, khăn đỏ, quai da đeo chéo, cổ tay da, ủng gập. Giữ nét viền nâu và mảng đổ khối góc cạnh của ảnh đó. Các bản thử chibi đã bị loại, không nằm trong bộ bàn giao hay danh sách nguồn xuất.

Hiệp sĩ dùng kiếm gỗ thay lưỡi thép theo quy cách tân thủ; khiên vẫn là nắp thùng gỗ tròn. Orc và bù nhìn dùng cùng họ nét/đổ bóng, hài hước, không kinh dị. Không vẽ sẵn mồ hôi bay ở dáng `scared`, sao choáng hay tia lóe răng; code đang thêm chúng từ ảnh FX riêng.

## Đủ file theo hợp đồng

| Nhóm | Số PNG | Đường dẫn |
|---|---:|---|
| Hiệp sĩ | 17 | `assets/characters/hero_rookie/` |
| Thân Orc, không khiên cầm | 17 | `assets/characters/orc_shield/` |
| Khiên riêng | 4 | `assets/characters/orc_shield/shield_3.png` … `shield_0.png` |
| Bù nhìn | 7 | `assets/characters/scarecrow/` |
| Nền | 2 | `assets/bg/training_field.png`, `assets/bg/orc_camp.png` |
| FX | 5 | `assets/fx/battle/` |

Tổng **52 PNG và 3 `rig.json`**. File `.import` nếu có do Godot sinh ra để nhập tài nguyên; không phải dáng bổ sung.

Hiệp sĩ và Orc: `fresh`, `bruised`, `battered` × `idle`, `attack`, `hurt`, `scared`, `cheer`, cộng `victory.png`, `defeat.png`. Bù nhìn: ba mức × `idle`, `hurt`, cộng `defeat.png`; không thêm dáng tấn công.

## Canvas và đăng ký vị trí

- Tất cả dáng nhân vật và khiên: **512×512 PNG RGBA** với nền ngoài trong suốt.
- Điểm chân trong cả ba rig là **(256,500)**. Ảnh được căn cùng đường chân, không căn giữa bbox vì kiếm/khăn/khiên có thể làm bbox lệch tâm.
- Dáng đứng hiệp sĩ/Orc khoảng 400 px; một số dáng cúi/ra đòn thấp hơn tự nhiên, dáng giơ kiếm có vũ khí cao hơn đầu. Bù nhìn khoảng 440 px. Dáng ngồi/quỵ/sụp thấp hơn, giữ cỡ đầu thay vì phóng to để bằng dáng đứng.
- Hiệp sĩ quay phải; Orc/bù nhìn quay trái. Hai dáng kết trận có thể quay ra phía người xem. Không cắt tóc, vũ khí, tai hay ủng ở biên canvas.
- Mỗi `rig.json` có đúng một mục `anchors` cho mỗi file dáng, tên không có `.png`, gồm `head` và `mouth`; không thêm mục cho ảnh khiên.
- Orc có `shield: [95,319]`, là tâm lớp khiên theo vị trí bàn tay thực tế trong bộ này. Đây là tọa độ đo theo ảnh, không bắt buộc trùng ví dụ minh họa `[150,330]` trong issue. Cả bốn lớp khiên dùng chung canvas/vị trí đó; hình khiên khoảng 154×196 px.
- `shield_0.png` hoàn toàn trong suốt, đúng lựa chọn được issue cho phép. Dáng Orc `defeat` không cầm khiên, có các mảnh gỗ nằm dưới đất; code hiện không chồng lớp khiên khi ở dáng này.

`CharacterRig` trên main đã đọc trực tiếp `feet`, `anchors`, `shield`, vẽ toàn bộ canvas 512 thành 360 px và đặt gốc ở chân; không cần lật ngang hay thêm offset mặc định khác khi dùng bộ này.

## Dấu hiệu ba mức tơi tả

| Nhân vật | Fresh | Bruised | Battered |
|---|---|---|---|
| Hiệp sĩ | Áo sạch, kiếm gỗ nguyên | Băng trán, băng má, vết nứt đậm trên kiếm nguyên chiều dài | Mắt bầm, áo rách, nửa lưỡi kiếm gãy nham nhở, khiên mẻ |
| Orc | Mũ da vá, da xanh, trang phục nguyên | Băng đầu/má, bầm nhẹ, răng mẻ dần | Băng dày, mắt bầm, răng mẻ rõ, áo rách; giọt mồ hôi nhỏ bám trên mặt |
| Bù nhìn | Áo/rơm nguyên, nón ngay | Áo thủng, rơm lòi, nón lệch | Mất một tay, mặt bao rách, nhiều rơm lộ ra |

`victory` hiệp sĩ có nụ cười lộ răng trắng và kiếm gỗ giơ cao; `defeat` ngồi bệt, cầm nửa kiếm gãy, mắt xoáy. Orc thắng cười hô hố/ưỡn ngực, thua quỵ gối mếu máo. Bù nhìn thua sụp thành đống rơm, đầu rơi cạnh thân. Bù nhìn không có đối đòn.

## Nền và FX

Hai nền PNG opaque **1080×660**. Vùng sàn trước được đăng ký từ **y=470**, phần dưới cùng 90 px ít tương phản và không có vật thể quan trọng để thanh máu che được. Thao trường có hàng rào/rơm/cọc và lâu đài xa; trại Orc có lều da/cọc gỗ trên đường rừng. Không vẽ nhân vật cố định trong nền.

| FX | Canvas | Nội dung |
|---|---|---|
| `sweat.png` | 128×128 | 3 giọt xanh nhạt |
| `stars.png` | 192×96 | Vòng sao choáng |
| `sparkle.png` | 128×128 | Tia trắng-vàng bốn cánh |
| `splinters.png` | 256×256 | Mảnh gỗ gãy văng |
| `straw.png` | 256×256 | Cọng rơm bay |

FX là ảnh tĩnh nền trong suốt; bay/xoay/fade, mồ hôi khi sợ và lóe răng do code hiện có thực hiện. Không cộng thêm một bộ FX tĩnh lên mặt hiệp sĩ trong các pose PNG.

## Xem thử và tự kiểm tra

- [Trang xem chọn từng dáng, chồng khiên và hiện điểm neo](issue5_review.html) chạy từ file hoặc máy chủ tĩnh; không phải bản web mới trên `gh-pages`.
- [17 dáng hiệp sĩ ở 360 px](issue5_review/hero_rookie_360.png).
- [17 dáng Orc ở 360 px](issue5_review/orc_shield_360.png).
- [7 dáng bù nhìn ở 360 px](issue5_review/scarecrow_360.png).
- [4 lớp khiên chồng lên Orc fresh_idle](issue5_review/orc_shield_layers_360.png).
- [So sánh ba mức](issue5_review/wear_360.png).
- [Cảnh thao trường](issue5_review/battle_training.png) · [cảnh Orc](issue5_review/battle_orc.png).
- [Kích thước, alpha, đường chân và số lượng](issue5_review/metrics.json).

Lưới giữ canvas mỗi ảnh đúng **360 px**; đường đỏ mảnh là y=500 của PNG sau thu nhỏ. Mở PNG gốc để xem cỡ thật nếu trang GitHub thu nhỏ ảnh. Chân cùng hàng, các mức vẫn nhận ra khi nhìn thoáng; khiên thay lớp giữ đúng tay. Nền và nhân vật trong hai cảnh xem thử được ghép theo `BattleView.HERO_FEET = (270,470)`, `MONSTER_FEET = (810,470)` và `DISPLAY_SIZE = 360` hiện có.

Kiểm tra có thể chạy lại:

```sh
node docs/ideas/issue5_verify.mjs
```

Lệnh cần Node.js, Playwright, Chromium và ImageMagick; chỉ đọc asset và ghi ảnh bằng chứng trong `docs/ideas/issue5_review/`. Không sửa hoặc thay thế tests gameplay.

`issue5_pack.mjs` là bộ tách/đăng ký raster từ các ảnh nguồn sinh bằng công cụ vẽ, không tự vẽ lại nhân vật. Có thể dùng `IMAGE_SOURCE_DIR` trỏ đến bản gốc được ghi trong `issue5_sources.json` nếu còn giữ. Bản gốc nằm ngoài checkout để tránh commit cả sheet lớn; game chỉ cần 52 PNG cuối và ba rig, không cần các bản thử hoặc công cụ sinh ảnh. PNG cuối nén không mất dữ liệu, bỏ metadata ngày giờ; chỉ commit bộ cuối.

Claude có thể merge `art/characters` từ base main tương ứng; code nạp theo tên đã có sẵn. Cần tự kiểm tra lại diễn tiến trận thật và hai kết quả thắng/thua sau merge; ảnh xem thử không thay cho xác minh logic trận đấu.

## Kết quả đã chạy

- **454 kiểm tra ảnh PASS**: số lượng/tên file, kích thước, alpha, đường chân y=500, đủ 41 mục anchors, bốn khiên, hai nền và năm FX; đã xem trực tiếp lưới 360 px, ba mức tơi tả và ảnh chồng khiên.
- **Godot 4.7.2 PASS**: `CharacterRig` hiện tại lấy đúng cả 41 đường dẫn pose mới (không rơi về placeholder), đọc được ba rig, bốn khiên, hai nền, năm FX. Import không báo lỗi/cảnh báo.
- Không sửa code/scene/tests/project, không merge main và không push `gh-pages`.
