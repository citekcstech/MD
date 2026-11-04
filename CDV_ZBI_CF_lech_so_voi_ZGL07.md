# CDV PRD800 — ZBI_CF lệch số với ZGL07 (kỳ 08.2026, version ZCF2)

Ngày kiểm tra: 04.11.2026 · Hệ: `GUI_CDV_PRD800` (PRD, client 800, On-Premise) · Chỉ đọc, không thay đổi gì trên hệ thống.

## 1. Kết luận ngắn

- **ZBI_CF không tính lại từ sổ cái.** Chế độ "CADIVI (hợp nhất)" của `ZFI_PG_ZBI_CF` chỉ **cộng lại dữ liệu đã lưu** trong bảng `ZTB_FI_ZBI_CF` của 4 công ty 1000/1100/1200/1300 (form `PROCESS_SUM`, `PROCESS_DATA_SYSTEM_CDVHN`). Vì vậy "chạy lại program" ở chế độ hợp nhất **không làm đổi số**.
- **ZBI_CF và ZGL07 đang tính bằng 2 đường khác nhau**, và đường của ZGL07 vừa bị đổi ngày 03.10.2026:

| | ZGL07 (`ZFI_PG_GL_BCLCTTGT`) | Lưu ZBI_CF (`ZFI_PG_ZBI_CF`) |
|---|---|---|
| FM | `ZCORE_FM_J3RFF4V` | `ZCORE_FM_J3RFF4V2` |
| Report chuẩn được SUBMIT | `ZSAP_PG_J_3RFFORM4` | `ZSAP_PG_J_3RFFORM4_CF` |
| Ledger truyền vào (`IW_RLDNR`) | **để trống** (dòng `'0L'` bị comment từ 03.10.2026 — TR `DEVK920256`, "CS_DuyHTK_03.10.2026_ZGL07 Fix báo cáo", ghi chú trong code: *"fix không hiện đúng CS"*) | **`'0L'`** |

- Trong AMDP chuẩn `CL_J_3RF_CASH_FLOW_HANA` (BAdI `get_acc_off`) logic **rẽ nhánh theo ledger trống / có giá trị** (`IF var_ledger = ''` dòng 318; `WHERE var_ledger = ''` dòng 1497; `WHERE var_ledger <> ''` dòng 1562). Tức ledger trống và `0L` chạy 2 nhánh tính khác nhau (xác định tài khoản đối ứng / bù trừ thanh toán).

> Mức chắc chắn: nguyên nhân là **phần suy luận từ code**, chưa chạy đối chứng số (xem mục 5). Chưa loại trừ hẳn khả năng dữ liệu `ZTB_FI_ZBI_CF` lưu cũ (bảng không có timestamp lưu).

## 2. Số liệu đối chiếu kỳ 08.2026 (đọc từ ảnh + bảng `ZTB_FI_ZBI_CF`)

Số trên màn hình = giá trị trong bảng × 100 (VND hiển thị 2 số lẻ). Bảng dưới là giá trị thật (VND).

| Mã số | ZBI_CF (REPVAL, = Σ 1000..1300) | ZGL07 | ZGL07 − ZBI_CF |
|---|---|---|---|
| 11 Tăng/giảm khoản phải trả | 5.418.902.041,48 | 4.488.696.920,63 | −930.205.120,85 |
| 14 Tiền lãi vay đã trả | −28.921.671,87 | −164.719.717,99 | −135.798.046,12 |
| 17 Tiền chi khác cho HĐKD | −25.000,00 | −1.126.309,00 | −1.101.309,00 |
| 23 Tiền chi cho vay, mua công cụ nợ | 0 | −4.000.000.000,00 | −4.000.000.000,00 |
| 27 Tiền thu lãi cho vay, cổ tức | 583.654,81 | 139.042.924,70 | +138.459.269,89 |
| 33 Tiền thu từ đi vay | 948.611.187,71 | 13.611.498.490,81 | +12.662.887.303,10 |
| 34 Tiền trả nợ gốc vay | −3.244.878.046,23 | −14.005.703.790,19 | −10.760.825.743,96 |

Các dòng còn lại nhìn thấy trên ảnh (01, 02, 04, 05, 06, 08, 09, 12, 21…) **khớp nhau**.

Đối soát tổng (khớp tuyệt đối → cách đọc số từ ảnh là đúng):
- Mã 20 (LC thuần từ HĐKD): chênh −1.067.104.475,97 = (11) + (14) + (17).
- Mã 30 (LC thuần từ HĐ đầu tư): chênh −3.861.540.730,11 = (23) + (27).

→ Chênh lệch **chỉ nằm ở 7 mã** liên quan thanh toán công nợ / vay / cho vay / lãi — đúng nhóm phụ thuộc cách xác định tài khoản đối ứng.

