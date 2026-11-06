# BDP – Dump SYNTAX_ERROR 06.11.2026 13:53:42 (enhancement ZQM_EI_QM04_STKCHG)

File dump: `CodeABAP/BDP/Dump/SYNTAX_ERROR_20261106_135342.zip` — kiểm trên `GUI_BIDIPHAR_DEV100` (DEV, client 100, release 816). Dump xảy ra ở **client 500**, user `CT.MM`, Tcode `/SCWM/PRDO` → program `/SCWM/TO_CONF` (màn Confirm Warehouse Task, kho W498).

## 1. Tóm tắt dump

| Mục | Giá trị |
|---|---|
| Runtime error | `SYNTAX_ERROR` — program `/SCWM/SAPLGMVT` (function group `/SCWM/GMVT`, "Stock Changes") |
| Lỗi cú pháp | Include `ZQM_EI_QM04_STKCHG====…E` dòng 5: `The field "IS_HEADER" cannot be modified.` |
| Chỗ dump | `/SCWM/SAPLL03A` form `TO_ASSIGN_QUANT`, include `/SCWM/LL03AF06` dòng 786: `CALL FUNCTION '/SCWM/GM_ORDIM_INFO'` |
| Tác giả / người sửa cuối include | `CT.ABAP` |

Dump **không phải lỗi của `/SCWM/TO_CONF`**. Lần gọi `/SCWM/GM_ORDIM_INFO` buộc hệ thống nạp program `/SCWM/SAPLGMVT`; program này không generate được vì có 1 dòng sai trong enhancement của Z.

## 2. Nguyên nhân gốc

Enhancement implementation `ZQM_EI_QM04_STKCHG` (ENHO/XHH, package `ZPK_QM`, mô tả "QM04 enhance"; ThaoNTT 05.11.2026 11:43:36) là implicit enhancement **đầu FM `/SCWM/STOCK_CHANGE`**. Toàn bộ nội dung:

```abap
ENHANCEMENT 1  .
" ThaoNTT add begin 05.11.2026 11:43:36
" FS QM.04 - gan Posting Date nguoi dung chon vao BUDAT cua Material Document EWM
zqm_cl_qm04_post=>apply_budat( CHANGING cs_header = is_header ).
" ThaoNTT add end 05.11.2026 11:43:36
ENDENHANCEMENT.
```

Trong `/SCWM/STOCK_CHANGE`, `is_header TYPE /scwm/s_gmheader` khai báo ở nhóm **IMPORTING** (truyền tham chiếu, chỉ đọc), nên không thể làm tham số thực của `CHANGING cs_header` (method `ZQM_CL_QM04_POST=>APPLY_BUDAT` khai `CHANGING cs_header TYPE /scwm/s_gmheader`).

Syntax check khi activate ENHO không bắt được lỗi này; chỉ lộ ra khi program chủ (`/SCWM/SAPLGMVT`) được generate lúc chạy.

## 3. Phạm vi ảnh hưởng

- Mọi FM trong function group `/SCWM/GMVT` đều dump khi được gọi lần đầu trong session: `/SCWM/STOCK_CHANGE`, `/SCWM/GM_CREATE`, `/SCWM/GM_POST`, `/SCWM/GM_CANCEL`, `/SCWM/GM_ORDIM_INFO`, `/SCWM/DIFFERENCE_POST`… tức mọi giao dịch EWM chuyển hàng/xác nhận TO/kiểm kê trên DEV.
- ENHO là object cross-client → lỗi cho mọi client của hệ DEV (không riêng client 500).
- TR (kiểm 06.11.2026 qua `GetTransport`): `ZQM_CL_QM04_POST` và cả 4 enhancement `ZQM_EI_QM04_*` (TOP, UCOMM, BSAVE, STKCHG) đều nằm trong **`DEVK900814`** (task `DEVK900815`, owner `CT.ABAP`, mô tả `ThaoNTT_QM_Enhance_QM01_21.10.2026_Create`, target PRD, status **Modifiable = chưa release**) → QAS/PRD chưa nhận lỗi. TR này gộp 26 object (QM01 LMN, SIGN, UD_DATE, QM04…): release nguyên TR sẽ mang theo enhancement lỗi → sửa/gỡ `ZQM_EI_QM04_STKCHG` trước khi release.

## 4. Vấn đề thứ hai (chức năng) — sửa cú pháp xong vẫn có thể không ra kết quả mong muốn

Class `ZQM_CL_QM04_POST=>APPLY_BUDAT` ghi `cs_header-mmim_budat_migration` khi `cs_header-code = 'QINSP'` (QM follow-up). Nhưng trong `/SCWM/GM_CREATE` (dòng 1416-1418):

