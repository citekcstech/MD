# QCM_UPG – ZPG_MM_STORE_TRANSFER: lỗi "Kết quả sai trên HANA – SELECT không ORDER BY nhưng dùng thứ tự kết quả"

Ngày kiểm tra: 04.11.2026
Source: `CodeABAP/QCM_UPG/06_Source Code 20261022/Program/zpg_mm_store_transfer/` (main + `_top` + `_f01` + `_f02`, f02 toàn bộ là comment)
Nguồn ATC: `CHECK_ATC/ZP_RETAIL/SELECT OPEN CURSOR WITHOUT ORDER BY.xlsx` (check "Search problematic statements for result of SELECT/OPEN CURSOR without ORDER BY")

> File export ATC chỉ ghi "... line ..." (không có số dòng) nên vị trí dưới đây suy ra từ đối chiếu source, không phải số dòng do ATC báo.

## 1. ATC báo 3 message cho chương trình này

| # | Priority | Message | Vị trí trong source |
|---|----------|---------|---------------------|
| 1 | **1** | `READ .. BINARY SEARCH for result of statement at ... line ...` | **`f01` dòng 520–522** (nguồn data: SELECT dòng 389–398) — xác định chắc |
| 2 | 3 | `Empty SELECT/ENDSELECT at ... line ...` | `f01` dòng 620–628 (SELECT … UP TO 1 ROWS … ENDSELECT với thân rỗng) — xác định chắc |
| 3 | 3 | `SELECT ... for (former) pool table ... without ORDER BY found` | Chưa xác định chắc; nhiều khả năng là cùng SELECT T007V ở dòng 620–628 (cần mở kết quả ATC trong SAP xem dòng, và kiểm tra T007V có từng là pool table không) |

## 2. Lỗi chính (Priority 1) – `gt_t157e_vi` được READ BINARY SEARCH nhưng không bao giờ được SORT

- `FORM get_add_data` (f01 dòng 388–398): `SELECT bwart grund grtxt FROM t157e INTO TABLE gt_t157e_vi FOR ALL ENTRIES IN gt_gr WHERE spras = 'VI' ...` → **không ORDER BY**.
- `FORM edit_alv_data` khối SORT (f01 dòng 429–437) có sort: `gt_gr, gt_mara, gt_t157e, gt_uprice, gt_curr, gt_knvi, gt_mlan` → **thiếu `gt_t157e_vi`** (dòng 433 chỉ sort `gt_t157e`).
- f01 dòng 520–522: `READ TABLE gt_t157e_vi INTO ls_t157e WITH KEY bwart = ... grund = ... BINARY SEARCH.`

Hậu quả: DB cũ trả theo thứ tự khoá chính nên BINARY SEARCH vô tình đúng; HANA không đảm bảo thứ tự → BINARY SEARCH có thể không tìm thấy dòng dù có trong bảng → cột "Reason for different" (`I002`) bị trống khi fallback sang tiếng Việt.

Cách sửa gợi ý (chưa áp dụng): thêm `SORT gt_t157e_vi BY bwart grund.` ngay sau dòng `SORT gt_t157e BY bwart grund.` (f01 dòng 433). Không dùng `ORDER BY` trong SELECT vì có `FOR ALL ENTRIES` (chỉ cho phép `ORDER BY PRIMARY KEY`, và SELECT đang chọn một phần cột).

## 3. Các chỗ đã kiểm tra và KHÔNG bị lỗi (có SORT trước READ BINARY SEARCH / DELETE ADJACENT)

| Bảng nội bộ | SELECT | SORT | READ BINARY SEARCH |
|-------------|--------|------|--------------------|
| gt_po_t | 142–165 | 173 (trước DELETE ADJACENT 174) | – |
| gt_issue | 178–184 | 185 | 198, 645 |
| gt_rece | 188–194 | 195 | 200, 653 |
| gt_gr | 236–263 | 283, 429 | 287 |
| gt_mara | 343–349 | 432 | 462 |
| gt_t157e | 377–386 | 433 | 513 |
| gt_uprice | 331–340 | 434 | 567 |
| gt_curr | 322–328 | 435 | 575 |
| gt_knvi | 355–363 | 436 | 587 |
| gt_mlan | 367–374 | 437 | 590 |
| gt_kunnr | – (APPEND trong LOOP) | 352 (trước DELETE ADJACENT 353) | – |

## 4. Priority 3 – SELECT … UP TO 1 ROWS … ENDSELECT rỗng (f01 dòng 620–628)

```abap
SELECT kbetr FROM t007v UP TO 1 ROWS INTO lw_kbetr
  WHERE aland = 'VN' AND mwskz = ls_alv-mwsk1 AND kschl = 'MWAS'.
ENDSELECT.
```

- Không ORDER BY: nếu có nhiều dòng thoả điều kiện thì HANA trả dòng nào cũng được → thuế suất có thể sai.
- Nằm trong `LOOP AT gt_po` → SELECT trong LOOP (performance).
- Hướng sửa: kiểm tra khoá T007V; nếu điều kiện đã xác định duy nhất 1 dòng → `SELECT SINGLE`; nếu không → bổ sung điều kiện (hoặc ORDER BY trường quyết định, VD ngày hiệu lực) rồi `UP TO 1 ROWS`. Tốt hơn: đọc T007V 1 lần ngoài LOOP vào bảng nội bộ rồi READ TABLE.

## 5. Rủi ro cùng bản chất nhưng ATC KHÔNG báo – nên xử lý kèm