## 3. Đã kiểm tra và loại trừ

- Include `ZIN_J_3RFFORM4F01` (thay include chuẩn từ 02.10.2026, TR `DEVK920248`, ThuanNDQ #34874): so với `J_3RFFORM4F01` chuẩn **chỉ khác 2 chỗ `IV_SHOW_MESSAGE = ABAP_FALSE`** (ẩn message) → không đổi số.
- `NEW_OFFS_VALID_DATE` của `ZCF2` trong `J_3RFF4VERS` = trống → cả hai đường đều bị ép `99991231` → không phải nguyên nhân.
- `ZJ_3RFFORM4F07` (debug dump CADIVI) chỉ khác phần in PDF.
- Ledger trống = leading ledger `0L` ở các phần dùng `FAGL_GET_LEADING_LEDGER`, nhưng **AMDP nhận `iv_rldnr` nguyên giá trị** nên vẫn rẽ nhánh khác.
- Bản `_CF` có thêm `GV_CNTRYVER = GC_RU`, nhưng tham số `COUNTRY` của report chuẩn đã mặc định `GC_RU` → không đáng kể.
- Hệ có 2 ledger năm 2026: `0L` (leading) và `GC` (valuation view 1); `GC` có thêm bút toán riêng (ML +1.955, PR +102, RV +239, RE +55… dòng ở kỳ 8/2026). Không trực tiếp gây chênh vì cả hai đường không cộng cả 2 ledger, nhưng cần lưu ý khi chốt "ledger nào đúng".

## 4. Cách cộng của ZBI_CF (đã kiểm chứng bằng data)

`CDVGR / ZCF2 / 202608 / ID 11`: REPVAL 5.418.902.041,48 = 1000 (2.556.698.041,36) + 1300 (2.862.204.000,12); 1100, 1200 = 0. Cột "Giá trị điều chỉnh" (ZGTDC) lấy từ công ty 9999 (−1.061.681.403,28) → "Số sau điều chỉnh" 4.357.220.638,20. Màn hình ZBI_CF cột "Số cuối kỳ" là REPVAL (trước điều chỉnh).

## 5. Cách xác nhận (không thay đổi hệ thống)

SE38 chạy `ZSAP_PG_J_3RFFORM4_CF` cho công ty 1000, version ZCF2, năm 2026, so sánh 2025, kỳ 8, **2 lần**: Ledger = `0L` và Ledger để trống. Xem mã 11:
- `0L` phải ra số = ZBI_CF (công ty 1000: 2.556.698.041,36 → hiển thị ×100).
- Để trống phải ra số theo ZGL07.
Nếu đúng → xác nhận nguyên nhân. Lưu ý hỏi thêm: các kỳ 09, 10/2026 có lệch không? Nếu **chỉ ≤ 08 lệch** mà 09–10 khớp thì khả năng là dữ liệu lưu cũ, không phải chênh ledger.

## 6. Việc cần quyết định (chưa làm gì)

1. Hỏi DuyHTK lý do bỏ `'0L'` ở ZGL07 (03.10.2026) — "CS" không đúng ở trường hợp nào.
2. Kế toán chốt số nào đúng (nhánh `0L` hay ledger trống) bằng đối chiếu số dư/bút toán thực.
3. Sau đó đồng bộ: hoặc khôi phục `IW_RLDNR = '0L'` ở ZGL07, hoặc bỏ `'0L'` ở `GET_DATA_SYSTEM`/`GET_DATA_SYSTEM_CDVHN` của `ZFI_IN_ZBI_CF_F01`.
4. Muốn làm mới ZBI_CF: phải chạy chế độ **CADIVI (từng công ty)** cho 1000, 1100, 1200, 1300 trước, rồi mới chạy **CADIVI (hợp nhất)**; chạy lại ghi đè `ZTB_FI_ZBI_CF` (chỉ giữ cột điều chỉnh với dòng có `FLAG_SAVE`).

## 7. Lịch sử thay đổi liên quan

- 01.07.2026 — TaiNA, `ZFI_IN_ZBI_CF_F01` "Fix condition calculate for Tcode ZBI_CF" (`DEVK919267`).
- 03.08.2026 / 01.09.2026 — DuyHTK, `ZJ_3RFFORM4F07` "Debug Dump CADIVI UP" (`DEVK919761`).
- 02.10.2026 — ThuanNDQ, `ZSAP_PG_J_3RFFORM4`, `_CF`, `ZIN_J_3RFFORM4F01` (`DEVK920248`).
- 03.10.2026 — DuyHTK, `ZFI_IN_GL_BCLCTTGT_F01` bỏ `IW_RLDNR = '0L'` (`DEVK920256`).
