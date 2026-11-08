# Quái đợt 1 cho ChatGPT: làm lại hoạt ảnh quái cho đẹp ngang hiệp sĩ

Claude viết. Kế hoạch chung: [docs/sprite_plan.md](../../sprite_plan.md), mục 3.

Hiệp sĩ đã có 24 động tác, mỗi động tác 8–16 khung. Quái hiện chỉ có 4–6 khung mỗi động tác, nên đánh nhau trông giật và yếu. Đợt này vẽ lại quái **nhiều khung hơn, đòn mạnh tay hơn**.

Gemini đang vẽ hiệp sĩ song song. Hai bên **không đụng file của nhau**.

## Nhánh và thư mục

- Nhánh mới `art/monsters-1`, tạo từ `origin/core/world-life`.
- Chỉ thêm hoặc sửa file trong `assets/characters/<quái>/anim/` và `docs/ideas/sprites/monsters1/`.
- Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`. Claude sẽ tự cập nhật `anim.json` theo số khung mới.
- Không sửa gì của `hero_rookie`. Không force push.

## Nhân vật giữ nguyên

Mỗi quái **giữ đúng hình dáng hiện tại**: mặt, màu da, quần áo, vũ khí, tỉ lệ, nét viền và cách tô bóng như khung 0 của `assets/characters/<quái>/anim/fresh_idle.png`. Không vẽ quái mới từ mô tả chữ. Lấy khung đó làm ảnh gốc rồi vẽ động tác từ nó.

## Định dạng (có script kiểm)

- Mỗi động tác một sheet, **lưới 4 cột**, khung **512×512**, đọc trái sang phải, trên xuống dưới.
- **Quay mặt sang trái** (về phía hiệp sĩ), như quái đang có.
- **Chân chạm đất tại (256, 500)** ở khung đầu và khung cuối. Cỡ người khớp khung 0 `fresh_idle` hiện tại của chính quái đó (lệch tối đa 8%).
- Diễn tại chỗ: chân không trôi ngang quá 40 px. Game tự cho quái lao tới hay lùi.
- Không phần nào bị mép khung cắt.
- **Không vẽ hiệu ứng:** không vệt chém, lửa, nổ, bụi, bóng đất. Game tự vẽ.
- Khung đầu và khung cuối gần giống tư thế đứng, để nối mượt.

## Xóa nền: nền hồng tím #FF00FF

Quái da xanh lá nên **không dùng nền xanh** như hiệp sĩ.

1. Vẽ mọi khung trên nền **hồng tím thuần #FF00FF**, phẳng một màu. Quái không được có màu hồng tím.
2. Lưu bản gốc: `docs/ideas/sprites/monsters1/raw/<quái>_<động tác>_key.png`.
3. Tách nền chỉ bằng công cụ:
   ```sh
   python3 tools/sprites/key_out.py docs/ideas/sprites/monsters1/raw/<quái>_<động tác>_key.png assets/characters/<quái>/anim/fresh_<động tác>.png --key ff00ff
   ```
4. Mép xấu thì sửa bản gốc rồi tách lại, không sửa tay bản đã tách.

## Bộ động tác chuẩn cho mỗi quái

`impact` là khung (đếm từ 0) mà đòn chạm hiệp sĩ.

| Động tác | Khung | fps | impact | Diễn |
|---|---|---|---|---|
| `idle` | 8 | 12 | — | thở, nhún nhẹ, nhìn hiệp sĩ; khung cuối nối được về khung đầu |
| `attack` | 12 | 24 | 6 | 0–3 lấy đà rõ (nghiêng ra sau, giơ vũ khí) · 4–6 ra đòn hết sức · 7–11 thu về |
| `hurt` | 8 | 24 | — | 0–2 giật bật ra sau, mặt nhăn · 3–7 lấy lại thăng bằng |
| `special` | 12 | 24 | 7 | đòn riêng của quái (bảng dưới): 0–5 gồng lấy đà · 6–7 tung đòn · 8–11 thu về |
| `defeat` | 12 | 12 | — | loạng choạng rồi ngã gục; khung cuối nằm trên đất, vẫn trong khung |
| `victory` | 8 | 12 | — | ăn mừng, chế nhạo; khung cuối nối được về khung đầu |
| `rage` | 10 | 12 | — | chỉ quái có ghi: gầm lên, gồng người, mặt đỏ |

## Danh sách (làm theo thứ tự này)

| # | Quái | Đòn `special` | `rage` |
|---|---|---|---|
| 1 | `orc_chief` (trùm) | đập chùy xuống đất bằng hai tay | có |
| 2 | `orc_chief_enraged` (trùm nổi điên) | xoay chùy quét ngang hai vòng | có |
| 3 | `orc_rock` | giơ tảng đá qua đầu rồi ném | có |
| 4 | `orc_drummer` | đánh trống dồn dập, gầm cổ vũ | có |
| 5 | `orc_boar` | lợn rừng chồm lên, húc tới | có |
| 6 | `goblin_thief` | lộn người, đâm dao | — |
| 7 | `goblin_archer` | kéo căng cung, bắn mạnh | — |
| 8 | `goblin_bomber` | châm ngòi, quăng bom vòng cầu (bom rời tay ở khung 7, không vẽ nổ) | — |
| 9 | `crocodile` | há mõm đớp tới | — |
| 10 | `frost_slime` | phồng to rồi phun băng (không vẽ tia băng) | — |

`orc_shield` và `scarecrow` không làm đợt này.

## Tự kiểm tra

Với mỗi sheet:

```sh
python3 tools/sprites/check_sheet.py assets/characters/<quái>/anim/fresh_<động tác>.png --frames <khung> --fps <fps> --key ff00ff --ref docs/ideas/sprites/monsters1/ref/<quái>_idle_old.png --out docs/ideas/sprites/monsters1
```

**Trước khi ghi đè `fresh_idle.png` của một quái**, chép bản cũ ra `docs/ideas/sprites/monsters1/ref/<quái>_idle_old.png` để làm `--ref` đo cỡ người.

Riêng `defeat` khung cuối nằm dưới đất nên thêm `--airborne` (bỏ kiểm chân khung cuối).

Phải **ĐẠT tất cả**, tối đa 5 vòng sửa mỗi sheet. Ghi số đo vào `docs/ideas/sprites/monsters1/rounds.md`.

Tự xem GIF trên nền tối:
- liền mạch, không giật;
- không khung nào quái đổi cỡ, đổi màu, mất vũ khí;
- không viền hồng.

## Điểm dừng duyệt

1. Làm **trọn `orc_chief`** (7 động tác), commit, push, báo, rồi **dừng chờ duyệt**.
2. Được báo "duyệt quái" thì làm tiếp từ số 2 đến 10. Mỗi quái xong thì commit và push một lần, không cần dừng.
3. Xong cả 10 quái: báo kết quả kiểm tra từng sheet, rồi **dừng**.
