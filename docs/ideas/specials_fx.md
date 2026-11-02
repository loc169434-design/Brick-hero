# Hiệu ứng ô đặc biệt và font

Nhánh `art/specials-fx`, tạo từ main `b4c61d7`. Bộ này chỉ thêm asset và trang xem hình; Claude ghép vào resolver/BoardView sau khi duyệt.

## File game dùng

| PNG trong `assets/fx/specials/` | Khung | Khung hoạt ảnh | Atlas |
|---|---|---:|---|
| lightning_beam.png | 256×96 | 8 | 2048×96 |
| lightning_hub.png | 256×256 | 8 | 2048×256 |
| bomb_blast.png | 512×512 | 12 | 4096×1024 |
| star_burst.png | 512×512 | 12 | 4096×1024 |
| star_spark.png | 192×192 | 8 | 1536×192 |
| fusion_flash.png | 512×512 | 8 | 4096×512 |

`specials.json` dùng tên PNG làm khóa; mỗi mục gồm `frame_width`, `frame_height`, `frames`, `fps:24`, `loop:false`. Đọc khung i tại `(i%8*w, floor(i/8)*h)`, gốc vẽ ở tâm khung. Khung cuối hoàn toàn trong suốt; bốn ô dư trên hàng thứ hai của atlas 12 khung cũng trống. Một lượt phát dài 8/24 hoặc 12/24 giây; không tự lặp trong game.

Sét, bom và fusion là ảnh xám có lõi sáng/viền tối để nhân màu bằng modulate. Sao giữ màu cầu vồng. Không nhân alpha hai lần khi tô màu.

Đoạn sét có cột alpha/RGB đầu và cuối giống hệt nhau; hai đầu nằm y=48. Lặp đoạn 256px dọc toàn hàng; xoay 90° rồi lặp dọc toàn cột. Crop ở rìa bảng, đặt hub tại giao điểm. Bom vẽ ở kích thước 512px, tâm ô bom: phần ảnh gồm tia/khói ngoài vùng tác động 3×3=420px. Vùng tác động do luật quyết định, không suy ra từ alpha vụ nổ. Sao dùng burst tại nguồn và spark trên từng ô bị xóa cùng màu. Fusion đặt tại tâm cặp đặc biệt; vùng xóa tùy loại cặp do code quyết định.

## Font và giấy phép

`assets/fonts/baloo_2_extra_bold.ttf`: Baloo 2, weight 800, font miễn phí SIL Open Font License 1.1. Giữ nguyên thông tin tác giả/giấy phép trong font; kèm `assets/fonts/OFL.txt`.

Nguồn chính thức: [Google Fonts / ofl/baloo2](https://github.com/google/fonts/tree/main/ofl/baloo2). File tải: [Baloo2[wght].ttf](https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/Baloo2%5Bwght%5D.ttf), [OFL.txt](https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/OFL.txt). FontTools tạo static instance tại weight 800 để nạp trực tiếp, không yêu cầu biến trục ở runtime. Tên file đổi để dễ dùng; không sửa glyph. OFL nguồn không khai báo Reserved Font Name.

Đã kiểm tra 136 codepoint gồm vùng tiếng Việt U+1EA0–U+1EF9, Đ/đ, các nguyên âm có mũ/móc và dấu kết hợp: không thiếu. [Thông số và SHA256](specials_font_metrics.json). [Ảnh đủ tám chuỗi thử](specials_fx_review/font_samples.png), gồm `Ữ Ỗ Ặ Ẫ Ợ`; đã xem trực tiếp dấu trên/dưới.

## Xem thử, tái xuất và giới hạn

[Trang xem hoạt ảnh](specials_fx_review.html) nạp sáu atlas cuối trên 56 gạch Orc thật, canvas 980×1120, ô140px. Có chọn màu, dừng, kéo khung; đường viền minh họa cả hàng/cột hoặc đúng 420×420px của bom. Mở qua máy chủ tĩnh ở gốc repo nếu trình duyệt hạn chế file cục bộ.

Nguồn raster do công cụ vẽ tạo nằm ở `specials_fx_sources/`; `specials_fx.js` chỉ biến đổi scale/rotate/fade theo thời gian để xuất sprite. Chạy `node docs/ideas/specials_fx_build.mjs` với Node, Playwright, Chromium, ImageMagick để tái xuất PNG và ảnh bằng chứng. Không cần công cụ này khi chơi game.

[Kết quả kiểm tra](specials_fx_review/metrics.json): kích thước atlas, khung cuối trống và hai mép sét giống nhau; ảnh bằng chứng [sét](specials_fx_review/lightning.png), [bom](specials_fx_review/bomb.png), [sao](specials_fx_review/star.png), [fusion](specials_fx_review/fusion.png). Đây là xác minh asset/hiển thị, chưa kiểm việc kích nổ trong trận thật. Hình tĩnh được animate bằng biến đổi, chưa phải mỗi khung vẽ tay riêng. Cần Claude thử nhịp 24fps và cách tô màu trong Godot/điện thoại trước khi chốt cảm giác; atlas kích thước lớn cần kiểm ngân sách texture thiết bị.

Danh sách đầy đủ file mới nằm trong `specials_fx_files.txt`; không sửa code game, scene, tests hay project.