`gt_gr` (SELECT từ MSEG, f01 dòng 236–263) không ORDER BY, rồi chỉ `SORT gt_gr BY matnr ebeln ebelp` (dòng 283, 429; không STABLE, không khoá phụ). Trong `LOOP AT gt_gr ... WHERE matnr/ebeln/ebelp` (f01 dòng 477–551) kết quả phụ thuộc thứ tự các dòng cùng khoá:

- dòng 480–485: `budat_mkpf` (PGR date) lấy theo dòng 101 **đầu tiên**.
- dòng 498–505: `meins` bị ghi đè → lấy dòng **cuối**.
- dòng 529: `i001` (Remark) → dòng **cuối** (kể cả rỗng).
- dòng 532–536: `budat` (PGI date) → dòng 351/641/301 **cuối**.

Trên HANA thứ tự các dòng cùng khoá này không cố định giữa các lần chạy → các cột trên có thể khác nhau. Gợi ý: SELECT thêm `mjahr` và SORT theo `matnr ebeln ebelp budat_mkpf mjahr mblnr zeile` (thứ tự cụ thể cần user/nghiệp vụ chốt: lấy ngày đầu hay cuối).

## 6. Trạng thái

- **04.11.2026 14:15** – đã sửa FILE LOCAL (mục 2): `f01` dòng 434–437 thêm `SORT gt_t157e_vi BY bwart grund.` bọc marker `"SangVT add begin/end 04.11.2026 14:15:53` (comment dùng ASCII vì abaplint `7bit_ascii`). Sau khi thêm 4 dòng, READ BINARY SEARCH `gt_t157e_vi` nằm ở dòng 524–526.
- Chưa sửa mục 4 (T007V) và mục 5 (thứ tự dòng của gt_gr / MSEG) – cần user chốt hướng.
- Chưa đẩy lên SAP, chưa chạy SyntaxCheck (không có server MCP dự án QCM_UPG).

---

# Phần 2 – ZPG_RT_CLOSE_PO_STO (cùng check ATC "SELECT/OPEN CURSOR without ORDER BY")

Ngày kiểm tra/sửa: 04.11.2026
Source: `CodeABAP/QCM_UPG/06_Source Code 20261022/Program/zpg_rt_close_po_sto/zpg_rt_close_po_sto.abap` (+ `zin_rt_close_pobtop`, `zin_rt_close_poblay`)

## 1. ATC báo 4 message (file `SELECT OPEN CURSOR WITHOUT ORDER BY.xlsx`, ZP_RETAIL)

| # | Priority | Message | Vị trí (số dòng TRƯỚC khi sửa) |
|---|----------|---------|-------------------------------|
| 1–3 | **1** (x3) | `LOOP AT itab. ON CHANGE OF ... ENDON. for result of statement at ... line ...` | `LOOP AT bopo INTO ab. ... ON CHANGE OF ab-ebeln` dòng 547–572. 3 message = 3 SELECT đổ vào `lt_sto` rồi `APPEND ab TO bopo`: dòng 327–344, 454–470, 513–529 |
| 4 | 3 | `SELECT ... for (former) cluster table ... without ORDER BY found` | SELECT `cdpos` JOIN `cdhdr` dòng 364–378 (CDPOS từng là cluster table) |

## 2. Nguyên nhân message 1–3

`ON CHANGE OF ab-ebeln` chỉ đúng khi bảng đã gom theo `ebeln`. `bopo` = kết quả FM `WPOCS_SELECT_POS` + các dòng nối thêm từ 3 SELECT (FAE, không ORDER BY) → trên HANA thứ tự không đảm bảo → cùng 1 PO có thể bị tạo nhiều header trong `changing_header` (APPEND abhead mỗi lần đổi ebeln).

## 3. Đã sửa file local (04.11.2026 14:27:19, marker `"SangVT ...`)

- Dòng 553–556: thêm `SORT bopo STABLE BY ebeln ebelp.` ngay trước `LOOP AT bopo INTO ab.` (STABLE giữ thứ tự cũ cho các dòng trùng khoá). Hệ quả: `changing_items` giờ theo thứ tự ebeln/ebelp.
- Dòng 378–384: SELECT `cdpos`/`cdhdr` thêm `ORDER BY a~tabkey, b~udate DESCENDING, b~utime DESCENDING` (khớp SORT ở dòng ~388 đã có); câu `AND b~udate >= @lv_date.` cũ comment lại (marker `comment begin/end`), viết lại không có dấu chấm + ORDER BY (marker `add begin/end`). Code SORT cũ giữ nguyên.

## 4. Đã kiểm tra, KHÔNG sửa

- FORM `log` dòng 671–672 `LOOP AT p_messages ... ON CHANGE OF p_messages-ebeln`: đã `SORT p_messages BY ebeln ebelp etenr msgty` ở dòng 669 → đúng.
- `lt_ekpochk` (SORT dòng 236 trước BINARY SEARCH 240), `lt_tmpc` (SORT 253 trước BINARY SEARCH 557 – cùng điều kiện `s_betyp`/`int`), `lt_podel` (SORT + DELETE ADJACENT 381–386) → đều đã sort.

## 5. Chưa làm / lưu ý

- Chưa chạy SyntaxCheck (QCM_UPG không có server MCP) và chưa đẩy lên SAP → cần syntax check khi upload (đặc biệt câu SELECT có ORDER BY + JOIN).
- Tie-break của SORT dòng 388 (cùng tabkey/udate/utime nhưng khác value_new) vẫn không xác định nếu 2 thay đổi cùng giây – hiếm; có thể bổ sung `a~changenr` nếu cần chặt.

---

