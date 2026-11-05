# Issue #42 — bộ phép Mụ Phù Thủy Cóc

Nhánh `art/toad-witch-spells` tạo từ G2 đã sửa Cá Sấu, **`2f51e32`**. Theo [issue #42](https://github.com/loc169434-design/Brick-hero/issues/42), chỉ sửa `assets/` và `docs/ideas/`. PNG cũ giữ nguyên từng byte, không thay truyện chương 1–3 V2 đã duyệt.

## Ba GIF ghép cảnh

1. [Ném bình → bình xuống ô → nổ khói → hiệp sĩ hóa cóc → idle/lè lưỡi → hồi phục](toad_witch_spells_review/scene_01_potion_hero_toad.gif): **765.664 byte**, khoảng 6,16 giây.
2. [Phép tím → kiếm hóa chổi → quét bụi → chổi hóa lại kiếm](toad_witch_spells_review/scene_02_broom_curse.gif): **911.557 byte**, khoảng 4,76 giây.
3. [Mụ uống thuốc hóa cóc khổng lồ → ợ hai cóc con xuống hai ô](toad_witch_spells_review/scene_03_transform_burp.gif): **666.590 byte**, 3,90 giây.

[Toàn bộ **35 GIF**](toad_witch_spells_review/index.md): 31 clip, ba cảnh ghép và một bảng icon. Mỗi file dưới **2.000.000 byte**, không có preview PNG/JPG/WebP mới. Cảnh ghép dùng atlas production, nền/gạch G2 và timeline theo fps; đây là minh họa offline để duyệt cảm giác, không phải screenshot gameplay đã tích hợp.

## Nhân vật — 24 biến thể clip, 244 cel

Mỗi cel mới được vẽ tay bằng công cụ ảnh theo tư thế hoàn chỉnh; có squash/stretch, smear và khói. Công cụ Python chỉ đo biên/cắt nguyên hình, co đồng đều, đăng ký, đóng atlas và ghép preview; không nội suy thêm tư thế, không ghép tay/chân để tạo khung mới. Các bản chổi dựa trên bộ pose hiệp sĩ #24/#30 làm mẫu, giữ số khung và nhịp tương ứng.

Quy cách RGBA, ô **512×512**, **4 cột**, ô thừa alpha 0, chân chuẩn `(256,500)`; quái quay trái, hiệp sĩ quay phải. `impact` dưới đây đếm từ **0**. Atlas dùng `compress/mode=2`.

### Mụ Phù Thủy Cóc

Thêm vào `assets/characters/toad_witch/anim/`, giữ nguyên sáu clip cũ:

| Clip | Khung | FPS | Lặp | Impact |
|---|---:|---:|---|---:|
| `cast_toads` | 12 | 14 | Không | 7 |
| `cast_broom` | 12 | 14 | Không | 6 |
| `throw_potion` | 12 | 14 | Không | 6 |
| `cackle` | 8 | 10 | Có | — |
| `stomp_angry` | 8 | 12 | Không | 4 |
| `drink_transform` | 16 | 12 | Không | 15 |

Tung **ba** cóc từ đầu gậy; tia xoắn **tím**; bình thuốc **xanh**; cười ôm bụng; dậm chân có hơi ở tai. `drink_transform` có phồng bụng/mang, smear rộng, khói xanh, hiện cóc; khung cuối bằng chính xác **idle 0 của `toad_witch_giant`**. Các clip còn lại bắt đầu/kết thúc bằng idle 0 của mụ.

### Cóc khổng lồ

Thêm `fresh_burp_toads.png` (**10@12**, impact **5**) và `fresh_victory.png` (**8@8**) vào `assets/characters/toad_witch_giant/anim/`, kèm `victory.png`. Ợ ra **hai** cóc nhỏ; victory vỗ bụng cười, mũ sen rung. Đầu/cuối khớp idle 0; không sửa các clip lưỡi, dậm, mưa độc và defeat cũ.

### Hiệp sĩ hóa cóc

`assets/characters/hero_toad/`, có `anim.json`, `rig.json`, ảnh đứng. Cóc xanh rêu nhỏ, vẫn có **mái tóc nâu bờm xờm, khăn đỏ**, mắt mếu máo và chút áo xanh; không lẫn với cóc tím của mụ.

| Clip | Khung | FPS | Lặp | Impact |
|---|---:|---:|---|---:|
| `transform_in` | 14 | 14 | Không | 9 |
| `idle` | 8 | 10 | Có | — |
| `attack` | 8 | 14 | Không | 4 |
| `hurt` | 6 | 12 | Không | — |
| `transform_out` | 14 | 14 | Không | 10 |

`transform_in` bắt đầu bằng **đúng pixel hero_rookie idle 0** và kết thúc bằng hero_toad idle 0. `transform_out` làm chiều ngược lại bằng các cel vẽ riêng: phồng người, khói, hiện hiệp sĩ, lắc đầu, thở phào; không đảo ngược một strip để giả cảnh hồi phục. Đầu/cuối attack/hurt khớp idle cóc. Tongue attack có các tư thế bật nhảy, lưỡi quất và thu về. Chỉ cần một bộ fresh; đã kiểm fallback cả ba wear.

### Hiệp sĩ cầm chổi

`assets/characters/hero_rookie/anim/broom/`: đủ **fresh/bruised/battered × idle/attack/hurt**. Số khung/fps như bộ kiếm: idle **8@12**, attack **12@24** impact **6**, hurt **8@24**. Chổi cán gỗ, đầu rơm vàng buộc dây tím; quét có bụi/rơm, biểu cảm ngượng. Có vết bầm ở bruised, băng trán/rách áo ở battered.

Thêm `fresh_broom_in.png` và `fresh_broom_out.png`, **12 khung @14fps** mỗi clip, impact **7/6**. Issue gốc ghi 10, nhưng yêu cầu mới của người dùng quy định cảnh biến hình **12–16 khung**, nên hai cảnh đổi vũ khí dùng 12. Đầu/cuối lần lượt khớp pixel giữa idle kiếm và idle chổi fresh. Metadata nằm trong **`anim/broom/anim.json`**; hai cảnh chuyển chỉ có fresh, ghi rõ `fresh_only`.

## Bình thuốc, FX và status

- `assets/board/obstacles/potion_bottle.png`: RGBA **256×256**. `potion_bottle_idle`: **4@10**, lặp; `potion_break`: **4@14**, vỡ vô hại; `potion_burst`: **8@14**, nổ khói xanh. Atlas 512/cel, 4 cột, khai báo thêm trong `obstacles.json`, giữ nguyên mọi entry cũ. Break/burst kết thúc trong suốt.
- `assets/fx/curse/`, `anim.json` theo dạng dictionary như FX combat: `toad_hop` **6@14**, `poof_green` **8@14**, `broom_spell` **8@14**, `spell_break` **8@14**. Canvas 512, 4 cột, gốc hiệu ứng tại tâm; các hiệu ứng tan kết thúc alpha 0. Cóc con là từng tư thế bay/đáp riêng.
- `assets/ui/status/`: `toad.png`, `broom.png`, `poison.png`, RGBA **128×128**, không chữ. Icon cóc cũng giữ tóc nâu/khăn đỏ.

## Tích hợp cho Claude

Các clip root đã được tải qua `CharacterRig`; các variant chổi trong thư mục con có metadata riêng. Claude cần nối lựa chọn thư mục **`anim/broom/`**, cùng chuyển trạng thái `hero_toad`, countdown hai lượt, giảm sát thương, khóa tuyệt chiêu, telegraph trước một lượt và logic phá phép. Không thêm alias clip root trỏ tới file không tồn tại. Bộ kiếm gốc và code game vẫn nguyên.

`anim.json` ghi thêm `projectile_visual` để tránh vẽ vật bay hai lần. Một vài cel phóng đã có vật vừa rời tay/gậy/miệng; giữ event gameplay tại `impact`, chuyển phần vẽ vật bay sang effect ngoài từ frame dưới đây:

| Chiêu | Impact | Có vật trong cel | Vẽ projectile ngoài từ |
|---|---:|---|---:|
| `cast_toads` | 7 | 6–8, ba cóc | 9 |
| `cast_broom` | 6 | 5–7, tia tím | 8 |
| `throw_potion` | 6 | 6–7, bình | 8 |
| `burp_toads` | 5 | 5–6, hai cóc | 7 |

Ba GIF tuân theo việc chuyển quyền vẽ này. Atlas cóc khổng lồ vẫn dùng canvas/pivot chung; cảnh ghép tăng tỷ lệ hiển thị pha 2 khoảng 1,33 để đọc rõ kích thước. Anchor mới kế thừa idle làm điểm gần đúng; không phải dữ liệu track miệng từng khung biến hình.

## Kiểm tra và nguồn

- [Kiểm #42](toad_witch_spells_review/validation.json): **956 điều kiện đạt**; kích thước/grid, alpha lề/ô thừa, pose riêng, metadata/fps/impact, điểm nối pixel, nhịp GIF, ba cảnh, SHA-256 nguồn và bảo toàn PNG cũ.
- [Luật liên thông](campaign_g2_review/contiguity_validation.json): mở rộng lên **584 ô**, không có mảnh lớn chưa được đối chiếu; vẫn bắt đủ **18 ô cá sấu lỗi ở `10ccc4c`**. Ngoại lệ FX mới là từng mask có lý do/diện tích/hộp bao/digest ở `issue42_intentional_fx.json`, không miễn cả clip/ô và không thay các ngoại lệ cũ của #41.
- [Smoke Godot 4.7.2](toad_witch_spells_review/resource_smoke.log): **25 clip root × ba wear**, **11 variant chổi**, bốn FX, bốn texture bình, ba icon; **0 failures**.
- [Suite hiện có](toad_witch_spells_review/godot_tests.log): **93 passed, 0 failed**. Godot import không lỗi.
- Kiểm G2 giữ nguyên các điều kiện cũ, thêm inventory phép và số hàng động cho `potion_burst` tám khung; [kết quả G2](campaign_g2_review/validation.json) **1.287 điều kiện đạt**. Không tắt kiểm tra để né atlas hai hàng.

**32 ảnh nguồn** mới ở ngoài repo; đường dẫn/SHA-256/hộp cắt đã đo nằm trong `toad_witch_spells_sources.json`. Hộp cắt bám khoảng trống thật, không chia hàng nguồn một cách máy móc như lỗi #41. [Danh sách file mới/thay đổi](toad_witch_spells_files.json).

```sh
python docs/ideas/pack_toad_witch_spells.py --group all
python docs/ideas/review_toad_witch_scenes.py
python docs/ideas/check_toad_witch_spells.py
python docs/ideas/check_campaign_g2.py
godot --headless --editor --path . --import --quit
godot --headless --path . -s res://docs/ideas/toad_witch_spells_resource_smoke.gd
godot --headless --path . -s res://tests/run_tests.gd
```

Python cần Pillow, NumPy, SciPy; Godot dùng **4.7.2**, các thư mục XDG writable theo cấu hình onboarding. Nguồn ngoài repo phải còn khi tái xuất; tài nguyên production độc lập khi chơi. Công việc này bàn giao asset và cue; phần cơ chế chiến đấu do Claude tích hợp. Nhánh không merge vào main.

Khi xuất lại nhóm `characters` hoặc `world` bằng packer G2 cũ, lớp bổ sung #42 được gọi ở cuối để không làm mất metadata phép/bình thuốc đã bàn giao.
