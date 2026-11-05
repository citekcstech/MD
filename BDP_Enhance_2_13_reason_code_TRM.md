# BDP — Enhance 2.13: Reason code trên màn hình TRM

Nguồn: `CodeABAP/BDP/Enhance/BIDIPHAR_FI_Enhancement_V1.0_internal.docx`, mục 2.13 (V1.0, 16/06/2026, người thiết kế Nguyễn Thị Tuyết Nhi).
Hệ làm: `GUI_BIDIPHAR_DEV100` (ghi). Test: `GUI_BIDIPHAR_DEV300` (cùng hệ DEV, khác client; object code dùng chung).
Trạng thái (05.11.2026): user đã chốt 3 điểm ở mục 5 → **đã tạo object trên DEV100** (mục 6), implementation BAdI màn hình đã xong (SE19 + MCP điền method), `ZCORE_PG_CSTECH` v8 đã cài (user chọn cách A). Còn thiếu: dynpro 0100 (chờ user chạy F8) và phần hạch toán TBB1 (mục 7.3, đã đổi hướng sang `TPM_ACCIF_TRAC`).

## 1. Yêu cầu trong FS (mục 2.13)

- Hiện trạng: màn hình TRM (`FTR_CREATE`, `FTR_EDIT`) không có Reason code; chứng từ FI sinh từ `TBB1` không có Reason code.
- Yêu cầu: chứng từ hạch toán từ TRM có line **112\*** mang Reason code đã điền ở Transaction.
- Thiết kế nghiệp vụ:
  1. Custom field **Reason code** (search help chuẩn SAP) trên `FTR_CREATE`, `FTR_EDIT`, **tab Payment Details**.
  2. Khi post từ `TBB1`, lấy Reason code **tương ứng với Flow type ở Transaction** điền vào `BSEG-RSTGR` của line 112\*.
- "Mô tả thiết kế kỹ thuật": **để trống** trong FS → phải tự đề xuất (mục 3).

Đánh số mục: FS không gõ số, Word tự đánh theo Heading 2 dưới "2. THIẾT KẾ ENHANCEMENT"; mục lục trong file chỉ cập nhật tới 2.9 (khớp cách đếm này). Thứ tự: 2.10 Segment GL/Profit center GL vào báo cáo chuẩn → 2.11 bắt Funds Center cho line tài sản (MIRO, F-90, MIGO) → 2.12 cảnh báo vượt ngân sách MIGO → **2.13 Reason code trên màn hình TRM** (mục cuối của tài liệu). Nếu user muốn mục khác thì báo lại.

## 2. Hiện trạng hệ (đọc trực tiếp, DEV100/DEV300, 05.11.2026)

| Kiểm tra | Kết quả |
|---|---|
| `VTBFHA` (Transaction TRM) | **0 dòng ở cả client 100 và 300** → chưa có deal để test |
| `BKPF` `AWTYP = 'TRTM'` (client 300) | 0 dòng |
| `TZPA` (**Product type**, khóa `GSART`; client 300) | 120 dòng → có Customizing TRM. Flow type nằm ở `TZB0A` (khóa `SBEWART`, text `TZB0T`); trên deal là `VTBFHAPO-SFHAZBA` (data element `TB_SFHAZBA`, domain `SBEWART`) |
| Field Reason code | `BSEG-RSTGR` (data element `RSTGR`, domain `RSTGR`, DE không gắn search help, giá trị từ `T053R`); **không có** trong `VTBFHA`/`VTBFHAZU`/`VTBFHAPO` |
| `T053R` | giống nhau ở client 100/300: công ty 1000 = 63 dòng, 0001/0003/RECO/REOB/RERF = 12, TH01 = 1 |
| `VTBFHA` có field ZZ/CI include | Không |
| Implementation BAdI `ACC_DOCUMENT` của BDP | Không có (chỉ SAP: `ACC_DOCUMENT_CREDIT`, `GTCN_TR_ACC_DOC`, `IPM_SPLIT_CHECK`, `REIT_ACC_DOCUMENT_DS`, `REXC_IN_BADI_ACC_DOC`, `J_1IG_ACC_DOC_JV`) |
| Mục 2.6–2.8 (BA/Baseline/Assignment cho TRM/TBB1) | Chưa có object Z nào tương ứng trên DEV |

