# BDP_PCE – Tổng hợp xử lý Long Text (Text Object / Text ID / Program / Tcode)

- **Phạm vi:** toàn bộ folder `CodeABAP/BDP_PCE` (đọc local, không dùng MCP, không đọc `Backup/`, `DRAFT/`).
- **Cách rà:** tìm mọi chỗ gọi `READ_TEXT`, `READ_TEXT_TABLE`, `SAVE_TEXT`, `ZCORE_FM_GET_LONG_TEXT[_MULTI]`, `ZCORE_FM_SAVE_LONG_TEXT`, `ZCL_BASE_ABAP=>GET_LONG_TEXT_MULTI`, `SELECT … STXH`, rồi đọc từng chỗ gọi để lấy Text Object / Text ID / TDNAME / đích gán.
- **Cột Trạng thái:** `Active` = đang chạy; `Comment` = đã bị comment trong code (không còn chạy, ghi lại để tham khảo).
- **Ý nghĩa Text ID** lấy từ comment + tên biến đích trong code (không đọc được bảng `TTXID/TTXIT` trên hệ thống). Dòng nào là suy luận có ghi rõ.
- **Tcode** không nằm trong code local (nằm ở bảng `TSTC`). Chỉ ghi được Tcode khi code/comment/FS có nhắc; còn lại ghi "Chưa xác định".

---

## 1. Hàm/cơ chế dùng chung

| Hàm / cơ chế | Chức năng | Tham số chính | Định nghĩa tại |
|---|---|---|---|
| `ZCORE_FM_GET_LONG_TEXT` | Đọc 1 text (`READ_TEXT`), nối các dòng bằng dấu cách → `E_LONG_TEXT`; trả thêm dòng 1-3 và `ET_TLINE`; thay `<(>`/`<)>` khi có ký tự `&` | `I_TDOBJECT`, `I_TDNAME`, `I_TDID`, `I_TDSPRAS` (mặc định `'E'`) | `zfi_pg_ar_zar03/zcore_fm_get_long_text/zcore_fm_get_long_text.abap` |
| `ZCORE_FM_GET_LONG_TEXT_MULTI` | Đọc nhiều text một lần (`READ_TEXT_TABLE`) → kết quả ở `T_LTEXT-LTEXT1` (structure `ZST_LTEXT`: TDOBJECT/TDNAME/TDID/TDSPRAS/LTEXT1); `TDSPRAS` trống → `SY-LANGU` | `T_LTEXT` | `zco_pg_pc_bcgttt_a/zcore_fm_get_long_text_multi/zcore_fm_get_long_text_multi.abap` |
| `ZCL_BASE_ABAP=>GET_LONG_TEXT_MULTI` | Bản class của hàm MULTI (dùng trong `zco_pg_pc_bcgttt`) | `T_LTEXT` (key TDOBJECT TDNAME TDID TDSPRAS, field `LTEXT`) | Class `ZCL_BASE_ABAP` (không nằm trong folder) |
| `ZCORE_FM_SAVE_LONG_TEXT` | Ghi text: tách chuỗi theo `I_LENGTH_SPLIT` (mặc định 132) → `SAVE_TEXT` → `COMMIT_TEXT` → `COMMIT WORK AND WAIT`. Riêng `TDOBJECT = 'ZAP12'` dùng `RKD_WORD_WRAP` (ngắt theo `, `) | `I_TDOBJECT`, `I_TDNAME`, `I_TDID`, `I_TDSPRAS` (mặc định `'E'`), `I_LONGTEXT`, `I_LENGTH_SPLIT` | `zfi_pg_upload_r_fidoc/zcore_fm_save_long_text/zcore_fm_save_long_text.abap` |
| `ZCORE_FM_GET_DOC_DES` / `_DES_N` / `_DES_CORRES` | Wrapper lấy diễn giải dòng chứng từ FI (`DOC_ITEM`/`0001`); ưu tiên 1 long text item → 2 item text (`SGTXT`) → 3 header text (`BKTXT`) | – | `zfi_pg_ap_bbdccn_phaitra/zcore_fm_get_doc_des/…`, `zfi_pg_cm_sqt/zcore_fm_get_doc_des_n/…`, `zfi_pg_cm_sqt/zcore_fm_get_doc_des_corres/…` |
| `READ_TEXT` trực tiếp | Một số chỗ gọi thẳng | – | xem từng program bên dưới |
| `SELECT … STXH` (kiểm tra text có tồn tại trước khi `READ_TEXT`) | Giảm số lần gọi FM | – | `zfi_pg_ap_zap03` (f02:312-318), `zmm_pg_thncvt` (f01:266-271) |

**Quy ước TDNAME hay gặp**

| Text Object | TDNAME |
|---|---|
| `BELEG` (extra text header chứng từ FI) | `BUKRS` + `BELNR` + `GJAHR` |
| `DOC_ITEM` (text dòng chứng từ FI) | `BUKRS` + `BELNR` + `GJAHR` + `BUZEI` |
| `MATERIAL` | `MATNR` |
| `EKKO` / `EKPO` | `EBELN` / `EBELN` + `EBELP` |
| `EBANH` / `EBAN` | `BANFN` / `BANFN` + `BNFPO` |
| `VBBK` (header SO / delivery) | `VBELN` (số SO hoặc số delivery `LE_VBELN`) |
| `ANLA` | `BUKRS` + `ANLN1` + `ANLN2` |
| `LFA1` | `LIFNR` |

---

## 2. Chi tiết theo Program

Đường dẫn file tính từ `CodeABAP/BDP_PCE/`. `R` = đọc, `W` = ghi.

### 2.1 FI – Kế toán tổng hợp / thuế / quỹ

