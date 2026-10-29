# ZEIV01 / ZEIV02 — Number Range được dùng

Hệ: `GUI_BIDIPHAR_DEV100` (DEV, client 100, S/4HANA On-Premise 816, HANA). Ngày kiểm: 29.10.2026.

Cả 2 Tcode là Tcode chạy report (hóa đơn điện tử SITG), không phải Tcode cấu hình Number Range. Chúng chỉ **lấy số** từ các Number Range object bên dưới.

## Tổng hợp

| Object (SNRO) | Range | ZEIV01 | ZEIV02 | Tồn tại ở DEV100? |
|---|---|---|---|---|
| `ZSKL` | `01` | Có | Có | Không |
| `ZZL_OBJID` | `01` | Có | Không | Không |
| `ZFKEY` | `01` | Không | Có | Không |

Cả 3 object đều **không tồn tại trong DEV100**: `TNRO`, `TNROT`, `NRIV` rỗng cho `ZSKL`, `ZZL_OBJID`, `ZFKEY` (và cả prefix `ZZL%`). Vì vậy chưa có số liệu interval (From/To, External, Current number, Buffer, Domain length). Chạy 2 Tcode này ở DEV100 tới đoạn lấy số sẽ gặp exception `OBJECT_NOT_FOUND` (3) của `NUMBER_GET_NEXT`. Muốn xem cấu hình phải vào hệ đang chạy thật (client 320/400 theo điều kiện trong code, hoặc QAS/PRD): SNRO hoặc query `TNRO` + `NRIV` + `TNROT` theo object.

## ZEIV01

| Mục | Giá trị |
|---|---|
| Program / screen | `ZPG_SITG_HDDT_V2` / 1000 |
| Package | `ZPK_BDP` |
| Include | `ZIN_SITG_HDDT_V2_TOP`, `_F01`, `_F02`, `_F03`, `_F04`, `ZPG_SITG_HDDT_V2_O01`, `_I01` |

| # | Object | Range | Dùng để | Nơi gọi `NUMBER_GET_NEXT` | Đường gọi từ ZEIV01 |
|---|---|---|---|---|---|
| 1 | `ZSKL` | `01` | Số `MAX` kiểu `ZDD_PROXYNO` (mã proxy/số thứ tự gửi hóa đơn điện tử) | FM `ZSITG_FM_GET_MAXNUM` (FG `ZSITG_FG_FUNCTION`, include U01) | `ZFM_SITG_POST_HDDT` (U03) và `ZFM_SITG_CANCEL_HDDT` (U04) đều gọi FM này; ZEIV01 gọi 2 FM đó tại `_F01` dòng 5938, 5998, 6269, 6325 (POST) và 9438, 9455 (CANCEL) |
| 2 | `ZZL_OBJID` | `01` | `OBJECT_ID` của bảng log Zalo `ZTB_ZALO_LOG` (`ZZALO_OBJECT = 'BILLING'`) | FM `ZFM_ZALO_BILLING` (include U13, dòng 66) | FORM `ZALO_BILL` (`_F02`:551) gọi FM này; `PERFORM ZALO_BILL` ở `_F01` dòng 2386, 6110, 6122, 6426, 6438, 11129 |

Ghi chú:
- Điều kiện gọi `ZALO_BILL` ở `_F01` dòng 6110–6122 và 6426–6438: `SY-MANDT = '400'` hoặc `'320'`, một số nhánh thêm điều kiện BUKRS/BUDAT/FKART/VTWEG. Dòng 2386 và 11129 chưa đọc điều kiện.
- `FORM CHECK_CODE` (`_F01`:11408) cũng gọi `NUMBER_GET_NEXT` với `ZZL_OBJID` / `01`, nhưng không có `PERFORM CHECK_CODE` ở đâu trong program và include → code không chạy.

## ZEIV02

| Mục | Giá trị |
|---|---|
| Program / screen | `ZSITG_PG_ZPXK` / 1000 |
| Package | `ZPK_BDP` |
| Include | `ZIN_SITG_ZPXK_TOP`, `_F01`, `_O01`, `_I01` (chỉ `_F01` có logic lấy số) |

