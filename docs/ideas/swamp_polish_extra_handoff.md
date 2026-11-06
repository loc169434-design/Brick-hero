# Issue #48 — bổ sung Nhấc Gạch và Orc nổi điên

Tiếp nhánh `art/swamp-polish` sau `05ad58a` (nền và 392 khung gạch Cóc B). Chỉ sửa `assets/` và `docs/ideas/`. Main lúc bắt đầu vẫn chưa nhập PR #47; metadata Mụ Cóc và curse được lấy từ đầu PR #47 `e35ebff4` để giữ đủ các clip/phép cũ. Các ảnh cũ của Mụ Cóc do PR #47 cung cấp; nhánh này bổ sung clip mới.

- **Mụ Cóc:** `assets/characters/toad_witch/anim/fresh_lift.png`, 12 khung, 14 fps, `impact=6`, không lặp. Cùng bà phù thủy mặt người, tóc bạc, mũ lá sen/hoa hồng, áo tím, cóc nhỏ trên vai, đũa nấm. Khung 0–5 nhấc đũa/phát sáng và đưa tay nâng; khung 6 vung kèm nét nhòe tím; 7–11 cười rồi trở về dáng đứng. [GIF](swamp_polish_extra_review/toad_witch_lift.gif).
- **Vòng phép:** `assets/fx/curse/levitate.png`, 8 khung, 12 fps, lặp, tâm trong suốt để quấn quanh ô. [GIF](swamp_polish_extra_review/levitate.gif) · [ghép cảnh phép và ô](swamp_polish_extra_review/lift_scene.gif).
- **Bốn Orc:** `assets/characters/{orc_shield,orc_rock,orc_drummer,orc_boar}/anim/fresh_rage.png`, mỗi clip 10 khung, 12 fps, không lặp. Gồng, gầm ngửa mặt, mắt đỏ, hơi nóng, hạ về thế đứng giận dữ. Giữ nguyên thiết kế/trang phục/đạo cụ, gồm cả lợn cưỡi. [Mũ da](swamp_polish_extra_review/orc_shield_rage.gif) · [túi đá](swamp_polish_extra_review/orc_rock_rage.gif) · [đánh trống](swamp_polish_extra_review/orc_drummer_rage.gif) · [cưỡi lợn](swamp_polish_extra_review/orc_boar_rage.gif).
- **Hơi nóng:** `assets/fx/combat/anim/rage_steam.png`, 8 khung, 12 fps, lặp, chồng phía trên đầu khi trạng thái nổi điên tiếp tục. [GIF](swamp_polish_extra_review/rage_steam.gif).

Tất cả atlas bốn cột, cel **512×512**; nhân vật giữ gốc chân **(256,500)**. Mỗi sheet dùng một tỉ lệ cố định, không thu/phóng theo từng tư thế; mốc chân được đăng ký khi ghép. Tám GIF đều dưới 2 MB, lớn nhất ~701 KB. Đã thêm `clips.lift`/`clips.rage` và hai entry FX vào các `anim.json`, giữ nguyên mọi entry cũ.

Claude thay clip mượn `cast_broom` bằng `lift`, đồng bộ cú ném ở impact 6, dùng `levitate` trên ô đang được nhấc. Khi Orc đi qua ngưỡng máu 30%, chạy `rage` một lần rồi tiếp tục trạng thái nóng giận/overlay steam theo code. Các cel rage đã có vài vệt hơi nóng ngắn, overlay dùng cho hơi nóng tiếp diễn.

Đã kiểm tra **52 cel nhân vật +16 cel FX**, không chạm mép ô. Luật alpha nối 8 hướng, alpha>32, phát hiện phần rời >200 px; chỉ 28 vệt hơi nóng trên đầu ở rage 6–8 đã được xem và lưu **mask hash chính xác** trong `swamp_polish_extra_fx_masks.json`. Không có ngoại lệ chung cho thân, chân, đuôi hoặc vũ khí. [Kết quả](swamp_polish_extra_review/validation.json).

Nguồn gốc và hash/crop/đăng ký khung: `swamp_polish_extra_sources.json`; nguyên bản giữ ngoài repo. Chỉ cắt cả hình, căn/chỉnh kích thước toàn sheet và ghép atlas, không tô lại bằng mã.

```bash
python docs/ideas/pack_swamp_polish_extra.py
python docs/ideas/check_swamp_polish_extra.py
godot --headless --path . --editor --import
godot --headless --path . --script res://docs/ideas/swamp_polish_extra_resource_smoke.gd
```

Dùng Godot 4.7.2. [Smoke](swamp_polish_extra_review/resource_smoke.log) · [suite game](swamp_polish_extra_review/godot_tests.log).
