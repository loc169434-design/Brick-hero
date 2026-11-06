# Issue #49 — world life

Nhánh `art/world-life` từ main **`cb34881`**, đã có nền và Cóc B của `05ad58a`. Phần Nhấc Gạch/Orc nổi điên #48 đã push riêng ở `2e7834c` trước khi bắt đầu #49. Chỉ sửa `assets/` và `docs/ideas/`, giữ nhân vật và nét game.

## 1. Bảng Lượt

`assets/ui/hud/turn_plaque.png`: **360×116**, gỗ óc chó tối, viền vàng, tâm trống. Vùng đặt chữ gợi ý `[22,18,316,80]` (x,y,w,h); không có chữ vẽ sẵn. `sword_left.png` và `sword_right.png`: **160×160**, một kiếm mỗi PNG, chuôi/cản vàng, mũi lên và nghiêng nhẹ sang hai phía. Code chồng/xoay để tạo từng cặp kiếm. `clash_spark.png`: **6 cel 160×160**, ba cột, **24 fps**, không lặp; khai báo trong `anim.json`. `hud_manifest.json` ghi kích thước/mốc tâm.

[GIF bảng + hai cặp kiếm chạm mỗi 2 giây](world_life_review/hud/turn_plaque_clash.gif) · [ảnh tĩnh](world_life_review/hud/turn_plaque_preview.jpg) · [tia lửa](world_life_review/hud/clash_spark.gif).

Chữ “Lượt 12”, động tác xoay và ghép tia lửa chỉ dùng trong ảnh xem thử. Claude nối PNG vào HUD, giữ phần đếm lượt trong code. Tất cả preview dưới 2 MB.
