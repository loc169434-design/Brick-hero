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

Đã xem từng khung của cả 7 clip trên nền tối, rồi tải cả 7 GIF trong Chromium và xem các ảnh chụp ở nhiều thời điểm. Tư thế nối vòng về ready; giữ vũ khí và màu, không thấy viền hồng hay hình bị cắt. GIF ở `orc_chief/dark/` dùng đúng fps (làm tròn thời lượng từng khung theo lưới 10 ms của GIF, giữ đúng tổng thời lượng); xem `orc_chief/review.html` hoặc từng GIF/contact sheet. Đây là kiểm art, chưa phải tích hợp gameplay.

## Chạy lại

Từ gốc repo:

```sh
python3 docs/ideas/sprites/monsters1/assemble_key.py
python3 tools/sprites/key_out.py docs/ideas/sprites/monsters1/raw/orc_chief_attack_key.png assets/characters/orc_chief/anim/fresh_attack.png --key ff00ff
python3 tools/sprites/check_sheet.py assets/characters/orc_chief/anim/fresh_attack.png --frames 12 --fps 24 --key ff00ff --ref docs/ideas/sprites/monsters1/ref/orc_chief_idle_old.png --out docs/ideas/sprites/monsters1
```

Lặp lại hai lệnh cuối cho các clip theo bảng; defeat thêm `--airborne`. `python3 docs/ideas/sprites/monsters1/make_previews.py` tái tạo GIF nền tối. Log từng lệnh kiểm: `orc_chief/fresh_<clip>_check.log`; số đo từng khung: `orc_chief/fresh_<clip>_report.json`.

## Bàn giao

Chỉ thay 7 PNG trong `assets/characters/orc_chief/anim/` và thêm hồ sơ này. Không sửa `anim.json`, `.import`, scripts, scenes, tests, project.godot hay hero_rookie. Claude cập nhật frame count/fps/impact trong anim.json sau khi duyệt. Chưa chạy nhập asset bằng Godot để tránh phát sinh/chỉnh .import. Không làm quái thứ 2 cho đến khi được duyệt.


## orc_chief_enraged — vòng kiểm 1/5

| Sheet | Khung | fps | impact | Cao 0 / mẫu | Lệch x dải chân tối đa | Kết quả |
|---|---:|---:|---:|---|---:|---|
| `idle` | 8 | 12 | — | 408 / 408 px | 1 px | **ĐẠT** |
| `attack` | 12 | 24 | 6 | 408 / 408 px | 37 px | **ĐẠT** |
| `hurt` | 8 | 24 | — | 408 / 408 px | 1 px | **ĐẠT** |
| `special` | 12 | 24 | 7 | 408 / 408 px | 16 px | **ĐẠT** |
| `defeat` | 12 | 12 | — | 408 / 408 px | 2 px | **ĐẠT** |
| `victory` | 8 | 12 | — | 408 / 408 px | 1 px | **ĐẠT** |
| `rage` | 10 | 12 | — | 408 / 408 px | 6 px | **ĐẠT** |

Hồ sơ từng khung, log kiểm, GIF nền tối và review: [`orc_chief_enraged/review.html`](orc_chief_enraged/review.html). Ảnh RGB gốc nằm ở `orc_chief_enraged/generated/`, bản nền hồng chuẩn lưới ở `raw/orc_chief_enraged_<clip>_key.png`. Dùng cùng ready ở đầu/cuối (trừ defeat), hệ số cỡ người cố định từng clip; chỉ key_out.py tạo alpha. Idle thở/nhún rõ hơn, hurt bật ngửa mạnh hơn. Chưa đổi anim.json hoặc .import; chưa tích hợp gameplay.


## orc_chief_enraged — vòng kiểm 2/5

| Sheet | Khung | fps | impact | Cao 0 / mẫu | Lệch x dải chân tối đa | Kết quả |
|---|---:|---:|---:|---|---:|---|
| `idle` | 8 | 12 | — | 408 / 408 px | 1 px | **ĐẠT** |
| `attack` | 12 | 24 | 6 | 408 / 408 px | 37 px | **ĐẠT** |
| `hurt` | 8 | 24 | — | 408 / 408 px | 1 px | **ĐẠT** |
| `special` | 12 | 24 | 7 | 408 / 408 px | 26.5 px | **ĐẠT** |
| `defeat` | 12 | 12 | — | 408 / 408 px | 2 px | **ĐẠT** |
| `victory` | 8 | 12 | — | 408 / 408 px | 1 px | **ĐẠT** |
| `rage` | 10 | 12 | — | 408 / 408 px | 6 px | **ĐẠT** |

