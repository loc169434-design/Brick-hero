# Issue #49 — world life

Nhánh `art/world-life` từ main **`cb34881`**, đã có nền và Cóc B của `05ad58a`. Phần Nhấc Gạch/Orc nổi điên #48 đã push riêng ở `2e7834c` trước khi bắt đầu #49. Chỉ sửa `assets/` và `docs/ideas/`, giữ nhân vật và nét game.

## 1. Bảng Lượt

`assets/ui/hud/turn_plaque.png`: **360×116**, gỗ óc chó tối, viền vàng, tâm trống. Vùng đặt chữ gợi ý `[22,18,316,80]` (x,y,w,h); không có chữ vẽ sẵn. `sword_left.png` và `sword_right.png`: **160×160**, một kiếm mỗi PNG, chuôi/cản vàng, mũi lên và nghiêng nhẹ sang hai phía. Code chồng/xoay để tạo từng cặp kiếm. `clash_spark.png`: **6 cel 160×160**, ba cột, **24 fps**, không lặp; khai báo trong `anim.json`. `hud_manifest.json` ghi kích thước/mốc tâm.

[GIF bảng + hai cặp kiếm chạm mỗi 2 giây](world_life_review/hud/turn_plaque_clash.gif) · [ảnh tĩnh](world_life_review/hud/turn_plaque_preview.jpg) · [tia lửa](world_life_review/hud/clash_spark.gif).

Chữ “Lượt 12”, động tác xoay và ghép tia lửa chỉ dùng trong ảnh xem thử. Claude nối PNG vào HUD, giữ phần đếm lượt trong code. Tất cả preview dưới 2 MB.

## 2. Cóc bị nhấc: cười gian và chóng mặt

Thêm tám PNG **128×128**: `assets/tiles/swamp_b/expressions/<color>_sly.png` và `<color>_dizzy.png`, với `color=red/green/yellow/purple`. Giữ nguyên bộ B đã duyệt, màu và phụ kiện. `sly`: cười lệch và liếc rõ sang trái phía hiệp sĩ; `dizzy`: mắt xoáy, lưỡi thè, mặt méo.

[GIF đổi hai nét của cả bốn màu](world_life_review/faces/sly_dizzy_four_colors.gif) · [so ở 128 và46px](world_life_review/faces/sly_dizzy_128_46.jpg).

Giữ nguyên byte 48 PNG biểu cảm cá nhân cũ (12 mỗi màu) và các atlas animation. Bảng tổng biểu cảm mở rộng từ **3×4 lên3×5**, 14 ô có hình, ô cuối trong suốt; thứ tự cũ giữ nguyên, thêm `sly`, `dizzy` ở cuối. Cập nhật danh sách/bố cục trong `swamp_manifest.json` và danh sách biểu cảm của riêng family B trong `animation_pack.json`. Claude gọi `TileArt.expression(color,"sly")` khi nhấc và `"dizzy"` sau khi xoay.

## 3. Trời bốn giờ, mắt đỏ và thời tiết

Cả `training_field`, `orc_camp`, `swamp`, `goblin_camp` có **`sky_morning.png`, `sky_noon.png`, `sky_dusk.png`, `sky_night.png`**, mỗi ảnh **1080×660**, opaque. Giữ bố cục mây qua bốn giờ, bản đêm có trăng/sao. Các PNG `sky.png`, `far.png`, `mid.png`, `ground.png` hiện có và nhân vật giữ nguyên byte. Sàn đầm lầy/trại Goblin đã sửa ở #48 tiếp tục được dùng.

Mỗi `layers.json` thêm **ba vị trí `eyes`** trong vùng rìa tối và ngoài làn đứng của nhân vật, `sky_times` chỉ tới bốn PNG, `time_lighting` là màu điều chỉnh runtime gợi ý cho far/mid/ground và nhân vật. Lớp trời đã được vẽ theo giờ nên giữ màu nguyên bản; mắt đỏ vẽ sau bước điều chỉnh ánh sáng. Không tạo ảnh nhân vật bị tô lại. Thiết lập parallax, hiệu ứng, mặt đất cũ giữ nguyên.

