Đã hoàn thành bộ ảnh issue #5 trên nhánh **art/characters**, tạo từ main tại **0d24119f2dbd84ed024c46fd460f728549a68599**. Chỉ thêm assets/ và docs/ideas/; không sửa scripts/, scenes/, tests/, project.godot; không đẩy gh-pages.

Theo phản hồi trực tiếp của người dùng, dùng **ảnh anh hùng gốc làm chuẩn**, giữ khuôn mặt/hàm rộng/tỉ lệ người lớn/nét đổ khối, áo xanh xám, khăn đỏ, quai da đeo chéo. Các bản thử chibi đã loại, không nằm trong bộ bàn giao. Kiếm chuyển sang gỗ theo quy cách tân thủ.

**Đủ 52 PNG + 3 rig.json:**
- hero_rookie: 17 dáng (3 mức × 5 mood + victory/defeat).
- orc_shield: 17 dáng thân không khiên + shield_3/2/1/0; shield_0 trong suốt hoàn toàn.
- scarecrow: 7 dáng, không có tấn công.
- training_field.png và orc_camp.png: 1080×660, sàn đăng ký y=470, phần dưới ít tương phản.
- sweat 128×128; stars 192×96; sparkle 128×128; splinters và straw 256×256.
- Nhân vật/khiên: PNG RGBA 512×512, feet=(256,500), đủ anchors head/mouth từng pose. Khiên Orc dùng tâm [95,319] đo theo ảnh thực, cả bốn lớp cùng canvas/vị trí. Các tên file đúng hợp đồng code hiện có.

**Tự kiểm tra:** 454 kiểm tra ảnh PASS; đã xem lưới từng dáng ở cỡ360px, ba mức tơi tả và chồng bốn lớp khiên trên fresh_idle. Godot4.7.2 import không lỗi/cảnh báo; CharacterRig nạp đúng cả41 pose mới, không fallback hình tạm; đọc đủ3 rig,4 khiên,2 nền,5 FX. Đây là kiểm tra asset/nạp tài nguyên, không thay cho kiểm thử diễn tiến trận sau merge.

**Ảnh xem thử:**

![Thao trường](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/battle_training.png?raw=true)

![Trận Orc Khiên](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/battle_orc.png?raw=true)

![Ba mức tơi tả](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/wear_360.png?raw=true)