Hồ sơ từng khung, log kiểm, GIF nền tối và review: [`orc_chief_enraged/review.html`](orc_chief_enraged/review.html). Ảnh RGB gốc nằm ở `orc_chief_enraged/generated/`, bản nền hồng chuẩn lưới ở `raw/orc_chief_enraged_<clip>_key.png`. Dùng cùng ready ở đầu/cuối (trừ defeat), hệ số cỡ người cố định từng clip; chỉ key_out.py tạo alpha. Idle thở/nhún rõ hơn, hurt bật ngửa mạnh hơn. Chưa đổi anim.json hoặc .import; chưa tích hợp gameplay.

## orc_chief — sửa theo duyệt, vòng 2/5 (idle vòng 3/5)

- special/5: vẽ lại hướng trái, hai tay giơ chùy trên đầu, mặt và vương miện rõ, giữ khiên tay trái. Chỉ thay ô 5.
- attack/1: vẽ lại thân thấp, bè và khiên cùng cỡ khung 0. Chỉ thay ô 1.
- idle: đăng ký lại nhịp thở 0–2–4–6–6–4–2–0 px ở vai/bụng, giữ nguyên toàn bộ phần chân y>=420. Loại bản ghép có đường nối sau kiểm trực quan; không dùng bản đó.
- Chỉ xử lý ảnh RGB nền hồng; alpha được tách lại bằng key_out.py. Ảnh sinh gốc sửa được lưu trong orc_chief/generated_revision_*.png.

| Sheet | Khung | fps | Kết quả check_sheet |
|---|---:|---:|---|
| fresh_special | 12 | 24 | ĐẠT |
| fresh_attack | 12 | 24 | ĐẠT |
| fresh_idle | 8 | 12 | ĐẠT |

Báo cáo chi tiết và GIF được cập nhật trong orc_chief/. Không thay các sheet đã duyệt khác, anim.json hoặc .import.


## orc_rock — vòng kiểm 1/5

| Sheet | Khung | fps | impact | Cao 0 / mẫu | Lệch x dải chân tối đa | Kết quả |
|---|---:|---:|---:|---|---:|---|
| `idle` | 8 | 12 | — | 385 / 385 px | 0.5 px | **ĐẠT** |
| `attack` | 12 | 24 | 6 | 385 / 385 px | 6 px | **ĐẠT** |
| `hurt` | 8 | 24 | — | 385 / 385 px | 1 px | **ĐẠT** |
| `special` | 12 | 24 | 7 | 385 / 385 px | 20 px | **ĐẠT** |
| `defeat` | 12 | 12 | — | 385 / 385 px | 2.5 px | **ĐẠT** |
| `victory` | 8 | 12 | — | 385 / 385 px | 0.5 px | **ĐẠT** |
| `rage` | 10 | 12 | — | 385 / 385 px | 1 px | **ĐẠT** |

Hồ sơ từng khung, log kiểm, GIF nền tối và review: [`orc_rock/review.html`](orc_rock/review.html). Ảnh RGB gốc nằm ở `orc_rock/generated/`, bản nền hồng chuẩn lưới ở `raw/orc_rock_<clip>_key.png`. Dùng cùng ready ở đầu/cuối (trừ defeat), hệ số cỡ người cố định từng clip; chỉ key_out.py tạo alpha. Idle thở/nhún rõ hơn, hurt bật ngửa mạnh hơn. Chưa đổi anim.json hoặc .import; chưa tích hợp gameplay.


## orc_drummer — vòng kiểm 1/5

| Sheet | Khung | fps | impact | Cao 0 / mẫu | Lệch x dải chân tối đa | Kết quả |
|---|---:|---:|---:|---|---:|---|
| `idle` | 8 | 12 | — | 323 / 323 px | 0 px | **ĐẠT** |
| `attack` | 12 | 24 | 6 | 323 / 323 px | 0.5 px | **ĐẠT** |
| `hurt` | 8 | 24 | — | 323 / 323 px | 1 px | **ĐẠT** |
| `special` | 12 | 24 | 7 | 323 / 323 px | 1.5 px | **ĐẠT** |
| `defeat` | 12 | 12 | — | 323 / 323 px | 1 px | **ĐẠT** |
| `victory` | 8 | 12 | — | 323 / 323 px | 0.5 px | **ĐẠT** |
| `rage` | 10 | 12 | — | 323 / 323 px | 0.5 px | **ĐẠT** |

Hồ sơ từng khung, log kiểm, GIF nền tối và review: [`orc_drummer/review.html`](orc_drummer/review.html). Ảnh RGB gốc nằm ở `orc_drummer/generated/`, bản nền hồng chuẩn lưới ở `raw/orc_drummer_<clip>_key.png`. Dùng cùng ready ở đầu/cuối (trừ defeat), hệ số cỡ người cố định từng clip; chỉ key_out.py tạo alpha. Idle thở/nhún rõ hơn, hurt bật ngửa mạnh hơn. Chưa đổi anim.json hoặc .import; chưa tích hợp gameplay.