| # | Object | Range | Dùng để | Nơi gọi | Đường gọi từ ZEIV02 |
|---|---|---|---|---|---|
| 1 | `ZSKL` | `01` | Số `MAX` kiểu `ZDD_PROXYNO` (`LW_MAX`), lấy khi `LS_ALV-PROXYNO` rỗng | **Trực tiếp:** `CALL FUNCTION 'ZSITG_FM_GET_MAXNUM'` ở `_F01`:3255 trong `FORM POST_DATA_N`. **Gián tiếp:** `ZFM_SITG_POST_PXK` (U05) và `ZFM_SITG_CANCEL_HDDT` (U04) cũng gọi `ZSITG_FM_GET_MAXNUM` | `POST_DATA_N` ← `PERFORM` ở `_F01`:1894 (trong `FORM HANDLE_USER_COMMAND`); `ZFM_SITG_POST_PXK` gọi tại 2770, 2808, 3079, 3116; `ZFM_SITG_CANCEL_HDDT` gọi tại 4283, 4301 (`FORM CANCEL_DATA`) |
| 2 | `ZFKEY` | `01` | Số `LW_FKEY` (khóa FKEY của hóa đơn) khi `GS_ALV-BELNR` rỗng | `NUMBER_GET_NEXT` gọi thẳng trong `FORM PROC_DATA` (`_F01`:3493) và `FORM PROC_DATA_TT` (`_F01`:3820), `NR_RANGE_NR = '01'` | `PROC_DATA` ← `PERFORM` ở 2760, 2974, 4692; `PROC_DATA_TT` ← `PERFORM` ở 3009, 3067, 4644. Các form này chạy qua nút ALV (`HANDLE_USER_COMMAND`: POST_DATA, POST_DATA_N, EX_JSON, EX_JS_TT) và các form in (`PRINT_PREVIEW`, `PRINT_PREVIEW_TT`) |

Ghi chú:
- ZEIV02 **không** dùng `ZZL_OBJID` (không gọi `ZFM_ZALO_BILLING`).
- Mục đích chính xác của `LW_FKEY` suy ra từ code quanh dòng 3493/3820 và các chỗ `LW_FKEY = GS_ALV-BELNR` khi gọi `ZFM_SITG_GET_CODE_CQT`; chưa đọc toàn bộ cách giá trị này được đưa vào payload JSON.
- `ZFM_SITG_POST_PXK` (U05) và `ZFM_SITG_CANCEL_HDDT` (U04) không gọi `NUMBER_GET_NEXT` trực tiếp; chúng đi qua `ZSITG_FM_GET_MAXNUM` (kiểm bằng bảng `CROSS`).

## Phạm vi kiểm tra và giới hạn

- Đã quét: program chính + include của từng Tcode (tìm `NUMBER_GET_NEXT`, `NUMBER_RANGE*`, `NRIV`, `SNRO`...); function group `ZSITG_FG_FUNCTION` và `LZCORE*` qua bảng `CROSS` (chỉ include `U01`, `U13` của `ZSITG_FG_FUNCTION` gọi `NUMBER_GET_NEXT`; `LZCORE*` không có).
- Không bắt được: lời gọi động (tên FM/object nằm trong biến), class `CL_NUMBERRANGE_RUNTIME`, và code của các FM không có trong DEV100: `ZFM_SITG_CANCEL_HDDT_N`, `ZSITG_FM_GET_CODE_CQT`, `ZFM_SITG_DOWN_HDDT`, `ZSITG_FM_PRINT_HDDT`, `ZFM_DMS_WAREHOUSE_CN` (có trong source, chưa rõ đang active hay nằm trong comment).
- Không đọc code các FM của `ZSITG_FG_FUNCTION` ngoài `ZSITG_FM_GET_MAXNUM` và `ZFM_ZALO_BILLING`; kết luận cho các FM còn lại dựa vào bảng `CROSS`.
