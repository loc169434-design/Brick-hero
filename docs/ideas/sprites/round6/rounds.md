# Đợt 6 — Bộ Băng (Bậc 5) & Các tuyệt kĩ theo bộ (`art/hero-frost`)

## 1. Trang mẫu & Tự duyệt theo checklist

- Trang mẫu: `docs/ideas/sprites/round6/frost_model_sheet.png`
- Trả lời checklist tự duyệt (đối chiếu cạnh `rookie_ref.png` và `round4/royal_model_sheet.png`):
  1. **Có đúng cùng một khuôn mặt không?** **Có** — mắt to, lông mày rậm, miệng cười lộ răng, tóc nâu lòi dưới mũ hở mặt bạc trắng đúng Tân binh.
  2. **Có râu không?** **Không** — cằm trơn hoàn toàn.
  3. **Có chỗ nào xanh lá không?** **Không** — chỉ dùng bạc trắng (`#E6ECF2`, `#B9C4CF`), xanh băng (`#8FE3F0`, `#4FB8D6`), xanh lam đinh (`#2F6FD0`) và khóa vàng (`#E8B530`), kèm viền nét tối lạnh để `key_out.py` không ăn vào mép trắng.
  4. **Có dễ phân biệt với Hoàng Gia khi thu nhỏ không?** **Có** — tông bạc trắng sáng lạnh + áo choàng trắng xanh cổ lông trắng + khiên bông tuyết tách biệt hoàn toàn với xanh hoàng gia đậm + áo choàng đỏ + chỏm lông đỏ của Bộ Hoàng Gia.

## 2. Việc 1 — Kết quả 25 clip Bộ Băng (`check_sheet.py`)

