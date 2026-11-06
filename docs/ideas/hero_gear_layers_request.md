# Yêu cầu cho ChatGPT: hiệp sĩ đổi ngoại hình theo từng món trang bị, và ảnh cho tính năng mới

Claude viết, gửi ChatGPT. Làm trên nhánh `art/gear-layers` (phần 1) và `art/new-features` (phần 2), chỉ sửa `assets/` và `docs/ideas/`. Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`. Code ghép đã có sẵn, ảnh đặt đúng chỗ là game tự dùng.

Thay cho phần 2 của issue #30 (chỉ đổi kiếm và nón). Người chơi muốn **mua món nào thấy món đó trên người hiệp sĩ, rõ ràng, không lệch**.

## Phần 1. Hiệp sĩ vẽ theo lớp

### Vì sao phải tách lớp

Hiện mỗi khung hoạt ảnh vẽ liền kiếm, áo, ủng vào người, nên đổi một món phải vẽ lại cả bộ, và ghép ảnh món đồ lên sau thì lệch tay, lệch đầu. Game khác làm được vì họ **vẽ từng món thành một lớp riêng, trên đúng lưới khung của hoạt ảnh**: khung 7 của lớp kiếm được vẽ đè lên đúng khung 7 của thân. Code chỉ chồng các lớp, không dịch, không xoay, nên không thể lệch.

### Quy cách

Thư mục `assets/characters/hero_rookie/anim/layers/`, mỗi lớp một thư mục con:

| Thư mục | Nội dung |
|---|---|
| `body/` | Hiệp sĩ **trần**: áo vải thường, quần, tóc, mặt, tay trống (vẫn nắm như đang cầm chuôi), **không** kiếm, giáp, nón, ủng (chân đi giày vải mỏng). Khiên tròn giữ nguyên trong `body` |
| `wood_sword/`, `iron_sword/`, `tempered_sword/` | Chỉ thanh kiếm, đúng vị trí bàn tay từng khung |
| `leather_armor/`, `iron_armor/` | Chỉ giáp, ôm theo thân từng khung |
| `leather_helmet/`, `iron_helmet/` | Chỉ nón, theo đầu từng khung |
| `reinforced_boots/`, `climbing_boots/` | Chỉ ủng, theo chân từng khung |
| `<món>_back/` (tuỳ chọn) | Phần của món nằm **sau** thân ở vài khung (lưỡi kiếm khi vung ra sau lưng). Khung nào không có thì để trong suốt. Không có thư mục này cũng được |

- Tên file **giống hệt** hoạt ảnh hiện có: `<mức>_<clip>.png`, `<mức>` là `fresh`, `bruised`, `battered`. Ví dụ `layers/iron_sword/fresh_attack.png`.
- **Cùng lưới** với file hiện có: 4 cột, ô 512×512, cùng số khung, cùng điểm neo chân (256,500), RGBA, phần không có món thì trong suốt. Ghép `body` + các món phải ra hình y như một khung vẽ liền, không hở viền, không lem.
- Code vẽ theo thứ tự: các lớp `_back` → `body` → ủng → giáp → nón → kiếm. Món che món khác (giáp che thắt lưng của thân) thì vẽ phần che trong lớp món đó.
- Mức `bruised`/`battered`: thân bầm, áo rách như hiện tại. Lớp món của mức đó có thể sứt mẻ (kiếm gỗ gãy ở `battered` như quy ước #24). Món nào không cần khác giữa các mức thì chỉ vẽ `fresh_<clip>.png`, code tự dùng lại cho mức khác.
- Code chỉ bật chế độ lớp cho clip nào **có file `body`**. Clip chưa có lớp vẫn chạy hình vẽ liền như cũ, nên có thể giao dần.

### Thứ tự giao (mỗi đợt chơi được ngay)

1. `idle`, `attack` (đủ 3 mức) cho `body` + 3 kiếm + 2 giáp + 2 nón + 2 ủng. Đây là 2 clip nhìn thấy nhiều nhất, duyệt hình ở đợt này.
2. `hurt`, `cheer`, `victory`, `defeat`, `throw`, `kick`, `bash`, `leap`.
3. Các clip còn lại: `drink`, `dizzy`, `knocked`, `scared`, `run`.

Mỗi đợt kèm GIF duyệt: cùng một clip với 3 bộ đồ (không đồ / đồ da / đồ sắt) và lưới khung đánh số chồng lớp, để soi lệch.

### Rèn kiếm +1/+2/+3

Không vẽ thêm kiếm. Code đã biết cấp rèn (`Gear.outfit()["refine"]`, 0–3) nhưng chưa đổi hình. Đề xuất giao thêm `layers/sword_glow/<mức>_<clip>.png`: vệt sáng trắng trên lưỡi, cùng lưới; Claude sẽ ghép và tô màu theo cấp sau khi có ảnh.

## Phần 2. Ảnh cho tính năng mới (đã chạy trong game bằng hình vẽ tạm)

| Đường dẫn | Quy cách | Ghi chú |
|---|---|---|
| `assets/tiles/specials/rocket.png` | 128×128, nền trong suốt, như `bomb.png` | **Tên lửa**: ô đặc biệt mới, sinh ra khi nối khép kín ô vuông 2×2. Thân trắng, mũi đỏ, cánh đỏ, lửa đuôi. Không mang màu ô |
| `assets/tiles/specials/rocket_idle.png` | Dải 8 khung 128 px, như `lightning_idle.png`; thêm dòng vào `specials.json` | Rung nhẹ, lửa đuôi phập phồng, lặp |
| `assets/ui/boosters/hammer.png`, `shuffle.png`, `potion.png`, `opening_bombs.png` | 256×256, viền nâu đậm như icon trang bị | Búa, Xáo bảng, Bình máu, Bom mở màn. Hiện trên nút trong trận và trên kệ lò rèn |
| `assets/ui/skill_thunder_slash.png`, `skill_iron_guard.png`, `skill_blade_vortex.png`, `skill_starfall_strike.png` | Như `skill_armor_breaker.png` | Nút 4 tuyệt chiêu mới |
| `assets/fx/comic/thunder_slash.png`, `iron_guard.png`, `blade_vortex.png`, `starfall.png` | 512×320 như các chữ comic khác | Chữ tiếng Anh: THUNDER SLASH!, IRON GUARD!, BLADE VORTEX!, STARFALL! |
| `assets/ui/status/guard.png` | Như `poison.png` | Biểu tượng Hộ Thể cạnh thanh máu |

Clip tuyệt chiêu của hiệp sĩ vẫn theo [skills_art_request.md](skills_art_request.md). Nếu làm phần 1 trước thì clip tuyệt chiêu vẽ luôn theo lớp.
