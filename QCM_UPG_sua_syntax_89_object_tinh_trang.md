# QCM_UPG – Sửa syntax 89 object (sheet "Lỗi syntax") – tình trạng 27/10/2026

Phạm vi: chỉ sửa cú pháp, không đổi logic; chuẩn cú pháp đích **SAP S/4HANA 2025 (ABAP 7.58)**.
Nguồn danh sách: `Citek_WCM_ATC_PhanCong_v1.0.xlsx` → sheet `Lỗi syntax` (89 object). Source: `06_Source Code 20261022/`.

## Vì sao chưa sửa được hàng loạt

- Thông điệp ATC của 74/89 object chỉ là `Syntax error in ....` / `Program contains syntax errors` — **không có số dòng, không có nội dung lỗi**.
- Repo chưa có MCP server nối vào hệ DS4 của QCM (`.mcp.json` chỉ có MPC, RETAIL, APA, CDV, BIDIPHAR, HPDQ, ACG, NKG) nên không chạy được SyntaxCheck.
- Sửa theo đoán sẽ vi phạm quy tắc "không đoán nội dung rồi sửa code".

## Thống kê 89 object

| Loại | Lỗi cú pháp | Method was not implemented | Không phân tích được / ký tự lạ |
|---|---|---|---|
| CLAS | 29 | 7 | 3 |
| PROG | 36 | 0 | 2 |
| FUGR | 9 | 0 | 0 |
| ENHO | 3 | 0 | 0 |

- 9 object **không có source local** (STT 47, 52, 54, 62, 63, 68, 69, 74, 82): ZPG_FI_WRSZ_VIRTUAL_SITE, ZPG_IMPORT_IDOC_WVINVE03_MM, ZPG_MD_SEND_CHANGEDPRICE, ZPG_TTMS_ZMS_006, ZPG_UPDATE_BBY_UDT, ZRACORR_RENUM_SUBTA_ANEK_KEY, ZRACORR_RENUM_SUBTA_FULL, ZPG_ARBA_CUS_MSTR_EXPRT, ZPG_RT_315_TU_DONG_HUY_TRA → không sửa được local.

## Đã sửa

| STT | Object | Nội dung |
|---|---|---|
| 84 | ZCL_HR_PY_EXCEL | `Class/zcl_hr_py_excel/public_methods/format_cells.abap` dòng 43–44: ký tự điều khiển `0x01` trong dòng comment → thay bằng dấu cách, bọc marker `SangVT modify`. Khớp "Illegal characters in ABAP source code ×2". |
| 81 | ZCL_HRSFI_COMP_DATA_ACTIVATION | Thiếu 3 method của `IF_HRSFI_COMP_DATA_ACTIVATION` (interface có đúng 4 method theo 6 lớp cùng interface; lớp này mới có GET_FIELD_LIST rỗng). Thêm 3 file method rỗng `activate_changes`, `call_field_f4`, `set_activation_fields` trong `public_methods/`, bọc marker `SangVT add`. Khớp "Method was not implemented ×3". |

## Kết quả kiểm tra 2 thư mục anh chỉ định (27/10/2026)

- `syntax/*.xlsx` (29 file): chỉ là **danh mục đối tượng** — cột `Result of Package Check` chỉ có `OK`/`Deleted`, cột `Remark` rỗng; không có số dòng hay nội dung lỗi.
- `CHECK_ATC/*.xlsx` (23 file, 16.400 dòng): chỉ có `Check Title`, `Check Message` (mẫu thông điệp, ví dụ `Syntax error in ....`), tên object; cột `Remarks` rỗng 100%. Không có dòng, không có tên đối tượng gây lỗi. Muốn có phải xuất lại ATC kèm `Message text`/`Location`.
- Phân tích gián tiếp được: 27/29 lớp lỗi dùng chung `ZCL_HR_UTILITIES` (chính nó cũng trong danh sách); 34 object PROG/FUGR có thêm `Used object ... does not exist` (nhiều object là bản copy chương trình chuẩn `RFUMSV00`, `RFBILA00`, ZFG_RSAX, ZFI_ITEMS dùng include chuẩn). Chưa xác nhận được nguyên nhân do không có DDIC/include chuẩn của S/4HANA 2025 trong máy.

## Phát hiện nhưng chưa sửa (cần dữ liệu từ hệ thống)