| Program | Tcode | Text Object | Text ID | Ý nghĩa Text ID (theo code) | TDNAME | R/W | Vị trí | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| `ZFI_PG_AP_ZAP03` (Bảng kê HĐ, chứng từ hàng hóa dịch vụ mua vào) | **ZAP03** (hằng `GC_TCODE`) | `BELEG` | `0001` | Tên người bán – phần 1 → `T1` | BUKRS+BELNR+GJAHR | R | `zfi_pg_ap_zap03/zfi_in_ap_zap03_f02.abap:312-361, 377` (SQL `STXH` + `READ_TEXT`) | Active |
| | | `BELEG` | `0002` | Tên người bán – phần 2 → `T2` | như trên | R | như trên | Active |
| | | `BELEG` | `0003` | Tên người bán – phần 3 → `T3` | như trên | R | như trên | Active |
| | | `BELEG` | `0004` | Tên người bán – phần 4 → `T4` | như trên | R | như trên | Active |
| | | `BELEG` | `0005` | MST người bán → `TAXNO` | như trên | R | như trên | Active |
| | | `BELEG` | `0011` | Ký hiệu mẫu hóa đơn → `KHMHD` | như trên | R | như trên | Active |
| | | `BELEG` | `0001-0005`, `0011` | (bản cũ gọi `ZCORE_FM_GET_LONG_TEXT` từng dòng) | như trên | R | `zfi_pg_ap_zap03/zfi_in_ap_zap03_f01.abap:469-710` | Comment |
| `ZFI_PG_AR_ZAR03` (Bảng kê HĐ, chứng từ hàng hóa dịch vụ bán ra) | **ZAR03** (suy từ tên program) | `BELEG` | `0005` | MST khách hàng → `KUNNR_LIFNR_STCEG` (trống thì lấy `ZCORE_FM_GET_PROFILE`/`KNA1-STCEG`) | BUKRS+BELNR+`P_GJAHR` | R | `zfi_pg_ar_zar03/zfi_in_ar_zar03_f01.abap:414-450` | Active |
| | | `BELEG` | `0011` | Ký hiệu mẫu hóa đơn → `ZKHMHD` | như trên | R | `…zar03_f01.abap:465-473` | Active |
| `ZFI_PG_CM_PHIEUTHU` (Phiếu thu) | Chưa xác định | `DOC_ITEM` | `0001` | Diễn giải/lý do thu của dòng chứng từ → `LW_ITEM_TEXT`, `GW_LYDO` | BUKRS+BELNR+GJAHR+BUZEI | R | `zfi_pg_cm_phieuthu/zfi_in_cm_phieuthu_f01.abap:149, 307` | Active |
| | | `BELEG` | `0007` | Tên người nộp tiền → `GW_HOTEN`/`ZZPAYPER` (comment code: "ten nguoi nop tien") | BUKRS+BELNR+GJAHR | R | `…phieuthu_f01.abap:781` | Active |
| | | `BELEG` | `0009` | Địa chỉ đối tượng nhận tiền → `GW_DIACHI` | như trên | R | `…phieuthu_f01.abap:798` | Active |
| | | `BELEG` | `0001` | Tên đơn vị nhận tiền → `GW_TEN_DONVI`/`ZZDONVI` | như trên | R | `…phieuthu_f01.abap:820` | Active |
| `ZFI_PG_CM_PHIEUCHI` (Phiếu chi) | Chưa xác định | `DOC_ITEM` | `0001` | Diễn giải dòng chứng từ → `LW_ITEM_TEXT` | BUKRS+BELNR+GJAHR+BUZEI | R | `zfi_pg_cm_phieuchi/zfi_in_cm_phieuchi_f01.abap:234` | Active |
| | | `BELEG` | `0007` | Tên đối tượng (comment code: "ten nguoi nop tien") | BUKRS+BELNR+GJAHR | R | `…phieuchi_f01.abap:851` | Active |
| | | `BELEG` | `0009` | Địa chỉ đối tượng nhận tiền | như trên | R | `…phieuchi_f01.abap:869` | Active |
| | | `BELEG` | `0001` | Tên đơn vị nhận tiền | như trên | R | `…phieuchi_f01.abap:891` | Active |
| `ZFI_PG_CM_UYNHIEMCHI` (Ủy nhiệm chi) | Chưa xác định | `DOC_ITEM` | `0001` | Nội dung/diễn giải dòng → `LW_ITEM_TEXT`, `NOIDU` | BUKRS+BELNR+GJAHR+BUZEI | R | `zfi_pg_cm_uynhiemchi/zfi_in_cm_uynhiemchi_f01.abap:333, 728` (dòng 106 Comment) | Active |
| | | `BELEG` | `0008` | Tài khoản bên nhận → `CDACC` | BUKRS+BELNR+GJAHR | R | `…uynhiemchi_f01.abap:470` | Active |
| | | `BELEG` | `0007` | Tên đối tượng nhận tiền → `CDNAM` (comment code) | như trên | R | `…uynhiemchi_f01.abap:619` | Active |
| | | `BELEG` | `0009` | Địa chỉ bên nhận → `CDADD` | như trên | R | `…uynhiemchi_f01.abap:644` | Active |
| | | `BELEG` | `0010` | Ngân hàng bên nhận ("Tai NH") → `CDBAK` | như trên | R | `…uynhiemchi_f01.abap:660` | Active |
| `ZFI_PG_CM_SQT` (Sổ quỹ tiền mặt / sổ ngân hàng) | Chưa xác định | `DOC_ITEM` | `0001` | Diễn giải dòng → `ZCHITIEU14` (trống thì lấy `SGTXT`) | BUKRS+BELNR+GJAHR+BUZEI | R | `zfi_pg_cm_sqt/zfi_in_cm_sqt_f01.abap:315`; MULTI trong `zcore_fm_get_doc_des_n.abap:37`, `zcore_fm_get_doc_des_corres.abap:44` (TDNAME dùng `BUZEI_CORRES` khi `I_INCLUDE_CORRES`) | Active |
| `ZFI_PG_AP_BBDCCN_PHAITRA` (BB đối chiếu công nợ phải trả) | Chưa xác định | `DOC_ITEM` | `0001` | Diễn giải dòng → `E_DESCRIPTION` (trống → `SGTXT`/`BKTXT`) | BUKRS+BELNR+GJAHR+BUZEI (hoặc `BUZEI_CORRES`) | R | `zfi_pg_ap_bbdccn_phaitra/zcore_fm_get_doc_des/zcore_fm_get_doc_des.abap:27` | Active |
| `ZPG_FI_ZGL07` | **ZGL07** (suy từ tên program) | `DOC_ITEM` | `0001` | Diễn giải dòng chứng từ → `LW_LONGTEXT` | BUKRS+BELNR+GJAHR+BUZEI | R | `zpg_fi_zgl07/zin_fi_zgl07_f01.abap:391` | Active |
| `ZFI_PG_GL_SCTTK` (Sổ tổng hợp tài khoản) | Chưa xác định (code có nhắc `ZGL10` nhưng không rõ là Tcode của chính program) | `DOC_ITEM` | `0001` | Diễn giải dòng chứng từ → `LW_LONGTEXT` | như trên | R | `zfi_pg_gl_scttk/zfi_in_gl_scttk_f01.abap:485` | Active |
| `ZFI_PG_GL_CHUNGTUGHISO` (Chứng từ ghi sổ) | Chưa xác định | `DOC_ITEM` | `0001` | Diễn giải dòng chứng từ (comment code "nha cung cap") → `LW_ITEM_TEXT`/`LW_LONG_TEXT` | như trên | R | `zfi_pg_gl_chungtughiso/zfi_in_gl_chungtughiso_f01.abap:171, 564, 1168` | Active |
| `ZFI_PG_AA_BCTGTSCD` (BC tình hình tăng giảm TSCĐ) | Chưa xác định | `ANLA` | `XLTX` | Long text mô tả tài sản (comment code: "GET LONG TEXT FOR DESCRIBLE ABOUT ASSET") → `GT_TSCD-INFOR` | BUKRS+ANLN1+ANLN2 | R (`READ_TEXT` trực tiếp) | `zfi_pg_aa_bctgtscd/zfi_in_aa_bctgtscd_f01.abap:531` | Active |

