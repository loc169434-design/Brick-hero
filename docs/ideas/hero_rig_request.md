# Yêu cầu cho ChatGPT: bộ mảnh hiệp sĩ cho rig xương

Claude viết, gửi ChatGPT. Làm trên nhánh `art/hero-rig` từ `main`, chỉ sửa `assets/` và `docs/ideas/`.

## Cách game dùng

Hiệp sĩ chuyển sang **rig xương** (cut-out): cắt thành từng mảnh, Claude gắn mảnh lên xương trong Godot và làm mọi động tác bằng code. Trang bị là mảnh gắn vào đúng xương, nên mua món nào thấy món đó ở mọi động tác mà không lệch. **ChatGPT chỉ vẽ mảnh, không vẽ hoạt ảnh.** Code đã chạy với mảnh tạm (`scripts/battle/hero_rig.gd`, xem thử ở `scenes/rig_lab.tscn`).

## Quy cách chung (quan trọng nhất)

- Vẽ hiệp sĩ hiện tại (`assets/characters/hero_rookie/anim/fresh_idle.png`, khung 0) ở **một dáng đứng chuẩn**: quay phải, thẳng người, hai chân dạng nhẹ, tay khiên hơi đưa ra trước, tay kiếm buông tự nhiên và nắm lại như đang cầm chuôi. Cùng nét, màu, tỉ lệ, mặt, tóc.
- **Mỗi mảnh là một PNG 512×512 RGBA**, nền trong suốt, mảnh nằm **đúng chỗ của nó** trên dáng đứng đó. Chân chạm đất tại (256, 500). Chồng tất cả mảnh lên nhau phải ra nguyên hiệp sĩ.
- **Khớp nối có phần thừa bo tròn** chồng vào mảnh kế bên (vai, khuỷu, cổ tay, hông, gối, cổ chân, cổ), để khi xoay 30–40° không hở khe. Phần thừa nằm dưới mảnh kia nên ở dáng đứng không thấy.
- Không bóng đổ, không viền ngoài chung cho cả người: mỗi mảnh tự có viền.

## Danh sách mảnh: `assets/characters/hero_rig/parts/<tên>.png`

| Tên file | Nội dung |
|---|---|
| `pelvis` | Hông, thắt lưng, phần trên quần |
| `torso` | Thân áo xanh, dây đeo chéo |
| `head` | Đầu, tóc, mặt, cổ |
| `cape` | Khăn choàng đỏ, phần bay sau lưng |
| `shield_arm_upper`, `shield_arm_lower`, `shield_hand` | Tay cầm khiên: bắp tay, cẳng tay, bàn tay |
| `shield` | Khiên tròn |
| `sword_arm_upper`, `sword_arm_lower`, `sword_hand` | Tay cầm kiếm: bắp tay, cẳng tay, nắm tay **không có kiếm** |
| `back_leg_upper`, `back_leg_lower`, `back_foot` | Chân sau: đùi, ống chân, bàn chân (giày vải mỏng) |
| `front_leg_upper`, `front_leg_lower`, `front_foot` | Chân trước: như trên |

**Không vẽ kiếm.** Game dùng sẵn 3 icon kiếm trong `assets/ui/items/` (`wood_sword`, `iron_sword`, `tempered_sword`), cầm ở chuôi.

## Toạ độ khớp: `assets/characters/hero_rig/joints.json`

Toạ độ pixel trên canvas 512 của dáng đứng, đúng tâm xoay của khớp:

```json
{
  "joints": {
    "hip": [x, y], "waist": [x, y], "neck": [x, y], "cape": [x, y],
    "shoulder_shield": [x, y], "elbow_shield": [x, y], "wrist_shield": [x, y], "shield": [x, y],
    "shoulder_sword": [x, y], "elbow_sword": [x, y], "wrist_sword": [x, y], "grip": [x, y],
    "hip_back": [x, y], "knee_back": [x, y], "ankle_back": [x, y],
    "hip_front": [x, y], "knee_front": [x, y], "ankle_front": [x, y]
  },
  "order": ["cape", "back_leg_upper", "back_leg_lower", "back_foot", "sword_arm_upper",
            "pelvis", "front_leg_upper", "front_leg_lower", "front_foot", "torso", "head",
            "sword", "sword_arm_lower", "sword_hand", "shield_arm_upper", "shield_arm_lower",
            "shield_hand", "shield"]
}
```

- `hip` là tâm hông (gốc cả người), `waist` là eo (thân xoay quanh đây), `neck` là gốc cổ, `cape` là chỗ khăn buộc ở vai.
- `shield` là chỗ khiên gắn vào cẳng tay. `grip` là giữa lòng nắm tay kiếm, nơi chuôi kiếm nằm.
- `order` là thứ tự vẽ từ sau ra trước. Sửa nếu dáng vẽ cần khác (ví dụ tay kiếm nằm sau thân).

## Trang bị: `assets/characters/hero_rig/gear/<món>/<mảnh>.png`

Cũng là PNG 512×512, vẽ **chồng đúng lên mảnh nó che**, cùng canvas với mảnh đó (nên tự khớp xương của mảnh, không lệch). Chỉ vẽ phần trang bị, chỗ khác trong suốt.

| Món | Các file |
|---|---|
| `leather_armor`, `iron_armor` | `torso.png` (giáp thân), `shield_arm_upper.png`, `sword_arm_upper.png` (giáp vai), `pelvis.png` (vạt giáp hông, nếu có) |
| `leather_helmet`, `iron_helmet` | `head.png` (nón, không che mặt) |
| `reinforced_boots`, `climbing_boots` | `back_leg_lower.png`, `back_foot.png`, `front_leg_lower.png`, `front_foot.png` (cổ ủng và đế ủng) |

Món da màu nâu, đường khâu; món sắt xám bạc, đinh tán. Khớp kiểu dáng với icon trong `assets/ui/items/`.

## Bàn giao và tự kiểm tra

Trong `docs/ideas/hero_rig_review/`:
- `assembled_bare.png`, `assembled_leather.png`, `assembled_iron.png`: chồng đủ mảnh (và đồ) theo `order`, phải giống hệt hiệp sĩ hiện tại, không khe hở.
- `joints_overlay.png`: dáng ghép có chấm đỏ đánh tên tại mọi khớp.
- `rotation_test.png`: mỗi khớp tay/chân/cổ xoay ±35° quanh toạ độ khớp, chứng minh không hở.
- Kiểm tra kích thước 512×512, RGBA, mảnh không chạm mép canvas.

Đợt đầu chỉ cần mảnh thân + giáp da + nón da + ủng gia cố; đồ sắt làm đợt sau cũng được.