```abap
" relevant scenarios for variable posting date are migration and cancellation of migration via adgi transaction
IF gs_global-code = wmegc_gmcode_init_load OR
   gs_global-code = wmegc_gmcode_giscrap AND gs_global-cancel = abap_true.
  ls_ordim_c-mmim_budat_migration = is_header-mmim_budat_migration.
ENDIF.
```

→ SAP chỉ chép `mmim_budat_migration` sang `ORDIM_C` cho **migration** (`init_load`) và **hủy migration** (`giscrap` + cancel). Với `QINSP` giá trị bị bỏ qua. Đã grep `budat` trong các include `/SCWM/LGMVTF01..F23`, `/SCWM/LGMVT$01..$11`, FM `GM_POST`, `GM_ORDIM_INFO`: không có chỗ nào khác đọc trường này (chưa grep `$12-$17`, TOP, UXX). Chưa debug để xác nhận nơi tiêu thụ cuối cùng của `ORDIM_C-MMIM_BUDAT_MIGRATION`.

Ngoài ra, `/SCWM/STOCK_CHANGE` chép `ls_header = is_header` ở dòng 1740 rồi gọi `/SCWM/GM_CREATE` với `ls_header` (dòng 1864). Hook đầu FM chạy **trước** dòng 1740 nên dù sửa `is_header` được cũng không đổi được gì mong muốn ngoài việc ghi đè dữ liệu của caller. Trong `/SCWM/STOCK_CHANGE` không có `ENHANCEMENT-POINT/SECTION` hay BAdI để chèn giữa dòng 1740 và 1864.

## 5. Hướng xử lý

1. **ĐÃ LÀM 06.11.2026 14:30 (user đồng ý)**: comment dòng 5 của `ZQM_EI_QM04_STKCHG` bằng `EditSource` (`syntax_check=false`, `transport=DEVK900814`), marker `" SangVT comment begin/end 06.11.2026 14:30:21`, đã activate. Đọc lại source: dòng `*zqm_cl_qm04_post=>apply_budat( ... )` đã comment. `SyntaxCheck` toàn program `/SCWM/SAPLGMVT` sau đó chỉ còn warning (W) của code SAP chuẩn, không còn lỗi `IS_HEADER cannot be modified`. **Chưa** retest thực tế `/SCWM/PRDO` (user kiểm). Hệ quả: `APPLY_BUDAT` không còn được gọi → QM.04 không gán Posting Date vào header GM (vốn cũng không có tác dụng với `QINSP`, xem mục 4).
2. **Làm lại thiết kế QM.04 (Posting Date khi UD hàng EWM)**: không dùng `mmim_budat_migration` cho `QINSP`. Cần tìm điểm hook đúng ở bước posting sang ERP/MM (BAdI hoặc enhancement ở đoạn tạo Material Document), hoặc caller phía QA32 → EWM Inspection (`/SCWM/SAPLQUI_INSP_EXT`) nơi header còn ghi được. Chưa khảo sát trên hệ.
3. Không dùng thủ thuật `ASSIGN is_header TO <fs>` để ghi vào tham số read-only: ghi đè dữ liệu của caller, chưa kiểm, không khuyến nghị.

## 6. Object liên quan (DEV100)

- `ZQM_EI_QM04_STKCHG` (ENHO/XHH) — đầu FM `/SCWM/STOCK_CHANGE` — **nguồn lỗi**.
- `ZQM_EI_QM04_BSAVE` (ENHO/XHH) — popup nhập Posting Date khi `sy-ucomm = 'TAKEOVER'/'SAVE'`, gọi `ZQM_CL_QM04_POST=>POPUP_BUDAT( )`.
- `ZQM_EI_QM04_TOP` (ENHO/XHH) — `DATA gv_zz_budat TYPE budat` cuối include TOP FUGR `/SCWM/QUI_INSP_EXT`.
- `ZQM_EI_QM04_UCOMM` (ENHO/XHH, "Popup QM04") — chưa đọc nội dung.
- `ZQM_CL_QM04_POST` (class, `POPUP_BUDAT`, `APPLY_BUDAT`).

## 7. Lưu ý công cụ (GUI_BIDIPHAR_DEV100)

- Tên include trong dump dạng `ZQM_EI_QM04_STKCHG============E` (ENHO) → `GetInclude`/`GetSource(INCL)` lỗi 500 `Resource PROGRAM … could not be successfully read`.
- Đọc được ENHO/XHH bằng `GrepObject` với `object_url=/sap/bc/adt/enhancements/enhoxhh/<tên chữ thường>/source/main`, `pattern=.` (in toàn bộ dòng, có số dòng).
- `GetInactiveObjects` chỉ liệt kê object của user đăng nhập MCP (`CT.CSTECH`), không phản ánh bản inactive của user khác.