### 2.2 FI – Đề nghị thanh toán (ZAP12) và upload chứng từ

| Program | Tcode | Text Object | Text ID | Ý nghĩa Text ID (theo code) | TDNAME | R/W | Vị trí | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| `ZFI_PG_PYMT_REQ` (Payment request) | **ZAP12** (code kiểm `SY-TCODE = 'ZAP12'`) | `BELEG` | `0007` | Họ tên người nhận tiền → `GS_DATA-HTNN` (ưu tiên 2 sau field màn hình tham số) | BUKRS+BELNR+GJAHR | R (qua `EXTRA_TEXT` → `READ_TEXT` → `ZCORE_FM_GET_LONG_TEXT`) | `zfi_pg_pymt_req/zfi_in_pymt_req_f01.abap:3174` (form `EXTRA_TEXT` 2111-2123, `READ_TEXT` 5067-5082) | Active |
| | | `BELEG` | `0037` | Hóa đơn giảm (comment code: "H.Đơn giảm (ZAP12)") → `ZHD_DCG` / `/SAPF15/BEWIRTSCHAFTER` | như trên | R | `…pymt_req_f01.abap:4666, 10798` | Active |
| | | `DOC_ITEM` | `0001` | Nội dung dòng chứng từ → `LS_SF-NOIDUNG` (trống → `SGTXT`) | BUKRS+BELNR+GJAHR+BUZEI | R (`READ_TEXT` trực tiếp + MULTI) | `…pymt_req_f01.abap:3614` (READ_TEXT), `6077-6088` (MULTI, "get long text item") | Active |
| | | `LFA1` | `Z001` | Tên hàng hóa kinh doanh của NCC → `GS_HD_TB-HANGHOAKD` (comment code: "Tên hàng hóa KD") | `LIFNR` | R | `…pymt_req_f01.abap:9845` | Active |
| | | `ZAP12` (text object tự tạo) | `Z001` | Nội dung đề nghị (ghi, ngắt dòng 74 ký tự) | Số đề nghị (`LPW_ID`) | W | `…pymt_req_f01.abap:7821-7827` | Comment |
| `ZFI_PG_PYMT_REQ_P` (Post ủy nhiệm chi / phiếu) | **ZAP12P** (code kiểm `TCODE NE 'ZAP12P'`) | `BELEG` | `0007` | Họ tên người nhận tiền ← `LS_HEAD-HTNN` | doc_cc+BELNR+GJAHR | W (`CALL_SAVE_TEXT` → `ZCORE_FM_SAVE_LONG_TEXT`) | `zfi_pg_pymt_req_p/zfi_in_pymt_req_p_f01.abap:989` | Active |
| | | `BELEG` | `0008` | Số tài khoản ← `LS_HEAD-SOTAIKHOAN` | như trên | W | `…pymt_req_p_f01.abap:997` | Active |
| | | `BELEG` | `0010` | Tài khoản ngân hàng ← `LS_HEAD-TAIKHOAN_NH` | như trên | W | `…pymt_req_p_f01.abap:1005` | Active |
| | | `BELEG` | `0016` | Lý do chi ← `LS_HEAD-LYDOCHI`; hoặc Nội dung ← `LS_HEAD-NOIDUNG` | như trên | W | `…pymt_req_p_f01.abap:1014, 1023` | Active |
| | | `DOC_ITEM` | `0001` | Nội dung từng dòng ← `<LF_ALV>-NOIDUNG` (ghi bằng `SAVE_TEXT` trực tiếp, `SAVEMODE_DIRECT = 'X'`) | doc_cc+BELNR+GJAHR+BUZEI | W | `…pymt_req_p_f01.abap:1099-1127` | Active |
| | | (tham số `LPW_OBJECT`/`LPW_ID`) | – | Form `READ_TEXT` gọi `ZCORE_FM_GET_LONG_TEXT` nhưng không thấy `PERFORM` nào trong program | – | R | `…pymt_req_p_f01.abap:635-648` | Có form, không có chỗ gọi |
| `ZFI_PG_PYMT_REQ_H` (In ủy nhiệm chi / phiếu chi) | **ZAP12H** (suy từ comment/message "bên ZAP12H") | `BELEG` | `0004` | Họ tên người nhận tiền (comment code) / Người nộp | BUKRS+BELNR+GJAHR | R | `zfi_pg_pymt_req_h/zfi_in_pymt_req_h_f01.abap:694, 2340` | Comment |
| | | `BELEG` | `0008` | Địa chỉ (`LW_DIACHI`) | như trên | R | `…pymt_req_h_f01.abap:2344` | Comment |
| | | `SKB1` | `0002` | Text của G/L account (chưa rõ nghĩa) → `LW_LTEXT` | `SAKNR`+… (theo code gốc) | R | `…pymt_req_h_f01.abap:2765-2771` | Comment |
| | | `LFA1` | `Z001` | Tên hàng hóa KD → `LPS_EXCEL-TENHANGHOAKD` | `LIFNR` | R | `…pymt_req_h_f01.abap:4335, 5047, 5122` | Comment |
| `ZFI_PG_UPLOAD_FIDOC` (Upload FI Document từ Excel) | Chưa xác định | `BELEG` | **Động** = `FIELDNAME+2(4)` của cột ALV dạng `ID0xxx` / `IDZxxx` (chỉ ghi nếu tồn tại trong `TTXID` của `BELEG`) | Mỗi cột Excel `IDnnnn` = Extra text ID `nnnn` của chứng từ | BUKRS+BELNR+GJAHR | W | `zfi_pg_upload_fidoc/zfi_in_upload_fidoc_f01.abap:2154-2173`; form `CALL_SAVE_TEXT` 2650-2670 | Active |
| | | `DOC_ITEM` | `0001` | Diễn giải dòng ← `LS_DETAIL-LTEXT` | BUKRS+BELNR+GJAHR+số thứ tự dòng | W | `…upload_fidoc_f01.abap:2193` | Active |
| `ZFI_PG_UPLOAD_R_FIDOC` (Hạch toán thu tiền hàng loạt) | Chưa xác định | `DOC_ITEM` | `0001` | Diễn giải dòng ← `LS_DETAIL-LTEXT` | như trên | W | `zfi_pg_upload_r_fidoc/zfi_in_upload_r_fidoc_f01.abap:1408`; form `CALL_SAVE_TEXT` 1862-1895 | Active |
| `ZFI_PG_UPLOAD_CTP` (Upload FI Document từ Excel – hoàn ứng/CTP) | Chưa xác định | `BELEG` | `0002` | Số tài khoản nhận tiền ← `L_STKNT` | BUKRS+BELNR+GJAHR | W | `zfi_pg_upload_ctp/zfi_in_upload_ctp_f01.abap:2900` | Active |
| | | `BELEG` | `0001` | Ngân hàng nhận tiền ← `L_NHNT` | như trên | W | `…upload_ctp_f01.abap:2906` | Active |
| | | `BELEG` | `0004` | Tên tài khoản hưởng thụ ← `L_HTNN` | như trên | W | `…upload_ctp_f01.abap:2912` | Active |
| | | `BELEG` | `0006` | Địa chỉ ngân hàng nhận tiền ← `L_DCNHNT` | như trên | W | `…upload_ctp_f01.abap:2918` | Active |
| | | `BELEG` | `0008` | Tên nhận tiền ← `L_NAME1` | như trên | W | `…upload_ctp_f01.abap:2924` | Active |
| | | `BELEG` | `0009` | Mã số thuế NCC ← `L_MSTNCC` | như trên | W | `…upload_ctp_f01.abap:2930` | Active |
| | | `BELEG` | `0028` | Ghi chú hoàn ứng ← `L_GCHU` | như trên | W | `…upload_ctp_f01.abap:2936` | Active |
| | | `DOC_ITEM` | `0001` | Diễn giải dòng ← `ZLONG_TEXT` / `LTEXT` | BUKRS+BELNR+GJAHR+BUZEI | W | `…upload_ctp_f01.abap:2962, 3091`; form `CALL_SAVE_TEXT` 3548-3568 | Active |
| | | `BELEG` | `0007` | (đọc MULTI, chưa rõ đích) | – | R | `…upload_ctp_f01.abap:4502-4506` | Comment |

