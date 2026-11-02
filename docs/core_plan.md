# Kế hoạch dựng lõi – Brickbound Hero

Godot 4.7.2, renderer Mobile, khung hình dọc 1080×1920.
Mục tiêu giai đoạn này: **một trận đánh quái chơi được và vui**, chưa có bùa, bản đồ hay lò rèn.

---

## 1. Luật lõi (kiểu lai: khối rơi + ghép màu)

**Bảng chơi**
- 8 cột × 12 hàng, mỗi ô 110 px → bảng 880×1320 ở nửa dưới màn hình. Phía trên 600 px dành cho anh hùng và quái.
- Kích thước để trong một file hằng số, chơi thử rồi chỉnh.

**Khối rơi**
- Gồm 2–4 ô, nhiều hình dạng: thanh 2, thanh 3, chữ L nhỏ, vuông 2×2, chữ L, T, S, thanh 4. Bộ hình không theo đúng 7 khối của Tetris.
- Mỗi ô trong khối mang 1 trong 4 màu: đỏ, xanh lá, vàng, tím. Mỗi khối có tối đa 2 màu để người chơi dễ tính cụm.
- Có ô **Giữ khối** và hiện trước **3 khối tiếp theo**.
- Dùng "túi khối" để không bị ra cùng một hình quá nhiều lần liên tiếp.

**Xóa ô**: sau khi khối chạm đáy, game kiểm tra đồng thời hai điều kiện:
1. **Hàng đầy**: cả hàng bị xóa.
2. **Cụm màu**: 4 ô trở lên cùng màu chạm nhau theo cạnh thì nổ.

**Dây chuyền**: xóa xong, *từng ô* lơ lửng rơi xuống riêng lẻ, không rơi theo cả khối. Rơi xong lại kiểm tra từ đầu. Mỗi vòng nổ thêm thì hệ số dây chuyền tăng x1 → x2 → x3…

**Combo giữa các lần thả**: lần thả nào có xóa ô thì combo +1. Thả một khối mà không xóa gì thì combo về 0.

**Khối đặc biệt**: sinh ra tại vị trí cụm vừa nổ.

| Điều kiện | Khối đặc biệt | Khi bị xóa |
|---|---|---|
| Cụm 5 ô | Sét | Xóa cả hàng và cả cột của nó |
| Cụm từ 6 ô | Bom | Nổ vùng 3×3 |
| Xóa 2 hàng trở lên một lần | Cầu vồng | Xóa hết ô cùng màu với ô bên cạnh |
| 2 khối đặc biệt nổ cạnh nhau | Siêu hiệu ứng | Ví dụ sét + bom = xóa 3 hàng và 3 cột |

Khối đặc biệt nổ có thể kích hoạt khối đặc biệt khác. Đây là nguồn dây chuyền lớn nhất.

**Thua trên bảng**: khối mới không còn chỗ xuất hiện.

**Điều khiển**
- Điện thoại: kéo ngang để di chuyển, chạm để xoay, vuốt xuống để thả nhanh, nút Giữ.
- Máy tính, để thử nhanh: phím mũi tên, Z/X để xoay, Space để thả nhanh, C để giữ.

---

## 2. Từ bảng sang trận đánh

- Mỗi ô bị xóa gây hiệu ứng theo màu:
  - Đỏ: sát thương.
  - Xanh lá: hồi máu.
  - Vàng: vàng.
  - Tím: phá khiên.
- Công thức gốc: `giá trị = số ô × giá trị màu × hệ số dây chuyền × (1 + 0,25 × combo)`. Tất cả hệ số nằm trong file dữ liệu để chỉnh.
- Quái có máu, khiên và đồng hồ đếm ngược theo số khối thả. Hết giờ thì quái tung chiêu, và luôn báo trước 1 lượt bằng biểu tượng trên đầu.
- Quái đầu tiên để thử là **Orc Khiên**: chỉ có khiên dày, đánh thẳng vào máu người chơi.

---

## 3. Kiến trúc code

Nguyên tắc: **phần luật tách khỏi phần hiển thị**. Phần luật là script thuần, không phụ thuộc Node, nên chạy được kiểm thử tự động không cần mở game. Phần hiển thị chỉ nhận sự kiện từ phần luật rồi vẽ và chạy hoạt ảnh.

```
scripts/
  core/            # luật bảng chơi, không dùng Node
    cell.gd          ô: màu, loại đặc biệt, hình phủ (cóc/băng… dùng sau)
    board_rules.gd   mọi con số của bảng: kích thước, ngưỡng cụm, ngưỡng khối đặc biệt
    piece.gd         khối rơi: hình dạng, màu, xoay
    piece_bag.gd     túi khối + hàng chờ 3 khối
    board_model.gd   lưới ô, đặt khối, va chạm
    resolver.gd      tìm hàng đầy + cụm màu, sinh khối đặc biệt, trọng lực, dây chuyền
    clear_step.gd    kết quả mỗi vòng nổ, gửi sang trận đánh và phần hiển thị
    drop_result.gd   tổng kết một lần thả: các vòng nổ + combo
    board_game.gd    một ván: khối trên tay, giữ khối, xoay, thả, combo
  board/           # hiển thị + điều khiển
    board_view.gd    vẽ ô, hoạt ảnh nổ/rơi
    board_input.gd   chạm, vuốt, bàn phím
  battle/
    battle_rules.gd    mọi con số trận đánh (sửa trong data/balance.tres)
    monster_data.gd    một loại quái: máu, khiên, đòn đánh, đồng hồ, bộ gạch
    battle_state.gd    luật trận đánh thuần, không dùng Node: ô xóa → sát thương, lượt quái
    turn_report.gd     kết quả một lần thả, để hiển thị
    battle_view.gd     nền, thanh máu, khiên, đồng hồ, gợi ý, số bay lên; dựng cảnh mỗi lượt
    character_rig.gd   một nhân vật: mức tơi tả theo máu, cảm xúc chớp nhoáng, cảnh kết trận, hiệu ứng
                       (quy cách ảnh: issue #5)
    battle_manager.gd  nối bảng chơi với trận đánh, kết thúc trận
  autoload/
    events.gd        kênh tín hiệu chung
    game_state.gd    vàng, nâng cấp (dùng sau)
data/
  balance.tres     mọi con số cân bằng
  monsters/*.tres  mỗi quái một file Resource
scenes/
  main.tscn, battle.tscn, board.tscn
  forge.tscn, map.tscn  (để trống)
assets/
  tiles/ characters/ monsters/ fx/ ui/ bg/
tests/
  run_tests.gd       chạy tất cả bài kiểm tra
  test_resolver.gd, test_board_game.gd
```

