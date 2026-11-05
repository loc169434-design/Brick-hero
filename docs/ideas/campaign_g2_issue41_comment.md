Đã hoàn thành ảnh theo issue #41, chỉ sửa assets/ và docs/ideas/.

- Phần 0 trên `art/campaign-100-g1`: sửa overlap 200 px, victory Tù Trưởng, lem Kỵ Lợn và thêm bà lão ăn xin. Chương 1 nét V2 ở `46d7f0b`; người dùng đã trả lời **“Duyệt V2”**. Đã áp nét đó cho đủ 6 khung chương 2, push `5725afb`.
- G2 trên `art/campaign-100-g2`: 10 dạng quái, 65 clip nhân vật/NPC, 340 cel, gạch, vật cản, hai nền nhiều lớp, map 19–36, NPC, **7 khung chương 3** sau màn 36. Giữ nét bút phác và màu tô thưa V2; toàn bộ ảnh xem thử GIF/JPG dưới 2 MB, nguồn lớn ngoài repo.
- Kiểm G1 560/560, Phần 0 97/97, chương 2 45/45; kiểm G2 1.163/1.163, chương 3 49/49; Godot smoke tải đủ clip và truyện, 0 failures; suite hiện có 93/93.

[Chương 2](https://github.com/loc169434-design/Brick-hero/blob/art/campaign-100-g1/docs/ideas/issue41_chapter2_review/webtoon.jpg) · [Chương 3](https://github.com/loc169434-design/Brick-hero/blob/art/campaign-100-g2/docs/ideas/issue41_chapter3_review/webtoon.jpg) · [Bàn giao G2](https://github.com/loc169434-design/Brick-hero/blob/art/campaign-100-g2/docs/ideas/campaign_g2_handoff.md) · [Gallery G2](https://github.com/loc169434-design/Brick-hero/blob/art/campaign-100-g2/docs/ideas/campaign_g2_review/index.md).

Tích hợp G1 trước G2; giữ map segment_02 của G2 để nối đúng đoạn 3. Chưa merge hoặc tích hợp gameplay; phần code thuộc Claude. Nội dung này được lưu sẵn vì GitHub GraphQL từ chối tạo PR/comment (`Forbidden`), chưa đăng lên issue.

Đợt sửa sau `10ccc4c`: đóng lại đủ bộ cá sấu, làm sạch Mụ Cóc attack 2–3; thêm luật liên thông toàn bộ 340 ô, từ chối mảnh lớn >200 pixel trừ mask hiệu ứng đã đối chiếu. Đã kiểm luật bắt đủ 18 ô lỗi cũ và xử lý thêm mảnh lẫn ô cùng nguyên nhân ở các actor khác. Xem `docs/ideas/issue41_atlas_repair.md`.
