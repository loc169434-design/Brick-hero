# Issue #48 — nền đứng vững và Cóc B chuyển động

- [So sánh trại Orc / trước / sau, bố cục trong game](backgrounds_game_layout.jpg): hiệp sĩ và Orc/Goblin `fresh_idle`, scale 0,7; chân `(270,405)` và `(810,405)`, nền dịch lên 80 px như PR #47.
- [So sánh trên canvas nền gốc 1080×660](backgrounds_native_feet.jpg).
- [Nền đầm lầy](swamp_background.jpg) · [ghép nhân vật và đánh dấu dải đất](swamp_feet_overlay.jpg).
- [Nền trại Goblin](goblin_camp_background.jpg) · [ghép nhân vật và đánh dấu dải đất](goblin_camp_feet_overlay.jpg).
- **[GIF bảng 7×8, ô 46 px, idle lệch nhịp](board_7x8_idle_offset.gif)** · [ảnh tĩnh](board_7x8_46px.jpg).
- [Ba biểu cảm mới của cả bốn màu](new_expressions.jpg).

GIF chi tiết bốn màu, chạy đúng fps của clip (GIF làm tròn thời gian theo đơn vị 10 ms):

| Clip | Khung / fps | Xem |
|---|---|---|
| idle | 12 / 10, lặp | [Thở, liếc mắt, ộp](idle_four_colors.gif) |
| taunt | 10 / 12 | [Lè lưỡi](taunt_four_colors.gif) |
| hurt | 8 / 14 | [Bẹp, mắt xoáy, bật lại](hurt_four_colors.gif) |
| fear | 8 / 12, lặp | [Run và mồ hôi](fear_four_colors.gif) |
| combo | 8 / 16 | [Nhảy và tan thành bọt](combo_four_colors.gif) |
| drop | 6 / 16 | [Rơi](drop_four_colors.gif) |
| land | 6 / 16 | [Chạm đất, nảy](land_four_colors.gif) |
| gloat | 8 / 12 | [Đắc ý](gloat_four_colors.gif) |
| near_miss | 8 / 12 | [Hú hồn](near_miss_four_colors.gif) |
| win | 8 / 12 | [Thắng](win_four_colors.gif) |
| lose | 8 / 12 | [Thua](lose_four_colors.gif) |
| death | 8 / 12 | [Tan thành bọt](death_four_colors.gif) |

Tất cả 21 ảnh xem thử là JPG/GIF dưới 2.000.000 byte mỗi file. [Bàn giao](../swamp_polish_handoff.md) · [kiểm tra ảnh](validation.json) · [Godot smoke](resource_smoke.log) · [suite hiện có](godot_tests.log).
