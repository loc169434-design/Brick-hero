# Vẽ tay lại hiệp sĩ – Brickbound Hero

Viết ngày 2026-11-06 theo góp ý của người chơi: các clip của hiệp sĩ đang được dựng bằng Python, cắt hình đứng thành từng mảnh rồi xoay tay chân (`docs/ideas/build_anim_moves.py`). Kết quả là mọi khung có cùng một thân, cùng một mặt, cùng một áo choàng, chỉ cánh tay cầm kiếm đổi góc, cú nhảy không rời mặt đất. Nhìn cứng và rẻ.

Mục tiêu: **mỗi khung là một bức vẽ tay trọn vẹn**, như phim hoạt hình 2D, nhưng **giữ nguyên thiết kế hiệp sĩ** (tóc nâu xù, khăn choàng đỏ, áo xanh viền kem, đai nâu khóa vàng, giáp tay da, khiên gỗ tròn viền sắt, kiếm, ủng nâu), nét viền nâu đậm và màu như hiện tại.

---

## 1. Luật vẽ

**Bắt buộc:**
- **Không cắt ghép, không xoay mảnh cơ thể bằng code.** Mỗi khung vẽ lại cả người. Được phép: lặp lại nguyên một khung để giữ dáng (hold), lật màu cho các mức trầy xước (mục 4).
- **Một bảng mẫu nhân vật trước** (`hero_model_sheet.png`): dáng đứng, 3 biểu cảm (cười tự tin, gầm khi chém, nhăn khi đau), bàn tay nắm và mở, kiếm và khiên vẽ riêng, bảng màu có mã hex. Mọi khung sau đều so với bảng này.
- **Cỡ cố định:** cel 512×512. Khi đứng, chân ở (256, 500) và cao như `fresh_idle` hiện tại (bbox 400 px, đầu khoảng 115 px). Cúi, ngồi, nhảy thì người thấp hoặc cao hơn theo dáng, nhưng **đầu không đổi cỡ**.
- **Nhân vật không tự di chuyển trong cel.** Code đã dời hiệp sĩ tới quái (`dash_to`), nhảy theo đường cong (`hop_to`) và kéo về (`home`). Tranh chỉ đổi dáng; gốc chân vẫn ở (256, 500), riêng khung trên không thì gốc là bóng dưới chân.

**Để động tác có hồn** (nguyên lý hoạt hình cổ điển):
- **Đường hành động (line of action):** mỗi dáng chính có một đường cong rõ chạy từ đầu xuống chân sau. Không có dáng nào đứng thẳng đơ trừ khi đang thủ.
- **Lấy đà → ra đòn → theo đà → hồi về.** Trước cú chém phải lùi người, kéo kiếm ra sau; sau cú chém người còn lao theo, áo choàng và tóc vẫn bay rồi mới rơi xuống.
- **Bóp và giãn:** khung lấy đà người nén lại, khung ra đòn người duỗi dài; khi tiếp đất thì khuỵu gối.
- **Khung nhòe (smear):** cú vung nhanh vẽ 1 khung kiếm nhòe thành dải, tay kéo dài. Đừng chèn vệt sáng lên một khung đứng yên.
- **Trễ nhịp:** khăn choàng, tóc và dây đai theo sau thân 1–2 khung.
- **Mặt thay đổi:** nheo mắt khi lấy đà, há miệng gầm khi chém, mắt nhắm khi bị đánh. Khung đứng có 1 khung chớp mắt.
- **Hình bóng rõ:** tô đen cả người, ở cỡ 200 px vẫn đọc được đang làm gì. Kiếm và khiên không bị thân che mất ở khung chính.

## 2. Tham khảo thế đứng, đi, đánh

