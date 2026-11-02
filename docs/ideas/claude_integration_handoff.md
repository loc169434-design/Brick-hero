# Bàn giao Claude — ghép asset Training + Orc vào bàn chơi

## Mục tiêu và phần đã có

Ghép bộ ảnh và animation đã chốt vào game Godot 4.7.2, giữ nguyên luật bảng, thao tác chạm/bàn phím, Hold và 3 khối tiếp theo. **Cập nhật issue #3:** Training giữ khung gỗ/nẹp sắt; Orc chuyển sang viền sơn gameplay rộng và phụ kiện/huy hiệu cùng màu: khăn đỏ/kiếm, mũ lá/lá, mũ sắt vàng/đồng xu, mũ trùm tím/pha lê. Thay mô tả mũ vá/băng trán cũ bằng [bản sửa issue #3](issue3_feedback.md).

ChatGPT chỉ làm asset và tài liệu; phần code/scene/tests thuộc Claude theo `AGENTS.md`. Theo issue #3, Claude đã ghép bộ trước vào PR #2/`board/playable`. Bản sửa ảnh này chưa được kiểm thử lại trong gameplay; Claude cần merge `art/tiles` vào PR đó rồi chạy kiểm tra và chụp màn hình.

Nguồn để ghép:

- `origin/art/tiles`: asset và tài liệu; commit `ad4b3f6` thêm bộ animation, `2cc659c` thêm công cụ xuất web. Lấy bản mới nhất của nhánh để có doc này.
- `origin/board/playable`: bản bàn chơi có `BoardView`, `BoardInput`, scene main/board đã được đọc để viết doc này. Đọc lại HEAD hiện tại trước khi sửa nếu nhánh đã thay đổi.
- `origin/main`: tại thời điểm đối chiếu đã có core và tests, chưa có phần hiển thị của `board/playable`.
- `gh-pages`: **chỉ là bản website đã xuất**, không merge nhánh này vào game.

Làm trên nhánh tích hợp riêng từ nhánh code phù hợp, dùng checkout hiện có và giữ thay đổi đang làm. Không sửa trực tiếp `main`, không tạo worktree nếu người dùng chưa yêu cầu. Fetch rồi merge `origin/art/tiles` vào nhánh tích hợp; không reset/ghi đè phần code của Claude.

Đọc theo thứ tự: `AGENTS.md` → `docs/core_plan.md` → doc này → [chi tiết gói ảnh](animation_pack.md). Trang xem đối chiếu: `docs/ideas/asset_preview/index.html`. Website nằm trên nhánh `gh-pages`; trạng thái Pages live cần kiểm tra riêng, không phải nguồn code game.

## Những quyết định hình ảnh đã chốt

- Màn thao trường dùng `training`: kiếm, lá, đồng xu, pha lê trong khung gỗ/nẹp sắt.
- Gặp Orc yếu đầu game dùng `orc_shield`: icon trên gạch là **mặt Orc**, không còn là biểu tượng dụng cụ. Bốn màu có bốn dáng đầu/phụ kiện để phân biệt ngoài màu sắc; không phải bốn hệ luật mới hay bốn con quái có máu riêng.
- Giữ nguyên ý nghĩa màu: đỏ sát thương, xanh hồi máu, vàng tiền, tím phá khiên. Theme chỉ đổi hình và phản ứng.
- Orc hoạt hình, ngố, hơi nhếch nhác, không kinh dị. Cười chọc bằng biểu cảm; không hiện lời xúc phạm người chơi.
- Bộ này là gạch và FX, **không có sprite toàn thân quái, animation anh hùng hay giọng cười/hét thu âm**. Không dùng ảnh mặt gạch như một bộ animation quái toàn thân rồi coi phần chiến đấu đã xong.

## Tài nguyên cần nạp

| Mục đích | Đường dẫn `res://` |
|---|---|
| Gạch tĩnh, Hold, preview | `assets/tiles/<family>/tile_<color>.png` |
| AnimatedSprite2D | `assets/tiles/<family>/sprite_frames_<color>.tres` |
| Một animation riêng | `assets/tiles/<family>/animations/<color>_<animation>.png` |
| Manifest đầy đủ | `assets/tiles/animation_pack.json` |
| Biểu cảm Orc riêng | `assets/tiles/orc_shield/expressions/<color>_<pose>.png` |
| Atlas biểu cảm | `assets/tiles/orc_shield/expressions_<color>.png` |
| FX riêng | `assets/fx/tile_reactions/` |

