# Hiệp sĩ — đợt 1 / Issue #52

Theo [kế hoạch](../../hero_sprite_plan.md), nhánh `art/hero-hand-drawn`.
Mốc so sánh: `d13e819b0e159398f3edaf5119656ebe236d22aa` (sau PR #51).

## Bàn giao

- [Bảng mẫu](../../../assets/characters/hero_rookie/hero_model_sheet.png): toàn thân, cười tự tin / gầm khi chém / đau, tay nắm / mở, kiếm gỗ / khiên gỗ và màu có mã hex.
- `assets/characters/hero_rookie/anim/fresh_idle.png`: 8 cel, 12 fps, lặp; chớp mắt ở khung 5.
- `assets/characters/hero_rookie/anim/fresh_run.png`: 8 cel, 16 fps, lặp; chạm / dồn xuống / bước qua / bật, hai nửa vòng. Khung 3 và 7 có chân rời đất.
- `assets/characters/hero_rookie/anim/fresh_attack.png`: 12 cel, 24 fps, `impact=6`; 0 thủ, 1–3 lấy đà, 4 nhòe kiếm, 5–6 giữ cùng một cel chạm, 7–9 theo đà, 10–11 hồi.

Atlas RGBA, cel 512×512, 4 cột. `idle` và `run`: 2048×1024; `attack`: 2048×1536. Gốc đăng ký (256, 500); riêng chân trên không của `run` nằm cao hơn đường đất. Dáng đứng cao khoảng 392 px; gót đứng ở y=499–500. Đầu được đối chiếu bằng mắt với bảng mẫu, không coi phép đo bbox toàn thân là phép đo đầu.

Giữ tóc nâu, khăn đỏ, áo xanh viền kem, đai / giáp tay da, khiên gỗ viền sắt, kiếm **gỗ** và ủng nâu của mẫu cũ. Không đổi sang hiệp sĩ mặc giáp sắt.

## Xem nhịp và dáng

| Clip | GIF cũ / mới | Onion skin | Hình bóng, mỗi cel 200 px |
|---|---|---|---|
| idle | [So sánh](idle_comparison.gif) | [0, 2, 5, 6](idle_onion.png) | [8 khung](idle_silhouettes_200.png) |
| run | [So sánh](run_comparison.gif) | [0, 1, 2, 3](run_onion.png) | [8 khung](run_silhouettes_200.png) |
| attack | [So sánh](attack_comparison.gif) | [0, 3, 4, 5, 8, 11](attack_onion.png) | [12 khung](attack_silhouettes_200.png) |

GIF đặt cũ bên trái, mới bên phải, cùng tỷ lệ hiển thị. Trước đây **chưa có run**: ô trái của GIF run là dáng idle gốc và có ghi nhãn, không dựng một clip chạy cũ giả. Cột cũ lấy từ Git ở mốc trên. GIF dùng bước thời gian 1/100 giây theo chuẩn GIF: idle 670 ms/vòng (lý tưởng 666,7 ms), run 500 ms/vòng, attack 500 ms/vòng. Không làm chậm để che nhịp. Mọi ảnh xem thử và bảng mẫu đều dưới 2 MB.

## Cách làm và phạm vi

Các cel toàn thân được vẽ lại bằng công cụ tạo ảnh theo ảnh gốc và bảng mẫu, theo phong cách hoạt hình vẽ tay; đây không phải tranh do họa sĩ người vẽ thủ công. Mỗi dáng có nét mặt, thân, chân và khăn riêng. Không dùng bộ dựng khớp Python cũ; không lấy tay, chân, đầu hay kiếm từ khung đứng rồi xoay / ghép lại.

Khâu đóng gói chỉ tách **nguyên cel**, cắt khoảng trống ngoài cel kèm lề nét, đăng ký / thu phóng đồng đều **cả cel**, đóng atlas và xuất ảnh xem thử từ alpha. Không biến dạng hoặc xoay riêng bộ phận cơ thể. Ngoại lệ hold đúng kế hoạch: khung attack 6 là bản sao nguyên vẹn của khung 5. Idle có 8 cel khác nhau; run có 8; attack có 11 cel khác nhau và một hold.

`anim.json` giữ nguyên toàn bộ thông số clip cũ, chỉ thêm `run`. Chưa thêm `hop_back` vì thuộc đợt 2 và chưa có tranh; không khai báo clip trống. Không sửa rig, code, scene hay test. Hai mức trầy xước và các clip khác giữ nguyên. Code hiện tại chưa tự chọn `run` khi dash; việc nối vào `dash_to` thuộc phần code ở mục 6 của kế hoạch.

## Kiểm tra

- Kiểm tra kích thước, alpha, số cel, không có pixel alpha chạm mép cel, số cel khác nhau và hold 5–6.
- Kiểm tra metadata cũ không đổi; `attack.impact=6`.
- Kiểm tra số khung / thời lượng GIF, mọi preview <2.000.000 byte.
- Import bằng Godot 4.7.2; `fresh_run.png.import` dùng VRAM compression như các atlas hiện có.
- Bộ test hiện có: **121 passed, 0 failed**, không có `SCRIPT ERROR` hay `ERROR` trong log import / test: `godot --headless --path . -s res://tests/run_tests.gd`.

[Số liệu đóng gói](validation.json) ghi bbox phần nét đặc (alpha >220), số cel khác nhau và thời lượng GIF. Kiểm tra mép cel dùng toàn bộ alpha, không chỉ ngưỡng này. Các kiểm tra kỹ thuật không thay cho duyệt cảm giác động tác: dùng GIF / onion / hình bóng ở trên để người chơi duyệt nét và nhịp trước đợt 2.
