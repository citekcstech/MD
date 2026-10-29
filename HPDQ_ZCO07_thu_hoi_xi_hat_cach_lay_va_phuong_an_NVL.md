# HPDQ ZCO07 – Dòng "Thu hồi xỉ hạt" lấy thế nào, có đưa thành NVL được không

Ngày 28/10/2026. Nguồn đọc: `CodeABAP/HPDQ_ZCO07/ABAP/zfi_pg_btgt_07/zfi_pg_btgt_07.abap` (local), FS `HPDQ_FS_CO_ZCO07_CoCauGiaThanhSanPham.xlsx` (sheet ZCO07 D94, sheet "C.Phụng note"), file CKMLQS đã export trong `Data/`.

**Kết luận cuối (28/10/2026): đã BỎ dòng "Thu hồi xỉ hạt" khỏi report, không chuyển thành NVL** - xem mục 5. Các mục 1-4 là quá trình phân tích trước khi user xác nhận trên PRD. Ban đầu MCP `GUI_HPDQ_DEV100` lỗi 401 (user CT.SUPPORT, client 100); sau khi user sửa đăng nhập thì chạy lại được (mục 4).

## 1. Hiện đang lấy thế nào (chỉ tiêu 22, FORM `GET_SLAG_VALUE`)

1. Lấy danh sách Order của mã thành phẩm trong kỳ: MSEG MVT 101/102/131/132 (FORM `GET_ORDER_LIST`).
2. Trên các Order đó, lấy MSEG MVT 531/532 trong kỳ, join MARA, giữ vật tư có `MTART = 'M47'`.
3. Tìm KALNR trong CKMLHD (BWKEY của Plant, PSPNR rỗng).
4. Gọi `ZCL_ML_DATA_SELECT->GET_SUM_INIT` (giống Tcode CKM3, Curr/Valuation 10), cộng các dòng `CATEG = 'ZU'`, `PTYP = 'BF'` (Receipts → Production) của mọi mã M47: `STVAL + KDM + PRD`.
5. Ghi vào `GT_CC_VALUE` với `ITEM = '22'`. `GET_CC_AMOUNT` đổi thành `-ABS(giá trị)` vì khai báo `MINUS = X`.
6. `BUILD_OUTPUT` xếp vào cụm "Chi phí chung khác" (chỉ tiêu 14–22), cộng vào tổng giá thành.

Đối chiếu ảnh PRD/800 kỳ 07.2026: Khí oxi 53.328.943.076 + Vật tư khác 8.579.366.869 + Bảo trì 46.047.969.679 + VLCL 29.633.121.199 + Vật tư công nghệ 37.236.012 + CP LOG 6.660.411.990 + Dịch vụ 6.962.754.603 + Gas LPG 64.343.664 − Thu hồi xỉ 31.930.197.000 = **119.383.950.092**, đúng bằng dòng "Chi phí chung khác". Vậy bản PRD chạy cùng logic với source local; khoản xỉ đang làm giảm "Chi phí chung khác".

Dòng này chỉ có Giá trị + Crcy. Không có Mã vật tư, Mat.Type, Origin Group, Đơn giá, Tiêu hao, ĐVT.

## 2. Có đưa thành NVL bình thường được không

Được về mặt kỹ thuật. Dữ liệu cần đều đã có sẵn trong lần gọi CKM3 hiện tại:

- Mã vật tư = từng KALNR/MATNR M47 ở bước 2 (hiện bị gộp thành 1 số).
- Tiêu hao = `-QUANT` của dòng ZU/BF (CKM3 có sẵn số lượng, `GET_CKM3_PRICE` đang dùng field này cho dòng EB).
- Giá trị = `-(STVAL+KDM+PRD)`; Đơn giá = Giá trị / Số lượng.
- Origin Group lấy qua `SET_ORIGIN_GROUP` + bảng `ZCO_T_ORGRP_MAP` (WERKS + MTART = M47).

Cách làm: trong `GET_SLAG_VALUE` thay vì `COLLECT` vào `GT_CC_VALUE` thì `APPEND/COLLECT` từng vật tư M47 vào `GT_LEAF`, gọi trước `SET_ORIGIN_GROUP` / `CALC_LEAF_VALUE`; bỏ `ITEM '22'` khỏi `GT_CC_TEXT` để khỏi tính 2 lần. Thứ tự gọi trong `MAIN_PROC` phải đổi: hiện `CALC_LEAF` chạy trước `GET_ORDER_LIST`, nên cần tách bước lấy slag ra gọi trước khi gom `GT_LEAF` hoặc gọi lại `SET_ORIGIN_GROUP`.