`family` = `training` hoặc `orc_shield`. Ánh xạ `Cell.BlockColor`: `RED → red`, `GREEN → green`, `YELLOW → yellow`, `PURPLE → purple`. Không dùng `Cell.NO_COLOR = -1` làm chỉ số mảng màu. Rainbow xử lý riêng.

Bốn PNG ở gốc `assets/tiles/tile_<color>.png` vẫn là hình Training cũ để tương thích. Chỉ thay `TILE_PATHS` hiện tại sẽ thấy gạch tĩnh; **không đủ để có animation hay chọn theme**.

Đã bổ sung `assets/tiles/special_lightning.png` và `special_bomb.png` là **lớp phủ trong suốt** trên ô màu; `special_rainbow.png` là **cả ô thay thế**. Giữ cơ chế nạp hiện tại và phần vẽ dự phòng khi thiếu ảnh. Đừng làm ô đặc biệt trông giống ô thường khi thêm mặt Orc; Rainbow không tự chọn mặt theo màu `-1`. Không cần thêm animation cho ba ảnh này.

## Kích thước, vị trí và cách phát

- PNG tĩnh: canvas 128×128, phần hình đúng 120×120 tại (4,4); cả bốn màu và hai bộ đã chuẩn hóa cùng cỡ.
- Animation: 24 frame, atlas 1536×576, 8 cột × 3 hàng, mỗi frame **192×192** gồm gạch 128 px ở giữa và đệm FX. Rect frame `i`: `(i % 8 × 192, floor(i / 8) × 192, 192, 192)`.
- `SpriteFrames` đã lưu rect, fps và loop, không cắt lại atlas thành ô 128 px.
- Tâm frame là `(96,96)`. Đặt node tại tâm ô bảng. `AnimatedSprite2D.centered = true`; scale = **kích thước ô logic / 128**, không phải `/192`.
- `BoardView.CELL` trong nhánh đã đọc là **100**, khác con số 110 trong bản kế hoạch. Dùng giá trị thực tế này: scale `100/128`; không đổi kích thước bảng chỉ để khớp doc. Hold/preview đang là 36 px thì dùng ảnh tĩnh với tỉ lệ tương ứng.
- Đệm FX có thể vượt biên ô; không dùng cả rect 192 px làm hitbox và không clip từng sprite theo ô lưới. Có thể clip ở biên toàn bảng nếu chủ ý thiết kế yêu cầu.
- PNG animation **đã ghép FX**. Không phát thêm bụi/vụn gỗ lần nữa cho cùng clip. FX riêng dùng khi dựng hiệu ứng độc lập hoặc thêm confetti sau một cái chết đã phát.

Gán tài nguyên vào `AnimatedSprite2D.sprite_frames`, rồi `play(name)`. Dùng `animation_finished` cho clip không lặp; không chờ signal này ở `idle`. Khi tăng tốc replay, dùng cùng hệ số cho timer và clip, không chờ thời lượng gốc sau khi sprite đã chạy nhanh hơn.

## Danh sách animation và kết thúc

| Clip | Giây ở tốc độ 1× | Có ở bộ nào | Kết thúc / mục đích |
|---|---:|---|---|
| `idle` | 2.40 | Cả hai | Lặp; Orc chớp mắt |
| `drop` | 0.85 | Cả hai | Rơi cục bộ → nén → nảy, rồi đứng |
| `land` | 0.65 | Cả hai | Chỉ nén/nảy và bụi khi chạm đất |
| `combo` | 1.20 | Cả hai | Ô bị xóa → biến mất; frame cuối trong suốt |
| `hurt` | 0.75 | Cả hai | Rung/đau nhưng sống → nét thường |
| `taunt` | 1.70 | Orc | Cười sau lượt hụt, không tự lặp |
| `fear` | 1.20 | Orc | Run và giữ nét hoảng |
| `near_miss` | 2.80 | Orc | Sợ → nhẹ nhõm → cười vì còn sống |
| `gloat` | 1.70 | Orc | Cười hiểm khi người chơi sắp thua |
| `death` | 1.50 | Orc | Hoảng → hét → biến mất |
| `win` | 1.80 | Cả hai | Người chơi thắng: Training nhảy mừng; Orc hét/biến mất; có confetti |
| `lose` | 2.00 | Cả hai | Người chơi thua: Training chùng xuống; Orc cười thắng và còn hiện |

Ngoài `idle`, tất cả clip không lặp. Sau `land`, `hurt`, `taunt`, `near_miss`, `gloat`, trở về `idle` **chỉ khi ô còn tồn tại và lượt/trận vẫn cho phép**. `fear` giữ nét hoặc được thay bằng kết quả thật. Sau `combo`, `death`, `win` phía Orc: bỏ node/giữ trong suốt, không tự idle để tránh hồi sinh. Kết quả trận giữ đến màn tiếp theo/restart; không tự idle sau `win/lose` vì clip vừa kết thúc.

