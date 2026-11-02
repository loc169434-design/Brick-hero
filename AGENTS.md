# Hướng dẫn cho AI cộng tác

Dự án có hai AI làm cùng nhau. Đọc kỹ để không sửa đè lên nhau.

Game: **Brickbound Hero**, vuốt nối ô cùng màu (kiểu Two Dots) để đánh quái theo lượt và cứu công chúa.
Engine: Godot 4.7.2 (GDScript), renderer Mobile, màn hình dọc 1080×1920.
Kế hoạch chi tiết: [docs/core_plan.md](docs/core_plan.md).

## Chia việc

| Ai | Phụ trách | Không đụng vào |
|---|---|---|
| Claude | Toàn bộ code (`scripts/`, `scenes/`, `tests/`, `project.godot`) | — |
| ChatGPT | Ảnh (`assets/`), ý tưởng và chữ (`docs/ideas/`), dữ liệu cân bằng khi được yêu cầu | `scripts/`, `scenes/`, `tests/`, `project.godot` |

Muốn đề xuất thay đổi code thì viết vào `docs/ideas/` hoặc mở issue, đừng sửa thẳng.

## Quy tắc chung

- Không làm việc trực tiếp trên `main`. Mỗi việc một nhánh, ví dụ `art/tiles`, `docs/charms`, rồi mở pull request.
- Ảnh đặt đúng thư mục và đúng tên file ghi trong mục 5 của `docs/core_plan.md`. Dùng PNG nền trong suốt.
- Tên file viết thường, không dấu, nối bằng dấu gạch dưới: `orc_shield_idle.png`.
- Không dùng chữ "Tetris" hay biến thể của nó ở bất cứ đâu.
