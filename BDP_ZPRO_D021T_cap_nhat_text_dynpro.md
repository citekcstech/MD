# BDP — Cập nhật D021T (text dynpro ZSD_PG_PROMOTION) từ ZPRO_TEXT.xlsx

- Nguồn: `CodeABAP/BDP/ZPRO/ZPRO_TEXT.xlsx` (sheet `Data`, 33 dòng, 5 cột: Program Name | Dynpro No. | Lang. | Field name | Dynpro Key Word Text).
- Đích: `GUI_BIDIPHAR_DEV100` (DEV, client 100, S/4HANA 816, HANA) — bảng `D021T` ("Dynpro Schluesselworttexte", delivery class W).
- Khóa D021T: `PROG` + `DYNR` (NUMC 4) + `LANG` + `FLDN`; cột text `DTXT` (CHAR 132).
- Quy đổi khi ghi: `Dynpro No.` `200` → `DYNR = '0200'`; `Lang.` `EN` → `LANG = 'E'`.

## Kết quả đối chiếu (đọc DEV100 ngày 01.11.2026, chưa ghi gì)

- Cả 33 khóa trong Excel **đã có sẵn** ở D021T (LANG = E) → toàn bộ là **UPDATE DTXT**, không INSERT.
- 33 dòng này chính là **toàn bộ** các dòng D021T của `ZSD_PG_PROMOTION` đang bị hỏng dấu tiếng Việt (ký tự có dấu bị thay bằng `#`). Excel là bản text đúng.
- Độ dài text lớn nhất trong Excel = 23 ký tự (≤ 132). Tất cả đã chuẩn NFC, không có ký tự lạ.

| Dynpro | Field name | Text hiện tại (DEV100) | Text mới (Excel) |
|---|---|---|---|
| 0200 | BT_CHKREL | Ki#m tra quan h# | Kiểm tra quan hệ |
| 0200 | CS_NGUONG | C# s# ng##ng | Cơ sở ngưỡng |
| 0200 | DKTQ | #i#u ki#n tiên quy#t | Điều kiện tiên quyết |
| 0200 | GXHDHT | Giá xu#t H# hàng t#ng | Giá xuất HĐ hàng tặng |
| 0200 | TGTPCL | Tính trên ph#n còn l#i | Tính trên phần còn lại |
| 0200 | TS_0200_FC10 | Doanh thu ##ng ký | Doanh thu đăng ký |
| 0200 | TS_0200_FC11 | Ch##ng trình #ính kèm | Chương trình đính kèm |
| 0200 | ZST_PRO_D03-ACCRRATE | T# l# trích tr##c | Tỷ lệ trích trước |
| 0200 | ZST_PRO_D03-CHKCOND | #i#u ki#n ki#m tra | Điều kiện kiểm tra |
| 0200 | ZST_PRO_D03-CONDTYPE2 | Lo#i #i#u ki#n | Loại điều kiện |
| 0200 | ZST_PRO_D03-DISCTYPE | Lo#i chi#t kh#u | Loại chiết khấu |
| 0200 | ZST_PRO_D03-FOCPRICE | ##n giá hàng t#ng | Đơn giá hàng tặng |
| 0200 | ZST_PRO_D03-FORM | Hình th#c | Hình thức |
| 0200 | ZST_PRO_D03-NGANSACH | Ngu#n ngân sách | Nguồn ngân sách |
| 0200 | ZST_PRO_D03-PAYTYPE | Lo#i chi tr# | Loại chi trả |
| 0200 | ZST_PRO_D03-SCALE | M#c/Scale | Mức/Scale |
| 0200 | ZST_PRO_D03-SUBPRO | Ch##ng trình con | Chương trình con |
| 0210 | BAO_LUU_CT | B#o l#u chi tr# | Bảo lưu chi trả |
| 0210 | CACH_XDK | Cách xét #i#u ki#n | Cách xét điều kiện |
| 0210 | DKGT_TXT | ##ng ký giá tr# | Đăng ký giá trị |
| 0210 | DONG_GN | Dòng ghi nh#n | Dòng ghi nhận |
| 0210 | HAN_CTD | H#n chi tr# ##n | Hạn chi trả đơn |
| 0210 | HINH_THUC_TXT | Hình th#c IO | Hình thức IO |
| 0210 | KY_TTL | K# tính tích lu# | Kỳ tính tích luỹ |
| 0210 | LOAI_AD | Lo#i áp d#ng | Loại áp dụng |
| 0210 | SALE_OFPT | Sales Office Ph# Trách | Sales Office Phụ Trách |
| 0210 | ZST_PRO_H01-EXTNR | Mã ch##ng trình | Mã chương trình |
| 0210 | ZST_PRO_H01-PROAPR | Tr#ng thái ch##ng trình | Trạng thái chương trình |
| 0210 | ZST_PRO_H01-PRODES | Tên ch##ng trình | Tên chương trình |
| 0210 | ZST_PRO_H01-PROFWK | Hình th#c ch##ng trình | Hình thức chương trình |
| 0210 | ZST_PRO_H01-PROTYP | Lo#i ch##ng trình | Loại chương trình |
| 0350 | NAME_PG | Tên ch##ng trình | Tên chương trình |
| 0350 | NUM_PG | Mã ch##ng trình | Mã chương trình |

## Lưu ý

- Không có tool MCP ghi thẳng bảng. `ExecuteABAP` mức `dangerous` **không dùng được** trên `GUI_BIDIPHAR_DEV100` (xem mục Trạng thái). Ghi trực tiếp DB (UPDATE/MODIFY bằng ABAP) **không sinh TR** → không tự đi sang QAS/PRD; muốn transport phải làm qua SE63/SE51.
- Dynpro load có thể cache text cũ: nếu mở màn hình chưa thấy đổi, generate lại dynpro (SE51).
- Ngoài phạm vi Excel, D021T của cùng program còn vài dòng nghi lỗi font: `0200 ZST_PRO_D03-UNITFG1` = "ÐVT FOC" và `0340 CMND_NDD` = "CMND NÐD" (chữ `Ð` thay `Đ`). Chưa đụng tới.

## Trạng thái

- [x] User đã xác nhận ghi trực tiếp (01.11.2026).
- [x] **ĐÃ GHI XONG trên `GUI_BIDIPHAR_DEV100` (01.11.2026).**
  - Lần 1 (trước khi user cấp quyền): `ExecuteABAP` `dangerous` báo `Success: true` nhưng `0.000 s`, không alert, D021T không đổi (mức `dangerous` chưa chạy được).
  - Lần 2 (sau khi user cấp quyền): `ExecuteABAP` `dangerous` chạy thật (`0.100 s`): `UPDATE d021t` 33 khóa + `COMMIT WORK` → `updated=33`, `mismatch_after_commit=0`.
  - Kiểm độc lập bằng `RunQuery`: không còn dòng nào có `#` ở dynpro 0200/0210/0350 của `ZSD_PG_PROMOTION`; 33 text khớp Excel. Các dòng ngoài Excel (`ÐVT FOC`, `Valid From(*)`...) không bị đổi.
- **Việc còn lại (ngoài MCP):** thay đổi này ghi thẳng DB, **không có TR** → QAS/PRD vẫn còn text hỏng. Muốn đưa sang hệ khác phải chạy lại cùng cách trên từng hệ, hoặc dịch/sửa lại qua SE63/SE51 gắn TR. Nếu màn hình chưa hiện text mới thì generate lại dynpro (SE51). Hai dòng nghi lỗi font ngoài Excel (`0200 ZST_PRO_D03-UNITFG1`, `0340 CMND_NDD`) chưa xử lý.