Ảnh so sánh bốn giờ, hai nhân vật `fresh_idle` đúng chân `(270,405)/(810,405)`, scale0,7, nền dịch `(0,-80)` như game, **dựng thật bằng Godot 4.7.2** với chính các texture này:

- Bãi tập: [bốn giờ](world_life_review/weather/training_field_four_hours.jpg) · [GIF](world_life_review/weather/training_field_day_cycle.gif).
- Trại Orc: [bốn giờ](world_life_review/weather/orc_camp_four_hours.jpg) · [GIF](world_life_review/weather/orc_camp_day_cycle.gif).
- Đầm lầy: [bốn giờ](world_life_review/weather/swamp_four_hours.jpg) · [GIF](world_life_review/weather/swamp_day_cycle.gif).
- Trại Goblin: [bốn giờ](world_life_review/weather/goblin_camp_four_hours.jpg) · [GIF](world_life_review/weather/goblin_camp_day_cycle.gif).

Đây là cảnh tham chiếu để Claude nối vào code giờ/thời tiết; script render nằm trong `docs/ideas/`, không sửa game code.

`assets/fx/weather/anim.json` ghi đầy đủ cel, cột, fps, loop:

| File | Cel | Số khung / fps | Lặp |
|---|---|---|---|
| rain.png |1080×660|4 /12|Có; mép x/y trong suốt khớp nhau|
| rain_splash.png |512×512|6 /16|Không; gốc va chạm `(256,420)`|
| lightning_bolt.png |512×1024|6 /18|Không|
| fog.png |1080×660|4 /8|Có; mép x trong suốt khớp nhau|
| red_eyes.png |256×128|6 /8|Không; khung0và5 trống hoàn toàn|

Rain/fog atlas hai cột; ba FX còn lại ba cột. Năm atlas đã bật **nén VRAM**. Mắt đỏ được kích ngẫu nhiên ở các điểm khai báo; chu kỳ tự kết thúc ở trạng thái tắt. Sương có thể cuộn ngang cả texture theo thời gian. Mưa rõ trên cả nền sáng và tối; code có thể hạ opacity khi mưa nhẹ.

Bảy biểu tượng **128×128** cùng viền vàng/nét game: `icon_morning`, `icon_noon`, `icon_dusk`, `icon_night`, `icon_rain`, `icon_storm`, `icon_fog` trong `assets/fx/weather/`.

[Biểu tượng](world_life_review/weather/weather_icons.jpg) · [mưa trong cảnh](world_life_review/weather/rain_scene.gif) · [sét](world_life_review/weather/lightning_bolt_scene.gif) · [sương](world_life_review/weather/fog_scene.gif) · [mắt đỏ](world_life_review/weather/red_eyes.gif) · [giọt bắn](world_life_review/weather/rain_splash.gif).

Kiểm tra `check_world_life_weather.py` đối chiếu byte ảnh nền/nhân vật cũ, ánh sáng đêm, vị trí mắt, cel trống, đường nối của lớp lặp, VRAM và giới hạn 2 MB. [Kết quả](world_life_review/weather/validation.json) · [Godot resource smoke](world_life_review/weather/resource_smoke.log). `world_life_render_hours.gd` xuất 16 cảnh bằng Godot; PNG render gốc giữ ngoài repo, chỉ JPG/GIF nhỏ được đưa vào git.

## 4. Bản đồ sống động

Thêm `assets/bg/campaign/map_cloud_1.png` đến `map_cloud_3.png`, **600×260**, ba dáng mây trắng mềm có alpha. `map_smoke.png`: **6 cel192×192**, `map_flag.png`: **6 cel128×192** (chỉ vải đỏ lay, chồng giữa cột có sẵn), `waterfall.png`: **6 cel256×384**. Ba atlas ba cột, **12fps, lặp**, nén VRAM. `anim.json` ghi đủ hợp đồng. `map_water_glint.png` dùng lại nguyên byte bản sparkle có sẵn, màu/độ mờ do runtime điều chỉnh.

