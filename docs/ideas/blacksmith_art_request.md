# Yêu cầu cho ChatGPT: vẽ lại hoạt hình thợ rèn

Claude viết, gửi ChatGPT. Làm trên nhánh `art/blacksmith`, chỉ sửa `assets/characters/blacksmith/` và `docs/ideas/`. Không sửa code; Claude ghép vào lò rèn.

## Vì sao làm lại

Người dùng chơi thử thấy thợ rèn **thô và xấu**. Bộ clip ở issue #30 được dựng bằng Python/Pillow, xoay và kéo các mảnh cắt từ một ảnh đứng, nên:

- Cú đập búa chỉ 6 khung, búa vung ngang chứ không giơ cao rồi giáng xuống mặt đe, không thấy lực.
- Thân, mặt và tay gần như không đổi giữa các khung: không gồng, không nhăn mặt, không đổ mồ hôi.
- Ăn mừng là ảnh đứng giơ búa, mặt không đổi.

## Cách vẽ

- **Vẽ tay từng khung**: mỗi khung là một hình vẽ hoàn chỉnh của cả nhân vật, đúng tư thế của khung đó. **Không** dựng bằng Python/Pillow, không xoay, kéo hay ghép mảnh cắt từ một ảnh gốc. Dùng script chỉ để xếp khung vào atlas và kiểm tra.
- Giữ đúng nhân vật hiện có: tóc nâu bù xù có băng trán, ria mép và râu quai nón, áo xanh xắn tay, tạp dề da có khóa vàng, kìm đeo hông, búa cán gỗ đầu sắt. Cùng nét mực đậm, cùng kiểu tô bóng với nền `assets/bg/forge.png`.
- Mặt **quay sang trái** như hiện tại, vì đe nằm bên trái ông.
- Không vẽ bóng dưới chân, không vẽ đe hay lửa vào ảnh. Nền trong suốt.

## Cân đối với phòng rèn

Nền là ảnh 1080×1920. Mặt đe ở khoảng (650, 735), sàn chỗ ông đứng ở y ≈ 880, mặt bàn ở y ≈ 715. Trên màn hình ông cao khoảng **300 px**: mặt bàn ngang thắt lưng, mặt đe ngang hông.

- Ô khung 512×512, chân đặt giữa đáy tại (256, 500), người cao khoảng 400 px trong ô (đỉnh tóc ở y ≈ 100), giống ảnh `idle.png` hiện tại. Code tự co theo cỡ này.
- Mọi khung, mọi clip cùng điểm chân và cùng cỡ người.
- Ở khung `impact` của `hammer` và `hammer_final`, ghi vị trí **đầu búa** trong ô vào `rig.json`, mục `anchors.<clip>.hammer`. Claude sẽ dùng điểm này để đặt ông sao cho búa giáng đúng mặt đe.

## Các clip

Theo quy cách các clip hiện có: `assets/characters/blacksmith/anim/fresh_<clip>.png`, lưới 4 cột, ô 512×512, RGBA, ô thừa trong suốt. Khai báo `frames`, `fps`, `loop`, `impact` trong `anim/anim.json`, thêm `head` và `mouth` cho clip mới trong `rig.json`. Clip không lặp kết thúc đúng pixel `idle` khung 0.

| Clip | Khung | Lặp | Dùng khi | Nội dung |
|---|---|---|---|---|
| `idle` | 12, 12 fps | Có | Đứng chờ | Thở, ngực phập phồng, một lần đưa mu tay lau trán, mắt chớp |
| `talk` | 8, 12 fps | Có | Nói câu chào | Miệng mở đóng, tay cầm búa khoát nhẹ, lông mày nhướn |
| `hammer` | 16, 24 fps, `impact` ≈ 9 | Không | Nhát 1 và 2 | Hai tay nắm cán, **giơ búa cao qua vai**, người ngả ra sau lấy đà, bắp tay gồng; giáng mạnh xuống mặt đe, mặt nhăn, răng nghiến, má phồng. Khung chạm: búa nảy nhẹ, thân rung, **mồ hôi văng khỏi trán**; rồi hồi về |
| `hammer_final` | 20, 24 fps, `impact` ≈ 12 | Không | Nhát thứ 3 | Như `hammer` nhưng dồn hết sức: nhón chân, giơ búa cao hơn, hét. Khung chạm: mồ hôi văng nhiều, tóc và râu bật lên. Sau đó thở hắt ra |
| `cheer` | 16, 12 fps | Không | Rèn xong | Đặt búa xuống, **lau mồ hôi trán** bằng cẳng tay, thở phào rồi **cười tươi**, gật đầu hài lòng |
| `grin` | 14, 12 fps | Không | Món đồ bay vào trang bị của hiệp sĩ | Chống tay hông, ngẩng cằm, **nhe răng cười đắc ý**; ở khoảng khung 5–9 một chiếc răng **lóe sáng** (tia sáng bốn cánh trắng-vàng, vẽ luôn vào khung). Ghi vị trí chiếc răng vào `rig.json`, mục `anchors.grin.tooth` |

Mồ hôi: những giọt trong suốt màu xanh nhạt có viền mực, đọng ở trán và thái dương trong `hammer`, `hammer_final`, và văng ra ở khung chạm. Trong `cheer`, trán còn ướt trước khi lau.

## Kiểm tra trước khi giao

- GIF từng clip đúng fps, ảnh lưới đánh số trên nền xanh đậm, đặt trong `docs/ideas/blacksmith_review/` (kèm `.gdignore`).
- Một ảnh ghép nhân vật vào nền `forge.png` ở cỡ 300 px, đặt chân tại (790, 880), cho khung `idle` 0 và khung `impact` của `hammer`, để thấy ông cân với bàn và đe.
- Kiểm tra: số khung, fps, impact, alpha, khung cuối trùng `idle` 0, điểm chân đúng.
- Chạy Godot 4.7.2 import và bộ test.

## Code đã chuẩn bị

Trên nhánh `core/forge-polish`, lò rèn đã:

- phóng thợ rèn lên khoảng 300 px;
- tự dùng `hammer_final` cho nhát thứ 3 và `grin` khi món đồ tới tay hiệp sĩ, nếu có hai clip này;
- tạm vẽ giọt mồ hôi văng ra và tia lóe ở miệng bằng code. Khi có `grin` vẽ sẵn tia lóe, code tự tắt tia lóe của mình.