# Phần 3 – ZPR_RT_STO_FORM_VM_E: nhóm "2. Gọi hàm/chương trình/đối tượng sai hoặc không tồn tại – nguy cơ dump"

Ngày kiểm tra: 04.11.2026 – ĐÃ SỬA FILE LOCAL cả 3 điểm lúc 14:43:37 (xem mục 5; số dòng ở mục 1–2 là TRƯỚC khi sửa)
Source: `CodeABAP/QCM_UPG/06_Source Code 20261022/Program/zpr_rt_sto_form_vm_e/` (main `zpr_rt_sto_form_vm_e.abap` + `zin_method_delivery.abap` + `zin_rt_sto_form_vm_e_top.abap`)
Nguồn ATC: `CHECK_ATC/ZP_HDDT.xlsx` (khớp 100% với danh sách user dán ngày 04.11.2026). Export ATC không có số dòng → vị trí suy ra bằng cách đối chiếu chữ ký hàm.

## 1. Message thuộc nhóm 2 của chương trình này (theo sheet "Ưu tiên xử lý" của WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx)

| Priority | Message SLIN | Số lần | Vị trí suy ra |
|----------|--------------|--------|----------------|
| 1 | Formal parameter incompatible with actual parameter | 2 | (a) main:384–391 `iv_bupla = p_belnr`; (b) main:354–362 `t_item = gt_item` |
| 2 | Function module parameter missing | 1 | zin_method_delivery:384–390 `i_tcode = sy-tcode` |

(Các message khác của chương trình – exception not handled x4, return codes ignored x7, SELECT*, text element... – thuộc nhóm khác.)

## 2. Chi tiết từng điểm

**(a) P1 – `Z_FI_GET_ADDRESS`, main dòng 384–391 (FORM `f_get_header_info`)**
- `iv_bupla = p_belnr`: IV_BUPLA là `BUPLA` (CHAR4, VALUE), `p_belnr` là `TYPE vbrk-vbeln` (CHAR10) → sai kiểu/độ dài → dump `CALL_FUNCTION_CONFLICT_LENG`/`_TYPE` nếu chạy.
- FORM này hiện KHÔNG được gọi (dòng 350 `"PERFORM f_get_header_info CHANGING .` đã comment) → lỗi tiềm ẩn, SLIN vẫn bắt.
- Chương trình anh em ZPR_RT_B2B_VAT_FORM_VM_E (main:384) truyền `iv_bupla = lv_bupla` (biến BUPLA đọc từ VBRK) và không bị báo lỗi này.
- Hướng sửa: truyền biến đúng kiểu BUPLA – `p_bupla` (selection parameter `LIKE vbrk-bupla`) hoặc biến BUPLA đọc từ chứng từ; cần user chốt nguồn đúng.

**(b) P1 – `ZFM_RT_READ_BILL_DETAIL_HDDT`, main dòng 354–362 (FORM `f_process_data`, ĐANG chạy: gọi từ dòng 196 và 1087)**
- FM: `T_ITEM TYPE ZTT_VAT_ITEMS`. Chương trình: `gt_item TYPE ztt_dlv_items` (top:65). B2B_VAT dùng `ztt_vat_items` và không bị báo.
- gs_item trong chương trình đọc các field `note`, `vrkme`... mà FM không điền (FM điền itemno, posnr, matnr, fkimg, kzwi2, waers, mwskz, ztaxamt, zfinal... theo `zst_vat_items`) → hai structure khác nhau. ĐÃ XÁC NHẬN bằng DDIC local (`dictionary/zst_dlv_items.html` vs `zst_vat_items.html`): ZST_DLV_ITEMS = 23 field giống hệt ZST_VAT_ITEMS + field thứ 24 `NOTE` (CHAR200) → lỗi thật.
- Hướng sửa an toàn: khai báo `lt_item TYPE ztt_vat_items` trong FORM, truyền `t_item = lt_item`, sau đó `gt_item = CORRESPONDING #( lt_item )` (giữ nguyên `gt_item` vì còn dùng cho smartform `it_deta` ở dòng 255/281 và LOOP trong zin_method_delivery). Không nên đổi kiểu `gt_item` toàn chương trình.
- `gt_item` còn được APPEND ở main:2251 (`APPEND gs_item TO gt_item`) và FREE ở 989 → nếu `lt_item` rỗng sau khi FM chạy thì `CORRESPONDING #( )` làm gt_item rỗng (đúng hành vi FM cũ: FM đọc lại từ VBRP theo VBELN).

**(c) P2 – `ZFM_GENERATE_XML_TAG`, zin_method_delivery dòng 384–390 (FORM `exe_import`)**
- Call truyền `i_tcode = sy-tcode` nhưng FM chỉ có `I_XMLTAG`, `I_SERIALNO` (IMPORTING) và `C_XML_TAG` (CHANGING) – cả 2 bản export local (`Function_group/zfm_generate_xml_tag/...` và `saplzfg_einvoice_tag/lzfg_einvoice_tagu03.abap`) đều không có I_TCODE → dump `CALL_FUNCTION_PARM_UNKNOWN`.
- 2 call còn lại (dòng 127 và 1210) đã comment `*  i_tcode = sy-tcode` → dev trước cũng đã gặp.
- FORM `exe_import` hiện không được PERFORM ở đâu (chỉ có định nghĩa) → lỗi tiềm ẩn.
- Hướng sửa: comment dòng `i_tcode = sy-tcode` (marker `"SangVT comment begin/end`), giống 2 call kia. FM không dùng tcode nên không đổi kết quả.

## 3. Đã kiểm tra, KHÔNG có vấn đề