## Ghép ngay vào nhánh bàn chơi

Các tên dưới đây đã có trong `scripts/board/board_view.gd`; Claude quyết định cấu trúc node/cache mới, không bắt buộc viết lại toàn bộ renderer.

1. **Chọn theme từ phía trình bày.** Thêm lựa chọn `training/orc_shield` ở view/cấu hình encounter, mặc định Training. Chuyển theme giữa hai lượt hoặc khi đổi màn, không đổi giữa một replay. Chưa có battle manager thì cho debug selector để kiểm tra Orc.
2. **Giữ hình tĩnh cho khối đang chọn, Hold và NEXT.** `_draw_piece()`, `_draw_piece_in()`, `_draw_cell()` lấy texture theo theme. Giữ ghost hiện tại dễ nhìn, không cho ghost phát cười/nổ.
3. **Chỉ một lớp vẽ sở hữu mỗi ô.** Khi node animation vẽ ô, `_draw()` không vẽ lại texture tĩnh của ô đó. Nếu không tách sẽ thấy gạch tĩnh nằm dưới frame nổ và tưởng ô chưa biến mất.
4. **Replay clear theo `result.steps`.** Ở `_replay()`, dùng từng `ClearStep.cleared` và `cleared_cells` (cùng thứ tự) để lấy đúng ảnh/màu của ô trước khi xóa. Model đã được resolve xong; không hỏi board cuối để tìm màu của ô đã mất.
5. **Bắt đầu `combo` trước khi xóa hình.** Tạo các sprite xóa ô của một bước cùng lúc; chờ theo batch rồi chuyển bước. Không chờ 1.2 giây nối tiếp cho từng ô. Không áp `FLASH_TIME = 0.22` rồi cắt mất phần lớn clip 1.2 giây. Nếu cần nhịp nhanh hơn, tăng tốc cả clip và lịch replay theo cùng hệ số.
6. **Giữ trình tự clear → spawn special → gravity.** `_shown`, `_flashing`, `_falling`, `_fall_t` hiện là trạng thái hiển thị theo bước. Giữ snapshot cần thiết đến khi hiệu ứng tương ứng xong; dùng `step.spawned` để hiển thị đúng special mới và `step.falls` để di chuyển ô sống.
7. **Di chuyển do gravity vẫn do view làm.** `_falling`/`_set_fall_t()` đã dịch ô từ `from` đến `to`; sau tween phát `land` tại đích. Không thêm `drop` lên cả quãng đường đó: clip `drop` chỉ dịch hình cục bộ khoảng 78 px trong canvas, không biết ô rơi bao nhiêu hàng. Khối hard-drop từ đầu bảng cũng phải có chuyển động vị trí thực nếu muốn nhìn thấy quãng rơi.
8. **Chỉ phát phản ứng sau kết quả replay.** `drop_finished(result)` của view phù hợp cho phản ứng sau lượt. `BoardGame.dropped` phát đồng bộ khi model resolve, trước `_spawn()` kiểm tra topped-out, nên không dùng nó làm dấu “animation đã xong”.
9. **Restart phải hủy replay cũ.** `BoardInput` đang cho phím R gọi `new_game()` kể cả khi busy. Dùng mã thế hệ/lượt hoặc cơ chế hủy tương đương, dọn tween/node/queue để coroutine cũ không xóa ô của game mới sau một `await`. Giữ toàn bộ thao tác bàn phím và touch hoạt động như trước.
10. **Game-over overlay phải theo nhịp kết thúc.** `_draw()` hiện đọc `game.is_over` ngay; model có thể topped-out trong khi view còn clear/fall. Hoàn tất hoặc hủy replay theo chính sách rõ ràng, phát `lose` rồi hiện overlay; không để overlay che sạch cảnh mà người dùng vừa yêu cầu.

`BoardView._busy` tiếp tục chặn hành động làm thay đổi bảng trong đoạn cần đồng bộ clear/fall. Các cảnh cười phụ không cần giữ input 1.7–2.8 giây mỗi lượt; có thể chạy nền và bị ngắt bởi lượt tiếp theo. Không làm game chậm chỉ vì mọi ô phải phát hết một lần cười.

## Gắn biểu cảm vào sự kiện thật

Tên trong `animation_pack.json.eventMap` là **hợp đồng đề xuất**, chưa phải những signal hiện đã có đủ trong game.