### 2.3 SD – Bán hàng / Billing

| Program | Tcode | Text Object | Text ID | Ý nghĩa Text ID (theo code) | TDNAME | R/W | Vị trí | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| `ZSD_PG_APPROVE_SO_CKTM` (Approve SO theo user status) | Chưa xác định | `VBBK` | `Z001` | Ghi chú đơn hàng → `GCDH` (và `NOTE_KTDP`); ghi lại khi quyền sửa `GW_AUTH_EDIT = '02'` | `VBELN` (SO) | R (MULTI, f01:121-137, 501-508) + W (f01:2137) | `zsd_pg_approve_so_cktm/zsd_in_approve_so_f01.abap` | Active |
| | | `VBBK` | `Z002` | Ghi chú kế toán công nợ (KTCN) → `NOTE_KTCN`; ghi khi `BERSL_NEXT = 'REL2'` | `VBELN` | R (f01:493-499) + W (f01:2120) | như trên | Active |
| | | `VBBK` | `Z006` | Số hóa đơn (Invoice number) → `INV_NUM`; ghi khi `AUART` thuộc `LR_AUART` và `BERSL_NEXT = 'REL3'` | `VBELN` | R (f01:469-475) + W (f01:2091) | như trên | Active |
| | | `VBBK` | `Z007` | Lý do từ chối phê duyệt → `REJECT_REASON` | `VBELN` | R (f01:461-467) + W (f01:3062) | như trên | Active |
| | | `VBBK` | `Z012` | Ngày hóa đơn → `NGAY_HD`; ghi cùng Z006 | `VBELN` | R (f01:477-483) + W (f01:2104) | như trên | Active |
| | | `VBBP` | `0001` | Material Sales Text → `DTEXT01` | `VBELN`+`POSNR` | R | `…approve_so_f01.abap:2526` | Comment |
| | | `VBBP` | `0006` | Production Memo → `DTEXT02` | như trên | R | `…approve_so_f01.abap:2534` | Comment |
| | | `VBBP` | `Y101` | Chiếu xạ → `DTEXT03` | như trên | R | `…approve_so_f01.abap:2542` | Comment |
| | | `VBBP` | `X101` | Ghi chú Item → `DTEXT04` | như trên | R | `…approve_so_f01.abap:2550` | Comment |
| | | `VBBP` | `Y102` | Định mức bán hàng → `DTEXT05` | như trên | R | `…approve_so_f01.abap:2558` | Comment |
| | | `VBBP` | `Y103` | Item Basic Text → `DTEXT06` | như trên | R | `…approve_so_f01.abap:2566` | Comment |
| `ZSD_PG_HD_POST_BILL` (Tạo chứng từ GL thuế từ Billing bán hàng & trả hàng) | Chưa xác định | `VBBK` | `Z075` | Text đánh dấu trên billing; nếu **có nội dung** thì billing bị loại khỏi danh sách xử lý (**suy luận từ logic**, chưa có comment mô tả) | `VBELN` (billing) | R (MULTI) | `zsd_pg_hd_post_bill/zsd_in_hd_post_bill_f01.abap:723-745` | Active |
| | | `BELEG` | `0023` | Số hóa đơn gốc ("So HD Goc") ← `SO_HDG` | BUKRS+BELNR+GJAHR của chứng từ GL vừa tạo | W | `…hd_post_bill_f01.abap:1220` | Active |
| | | `BELEG` | `0024` | Ngày hóa đơn gốc ("Ngay HD Goc") ← `NGAY_HDG` | như trên | W | `…hd_post_bill_f01.abap:1229` | Active |
| | | `DOC_ITEM` | `0001` | Diễn giải dòng 001 và 002 ← `HDDC_DES` | BUKRS+BELNR+GJAHR+`001`/`002` | W | `…hd_post_bill_f01.abap:1238, 1246` | Active |