- Mọi `PERFORM` truyền vào FORM có tham số khai kiểu: check_puslished_invoice (gty_vbrk, char1), zcus_print_transf_slip (mblnr, mjahr), encode_envoice/built_customer_code (string, zst_dlv_head), export_file (string), built_data_inv/update_hdr_inf/modify_view/call_mb03 (gty_vmcfa) → kiểu khớp.
- `ZFM_RT_GET_LOGO_VC` (i_werks WERKS_D, e_logo RSTXT-TDNAME), `Z_FI_GET_ADDRESS` tại main:1964 và 2145 (iv_bukrs/iv_kunnr, ev_name TYPE C generic, ev_address CHAR200, ev_vat STCEG – biến khai báo đúng kiểu), READ_TEXT x4, POPUP_TO_INFORM/CONFIRM, LVC_FIELDCATALOG_MERGE, SCMS_*, GUI_FILE_SAVE_DIALOG, GUI_DOWNLOAD, SSF_* → đủ tham số bắt buộc, kiểu khớp.
- `CALL FUNCTION lf_fm_name` (smartform, tên động) – SLIN không kiểm được; cần đối chiếu thủ công tham số với smartform đang dùng nếu muốn chắc.

## 4. Lưu ý

- ATC user dán vẫn còn "exception not handled x4" và "return codes ignored x7" dù file local đã có marker `SangVT ... 27.10.2026 16:42:04` xử lý các call này → có thể ATC chạy trước khi đẩy bản sửa lên hệ thống (hoặc bản sửa chưa upload).
- Chưa chạy SyntaxCheck (QCM_UPG không có server MCP) và chưa đẩy lên SAP.

## 5. Đã sửa file local (04.11.2026 14:43:37, marker `"SangVT ...`)

| Điểm | File | Sửa (số dòng SAU khi sửa) |
|------|------|---------------------------|
| (c) P2 | `zin_method_delivery.abap` dòng 386–389 | comment `i_tcode = sy-tcode` (marker comment) |
| (a) P1 | `zpr_rt_sto_form_vm_e.abap` dòng 399–405 (FORM `f_get_header_info`) | comment `iv_bupla = p_belnr`, thêm `iv_bupla = p_bupla` (selection param `LIKE vbrk-bupla`, CHAR4) |
| (b) P1 | `zpr_rt_sto_form_vm_e.abap` dòng 345–378 (FORM `f_process_data`) | thêm `DATA lt_item TYPE ztt_vat_items`; truyền `t_item = lt_item` (comment dòng cũ `t_item = gt_item`); sau CALL thêm `gt_item = CORRESPONDING #( lt_item ).` |

Lưu ý khi test:
- (a) FORM `f_get_header_info` và (c) FORM `exe_import` hiện không được PERFORM → không đổi hành vi; `p_bupla` là giả định của Claude (user chưa xác nhận nguồn BUPLA đúng nếu sau này bật lại FORM).
- (b) đường đang chạy (`processing` dòng ~196, `preview_inv` dòng ~1087 trước khi sửa): `gt_item` được thay bằng kết quả FM (như hành vi cũ, FM vốn ghi đè cả bảng); `NOTE` để trống vì FM không điền. Cần test in/preview hóa đơn STO sau khi đẩy lên DEV.
- Cảnh báo `7bit_ascii` của IDE ở file này do chuỗi/comment tiếng Việt có sẵn (kể cả dòng đợt 27.10), không phải do đợt sửa này; phần mới viết toàn ASCII.

---

# Phần 4 – ZPR_RT_STO_FORM_VM_E: so sánh và merge với bản hệ thống

Ngày: 04.11.2026
So sánh: file local `zpr_rt_sto_form_vm_e.abap` (2425 dòng, đã có các sửa SangVT) với bản hệ thống user cung cấp `zpr_rt_sto_form_vm_e copy.abap` (2281 dòng; trùng khớp 100% với đoạn user dán 1581 dòng đầu, chỉ khác BOM) bằng `diff --strip-trailing-cr -b`.

## Kết quả

| # | Khác biệt | Nguồn | Xử lý |
|---|-----------|-------|-------|
| 1 | Marker 2 dòng `break` đã comment: `*  break v_phong.` (check_adjust_inv) và `*    break ae-uyen.` (khu vực dòng ~1960): hệ thống `"LongND comment begin/end 29.10.2026 13:45:00`, local `"SangVT comment begin/end 27.10.2026 16:42:04` | cùng một thay đổi, khác tên marker | ĐÃ MERGE: đổi 2 chỗ trong local sang marker LongND của hệ thống (bản hệ thống đã có, tránh khai trùng tác giả) |
| 2 | Toàn bộ sửa SangVT 27.10.2026 16:42:04 (IF sy-subrc sau FM, guard FOR ALL ENTRIES rỗng, SORT lt_bkpf BY belnr, POPUP_TO_CONFIRM EXCEPTIONS OTHERS) | chỉ có ở local | Giữ nguyên – hệ thống CHƯA có |
| 3 | Toàn bộ sửa SangVT 04.11.2026 14:43:37 (3 điểm nhóm "gọi hàm sai": f_process_data/lt_item, iv_bupla, – và `i_tcode` ở include) | chỉ có ở local | Giữ nguyên – hệ thống CHƯA có |
| 4 | Khối comment cuối file (GUI Texts / Text elements / Selection texts / Messages, ~50 dòng) | chỉ có ở local – do công cụ export thêm, không phải code | Giữ nguyên |