| Điều kiện đã xác nhận | Phản ứng | Nơi áp dụng / ràng buộc |
|---|---|---|
| Ô vừa chạm đất | `land` | Cả hai theme; sau vị trí rơi thực |
| Ô nằm trong `step.cleared` | `combo` | Ô đó biến mất sau clip; không tiếp tục cười |
| `result.cleared_anything() == false`, chưa kết thúc | `taunt` | Chỉ Orc còn sống; không gọi lượt này là “đi ngu” trong UI |
| Có dự báo sát thương chí mạng đáng tin | `fear` | Orc đang sống, không phán đoán từ số ô/chain đơn thuần |
| Sau dự báo trên, resolve xong và HP quái vẫn > 0 | `near_miss` | Đã chứa cả sợ, nhẹ nhõm và cười; không ghép thêm một `fear` đầy đủ ở đầu lần nữa |
| Quái trúng đòn nhưng vẫn sống | `hurt` | Khi battle HP/shield thật đã tồn tại; không chọn cả ô sống để rung mỗi lần clear |
| Người chơi gần thua nhưng chưa thua | `gloat` | Từ trạng thái thật; giới hạn tần suất, không gọi mỗi frame |
| Quái đã chết | `death` **hoặc** `win` | Không chạy cả hai liên tiếp trên cùng sprite |
| Kết quả trận: người chơi thắng | `win` | Dùng thay đoạn chết nếu chưa phát; nếu `death` đã chạy thì chỉ thêm confetti/UI |
| Kết quả trận: người chơi thua | `lose` | Orc sống cười thắng; Training chùng xuống |

Hiện nhánh B2 được đọc **chưa có HP, khiên hoặc kết quả trận đánh**. Ghép Training/Orc trên bảng ngay; các trigger battle chưa có phải để adapter/debug event rõ ràng, không bịa `player_won` từ việc xóa nhiều ô hay bài test UI qua. Training không có mục tiêu hoàn tất bài tập được định nghĩa thì chỉ xem `win` bằng debug; `game.is_over`/`topped_out` là điều kiện thua đã có.

Nếu cần phản ứng gần thua ngay trong B2, có thể đề xuất dựa trên vùng spawn bị đe dọa; Claude định nghĩa điều kiện từ board và kiểm thử trước, không nhầm nó với “đã thua”. Ngưỡng HP/tần suất sau này phải nằm trong cấu hình, không đặt tùy tiện vào luật core.

Các clip này là **phản ứng của mặt trên gạch**. Đừng khiến mọi ô biến mất khi chỉ có một quái ngoài bảng chết, trừ khi đó là chuyển cảnh cuối trận đã được định nghĩa. Chọn một nhóm ô hoặc một mặt đại diện cho cười/hoảng để tránh cả bảng rung cùng lúc; ô đang clear/fall luôn ưu tiên hành động của chính nó.

## Ưu tiên và chống xung đột

Manifest đưa thứ tự tham khảo: `win/lose` → `death` → `combo` → `near_miss` → `fear` → `hurt` → `gloat` → `taunt` → `drop` → `land` → `idle`. **Phải áp dụng theo mục tiêu**: sự kiện kết thúc trận cho scene; xóa/rơi cho ô tương ứng; cảm xúc chỉ ở ô sống, không được cướp animation chuyển động của ô đang rơi chỉ vì đứng cao hơn trong danh sách.

- Mỗi node chỉ một clip hiện hành; clear/death đánh dấu node kết thúc để chặn các callback cười đến muộn.
- Chốt kết quả trận một lần theo luật game; `win` và `lose` không thể cùng phát. Không quyết định thắng do thứ tự hai cái tên trong manifest.
- Xóa queue cảm xúc khi đổi theme, restart, kết thúc trận hoặc xóa node. Callback cần kiểm tra phiên hiện tại và node còn hợp lệ.
- Không phát cười chọc nếu `game.is_over`; không phát near-miss nếu HP thực tế đã bằng 0.
- Đổi lượt có thể ngắt cười về idle; không ngắt rõ ràng một batch xóa ô rồi để hình/model lệch nhau.

Nếu `fear` đã chạy trong lúc chờ kết quả, khi biết quái thoát chết có thể phát `near_miss` từ **frame 9 (đếm từ 0)**, là frame đầu biểu cảm nhẹ nhõm trong bản xuất 24 frame, thay vì bắt người chơi xem lại đoạn sợ từ đầu. Nếu chưa có dự báo trước đó, phát toàn bộ `near_miss` khi mô phỏng/debug chuỗi phản ứng. Đừng dùng một clip dài để trì hoãn việc cập nhật HP thật.

## Bộ nhớ và hiệu năng điện thoại