Không chép nhân vật của game nào. Chỉ học cách chia nhịp từ các tài liệu hoạt hình 2D quen thuộc (sách *The Animator's Survival Kit* của Richard Williams, các bảng sprite vẽ tay của game đối kháng 2D):

| Thế | Khung chính | Ghi chú |
|---|---|---|
| **Đứng thủ** | Hai chân dang rộng hơn vai, gối hơi chùng, người nghiêng về phía quái, khiên trước ngực, kiếm giơ sau vai | Thở: vai lên xuống 2–4 px, khăn choàng phấp phới, có khung chớp mắt |
| **Chạy lướt** | Chạm đất → dồn xuống → bước qua → bật lên, lặp 2 lần là đủ một vòng 8 khung | Người đổ về trước khoảng 15°, khiên đưa ra trước, kiếm kéo sau, khăn bay ngang |
| **Chém** | Thủ → lấy đà (vặn người, kiếm ra sau đầu) → nhòe → chạm (người duỗi, chân trước khuỵu) → theo đà → hồi | Khung chạm giữ 2 khung để người chơi kịp thấy |
| **Nhảy bổ** | Khuỵu sâu → bật lên (duỗi thẳng) → lộn hoặc giơ kiếm trên đầu → bổ xuống (kiếm dọc) → tiếp đất khuỵu | Chiều cao do code lo; tranh lo dáng người co, duỗi |
| **Đá bay** | Co gối → đá thẳng (chân duỗi, người ngả sau) → thu chân | Khung đá có vệt nhòe ở bàn chân |
| **Húc khiên** | Hạ thấp người, vai sau khiên → lao (người gần nằm ngang) → va (khiên méo nhẹ) → bật lại | |
| **Bị đánh** | Đầu giật ra sau, mắt nhắm, một chân nhấc lên → loạng choạng → về thủ | |
| **Bị hất ngã** | Bay ngửa → chạm đất nảy → chống kiếm đứng dậy | |

## 3. Danh sách clip

Giữ đúng tên, số khung, fps và `impact` để code không phải đổi. **In đậm** là clip mới.

| Clip | Khung | fps | impact | Nội dung theo khung |
|---|---|---|---|---|
| `idle` | 8 | 12 | – | 0–3 thở ra, 4–7 thở vào; khung 5 chớp mắt; khăn choàng gợn suốt vòng |
| **`run`** | 8 | 16 | – | vòng chạy lướt ở trên. Code dùng lúc lao tới quái trước `attack`, `kick`, `bash` |
| **`hop_back`** | 6 | 16 | – | nhảy lùi về chỗ: khuỵu, bật lùi, chạm đất, đứng thủ. Thay cho cảnh trượt về hiện tại |
| `attack` | 12 | 24 | 6 | 0 thủ, 1–3 lấy đà, 4 nhòe, **5–6 chạm**, 7–9 theo đà, 10–11 hồi |
| `throw` | 10 | 24 | 4 | 0–2 kéo kiếm ra sau, 3 nhòe, **4 buông kiếm** (tay trống từ đây), 5–9 tay duỗi theo rồi chờ đón kiếm |
| `leap` | 16 | 24 | 10 | 0–2 khuỵu, 3–5 bật lên, 6–8 kiếm giơ cao, 9 nhòe bổ, **10 bổ xuống**, 11–13 khuỵu tiếp đất, 14–15 đứng dậy |
| `kick` | 8 | 24 | 3 | 0–1 co gối, 2 nhòe, **3 đá thẳng**, 4–7 thu chân về thủ |
| `bash` | 10 | 24 | 4 | 0–2 hạ người sau khiên, 3 lao, **4 va**, 5–9 bật lại, về thủ |
| `hurt` | 8 | 24 | – | 0–2 giật đầu, 3–5 loạng choạng, 6–7 về thủ |
| `knocked` | 8 | 24 | – | bay ngửa, nảy, nằm (khung cuối giữ được) |
| `dizzy` | 12 | 12 | – | lắc lư, mắt xoáy, lưỡi thè (sao do code vẽ) |
| `scared` | 8 | 12 | – | co người sau khiên, run, mồ hôi |
| `drink` | 12 | 12 | – | lấy bình, ngửa cổ uống, lau miệng, gồng tay |
| `cheer` | 12 | 12 | – | nhảy lên giơ kiếm, cười to |
| `victory` | 12 | 12 | – | dáng chiến thắng lặp: chống kiếm, khăn bay |
| `defeat` | 12 | 12 | – | khuỵu gối, gục, kiếm rơi |

Các clip biến hình (`broom_in`, `broom_out`, `transform_in`, `transform_out`, thư mục `broom/`) vẽ lại theo cùng luật **sau** khi bộ chính đã duyệt.

## 4. Ba mức trầy xước

Hiện có `fresh_`, `bruised_`, `battered_` cho mỗi clip. Không vẽ lại cả ba từ đầu:
1. Vẽ tay toàn bộ bộ `fresh_`.
2. `bruised_` và `battered_` dùng **đúng nét và dáng** của `fresh_`, chỉ **tô thêm bằng tay** trên từng khung: vết bầm, băng cá nhân, áo rách, khăn sờn, khiên nứt (mức 3 khiên mẻ một góc). Được dùng một lớp tô chung theo vị trí nếu khớp với dáng từng khung, nhưng không xoay hay cắt hình.

## 5. Thứ tự và duyệt

1. **Bảng mẫu nhân vật** + 3 clip thử: `idle`, `run`, `attack`. Người chơi duyệt nét và nhịp trước khi làm tiếp.
2. `leap`, `kick`, `bash`, `throw`, **`hop_back`**.
3. `hurt`, `knocked`, `dizzy`, `scared`, `drink`.
4. `cheer`, `victory`, `defeat`.
5. Hai mức trầy xước, rồi các clip biến hình.

**Mỗi clip giao kèm:**
- GIF đúng tốc độ, đặt cạnh clip cũ;
- ảnh chồng hành (onion skin) của các khung chính;
- ảnh hình bóng đen ở 200 px.

**Kiểm tra trước khi push:**
- [ ] Không khung nào là bản xoay hoặc dời của khung khác (trừ khung giữ y nguyên).
- [ ] Đầu cùng cỡ với bảng mẫu (±5%); khi đứng, chân ở (256, 500 ± 4).
- [ ] Không chạm mép cel; nền trong suốt; đúng tên file `fresh_<clip>.png`, atlas 4 cột.
- [ ] `anim.json` giữ nguyên các clip cũ, thêm `run`, `hop_back`.
- [ ] GIF dưới 2 MB.

## 6. Phần code (Claude)

- Nạp `run` khi hiệp sĩ lao tới quái (`dash_to`) rồi chuyển sang đòn đánh đúng lúc tới nơi; dùng `hop_back` thay cho `home` trượt về.
- Nếu clip mới chưa có thì giữ cách cũ, để ráp từng phần.
- Thêm bài kiểm tra: mỗi clip của hiệp sĩ có đủ số khung khai báo và `impact` nằm trong clip.
