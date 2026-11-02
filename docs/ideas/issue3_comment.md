Đã sửa 5 điểm trên nhánh `art/tiles`. Chỉ đổi `assets/` và `docs/ideas/`, không sửa scripts/scenes/tests/project.godot, không cập nhật gh-pages và không merge main/PR #2.

1. **Màu Orc:** viền sơn rộng + phụ kiện/huy hiệu: khăn đỏ/kiếm; mũ lá/lá (da xám xanh); mũ sắt vàng/đồng xu; mũ trùm tím/pha lê. Xuất lại đủ 48 clip Orc và 36 nét mặt.
2. **Đệm/cỡ:** cả 8 ô Training/Orc có bounds alpha **120×120 tại (4,4)** trên canvas 128. Bốn PNG dự phòng ở gốc đồng bộ Training. 28 clip Training đổi vì cả bốn ô đổi đệm. Frame đầu idle/land khớp ảnh tĩnh, bounds **(36,36,120,120)** trong frame 192; land chỉ bắt đầu nảy/bụi từ frame sau.
3. **Ảnh đặc biệt:** thêm `assets/tiles/special_lightning.png`, `special_bomb.png` (overlay trong suốt), `special_rainbow.png` (cả ô thay thế). Đã chồng sét/bom lên đủ 8 ô nền, xem ở 100 px màu và xám.
4. **Tương thích:** tên file không đổi; toàn bộ 76 bản ghi atlases giữ nguyên (deep-equality), gồm family/color/animation/file/fps/loop/frames/columns/cell. Không đổi schema, fps hoặc loop. SpriteFrames không đổi; metadata mô tả phụ kiện/pose đầu land cập nhật theo ảnh mới.
5. **Dung lượng:** PNG nén không mất dữ liệu mức 9, bỏ metadata ngày giờ; chỉ commit một bộ cuối. Bộ xuất so pixel và giữ file giống nguyên trạng. Xuất lại cùng input: **0 atlas cập nhật, 76 giữ nguyên**. Không đẩy các lần thử/bản web.

**Tự kiểm tra:**

- Đã tự xem 4 màu cạnh nhau ở **46×46**, **100×100** và **ảnh xám**: phân biệt được viền, phụ kiện và huy hiệu. Đây là tự quan sát, không phải thử nghiệm tốc độ với người chơi.
- Mảng màu gameplay trên toàn canvas 46 px, có trọng số alpha: **đỏ 53,5%; xanh 43,8%; vàng 55,2%; tím 46,3%**, đều >40%.
- **87 kiểm tra issue #3 PASS**, **325 kiểm tra browser PASS**.
- Godot 4.7.2 import không lỗi; tải đủ **8 SpriteFrames / 76 clip / 1.824 frame**.
- Nhờ Claude merge art/tiles lại vào PR #2, chạy tests gameplay và chụp NEXT/HOLD 46 px/bàn 100 px trước khi merge main; kiểm tra asset không thay cho kiểm tra game.

