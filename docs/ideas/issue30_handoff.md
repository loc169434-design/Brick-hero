# Issue #30 — biểu tượng trang bị và hoạt hình thợ rèn

Nhánh `art/gear`, tạo từ `main` tại `fb87b63`. Phạm vi được yêu cầu: **phần 1 và phần 3**. Phần 2 (thay kiếm/nón trên mọi hoạt hình hiệp sĩ) chưa thực hiện, chờ duyệt phần 1 theo issue. Chỉ sửa `assets/` và `docs/ideas/`, không sửa code game, scene hoặc test.

## Phần 1 — bốn biểu tượng

Trong `assets/ui/items/`, PNG RGBA 256×256, nền trong suốt, viền nâu đậm, không chữ/số/+:

- `leather_helmet.png`: mũ da tròn có quai và đường khâu.
- `iron_helmet.png`: mũ sắt xám có sống mũ, đinh tán.
- `climbing_boots.png`: đôi ủng cao cổ, dây buộc, đế răng cưa và móc sắt.
- `sword_refine.png`: búa chạm lưỡi kiếm trên đe, tóe lửa; +1/+2/+3 do code chồng sau.

![Biểu tượng ở cỡ lớn và 64px](gear_review/items.png)

[Kiểm tra kích thước, alpha, biên và SHA-256](gear_review/part1_checks.json). Preview PNG 88.742 byte, dưới 2 MB. Sáu biểu tượng có sẵn không thay đổi. Các icon mới được vẽ theo hình tham chiếu hiện có rồi tách/chuẩn hóa từng ô, không dùng lại một icon cũ để thay tên món.

### Nội dung comment phần 1

Phần 1 đã có trên `art/gear`: bốn icon leather_helmet/iron_helmet/climbing_boots/sword_refine, RGBA 256×256, không chữ, cùng kiểu viền nâu với bộ cũ. [Ảnh duyệt cỡ lớn và 64px](https://github.com/loc169434-design/Brick-hero/blob/art/gear/docs/ideas/gear_review/items.png) · [Bàn giao và kiểm tra](https://github.com/loc169434-design/Brick-hero/blob/art/gear/docs/ideas/issue30_handoff.md). Phần 2 chưa làm, đúng yêu cầu chờ duyệt; phần 3 thợ rèn được làm cùng đợt này theo yêu cầu bổ sung.