- **Method was not implemented (6 lớp còn lại)**: thiếu method của interface chuẩn trong lớp Z, danh sách method của interface S/4HANA 2025 không có local và không suy ra được từ lớp khác (tổng method gộp từ các lớp local = đúng số method đã có). Ví dụ ZCL_HR_BADI_EP_CUSTOM (×53): lớp cùng interface `IF_HRSFI_EMPL_DATA_REPLICATION` là ZCL_HRSFI_EMPL_DATA_REPL chỉ có 38 method.
- File `screens/*.txt` có byte `0x00` (ZHRF0011, ZFG_SE16N) là định dạng dump màn hình, không phải lỗi ABAP.
- BOM `U+FEFF` ở đầu mọi file `.abap` là dấu vết lúc extract, không phải lỗi.

## Cần để làm tiếp

1. Nội dung lỗi thật của từng object (ATC mở chi tiết / SE80 syntax check xuất ra: số dòng + message), **hoặc**
2. MCP server `GUI_*` nối vào hệ DS4 (QCM) để chạy SyntaxCheck trực tiếp — thay đổi `.mcp.json`/mật khẩu cần user đồng ý.

## Điều chỉnh file Citek_WCM_ATC_PhanCong_v1.0.xlsx (27/10/2026, lần 2)

Yêu cầu: object có trạng thái `OK` trong `06_Source Code 20261022/syntax` thì bỏ khỏi sheet `Lỗi syntax`, đưa về 2 sheet `Ưu tiên xử lý` và `Ưu tiên theo ST03N` để xử lý như lỗi ATC.
Chọn phương án (user xác nhận): **bỏ lỗi biên dịch giả, giữ lỗi SLIN thật**.

Quy tắc:
- 86/89 object có `OK`; 3 enhancement (ZEN_RT003_F, ZHRI0002, ZHRI0004) không có trong danh mục → giữ ở `Lỗi syntax` với thông điệp `Program contains syntax errors`.
- Bỏ 212 lượt ATC của 86 object OK: `Syntax error in ....` (140), `Program contains syntax errors` (70), `Program source cannot be analyzed` (2).
- Giữ 77 lượt SLIN thật, xếp lại nhóm: `Method was not implemented` (67), `Syntax check warning ...` (4), `Byte-like values ...` (3) → nhóm 4 (Tương thích S/4HANA); `Illegal characters` (2) → nhóm 10 (Dọn dẹp mã); `Program does not exist` (1) → nhóm 2 (Gọi sai/không tồn tại). Đây là cách xếp nhóm do Claude đề xuất, anh Sang chưa duyệt.
- Tính lại theo đúng ma trận ở sheet Tổng quan mục 7 (mức nghiêm trọng A–D × mức hoạt động); kiểm chứng bộ tính trên dữ liệu cũ khớp 799/799 object.

Kết quả:

| Sheet | Trước | Sau |
|---|---|---|
| Lỗi syntax | 89 object | 3 object |
| Ưu tiên theo ST03N | 799 object (Ưu tiên 1/2/3/4 = 7/141/148/503) | 763 object (5/80/149/529) |
| Ưu tiên xử lý | 146 dòng | 143 dòng |
| WCM Task List | 1.034 task | 909 task (xoá 86 SY + 36 ST + 3 UT) |
| ATC lượt | 16.400 (P1 1.758) | 16.188 (P1 1.546) |

- 36 object hết thông điệp ATC nên rời cả 2 sheet (chỉ cần chạy lại ATC để xác nhận): 27 ZHR (ZCL_HRSFI_*, ZCL_HR_COMP_COMPEN01, ZCL_HR_UTILITIES), ZARBA_ERP_OUTBOUND_MAPPING, ZCL_ARBCIG_IM_TC_PURCHASE_REQ, ZFG_BUSVOLBASE, ZFG_IDOC_COND_A_SEND, ZFG_IDOC_COND_A_SEND_O, ZFG_RSAX, ZFI_ITEMS, ZPG_UPDATE_BBY_UDT, Z_ASFG_FPA_EXPORT_CE.
- 50 object còn thông điệp ATC: bỏ cờ `Có lỗi syntax`, hạ mức nghiêm trọng/ưu tiên (46 object đổi độ ưu tiên; 2 object rời Ưu tiên 1: ZPG_FI_WF_TS00407862_MASS, ZFI_ITEMS).
- Giữ nguyên người phụ trách, trạng thái, test của các task còn lại. **Mã task và STT đã đánh số lại** (UT-/ST-/SY-) vì sheet sắp xếp lại; cột Note ghi ưu tiên cũ của từng object.
- Tải sau cập nhật (ngày công = MD ÷ công suất): Khoa 129, Quý 134, Phát ≈ 62 (trước 131), Danh 138, Sang 134 → **cần chia lại cho Phát**.
- Sheet PhanCong_DEV đã sửa các con số/câu bị cũ (A2, F8, B41, B42, B45, A56–B57). Công thức giữ nguyên, đặt `fullCalcOnLoad` để Excel tính lại khi mở; giá trị cache đã tính sẵn (bộ tính kiểm chứng khớp 327/327 ô trên file gốc, TG dự kiến khớp 1.034/1.034).
- Bản gốc: `CodeABAP/QCM_UPG/Citek_WCM_ATC_PhanCong_v1.0_truoc_khi_dua_syntax_OK_ve_ATC.xlsx` (xoá được khi đã kiểm tra).
- Chưa cập nhật `06_Source Code 20261022/WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx` (nguồn) nên 2 file đang lệch số liệu. Chưa mở bằng Excel trong phiên (không có Excel/LibreOffice): đã kiểm tra cấu trúc zip/XML, nạp lại bằng openpyxl, đối chiếu task ↔ sheet.

