# Quái đợt 2 cho ChatGPT: đầm lầy và bù nhìn

Claude viết, ngày 10/11/2026. Cách làm **y hệt đợt 1**: [monsters_round1.md](monsters_round1.md) (giữ nguyên nhân vật, lưới 4 cột, khung 512, chân tại (256, 500), quay mặt sang trái, nền `#FF00FF`, tách bằng `key_out.py`, kiểm bằng `check_sheet.py`, không vẽ hiệu ứng). File này chỉ ghi những gì khác.

Đợt 1 đã duyệt: cả 10 quái đạt, Claude đã kiểm lại cả 65 sheet.

## Nhánh và thư mục

- Nhánh mới `art/monsters-2`, tạo từ `origin/art/monsters-1` (để có sẵn bản đợt 1).
- Chỉ thêm hoặc sửa file trong `assets/characters/<quái>/anim/` và `docs/ideas/sprites/monsters2/`.
- Không sửa `scripts/`, `scenes/`, `tests/`, `project.godot`, mọi `anim.json`, các file `.import`, `hero_rookie`. Không force push.
- Trước khi ghi đè `fresh_idle.png` của một quái, chép bản cũ ra `docs/ideas/sprites/monsters2/ref/<quái>_idle_old.png`.

## Việc 0: sửa nhỏ đợt 1

1. **`goblin_archer` `special`** đang gần giống hệt `attack`. Làm khác hẳn: khuỵu thấp một gối, kéo dây cung căng hết cỡ (cung cong mạnh, tay run 2 khung), nheo một mắt; khung 7 buông tên, người giật ngửa ra sau vì lực bật; 8–11 đứng dậy.
2. **`goblin_thief` `victory`** khung 1–5: con dao găm tự hiện ra ở thắt lưng. Giữ đúng đồ như `idle` (không dao ở thắt lưng).

## Việc 1: quái đầm lầy (hồi 2)

Bộ chuẩn như đợt 1: `idle` 8/12, `attack` 12/24 impact 6, `hurt` 8/24, `special` 12/24 impact 7, `defeat` 12/12, `victory` 8/12.

| # | Quái | `special` | Thêm |
|---|---|---|---|
| 1 | `toad_spitter` (Cóc Phun Độc) | phồng má, ngửa cổ rồi phun (không vẽ bãi độc hay cóc con) | — |
| 2 | `swamp_leech` (Đỉa Đầm) | vươn dài người, há giác hút đớp tới rồi co về | — |
| 3 | `swamp_spider` (Nhện Đầm) | chổng bụng, giơ hai chân trước, bắn tơ (không vẽ sợi tơ) | — |
| 4 | `toad_witch` (Mụ Phù Thủy Cóc, trùm) | vung gậy phép, cười khằng khặc | **`lift`** 12/24 impact 8: hai tay giơ cao, nâng một vật vô hình lên, rồi hất mạnh về phía trước ở khung 8 |
| 5 | `toad_witch_giant` (Cóc Khổng Lồ, trùm) | đập bụng xuống đất | — |

Ghi chú:
- **`toad_witch`**: chỉ vẽ lại 6 động tác chuẩn và `lift`. **Giữ nguyên** `cast_toads`, `cast_broom`, `throw_potion`, `cackle`, `stomp_angry`, `drink_transform` (đã đủ khung). `lift` bản cũ bị vẽ nhỏ bằng nửa người (issue #48): bản mới phải **cùng cỡ với `idle`** (lệch tối đa 8%).
- **`toad_witch_giant`**: giữ nguyên `burp_toads`, `special2`. Quái to: chiều cao theo đúng `fresh_idle` cũ, không thu nhỏ cho vừa nhóm.

## Việc 2: bù nhìn (màn 1–5, người chơi gặp đầu tiên)

| # | Quái | Động tác cần |
|---|---|---|
| 6 | `scarecrow` | giữ `idle`, `hurt`; **thêm `defeat`** 12/12: cọc nghiêng dần, đổ xuống, rơm bung ra một ít; khung cuối nằm trên đất |
| 7 | `scarecrow_wood` (Bù nhìn gỗ, có đánh trả) | `idle` 8/12 (lắc lư trên cọc), `attack` 12/24 impact 6 (xoay cọc, cánh tay gỗ quật tới), `hurt` 8/24, `defeat` 12/12 (gãy đôi ở cọc), `victory` 8/12 (xoay vòng trên cọc) |
| 8 | `scarecrow_straw_shield` (Bù nhìn khiên rơm, không đánh) | `idle` 8/12, `hurt` 8/24 (khiên rơm bị đẩy lệch rồi về), `defeat` 12/12 (khiên rơi, cọc đổ) |

Bù nhìn đứng trên một cọc, nên "chân" là chân cọc tại (256, 500).

## Tự kiểm tra và điểm dừng

- Mỗi sheet chạy `check_sheet.py` như đợt 1, `--ref docs/ideas/sprites/monsters2/ref/<quái>_idle_old.png --out docs/ideas/sprites/monsters2`; `defeat` thêm `--airborne`. Phải ĐẠT tất cả, tối đa 5 vòng sửa. Ghi số đo vào `docs/ideas/sprites/monsters2/rounds.md`.
- Xem GIF trên nền tối: không khung nào đổi hướng mặt đột ngột, đổi cỡ, đổi màu, mất hay thêm đồ so với `idle`.
- **Làm một mạch, không dừng giữa chừng** (đổi ngày 11/11): Việc 0, rồi 8 quái theo thứ tự bảng.
- **Mỗi quái xong thì commit và push ngay**, để Claude theo dõi giữa chừng.
- Một sheet sửa tối đa 5 vòng. Quá 5 vòng vẫn trượt thì ghi lý do vào `rounds.md` rồi làm sheet tiếp theo.
- Xong hết: báo bảng kết quả từng sheet (ĐẠT hay TRƯỢT, số vòng sửa), rồi **dừng**.
