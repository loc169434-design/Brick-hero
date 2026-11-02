# Issue #3 — sửa bộ ảnh trước khi ghép lại PR #2

Nguồn yêu cầu: [issue #3](https://github.com/loc169434-design/Brick-hero/issues/3). Nhánh làm việc `art/tiles`. Phạm vi thay đổi chỉ `assets/` và `docs/ideas/`; không chỉnh code, scene, tests hay cấu hình project. Bản website `gh-pages` không cập nhật trong lần sửa này.

## 1. Nhận diện bốn màu Orc

Khung/backdrop chuyển thành mảng sơn gameplay rộng ở viền, thu nhỏ phần mặt tương đối. Phụ kiện và huy hiệu góc phải dưới cố định qua chín nét mặt:

| Màu | Phụ kiện | Huy hiệu | Da |
|---|---|---|---|
| Đỏ | Khăn/băng đầu đỏ | Kiếm | Xanh olive |
| Xanh lá | Mũ lá xanh | Lá | Xám xanh nhạt, không lẫn nền xanh |
| Vàng | Mũ sắt vàng | Đồng xu | Xanh olive |
| Tím | Mũ trùm tím | Pha lê | Xanh olive |

Đã xem trực tiếp bốn ô cạnh nhau ở **46×46** và **100×100**, cả ảnh màu lẫn ảnh xám. Ở 46 px, viền màu thấy ngay; ảnh xám vẫn tách được khăn buộc, mũ lá, mũ sắt, mũ trùm và các huy hiệu kiếm/lá/đồng xu/pha lê. Đây là tự kiểm tra hình ảnh, không phải thử nghiệm tốc độ nhận diện với người chơi.

Phép đo màu theo mặt nạ hue/saturation, có trọng số alpha, trên toàn canvas 46×46:

| Đỏ | Xanh lá | Vàng | Tím |
|---:|---:|---:|---:|
| 53,5% | 43,8% | 55,2% | 46,3% |

Cả bốn trên 40%; đồng thời kiểm tra có mảng màu ở dải viền ngoài. Định nghĩa phép đo và số liệu ở 46/100/128 px nằm trong [metrics.json](issue3_review/metrics.json).

Ảnh bằng chứng, thứ tự trái sang phải: đỏ, xanh lá, vàng, tím. Mỗi ô giữ đúng kích thước pixel ghi trên tên file, không phóng to bằng CSS:

![Orc 46 px màu](issue3_review/orc_shield_46_color.png)

![Orc 46 px xám](issue3_review/orc_shield_46_gray.png)

[Orc 100 px màu](issue3_review/orc_shield_100_color.png) · [Orc 100 px xám](issue3_review/orc_shield_100_gray.png) · [Training 46 px màu](issue3_review/training_46_color.png) · [Training 46 px xám](issue3_review/training_46_gray.png).

## 2. Khung và khoảng đệm

- Cả 8 ô tĩnh của Training/Orc có canvas 128×128, bounds alpha của hình đúng **(4,4,120,120)**. Training vàng đã được đưa lên cùng cỡ với ba màu còn lại.
- Bốn file dự phòng `assets/tiles/tile_<color>.png` được đồng bộ với Training để không còn hai cỡ khung theo hai đường nạp.
- Chín nét mặt mỗi màu Orc cùng cỡ khung, hình 120×120 ở giữa canvas 128.
- Xuất lại clip với tỉ lệ mới. Trong frame đầu `idle` và `land`, bounds hình thật là **(36,36,120,120)** trong ô animation 192×192. Vùng giữa (32,32,128,128) khớp ảnh tĩnh; sai số kênh pixel do vòng chuyển alpha Canvas được giới hạn tối đa 1/255, không có sai khác vị trí/kích thước.
- Sửa bộ xuất ảnh: `land` bắt đầu bằng pose thường, chưa có bụi ở frame 0; từ frame kế tiếp mới nén/đổi nét và phát FX. Thời lượng, fps, số frame và loop của clip giữ nguyên.

## 3. Ba ô đặc biệt

| File | Cách dùng |
|---|---|
| `assets/tiles/special_lightning.png` | Lớp phủ tia sét chữ thập, nền trong suốt, viền sáng/tối tương phản |
| `assets/tiles/special_bomb.png` | Lớp phủ bom có ngòi, nền trong suốt, viền kem để tách khỏi cả nền tối và sáng |
| `assets/tiles/special_rainbow.png` | Cả ô bốn màu, dấu sao bốn cánh nhận diện wildcard, thay ô màu; không gán màu riêng |

Cả ba canvas 128×128, hình nằm trong vùng đệm 4 px; cầu vồng có khung hình 120×120. Sét và bom đã được chồng lên bốn màu của **cả Training lẫn Orc**, xem ở 100 px cả màu và xám. Không có animation đặc biệt mới.

[Ảnh chồng 16 trường hợp màu](issue3_review/specials_100_color.png) · [ảnh xám](issue3_review/specials_100_gray.png). Thứ tự hàng: sét/Training, sét/Orc, bom/Training, bom/Orc. [Ba ô đặc biệt ở 46 px](issue3_review/specials_standalone_46_color.png) · [ảnh xám](issue3_review/specials_standalone_46_gray.png).

## 4. Tương thích đường nạp và manifest

Giữ nguyên:

- `assets/tiles/<family>/tile_<color>.png`.
- `assets/tiles/<family>/animations/<color>_<clip>.png`.
- Toàn bộ 76 bản ghi `atlases` trong `assets/tiles/animation_pack.json`, gồm cả tên/giá trị `family`, `color`, `animation`, `file`, `fps`, `loop`, `frames`, `columns`, `cell` và kích thước/thời lượng. Kiểm tra deep-equality với bản trước sửa.
- Danh sách family, tên clip, event map và tài nguyên `sprite_frames_*.tres`.

Chỉ metadata mô tả màu/phụ kiện và pose đầu `land` cập nhật theo hình mới; không đổi cấu trúc manifest hay cách Claude đang đọc atlas. Giữ các PNG `expressions/` và atlas biểu cảm để trang xem thử vẫn dùng được; gameplay không bắt buộc nạp chúng.

## 5. Dung lượng và xuất ảnh

48 clip Orc phải đổi vì cả bốn mặt/phụ kiện/khung đổi; 28 clip Training phải đổi vì cả bốn ô tĩnh đều tăng hình thật lên 120×120. Do đó lần này 76 clip thay đổi có lý do cụ thể, không phải xuất lại nội dung không đổi để thêm blob mới.

PNG được nén **không mất dữ liệu** bằng ImageMagick/zlib mức 9, filter 5, bỏ metadata ngày giờ. Không giảm bảng màu, không thay checksum để né kiểm tra và không rewrite lịch sử Git.

Bộ xuất nay so pixel của ảnh ứng viên với file hiện có trước khi ghi. Nếu pixel giống, giữ nguyên cả file cũ; tài nguyên/manifest cũng chỉ ghi khi byte thực sự đổi. Đã chạy lại sau lần xuất đầu, kết quả **0 atlas cập nhật, 76 atlas giữ nguyên** khi input không đổi. Chỉ commit kết quả cuối sau khi tự kiểm tra, không push các lần thử và không rebuild/push nhánh web.

## Tự kiểm tra và bàn giao

Chạy từ root repo:

```sh
node docs/ideas/asset_preview/issue3_verify.mjs
node docs/ideas/asset_preview/verify.mjs
```

Script thứ nhất kiểm tra 87 điều kiện về tỉ lệ màu, bounds/đệm, frame đầu, hợp đồng manifest và ảnh đặc biệt, đồng thời tạo bảng ảnh thật 46/100 px và ảnh xám tại [issue3_review/index.html](issue3_review/index.html). Script thứ hai kiểm tra trang xem thử, animation và HTML offline; không sửa hoặc chạy thay bộ tests game của Claude.

Các phép đo không thay cho kiểm thử trên game thật. Claude merge `art/tiles` vào lại PR #2/`board/playable`, chạy suite game và chụp NEXT/HOLD 46 px cùng bàn 100 px trước khi merge `main`. Không cần đổi code nạp ảnh vì tên file và toàn bộ bản ghi atlas được giữ nguyên.

Kết quả lần sửa này: **87 kiểm tra issue #3 PASS**, **325 kiểm tra browser PASS**; Godot 4.7.2 import không báo lỗi và tải thành công **8 SpriteFrames / 76 clip / 1.824 frame**. Không sửa hoặc chạy thay tests gameplay của Claude. [Danh sách đầy đủ file thay đổi](issue3_files_changed.txt) và [nội dung comment bàn giao](issue3_comment.md) được lưu cùng nhánh.