### 2.4 MM – Mua hàng

| Program | Tcode | Text Object | Text ID | Ý nghĩa Text ID (theo code) | TDNAME | R/W | Vị trí | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| `ZMM_PG_ZMM01` (Phiếu yêu cầu mua hàng) | **ZMM01** (suy từ Program ID/comment) | `EBAN` | `B01` | Bộ phận yêu cầu → `BOPHANYC` (comment: "LAY THONG TIN BO PHAN YEU CAU") | BANFN+BNFPO | R | `zmm_pg_zmm01/zin_mm_zmm01_f01.abap:689` | Active |
| | | `EBAN` | `B02` | Ghi chú item ("ITEM NOTE") → `GHICH` | như trên | R | `…zmm01_f01.abap:615` | Active |
| | | `EBAN` | `B03` | Nơi nhận → `KHONHAN` | như trên | R | `…zmm01_f01.abap:625` | Active |
| | | `EBAN` | `B04` | "Items text" → `SO_CODE` | như trên | R | `…zmm01_f01.abap:783` | Active |
| | | `EBAN` | `B08` | Ngày thỏa thuận → `D_THOATHUAN` | như trên | R | `…zmm01_f01.abap:903` | Active |
| | | `EBAN` | `B09` | Ý kiến của KH → `YK_KH` | như trên | R | `…zmm01_f01.abap:893` | Active |
| | | `EBAN` | `B10` | Yêu cầu chất lượng → `YC_CL` | như trên | R | `…zmm01_f01.abap:793, 883` | Active |
| | | `EBAN` | `B11` | Vai trò – Mục đích sử dụng → `VT_MDSD` | như trên | R | `…zmm01_f01.abap:803, 914` | Active |
| | | `EBAN` | `B12` | Số IO → `SO_IO`; và nhà sản xuất/nước SX → `NSXNS` (khi `P_FQC` và `NSXNS` trống) | như trên | R | `…zmm01_f01.abap:813, 602` | Active |
| | | `EBAN` | `B13` | Nhà sản xuất – nước sản xuất → `GW_NHASX` (comment: "LAY THONG TIN NHA SAN XUAT NUOC SAN XUAT") | như trên | R | `…zmm01_f01.abap:560` | Active |
| | | `EBANH` | `B01` | Diễn giải (comment: "LAY THONG TIN DIEN GIAI") → `HEADER13` | BANFN | R | `…zmm01_f01.abap:1332` | Active |
| | | `EBANH` | `B02` | Mã SPM → `MA_SPM` | BANFN | R | `…zmm01_f01.abap:846` | Active |
| | | `EBANH` | `B03` | Tên SP → `TEN_SP` | BANFN | R | `…zmm01_f01.abap:856` | Active |
| | | `EBANH` | `B04` | Ngày đề nghị hoàn thành → `D_HOANTHANH` | BANFN | R | `…zmm01_f01.abap:866` | Active |
| | | `EBANH` | `B05` | Bộ phận yêu cầu → `GW_BOPHANYC` (bản cũ dùng `EBAN`/`B01`) | BANFN | R | `…zmm01_f01.abap:664` | Active |
| | | `EBAN` | `B14` | (đã comment) | BANFN+BNFPO | R | `…zmm01_f01.abap:826` | Comment |
| `ZMM_PG_THNCVT` (BC tổng hợp nhu cầu mua vật tư PR→PO→GR) | **ZMM18** (header program) | `EBAN` | `B02` | "Item note chuẩn" → cột ALV `GHI_CHU` (mặc định trong `GT_TXTMAP`, `gc_id_note`) | BANFN+BNFPO | R (`STXH` → `READ_TEXT`) | `zmm_pg_thncvt/zmm_in_thncvt_f01.abap:261-271, 557-594`; hằng ở `zmm_in_thncvt_top.abap:18-20` | Active |
| | | `EBANH` (`gc_obj_head`) | cấu hình được theo bảng map | Text header PR – chỉ chạy nếu map khai báo (`ZTMM_RPT_PARAM` nhóm `PRTEXT` hiện đang tạm bỏ) | BANFN | R | `…thncvt_f01.abap:246-259` | Comment (đang tạm bỏ) |
| `ZMM_PG_DDH` (Đơn đặt hàng) | Chưa xác định (code có `PF-STATUS 'ZMM03_ALV'`, message class `ZMM03` → **suy đoán ZMM03**) | `EKPO` | `F01` | Tiêu chuẩn → `TIEUCHUAN` ("item text, then Classification") | EBELN+EBELP | R | `zmm_pg_ddh/zmm_in_ddh_f01.abap:402` | Active |
| | | `EKPO` | `F02` | Ghi chú dòng → `GHICHU` (comment: "LAY THONG TIN GHI CHU") | như trên | R | `…ddh_f01.abap:268` | Active |
| | | `EKPO` | `F03` | Ghi chú dòng (fallback của F02) → `GHICHU` | như trên | R | `…ddh_f01.abap:278` | Active |
| | | `EKPO` | `F04` | Nhà SX/nước SX → `NSXNS` (comment code: "LAY THONG TIN NONG DO HAM LUONG") | như trên | R | `…ddh_f01.abap:300` | Active |
| | | `MATERIAL` | `GRUN` | Basic data text (tên dài vật tư) → `LW_ARKTX` (chỉ plant `4000`, loại `MTART` ≠ Z51/Z62) | MATNR | R | `…ddh_f01.abap:499` | Active |
| | | `EKKO` | `F15` | Số hợp đồng → `HEADER12` (trống → `KONNR`) | EBELN | R | `…ddh_f01.abap:906` | Active |
| | | `EKKO` | `F01` | Diễn giải → `LW_DIENG` (comment: "LAY THONG TIN DIEN GIAI") | EBELN | R | `…ddh_f01.abap:970` | Active |
| | | `EKKO` | `F05` | Điều kiện giao hàng → `PARAMETER22` | EBELN | R | `…ddh_f01.abap:1026` | Active |
| | | `EKKO` | `F14` | Nơi giao hàng → `PARAMETER24` (PO trả hàng `RETPO='X'` lấy `HEADER14`) | EBELN | R | `…ddh_f01.abap:1038` | Active |
| | | `EKKO` | `F02` | Ghi chú → `PARAMETER27` | EBELN | R | `…ddh_f01.abap:1052` | Active |
| `ZMM_PG_DDHNK` (Đơn đặt hàng nhập khẩu / Mẫu in hợp đồng mua hàng) | **ZMM04** (FS ZMM04) | `EKKO` (header Contract) | `Z01` | (15) Nhóm hàng hóa → `T_GOODS_GRP` | EBELN | R (`READ_TEXT` trực tiếp) | `zmm_pg_ddhnk/zin_ddhnk_f02.abap:1470` (form `READ_TEXT` 1505-1540; hằng `gc_tdid_*` ở `zin_ddhnk_top.abap:188-196`) | Active |
| | | `EKKO` | `Z02` | (11) Giấy ủy quyền Bên Bán → `S_POA` | EBELN | R | `…ddhnk_f02.abap:1471` | Active |
| | | `EKKO` | `Z03` | (20) Số ngày xác nhận ĐĐH → `T_CONFIRM_DAYS` | EBELN | R | `…ddhnk_f02.abap:1473` | Active |
| | | `EKKO` | `Z04` | (18) Các quy định khác → `T_OTHER` | EBELN | R | `…ddhnk_f02.abap:1472` | Active |
| | | `EKKO` | `Z05` | (21) Chi phí giao hàng, bốc dỡ → `T_DELIV_COST` | EBELN | R | `…ddhnk_f02.abap:1474` | Active |
| | | `EKKO` | `Z06` | (33) Tiêu chuẩn chất lượng → `T_QUALITY` | EBELN | R | `…ddhnk_f02.abap:1476` | Active |
| | | `EKKO` | `Z07` | (23) Hồ sơ thanh toán → `T_PAY_DOCS` | EBELN | R | `…ddhnk_f02.abap:1475` | Active |
| | | `EKKO` | `Z08` | (34) Địa điểm giao hàng → `T_DELIV_PLACE` | EBELN | R | `…ddhnk_f02.abap:1477` | Active |
| | | `EKKO` | `Z09` | (35) Thời hạn giao hàng → `T_DELIV_TIME` | EBELN | R | `…ddhnk_f02.abap:1480` | Active |
| `ZMM_PG_BBG` (Bảng báo giá) | **ZMM02** (FS ZMM02) | `EKKO` | `A01` | Nhận xét (RFQ đầu tiên) → `NHANXET` | EBELN | R | `zmm_pg_bbg/zin_bbg_f01.abap:1648-1655` | Active |
| | | `EKKO` | `A02` | Đề nghị (RFQ đầu tiên) → `DENGHI` | EBELN | R | `…bbg_f01.abap:1656-1663` | Active |
| | | `EKKO` | `A05` | (17) Thời hạn thanh toán – header text "Terms of delivery" → `THANHTOAN` (trống → payment term) | EBELN | R | `…bbg_f01.abap:1722` | Active |
| | | `EKPO` | `A01` | (15) Tiêu chuẩn NSX – item text RFQ → `TIEUCHUAN_NSX` (trống → `MARA-ZEINR`) | EBELN+EBELP | R | `…bbg_f01.abap:1689` | Active |
| | | `EKPO` | `A4` | (16) Thời gian giao hàng – additional item text → `EINDT_S` (trống → `EKET-EINDT`) | EBELN+EBELP | R | `…bbg_f01.abap:1702` | Active |
| | | `EKPO` | `F04` | (22) Nhà sản xuất của PO liền kề – delivery text PO → `CT25` | `EBELN_PO`+`EBELP_PO` | R | `…bbg_f01.abap:1782` | Active |
| | | `EKKO`/`EKPO` | `A01`, `A02`, `A05`, `A4`, `F04` | Bản cũ (cùng nội dung) | – | R | `…bbg_f01.abap:302-583` | Comment |