## 3. Đề xuất thiết kế kỹ thuật

### 3.1 Màn hình (FTR_CREATE / FTR_EDIT)

- Cơ chế chuẩn SAP: BAdI **`FTR_CUSTOMER_EXTENT`** (SXSD, IMG "BAdI: Customer Enhancements", interface `IF_EX_FTR_CUSTOMER_EXTENT`, 11 method gồm `EVT_APPLICATION_START` (đăng ký tab qua `PC_TAB_BADI_TABS`), `EVT_TRANSACTION_CHECK`, `EVT_TRANSACTION_SAVE_READY`...). Mẫu SAP: function group `FTR_CUSTOM_BADI_SAMPLE`; API dữ liệu tab: `FTR_API_CUSTOMDATA_GET/SET`.
- **Giới hạn**: BAdI này thêm **tab riêng** ("Customer data") chứ không chèn field vào tab Payment Details có sẵn → lệch FS (xem câu hỏi 2).
- Lưu dữ liệu: bảng Z riêng (khóa `BUKRS` + `RFHA` [+ flow type nếu chọn phương án theo flow type]), field `RSTGR`.
- Cần tạo: function group Z + subscreen (screen/GUI status → qua `ZCORE_PG_CSTECH`, MCP không tạo screen trực tiếp), implementation BAdI (SE19 — MCP chưa chắc ghi được, ghi chú NOTES: include `PROG/I` lỗi `package metadata not found`).

### 3.2 Hạch toán TBB1 (đề xuất ban đầu — **đã thay bằng `TPM_ACCIF_TRAC`, xem mục 7.3**)

- `FTR_TR_TBB1_EXIT` chỉ có `VBUND_EXIT` (trading partner) → **không dùng được**.
- Đề xuất: BAdI **`ACC_DOCUMENT`** (method `CHANGE`, interface `IF_EX_ACC_DOCUMENT`) — implementation Z mới: với chứng từ có nguồn TRM, dòng `HKONT` 112\* → đặt `ACCIT-RSTGR` = Reason code của Transaction (theo flow type). Cần xác nhận khi có deal thật: cách nhận biết chứng từ TRM trong `ACCIT` (`AWTYP`/`AWKEY`) và cách lấy `RFHA` + flow type từ đó.
- Mục 2.6–2.8 (BA/Baseline date/Assignment) cùng luồng TBB1 → nên gộp vào **1 implementation `ACC_DOCUMENT`** để tránh nhiều impl chồng nhau (cần user/FS xác nhận).

## 4. Kế hoạch test ở DEV300 (sau khi code xong)

1. Tạo Transaction ở `FTR_CREATE` (user làm tay vì chưa có deal nào) → nhập Reason code.
2. Lưu, mở lại bằng `FTR_EDIT` → kiểm Reason code hiện đúng.
3. Chạy `TBB1` post flow → đọc `BSEG` (`RSTGR`) của line 112\* bằng `RunQuery` ở DEV300.

## 5. Quyết định của user (05.11.2026)

1. Reason code lưu **theo từng Flow type** (không phải 1 giá trị/Transaction).
2. Chấp nhận **tab riêng** (BAdI `FTR_CUSTOMER_EXTENT`) thay cho "tab Payment Details".
3. Đồng ý tạo object lên DEV100 (TR mới theo quy ước tên team) và test ở DEV300.

Thiết kế theo quyết định 1: tab liệt kê **các Flow type có trong deal** (lấy từ `A_TAB_CASHFLOW`, cột `SFHAZBA`); Flow type chỉ hiển thị, người dùng chỉ chọn Reason code (F4 = search help chuẩn `H_T053R`). Flow type không còn trong deal thì không hiển thị và bị xoá khi lưu.

