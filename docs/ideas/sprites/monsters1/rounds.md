# orc_chief — vòng 1, chờ duyệt

Nhánh `art/monsters-1`, tạo từ `origin/core/world-life` tại `d5b15e70b234f522ecd7b8bff2d484590abdccd4`. Checkout riêng: `/workspace/Brick-hero-art-monsters-1`. Chỉ làm `orc_chief`; dừng sau commit/push này.

## Kết quả đo — vòng kiểm 1/5

Cả 7 sheet ĐẠT ở lần chạy check_sheet đầu tiên; không cần vòng sửa sau kiểm. Mỗi sheet 4 cột, ô 512 × 512; 70 khung hoạt ảnh tổng cộng.

| Clip | Khung | fps | impact | Chân đầu/cuối (x, y) | Cao khung 0 / mẫu | Lệch x lớn nhất, toàn clip | Nền/viền hồng | Kết quả |
|---|---:|---:|---:|---|---|---:|---|---|
| `idle` | 8 | 12 | — | (256, 500) | 392 / 391 px (+0,26%) | 0.5 px | 0 / 0 px | **ĐẠT** |
| `attack` | 12 | 24 | 6 | (256, 500) | 392 / 391 px (+0,26%) | 10.5 px | 0 / 0 px | **ĐẠT** |
| `hurt` | 8 | 24 | — | (256, 500) | 392 / 391 px (+0,26%) | 8 px | 0 / 0 px | **ĐẠT** |
| `special` | 12 | 24 | 7 | (256, 500) | 392 / 391 px (+0,26%) | 38 px | 0 / 0 px | **ĐẠT** |
| `defeat` | 12 | 12 | — | (256, 500), cuối nằm gục | 392 / 391 px (+0,26%) | 29.5 px | 0 / 0 px | **ĐẠT** |
| `victory` | 8 | 12 | — | (256, 500) | 392 / 391 px (+0,26%) | 1.5 px | 0 / 0 px | **ĐẠT** |
| `rage` | 10 | 12 | — | (256, 500) | 392 / 391 px (+0,26%) | 2.5 px | 0 / 0 px | **ĐẠT** |

Tất cả: 0 stray, 0 speck, 0 haze, 0 pixel nền #FF00FF, 0 pixel viền hồng; không khung trống hoặc khung chạm mép. Chân mọi khung có y trong 499–502 px; chỉ số x dùng dải thấp nhất (ở special/7 có cả đầu chùy chạm đất). `defeat` được kiểm với `--airborne` đúng yêu cầu. Hai ô dư của `rage` hoàn toàn trong suốt.

## Vẽ và xử lý

- Dùng đúng khung 0 của fresh_idle cũ làm ảnh tham chiếu; giữ khuôn mặt da ôliu, vương miện sừng, áo choàng đỏ/khóa vàng/lông kem, đồ da nâu, chùy gỗ nạm kim loại và khiên gỗ tròn. Bản idle cũ được lưu nguyên vẹn trong `ref/orc_chief_idle_old.png` trước khi ghi đè.
- Ảnh vẽ sinh gốc nền hồng nằm ở `generated/`. `assemble_key.py` sắp các bản vẽ RGB lên lưới, chuẩn hóa nền trống về #FF00FF; hệ số x/y cố định cho từng clip, không kéo cỡ từng khung. Khôi phục trọn hình chùy khi vị trí ô nguồn lệch; chỉ dịch vừa đủ để không chạm mép. Thông số và bbox nguồn ghi trong `layout.json`.
- Các bản gốc RGB nền #FF00FF đúng lưới nằm tại `raw/orc_chief_<clip>_key.png`. Không tự vẽ/sửa ảnh alpha. Chỉ `tools/sprites/key_out.py --key ff00ff` tạo alpha cho 7 sheet đích.
- Dùng chung tư thế ready đầu/cuối để nối mượt; defeat chỉ dùng ở đầu và giữ cuối nằm trên đất. Attack impact ở 6; special hai tay đập chùy ở 7; rage có gồng người, gầm và đỏ má. Không vẽ vệt chém, bụi, bóng đất hay hiệu ứng.

## Kiểm trực quan

Đã xem từng khung của cả 7 clip trên nền tối, rồi tải cả 7 GIF trong Chromium và xem các ảnh chụp ở nhiều thời điểm. Tư thế nối vòng về ready; giữ vũ khí và màu, không thấy viền hồng hay hình bị cắt. GIF ở `dark/` dùng đúng fps (làm tròn thời lượng từng khung theo lưới 10 ms của GIF, giữ đúng tổng thời lượng); xem `review.html` hoặc từng GIF/contact sheet. Đây là kiểm art, chưa phải tích hợp gameplay.

## Chạy lại

Từ gốc repo:

```sh
python3 docs/ideas/sprites/monsters1/assemble_key.py
python3 tools/sprites/key_out.py docs/ideas/sprites/monsters1/raw/orc_chief_attack_key.png assets/characters/orc_chief/anim/fresh_attack.png --key ff00ff
python3 tools/sprites/check_sheet.py assets/characters/orc_chief/anim/fresh_attack.png --frames 12 --fps 24 --key ff00ff --ref docs/ideas/sprites/monsters1/ref/orc_chief_idle_old.png --out docs/ideas/sprites/monsters1
```

Lặp lại hai lệnh cuối cho các clip theo bảng; defeat thêm `--airborne`. `python3 docs/ideas/sprites/monsters1/make_previews.py` tái tạo GIF nền tối. Log từng lệnh kiểm: `fresh_<clip>_check.log`; số đo từng khung: `fresh_<clip>_report.json`.

## Bàn giao

Chỉ thay 7 PNG trong `assets/characters/orc_chief/anim/` và thêm hồ sơ này. Không sửa `anim.json`, `.import`, scripts, scenes, tests, project.godot hay hero_rookie. Claude cập nhật frame count/fps/impact trong anim.json sau khi duyệt. Chưa chạy nhập asset bằng Godot để tránh phát sinh/chỉnh .import. Không làm quái thứ 2 cho đến khi được duyệt.
