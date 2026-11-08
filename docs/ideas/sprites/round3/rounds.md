# Đợt 3 — Bộ sắt (Tier-2 Iron Set) — Báo cáo kiểm tra

## 1. Trang mẫu Bộ sắt (`iron_model_sheet.png`)
- Bản gốc nền xanh `#00FF00`: `docs/ideas/sprites/round3/raw/iron_model_sheet_green.png`
- Bản tách nền (`key_out.py`): `docs/ideas/sprites/round3/iron_model_sheet.png`
- Giữ nguyên gương mặt Tân binh (mắt nâu to, cười nhe răng, cằm trơn không râu), tóc nâu bù xù lộ dưới vành mũ sắt tròn, khăn choàng đỏ, áo lam dưới giáp ngực sắt (`#B8C2CC` / `#7E8A96`), cầu vai sắt, găng sắt, tà giáp sắt đinh tán, giày có ốp ống quyển và mũi sắt, kiếm sắt sáng, khiên sắt tròn có vạch sơn đỏ ngang (`#C8382B`).

## 2. Kết quả kiểm tra 24 clip Bộ sắt (`check_sheet.py --key 00ff00`)

| # | Clip | Số khung | FPS | Cỡ ảnh | Cỡ nhân vật (Frame 0) | Kết quả 6 mục (`grid`, `feet`, `size`, `clean`, `inside`, `key`) |
|---|---|---:|---:|---|---|---|
| 1 | `fresh_idle.png` | 8 | 12 | 2048×1024 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 2 | `fresh_attack.png` | 12 | 24 | 2048×1536 | 396 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 3 | `fresh_throw.png` | 10 | 24 | 2048×1536 | 406 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 4 | `fresh_leap.png` | 16 | 24 | 2048×2048 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 5 | `fresh_kick.png` | 8 | 24 | 2048×1024 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 6 | `fresh_bash.png` | 10 | 24 | 2048×1536 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 7 | `fresh_drink.png` | 12 | 12 | 2048×1536 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 8 | `fresh_hurt.png` | 8 | 24 | 2048×1024 | 391 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 9 | `fresh_dizzy.png` | 12 | 12 | 2048×1536 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 10 | `fresh_knocked.png` | 8 | 24 | 2048×1024 | 377 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 11 | `fresh_scared.png` | 8 | 12 | 2048×1024 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 12 | `fresh_cheer.png` | 12 | 12 | 2048×1536 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 13 | `fresh_victory.png` | 12 | 12 | 2048×1536 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 14 | `fresh_defeat.png` | 12 | 12 | 2048×1536 | 408 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 15 | `fresh_run.png` | 8 | 16 | 2048×1024 | 346 px tall, reference 338 (`--airborne`) | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 16 | `fresh_combo.png` | 16 | 24 | 2048×2048 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 17 | `fresh_block.png` | 8 | 24 | 2048×1024 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 18 | `fresh_dash.png` | 6 | 24 | 2048×1024 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 19 | `fresh_skill_armor_breaker.png` | 14 | 24 | 2048×2048 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 20 | `fresh_skill_second_wind.png` | 14 | 12 | 2048×2048 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 21 | `fresh_skill_thunder_slash.png` | 14 | 24 | 2048×2048 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 22 | `fresh_skill_iron_guard.png` | 10 | 12 | 2048×1536 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 23 | `fresh_skill_blade_vortex.png` | 16 | 24 | 2048×2048 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |
| 24 | `fresh_skill_starfall_strike.png` | 16 | 24 | 2048×2048 | 404 px tall, reference 394 | **ĐẠT** (0 stray, 0 specks, 0 haze, 0 #00ff00) |

## 3. Chi tiết log `check_sheet.py`
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 396 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 391 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 377 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 346 px tall, reference 338
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 6 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 404 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT

```