## 6. Object đã tạo trên DEV100 (TR `DEVK901215`, package `ZPK_BDP`, tên TR `SangVT_FI_TRM_ReasonCode_05.11.2026_Enhance 2.13`)

| Object | Trạng thái | Ghi chú |
|---|---|---|
| Bảng `ZTB_TRM_RSTGR` | Active | Khóa `MANDT`, `BUKRS`, `RFHA`, `SFHAZBA`; field `RSTGR`, `ERNAM`, `ERDAT`, `ERZET` |
| Class `ZCL_TRM_RSTGR` | Active (SyntaxCheck sạch) | Toàn bộ logic: `START`, `GET_ROWS`, `SET_RSTGR`, `IS_EDITABLE`, `IS_CHANGED`, `CHECK` (đối chiếu `T053R` theo `BUKRS`), `SAVE` (xoá + ghi lại theo `BUKRS`/`RFHA`), `FREE` |
| Function group `ZFG_TRM_RSTGR` | Active | Include TOP đã có khai báo + 4 module (`STATUS_0100`, `TC_RSTGR_GET_LINE`, `TC_RSTGR_PUT_LINE`, `F4_RSTGR`); **chưa có dynpro 0100** |
| BAdI implementation `ZCL_IM_FTR_CUSTOMER` (SXCI, BAdI `FTR_CUSTOMER_EXTENT`) + class `ZCL_IM_CL_IM_FTR_CUSTOMER` | Active (SE19, user tạo; MCP điền 13 method, TR task `DEVK901216` thuộc request `DEVK901215`) | 6 method gọi `ZCL_TRM_RSTGR`: `START`, `CHECK` (2 event check), `SAVE`, `IS_CHANGED`, `FREE`. `ZCL_TRM_RSTGR=>START` chỉ đăng ký tab khi dynpro 0100 đã tồn tại (tránh dump `FTR_CREATE`/`FTR_EDIT` khi chưa có screen) |
| `ZCORE_PG_CSTECH`, `_SPEC`, `_RESULT` (`$TMP`) | Active, **v8**, `diff` khớp template 100% | Cài 05.11.2026 theo cách A. Selection text chưa đặt được (xem mục 7.1) |

## 7. Việc còn lại

### 7.1 Dynpro `SAPLZFG_TRM_RSTGR` 0100 (subscreen) — user đã chọn cách A
- **Cách A (đang làm)**: `ZCORE_PG_CSTECH` v8 đã cài. Bước 1 xong (05.11.2026 15:27): đọc mẫu table control `DEMO_DYNPRO_TABLE_CONTROL_1` 0100 OK. Bước 2: spec **CREATE** screen 0100 cho `SAPLZFG_TRM_RSTGR` đã ghi vào `ZCORE_PG_CSTECH_SPEC` (JSON kiểm hợp lệ cục bộ) → user SE38 `ZCORE_PG_CSTECH`, **Transport request = `DEVK901215`**, F8, tick screen 0100 → MCP đọc `ZCORE_PG_CSTECH_RESULT`.
- Include TOP của FG đã chỉnh cho khớp dynpro: cột hiển thị `GS_RSTGR-SFHAZBA`/`RSTGR` rộng 12 ký tự (đủ chỗ tiêu đề cột), chặn nhập Reason code quá 3 ký tự (`RSTGR` dài 3). Lỗi `LS_ROW` khai báo trùng giữa 2 module đã sửa; bài học ghi vào `chuan/CHUAN_CODE_GUI.md`.
- Selection text của `ZCORE_PG_CSTECH` chưa đặt được: `SetTextElements` cần `ZADT_VSP`, endpoint text elements báo `package metadata not found`. Màn hình chọn hiện tên kỹ thuật `P_GRP`/`P_OBJ`/`P_TR`; muốn đẹp thì SE38 → `ZCORE_PG_CSTECH` → Goto → Text elements → Selection texts: `P_GRP` "Hạng mục xử lý", `P_OBJ` "Object đích (program/Tcode..)", `P_TR` "Transport request".
- **Cách B (dự phòng, không cần dùng nữa nếu A chạy được)**: user tạo tay ở SE51, program `SAPLZFG_TRM_RSTGR`, screen `0100`, **Screen type = Subscreen**:
  - Layout: 1 Table control tên `TC_RSTGR`; 2 cột lấy từ program (nút "Get from program"): `GS_RSTGR-SFHAZBA` (đặt **Output only**, tiêu đề "Flow type") và `GS_RSTGR-RSTGR` (cho nhập, tiêu đề "Reason code"). Không bật cột chọn dòng.
  - Flow logic:

```
PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  LOOP WITH CONTROL tc_rstgr.
    MODULE tc_rstgr_get_line.
  ENDLOOP.

PROCESS AFTER INPUT.
  LOOP WITH CONTROL tc_rstgr.
    MODULE tc_rstgr_put_line.
  ENDLOOP.

PROCESS ON VALUE-REQUEST.
  FIELD gs_rstgr-rstgr MODULE f4_rstgr.
```
  - Activate screen + function group, lưu vào TR `DEVK901215`.

### 7.2 Implementation BAdI `FTR_CUSTOMER_EXTENT` — **XONG** (05.11.2026)
User tạo ở SE19 (implementation `ZCL_IM_FTR_CUSTOMER`, class `ZCL_IM_CL_IM_FTR_CUSTOMER`, active); MCP đã ghi thân method đúng như dưới đây:
SE19 → BAdI `FTR_CUSTOMER_EXTENT` → tạo implementation (vd `ZBDP_FTR_CUST_RSTGR`, TR `DEVK901215`), SE19 tự sinh class `ZCL_IM_...`. Thân method (MCP sẽ ghi nếu user báo tên class, hoặc dán tay):

```abap
METHOD if_ex_ftr_customer_extent~evt_application_start.
  zcl_trm_rstgr=>start( EXPORTING io_deal     = pi_proxy_transaction
                                  io_messages = pi_proxy_messages
                        CHANGING  ct_tabs     = pc_tab_badi_tabs ).
ENDMETHOD.

METHOD if_ex_ftr_customer_extent~evt_transaction_check.
  zcl_trm_rstgr=>check( ).
ENDMETHOD.

METHOD if_ex_ftr_customer_extent~evt_transaction_save_check.
  zcl_trm_rstgr=>check( ).
ENDMETHOD.

METHOD if_ex_ftr_customer_extent~evt_transaction_save_ready.
  zcl_trm_rstgr=>save( ).
ENDMETHOD.

METHOD if_ex_ftr_customer_extent~evt_transaction_save_required.
  pe_result = zcl_trm_rstgr=>is_changed( ).
ENDMETHOD.

METHOD if_ex_ftr_customer_extent~evt_application_free.
  zcl_trm_rstgr=>free( ).
ENDMETHOD.
```
Các method còn lại (`EVT_TRANSACTION_FCODE`, `EVT_TRANSACTION_SAVE_CANCEL`, `EVT_BAPI_*`, `EVT_TRANSACTION_DERIVE_DATA`) để trống.