Đã có tiền lệ: cây CKMLQS đã trả các khoản thu hồi (by-product) thành dòng lá NODE `C`, số lượng âm, MATL_TYPE M44/M45/M46/M47 (vd "Than cốc <10mm" M46 −15.190 TAN, "Quặng hồi lò cao" M45, "Quặng hồi máy bản lược" M47). Ghi chú của kế toán (sheet "C.Phụng note") cũng để "Than phế thu hồi" như 1 dòng NVL tiêu hao âm. Trong file export CKMLQS kỳ 03.2025 **không có** dòng nào tên xỉ/slag, nên không thể lấy xỉ từ cây mà phải giữ nguồn CKM3.

Tác động: tổng giá thành **không đổi**. "Chi phí chung khác" tăng thêm 31.930.197.000 (thành 151.314.147.092); nhóm Origin Group chứa xỉ giảm đúng khoản đó.

## 3. Cần quyết định / kiểm tra trước khi sửa

1. Xỉ đưa vào Origin Group nào (nhóm mới "Thu hồi/Xỉ" hay nhóm có sẵn)? Cần thêm dòng M47 vào `ZCO_T_ORGRP_MAP` cho Plant.
2. Hiển thị số âm trên cột Tiêu hao và Giá trị (giống Than phế thu hồi)?
3. Giá trị hiện lấy toàn bộ Receipts → Production của mã M47 trong kỳ, **không giới hạn theo Order của thành phẩm** (Order chỉ dùng để tìm mã). Nếu xỉ cũng phát sinh từ Order của mã khác (vd Gang thỏi) thì bị tính dôi cho thành phẩm này. Cần đối chiếu với MB51 (MVT 531/532 theo Order).
4. Hằng số `GC_CATEG_ZU = 'ZU'`, `GC_PTYP_PROD = 'BF'` và công thức `STVAL+KDM+PRD` (so với `TOTAL`) vẫn ghi "cần đối chiếu CKM3" ở readme_zco07.md mục "Điểm còn mở" số 2, chưa ai xác nhận.
5. Giá trị trong ảnh tròn nghìn (31.930.197.000) cho thấy nhiều khả năng giá xỉ là giá cố định (standard) × số lượng; nên kiểm tra mã M47 có Price control S không.

## 4. Kết quả kiểm tra bằng MCP `GUI_HPDQ_DEV100` (28/10/2026, sau khi user sửa đăng nhập)

Đăng nhập lại được (client 100). Chỉ kiểm tra được phần code/DDIC, không kiểm tra được số liệu vì **client 100 của DEV không có dữ liệu**: `MARA` và `MSEG` rỗng, không có mã 1500010130357, không có MVT 531/532.

| Kiểm tra | Kết quả |
|---|---|
| Source `ZFI_PG_BTGT_07` trên DEV | Cùng logic với bản local: `GET_SLAG_VALUE` ở dòng 1995, `MTART = 'M47'`, `BWART IN ('531','532')`, `CATEG = 'ZU'`, `PTYP = 'BF'`, `STVAL + KDM + PRD`, `ITEM = '22'`, `MINUS` (cùng số dòng) |
| Domain `CKML_CATEG` | `ZU` = Receipts (xác nhận), `EB` = Ending Inventory (xác nhận), `VN` = Consumption. `PTYP` (domain `CKML_PROZESS_TYP`) không có fixed value nên `'BF'` vẫn chưa xác nhận được |
| `FCML4H_COMMON_CCS_S` | Có `KALNR`, `CATEG`, `PTYP`, `QUANT` (số lượng), `MEINS`, `STVAL` = Preliminary Valuation, `PRD` = Price Difference, `KDM` = Exchange Rate Difference, `MARKUP` = Intercompany Profit, `TOTAL` = **Actual Value**, `PRICE` |
| `T134T` | M44 Thành phẩm quặng, M45 Hồi vê viên T.kết lò cao, M46 Than cốc vụn, **M47 Phế liệu thu hồi** |
| `ZCO_T_ORGRP_MAP` (WERKS, MTART, HRKFT) | Rỗng trên DEV, chưa có mapping Origin Group cho M47 |