### 2.5 CO / PP – Giá thành, sản xuất

| Program | Tcode | Text Object | Text ID | Ý nghĩa Text ID (theo code) | TDNAME | R/W | Vị trí | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| `ZCO_PG_PC_BCGTTT_A` (BC giá thành thực tế – CKM3) | Chưa xác định | `MATERIAL` | `GRUN` | Basic data text = "Tên dài của mã sản phẩm" → `BASIC_DATA_TEXT` | MATNR | R (MULTI) | `zco_pg_pc_bcgttt_a/zco_in_pc_bcgttt_a_f01.abap:203-216, 261-265` | Active |
| `ZCO_PG_PC_BCGTTT` (BC giá thành thực tế – CKM3, bản 2024) | Chưa xác định (code có `SY-TCODE = 'ZPA01'` ở f01:184 – chưa rõ có phải Tcode của program) | `MATERIAL` | `GRUN` | Basic data text → `BASIC_DATA_TEXT` | MATNR | R (`ZCL_BASE_ABAP=>GET_LONG_TEXT_MULTI`) | `zco_pg_pc_bcgttt/zco_in_pc_bcgttt_d01.abap:507-516, 591-594` | Active |
| `ZPP_PG_ZPI03` (BC danh sách Production version) | **ZPI03** (FS ZPI03) | `MATERIAL` | `GRUN` | Basic data text (mô tả dài mã vật tư) → `LONGTEXT` | MATNR | R | `zpp_pg_zpi03/zpp_in_zpi03_f01.abap:258` | Active |

### 2.6 WM – Kho

