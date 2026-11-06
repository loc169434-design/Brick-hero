Bản nháp lớp trang bị đợt 1 trên nhánh [`art/gear-layers`](https://github.com/loc169434-design/Brick-hero/tree/art/gear-layers), tạo từ main sau PR #53. Yêu cầu mới dùng atlas lớp đã đăng ký sẵn, thay cho biến thể nguyên người / track nón của mô tả cũ.

- Có 26 atlas: body ba mức cho idle / attack; hai giáp, hai nón, hai ủng; ba kiếm cho idle và kiếm gỗ gãy battered idle, kèm lớp chuôi sau ngón tay.
- [GIF, lưới đánh số và kiểm tra](https://github.com/loc169434-design/Brick-hero/tree/art/gear-layers/docs/ideas/gear_layers_review). Bảy GIF đều dưới 2 MB. GIF attack ghi rõ phần kiếm còn thiếu.
- [Bàn giao và danh sách còn phải làm](https://github.com/loc169434-design/Brick-hero/blob/art/gear-layers/docs/ideas/gear_layers_handoff.md).

**Chưa hoàn thành, chưa đề nghị ghép vào game.** Thiếu wood_sword fresh/battered attack, iron_sword fresh attack và tempered_sword fresh attack. Công cụ tạo ảnh từ chối yêu cầu lớp kiếm attack với nhãn `violence`; phần tạo tranh này còn bị chặn. Nón / giáp / ủng và đường biên tơi tả vẫn cần duyệt, chỉnh bằng mắt để đạt yêu cầu không lệch / không lộ khe.

Import Godot 4.7.2 thành công; 121/121 test game đạt. Validator lớp: 26 atlas hiện có đạt kiểm tra kỹ thuật, nhưng trả lỗi đầy đủ vì còn thiếu bốn atlas. Không sửa code, scene, test hay cấu hình game.
