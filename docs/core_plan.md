# Kế hoạch dựng lõi – Brickbound Hero

Godot 4.7.2, renderer Mobile, khung hình dọc 1080×1920.
Mục tiêu giai đoạn này: **một trận đánh quái chơi được và vui**, chưa có bùa, bản đồ hay lò rèn.

---

## 1. Luật lõi (nối ô, đánh theo lượt)

Đổi từ khối rơi sang nối ô ngày 2026-11-02, vì người chơi thấy kéo tay nối combo đã hơn. Bản khối rơi vẫn còn trong lịch sử git (PR #1, #2).

**Bảng chơi**
- 7 cột × 8 hàng, mỗi ô 140 px, **luôn đầy**. Phía trên là khu trận đánh.
- Khi chia bảng, không có sẵn hàng 3 nào, và luôn có ít nhất một nước nối. Nếu sau một lượt không còn nước nối nào thì chia lại bảng ("XÁO BẢNG").
- Kích thước và các ngưỡng nằm trong `BoardRules`.

**Một lượt = một lần nối**
- Đặt ngón tay lên một ô, vuốt qua các ô **cùng màu nằm cạnh nhau, chỉ ngang hoặc dọc** (không đi chéo), rồi thả tay.
- Cần từ **3 ô** trở lên. Kéo lùi lại ô trước thì bỏ ô vừa nối.
- Các ô trong đường nối nổ. Ô phía trên rơi xuống, ô mới rơi từ trên vào lấp đầy bảng.

**Dây chuyền**: sau khi rơi, hàng thẳng **3 ô cùng màu** trở lên (ngang hoặc dọc) tự nổ, rồi lại rơi và lấp đầy. Mỗi vòng nổ thêm thì hệ số dây chuyền tăng x1 → x2 → x3…

**Ô đặc biệt**: nối dài thì sinh ô đặc biệt ngay tại ô cuối cùng, chỗ ngón tay thả ra.

| Nối | Ô đặc biệt | Khi nổ |
|---|---|---|
| 5 ô | Sét (giữ màu đường nối) | Xóa cả hàng và cả cột |
| 6 ô | Bom (giữ màu đường nối) | Nổ vùng 3×3 |
| 7 ô trở lên | Sao | Ghép được với **mọi màu** khi người chơi nối. Khi nổ thì xóa hết ô cùng màu với đường nối. |
| 2 ô đặc biệt cạnh nhau | Siêu hiệu ứng | Ví dụ sét + bom: xóa 3 hàng và 3 cột |

- Nối đi qua ô đặc biệt thì kích nổ nó. Hàng 3 tự nổ có chứa sét hoặc bom cũng kích nổ chúng.
- Sao **không** tự ghép vào hàng 3 khi các ô rơi xuống: sao chỉ dành cho người chơi tự nối.

**Thua**: chỉ khi máu hiệp sĩ về 0 (bảng luôn đầy nên không có thua vì đầy bảng).

**Điều khiển**: chạm hoặc chuột để nối. Phím R chơi lại, T đổi bộ gạch (để thử).

---

## 2. Từ bảng sang trận đánh

- Mỗi ô bị xóa gây hiệu ứng theo màu:
  - Đỏ: sát thương.
  - Xanh lá: hồi máu.
  - Vàng: vàng.
  - Tím: phá khiên.
- Công thức gốc: `giá trị = số ô × giá trị màu × hệ số dây chuyền`. Tất cả hệ số nằm trong `data/balance.tres` để chỉnh.
- Quái có máu, khiên và đồng hồ đếm ngược theo số lượt nối. Hết giờ thì quái tung chiêu, và luôn báo trước 1 lượt.
- Trận đầu là **bù nhìn bãi tập** (không đánh lại, có gợi ý hướng dẫn), sau đó tới **Orc Khiên**.

---

## 3. Kiến trúc code

Nguyên tắc: **phần luật tách khỏi phần hiển thị**. Phần luật là script thuần, không phụ thuộc Node, nên chạy được kiểm thử tự động không cần mở game. Phần hiển thị chỉ nhận sự kiện từ phần luật rồi vẽ và chạy hoạt ảnh.

```
scripts/
  core/            # luật bảng chơi, không dùng Node
    cell.gd          ô: màu, loại đặc biệt, hình phủ (cóc/băng… dùng sau)
    board_rules.gd   mọi con số của bảng: kích thước, độ dài nối, ngưỡng ô đặc biệt
    board_model.gd   lưới ô
    link_game.gd     một ván: chia bảng, kiểm tra đường nối, chơi một lượt, xáo bảng
    resolver.gd      nổ đường nối, kích ô đặc biệt, rơi + lấp ô mới, hàng 3 tự nổ, dây chuyền
    clear_step.gd    kết quả mỗi vòng nổ, gửi sang trận đánh và phần hiển thị
    move_result.gd   tổng kết một lượt: đường nối + các vòng nổ
  board/           # hiển thị + điều khiển
    board_view.gd    vẽ ô, đường nối đang vuốt, hoạt ảnh nổ/rơi
    board_input.gd   chạm/chuột để nối, phím R/T
    tile_art.gd      nạp ảnh gạch và hoạt ảnh theo bộ
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
  test_resolver.gd, test_link_game.gd, test_tile_art.gd, test_battle_state.gd
```

Chạy kiểm tra (đường dẫn Godot trên máy hiện tại):

```bash
~/Downloads/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tests/run_tests.gd
```

Quái và bùa sau này là file Resource (`.tres`), nên thêm quái mới chủ yếu là thêm dữ liệu và ảnh, ít phải sửa code.

---

## 4. Các bước

| Bước | Nội dung | Trạng thái |
|---|---|---|
| **B1** | Luật bảng + kiểm tra tự động | Xong (bản khối rơi, PR #1), làm lại sang nối ô |
| **B2** | Bảng chơi được + ghép ảnh gạch Training/Orc | Xong (PR #2), làm lại sang nối ô |
| **B4** | Trận đánh: hiệp sĩ, quái, máu, khiên, đồng hồ, thắng/thua | Xong (PR #4, #6) |
| **Nối ô** | Bảng luôn đầy, vuốt nối, hàng 3 tự nổ, ô đặc biệt theo độ dài nối | PR này |
| **B3** | Cảm giác "đã tay": rung màn hình, âm thanh, chữ nảy | Chưa làm |
| **B5** | Chơi thử và chỉnh số liệu | Chưa làm. Tự thấy muốn chơi thêm trận nữa thì mới làm bùa. |

---

## 5. Chia việc với ChatGPT Plus

Để tránh hai AI sửa đè lên cùng một file code:
- **Claude**: toàn bộ code và scene. Đặt việc cho ChatGPT bằng GitHub issue.
- **ChatGPT**: ảnh, ý tưởng và chữ, làm trên nhánh `art/...`.

Đã xong: gạch Training/Orc kèm hoạt ảnh, ô đặc biệt (issue #3). Đang làm: nhân vật, nền, hiệu ứng trận đánh (issue #5, quy cách tên file nằm trong đó).

---

## 6. Còn để ngỏ, chốt khi chơi thử

- Bảng 7×8 vừa tay trên điện thoại chưa. Bốn màu có làm nối quá dễ hay quá khó không.
- Ngưỡng ô đặc biệt 5/6/7 có hợp lý không.
- Hàng 3 tự nổ sau khi rơi có xảy ra quá nhiều (game tự chơi hộ) hay quá ít không.
