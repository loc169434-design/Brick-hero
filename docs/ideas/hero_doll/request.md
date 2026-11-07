# Yêu cầu cho ChatGPT: vẽ lại hiệp sĩ thành bộ mảnh búp bê

Claude viết. Làm trên nhánh `art/hero-doll` tạo từ `origin/core/world-life`. Chỉ thêm file vào `assets/characters/hero_doll/` và `docs/ideas/hero_doll/`. Không sửa `assets/characters/hero_rig/` (game đang dùng) và không động vào `scripts/`, `scenes/`, `tests/`. Chỉ push nhánh này, không force push.

## Vì sao làm lại

Bộ `hero_rig/` hiện tại được **cắt ra từ một bức vẽ phẳng**. Chỗ nào bị che thì không được vẽ. Vì vậy khi xoay khớp thì lộ ra mép cắt nham nhở: nắm tay khoét lỗ, khiên bị mẻ, đầu ghép dính cổ lởm chởm, ống tay áo dính vào thân. Ảnh `current_defects.png` cho thấy các lỗi đó.

Lần này vẽ như **búp bê khớp tròn**. Mỗi mảnh là một hình **vẽ trọn vẹn**, có viền khép kín, không có mép nào bị cắt. Khớp nào cũng có đầu tròn chồng lên mảnh bên cạnh, nên xoay đến đâu cũng không hở.

## Bước 1: vẽ một tấm "bảng mảnh"

Vẽ trong **một lần sinh ảnh duy nhất** một tấm có đủ 17 mảnh rời, xếp cách nhau ít nhất 12 px trên nền trong suốt (hoặc nền trơn một màu rồi tách). Vẽ cả bộ trong một ảnh để nét, màu và tỉ lệ đồng đều. Lưu ảnh gốc vào `docs/ideas/hero_doll/sheet.png`.

Nhân vật vẫn là hiệp sĩ hiện tại: chibi, tóc nâu bù xù, áo xanh, khăn đỏ, thắt lưng da khóa vàng, quần nâu, ủng nâu, khiên tròn gỗ viền sắt. Tham chiếu: `reference.png`, ngoài ra có `assets/characters/hero_rookie/anim/fresh_idle.png` khung 0. Giữ đúng nét (viền nâu đậm khoảng 4 px trên canvas 512), cách tô bóng và tỉ lệ.

| Mảnh (tên file) | Vẽ trọn vẹn những gì | Đầu khớp tròn ở |
|---|---|---|
| `torso` | Thân áo, **khăn quàng quấn cổ và nút khăn**, đủ hai vai, dây đeo chéo, hông áo. Vẽ cả hai bên sườn dưới nách (phần thường bị tay che). Có "hốc cổ" để cổ cắm vào. | cổ, eo |
| `head` | Đầu, tóc, tai **và cổ**. Cổ kéo dài xuống khoảng 18 px dưới mép khăn, phần này nằm khuất dưới khăn. Mặt để trống (da trơn trong vùng mặt), xem bước 3. | gốc cổ |
| `cape` | Chỉ phần áo choàng bay phía sau lưng, gốc tròn gắn ở vai trái. Không vẽ khăn quấn cổ vào mảnh này. | gốc ở `cape` |
| `pelvis` | Hông, thắt lưng, khóa vàng, đáy quần. Vẽ kín cả phần giữa hai đùi. | eo, hai hông |
| `sword_arm_upper` | Tay áo ngắn, viền kem, bắp tay tới khuỷu. **Vai tròn**. | vai, khuỷu |
| `sword_arm_lower` | Cẳng tay và bao tay da. | khuỷu, cổ tay |
| `sword_hand` | Nắm tay cầm kiếm, xem bước 2. | cổ tay |
| `shield_arm_upper`, `shield_arm_lower`, `shield_hand` | Như tay kiếm, ở phía cầm khiên. | như trên |
| `shield` | Khiên **tròn nguyên vẹn**, viền sắt liền, đinh tán đều, không mẻ. | chỗ gắn `shield` |
| `back_leg_upper`, `back_leg_lower`, `back_foot` | Đùi, ống chân, bàn chân có ủng (chân sau). | hông, gối, cổ chân |
| `front_leg_upper`, `front_leg_lower`, `front_foot` | Như trên (chân trước). | như trên |

**Không vẽ kiếm.** Game lấy icon kiếm có sẵn trong `assets/ui/items/` gắn vào nắm tay.

**Quy tắc đầu khớp:** ở mỗi khớp, mảnh nằm dưới (theo thứ tự vẽ ở bước 3) có đầu tròn bán kính bằng nửa bề ngang chi tại đó, tâm đúng điểm khớp, kéo dài dưới mảnh nằm trên. Mảnh nằm trên cũng kết thúc bằng một đường viền cong khép kín. Không mảnh nào có cạnh thẳng hay mép cắt.

## Bước 2: nắm tay cầm kiếm

`sword_hand` là nắm tay cuộn tròn, có **rãnh chuôi thẳng đứng** đi xuyên qua giữa. Kiếm được vẽ phía sau nắm tay, lưỡi dựng thẳng lên.

