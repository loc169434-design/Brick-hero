# Quái đợt 2 — kết quả kiểm

Nhánh `art/monsters-2` từ `e68e8554e5164e486d15e968523817557492f550`. Chỉ sửa ảnh và hồ sơ trong phạm vi cho phép. RGB được sinh từ ảnh tham chiếu; assemble.py chỉ cắt/sắp lưới với hệ số cố định trong mỗi clip, key_out.py tạo alpha. Không thay anim.json.

Vòng gồm bản đầu (1); vòng sau là sửa bố cục/đồ mang theo/mép nguồn hoặc neo chân. Tối đa 5 vòng. Đỉa special sửa mảnh ô cạnh rồi thêm lề; witch attack sửa neo chân; lift bỏ đồ thừa rồi thêm lề đầu gậy; shield defeat sửa bố cục rồi hướng ngã. Các sheet sửa lề nguồn được kiểm lại sau key_out. Defeat dùng --airborne.

| Quái | Sheet | Kiểm | Vòng | Cao 0 / mẫu | Chân đầu/cuối (y,x) |
|---|---|---|---:|---|---|
| goblin_archer | special | ĐẠT | 1 | frame 0 body 391 px tall, reference 391 | [499.0, 254.5] / [500.0, 259.5] |
| goblin_thief | victory | ĐẠT | 1 | frame 0 body 385 px tall, reference 385 | [500.0, 259.5] / [500.0, 260.0] |
| scarecrow | defeat | ĐẠT | 1 | frame 0 body 437 px tall, reference 438 | [500.0, 256.5] / [500.0, 152.0] |
| scarecrow_straw_shield | defeat | ĐẠT | 3 | frame 0 body 439 px tall, reference 439 | [500.0, 256.0] / [500.0, 256.5] |
| scarecrow_straw_shield | hurt | ĐẠT | 1 | frame 0 body 439 px tall, reference 439 | [500.0, 256.5] / [500.0, 256.5] |
| scarecrow_straw_shield | idle | ĐẠT | 1 | frame 0 body 439 px tall, reference 439 | [499.0, 256.5] / [500.0, 256.5] |
| scarecrow_wood | attack | ĐẠT | 2 | frame 0 body 434 px tall, reference 434 | [500.0, 256.5] / [500.0, 256.0] |
| scarecrow_wood | defeat | ĐẠT | 1 | frame 0 body 434 px tall, reference 434 | [500.0, 256.0] / [500.0, 269.5] |
| scarecrow_wood | hurt | ĐẠT | 1 | frame 0 body 434 px tall, reference 434 | [500.0, 256.0] / [500.0, 256.0] |
| scarecrow_wood | idle | ĐẠT | 2 | frame 0 body 432 px tall, reference 434 | [499.0, 256.0] / [500.0, 256.5] |
| scarecrow_wood | victory | ĐẠT | 1 | frame 0 body 434 px tall, reference 434 | [500.0, 256.0] / [500.0, 256.5] |
| swamp_leech | attack | ĐẠT | 3 | frame 0 body 267 px tall, reference 267 | [500.0, 256.5] / [500.0, 257.0] |
| swamp_leech | defeat | ĐẠT | 1 | frame 0 body 267 px tall, reference 267 | [500.0, 274.5] / [500.0, 258.5] |
| swamp_leech | hurt | ĐẠT | 1 | frame 0 body 267 px tall, reference 267 | [500.0, 276.0] / [499.0, 280.0] |
| swamp_leech | idle | ĐẠT | 1 | frame 0 body 267 px tall, reference 267 | [500.0, 277.5] / [500.0, 278.0] |
| swamp_leech | special | ĐẠT | 4 | frame 0 body 267 px tall, reference 267 | [500.0, 256.5] / [500.0, 256.5] |
| swamp_leech | victory | ĐẠT | 1 | frame 0 body 267 px tall, reference 267 | [500.0, 275.5] / [499.0, 276.0] |
| swamp_spider | attack | ĐẠT | 2 | frame 0 body 236 px tall, reference 236 | [499.0, 256.0] / [500.0, 255.5] |
| swamp_spider | defeat | ĐẠT | 1 | frame 0 body 236 px tall, reference 236 | [500.0, 253.0] / [499.0, 255.5] |
| swamp_spider | hurt | ĐẠT | 1 | frame 0 body 236 px tall, reference 236 | [500.0, 252.5] / [500.0, 253.0] |
| swamp_spider | idle | ĐẠT | 1 | frame 0 body 236 px tall, reference 236 | [500.0, 254.0] / [499.0, 255.5] |
| swamp_spider | special | ĐẠT | 2 | frame 0 body 236 px tall, reference 236 | [500.0, 257.0] / [500.0, 256.5] |
| swamp_spider | victory | ĐẠT | 3 | frame 0 body 236 px tall, reference 236 | [500.0, 256.0] / [500.0, 256.0] |
| toad_spitter | attack | ĐẠT | 1 | frame 0 body 178 px tall, reference 178 | [500.0, 253.0] / [500.0, 253.0] |
| toad_spitter | defeat | ĐẠT | 1 | frame 0 body 178 px tall, reference 178 | [500.0, 254.0] / [500.0, 256.0] |
| toad_spitter | hurt | ĐẠT | 2 | frame 0 body 178 px tall, reference 178 | [500.0, 256.5] / [500.0, 256.5] |
| toad_spitter | idle | ĐẠT | 1 | frame 0 body 178 px tall, reference 178 | [500.0, 253.0] / [500.0, 252.5] |
| toad_spitter | special | ĐẠT | 1 | frame 0 body 178 px tall, reference 178 | [499.0, 252.5] / [499.0, 254.5] |
| toad_spitter | victory | ĐẠT | 1 | frame 0 body 177 px tall, reference 178 | [499.0, 254.0] / [500.0, 254.5] |
| toad_witch | attack | ĐẠT | 3 | frame 0 body 366 px tall, reference 366 | [500.0, 257.5] / [499.0, 256.5] |
| toad_witch | defeat | ĐẠT | 2 | frame 0 body 366 px tall, reference 366 | [500.0, 256.0] / [500.0, 255.5] |
| toad_witch | hurt | ĐẠT | 1 | frame 0 body 366 px tall, reference 366 | [500.0, 256.0] / [500.0, 256.0] |
| toad_witch | idle | ĐẠT | 1 | frame 0 body 365 px tall, reference 366 | [499.0, 256.5] / [500.0, 256.0] |
| toad_witch | lift | ĐẠT | 3 | frame 0 body 366 px tall, reference 366 | [500.0, 256.0] / [500.0, 256.5] |
| toad_witch | special | ĐẠT | 3 | frame 0 body 366 px tall, reference 366 | [500.0, 256.0] / [500.0, 255.5] |
| toad_witch | victory | ĐẠT | 2 | frame 0 body 366 px tall, reference 366 | [500.0, 256.5] / [500.0, 256.5] |
| toad_witch_giant | attack | ĐẠT | 1 | frame 0 body 301 px tall, reference 301 | [500.0, 256.5] / [500.0, 256.5] |
| toad_witch_giant | defeat | ĐẠT | 1 | frame 0 body 301 px tall, reference 301 | [500.0, 256.5] / [500.0, 256.0] |
| toad_witch_giant | hurt | ĐẠT | 1 | frame 0 body 301 px tall, reference 301 | [500.0, 256.0] / [500.0, 256.0] |
| toad_witch_giant | idle | ĐẠT | 1 | frame 0 body 301 px tall, reference 301 | [500.0, 256.5] / [499.0, 256.5] |
| toad_witch_giant | special | ĐẠT | 2 | frame 0 body 301 px tall, reference 301 | [500.0, 256.0] / [500.0, 256.0] |
| toad_witch_giant | victory | ĐẠT | 1 | frame 0 body 301 px tall, reference 301 | [500.0, 256.5] / [500.0, 256.0] |

