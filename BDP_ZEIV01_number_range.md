# ZEIV01 — Number Range được dùng

Hệ: `GUI_BIDIPHAR_DEV100` (DEV, client 100, S/4HANA On-Premise 816, HANA). Ngày kiểm: 29.10.2026.

## Tcode

| Mục | Giá trị |
|---|---|
| Tcode | ZEIV01 (mô tả "ZEIV01") |
| Program / screen | `ZPG_SITG_HDDT_V2` / 1000 |
| Package | `ZPK_BDP` |
| Include của program | `ZIN_SITG_HDDT_V2_TOP`, `_F01`, `_F02`, `_F03`, `_F04`, `ZPG_SITG_HDDT_V2_O01`, `_I01` |

ZEIV01 là Tcode chạy report (hóa đơn điện tử SITG, kèm tích hợp Zalo), không phải Tcode cấu hình Number Range. Nó chỉ **lấy số** từ 2 Number Range object.

## Number Range object

| # | Object (SNRO) | Range nr | Dùng để | Nơi gọi `NUMBER_GET_NEXT` | Đường gọi từ ZEIV01 |
|---|---|---|---|---|---|
| 1 | `ZSKL` | `01` | Số `MAX` kiểu `ZDD_PROXYNO` (mã proxy/số thứ tự gửi hóa đơn điện tử) | FM `ZSITG_FM_GET_MAXNUM` (FG `ZSITG_FG_FUNCTION`, include U01) | `ZFM_SITG_POST_HDDT` (U03) và `ZFM_SITG_CANCEL_HDDT` (U04) đều gọi FM này; ZEIV01 gọi 2 FM đó tại `_F01` dòng 5938, 5998, 6269, 6325 (POST) và 9438, 9455 (CANCEL) |
| 2 | `ZZL_OBJID` | `01` | `OBJECT_ID` của bảng log Zalo `ZTB_ZALO_LOG` (`ZZALO_OBJECT = 'BILLING'`) | FM `ZFM_ZALO_BILLING` (include U13, dòng 66) | FORM `ZALO_BILL` (`_F02`:551) gọi FM này; `PERFORM ZALO_BILL` ở `_F01` dòng 2386, 6110, 6122, 6426, 6438, 11129 |

Ghi chú:
- `ZFM_SITG_POST_PXK` (U05) cũng gọi `ZSITG_FM_GET_MAXNUM`, nhưng ZEIV01 không gọi FM này (chương trình ZPXK gọi, include `ZIN_SITG_ZPXK_F01`).
- Điều kiện gọi `ZALO_BILL` ở `_F01` dòng 6110–6122 và 6426–6438: `SY-MANDT = '400'` hoặc `'320'`, một số nhánh thêm điều kiện BUKRS/BUDAT/FKART/VTWEG. Dòng 2386 và 11129 chưa đọc điều kiện.
- `FORM CHECK_CODE` (`_F01`:11408) cũng gọi `NUMBER_GET_NEXT` với `ZZL_OBJID` / `01`, nhưng không có `PERFORM CHECK_CODE` ở đâu trong program và include → code không chạy.

## Cấu hình Number Range thực tế

Trong DEV100 **cả 2 object đều không tồn tại**: `TNRO`, `TNROT`, `NRIV` rỗng cho `ZSKL`, `ZZL_OBJID` và cả prefix `ZZL%`. Vì vậy chưa có số liệu interval (From/To, External, Current number, Buffer, Domain length). Chạy ZEIV01 ở DEV100 tới đoạn lấy số sẽ gặp exception `OBJECT_NOT_FOUND` (3) của `NUMBER_GET_NEXT`.

Muốn xem cấu hình phải vào hệ đang chạy thật (client 320/400 theo điều kiện trong code, hoặc QAS/PRD) và xem SNRO, hoặc query `TNRO` + `NRIV` + `TNROT` theo object.

## Phạm vi kiểm tra và giới hạn

- Đã quét: program chính + 7 include (tìm `NUMBER_GET_NEXT`, `NUMBER_RANGE*`, `NRIV`, `SNRO`...); function group `ZSITG_FG_FUNCTION` và `LZCORE*` qua bảng `CROSS` (chỉ include `U01`, `U13` của `ZSITG_FG_FUNCTION` gọi `NUMBER_GET_NEXT`; `LZCORE*` không có).
- Không bắt được: lời gọi động (tên FM/object nằm trong biến), class `CL_NUMBERRANGE_RUNTIME`, và code của các FM không có trong DEV100: `ZFM_SITG_CANCEL_HDDT_N`, `ZSITG_FM_GET_CODE_CQT`, `ZFM_SITG_DOWN_HDDT`, `ZSITG_FM_PRINT_HDDT`, `ZFM_DMS_WAREHOUSE_CN` (có trong source ZEIV01, chưa rõ đang active hay nằm trong comment).
- Không đọc code các FM còn lại của `ZSITG_FG_FUNCTION` ngoài `ZSITG_FM_GET_MAXNUM` và `ZFM_ZALO_BILLING`; kết luận cho chúng dựa vào bảng `CROSS`.