- Tâm rãnh trùng điểm `grip`.
- Rãnh rộng 30 px: chuôi các icon kiếm khi cầm rộng khoảng 28 px.
- Nắm tay cao 38–44 px, để đốc chắn kiếm nằm ngay trên nắm tay và quả chuôi ló ngay dưới.

Game cầm icon theo số liệu này: với mỗi kiếm `wood_sword`, `iron_sword`, `tempered_sword`, điểm `grip` lần lượt là (68,197), (127,200), (128,203) trên icon 256. Icon được xoay `turn` −40.9°, −0.2°, −0.3°, rồi thu phóng `210/256 × size` với `size` là 0.77, 1, 1. Kiểm tra bằng cách ghép thử cả 3 kiếm (bước 4).

## Bước 3: đặt mảnh lên khung và đo khớp

- Mỗi mảnh là một PNG **512×512 RGBA** nền trong suốt, mảnh nằm **đúng chỗ của nó trong dáng đứng**, chân chạm đất tại (256, 500), cùng kích cỡ với `reference.png`. Chồng các mảnh theo thứ tự vẽ phải ra nguyên hiệp sĩ đứng.
- Giữ các khớp gần đúng vị trí hiện tại (`reference_joints.png`, `assets/characters/hero_rig/joints.json`), lệch không quá 6 px. Như vậy code và các động tác không phải sửa.
- Thứ tự vẽ, từ sau ra trước: `cape, back_leg_upper, back_leg_lower, back_foot, pelvis, front_leg_upper, front_leg_lower, front_foot, torso, sword_arm_upper, head, sword, sword_arm_lower, sword_hand, shield_arm_upper, shield_arm_lower, shield_hand, shield`
- Ghi `assets/characters/hero_doll/joints.json` cùng định dạng với file hiện tại (gồm `joints` và `order`), đo đúng trên bộ mảnh mới. Điểm khớp nằm ở **tâm đầu tròn**.

Đường dẫn:
- `assets/characters/hero_doll/parts/<mảnh>.png` cho 16 mảnh thân.
- `assets/characters/hero_doll/head/bare.png`.
- `assets/characters/hero_doll/faces/{normal,blink,angry,hurt,happy,scared}.png`: miếng mặt đặc (alpha 255) nằm trong một khung mặt cố định, giống cách làm ở `docs/ideas/hero_head_v3/` (mép 3 px trùng màu da của `head/bare.png`). Lấy biểu cảm từ `docs/ideas/hero_rig_v2/inputs/head_<biểu_cảm>_edit.png`, rồi căn cho khớp đầu mới.

Đợt này **chưa làm** nón, giáp, ủng. Thân mới được duyệt rồi mới vẽ đồ cho khớp.

## Bước 4: tự kiểm tra

Viết `docs/ideas/hero_doll/check_doll.py`. Chạy sau mỗi lần sửa, tối đa 6 vòng, ghi số đo từng vòng vào `rounds.md`. Phải đạt hết:

1. **Định dạng:** đủ file, 512×512 RGBA, không mảnh nào chạm mép canvas.
2. **Mảnh liền:** mỗi mảnh là đúng một vùng liền (alpha ≥ 128), không có lỗ bên trong.
3. **Viền khép kín:** mọi điểm trên mép ngoài của mảnh đều cách một điểm mực (kênh sáng nhất < 80) không quá 2 px. Tức là không còn mép cắt trơ.
4. **Không bụi:** không có điểm alpha 1–63 nào nằm tách khỏi điểm alpha ≥ 200.
5. **Đúng dáng:** ghép đủ mảnh ở dáng đứng thì trùng hình bóng `reference.png` ≥ 90% (IoU của alpha ≥ 128).
6. **Không hở khi xoay:** dựng cây xương theo `order` và `joints` (con xoay theo cha). Xoay lần lượt từng khớp −40° và +40° (riêng `head` ±25°, `torso` ±20°) quanh điểm khớp, ghép lại. Trong bán kính 24 px quanh khớp đó, số điểm trong suốt nằm bên trong hình bao lồi của hình ghép phải bằng 0.
7. **Khiên tròn:** alpha của `shield` phủ ≥ 97% hình tròn khớp nhất với nó và không có vết khuyết sâu quá 2 px.
8. **Kiếm vừa tay:** ghép cả 3 kiếm theo số liệu ở bước 2. Tâm rãnh nắm tay lệch `grip` ≤ 2 px. Phần chuôi giữa đốc chắn và quả chuôi bị nắm tay che ≥ 90%. Đốc chắn chạm hoặc cách mép trên nắm tay ≤ 3 px.
9. **Mặt:** 6 miếng mặt nằm gọn trong khung mặt và phủ kín 100%. Mép 3 px lệch màu so với da bên dưới ≤ 10/255.

## Bàn giao trong `docs/ideas/hero_doll/`

- `sheet.png`: tấm bảng mảnh gốc.
- `assembled.png`: ghép đứng trên nền sáng và nền tối.
- `rotate_test.png`: mỗi khớp ±40°, khoanh đỏ chỗ hở nếu có.
- `sword_test.png`: 3 kiếm trong tay, phóng to ×3.
- `faces.png`: 6 biểu cảm trên đầu mới.
- `check.json`, `rounds.md`, `check_doll.py`.

Commit, push `art/hero-doll`, rồi báo số đo cuối.