Ngoài 4 nhóm trên, KHÔNG còn khác biệt nào ở file main (sau merge, các dòng LongND trùng 100% hệ thống; dòng khác với hệ thống chỉ là các sửa SangVT có chủ ý).

## Ý nghĩa

- Hệ thống = local trừ các sửa của SangVT → upload file main local lên DEV sẽ không ghi đè thay đổi nào khác của LongND trong file main (LongND chỉ comment 2 dòng break).
- Include `zin_method_delivery.abap` (còn 2 dòng break comment ở dòng 84, 1384 với marker SangVT) và 2 include TOP CHƯA so sánh – cần bản hệ thống tương ứng. ATC báo BREAK-POINT x4 cho chương trình = 2 ở main + 2 ở include → nhiều khả năng LongND cũng comment 2 dòng ở include đó.
- File `zpr_rt_sto_form_vm_e copy.abap` là file tạm để so sánh, đang nằm trong thư mục program → nên xóa/chuyển ra ngoài sau khi xong (không để lẫn khi export/grep).

---

# Phần 5 – ZPG_IF_SEND_FRE (package ZP_RETAIL, gửi dữ liệu sang F&R): check ATC

Ngày kiểm tra: 04.11.2026 – CHƯA SỬA (chờ user chọn phạm vi)
Source: `CodeABAP/QCM_UPG/06_Source Code 20261022/Program/zpg_if_send_fre/` (main `zpg_if_send_fre.abap` + `zin_if_send_fre_top.abap` + `zin_if_send_fre_f01.abap`); proxy ở `Class/zifco_si_sapecc_to_fre_*`.
Nguồn ATC: danh sách user dán ngày 04.11.2026 (không có số dòng → vị trí suy ra từ source).

