# Bộ ô gạch theo quái — Orc Khiên

> Cập nhật issue #3: bộ gỗ/nẹp sắt dùng cho **Training**; bộ **Orc** dùng viền sơn màu rộng, khăn đỏ/kiếm, mũ lá/lá, mũ sắt vàng/đồng xu, mũ trùm tím/pha lê. Cả hai bộ có hình thật 120×120 trong canvas 128. Xem [bản sửa và ảnh kiểm tra](issue3_feedback.md), [bàn giao animation](animation_pack.md) và [trang xem thử](asset_preview/index.html). Các ghi chú concept ban đầu bên dưới chỉ là lịch sử ý tưởng.

Theo mục 5 của `docs/core_plan.md`. Nhánh: `art/tiles`.

| File trong `assets/tiles/` | Màu | Biểu tượng | Ý nghĩa |
|---|---|---|---|
| `tile_red.png` | Đỏ | Kiếm | Sát thương |
| `tile_green.png` | Xanh lá | Lá cây | Hồi máu |
| `tile_yellow.png` | Vàng đất | Đồng xu | Vàng |
| `tile_purple.png` | Tím | Pha lê | Phá khiên |

Mỗi file là PNG RGBA 128×128 px, có khoảng đệm trong suốt. Biểu tượng khác nhau giúp nhận diện mà không chỉ dựa vào màu. Khung vuông bo góc thống nhất để ghép trên lưới.

## Style guide theo ảnh anh hùng đã được cung cấp

Tham chiếu trực tiếp ảnh anh hùng người dùng cung cấp trong cuộc trò chuyện: viền nâu đậm, nét hoạt hình 2D, mảng màu lớn và bóng đổ ít lớp. Chất liệu gỗ, da và kim loại mờ; bảng màu ấm theo khiên gỗ, kiếm và trang phục của anh hùng. Ảnh tham chiếu chưa được lưu trong repo.

Bộ Orc Khiên: khung gỗ vuông, nẹp sắt và đinh tán lớn, bảng màu sơn hơi trầm. Biểu tượng lớn, viền rõ, nhìn thẳng. Tránh bề mặt kẹo bóng, glow, hạt sáng, gradient dày và chi tiết li ti. Khung chung vẫn để lộ phần màu lớn để đọc tốt ở kích thước 110 px.

Ảnh được tạo bằng công cụ sinh ảnh với ảnh anh hùng làm tham chiếu phong cách. Bốn ô được tạo cùng một sheet, tách riêng, thu về 128×128 px và giữ alpha. Bản gốc độ phân giải cao nằm ngoài checkout trong `/workspace/generated_images/` của phiên tạo ảnh, không phải đường dẫn phụ thuộc khi chạy game. Bản đá quý ban đầu được thay bằng bộ này; có thể xem bản cũ trong lịch sử Git.

## Mỗi quái một bộ gạch

- Bộ Training: `assets/tiles/training/tile_<color>.png`; bộ Orc: `assets/tiles/orc_shield/tile_<color>.png`, với `color` là `red`, `green`, `yellow`, `purple`.
- Bốn file ở gốc `assets/tiles/` giữ bộ biểu tượng gỗ cũ làm dự phòng theo core plan. Chúng cùng hình với Training, không còn là bản sao mặt Orc. Không đồng bộ mặt Orc ngược lên bộ gốc.
- Các quái tiếp theo dùng thư mục `assets/tiles/<monster_id>/` và cùng bốn tên file. Theo yêu cầu mới, biểu tượng đổi thành mặt quái của từng loài, giữ ý nghĩa màu. Dáng đầu/tóc/phụ kiện khác nhau giúp nhận diện ngoài màu sắc.
- Mọi bộ giữ PNG RGBA 128×128, cùng kích thước hình bên trong và khoảng đệm trong suốt. Không thêm chi tiết tràn sang ô kế bên.
- Doc hiện chỉ xác định Orc Khiên; chưa tạo bộ cho quái chưa có thiết kế.

## Bàn giao

Code hiện có thể nạp trực tiếp các file bằng đường dẫn `res://assets/tiles/tile_<color>.png`. Đề xuất cho phần code: chọn `res://assets/tiles/<monster_id>/tile_<color>.png` theo quái hiện tại; dùng bộ gốc làm dự phòng. Đây là đề xuất bàn giao, chưa triển khai cơ chế đổi bộ. Bộ ảnh chưa được gắn vào bàn chơi vì checkout hiện chưa có scene hay script. B1–B2 vẫn có thể dùng ô màu tạm theo kế hoạch. Không thay đổi cấu hình project, scene, code hoặc tests trong nhánh ảnh này.
