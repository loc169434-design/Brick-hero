# Issue #41 — Phần 0, sửa G1 và duyệt nét truyện

Nhánh `art/campaign-100-g1`, commit tiếp sau `f83b5fc`. Theo [issue #41](https://github.com/loc169434-design/Brick-hero/issues/41). Chỉ sửa `assets/` và `docs/ideas/`.

## Duyệt chương 1

**V2 sau phản hồi “Cần nét mộc hơn nữa”:** đã vẽ lại toàn bộ sáu khung theo nét bút nâu mảnh, có nét dò/đứt, mảng màu tô để lộ giấy và gần như không có bóng. [So trực tiếp V1/V2](issue41_part0_review/chapter1_v1_v2.jpg). V1 ở commit `8241c12` chưa được duyệt; **Người dùng đã duyệt V2: “Duyệt V2”.** Dùng nét này cho chương 2–3. Metadata/source manifest ghi `style_revision: 2` và giữ nguồn ngoài repo.

**[So sánh đủ sáu khung trước/sau](issue41_part0_review/chapter1_before_after.jpg)** (JPG dưới 0,8 MB).

**[Đặt cạnh sprite gốc](issue41_part0_review/chapter1_sprite_comparison.jpg)** · [Đọc bản webtoon mới](issue41_part0_review/chapter1_after_webtoon.jpg).

Giữ sáu sự kiện cũ: luyện kiếm, quà sinh nhật, Bà Tiên xông vào, lời thử, rồng bắt, công chúa thả cánh hoa khi đang bị mang đi. Mỗi khung vẽ riêng theo ảnh mẫu nhân vật game. Viền nâu mảnh có nét dò và chỗ đứt, mảng màu tô thưa để lộ giấy, gần như không có bóng; ít đồ nền, không glow/ánh sáng điện ảnh. Khung xuất rộng 1080, cao lần lượt **540, 720, 1350, 540, 1440, 1484**, khung cuối cắt viền thành ảnh tràn mép. Chừa giấy trống cho thoại do code vẽ.

**V2 đã được duyệt bằng phản hồi “Duyệt V2”. Chương 2 đã vẽ lại đủ sáu khung trên G1; chương 3 nằm trên G2.** [Đọc chương 2](issue41_chapter2_review/webtoon.jpg) · [Trước/sau](issue41_chapter2_review/before_after.jpg) · [Đối chiếu sprite](issue41_chapter2_review/sprite_comparison.jpg). `chapter_01/chapter.json` ghi rõ trạng thái duyệt. Có thể tiếp tục phần quái/vật cản G2 độc lập với việc duyệt truyện.

## Sửa G1

- **Bản đồ**: [trước/sau](issue41_part0_review/map_join_before_after.jpg), [ghép toàn dải](issue41_part0_review/map_combined.jpg). Vẽ lại dải nối bằng công cụ ảnh, không làm mờ/crossfade để che lỗi. `segment_02` 200 px dưới và `segment_01` 200 px trên là cùng một vùng ảnh, khớp hoàn toàn từng pixel. `layout_g1.json` quy định **overlap 200 px**: đoạn trên tại y=0, đoạn dưới tại y=1720; ảnh ghép cao 3640. Không xếp hai ảnh sát nhau ở y=1920 vì sẽ lặp dải nối. Node 7 dịch x sang 610 theo đường mới. Từ đoạn 3 giữ cùng hợp đồng overlap.
- **Tù Trưởng victory**: [trước](issue41_part0_review/chief_victory_before.gif), [sau](issue41_part0_review/chief_victory_after.gif), [bốn khung đánh số](issue41_part0_review/chief_victory_after.jpg). Khung 0 bằng chính xác idle, tiếp theo đứng giơ chùy và cười. Không còn dáng ngồi choáng trong victory.
- **Kỵ Lợn**: công cụ ảnh làm sạch sheet nguồn, đóng lại cùng động tác/số khung. [Idle](issue41_part0_review/boar_idle_after.gif), [attack](issue41_part0_review/boar_attack_after.gif), [defeat](issue41_part0_review/boar_defeat_after.gif). Kiểm tra alpha xác nhận 18 px trái/phải của cả 16 ô thuộc ba clip đều alpha 0. Cập nhật ảnh đứng và các ranh giới về idle cho nhất quán.
- **Bà lão ăn xin màn 10**: `assets/characters/fairy_beggar/`, `idle`, `beg`, `reveal`, mỗi clip **4 khung @8fps**, ô 512×512, atlas 4 cột, chân `(256,500)`, quay trái. [Idle](issue41_part0_review/fairy_beggar_idle.gif), [xin bánh](issue41_part0_review/fairy_beggar_beg.gif), [lộ diện](issue41_part0_review/fairy_beggar_reveal.gif). Reveal kết thúc là bà tiên già đội mũ tím, không tự quay lại lốt ăn xin. Dáng thật đầy đủ và lốt quạ thuộc G2.

## Kiểm tra và tái xuất

- [Kiểm Phần 0](issue41_part0_review/validation.json): overlap trùng pixel, victory bắt đầu idle, lề alpha Kỵ Lợn, clip bà lão, kích thước/chiều cao truyện và mọi preview dưới 2 MB.
- [Godot smoke](issue41_part0_review/resource_smoke.log): **34 clip**, fallback ba mức máu, 12 panel, hai bản đồ, tám icon; **0 failures**.
- [Suite](issue41_part0_review/godot_tests.log): **93 passed, 0 failed**, Godot 4.7.2.
- Nguồn mới lớn để ngoài repo, đường dẫn/SHA-256 ở `issue41_part0_sources.json`. Script chỉ đóng gói, co nguyên hình, cắt dải overlap và ghép ảnh duyệt; không dựng tư thế bằng code.

```sh
python docs/ideas/pack_issue41_part0.py
python docs/ideas/pack_issue41_part0.py --chapter-only # Chỉ tái xuất truyện/ảnh duyệt, giữ các sửa G1 khác
python docs/ideas/check_issue41_part0.py
python docs/ideas/check_campaign_g1.py
godot --headless --editor --path . --import --quit
godot --headless --path . -s res://docs/ideas/campaign_g1_resource_smoke.gd
godot --headless --path . -s res://tests/run_tests.gd
```

Packer G1 gốc gọi lớp sửa Phần 0 cuối cùng, tránh tái xuất đè lại lỗi cũ. Nguồn bên ngoài cần còn tại đường dẫn manifest khi tái xuất; PNG production độc lập khi chơi. Chưa xác nhận gameplay quái mới hoặc chất lượng trên điện thoại. Không thay code/balance/test của Claude.

## Chương 2 theo V2 đã duyệt

Sáu khung riêng rộng 1080, cao 540/720/1350/540/1440/1440; khung cuối tràn mép. Bà lão vẫn là bà tiên già cùng tạo hình, không có cô tiên trẻ trong áo choàng. Hiệp Sĩ Bí Ẩn giữ kín mặt. Giữ diễn biến cho bánh → lộ dáng tiên → bình máu → phá khiên → Tù Trưởng thua → đầm lầy. Nét mực nâu có nét dò, màu marker tô thưa, không gradient/bóng điện ảnh.

[Kiểm truyện](issue41_chapter2_review/validation.json): **45 điều kiện đạt**; [smoke Godot](issue41_chapter2_review/resource_smoke.log): **34 clip, 12 panel, 0 failures**; [suite](issue41_chapter2_review/godot_tests.log): **93 passed, 0 failed**. Kiểm G1 560/560 và Phần 0 97/97 vẫn đạt. Preview lớn nhất 769.988 byte.

Tái xuất riêng: `python docs/ideas/pack_issue41_story.py 2`; kiểm: `python docs/ideas/check_issue41_story.py 2`. Nguồn mới ngoài repo, SHA-256 ở `story_chapter_02_sources.json`. Packer G1 gọi lại lớp sửa Phần 0 và chương 2 ở cuối để không khôi phục tranh cũ. Kiểm tra approval gate cho phép chương sau chỉ khi metadata ghi V2 đã duyệt; không còn yêu cầu giữ nguyên chương 2 sau khi người dùng đã cho phép.
