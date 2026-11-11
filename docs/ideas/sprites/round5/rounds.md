# Đợt 5 — Bộ Hắc Thép (Bậc 4) & Tuyệt kĩ `HẮC TRẢM` (`art/hero-obsidian`)

## 1. Trang mẫu & Tự duyệt theo checklist

- Trang mẫu: `docs/ideas/sprites/round5/obsidian_model_sheet.png`
- Trả lời checklist tự duyệt (đối chiếu cạnh `rookie_ref.png` và `round4/royal_model_sheet.png`):
  1. **Có đúng cùng một khuôn mặt không?** **Có** — mắt to, lông mày nâu rậm, miệng cười toe lộ răng trắng, tóc nâu lòi dưới mũ hở mặt đúng Tân binh.
  2. **Có râu không?** **Không** — cằm trơn hoàn toàn.
  3. **Có chỗ nào xanh lá hoặc xanh lam không?** **Không** — toàn bộ giáp dùng thép đen (`#2B2D33`, `#45484F`), bạc xám (`#9AA0A8`), đỏ (`#C0262D`) và đồng (`#D9822B`); không vương xanh lá hay xanh lam.
  4. **Khiên có phải tam giác đen với ngọn lửa đỏ không?** **Có** — khiên tam giác thép đen đầu nhọn hướng xuống, viền bạc xám, giữa chạm ngọn lửa đỏ; mặt trong thép đen tối quai da đỏ (không phải gỗ).

## 2. Kết quả kiểm tra 25 clip (`check_sheet.py`)