## Kiểm cuối

- `final_audit.json`: 42/42 sheet ĐẠT, 420 khung; SHA-256 từng PNG và độ lệch chân lớn nhất được lưu. Mọi clip ngoài defeat có lệch chân ngang ≤ 40 px trong toàn bộ khung. Defeat giữ khung đầu chạm đất, cuối nằm xuống.
- Một số clip vươn dài dùng hệ số ngang cố định cho toàn clip: leech attack/special 0,94; witch attack 0,90, special 0,94. Không đổi hệ số theo từng khung; chiều cao ready khớp ref.
- `toad_witch/lift`: khung đầu 366 px so với mẫu 366 px; cỡ thân được giữ trong các tư thế nâng/hất.
- Đã xem contact sheet nền tối và GIF chạy trong Chromium. `browser_review.json`: tải đủ 42 GIF, cả 42 đổi hình qua 4 ảnh chụp, không lỗi trang. Ảnh bằng chứng `gif_review_0.png` đến `gif_review_3.png`. GIF dùng nhịp 10 ms luân phiên để giữ tổng thời lượng ở 12/24 fps.
- Không sửa scripts, scenes, tests, project.godot, anim.json, .import hoặc hero_rookie. Giữ nguyên idle/hurt scarecrow và 8 sheet phép đặc biệt được yêu cầu. Chưa tích hợp/chạy gameplay; không thay metadata hoạt ảnh.

## Chạy lại

Từ gốc repository: `python3 docs/ideas/sprites/monsters2/audit.py`. Lệnh key_out/check_sheet cho mỗi sheet nằm trong assemble.py và log từng clip; layout JSON ghi nguồn, hộp cắt và hệ số. `python3 docs/ideas/sprites/monsters2/review.py` dựng lại bản xem nền tối.

Để xem lại GIF bằng Chromium/Playwright, chạy HTTP server nội bộ từ thư mục monsters2 trên cổng 8820, sau đó từ gốc repo chạy `python3 docs/ideas/sprites/monsters2/browser_review.py`. Trang `review.html` chỉ dùng nội bộ để kiểm art.