| STT | Clip | Khung | FPS | Cờ thêm | `grid` | `feet` | `size` | `clean` | `inside` | `key` | Số vòng | Kết quả |
|---:|---|---:|---:|---|---|---|---|---|---|---|---:|---|
| 1 | `fresh_idle.png` | 8 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 2 | `fresh_attack.png` | 12 | 24 | — | ĐẠT | ĐẠT | ĐẠT (398 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 3 | `fresh_hurt.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (393 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 4 | `fresh_run.png` | 8 | 16 | `--airborne --ref ...fresh_run.png` | ĐẠT | ĐẠT | ĐẠT (348 px tall / ref 338) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 5 | `fresh_block.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 6 | `fresh_dash.png` | 6 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 7 | `fresh_combo.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 8 | `fresh_throw.png` | 10 | 24 | — | ĐẠT | ĐẠT | ĐẠT (408 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 9 | `fresh_leap.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 10 | `fresh_kick.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 11 | `fresh_bash.png` | 10 | 24 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 12 | `fresh_drink.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 13 | `fresh_dizzy.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (408 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 14 | `fresh_knocked.png` | 8 | 24 | — | ĐẠT | ĐẠT | ĐẠT (379 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 15 | `fresh_scared.png` | 8 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 3 | **ĐẠT** |
| 16 | `fresh_cheer.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 17 | `fresh_victory.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (405 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 18 | `fresh_defeat.png` | 12 | 12 | — | ĐẠT | ĐẠT | ĐẠT (410 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 19 | `fresh_skill_armor_breaker.png` | 14 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |
| 20 | `fresh_skill_second_wind.png` | 14 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 3 | **ĐẠT** |
| 21 | `fresh_skill_thunder_slash.png` | 14 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 22 | `fresh_skill_iron_guard.png` | 10 | 12 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 23 | `fresh_skill_blade_vortex.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 24 | `fresh_skill_starfall_strike.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 1 | **ĐẠT** |
| 25 | `fresh_skill_frost_nova.png` | 16 | 24 | — | ĐẠT | ĐẠT | ĐẠT (406 px tall / ref 394) | ĐẠT | ĐẠT | ĐẠT | 2 | **ĐẠT** |

## 3. Việc 2 — Kết quả 3 tuyệt kĩ cho các bộ đã có (`check_sheet.py`)

| STT | Bộ | Clip | Khung | FPS | Tham chiếu `--ref` | Số vòng | Kết quả |
|---:|---|---|---:|---:|---|---:|---|
| 1 | `leather` | `fresh_skill_tumble_cut.png` | 16 | 24 | `anim/leather/fresh_idle.png` + `--airborne` | 1 | **ĐẠT** |
| 2 | `iron` | `fresh_skill_shield_charge.png` | 16 | 24 | `anim/iron/fresh_idle.png` | 3 | **ĐẠT** |
| 3 | `royal` | `fresh_skill_royal_rally.png` | 16 | 24 | `anim/royal/fresh_idle.png` | 3 | **ĐẠT** |

> [!NOTE]
> **Rà soát bổ sung đã hoàn thành**:
> - Toàn bộ mặt trong khiên Bộ Băng ở mọi clip lộ mặt trong (`attack`, `combo`, `dash`, `bash`, `run`, `skill_armor_breaker`, `skill_second_wind`, `skill_thunder_slash`, `skill_iron_guard`, `skill_blade_vortex`, `skill_starfall_strike`, `skill_frost_nova`) đều dùng đúng tông **bạc xám xanh** kèm quai da xanh lam (`#2F6FD0`).
> - Cỡ người và mặt ở `royal/fresh_skill_royal_rally.png` và `iron/fresh_skill_shield_charge.png` đã khớp 1:1 với `fresh_idle.png` của từng bộ, chân neo tại `(256, 500)`.

## 4. Chi tiết các clip đã hoàn thành

### Bộ Băng — `idle` (`fresh_idle.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_idle_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_idle.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_idle_frames.png`, `docs/ideas/sprites/round6/fresh_idle.gif`, `docs/ideas/sprites/round6/fresh_idle_report.json`
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

### Bộ Băng — `attack` (`fresh_attack.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_attack_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_attack.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_attack_frames.png`, `docs/ideas/sprites/round6/fresh_attack.gif`, `docs/ideas/sprites/round6/fresh_attack_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 398 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `hurt` (`fresh_hurt.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_hurt_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_hurt.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_hurt_frames.png`, `docs/ideas/sprites/round6/fresh_hurt.gif`, `docs/ideas/sprites/round6/fresh_hurt_report.json`
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

### Bộ Băng — `run` (`fresh_run.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_run_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_run.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_run_frames.png`, `docs/ideas/sprites/round6/fresh_run.gif`, `docs/ideas/sprites/round6/fresh_run_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 348 px tall, reference 338
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `block` (`fresh_block.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_block_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_block.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_block_frames.png`, `docs/ideas/sprites/round6/fresh_block.gif`, `docs/ideas/sprites/round6/fresh_block_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `dash` (`fresh_dash.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_dash_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_dash.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_dash_frames.png`, `docs/ideas/sprites/round6/fresh_dash.gif`, `docs/ideas/sprites/round6/fresh_dash_report.json`
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

### Bộ Băng — `combo` (`fresh_combo.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_combo_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_combo.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_combo_frames.png`, `docs/ideas/sprites/round6/fresh_combo.gif`, `docs/ideas/sprites/round6/fresh_combo_report.json`
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

### Bộ Băng — `throw` (`fresh_throw.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_throw_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_throw.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_throw_frames.png`, `docs/ideas/sprites/round6/fresh_throw.gif`, `docs/ideas/sprites/round6/fresh_throw_report.json`
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

### Bộ Băng — `leap` (`fresh_leap.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_leap_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_leap.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_leap_frames.png`, `docs/ideas/sprites/round6/fresh_leap.gif`, `docs/ideas/sprites/round6/fresh_leap_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `kick` (`fresh_kick.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_kick_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_kick.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_kick_frames.png`, `docs/ideas/sprites/round6/fresh_kick.gif`, `docs/ideas/sprites/round6/fresh_kick_report.json`
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

### Bộ Băng — `bash` (`fresh_bash.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_bash_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_bash.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_bash_frames.png`, `docs/ideas/sprites/round6/fresh_bash.gif`, `docs/ideas/sprites/round6/fresh_bash_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 10 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `drink` (`fresh_drink.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_drink_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_drink.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_drink_frames.png`, `docs/ideas/sprites/round6/fresh_drink.gif`, `docs/ideas/sprites/round6/fresh_drink_report.json`
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

### Bộ Băng — `dizzy` (`fresh_dizzy.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_dizzy_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_dizzy.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_dizzy_frames.png`, `docs/ideas/sprites/round6/fresh_dizzy.gif`, `docs/ideas/sprites/round6/fresh_dizzy_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `knocked` (`fresh_knocked.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_knocked_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_knocked.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_knocked_frames.png`, `docs/ideas/sprites/round6/fresh_knocked.gif`, `docs/ideas/sprites/round6/fresh_knocked_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 379 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `scared` (`fresh_scared.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_scared_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_scared.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_scared_frames.png`, `docs/ideas/sprites/round6/fresh_scared.gif`, `docs/ideas/sprites/round6/fresh_scared_report.json`
- Số vòng sửa: 3
```text
grid    ĐẠT  sheet 2048x1024 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 8 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `cheer` (`fresh_cheer.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_cheer_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_cheer.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_cheer_frames.png`, `docs/ideas/sprites/round6/fresh_cheer.gif`, `docs/ideas/sprites/round6/fresh_cheer_report.json`
- Số vòng sửa: 2
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 410 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `victory` (`fresh_victory.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_victory_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_victory.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_victory_frames.png`, `docs/ideas/sprites/round6/fresh_victory.gif`, `docs/ideas/sprites/round6/fresh_victory_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x1536 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 405 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 12 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `defeat` (`fresh_defeat.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_defeat_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_defeat.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_defeat_frames.png`, `docs/ideas/sprites/round6/fresh_defeat.gif`, `docs/ideas/sprites/round6/fresh_defeat_report.json`
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

### Bộ Băng — `skill_armor_breaker` (`fresh_skill_armor_breaker.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_armor_breaker_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_armor_breaker.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_armor_breaker_frames.png`, `docs/ideas/sprites/round6/fresh_skill_armor_breaker.gif`, `docs/ideas/sprites/round6/fresh_skill_armor_breaker_report.json`
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

### Bộ Băng — `skill_second_wind` (`fresh_skill_second_wind.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_second_wind_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_second_wind.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_second_wind_frames.png`, `docs/ideas/sprites/round6/fresh_skill_second_wind.gif`, `docs/ideas/sprites/round6/fresh_skill_second_wind_report.json`
- Số vòng sửa: 3
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 406 px tall, reference 394
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 14 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ Băng — `skill_thunder_slash` (`fresh_skill_thunder_slash.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_thunder_slash_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_thunder_slash.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_thunder_slash_frames.png`, `docs/ideas/sprites/round6/fresh_skill_thunder_slash.gif`, `docs/ideas/sprites/round6/fresh_skill_thunder_slash_report.json`
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

### Bộ Băng — `skill_iron_guard` (`fresh_skill_iron_guard.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_iron_guard_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_iron_guard.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_iron_guard_frames.png`, `docs/ideas/sprites/round6/fresh_skill_iron_guard.gif`, `docs/ideas/sprites/round6/fresh_skill_iron_guard_report.json`
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

### Bộ Băng — `skill_blade_vortex` (`fresh_skill_blade_vortex.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_blade_vortex_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_blade_vortex.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_blade_vortex_frames.png`, `docs/ideas/sprites/round6/fresh_skill_blade_vortex.gif`, `docs/ideas/sprites/round6/fresh_skill_blade_vortex_report.json`
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

### Bộ Băng — `skill_starfall_strike` (`fresh_skill_starfall_strike.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_starfall_strike_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_starfall_strike.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_starfall_strike_frames.png`, `docs/ideas/sprites/round6/fresh_skill_starfall_strike.gif`, `docs/ideas/sprites/round6/fresh_skill_starfall_strike_report.json`
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

### Bộ Băng — `skill_frost_nova` (`fresh_skill_frost_nova.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/fresh_skill_frost_nova_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/frost/fresh_skill_frost_nova.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_frost_nova_frames.png`, `docs/ideas/sprites/round6/fresh_skill_frost_nova.gif`, `docs/ideas/sprites/round6/fresh_skill_frost_nova_report.json`
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

### Bộ `leather` — `skill_tumble_cut` (`anim/leather/fresh_skill_tumble_cut.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/leather_fresh_skill_tumble_cut_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/leather/fresh_skill_tumble_cut.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_tumble_cut_frames.png`, `docs/ideas/sprites/round6/fresh_skill_tumble_cut.gif`, `docs/ideas/sprites/round6/fresh_skill_tumble_cut_report.json`
- Số vòng sửa: 1
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 412 px tall, reference 412
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ `iron` — `skill_shield_charge` (`anim/iron/fresh_skill_shield_charge.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/iron_fresh_skill_shield_charge_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/iron/fresh_skill_shield_charge.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_shield_charge_frames.png`, `docs/ideas/sprites/round6/fresh_skill_shield_charge.gif`, `docs/ideas/sprites/round6/fresh_skill_shield_charge_report.json`
- Số vòng sửa: 3
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 408 px tall, reference 408
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```

### Bộ `royal` — `skill_royal_rally` (`anim/royal/fresh_skill_royal_rally.png`)
- Bản gốc nền xanh: `docs/ideas/sprites/round6/raw/royal_fresh_skill_royal_rally_green.png`
- Bản tách nền (`key_out.py`): `assets/characters/hero_rookie/anim/royal/fresh_skill_royal_rally.png`
- Ảnh kiểm tra: `docs/ideas/sprites/round6/fresh_skill_royal_rally_frames.png`, `docs/ideas/sprites/round6/fresh_skill_royal_rally.gif`, `docs/ideas/sprites/round6/fresh_skill_royal_rally_report.json`
- Số vòng sửa: 3
```text
grid    ĐẠT  sheet 2048x2048 ok; empty frames: []
feet    ĐẠT  first/last frame feet (y, x) vs (500, 256): ok
size    ĐẠT  frame 0 body 412 px tall, reference 412
clean   ĐẠT  worst frame 0 stray pixels, 0 specks in 16 frames (and 0 haze pixels, cleared on shrinking)
inside  ĐẠT  frames touching the edge: none
key     ĐẠT  #00ff00 left: 0 px; rim tinted by it: 0 px
=> ĐẠT
```