| STT | Clip | Khung | FPS | Cờ thêm | `grid` | `feet` | `size` | `clean` | `inside` | `key` | Số vòng | Kết quả |
|---:|---|---:|---:|---|---|---|---|---|---|---|---:|---|
| 1 | `fresh_idle.png` | 8 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 2 | `fresh_attack.png` | 12 | 24 | — | ĐẠT | ĐẠT | ĐẠT (396 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 3 | `fresh_hurt.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (393 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 4 | `fresh_run.png` | 8 | 16 | `--airborne --ref ...fresh_run.png` | ĐẠT | ĐẠT | ĐẠT (347 px tall / ref 338) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 5 | `fresh_block.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 6 | `fresh_dash.png` | 6 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 7 | `fresh_combo.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 8 | `fresh_throw.png` | 10 | 24 | — | ĐẠT | ĐẠT | ĐẠT (408 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 9 | `fresh_leap.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 10 | `fresh_kick.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 11 | `fresh_bash.png` | 10 | 24 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 12 | `fresh_drink.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 13 | `fresh_dizzy.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 14 | `fresh_knocked.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (379 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 15 | `fresh_scared.png` | 8 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 16 | `fresh_cheer.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 17 | `fresh_victory.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 18 | `fresh_defeat.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 19 | `fresh_skill_armor_breaker.png` | 14 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 20 | `fresh_skill_second_wind.png` | 14 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 21 | `fresh_skill_thunder_slash.png` | 14 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 22 | `fresh_skill_iron_guard.png` | 10 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 23 | `fresh_skill_blade_vortex.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 24 | `fresh_skill_starfall_strike.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 25 | `fresh_skill_obsidian_cleave.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |

## 3. Chi tiết từng clip

### `idle` (`fresh_idle.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_idle_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_idle.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_idle_frames.png`, `docs/ideas/sprites/round5/fresh_idle.gif`, `docs/ideas/sprites/round5/fresh_idle_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `attack` (`fresh_attack.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_attack_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_attack.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_attack_frames.png`, `docs/ideas/sprites/round5/fresh_attack.gif`, `docs/ideas/sprites/round5/fresh_attack_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 396 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `hurt` (`fresh_hurt.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_hurt_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_hurt.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_hurt_frames.png`, `docs/ideas/sprites/round5/fresh_hurt.gif`, `docs/ideas/sprites/round5/fresh_hurt_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 393 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `run` (`fresh_run.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_run_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_run.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_run_frames.png`, `docs/ideas/sprites/round5/fresh_run.gif`, `docs/ideas/sprites/round5/fresh_run_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 347 px tall, reference 338
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `block` (`fresh_block.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_block_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_block.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_block_frames.png`, `docs/ideas/sprites/round5/fresh_block.gif`, `docs/ideas/sprites/round5/fresh_block_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `dash` (`fresh_dash.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_dash_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_dash.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_dash_frames.png`, `docs/ideas/sprites/round5/fresh_dash.gif`, `docs/ideas/sprites/round5/fresh_dash_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 6 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `combo` (`fresh_combo.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_combo_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_combo.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_combo_frames.png`, `docs/ideas/sprites/round5/fresh_combo.gif`, `docs/ideas/sprites/round5/fresh_combo_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `throw` (`fresh_throw.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_throw_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_throw.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_throw_frames.png`, `docs/ideas/sprites/round5/fresh_throw.gif`, `docs/ideas/sprites/round5/fresh_throw_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `leap` (`fresh_leap.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_leap_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_leap.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_leap_frames.png`, `docs/ideas/sprites/round5/fresh_leap.gif`, `docs/ideas/sprites/round5/fresh_leap_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `kick` (`fresh_kick.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_kick_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_kick.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_kick_frames.png`, `docs/ideas/sprites/round5/fresh_kick.gif`, `docs/ideas/sprites/round5/fresh_kick_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `bash` (`fresh_bash.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_bash_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_bash.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_bash_frames.png`, `docs/ideas/sprites/round5/fresh_bash.gif`, `docs/ideas/sprites/round5/fresh_bash_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `drink` (`fresh_drink.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_drink_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_drink.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_drink_frames.png`, `docs/ideas/sprites/round5/fresh_drink.gif`, `docs/ideas/sprites/round5/fresh_drink_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `dizzy` (`fresh_dizzy.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_dizzy_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_dizzy.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_dizzy_frames.png`, `docs/ideas/sprites/round5/fresh_dizzy.gif`, `docs/ideas/sprites/round5/fresh_dizzy_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `knocked` (`fresh_knocked.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_knocked_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_knocked.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_knocked_frames.png`, `docs/ideas/sprites/round5/fresh_knocked.gif`, `docs/ideas/sprites/round5/fresh_knocked_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 379 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `scared` (`fresh_scared.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_scared_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_scared.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_scared_frames.png`, `docs/ideas/sprites/round5/fresh_scared.gif`, `docs/ideas/sprites/round5/fresh_scared_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `cheer` (`fresh_cheer.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_cheer_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_cheer.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_cheer_frames.png`, `docs/ideas/sprites/round5/fresh_cheer.gif`, `docs/ideas/sprites/round5/fresh_cheer_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `victory` (`fresh_victory.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_victory_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_victory.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_victory_frames.png`, `docs/ideas/sprites/round5/fresh_victory.gif`, `docs/ideas/sprites/round5/fresh_victory_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `defeat` (`fresh_defeat.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_defeat_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_defeat.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_defeat_frames.png`, `docs/ideas/sprites/round5/fresh_defeat.gif`, `docs/ideas/sprites/round5/fresh_defeat_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_armor_breaker` (`fresh_skill_armor_breaker.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_armor_breaker_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_armor_breaker.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_armor_breaker_frames.png`, `docs/ideas/sprites/round5/fresh_skill_armor_breaker.gif`, `docs/ideas/sprites/round5/fresh_skill_armor_breaker_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_second_wind` (`fresh_skill_second_wind.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_second_wind_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_second_wind.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_second_wind_frames.png`, `docs/ideas/sprites/round5/fresh_skill_second_wind.gif`, `docs/ideas/sprites/round5/fresh_skill_second_wind_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_thunder_slash` (`fresh_skill_thunder_slash.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_thunder_slash_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_thunder_slash.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_thunder_slash_frames.png`, `docs/ideas/sprites/round5/fresh_skill_thunder_slash.gif`, `docs/ideas/sprites/round5/fresh_skill_thunder_slash_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_iron_guard` (`fresh_skill_iron_guard.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_iron_guard_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_iron_guard.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_iron_guard_frames.png`, `docs/ideas/sprites/round5/fresh_skill_iron_guard.gif`, `docs/ideas/sprites/round5/fresh_skill_iron_guard_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_blade_vortex` (`fresh_skill_blade_vortex.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_blade_vortex_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_blade_vortex.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_blade_vortex_frames.png`, `docs/ideas/sprites/round5/fresh_skill_blade_vortex.gif`, `docs/ideas/sprites/round5/fresh_skill_blade_vortex_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_starfall_strike` (`fresh_skill_starfall_strike.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_starfall_strike_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_starfall_strike.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_starfall_strike_frames.png`, `docs/ideas/sprites/round5/fresh_skill_starfall_strike.gif`, `docs/ideas/sprites/round5/fresh_skill_starfall_strike_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### `skill_obsidian_cleave` (`fresh_skill_obsidian_cleave.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round5/raw/fresh_skill_obsidian_cleave_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/obsidian/fresh_skill_obsidian_cleave.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round5/fresh_skill_obsidian_cleave_frames.png`, `docs/ideas/sprites/round5/fresh_skill_obsidian_cleave.gif`, `docs/ideas/sprites/round5/fresh_skill_obsidian_cleave_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```