Chạy kiểm tra (đường dẫn Godot trên máy hiện tại):

```bash
~/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tests/run_tests.gd
```

Quái và bùa sau này là file Resource (`.tres`), nên thêm quái mới chủ yếu là thêm dữ liệu và ảnh, ít phải sửa code.

---

## 4. Các bước

| Bước | Nội dung | Xong khi |
|---|---|---|
| **B1** | Luật bảng: khối, túi khối, đặt khối, xóa hàng + cụm, trọng lực, dây chuyền, khối đặc biệt + kiểm tra tự động | Các bài kiểm tra chạy qua, ví dụ "xếp sẵn bảng → thả 1 khối → ra dây chuyền 3 vòng" |
| **B2** | Bảng chơi được với ô màu tạm (hình vuông), điều khiển chạm + bàn phím, Giữ khối, xem trước 3 khối | Mở game, chơi xếp gạch được, thấy chữ "x2, x3" khi dây chuyền |
| **B3** | Cảm giác "đã tay": ô nổ, rơi có nảy, chữ combo bật lên, rung màn hình, âm thanh tạm | Một dây chuyền lớn trông và nghe đã như Candy Crush |
| **B4** | Trận đánh: anh hùng, Orc Khiên, thanh máu và khiên, đồng hồ quái, cảnh báo chiêu, thắng/thua | Đánh hết 1 trận từ đầu đến cuối |
| **B5** | Chơi thử và chỉnh số liệu | Tự thấy muốn chơi thêm trận nữa, rồi mới làm bùa |

B1–B2 chạy được với hình tạm, nên không cần đợi ảnh thật.

---

## 5. Chia việc với ChatGPT Plus

Để tránh hai AI sửa đè lên cùng một file code:
- **Claude (ở đây)**: toàn bộ code và scene trong dự án.
- **ChatGPT**: ảnh, ý tưởng và chữ.

Ảnh xong thì bạn thả vào đúng thư mục bên dưới, đúng tên file. Code sẽ tự dùng ảnh thật thay cho hình tạm.

**Việc cho ChatGPT, theo thứ tự cần dùng**

1. **Ô gạch 4 màu**: đỏ, xanh lá, vàng, tím, PNG nền trong suốt, 128×128.
   → `assets/tiles/tile_red.png`, `tile_green.png`, `tile_yellow.png`, `tile_purple.png`.
   Yêu cầu: hình dạng khác nhau theo màu (ví dụ đỏ có biểu tượng kiếm, xanh hình lá, vàng hình đồng xu, tím hình pha lê) để người mù màu vẫn phân biệt được.
2. **Khối đặc biệt**: sét, bom, cầu vồng, 128×128.
   → `assets/tiles/special_lightning.png`, `special_bomb.png`, `special_rainbow.png`.
3. **Anh hùng**: đứng, tấn công, bị đánh, 512×512, quay mặt sang phải.
   → `assets/characters/hero_idle.png`, `hero_attack.png`, `hero_hurt.png`.
4. **Orc Khiên**: đứng, bị đánh, tung chiêu, 512×512, quay mặt sang trái, cùng phong cách và tỉ lệ với anh hùng.
   → `assets/monsters/orc_shield_idle.png`, `orc_shield_hurt.png`, `orc_shield_attack.png`.
5. **Nền trận đánh**: 1080×600.
   → `assets/bg/battle_forest.png`.
6. **Biểu tượng giao diện**: khiên, trái tim, đồng hồ, cảnh báo, 96×96.
   → `assets/ui/`.
7. **Ngoài ảnh**: nghĩ tên và mô tả cho 8 bùa đầu tiên, viết đoạn mở đầu ngắn cho cốt truyện cứu công chúa.

Khi tạo ảnh, luôn dán style guide trước, và đính kèm ảnh anh hùng đã chốt để các nhân vật cùng phong cách.

---

## 6. Còn để ngỏ, chốt khi chơi thử

- Bảng 8×12 có quá chật hay quá rộng trên điện thoại không.
- Cụm nổ từ 4 hay từ 3 ô. Mặc định 4; nếu ít nổ quá thì một bùa có thể hạ xuống 3.
- Khối rơi tự động theo thời gian hay chỉ rơi khi người chơi thả. Đề xuất: **không tự rơi**, để người chơi có thời gian suy nghĩ và tính dây chuyền, hợp với game đánh theo lượt. Có thể thêm chế độ tự rơi sau.