| Program | Tcode | Text Object | Text ID | Ý nghĩa Text ID (theo code) | TDNAME | R/W | Vị trí | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| `ZWM_PG_BBKNHH` (Biên bản kiểm nhận hàng hóa) | Chưa xác định | `VBBK` (header delivery) | `ZLF1` | Số hóa đơn → `GW_SOHD` | `LE_VBELN` | R | `zwm_pg_bbknhh/zwm_in_bbknhh_f01.abap:776` (comment: "LAY THONG TIN SO HOA DON") | Active |
| | | `VBBK` | `ZLF2` | Ngày hóa đơn → `GW_NGAYHD` | `LE_VBELN` | R | `…bbknhh_f01.abap:788` | Active |
| | | `VBBK` | `ZLF3` | Người kiểm nhận → `GW_NGKIEMNHAN` (gán `XBLNR`) | `LE_VBELN` | R | `…bbknhh_f01.abap:1174` | Active |
| | | `VBBK` | `ZLF4` | Người vận chuyển → `GW_NGVANCHUYEN` (gán `FRBNR`) | `LE_VBELN` | R | `…bbknhh_f01.abap:1188` | Active |
| | | `VBBK` | `ZLF5` | Người giao hàng → `GW_NGGIAOHANG` (gán `ABLAD`) | `LE_VBELN` | R | `…bbknhh_f01.abap:1202` | Active |
| | | `VBBK` | `ZLF6` | Số xe vận chuyển → `GW_SOXE` (gán `XABLN`) | `LE_VBELN` | R | `…bbknhh_f01.abap:1216` | Active |
| `ZWM_PG_HSPH` (Hồ sơ phân phối) | Chưa xác định | `VBBK` | `ZLF1` | Số hóa đơn → `SOHD` (chỉ khi `BWART = 641` và `SOHD` trống; còn lại lấy `BKTXT`) | `LE_VBELN` | R | `zwm_pg_hsph/zwm_in_hsph_f01.abap:556` | Active |
| `ZWM_PG_BCTK` (Báo cáo thẻ kho) | Chưa xác định | `VBBK` | `ZLF1` | Số hóa đơn → `SOHD` (khi `BWART = 641` và `BKTXT` trống) | `LE_VBELN` | R | `zwm_pg_bctk/zwm_in_bctk_f01.abap:427` | Active |

---

## 3. Tổng hợp rút gọn: Text Object + Text ID duy nhất