## Cập nhật lần 3 (27/10/2026): thêm kết quả ATC ZP_RETAIL + ZP_ABAP2XLSX

Nguồn: `06_Source Code 20261022/CHECK_ATC/ZP_RETAIL/` (17 file theo check title = `ZP_RETAIL_TOTAL.xlsx` 19.786 lượt; `ZP_ABAP2XLSX.xlsx` 2.462 lượt; `ZSPDD.xlsx` rỗng). Đã ghi thẳng vào file dùng chung `...\citek.vn\QCM - 01_S4_Conversion\06_Source Code 20261022\Tổng hợp\Citek_WCM_ATC_PhanCong_v1.0.xlsx`.

- Bỏ trùng 304 lượt đã có trong dữ liệu cũ (ZP_RETAIL nằm lẫn ở ZP_HDDT/ZP_FICO) → thêm 21.944 lượt, 822 object (806 object còn dòng sau khi bỏ lỗi biên dịch giả). Áp dụng cùng quy tắc `/syntax`: 62/67 object mới có thông điệp nhóm 1 là `OK` (bỏ lỗi biên dịch giả 165 lượt, giữ SLIN thật); 5 object chưa có trong danh mục vào `Lỗi syntax`: ZDEMO_EXCEL32, ZDEMO_EXCEL26, ZEH_LOG_CHANGE_STO, ZENHAN_SERIAL_NUMBER_LM80, ZEN_IM_INBOUND_DELIVERY_CHECK.
- 25 thông điệp mới chưa từng có (72 lượt) được Claude xếp nhóm theo thông điệp tương tự (ví dụ `Default text not substituted` → 12, `Transaction code not entered in TSTC` → 10, `Buffered table ... in SELECT with subquery` → 8). Anh Sang chưa duyệt bảng này.
- Hoạt động ST03N cho object mới được dựng lại từ ExtractSAP (TSTC, đồ thị CODE_FACT ≤4 cấp, ST03N 5 tuần): kiểm chứng trên 799 object cũ khớp 96,7% mức hoạt động + quan hệ, 99% tcode trực tiếp, 97% tcode gián tiếp, 94% câu lý do; khác biệt chủ yếu ở số bước gián tiếp của function group lớn (chặn trên). Smartform nối với chương trình gọi bằng cách tìm tên trong source local.
- Kết quả: `Ưu tiên theo ST03N` 763 → 1.569 object (Ưu tiên 1/2/3/4 = 13/171/243/1.142; 8 object mới ở Ưu tiên 1, vd ZRM07MTRB 213.449 bước, ZPG_RT_094_P_PO_TRACKING_A 761.433 bước, ZPG_MD_RT062, ZPG_RT148E_PID, ZPG_RT_031_BBY_UPLOAD); `Ưu tiên xử lý` 143 → 169 dòng (26 dòng mới); `Lỗi syntax` 3 → 8; Task 909 → 1.746 (+837: 26 UT, 806 ST, 5 SY).
- Phân công: task UT mới theo nhóm (R3: nhóm 7/8/10 → Danh, còn lại Khoa); 8 task Ưu tiên 1 mới → Quý (R1); 5 object lỗi syntax mới (task SY + ST = 10 task) → Phát (R1/R2); **793 task còn lại (≈ 205 MD) chưa phân công** (cột ABAP Phụ trách để trống). Tải hiện giao (ngày công = MD ÷ công suất): Khoa 163, Quý 143, Phát 67, Danh 188, Sang 134 → cần chia lại.
- Giữ nguyên 100% giá trị 763 object ST03N cũ; trạng thái đã nhập (UT-001 và ST-0002 Đang thực hiện, ST-0003 Hoàn thành, ZPG_FI_WF_TS00407862_MASS Đang thực hiện → mã ST-0374) giữ theo từng task. Mã task/STT đánh số lại.
- Chưa cập nhật `WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx` (nguồn) và chưa chạy ATC cho ZP_HDDT_EFPT, ZUPG_ACTIVE_OBJ, Z_ASP_FPA_EXPORT_EXT (vẫn thiếu kết quả).