[17 dáng hiệp sĩ 360px](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/hero_rookie_360.png) · [17 dáng Orc](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/orc_shield_360.png) · [7 dáng bù nhìn](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/scarecrow_360.png) · [4 lớp khiên](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_review/orc_shield_layers_360.png) · [Bàn giao và cách xem lại](https://github.com/loc169434-design/Brick-hero/blob/art/characters/docs/ideas/issue5_handoff.md).

<details><summary>Danh sách đầy đủ 127 file thêm/đổi</summary>

```text
assets/bg/orc_camp.png
assets/bg/orc_camp.png.import
assets/bg/training_field.png
assets/bg/training_field.png.import
assets/characters/hero_rookie/battered_attack.png
assets/characters/hero_rookie/battered_attack.png.import
assets/characters/hero_rookie/battered_cheer.png
assets/characters/hero_rookie/battered_cheer.png.import
assets/characters/hero_rookie/battered_hurt.png
assets/characters/hero_rookie/battered_hurt.png.import
assets/characters/hero_rookie/battered_idle.png
assets/characters/hero_rookie/battered_idle.png.import
assets/characters/hero_rookie/battered_scared.png
assets/characters/hero_rookie/battered_scared.png.import
assets/characters/hero_rookie/bruised_attack.png
assets/characters/hero_rookie/bruised_attack.png.import
assets/characters/hero_rookie/bruised_cheer.png
assets/characters/hero_rookie/bruised_cheer.png.import
assets/characters/hero_rookie/bruised_hurt.png
assets/characters/hero_rookie/bruised_hurt.png.import
assets/characters/hero_rookie/bruised_idle.png
assets/characters/hero_rookie/bruised_idle.png.import
assets/characters/hero_rookie/bruised_scared.png
assets/characters/hero_rookie/bruised_scared.png.import
assets/characters/hero_rookie/defeat.png
assets/characters/hero_rookie/defeat.png.import
assets/characters/hero_rookie/fresh_attack.png
assets/characters/hero_rookie/fresh_attack.png.import
assets/characters/hero_rookie/fresh_cheer.png
assets/characters/hero_rookie/fresh_cheer.png.import
assets/characters/hero_rookie/fresh_hurt.png
assets/characters/hero_rookie/fresh_hurt.png.import
assets/characters/hero_rookie/fresh_idle.png
assets/characters/hero_rookie/fresh_idle.png.import
assets/characters/hero_rookie/fresh_scared.png
assets/characters/hero_rookie/fresh_scared.png.import
assets/characters/hero_rookie/rig.json
assets/characters/hero_rookie/victory.png
assets/characters/hero_rookie/victory.png.import
assets/characters/orc_shield/battered_attack.png
assets/characters/orc_shield/battered_attack.png.import
assets/characters/orc_shield/battered_cheer.png
assets/characters/orc_shield/battered_cheer.png.import
assets/characters/orc_shield/battered_hurt.png
assets/characters/orc_shield/battered_hurt.png.import
assets/characters/orc_shield/battered_idle.png
assets/characters/orc_shield/battered_idle.png.import
assets/characters/orc_shield/battered_scared.png
assets/characters/orc_shield/battered_scared.png.import
assets/characters/orc_shield/bruised_attack.png
assets/characters/orc_shield/bruised_attack.png.import
assets/characters/orc_shield/bruised_cheer.png
assets/characters/orc_shield/bruised_cheer.png.import
assets/characters/orc_shield/bruised_hurt.png
assets/characters/orc_shield/bruised_hurt.png.import
assets/characters/orc_shield/bruised_idle.png
assets/characters/orc_shield/bruised_idle.png.import
assets/characters/orc_shield/bruised_scared.png
assets/characters/orc_shield/bruised_scared.png.import
assets/characters/orc_shield/defeat.png
assets/characters/orc_shield/defeat.png.import
assets/characters/orc_shield/fresh_attack.png
assets/characters/orc_shield/fresh_attack.png.import
assets/characters/orc_shield/fresh_cheer.png
assets/characters/orc_shield/fresh_cheer.png.import
assets/characters/orc_shield/fresh_hurt.png
assets/characters/orc_shield/fresh_hurt.png.import
assets/characters/orc_shield/fresh_idle.png
assets/characters/orc_shield/fresh_idle.png.import
assets/characters/orc_shield/fresh_scared.png
assets/characters/orc_shield/fresh_scared.png.import
assets/characters/orc_shield/rig.json
assets/characters/orc_shield/shield_0.png
assets/characters/orc_shield/shield_0.png.import
assets/characters/orc_shield/shield_1.png
assets/characters/orc_shield/shield_1.png.import
assets/characters/orc_shield/shield_2.png
assets/characters/orc_shield/shield_2.png.import
assets/characters/orc_shield/shield_3.png
assets/characters/orc_shield/shield_3.png.import
assets/characters/orc_shield/victory.png
assets/characters/orc_shield/victory.png.import
assets/characters/scarecrow/battered_hurt.png
assets/characters/scarecrow/battered_hurt.png.import
assets/characters/scarecrow/battered_idle.png
assets/characters/scarecrow/battered_idle.png.import
assets/characters/scarecrow/bruised_hurt.png
assets/characters/scarecrow/bruised_hurt.png.import
assets/characters/scarecrow/bruised_idle.png
assets/characters/scarecrow/bruised_idle.png.import
assets/characters/scarecrow/defeat.png
assets/characters/scarecrow/defeat.png.import
assets/characters/scarecrow/fresh_hurt.png
assets/characters/scarecrow/fresh_hurt.png.import
assets/characters/scarecrow/fresh_idle.png
assets/characters/scarecrow/fresh_idle.png.import
assets/characters/scarecrow/rig.json
assets/fx/battle/sparkle.png
assets/fx/battle/sparkle.png.import
assets/fx/battle/splinters.png
assets/fx/battle/splinters.png.import
assets/fx/battle/stars.png
assets/fx/battle/stars.png.import
assets/fx/battle/straw.png
assets/fx/battle/straw.png.import
assets/fx/battle/sweat.png
assets/fx/battle/sweat.png.import
docs/ideas/issue5_comment.md
docs/ideas/issue5_files_changed.txt
docs/ideas/issue5_handoff.md
docs/ideas/issue5_pack.mjs
docs/ideas/issue5_registration.json
docs/ideas/issue5_review.html
docs/ideas/issue5_review/.gdignore
docs/ideas/issue5_review/battle_orc.png
docs/ideas/issue5_review/battle_training.png
docs/ideas/issue5_review/data.js
docs/ideas/issue5_review/fx.png
docs/ideas/issue5_review/hero_rookie_360.png
docs/ideas/issue5_review/metrics.json
docs/ideas/issue5_review/orc_shield_360.png
docs/ideas/issue5_review/orc_shield_layers_360.png
docs/ideas/issue5_review/rig_review.png
docs/ideas/issue5_review/scarecrow_360.png
docs/ideas/issue5_review/wear_360.png
docs/ideas/issue5_sources.json
docs/ideas/issue5_verify.mjs
```

</details>