| Priority | Message | SL | Vị trí / nguyên nhân | Độ chắc |
|----------|---------|----|----------------------|---------|
| 1 | DELETE ADJACENT DUPLICATES for result of SELECT without ORDER BY (= nhóm "3. Kết quả sai trên HANA") | 1 | f01 `send_ass_article`: SELECT dòng 261–276 (không ORDER BY) → `DELETE ADJACENT DUPLICATES ... COMPARING asort artnr datab datbi lifnr eantp` dòng 278 → mới `SORT gt_asst_art BY asort` dòng 280 (SORT đặt SAU và chỉ theo asort). Trên HANA thứ tự dòng không cố định → dòng trùng không liền kề → còn trùng, gửi trùng sang F&R | Cao |
| 1 | Exception is not handled and is not declared in the RAISING clause | 6 | `CREATE OBJECT lo_service_if.` ở 6 FORM: f01 dòng 98, 185, 282, 482, 641, 882. Constructor lớp proxy `ZIFCO_SI_SAPECC_TO_FRE_*` có `RAISING CX_AI_SYSTEM_FAULT` (đã xác nhận ở 5 file Class/*.abap dòng 20–24) nhưng không có TRY/CATCH → lỗi kết nối proxy = dump `CX_SY_NO_HANDLER` | Cao |
| 2 | Exception of category CX_STATIC_CHECK not handled | 7 | Không chốt được vị trí. 7 = số lệnh gọi method proxy trong TRY (f01 dòng 121, 208, 309, 337, 514, 660, 934) nhưng chúng ĐÃ có `CATCH cx_ai_system_fault` (catch rỗng); nhiều khả năng cùng nguyên nhân CX_AI_SYSTEM_FAULT của 6 CREATE OBJECT + 1 chỗ khác → chạy lại ATC sau khi sửa dòng trên | Thấp |
| 2 | Function module exception not handled | 1 | f01 dòng 725 `CALL FUNCTION 'VRM_SET_VALUES'` không có EXCEPTIONS (ứng viên duy nhất: các FM còn lại BAPI_TRANSACTION_COMMIT, CONVERSION_EXIT_ALPHA_INPUT, GET_WEEK_INFO_BASED_ON_DATE không có exception; ADD_TIME_TO_DATE, DATE_GET_WEEK, ROUND đã có) | Trung bình–cao |
| 2 | Buffered table ... in a JOIN | 6 | Có 8 SELECT dạng JOIN (f01 dòng 78, 165, 261, 421, 450, 595, 623, 839); không biết bảng nào buffered (không có DDIC WRSZ/WLK1/WRS1... local) → chỉ mang tính tham khảo, trên HANA không gây sai; khuyến nghị bỏ qua | – |
| 3 | Text element missing in a character string | 9 | 7 literal trong main `zpg_if_send_fre.abap` dòng 21–25, 27–28 ('Send Assortment-Site', 'Send Assortment-Article', 'Send Repleinishment', 'Send Forecast', 'Send Corrected Sale', 'Display ZWRSZ', 'Maintain ZWRSZ') + 2 message f01 dòng 692, 694 ('Gửi dữ liệu thành công', 'Không có dữ liệu'). Cần thêm text symbol (cú pháp `'text'(004)`) và khai trong text pool trên SAP | Cao |
| 3 | Table with replacement object changed | 1 | Không xác định bảng nào từ source (cần xem chi tiết message trong ATC) | – |

## Hướng sửa đề xuất (chưa áp dụng)

1. DELETE ADJACENT (P1): thêm `SORT gt_asst_art BY asort artnr datab datbi lifnr eantp.` ngay trước dòng 278 (hoặc `SELECT DISTINCT` – 6 trường select = 6 trường COMPARING). Giữ nguyên `SORT ... BY asort` ở dòng 280.
2. CREATE OBJECT x6 (P1): bọc `TRY. CREATE OBJECT lo_service_if. CATCH cx_ai_system_fault INTO DATA(lx_ai). MESSAGE lx_ai->get_text( ) TYPE 'S' DISPLAY LIKE 'E'. RETURN. ENDTRY.` – đổi hành vi: lỗi kết nối proxy sẽ báo message thay vì dump.
3. VRM_SET_VALUES (P2): thêm `EXCEPTIONS id_illegal_name = 1 OTHERS = 2.` + `IF sy-subrc <> 0.` (comment, giống pattern đợt sửa 27.10 ở ZPR_RT_STO_FORM_VM_E).
4. 7 CATCH cx_ai_system_fault rỗng: đang nuốt lỗi gửi → `lw_status` không set và cuối cùng hiện "Không có dữ liệu" (sai ngữ cảnh). Nếu sửa cần quyết định cách báo lỗi (message mỗi lần hay gom cuối) – cần user chốt.
5. Text element x9 (P3): thêm `(nnn)` + text pool – cần đẩy text pool lên SAP, ưu tiên thấp.

## Phần 5 – Cập nhật: ĐÃ SỬA FILE LOCAL (04.11.2026 14:58:27, marker `"SangVT ...`)

File sửa: `Program/zpg_if_send_fre/zin_if_send_fre_f01.abap` (chưa đẩy SAP, chưa SyntaxCheck – QCM_UPG không có server MCP).

| Mục | Sửa |
|-----|-----|
| P1 DELETE ADJACENT (`send_ass_article`) | thêm `SORT gt_asst_art BY asort artnr datab datbi lifnr eantp.` ngay trước `DELETE ADJACENT DUPLICATES` (dòng ~278) |
| P1 CREATE OBJECT x6 (`send_ass_site`, `send_ass_site_virtual`, `send_ass_article`, `send_repleinishment`, `send_forecast`, `send_correctedsale`) | bọc `TRY. CREATE OBJECT lo_service_if. CATCH cx_ai_system_fault INTO DATA(lx_ai). MESSAGE lx_ai->get_text( ) TYPE 'S' DISPLAY LIKE 'E'. RETURN. ENDTRY.` – giữ nguyên dòng `CREATE OBJECT` gốc, chỉ thêm TRY/CATCH quanh nó. Hành vi mới: lỗi tạo proxy báo message rồi thoát FORM, thay vì dump |
| P2 VRM_SET_VALUES (`build_art_type_list`, dòng ~725) | comment dòng `values = list.` cũ, viết lại thêm `EXCEPTIONS id_illegal_name = 1 OTHERS = 2.` + `IF sy-subrc <> 0 AND sy-msgid IS NOT INITIAL. MESSAGE ID sy-msgid ... DISPLAY LIKE 'E'. ENDIF.` |

Chưa sửa (cần user quyết định): (4) 7 `CATCH cx_ai_system_fault` rỗng đang nuốt lỗi gửi; (5) 9 text element thiếu (cần text pool trên SAP); buffered table in JOIN x6 (khuyến nghị bỏ qua); CX_STATIC_CHECK x7 và "Table with replacement object" x1 (không xác định được vị trí từ source – chạy lại ATC sau khi upload bản sửa).

Kiểm tra sau sửa: TRY/ENDTRY cân bằng (13/13 = 7 cũ + 6 mới); phần mới viết toàn ASCII; cảnh báo `7bit_ascii`/`line_break_style`/`whitespace_end` của IDE là lỗi có sẵn của file (comment tiếng Việt, CRLF).

---

# Phần 6 – ZPG_CON_CONTRACT_SEND_EMAIL (package ZP_RETAIL, gửi e-mail khi đổi condition contract)

Ngày: 04.11.2026 15:09:45 – ĐÃ SỬA FILE LOCAL (chưa SyntaxCheck – QCM_UPG không có server MCP; chưa đẩy SAP)
Source: `Program/zpg_con_contract_send_email/zpg_con_contract_send_email.abap` (1 file, 256 dòng, trước khi sửa). Nguồn ATC: danh sách user dán 04.11.2026 (không có số dòng).

| Priority | Message | SL | Vị trí (số dòng TRƯỚC khi sửa) | Xử lý |
|----------|---------|----|-------------------------------|-------|
| 1 | DELETE ADJACENT DUPLICATES for result of SELECT without ORDER BY | 1 | dòng 197 `DELETE ADJACENT DUPLICATES FROM lt_wcocoh COMPARING ch_name` – `lt_wcocoh` copy từ `gt_wcocoh` (SELECT * FROM wcocoh, không ORDER BY) và chưa sort theo `ch_name` | thêm `SORT lt_wcocoh BY ch_name.` trước DELETE |
| 2 | CONCATENATE in LOOP for result of SELECT without ORDER BY | 2 | dòng 199 (nối `ch_name` theo `lt_wcocoh`) và dòng 214 (nối `usnam` theo `gt_con_ctr_user`) – thứ tự tên trong nội dung e-mail phụ thuộc thứ tự SELECT | dòng 199: SORT ở trên; dòng 214: thêm ORDER BY PRIMARY KEY vào SELECT `ztb_con_ctr_user` |
| 3 | WRITE in LOOP for result of SELECT without ORDER BY | 2 | dòng 175 (`WRITE <lf_wcocoh>-num` theo `gt_wcocoh`) và dòng 181 (`WRITE usnam` theo `gt_con_ctr_user`) | thêm `ORDER BY PRIMARY KEY` vào 2 SELECT (`wcocoh`, `ztb_con_ctr_user`) |
| 2 | Analysis of WHERE: Table ...: No WHERE condition | 1 | dòng 86–87 `SELECT * FROM ztb_con_ctr_user` – bảng cấu hình người nhận mail (khóa MANDT+USNAM), cố ý đọc cả bảng | KHÔNG sửa – chấp nhận (bảng danh sách nhỏ, theo client) |
| 3 | Text element missing in a character string | 6 | 6 literal: dòng 172 'Condition Contract(s) sent for Approval:', 178 'Receiver(s):', 195 'Users: ', 202 'đã sửa các condition contracts dưới:<BR>', 212 '<BR>Đề nghị anh chị: Tên User ', 217 'release giúp các condition trên.' | CHƯA sửa – cần text pool trên SAP, ưu tiên thấp |

## Đã sửa (marker `"SangVT ... 04.11.2026 15:09:45`, comment ASCII)

- `select_data`: SELECT `wcocoh` – comment dòng `AND deact = 'X'.` cũ, viết lại `AND deact = 'X' ORDER BY PRIMARY KEY.`
- `select_data`: SELECT `ztb_con_ctr_user` – comment dòng `FROM ztb_con_ctr_user.` cũ, viết lại `FROM ztb_con_ctr_user ORDER BY PRIMARY KEY.`
- `built_content_email`: thêm `SORT lt_wcocoh BY ch_name.` ngay trước `DELETE ADJACENT DUPLICATES`.

Ghi chú:
- Dùng `ORDER BY PRIMARY KEY` vì khóa `WCOCOH` không có trong thư mục dictionary local (chỉ có `ZTB_CON_CTR_USER`); thứ tự nội dung e-mail/WRITE giờ theo khóa, ổn định giữa các lần chạy.
- Tên user trong e-mail: `lt_wcocoh` sắp theo `ch_name` (A→Z), người nhận (`usnam`) theo khóa.
- Chưa sửa tie-break: nếu cùng `ch_name` thì chỉ giữ dòng đầu (chỉ dùng `ch_name` nên không ảnh hưởng).
- Lưu ý không thuộc ATC (chưa sửa): `lw_uzeit = sy-uzeit - p_second` + range BT có thể rỗng khi cửa sổ thời gian qua nửa đêm (low > high).

---

# Phần 7 – ZPG_MS_GR_DROPSHIP (package ZMS, GR cho dropship PO TTMS/P&L)

Ngày: 04.11.2026 15:21:37 – ĐÃ SỬA FILE LOCAL (chưa SyntaxCheck – QCM_UPG không có server MCP; chưa đẩy SAP)
Source: `Program/zpg_ms_gr_dropship/` (`zpg_ms_gr_dropship.abap` + `zin_ms_gr_dropship_top.abap` + `zin_ms_gr_dropship_f01.abap` 1102 dòng trước khi sửa; `screens/screen_0100.txt`; `zfm_send_dropship/`). Nguồn ATC: danh sách user dán 04.11.2026 + `CHECK_ATC/ZMS.xlsx` (bản 22.10: 83 message; bản mới thêm 5 "Primary key is ignored").

| Priority | Message | SL | Vị trí (số dòng TRƯỚC khi sửa) | Xử lý |
|----------|---------|----|-------------------------------|-------|
| 1 | Literal incompatible with formal parameter | 2 | f01 dòng 527 (`goods_receipt_ttms`) và 659 (`goods_receipt_pl`): `BAPI_GOODSMVT_CREATE ... goodsmvt_code = '01'` – tham số `GOODSMVT_CODE` kiểu structure `BAPI2017_GM_CODE`, đang truyền literal | ĐÃ SỬA: khai `ls_gm_code TYPE bapi2017_gm_code`, `ls_gm_code-gm_code = '01'`, truyền `goodsmvt_code = ls_gm_code` (dòng literal cũ comment lại) |
| 2 | Exception handling for CX_.. is empty | 1 | f01 dòng 189 `CATCH cx_root.` rỗng trong vòng LOOP lt_eket (tính open quantity) | ĐÃ SỬA: `CATCH cx_root INTO DATA(lx_root).` + `<lfs_po>-stt = 'E'` + `<lfs_po>-msg = lx_root->get_text( )` – dòng bị lỗi tính số lượng giờ hiện status E + message thay vì im lặng |
| 1 | GUI Usability: "Cancel" function text is missing | 1 | GUI status – `STT100` (popup screen 0100: CONTINUE/CANCEL; `MODULE set_status` dòng 741 `SET PF-STATUS 'STT100'`). Status không có trong source local | KHÔNG sửa được từ file local → làm trong SE41 |
| 1 | GUI Usability: Standard function assigned to the wrong function key | 1 | cùng nhóm GUI status (`STT100` là ứng viên chính; `LOCK`/`STANDARD` là status ALV dòng 421/430) | KHÔNG sửa được từ file local → SE41: CANCEL gán F12, BACK F3, EXIT Shift+F3; nhập function text "Cancel" cho CANCEL |
| 3 | Text element missing in a character string | 63 | = 21 lần gọi macro `add_field` (f01 dòng 255–383) × 3 chỗ dùng `&2` (seltext_l/m/s): các text 'Site', 'Article', 'new Article ', 'Description', 'Storage Location', 'Vendor', 'TTMS PO'... | CHƯA sửa – cần text pool trên SAP, ưu tiên thấp |
| 3 | Text element is missing in a string template | 3 | f01 dòng 638 `\|Items [{ ... }] article [{ ... }] not match with dropship PO.\|` (3 đoạn chữ) | CHƯA sửa (text pool) |
| 3 | Use of ROLLBACK WORK | 2 | f01 dòng 811, 1068: nhánh ELSE khi `MODIFY ztb_ms_dropship FROM TABLE` lỗi | Không sửa – dùng có chủ đích (hoàn tác khi ghi bảng lỗi) |
| 3 | Value does not match this type | 10 | không map được vị trí từ source | Không sửa |
| 3 | Primary key is ignored (generic or standard key) | 5 | không map chắc: các LOOP/READ trên bảng STANDARD với key mặc định (vd LOOP lt_eket WHERE ebeln/ebelp dòng 184; READ lt_tmp WITH KEY ttms pnl bukrs ebeln_pl ebelp_pl dòng 789, 1050; READ gt_po dòng 562, 697) | Không sửa – chỉ là gợi ý hiệu năng (khai bảng SORTED/HASHED có key) |

## Đã sửa (marker `"SangVT ... 04.11.2026 15:21:37`, comment ASCII)

- `goods_receipt_ttms` và `goods_receipt_pl`: 2 chỗ BAPI_GOODSMVT_CREATE (structure `ls_gm_code` thay cho literal '01').
- `get_data`: 1 chỗ CATCH cx_root rỗng.

## Cần user làm trên SAP (không có trong source local)

- SE41, chương trình `ZPG_MS_GR_DROPSHIP`, status `STT100`: CANCEL gán F12 (type "E" – exit command, vì `MODULE exit_fcode AT EXIT-COMMAND`), nhập function text "Cancel"; kiểm tra lại BACK/EXIT. Chạy lại GUI Usability check để xem status nào còn lỗi (STT100 hay LOCK/STANDARD).

## Phần 7 – Cập nhật: MERGE với bản hệ thống `zin_ms_gr_dropship_f01 copy.abap` (04.11.2026)

So sánh: local `zin_ms_gr_dropship_f01.abap` (1127 dòng, có 3 sửa SangVT 04.11 15:21:37) với bản hệ thống user cung cấp (1178 dòng, có sửa của LongND 04.11.2026 09:29:31). 10 hunk khác biệt, KHÔNG chồng lấn nhau → merge sạch.

| Nhóm | Nội dung | Xử lý |
|------|----------|-------|
| Chỉ có ở hệ thống (LongND) | `get_data`: 2 SELECT `eket` (nhánh TTMS + P&L) từ `FOR ALL ENTRIES` → `SELECT DISTINCT ... INNER JOIN @gt_po`; `update_dropship` và `update_dropship_canceled`: `SELECT * ... FOR ALL ENTRIES` → `SELECT DISTINCT d~* ... INNER JOIN @lt_tmp`; `cancel_goods_receipt_pl`: SELECT `ekbe` (lt_mmdoc) → `SELECT DISTINCT ... INNER JOIN @lt_tmp ... ORDER BY` và comment `SORT lt_mmdoc`; macro `add_field`: viết hoa keyword (CLEAR, IS NOT, TO) | ĐÃ LẤY từ hệ thống (giữ nguyên marker LongND, 22 dòng khớp hệ thống) |
| Chỉ có ở local (SangVT 04.11 15:21:37) | `CATCH cx_root INTO DATA(lx_root)` (get_data) + 2 chỗ `goodsmvt_code = ls_gm_code` (goods_receipt_ttms/_pl) | GIỮ NGUYÊN (14 dòng marker, nguyên vẹn) |
| Chỉ có ở local (export) | khối `*` / `* ` 2 dòng cuối file (công cụ export thêm) | GIỮ NGUYÊN |

Kiểm tra sau merge: merged vs hệ thống chỉ khác đúng 3 chỗ SangVT + khối cuối file; merged vs local-trước-merge chỉ khác các hunk hệ thống, không đụng dòng SangVT nào; mã hóa giữ nguyên UTF-8 BOM + CRLF; TRY/ENDTRY 1/1. Bản local trước merge được sao lưu ở thư mục scratchpad (`f01_local_before_merge.abap`).

Lưu ý: file `zin_ms_gr_dropship_f01 copy.abap` là file tạm nằm trong thư mục program → nên xóa/chuyển ra ngoài. Include `zpg_ms_gr_dropship.abap` và `zin_ms_gr_dropship_top.abap` chưa được so sánh (chưa có bản hệ thống).

## Phần 7 – Cập nhật: GUI status STT100 (SE41) – 2 lỗi "Standard function assigned to the wrong function key"

Sau khi user sửa function text của CANCEL, ATC còn 2 message "wrong function key". Đọc ảnh SE41 status `STT100` (Interface ZPG_MS_GR_DROPSHIP):
- Reserved Function Keys: `F12` = CANCEL (đúng).
- Freely Assigned Function Keys: `F5` = CANCEL → gán thừa/sai phím (Cancel chuẩn chỉ ở F12).
- Recommended Function Key Settings: ô `Enter` TRỐNG, `F2` = CONTINUE → sai phím (F2 là phím chuẩn "Choose"; "Continue" chuẩn là Enter).

Cách sửa (SE41, user làm trên SAP): xóa CANCEL khỏi F5; xóa CONTINUE khỏi F2 và gán CONTINUE vào Enter; kiểm function CANCEL có kiểu `E` (Exit command, vì `MODULE exit_fcode AT EXIT-COMMAND`); kích hoạt lại rồi chạy lại ATC. Code ABAP không đổi (`user_command_screen` vẫn xử lý `CONTINUE`, `exit_fcode` xử lý `CANCEL`). Nếu `STT100` được copy sang ZPG_TTMS_CONVERT_DRAFT_PR / ZPG_TTMS_ZMS006B / ZPG_TTMS_ZMS011A thì sửa/copy tương tự.
