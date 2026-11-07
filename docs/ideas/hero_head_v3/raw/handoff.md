# Bàn giao ảnh nón raw — vòng 5

Nhánh `art/hero-head-raw`, từ `core/world-life` tại `0f77e55`. Chỉ ghi trong thư mục này. Không thay asset game, không cắt lớp.

Hai mẫu chính: nón da chiến binh ghép mảng lớn, đinh đồng; nón sắt sallet có sống giữa và che gáy ngắn. Có thêm mẫu da ranger khóa đồng theo yêu cầu nhiều kiểu nón da. Cả ba dùng viền nâu đậm và bóng cel đơn giản để cùng nét với nhân vật gốc, góc 3/4 quay phải.

| File | Nội dung |
|---|---|
| [leather_helmet_raw.png](leather_helmet_raw.png) | Nón da chiến binh, toàn thân 512×512 RGBA |
| [iron_helmet_raw.png](iron_helmet_raw.png) | Nón sắt trung cổ, toàn thân 512×512 RGBA |
| [leather_ranger_raw.png](leather_ranger_raw.png) | Biến thể nón da ranger, toàn thân 512×512 RGBA |
| [compare.png](compare.png) | Gốc — da — sắt |
| [style_options.png](style_options.png) | Gốc — da chiến binh — da ranger — sắt |
| [rounds.md](rounds.md) | Số đo cả 5 vòng và cách chạy script |

| Chỉ số vòng cuối | Da | Sắt | Da ranger |
|---|---:|---:|---:|
| MAE ngoài vùng sửa, /255 | 2.490 | 2.572 | 2.600 |
| MAE RGB foreground, tham khảo | 12.222 | 13.052 | 13.209 |
| Bề ngang nón / ngang đầu | 1.0315 | 1.0709 | 1.0945 |
| Đỉnh nón y, tóc gốc y105 | 106 | 107 | 108 |
| Dày vành px, ngưỡng ≤14 | 12.00 | 17.86 | 11.00 |
| Cách mày px, ngưỡng ≥6 | -6.00 | -0.21 | -1.00 |
| Pixel gần màu tóc ngoài viền phía trên vành | 0 | 0 | 0 |

Cả ba có nền trong suốt, đỉnh nón không cao hơn tóc gốc và còn nối liền với nhân vật theo kiểm tra alpha/điểm cổ. MAE toàn vùng ngoài đạt ≤6/255; MAE chỉ trên foreground cao hơn và được công khai, nên đây không phải cam kết giữ từng pixel mặt/thân.

**Chưa đạt toàn bộ tiêu chí:** khoảng cách vành–mày còn thiếu ở cả ba; nón sắt có vành dày 17,86 px. Tỷ lệ ngang được nới theo phản hồi “không nhất thiết quá bó vào đầu”; các ngưỡng còn lại giữ nguyên. Dừng ở giới hạn 5 vòng sửa ảnh. Bản này bàn giao để duyệt hình dáng/nét vẽ, chưa xác nhận sẵn sàng đưa vào rig.

`source_manifest.json` lưu hash đầu vào và ảnh cuối. `sources/` giữ ảnh sinh, ảnh đã căn, tham số căn toàn ảnh, contour và overlay đo từng vòng. Contour chỉ dùng đo; không xuất thành mảnh đồ hoặc ghép lại đầu.
