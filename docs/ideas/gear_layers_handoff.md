# Lớp trang bị hiệp sĩ — đợt 1, bản nháp chưa đủ bộ

Nhánh `art/gear-layers`, tạo từ `main` tại `6604efa` (đã ghép PR #53).
Đã đọc `AGENTS.md`, `docs/core_plan.md`, issue #30 và quy ước mức tơi tả ở issue #24. Yêu cầu lớp trong cuộc trò chuyện này thay cho cách làm biến thể nguyên người / tọa độ nón ở mô tả cũ của #30.

**Trạng thái: chưa hoàn thành; chưa đề nghị ghép vào game.** Có 26 atlas lớp để tiếp tục chỉnh và xem thử. Còn thiếu 4 atlas kiếm `attack`, và chưa duyệt chất lượng khớp viền của toàn bộ bộ đồ. Không có file trong suốt giả làm lớp kiếm còn thiếu.

## Đã lưu

Trong `assets/characters/hero_rookie/anim/layers/`:

| Lớp | idle | attack |
|---|---|---|
| body | fresh, bruised, battered | fresh, bruised, battered |
| wood_sword | fresh, battered; bruised dùng fresh | **thiếu** |
| iron_sword, tempered_sword | fresh; mức khác dùng fresh | **thiếu** |
| leather_armor, iron_armor | fresh, dùng chung mức | fresh, dùng chung mức |
| leather_helmet, iron_helmet | fresh, dùng chung mức | fresh, dùng chung mức |
| reinforced_boots, climbing_boots | fresh, dùng chung mức | fresh, dùng chung mức |

Các kiếm idle còn có lớp `<món>_back` tương ứng, chứa phần chuôi sau ngón tay; lớp kiếm trước có khoảng trống ở ngón tay. Khiên tròn thuộc body. Body không có kiếm, nón, giáp, giáp tay da hay ủng; dùng áo vải xanh viền kem, dây buộc vải và giày vải mỏng. Mức tơi tả có vết bầm, miếng vá, vết sờn vải / khăn, khiên nứt; battered thêm miếng mẻ nhỏ ở mép khiên. Kiếm gỗ battered idle là đoạn gỗ gãy, không phải kiếm nguyên.

Tất cả atlas dùng PNG RGBA, 4 cột, cel 512×512; idle 8 khung / 12 fps, attack 12 khung / 24 fps, giữ 5–6 cùng cel chạm. Không sửa metadata clip cũ. Điểm đăng ký đất là (256,500); phép kiểm tra x dùng trung điểm khoảng chiếm chỗ của hai chân trong phần thấp của cel, y dùng đáy nét chân. Đây là phép kiểm tra đăng ký ảnh, không phải track dịch chuyển cho runtime.

## Xem và ghép

[Thư mục ảnh kiểm tra](gear_layers_review/README.md) có 6 GIF, mỗi clip đủ 3 mức. Mỗi GIF đặt cạnh nhau: không đồ / giáp da + nón da + ủng gia cố + kiếm sắt / giáp sắt + nón sắt + ủng leo núi + kiếm thép. **GIF attack ghi rõ thiếu kiếm**; hai ô có trang bị chỉ là bản xem giáp / nón / ủng, chưa phải bộ đồ bàn giao hoàn chỉnh. Có lưới đánh số cho từng clip, mức và bộ đồ.

Thứ tự chồng: các `_back` → body → ủng → giáp → nón → kiếm. Tất cả ảnh lớp cuối đã đăng ký sẵn trên cùng cel: chồng tại **(0,0)**, không dịch, không xoay, không thu phóng riêng món ở runtime. Chỉ thu nhỏ *hình đã ghép xong* khi xuất ảnh xem thử.

```bash
python docs/ideas/gear_layers_review/compose_frame.py idle fresh 7 iron /tmp/gear_frame.png
python docs/ideas/gear_layers_review/validate_layers.py
```

Helper ghép đọc chính các PNG đã bàn giao. Nếu một món không có mức yêu cầu thì dùng fresh; nếu cả hai không có thì báo lỗi, không giấu thiếu. Kiểm tra đầy đủ trả mã **1** khi còn thiếu atlas; xem [kết quả kỹ thuật](gear_layers_review/technical_checks.json). Bộ test game có kết quả riêng, không dùng kết quả ấy để chứng minh ảnh đã khớp viền.

Đã chạy import bằng Godot 4.7.2, dùng VRAM compression cho các lớp mới; không có lỗi import / script trong log. Bộ test hiện có chạy đủ: **121 passed, 0 failed**. Validator lớp kiểm tra 26 atlas, không có lỗi kỹ thuật ở số ảnh hiện có, nhưng vẫn trả **1** vì thiếu bốn atlas kiếm attack. Bảy GIF và mọi PNG xem thử đều dưới 2.000.000 byte.

## Còn phải làm

1. `wood_sword/fresh_attack.png`, `wood_sword/battered_attack.png`, `iron_sword/fresh_attack.png`, `tempered_sword/fresh_attack.png`; thêm `_back` ở khung đi sau thân nếu cần. Bruised được dùng fresh khi hình không đổi.
2. Duyệt và chỉnh nón ở các góc đầu khác nhau, vùng cổ / tay / khiên của giáp, viền ủng với giày vải. Việc giữ nguyên alpha của thân dưới món không tự chứng minh rằng viền món đã ăn khớp như một bức vẽ liền.
3. Chỉnh đường biên tơi tả bằng tay nếu cần: hiện dùng các nét hỏng / vá đã vẽ làm decal đăng ký lên thân; chưa phải vẽ lại toàn bộ đường biên áo / khăn rách theo từng cel.
4. Xuất lại GIF attack có đủ kiếm, kiểm tra lại toàn bộ chồng lớp rồi mới đề nghị ghép.

Công cụ tạo ảnh đã từ chối yêu cầu tạo lớp kiếm attack với nhãn `violence` (request ID `42eddc36-22c7-4519-b2b2-1753ac6076a4`). Không đổi cách diễn đạt để lách từ chối đó; phần tạo tranh này còn bị chặn. Các yêu cầu nón / ủng / chất liệu hỏng độc lập vẫn tạo được và đã tiếp tục xử lý.

Nguồn tranh là công cụ tạo ảnh có tham chiếu bộ hiệp sĩ PR #53. Khâu chuẩn bị ảnh có cắt nguyên cel, đăng ký / nội suy tranh món vào vùng đầu / thân / chân và tạo matte che khuất trước khi lưu PNG; đây là xử lý **offline**, không phải tọa độ / phép xoay cần áp dụng trong game. Không mô tả bộ này là toàn bộ tranh do người vẽ thủ công. `validation.json` lưu hash tranh nguồn và hash PNG lớp.

Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot` hay ảnh hoạt hình gốc. Code game hiện chưa đọc thư mục lớp; phần nối bộ đồ với renderer thuộc nhiệm vụ code riêng.