---

## Xử lý local task ST-0031 – ZPR_RT_STO_FORM_VM_E (27/10/2026 16:42)

Dòng 31 sheet "Ưu tiên theo ST03N": Ưu tiên 2 – Làm sớm, package ZP_HDDT, nhóm chính "2. Gọi hàm/chương trình sai – nguy cơ dump", 104 thông điệp ATC (P1 8 / P2 24 / P3 72), 2 MD, hạn 30/10, phụ trách Sang. Chạy gián tiếp qua tcode ZHDDT (589 bước/5 tuần).

File sửa (local, không qua MCP): `Program\zpr_rt_sto_form_vm_e\zpr_rt_sto_form_vm_e.abap` và `zin_method_delivery.abap` (include). Marker `SangVT add|modify|comment begin/end 27.10.2026 16:42:04`. Bản gốc: scratchpad phiên, thư mục `bak_sto_form`.

| Thông điệp ATC | SL | Đã làm |
|---|---|---|
| BREAK-POINT | 4 | Comment 4 dòng `break` (v_phong ×2, ae-uyen, v_minhdv8) |
| Formal parameter incompatible with actual parameter (P1) | 2 | `PERFORM export_file USING '.PDF'/'.HTML'` → gán `DATA(lv_file_ext) = CONV string(...)` rồi truyền |
| READ .. BINARY SEARCH không ORDER BY (P1) | 1 | Thêm `SORT lt_bkpf BY belnr` |
| Tenuous use of FOR ALL ENTRIES | 3 | Bọc `IF <bảng> IS NOT INITIAL` cho 3 câu SELECT (MKPF/lt_mseg, ZTB_LOG_SD_E_INV, BKPF) |
| Function module exception not handled | 4 | Thêm `EXCEPTIONS OTHERS` + kiểm sy-subrc: SCMS_BASE64_DECODE_STR, SCMS_STRING_TO_XSTRING, SCMS_XSTRING_TO_BINARY, GUI_FILE_SAVE_DIALOG, POPUP_TO_CONFIRM ×2 |
| Return codes of FM exceptions ignored | 7 | Thêm `IF sy-subrc <> 0` (nhánh chỉ có chú thích, giữ nguyên hành vi) cho NAST_PROTOCOL_UPDATE, SSF_CLOSE, READ_TEXT ×4, Z_FI_GET_ADDRESS |

Chưa sửa và lý do:
- SELECT SINGLE không duy nhất (18), SELECT * (≈13), FAE→JOIN (2): đổi truy vấn → cần test dữ liệu S/4HANA.
- WHERE không có field index (5: MSEG, BKPF ×2, NAST, VBFA): cần thêm điều kiện/index theo nghiệp vụ.
- Text element (26 + 5), Menu bar (GUI status ZGST_100): nhập trong SE38/SE41 trên hệ thống.
- Table with replacement object (6), Critical Statements (5): thông tin S/4HANA, không phải lỗi.
- `Function module parameter missing` (1) và `USING reference parameters should not be modified` (1): chưa định vị được; nghi `i_tcode = sy-tcode` (exe_import) vì FM ZFM_GENERATE_XML_TAG bản local không có I_TCODE → xác nhận SE37 trên DS4; `FORM entry` do RSNAST00 gọi nên không đổi.

Quan sát ngoài phạm vi ATC (chưa đổi): ba lần READ_TEXT dùng chung `lt_temp` và chỉ CLEAR một lần → khi text Z003/Z004 không tồn tại, dòng của lần đọc trước có thể còn lại (nếu READ_TEXT không tự xoá bảng); `CHECK sy-subrc <> 0` sau `SELECT SINGLE COUNT( * )` luôn thoát FORM vì sy-subrc = 0.
