# Sửa nhỏ cho bộ rig v2 (Claude ghi sau khi ráp vào game)

Bộ `art/hero-rig-v2` đã ráp vào `core/world-life`: đầu thay nguyên ảnh theo nón và biểu cảm, ba giáp mới có trong lò rèn. Các động tác đứng, chém, trúng đòn, mừng đã chạy với ảnh thật (`ingame_poses.png`).

Còn hai lỗi ảnh, chỉ thấy khi xoay khớp trong game (bài kiểm tra xoay ±35° của bản v2 không bắt được vì nó chỉ xét vòng 20 px quanh tâm khớp):

1. **Thân thiếu phần vẽ lót dưới tay khiên.** Khi `shield_arm_upper` xoay 16–18° thì hở lỗ trong suốt giữa khiên, thân và đùi (`shield_arm_holes.png`, ảnh 1 và 4). Cần vẽ lót `torso.png` (và lớp giáp thân của cả 5 bộ giáp) ở toàn bộ vùng bị tay khiên che lúc đứng, để tay xoay tới ±35° vẫn thấy áo/giáp liền. Tạm thời code chỉ cho tay khiên xoay tối đa khoảng 5°.
2. **Vai tay kiếm có răng cưa trắng** ở khớp `shoulder_sword` khi chém (`ingame_poses.png`, ảnh 2). Mép trên `sword_arm_upper` và lớp giáp vai cần vẽ lót tròn, hết viền trắng sót lại.

Kiểm tra lại: xoay từng mảnh tay/chân quanh khớp ±35° và đếm pixel trong suốt **trong toàn bộ hình bóng lúc đứng** (không chỉ trong vòng 20 px).
