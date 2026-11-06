# BDP – ZPRO: Phân bổ chi phí hàng tặng + 2 báo cáo (hiện trạng DEV, 06.11.2026)

Nguồn: FS `CodeABAP/BDP/ZPRO/BIDIPHAR_FS_SD_ZPRO_ChucNangKhuyenMaiTangHang_V1.0.docx` (v1.0, 17/09/2026).
Hệ: DEV (client 100 = dev, client 200 = test, cùng 1 hệ). Chưa ghi gì lên SAP trong phiên này (chỉ đọc).

## 1. Cách màn hình ZPRO hoạt động

- Tcode `ZPRO` → program `ZSD_PG_PROMOTION_OVEVIEW`, screen 100. Mỗi nút có function code = **Tcode con**; bấm nút → nếu Tcode có trong `TSTC` thì `CALL TRANSACTION`, không có thì báo "Chức năng chưa hoàn thiện".
- 3 nút cần làm (theo comment trong `ZSD_IN_PROMOTION_OVEVIEW_TOP`):

| Nút trên ZPRO | Tcode | Hiện trạng DEV |
|---|---|---|
| Phân bổ chi phí hàng tặng | `ZRB23` | Có Tcode → `ZPRO_PG_CNPBHT` (**code cũ**, xem mục 2) |
| Báo cáo tình hình chi trả hàng tặng | `ZRB32` | **Chưa có Tcode, chưa có program** |
| Báo cáo ngân sách và số suất còn lại | `ZRB35` | **Chưa có Tcode, chưa có program** |

## 2. ZRB23 hiện tại KHÔNG khớp FS

`ZPRO_PG_CNPBHT` (tạo 05.10.2026) là bản kiểu settlement rule/COPA: dùng `COBRB`, `COPA_PROFITABILITY_SEGMENT`, `KOKRS = 'DGWC'`, bảng `ZTB_PRO_CNPBHT`, `ZTB_PRO_ADDFG`, tham số IO + kỳ. FS mới yêu cầu: tham số Company Code/Tháng/Năm/Ngày hạch toán/Promotion/IO/Hình thức/Sales Org, lấy chi phí từ `ACDOCA`, doanh thu từ `VBRK/VBRP`, lưu `ZTB_PROMO_ALLOC`, tạo chứng từ FI bằng `BAPI_ACC_DOCUMENT_POST`, huỷ bằng `BAPI_ACC_DOCUMENT_REV_POST`. Hai bản khác hẳn nhau.

## 3. Bảng/object có sẵn dùng được

- `ZTB_PRO_HEADER` (`PROTYP` Z1/Z2/Z3, `PROAPR` = trạng thái duyệt: **02 = Đã phê duyệt** – cột `PROSTA` là trạng thái thời gian 10/11/12, không phải trạng thái duyệt), `ZTB_PRO_ITEM`, `ZTB_PRO_AUFNR` (IO theo Company Code), `ZTB_PRO_BUDGET`, `ZVBAP` (Promotion theo dòng SO/billing), `ZTB_ZPRR_TICHLUY` (kết quả tính Z3), `ZTB_PRO_MAP_HTPB` (nguồn ngân sách: 01 Marketing, 02 Trade, 03 CSKH).
- **`ZTB_PRO_PHANBO` – "Khai báo tài khoản phân bổ chi phí"**: khoá `BUKRS + PROTYP + SAKNR_SRC`; cột `SAKNR_INT` (TK trung gian), `SAKNR_RCV` (TK nhận phân bổ), `BLART_ALLOC` (loại chứng từ phân bổ), `BLART_SETTLE`. Đúng cái FS gọi là "bảng khai báo tài khoản phân bổ / mục 2.3.1.9".
- Item Category hàng tặng: có 2 bảng ứng viên `ZTB_PRO_ITEMCAT` (`AUART+REGSTA+CONDTYP → PSTYV`) và `ZTB_PRO_MAPCAT` (`AUART+PSTYV+IS_DEFAULT`); FS mô tả "Mapping SO Type – Item Category" có thêm cột loại chương trình/hình thức/nguồn ngân sách → chưa khớp hẳn bảng nào.
- Chưa có: `ZTB_PROMO_ALLOC` (bảng lưu kết quả phân bổ theo FS).

## 4. Dữ liệu client 200 (test), kiểm 06.11.2026

- `ZTB_PRO_HEADER`: 58 promotion (Z1 23, Z2 17, Z3 18), `PROAPR = 02` có nhiều cái (vd Z2 `2000000005/6/7/9/10/11/12/13/14/15/16`).
- `ZVBAP`: 9 dòng, **`VBELN_VF` rỗng hết** (chưa có billing) → chưa có doanh thu để phân bổ.
- `ZTB_PRO_PHANBO`: **rỗng**; `ZTB_PRO_ITEMCAT`: **rỗng**; `ZTB_PRO_MAPCAT`: **rỗng**.
- `ZTB_PRO_BUDGET`: 9 dòng; `ZTB_ZPRR_TICHLUY`: 13 dòng.

→ Báo cáo ngân sách (ZRB35) test được ngay; báo cáo chi trả (ZRB32) test được một phần (13 dòng tích luỹ); phân bổ (ZRB23) cần thêm Customizing + billing + chi phí `ACDOCA` mới test trọn.

## 5. Điểm FS cần chốt/lưu ý

1. Item Category hàng tặng lấy từ bảng nào (`ZTB_PRO_ITEMCAT` hay `ZTB_PRO_MAPCAT`).
2. "GL Account" ở Khung 02 phân bổ: FS trỏ "Mapping hình thức với Material và GL Account" nhưng bảng thực tế (`ZTB_PRO_EXC_CATE`) chỉ có Material; tài khoản nằm ở `ZTB_PRO_PHANBO` → đề xuất lấy từ đó.
3. Tỷ lệ phân bổ: bảng Khung 03 ghi công thức khác bước 3 (6 số lẻ, dồn chênh lệch vào dòng doanh thu lớn nhất) → làm theo bước 3.
4. ZRB35: điều kiện lấy dữ liệu nói "Z2, Z1", tham số nói Z1/Z2/Z3, bảng field nói "chỉ Z2" → đề xuất Z1+Z2.
5. ZRB32: điều kiện nêu hình thức 02/03/06/07, bảng field nêu "02 Tặng hàng tích luỹ" → đề xuất 02/03/06/07.

## 6. Kế hoạch đề xuất (chờ user chốt)

- Object mới (giữ nguyên code cũ `ZPRO_PG_CNPBHT`, không xoá): bảng `ZTB_PROMO_ALLOC`; 3 program mới (ZRB23, ZRB32, ZRB35); Tcode `ZRB32`, `ZRB35` mới và trỏ lại `ZRB23` qua `ZCORE_PG_CSTECH` (user chạy hoặc job nền).
- Package `ZPK_BDP`; TR mới theo quy ước `Tên_Phân hệ_Chức năng_dd.mm.yyyy_Mô tả` (≤ 60 ký tự).
- Làm trên DEV100, test ở client 200 bằng `GUI_BIDIPHAR_DEV200` (client ≠ 80 nên đọc data bằng SQL được).
