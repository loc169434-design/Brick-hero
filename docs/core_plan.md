# Kế hoạch dựng lõi – Brickbound Hero

> Phần lõi trận đánh đã xong. Kế hoạch tiếp theo (bản đồ, các vùng đất, trùm, lò rèn, truyện tranh, giải đố) nằm ở [world_plan.md](world_plan.md).

Godot 4.7.2, renderer Mobile, khung hình dọc 1080×1920.
Mục tiêu giai đoạn này: **một trận đánh quái chơi được và vui**, chưa có bùa, bản đồ hay lò rèn.

---

## 1. Luật lõi (nối ô, đánh theo lượt)

Đổi từ khối rơi sang nối ô ngày 2026-11-02, vì người chơi thấy kéo tay nối combo đã hơn. Bản khối rơi vẫn còn trong lịch sử git (PR #1, #2).

**Bảng chơi**
- 7 cột × 8 hàng, mỗi ô 140 px, **luôn đầy**. Phía trên là khu trận đánh.
- Khi chia bảng, không có sẵn hàng 4 nào, và luôn có ít nhất một nước nối. Nếu sau một lượt không còn nước nối nào thì chia lại bảng ("XÁO BẢNG").
- Kích thước và các ngưỡng nằm trong `BoardRules`.

**Một lượt = một lần nối**
- Đặt ngón tay lên một ô, vuốt qua các ô **cùng màu nằm cạnh nhau, chỉ ngang hoặc dọc** (không đi chéo), rồi thả tay.
- Cần từ **3 ô** trở lên. Kéo lùi lại ô trước thì bỏ ô vừa nối.
- Các ô trong đường nối nổ. Ô phía trên rơi xuống, ô mới rơi từ trên vào lấp đầy bảng.

**Dây chuyền**: sau khi rơi, hàng thẳng **4 ô cùng màu** trở lên (ngang hoặc dọc) tự nổ, rồi lại rơi và lấp đầy. Mỗi vòng nổ thêm thì hệ số dây chuyền tăng x1 → x2 → x3…
Trước là hàng 3, đổi sang hàng 4 ngày 2026-11-02 sau khi mô phỏng cho thấy hàng 3 làm game tự chơi (mục 6).

**Ô đặc biệt**: nối dài thì sinh ô đặc biệt ngay tại ô cuối cùng, chỗ ngón tay thả ra.

| Nối | Ô đặc biệt | Khi nổ |
|---|---|---|
| 5 ô | Sét (giữ màu đường nối) | Xóa cả hàng và cả cột |
| 6 ô | Bom (giữ màu đường nối) | Nổ vùng 3×3 |
| 7 ô trở lên | Sao | Ghép được với **mọi màu** khi người chơi nối. Khi nổ thì xóa hết ô cùng màu với đường nối. |
| 2 ô đặc biệt cạnh nhau | Siêu hiệu ứng | Ví dụ sét + bom: xóa 3 hàng và 3 cột |

- Nối đi qua ô đặc biệt thì kích nổ nó. Hàng tự nổ có chứa sét hoặc bom cũng kích nổ chúng.
- Sao **không** tự ghép vào hàng tự nổ khi các ô rơi xuống: sao chỉ dành cho người chơi tự nối.

**Thua**: chỉ khi máu hiệp sĩ về 0 (bảng luôn đầy nên không có thua vì đầy bảng).

**Điều khiển**: chạm hoặc chuột để nối. Phím R chơi lại, T đổi bộ gạch (để thử), M tắt/bật tiếng.

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
    resolver.gd      nổ đường nối, kích ô đặc biệt, rơi + lấp ô mới, hàng 4 tự nổ, dây chuyền
    clear_step.gd    kết quả mỗi vòng nổ, gửi sang trận đánh và phần hiển thị
    move_result.gd   tổng kết một lượt: đường nối + các vòng nổ
  board/           # hiển thị + điều khiển
    board_view.gd    vẽ ô, đường nối đang vuốt, hoạt ảnh nổ/rơi
    board_input.gd   chạm/chuột để nối, phím R/T/M
    tile_art.gd      nạp ảnh gạch và hoạt ảnh theo bộ
    special_fx.gd    hiệu ứng nổ sét, bom, sao, hai ô đặc biệt nổ chung
  battle/
    battle_rules.gd    mọi con số trận đánh (sửa trong data/balance.tres)
    monster_data.gd    một loại quái: máu, khiên, đòn đánh, đồng hồ, bộ gạch
    battle_state.gd    luật trận đánh thuần, không dùng Node: ô xóa → sát thương, lượt quái
    turn_report.gd     kết quả một lần thả, để hiển thị
    battle_view.gd     nền, thanh máu, khiên, đồng hồ, gợi ý, số bay lên; dựng cảnh mỗi lượt
    character_rig.gd   một nhân vật: mức tơi tả theo máu, cảm xúc chớp nhoáng, cảnh kết trận, hiệu ứng
                       (quy cách ảnh: issue #5)
    battle_manager.gd  nối bảng chơi với trận đánh, phản ứng của gạch quái, kết thúc trận
  feel/            # cảm giác "đã tay"
    screen_feel.gd   camera: rung màn hình theo lực va chạm, ngừng hình, rung điện thoại
    sfx.gd           Sfx.play(&"tên"): phát âm thanh từ bất cứ đâu, M tắt tiếng
    sfx_bank.gd      âm thanh tổng hợp bằng code, dùng tạm tới khi có file thật
  autoload/        (dùng sau)
    events.gd        kênh tín hiệu chung
    game_state.gd    vàng, nâng cấp
data/
  balance.tres     mọi con số cân bằng
  monsters/*.tres  mỗi quái một file Resource
scenes/
  main.tscn, battle.tscn, board.tscn
  forge.tscn, map.tscn  (để trống)
assets/
  tiles/ characters/ monsters/ fx/ ui/ bg/ audio/
tests/
  run_tests.gd       chạy tất cả bài kiểm tra
  test_resolver.gd, test_link_game.gd, test_tile_art.gd, test_battle_state.gd, test_feel.gd,
  test_battle_sim.gd
  sim_balance.gd     mô phỏng hàng trăm trận bằng bot, in bảng số liệu (B5)
```

`scripts/sim/battle_sim.gd` là bot chơi trên luật thật, có ba kiểu: ngẫu nhiên, luôn nối dài nhất, và chơi khôn (ưu tiên màu đang cần).

Chạy kiểm tra (đường dẫn Godot trên máy Windows hiện tại):

```bash
~/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/run_tests.gd
```

Chạy mô phỏng cân bằng. Thử số liệu khác mà không cần sửa file, bằng cách thêm `--<tên luật>=<giá trị>` (luật trong `BattleRules`/`BoardRules`) hoặc `--monster.<thuộc tính>=<giá trị>`:

```bash
~/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/sim_balance.gd -- --fights=300 --monster=orc_shield --min_line=4
```

**Âm thanh**: mỗi âm có một tên. Đặt file `assets/audio/<tên>.wav` (hoặc `.ogg`) thì game tự dùng file đó thay cho âm tổng hợp, không cần sửa code. Danh sách tên nằm trong `RECIPES` của `scripts/feel/sfx_bank.gd`: `tick` (mỗi ô nối thêm), `untick`, `charge` (nối đủ dài để ra ô đặc biệt), `pop` (một vòng nổ), `land`, `boom` (sét/bom nổ), `special` (ô đặc biệt xuất hiện), `shuffle`, `hit` (hiệp sĩ đánh trúng), `clang` (đánh vào khiên), `shatter` (vỡ một lớp khiên), `heal`, `coin`, `thud` (quái đánh trúng), `warn` (quái sắp đánh), `win`, `lose`.

Quái và bùa sau này là file Resource (`.tres`), nên thêm quái mới chủ yếu là thêm dữ liệu và ảnh, ít phải sửa code.

---

## 4. Các bước

| Bước | Nội dung | Trạng thái |
|---|---|---|
| **B1** | Luật bảng + kiểm tra tự động | Xong (bản khối rơi PR #1, làm lại sang nối ô ở PR #7) |
| **B2** | Bảng chơi được + ghép ảnh gạch Training/Orc | Xong (PR #2, làm lại sang nối ô ở PR #7) |
| **B4** | Trận đánh: hiệp sĩ, quái, máu, khiên, đồng hồ, thắng/thua | Xong (PR #4, #6). Ảnh nhân vật, nền, hiệu ứng thật ở PR #8 |
| **Nối ô** | Bảng luôn đầy, vuốt nối, hàng tự nổ, ô đặc biệt theo độ dài nối | Xong (PR #7) |
| **B3** | Cảm giác "đã tay": rung màn hình, âm thanh, chữ nảy | Xong (PR #11). Âm thanh đang là âm tổng hợp, chờ file thật |
| **Đánh nhau có hồn** | Bảng sáng, nền đấu trường chuyển động, ô gạch "thở" và bắn hạt sáng lên trận; thế võ theo đường nối (chém, ném kiếm, nhảy đập, combo, húc khiên), Orc chọi đá/quăng chùy/húc và né cười gian, cục u, chữ truyện tranh tiếng Anh; chí mạng (ô chí mạng, 5% may mắn, Orc chí mạng mỗi 3 đòn có báo trước) | PR #20 (ảnh: issue #17, #18, #19), khán giả reo hò và la ó |
| **B5** | Chơi thử và chỉnh số liệu | Đang làm (nhánh `core/balance-sim`). Bot mô phỏng và số đo ở mục 6. Đã chốt: hàng 4 tự nổ, Orc 60 máu, đánh 12 mỗi 3 lượt. Còn chơi thử trên điện thoại. Tự thấy muốn chơi thêm trận nữa thì mới làm bùa. |

B3 gồm:
- Rung màn hình theo lực: nối dài, dây chuyền, ô đặc biệt nổ, hiệp sĩ đánh trúng, quái đánh trả. Ngừng hình vài khung khi vỡ khiên, kích ô đặc biệt và đòn kết liễu. Rung điện thoại khi va chạm mạnh (bản Android cần quyền VIBRATE khi tạo cấu hình xuất).
- Âm thanh cho mọi sự kiện. Mỗi ô nối thêm phát một nốt cao dần theo thang ngũ cung.
- Chữ "CHUỖI xN" và "NỐI N!" nảy vào kèm viền, dây chuyền càng dài chữ càng to. Số sát thương nảy lên, đòn càng mạnh số càng to.
- Thanh máu tụt có vệt nhạt chạy theo sau. Đồng hồ của quái đập nhịp khi quái sắp đánh.
- Gạch Orc chế giễu khi lượt không gây sát thương, toát mồ hôi thoát chết khi Orc còn dưới 15% máu (`near_miss`), cười đắc thắng khi hiệp sĩ sắp thua.

---

## 5. Chia việc với ChatGPT Plus

Để tránh hai AI sửa đè lên cùng một file code:
- **Claude**: toàn bộ code và scene. Đặt việc cho ChatGPT bằng GitHub issue.
- **ChatGPT**: ảnh, ý tưởng và chữ, làm trên nhánh `art/...`.

Đã xong:
- Gạch Training/Orc kèm hoạt ảnh, ô đặc biệt (issue #3).
- Nhân vật, nền, hiệu ứng trận đánh (issue #5, quy cách tên file nằm trong đó; gộp ở PR #8).
- Hiệu ứng nổ ô đặc biệt và font Baloo 2 (PR #13, quy cách ở `docs/ideas/specials_fx.md`). Đã ghép vào game: `scripts/board/special_fx.gd` phát hiệu ứng, font đặt làm mặc định trong `project.godot`.
- Thiết kế 4 quái, rồng, lò rèn, lời thoại (nhánh `docs/monsters`) và ảnh vương quốc (nhánh `art/kingdom`). Dùng cho giai đoạn 4–5, chưa ghép.

Việc mới thì tạo nhánh mới từ `main`, xong thì comment trực tiếp vào issue.

---

## 6. Số đo B5 (mô phỏng, 300 trận mỗi kiểu chơi)

Đo ngày 2026-11-02 bằng `tests/sim_balance.gd`. Mỗi ô ghi: kiểu ngẫu nhiên / nối dài nhất / chơi khôn.

| Luật | Orc: thắng | Orc: số lượt (trung vị) | Orc: máu hiệp sĩ còn | Lượt có tự nổ | Sát thương từ tự nổ | Chuỗi dài nhất | Ô đặc biệt mỗi trận |
|---|---|---|---|---|---|---|---|
| Hiện tại (hàng 3) | 100 / 100 / 100% | 7 / 7 / 7 | 98 / 98 / 98 | ~65% | 80–87% | 17 vòng | 0.1 / 0.5 / 0.5 |
| Hàng 3, ô mới không tạo sẵn hàng | 100 / 100 / 100% | 15 / 14 / 16 | 88 / 91 / 90 | ~42% | 60–73% | 12 vòng | 0.1 / 0.9 / 0.8 |
| Hàng 4 | 96 / 100 / 100% | 33 / 21 / 23 | 47 / 79 / 79 | ~20% | 23–38% | 6 vòng | 1.3 / 7.0 / 5.8 |
| **Đã chọn:** hàng 4, Orc 60 máu, đánh mỗi 3 lượt | 86 / 99 / 100% | 26 / 17 / 18 | 38 / 70 / 69 | ~20% | 23–38% | 6 vòng | 1.0 / 5.8 / 4.6 |

Nhận xét:
- Với hàng 3, trung bình mỗi lượt kéo theo 2.6 vòng nổ, có chuỗi 17 vòng (hệ số x17). Game gần như tự chơi: chơi bừa và chơi khôn ra kết quả như nhau, Orc không gây áp lực. Ô đặc biệt hầu như không xuất hiện vì trận kết thúc trước khi kịp nối dài.
- Giảm hệ số dây chuyền (`chain_step` 0.5 hoặc 0.25) chỉ kéo dài trận, không làm kỹ năng có giá trị hơn.
- Cho ô mới không tạo sẵn hàng giảm tự nổ nhưng chơi khôn vẫn không hơn chơi bừa.
- Hàng 4 là thay đổi duy nhất khiến kỹ năng có giá trị: chơi khôn thắng nhanh hơn và còn nhiều máu hơn hẳn, ô đặc biệt xuất hiện 5–7 lần mỗi trận, dây chuyền vẫn có nhưng thành phần thưởng (khoảng 1/5 số lượt).

---

## 7. Còn để ngỏ, chốt khi chơi thử

- Bảng 7×8 vừa tay trên điện thoại chưa. Bốn màu có làm nối quá dễ hay quá khó không.
- Ngưỡng ô đặc biệt 5/6/7 có hợp lý không.
- Hàng 4 tự nổ có làm dây chuyền quá hiếm, mất cảm giác "nổ dây chuyền" không. Mô phỏng nói khoảng 1/5 số lượt có tự nổ, cần cảm nhận bằng tay.
