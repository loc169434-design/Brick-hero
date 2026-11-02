# Bộ ô gạch 4 màu — bản đầu

Theo mục 5 của `docs/core_plan.md`. Nhánh: `art/tiles`.

| File trong `assets/tiles/` | Màu | Biểu tượng | Ý nghĩa |
|---|---|---|---|
| `tile_red.png` | Đỏ ruby | Kiếm | Sát thương |
| `tile_green.png` | Xanh lá emerald | Lá cây | Hồi máu |
| `tile_yellow.png` | Vàng hổ phách | Đồng xu | Vàng |
| `tile_purple.png` | Tím amethyst | Pha lê | Phá khiên |

Mỗi file là PNG RGBA 128×128 px, có khoảng đệm trong suốt. Biểu tượng khác nhau giúp nhận diện mà không chỉ dựa vào màu. Khung vuông bo góc thống nhất để ghép trên lưới.

## Style guide dùng cho bộ đầu

Fantasy hoạt hình, viền tím sẫm dày, bề mặt đá quý vát cạnh, ánh sáng từ góc trên trái, màu bão hòa, biểu tượng màu ngà lớn. Nhìn thẳng, không chữ, không đổ bóng ngoài ô. Ưu tiên nét rõ khi hiển thị ở 110 px hoặc nhỏ hơn. Đây là đề xuất ban đầu, chưa có style guide hay ảnh anh hùng đã chốt trong repo.

Ảnh được tạo bằng công cụ sinh ảnh; các biến thể dùng ô đỏ làm tham chiếu. Bản xuất được thu về 128×128 px và giữ alpha. Bản gốc độ phân giải cao nằm ngoài checkout trong `/workspace/generated_images/` của phiên tạo ảnh, không phải đường dẫn phụ thuộc khi chạy game.

## Bàn giao

Code có thể nạp trực tiếp các file bằng đường dẫn `res://assets/tiles/tile_<color>.png`. Bộ ảnh chưa được gắn vào bàn chơi vì checkout hiện chưa có scene hay script. B1–B2 vẫn có thể dùng ô màu tạm theo kế hoạch. Không thay đổi cấu hình project, scene, code hoặc tests trong nhánh ảnh này.