`ambience.json` theo cấu trúc `world_map_fx/anim.json` cũ: `textures`, `smoke` (dict position/phase), `water_glints` (cặp tọa độ), `smoke_motion`, `water_motion`; bổ sung `flags`, `waterfalls`, `clouds` và cách tạo bóng mây. Có hai bộ tọa độ rõ ràng:

- **`ambience.json` mặc định cho main hiện có hai đoạn**:1080×3840, đoạn2 y=0, đoạn1 y=1920. Như vậy dữ liệu mới không đặt khói/đốm nước sai chỗ trên main chưa có PR47.
- **`ambience_g2.json` cho hồi2 ba đoạn của PR47**:1080×5760, đoạn3 y=0, đoạn2 y=1920, đoạn1 y=3840. Khi Claude ghép với chiến dịch ba đoạn, chọn file này theo `Campaign.segments`. `profiles` trong file mặc định dẫn tới hai tên file.

Không dùng độ chồng200px của ảnh liên khung để tính tọa độ: game xếp từng đoạn trọn1920px. Mỗi vị trí còn ghi `segment` và `local_position` để đối chiếu nguồn. Khói bám đúng miệng ống khói nhà dân `(159,510)` và miệng nồi trại Orc `(373,1357)` theo tọa độ cục bộ; hai cờ ở `(635,788)` và `(270,1328)`. Hai thác đoạn1 đặt tâm ở `(158,298)` và `(936,920)` với kích thước60×90/84×126. Đốm nước có điểm ở suối và đầm; không đặt trên đường đất trại Orc.

[Vị trí trên bản đồ ba đoạn](world_life_review/map/map_positions_3_segments.jpg) · [GIF làng/suối/thác/khói/mây](world_life_review/map/village_life.gif) · [GIF trại Orc, cờ và khói nồi](world_life_review/map/orc_camp_life.gif). Cảnh được dựng bằng Godot từ các đoạn bản đồ PR47 đã có; PNG tranh bản đồ, layout và node trên nhánh này giữ nguyên byte.

[Ba mây](world_life_review/map/map_clouds.gif) · [khói](world_life_review/map/map_smoke.gif) · [cờ](world_life_review/map/map_flag.gif) · [thác](world_life_review/map/waterfall.gif).

Claude đổi nguồn mây đang mượn của trại Orc sang ba `map_cloud_*`, chọn đúng profile hai/ba đoạn, và nối các entry cờ/thác vào renderer ambience. Cờ lấy gốc `(64,20)` trên canvas128×192 tại mép treo; thác lấy tâm `(128,192)` và giữ tỉ lệ cel256×384 khi vẽ, không ép ô vuông. Khói/glint vẫn tải bằng định dạng cũ. Các tọa độ là map-local toàn bản đồ để cuộn cùng cảnh.

Kiểm tra `check_world_life_map.py`: hệ tọa độ2/3đoạn, điểm trong biên, kích thước/cel/mép alpha, sáu cel riêng cho từng FX, VRAM, byte map/layout/node cũ và preview dưới2MB. [Kết quả](world_life_review/map/validation.json) · [Godot smoke](world_life_review/map/resource_smoke.log) · [suite](world_life_review/map/godot_tests.log).

## Tái xuất

Các script `pack_world_life_hud.py`, `pack_world_life_faces.py`, `pack_world_life_weather.py`, `pack_world_life_map.py` chỉ cắt nguyên hình, chuẩn hóa và ghép atlas; nguồn/hash/crop trong `world_life_sources.json`, ảnh gốc giữ ngoài repo. Các script render Godot trong docs xuất PNG tham chiếu ngoài repo, sau đó dùng `--reviews-only` để ghép JPG/GIF nhỏ. Resource smoke dùng `world_life_resources.json`, bao gồm51texture mới/cập nhật. Bộ đóng gói #48 đã được chỉnh để giữ các nét `sly/dizzy` khi tái xuất bảng, thay vì ghi lại bảng12nét cũ.