Điểm rút ra:
- FS yêu cầu "Actual Value dòng Receipts → Production" = `TOTAL`, còn code cộng `STVAL + KDM + PRD`. Hai cách chỉ bằng nhau khi `MARKUP` = 0. Khi chuyển thành NVL nên dùng `TOTAL` (cùng cách `GET_CKM3_PRICE` đang dùng cho dòng EB) hoặc đối chiếu hai cách trên PRD.
- M47 là "Phế liệu thu hồi" chứ không riêng xỉ hạt: điều kiện `MTART = 'M47'` lấy mọi phế liệu thu hồi nhập MVT 531 trên Order, không chỉ xỉ. Dòng 22 có thể đang gồm cả phế liệu khác.
- File `CodeABAP/HPDQ_ZCO07/sql/query_xi_hat_m47_kiem_tra_prd.sql` có 4 câu để user chạy trên PRD: Order của thành phẩm, mã M47 trên các Order đó, cùng mã M47 trên mọi Order (kiểm tra tính dôi), price control và giá.

## 5. Quyết định cuối: bỏ dòng, đã sửa trên DEV100 (28/10/2026 10:58)

User kiểm tra trên PRD/800 kỳ 07.2026: phần NVL (cây CKMLQS) **đã có sẵn** dòng "Xỉ lò cao, hạt rắn", MATL_TYPE M47, mã 1251349900110, đơn giá 200 (VND/KG), tiêu hao −159.650.985 KG, giá trị **−31.930.197.000**, đúng bằng khoản của dòng "Thu hồi xỉ hạt" (159.650.985 × 200 = 31.930.197.000). Nên dòng 22 đang trừ cùng một khoản xỉ hai lần. Hai điều ở mục 2 đã được thay thế:
- "Không có dòng xỉ trong cây CKMLQS": đúng với file export kỳ 03.2025, **sai với PRD kỳ 07.2026**. Không cần đưa xỉ vào NVL vì cây đã trả sẵn.
- "Tổng giá thành không đổi": chỉ đúng nếu chuyển dòng sang NVL. Cách đã chọn là bỏ dòng, nên tổng giá thành **tăng 31.930.197.000** (từ 4.345.299.864.848 lên khoảng 4.377.230.061.848, ước tính theo ảnh PRD kỳ 07.2026) và "Chi phí chung khác" thành 151.314.147.092. Cần user xác nhận khi chạy lại.

Đã làm trên `GUI_HPDQ_DEV100`, package `ZPK_HPDQ`, TR mới **DEVK948212** ("CS_SangVT_28.10.2026_ZCO07_Bo dong Thu hoi xi hat", task DEVK948213, chưa release):
1. `INIT_PROC`: comment `PERFORM ADD_CC_TEXT USING '22' 'Thu hồi xỉ hạt' ABAP_TRUE.` (dòng ~427-432).
2. `MAIN_PROC`: comment `PERFORM GET_SLAG_VALUE.` (dòng ~596-601). FORM `GET_SLAG_VALUE` giữ nguyên (không được gọi).
3. Marker `SangVT comment begin/end 28.10.2026 10:58:35`; cùng thay đổi ở file local `zfi_pg_btgt_07.abap`.

Kiểm tra sau khi ghi: `EditSource` ×2 báo `success` + activation `success`; `REPOSRC` đúng 1 dòng `R3STATE='A'` (cập nhật 10:59:09); source đọc lại đúng, TR chứa đúng `PROG ZFI_PG_BTGT_07`; ATC 0 error, 7 warning (FAE→JOIN, sequential read sorted table, buffered table in JOIN: đều là mẫu cũ), 57 info, không có cảnh báo mới do FORM không được gọi. **Chưa chạy report** (DEV100 không có dữ liệu, `RunReport` bị chặn).

Còn lại: user release/chuyển TR DEVK948212 và chạy lại ZCO07 kỳ 07.2026 để xác nhận dòng 22 biến mất và số tổng đúng. Nếu muốn dọn hẳn code chết thì comment tiếp FORM `GET_SLAG_VALUE` và hằng số `GC_CATEG_ZU`/`GC_PTYP_PROD`.