Giữ số node theo ô hiển thị; không tạo lại một tài nguyên ảnh cho từng node mỗi frame. Các node có thể dùng chung texture/SpriteFrames được cache theo theme+màu, nhưng mỗi node cần trạng thái phát riêng. Hold/NEXT dùng PNG tĩnh.

Lưu ý `.tres` có tham chiếu **mọi clip của một màu**. Atlas RGBA 1536×576 cần khoảng 3.375 MiB trước mipmap/nén VRAM; toàn bộ 76 atlas khoảng 256.5 MiB. Nạp cả bốn màu Orc theo tài nguyên đầy đủ có thể kéo vào khoảng 162 MiB texture, chưa tính phần còn lại của game. Không preload cả hai bộ một cách mặc định và gọi đó là tối ưu.

Cách ghép nhanh để kiểm tra đúng hình: dùng `.tres` cung cấp. Khi đo trên điện thoại nếu quá nặng, dùng manifest dựng cache clip đang cần theo encounter/animation, hoặc dùng atlas biểu cảm 384×384 + transform/FX riêng để giảm bộ nhớ. Đó là quyết định triển khai của Claude; giữ nguyên bộ xuất đầy đủ để so sánh hình ảnh. Không bỏ nét mặt hoặc đổi thành ảnh tĩnh rồi coi yêu cầu animation đã hoàn tất.

## Tiêu chí nghiệm thu

- [ ] Mở game thấy đúng theme Training; chọn Orc thấy đúng bốn mặt, NEXT/Hold đồng bộ. Màu gameplay và RNG không đổi.
- [ ] Kéo ngang/chạm xoay/vuốt xuống/Hold và các phím trái–phải, Z/X, Space/Down, C, R vẫn dùng được. Hình và điểm chạm trùng nhau sau scale.
- [ ] Một lượt rơi: vị trí đi đúng quãng đường, chỉ một lần nảy/bụi khi chạm đích; không rơi cục bộ lần hai.
- [ ] Fixture chain nhiều bước: clear đồng thời đúng từng bước, đúng màu, special mới giữ đúng overlay, gravity đúng; nhãn CHAIN/COMBO vẫn đọc được.
- [ ] Ô clear xong không còn texture tĩnh phía dưới, không tự hiện lại ở idle.
- [ ] Orc sống sau lượt hụt mới cười; near-miss đổi đúng sợ → nhẹ nhõm → cười; nhấn lượt tiếp không bị khóa dài bởi cảm xúc phụ.
- [ ] Debug kịch bản chết/thắng không chạy hai lần chết; không cười sau chết. Gần thua cười hiểm, thua mới cười thắng. Training không gọi clip chỉ có ở Orc.
- [ ] Nhấn R hoặc restart bằng touch trong lúc clear/fall/cười: không callback cũ, không node mồ côi, không trạng thái busy kẹt.
- [ ] Hold/NEXT, ghost, special và Rainbow không mất khả năng nhận diện khi đổi theme; không truy cập màu `-1`.
- [ ] Kiểm tra hiệu năng/bộ nhớ trên thiết bị đích hoặc ghi rõ mới xác minh ở desktop. Mọi sửa luật core nếu có phải giải thích riêng; tác vụ này không yêu cầu đổi luật.

Chạy lại suite Godot hiện có (`godot --headless --path . --script tests/run_tests.gd` bằng binary 4.7.2), cộng các kiểm thử trạng thái/restart/replay phù hợp và smoke test chạm/bàn phím của bản ghép. Trước tích hợp, gói ảnh đã qua **325 kiểm tra browser** và kiểm tra tải **8 SpriteFrames / 76 clip / 1.824 frame** trên Godot 4.7.2; các kết quả đó **không thay cho kiểm thử gameplay sau khi ghép**.

## Tin nhắn có thể giao thẳng cho Claude

> Đọc AGENTS.md, docs/core_plan.md và docs/ideas/claude_integration_handoff.md. Trên nhánh tích hợp từ bản board/playable mới nhất, merge origin/art/tiles và ghép bộ Training + Orc vào game. Làm phần hiển thị/replay và input trước, dùng các trigger đã có thật; biểu cảm phụ chạy không cản thao tác, điều kiện battle chưa có để adapter/debug rõ ràng. Bảo toàn luật core, sửa code/scene/tests trong phạm vi Claude phụ trách. Kiểm tra scale, special/Rainbow, clear→fall, restart giữa animation và tình huống chết/thoát chết. Báo phần đã ghép và phần vẫn chờ battle manager; không báo hoàn tất toàn bộ chiến đấu nếu mới có bản xem asset.