![Orc 46 px màu](https://github.com/loc169434-design/Brick-hero/blob/art/tiles/docs/ideas/issue3_review/orc_shield_46_color.png?raw=true)

![Orc 46 px xám](https://github.com/loc169434-design/Brick-hero/blob/art/tiles/docs/ideas/issue3_review/orc_shield_46_gray.png?raw=true)

[Báo cáo và cách chạy lại](https://github.com/loc169434-design/Brick-hero/blob/art/tiles/docs/ideas/issue3_feedback.md) · [Ảnh 100 px/overlay màu và xám](https://github.com/loc169434-design/Brick-hero/blob/art/tiles/docs/ideas/issue3_review/) · [Số đo](https://github.com/loc169434-design/Brick-hero/blob/art/tiles/docs/ideas/issue3_review/metrics.json).

<details>
<summary>Danh sách đầy đủ 164 file đã đổi</summary>

```text
assets/tiles/animation_pack.json
assets/tiles/orc_shield/animations/green_combo.png
assets/tiles/orc_shield/animations/green_death.png
assets/tiles/orc_shield/animations/green_drop.png
assets/tiles/orc_shield/animations/green_fear.png
assets/tiles/orc_shield/animations/green_gloat.png
assets/tiles/orc_shield/animations/green_hurt.png
assets/tiles/orc_shield/animations/green_idle.png
assets/tiles/orc_shield/animations/green_land.png
assets/tiles/orc_shield/animations/green_lose.png
assets/tiles/orc_shield/animations/green_near_miss.png
assets/tiles/orc_shield/animations/green_taunt.png
assets/tiles/orc_shield/animations/green_win.png
assets/tiles/orc_shield/animations/purple_combo.png
assets/tiles/orc_shield/animations/purple_death.png
assets/tiles/orc_shield/animations/purple_drop.png
assets/tiles/orc_shield/animations/purple_fear.png
assets/tiles/orc_shield/animations/purple_gloat.png
assets/tiles/orc_shield/animations/purple_hurt.png
assets/tiles/orc_shield/animations/purple_idle.png
assets/tiles/orc_shield/animations/purple_land.png
assets/tiles/orc_shield/animations/purple_lose.png
assets/tiles/orc_shield/animations/purple_near_miss.png
assets/tiles/orc_shield/animations/purple_taunt.png
assets/tiles/orc_shield/animations/purple_win.png
assets/tiles/orc_shield/animations/red_combo.png
assets/tiles/orc_shield/animations/red_death.png
assets/tiles/orc_shield/animations/red_drop.png
assets/tiles/orc_shield/animations/red_fear.png
assets/tiles/orc_shield/animations/red_gloat.png
assets/tiles/orc_shield/animations/red_hurt.png
assets/tiles/orc_shield/animations/red_idle.png
assets/tiles/orc_shield/animations/red_land.png
assets/tiles/orc_shield/animations/red_lose.png
assets/tiles/orc_shield/animations/red_near_miss.png
assets/tiles/orc_shield/animations/red_taunt.png
assets/tiles/orc_shield/animations/red_win.png
assets/tiles/orc_shield/animations/yellow_combo.png
assets/tiles/orc_shield/animations/yellow_death.png
assets/tiles/orc_shield/animations/yellow_drop.png
assets/tiles/orc_shield/animations/yellow_fear.png
assets/tiles/orc_shield/animations/yellow_gloat.png
assets/tiles/orc_shield/animations/yellow_hurt.png
assets/tiles/orc_shield/animations/yellow_idle.png
assets/tiles/orc_shield/animations/yellow_land.png
assets/tiles/orc_shield/animations/yellow_lose.png
assets/tiles/orc_shield/animations/yellow_near_miss.png
assets/tiles/orc_shield/animations/yellow_taunt.png
assets/tiles/orc_shield/animations/yellow_win.png
assets/tiles/orc_shield/expressions/green_blink.png
assets/tiles/orc_shield/expressions/green_chuckle.png
assets/tiles/orc_shield/expressions/green_fear.png
assets/tiles/orc_shield/expressions/green_gloat.png
assets/tiles/orc_shield/expressions/green_hurt.png
assets/tiles/orc_shield/expressions/green_idle.png
assets/tiles/orc_shield/expressions/green_laugh.png
assets/tiles/orc_shield/expressions/green_relief.png
assets/tiles/orc_shield/expressions/green_scream.png
assets/tiles/orc_shield/expressions/purple_blink.png
assets/tiles/orc_shield/expressions/purple_chuckle.png
assets/tiles/orc_shield/expressions/purple_fear.png
assets/tiles/orc_shield/expressions/purple_gloat.png
assets/tiles/orc_shield/expressions/purple_hurt.png
assets/tiles/orc_shield/expressions/purple_idle.png
assets/tiles/orc_shield/expressions/purple_laugh.png
assets/tiles/orc_shield/expressions/purple_relief.png
assets/tiles/orc_shield/expressions/purple_scream.png
assets/tiles/orc_shield/expressions/red_blink.png
assets/tiles/orc_shield/expressions/red_chuckle.png
assets/tiles/orc_shield/expressions/red_fear.png
assets/tiles/orc_shield/expressions/red_gloat.png
assets/tiles/orc_shield/expressions/red_hurt.png
assets/tiles/orc_shield/expressions/red_idle.png
assets/tiles/orc_shield/expressions/red_laugh.png
assets/tiles/orc_shield/expressions/red_relief.png
assets/tiles/orc_shield/expressions/red_scream.png
assets/tiles/orc_shield/expressions/yellow_blink.png
assets/tiles/orc_shield/expressions/yellow_chuckle.png
assets/tiles/orc_shield/expressions/yellow_fear.png
assets/tiles/orc_shield/expressions/yellow_gloat.png
assets/tiles/orc_shield/expressions/yellow_hurt.png
assets/tiles/orc_shield/expressions/yellow_idle.png
assets/tiles/orc_shield/expressions/yellow_laugh.png
assets/tiles/orc_shield/expressions/yellow_relief.png
assets/tiles/orc_shield/expressions/yellow_scream.png
assets/tiles/orc_shield/expressions_green.png
assets/tiles/orc_shield/expressions_purple.png
assets/tiles/orc_shield/expressions_red.png
assets/tiles/orc_shield/expressions_yellow.png
assets/tiles/orc_shield/source_rects.json
assets/tiles/orc_shield/tile_green.png
assets/tiles/orc_shield/tile_purple.png
assets/tiles/orc_shield/tile_red.png
assets/tiles/orc_shield/tile_yellow.png
assets/tiles/special_bomb.png
assets/tiles/special_bomb.png.import
assets/tiles/special_lightning.png
assets/tiles/special_lightning.png.import
assets/tiles/special_rainbow.png
assets/tiles/special_rainbow.png.import
assets/tiles/tile_green.png
assets/tiles/tile_purple.png
assets/tiles/tile_red.png
assets/tiles/tile_yellow.png
assets/tiles/training/animations/green_combo.png
assets/tiles/training/animations/green_drop.png
assets/tiles/training/animations/green_hurt.png
assets/tiles/training/animations/green_idle.png
assets/tiles/training/animations/green_land.png
assets/tiles/training/animations/green_lose.png
assets/tiles/training/animations/green_win.png
assets/tiles/training/animations/purple_combo.png
assets/tiles/training/animations/purple_drop.png
assets/tiles/training/animations/purple_hurt.png
assets/tiles/training/animations/purple_idle.png
assets/tiles/training/animations/purple_land.png
assets/tiles/training/animations/purple_lose.png
assets/tiles/training/animations/purple_win.png
assets/tiles/training/animations/red_combo.png
assets/tiles/training/animations/red_drop.png
assets/tiles/training/animations/red_hurt.png
assets/tiles/training/animations/red_idle.png
assets/tiles/training/animations/red_land.png
assets/tiles/training/animations/red_lose.png
assets/tiles/training/animations/red_win.png
assets/tiles/training/animations/yellow_combo.png
assets/tiles/training/animations/yellow_drop.png
assets/tiles/training/animations/yellow_hurt.png
assets/tiles/training/animations/yellow_idle.png
assets/tiles/training/animations/yellow_land.png
assets/tiles/training/animations/yellow_lose.png
assets/tiles/training/animations/yellow_win.png
assets/tiles/training/tile_green.png
assets/tiles/training/tile_purple.png
assets/tiles/training/tile_red.png
assets/tiles/training/tile_yellow.png
docs/ideas/animation_pack.md
docs/ideas/asset_preview/data.js
docs/ideas/asset_preview/export.mjs
docs/ideas/asset_preview/index.html
docs/ideas/asset_preview/issue3_verify.mjs
docs/ideas/asset_preview/renderer.js
docs/ideas/claude_integration_handoff.md
docs/ideas/issue3_comment.md
docs/ideas/issue3_feedback.md
docs/ideas/issue3_files_changed.txt
docs/ideas/issue3_review/.gdignore
docs/ideas/issue3_review/index.html
docs/ideas/issue3_review/metrics.json
docs/ideas/issue3_review/orc_shield_100_color.png
docs/ideas/issue3_review/orc_shield_100_gray.png
docs/ideas/issue3_review/orc_shield_46_color.png
docs/ideas/issue3_review/orc_shield_46_gray.png
docs/ideas/issue3_review/specials_100_color.png
docs/ideas/issue3_review/specials_100_gray.png
docs/ideas/issue3_review/specials_standalone_100_color.png
docs/ideas/issue3_review/specials_standalone_100_gray.png
docs/ideas/issue3_review/specials_standalone_46_color.png
docs/ideas/issue3_review/specials_standalone_46_gray.png
docs/ideas/issue3_review/training_100_color.png
docs/ideas/issue3_review/training_100_gray.png
docs/ideas/issue3_review/training_46_color.png
docs/ideas/issue3_review/training_46_gray.png
docs/ideas/tile_art.md
```

</details>