### 7.3 Hạch toán TBB1 → `BSEG-RSTGR` line 112* — **ĐÃ GHI (05.11.2026 15:24), chờ test**
User đồng ý sửa; đã thêm khối `" SangVT add begin/end 05.11.2026 15:24:22` vào cuối `ZCL_IM_ENH_TPM_ACCIF_TRAC~ACCIT_EXIT`, lưu vào request `DEVK901036` (task mới `DEVK901217`; task cũ `DEVK901037` đã release). SyntaxCheck sạch, class active. Logic: `IM_DATA-FLOW_NUMBER` → `VTBFHAPO-RFHAZB` (khóa `BUKRS`+`RFHA`+`RFHAZB`) lấy `SFHAZBA` → đọc `ZTB_TRM_RSTGR` → nếu `HKONT` nợ/có khớp `112*` thì gán `ACCIT-RSTGR`. Không có Reason code thì không làm gì. `HKONT` lấy từ `ACCIT`, trống thì dùng `IM_DATA-GL_ACCOUNT_D/C`.
**Giả định cần kiểm khi test**: (1) `TRACS_EXIT_FLOW-FLOW_NUMBER` (INT4) = `VTBFHAPO-RFHAZB` (NUMC4) — không quy từ `DIS_FLOWTYPE` được vì đó là mã có tiền tố (`CML0110`, `AD1000`, `DBA_A020`...); (2) `ACCIT-RSTGR` được `BSEG-RSTGR` nhận lại khi hạch toán.

Ghi chú cũ (trước khi sửa):
**Không dùng `ACC_DOCUMENT` nữa.** Hệ đã có BAdI `TPM_ACCIF_TRAC` (interface `IF_EX_TPM_ACCIF_TRAC`) do đồng nghiệp (CTQUYBV, 30.10.2026) implement trong class `ZCL_IM_ENH_TPM_ACCIF_TRAC` (package `ZFI_PK_TBB1`) cho enhance 2.7/2.8: method `ACCIT_EXIT` đã nhận `IM_DATA` (kiểu `TRACS_EXIT_FLOW`: `COMPANY_CODE`, `DEAL_NUMBER`, `DIS_FLOWTYPE`, `GL_ACCOUNT_D/C`...) và `CH_ACCIT_D`/`CH_ACCIT_C` (dòng nợ/có của `ACCIT`), chỉ chạy khi `sy-tcode = TBB1` (hoặc `RFTBBB00`/`SAPLTB32NEU`).
- Việc cần làm: thêm 1 khối (marker `SangVT add begin/end`) vào cuối `ACCIT_EXIT`: dòng nợ/có có `HKONT` bắt đầu `112` → `ACCIT-RSTGR` = Reason code đọc từ `ZTB_TRM_RSTGR` theo (`COMPANY_CODE`, `DEAL_NUMBER`, flow type).
- Cần xác nhận khi có deal thật: `TRACS_EXIT_FLOW-DIS_FLOWTYPE` (domain `TPM_DIS_FLOWTYPE`, dài 8) quy về `SFHAZBA` (`TB_SFHAZBA`, dài 4) thế nào; `ACCIT-HKONT` đã có giá trị ở `ACCIT_EXIT` hay phải lấy từ `IM_DATA-GL_ACCOUNT_D/C`.
- **Phải hỏi user trước khi sửa**: class này là của đồng nghiệp, cần biết TR đang chứa và có bị khóa không.

## 8. Điểm chưa kiểm chứng (cần xác nhận khi test ở DEV300)

- `A_EDITMODE` = `'D'` là chế độ xem (đang giả định; sai thì tab vẫn cho nhập ở màn hình xem nhưng không lưu).
- `RFHA` đã có số thật ở event `SAVE_READY` khi tạo deal mới (nếu rỗng, `ZCL_TRM_RSTGR=>SAVE` bỏ qua, không ghi gì).
- Message `T0/101` (text `&`) hiển thị đúng lỗi Reason code không hợp lệ.
- Flow của deal mới đã có trong `A_TAB_CASHFLOW` lúc mở tab.

## 9. Kế hoạch test ở DEV300 (sau khi xong 7.1–7.3)

1. `FTR_CREATE` tạo deal → tab "Reason code" hiện các Flow type của deal → chọn Reason code (F4) → lưu.
2. `FTR_EDIT` mở lại → Reason code giữ nguyên; đổi 1 giá trị, lưu; nhập Reason code sai → báo lỗi.
3. Kiểm bảng: `SELECT * FROM ztb_trm_rstgr` ở DEV300.
4. `TBB1` post flow → `BSEG-RSTGR` của line 112* bằng `RunQuery` ở DEV300 (sau khi xong 7.3).