| Text Object | Text ID | Ý nghĩa (theo code) | Program dùng |
|---|---|---|---|
| `BELEG` | `0001` | Tên đơn vị nhận tiền (phiếu thu/chi) • Tên người bán – phần 1 (ZAP03) • Ngân hàng nhận tiền (upload CTP) | PHIEUTHU, PHIEUCHI, AP_ZAP03, UPLOAD_CTP |
| `BELEG` | `0002` | Tên người bán – phần 2 (ZAP03) • Số TK nhận tiền (upload CTP) | AP_ZAP03, UPLOAD_CTP |
| `BELEG` | `0003` | Tên người bán – phần 3 | AP_ZAP03 |
| `BELEG` | `0004` | Tên người bán – phần 4 (ZAP03) • Tên TK hưởng thụ (upload CTP) • Họ tên người nhận tiền (PYMT_REQ_H, comment) | AP_ZAP03, UPLOAD_CTP, PYMT_REQ_H |
| `BELEG` | `0005` | MST người bán / MST khách hàng | AP_ZAP03, AR_ZAR03 |
| `BELEG` | `0006` | Địa chỉ ngân hàng nhận tiền | UPLOAD_CTP |
| `BELEG` | `0007` | Họ tên / tên đối tượng nhận (nộp) tiền | PHIEUTHU, PHIEUCHI, UYNHIEMCHI, PYMT_REQ, PYMT_REQ_P |
| `BELEG` | `0008` | Số TK bên nhận (UNC, PYMT_REQ_P) • Tên nhận tiền (upload CTP) • Địa chỉ (PYMT_REQ_H, comment) | UYNHIEMCHI, PYMT_REQ_P, UPLOAD_CTP, PYMT_REQ_H |
| `BELEG` | `0009` | Địa chỉ đối tượng nhận tiền (phiếu thu/chi, UNC) • MST NCC (upload CTP) | PHIEUTHU, PHIEUCHI, UYNHIEMCHI, UPLOAD_CTP |
| `BELEG` | `0010` | Ngân hàng / tài khoản ngân hàng bên nhận | UYNHIEMCHI, PYMT_REQ_P |
| `BELEG` | `0011` | Ký hiệu mẫu hóa đơn | AP_ZAP03, AR_ZAR03 |
| `BELEG` | `0016` | Lý do chi / nội dung chi | PYMT_REQ_P |
| `BELEG` | `0023` | Số hóa đơn gốc | HD_POST_BILL |
| `BELEG` | `0024` | Ngày hóa đơn gốc | HD_POST_BILL |
| `BELEG` | `0028` | Ghi chú hoàn ứng | UPLOAD_CTP |
| `BELEG` | `0037` | Hóa đơn giảm (ZAP12) | PYMT_REQ |
| `BELEG` | `ID0xxx`/`IDZxxx` (động) | Extra text ID theo tên cột Excel | UPLOAD_FIDOC |
| `DOC_ITEM` | `0001` | Diễn giải / nội dung / lý do của dòng chứng từ FI | PHIEUTHU, PHIEUCHI, UYNHIEMCHI, SQT, BBDCCN_PHAITRA, ZGL07, GL_SCTTK, GL_CHUNGTUGHISO, PYMT_REQ, PYMT_REQ_P, UPLOAD_FIDOC, UPLOAD_R_FIDOC, UPLOAD_CTP, HD_POST_BILL |
| `ANLA` | `XLTX` | Long text mô tả tài sản | AA_BCTGTSCD |
| `LFA1` | `Z001` | Tên hàng hóa kinh doanh của NCC | PYMT_REQ (Active); PYMT_REQ_H (Comment) |
| `SKB1` | `0002` | Text G/L account (chưa rõ nghĩa) | PYMT_REQ_H (Comment) |
| `ZAP12` | `Z001` | Nội dung đề nghị thanh toán (text object tự tạo, ngắt 74 ký tự) | PYMT_REQ (Comment), xử lý đặc biệt trong `ZCORE_FM_SAVE_LONG_TEXT` |
| `MATERIAL` | `GRUN` | Basic data text – tên dài vật tư/sản phẩm | BCGTTT_A, BCGTTT, DDH, ZPI03 |
| `EKKO` | `A01` / `A02` | Nhận xét / Đề nghị (RFQ) | BBG |
| `EKKO` | `A05` | Thời hạn thanh toán ("Terms of delivery") | BBG |
| `EKKO` | `F01` | Diễn giải | DDH |
| `EKKO` | `F02` | Ghi chú | DDH |
| `EKKO` | `F05` | Điều kiện giao hàng | DDH |
| `EKKO` | `F14` | Nơi giao hàng | DDH |
| `EKKO` | `F15` | Số hợp đồng | DDH |
| `EKKO` | `Z01`…`Z09` | Nhóm hàng hóa, Giấy ủy quyền Bên Bán, Số ngày xác nhận ĐĐH, Các quy định khác, Chi phí giao hàng/bốc dỡ, Tiêu chuẩn chất lượng, Hồ sơ thanh toán, Địa điểm giao hàng, Thời hạn giao hàng | DDHNK |
| `EKPO` | `A01` | Tiêu chuẩn NSX (item text RFQ) | BBG |
| `EKPO` | `A4` | Thời gian giao hàng (additional item text) | BBG |
| `EKPO` | `F01` | Tiêu chuẩn | DDH |
| `EKPO` | `F02` / `F03` | Ghi chú dòng | DDH |
| `EKPO` | `F04` | Nhà SX / nồng độ hàm lượng (delivery text) | DDH, BBG |
| `EBAN` | `B01` | Bộ phận yêu cầu | ZMM01 |
| `EBAN` | `B02` | Ghi chú item | ZMM01, THNCVT |
| `EBAN` | `B03` | Nơi nhận | ZMM01 |
| `EBAN` | `B04` | "Items text" (SO_CODE) | ZMM01 |
| `EBAN` | `B08` | Ngày thỏa thuận | ZMM01 |
| `EBAN` | `B09` | Ý kiến của KH | ZMM01 |
| `EBAN` | `B10` | Yêu cầu chất lượng | ZMM01 |
| `EBAN` | `B11` | Vai trò – Mục đích sử dụng | ZMM01 |
| `EBAN` | `B12` | Số IO / nhà SX-nước SX | ZMM01 |
| `EBAN` | `B13` | Nhà sản xuất – nước sản xuất | ZMM01 |
| `EBANH` | `B01` | Diễn giải | ZMM01 |
| `EBANH` | `B02` | Mã SPM | ZMM01 |
| `EBANH` | `B03` | Tên SP | ZMM01 |
| `EBANH` | `B04` | Ngày đề nghị hoàn thành | ZMM01 |
| `EBANH` | `B05` | Bộ phận yêu cầu | ZMM01 |
| `VBBK` | `Z001` | Ghi chú đơn hàng | APPROVE_SO_CKTM |
| `VBBK` | `Z002` | Ghi chú kế toán công nợ | APPROVE_SO_CKTM |
| `VBBK` | `Z006` | Số hóa đơn | APPROVE_SO_CKTM |
| `VBBK` | `Z007` | Lý do từ chối phê duyệt | APPROVE_SO_CKTM |
| `VBBK` | `Z012` | Ngày hóa đơn | APPROVE_SO_CKTM |
| `VBBK` | `Z075` | Text đánh dấu billing (có nội dung → loại khỏi danh sách) – suy luận | HD_POST_BILL |
| `VBBK` (delivery) | `ZLF1` | Số hóa đơn | BBKNHH, HSPH, BCTK |
| `VBBK` (delivery) | `ZLF2` | Ngày hóa đơn | BBKNHH |
| `VBBK` (delivery) | `ZLF3` | Người kiểm nhận | BBKNHH |
| `VBBK` (delivery) | `ZLF4` | Người vận chuyển | BBKNHH |
| `VBBK` (delivery) | `ZLF5` | Người giao hàng | BBKNHH |
| `VBBK` (delivery) | `ZLF6` | Số xe vận chuyển | BBKNHH |
| `VBBP` | `0001`, `0006`, `Y101`, `X101`, `Y102`, `Y103` | Material Sales Text, Production Memo, Chiếu xạ, Ghi chú Item, Định mức bán hàng, Item Basic Text | APPROVE_SO_CKTM (Comment) |

---

## 4. Lưu ý

1. **Cùng Text ID nhưng ý nghĩa khác nhau giữa các program** (đối tượng `BELEG`): `0001`, `0002`, `0004`, `0008`, `0009` bị dùng khác nghĩa giữa nhóm phiếu thu/chi/UNC/PYMT_REQ_P và nhóm `ZFI_PG_UPLOAD_CTP` (và `ZAP03`). Bảng trên giữ nguyên theo từng program. Cần đối chiếu cấu hình Text ID của `BELEG` trên hệ thống (SE75 / bảng `TTXID`, `TTXIT`) để chốt ý nghĩa chuẩn — phần này chưa kiểm chứng được vì không dùng MCP.
2. **Tcode:** chỉ ghi được cho ZAP03, ZAP12, ZAP12P, ZAP12H, ZMM01, ZMM02, ZMM04, ZMM18, ZPI03, ZGL07, ZAR03 (căn cứ hằng số / header / FS / tên program; ghi rõ mức độ suy ra trong cột). Các program còn lại "Chưa xác định" — cần tra bảng `TSTC` (theo tên program) trên hệ thống.
3. `ZFI_PG_PYMT_REQ_H`: toàn bộ chỗ đọc long text hiện đã bị comment; form `READ_TEXT` của `ZFI_PG_PYMT_REQ_P` tồn tại nhưng không có chỗ gọi.
4. **Không tính là long text (đã loại):** `STXBITMAPS` / `GRAPHICS` `BMAP` trong `ZFM_GET_LOGO` (logo), `SET_LONG_TEXT` của ALV column, `create_text` của iXML trong `ZXLWB_INCLUDE`, macro `EDIT_TEXT` (field catalog ALV) trong các program `ZRB_*`, và `TODO` ghi long text 200 ký tự trong `zpmbc/zbcpm03/zbcpm03.abap:411` (chưa có code xử lý).
