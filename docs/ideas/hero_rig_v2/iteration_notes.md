# Số đo từng vòng

Ngưỡng cố định: IoU thân không kiếm ≥0.97; IoU mặc đồ ≥0.95; lớp đồ ngoài mảnh chủ +24px =0.
Vùng kiếm REF được nới Euclidean 4px ở cả hai ảnh trước khi chấm IoU.
Giữ nguyên pixel vùng không mặc đồ: MAE RGB ≤10/255 và P95 sai số kênh lớn nhất ≤30/255.
Khớp: xét bán kính 20px, không lỗ alpha kín, cha/con phải có diện tích chồng >0 và một thành phần tiếp xúc. Nền ngoài cơ thể không được gọi là khe hở; số pixel nền vẫn ghi riêng.

| Vòng | Thân IoU | Da IoU | Sắt IoU | MAE da/sắt | Khớp lỗi /78 | Ngoài chủ+24 | Kết luận |
|---|---:|---:|---:|---:|---:|---:|---|
| 1 | 0.999359 | 0.983694 | 0.974893 | 15.674/17.474 | 3/78 | 0 | TRƯỢT |
| 2 | 0.998187 | 0.877065 | 0.889907 | 33.570/21.518 | 4/78 | 0 | TRƯỢT |

Vòng 2 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_02.json.

Vòng 2 — xem ảnh phát hiện vùng biểu cảm bị lệch và bbox nón bị ảnh hưởng bởi điểm alpha rời; kiểm tra số chưa đủ để duyệt hình. Sửa phép căn chỉnh trước vòng 3.
| 3 | 0.998187 | 0.853823 | 0.909969 | 33.570/21.518 | 4/78 | 0 | TRƯỢT |

Vòng 3 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_03.json.

Vòng 3 — đã sửa bbox nón; biểu cảm còn dính nền matte từ ảnh sửa. Không duyệt hình, tiếp tục tách nền liên thông trước khi chuyển pixel mắt/miệng.
| 4 | 0.996304 | 0.937319 | 0.925497 | 10.502/12.300 | 0/78 | 0 | TRƯỢT |

Vòng 4 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_04.json.

Vòng 4 — thân và 78/78 phép xoay đã đạt; biểu cảm chưa đạt kiểm tra hình bằng mắt. Tạo lại từng biểu cảm bằng sửa ảnh riêng thay cho tách từ lưới; ảnh mặc đồ lần tiếp theo tiếp tục thử giữ nguyên pixel ngoài đồ.
| 5 | 0.996304 | 0.986854 | 0.968441 | 8.541/9.601 | 0/78 | 0 | TRƯỢT |

Vòng 5 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_05.json.
| 6 | 0.996317 | 0.987220 | 0.969992 | 6.819/7.701 | 0/78 | 0 | TRƯỢT |

Vòng 6 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_06.json.

Vòng 6 — đã bỏ phần đốc kiếm lẫn vào nắm tay. Xem compare phát hiện vạt đồ còn bị áo gốc che do chia sai chủ: vòng 7 chuyển vạt áo/thắt lưng về pelvis và ưu tiên owner theo pixel cắt thật, giữ nguyên order.

Từ vòng 7, kiểm tra pixel vùng không mặc đồ chấm trên WEAR cuối có ảnh đầu hoàn chỉnh, theo yêu cầu bổ sung. File `wear_*_body_registered.png` vẫn giữ nguyên ảnh edit đã căn trước thay đầu; số đo raw vẫn nằm trong JSON. Ngưỡng MAE≤10 và P95≤30 không đổi, không sửa pixel thân ngoài đồ để đạt kiểm tra. Đồng thời mở rộng mask bảo vệ từ đuôi khăn sang toàn bộ màu khăn.
| 7 | 0.996317 | 0.986963 | 0.969888 | 8.988/11.421 | 0/78 | 0 | TRƯỢT |

Vòng 7 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_07.json.

Vòng 7 — đã sửa vạt đồ; vẫn phát hiện phần bù khớp ở mảnh trước che đồ của mảnh sau trong dáng nghỉ. Vòng 8 giới hạn phần bù vào vùng bị mảnh sau che, dùng màu cổ ở đệm cổ. Mask bảo vệ được mở rộng ra toàn bộ khiên, nắm tay và cẳng tay thực sự cắt từ REF. Đây là vòng cuối trong giới hạn 8; không nới các ngưỡng khi có lỗi.
| 8 | 0.996504 | 0.986796 | 0.970037 | 10.194/11.010 | 0/78 | 0 | TRƯỢT |

Vòng 8 — đầu: 18/18 cổ/cằm ≤6; 18/18 landmark ≤2px; 36/36 xoay cổ ±20°. Xem head_metrics_round_08.json.
