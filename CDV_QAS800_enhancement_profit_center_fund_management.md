# CDV QAS800 — Enhancement liên quan Profit Center / Fund Management

- Hệ: `GUI_CDV_QAS800` — QAS, client 800, release 816, HANA (user `CT.SUPPORT`), kiểm tra ngày 29.10.2026.
- Cách quét: `ENHOBJ`, `TADIR` (ENHO), `SXC_EXIT` + `SXC_CLASS` (BAdI cổ điển), `MODACT` + `MODSAP` (CMOD), `TFDIR` + `D010INC` (map include `ZX*` → exit), rồi grep/đọc source từng object.

## Kết luận

1. **Chỉ có 1 enhancement chạm trực tiếp Profit Center: CMOD `PCA00005` (include `ZXPCAU19`)** — rất nhỏ, chỉ đặt cờ relevance của PCA.
2. Phân hệ Fund Management có thêm 2 exit CMOD + 4 BAdI Z + 1 enhancement implicit, nhưng **không cái nào đọc/gán `PRCTR`**. Chỉ `ZXFMCU08` có logic nghiệp vụ thật (copy Fund Center `FISTL`).
3. Không tìm thấy BAdI/enhancement Z nào gán Profit Center trong luồng FM (Fund / Fund Center / Commitment Item / FM derivation).

## A. Trực tiếp Profit Center

| Enhancement | Exit (function) | Include | Project CMOD | Nội dung |
|---|---|---|---|---|
| `PCA00005` | `EXIT_SAPLPC32_004` | `ZXPCAU19` | `ZCADIVI` (active) | `C_GROUP_RELEVANT = '0'`; dòng `C_PRCTR_RELEVANT = '0'` đang bị comment. Không có điều kiện, áp cho mọi chứng từ qua exit này |

## B. Phân hệ Fund Management (không chạm PRCTR)

| Enhancement | Loại / đối tượng chuẩn | Object Z | Nội dung |
|---|---|---|---|
| `FMRESERV` | CMOD, `EXIT_SAPLFMR4_002` | include `ZXFMCU08` (project `ZCADIVI`) | **Có logic**: trên MIR7 (`T_ACCIT`), lấy `FISTL` (Fund Center) của dòng GL `2199999999` (KOART `A`) copy sang dòng đối ứng (SHKZG khác) có GL `211*`, `212*`, `213*`, `241*`, `242*`, khớp theo `EBELN`/`EBELP`. Người sửa: sangvt 07.01.2025 |
| `SAPLFMDT` | CMOD, `EXIT_SAPLFMDT_002` | include `ZXFMDTU02` (project `ZCADIVI`) | FM derivation tool: điền `zzekgrp`, `zzbsart`, `zzafnam` vào `c_fmderive` (đọc từ memory `ZEKGRP`/`ZPO_BSART`/`ZPO_AFNAM`, thiếu thì đọc `EKKO` theo `po_number`). KhoaLD thêm `zzafnam` 13.08.2025 |
| BAdI `FMBCCF_ENTRY_DOC` | BAdI cổ điển | `ZENH_FMBB_ENTRY_DOC` / `ZCL_IM_ENH_FMBB_ENTRY_DOC` | `CHANGE_DOCUMENT` chỉ có `BREAK-POINT` cho user `CT.SUPPORT2` (**còn sót break-point**); `UPDATE_BUDGET_INFO` rỗng |
| BAdI `FMKU_BUDGET_EVNT` | New BAdI (ENHS) | `ZENH_FMKU_BUDGET_EVNT` / `ZCL_FMKU_BUDGET_EVNT` | 3 method rỗng (code debug đã comment) |
| BAdI `MM_PUR_S4_PR` | New BAdI | `ZENH_MAPPING_COST_CENTER_TO_FM` / `ZCL_MM_PUR_PR_MODIFY_ITEM` | `MODIFY_ITEM` rỗng, dù tên là "mapping cost center → FM" |
| BAdI `FM_COMMITMENTS_BADI` | New BAdI | `ZFMOI_PO_DOWN_PAYMENT_REDUCE` / `ZCL_ENH_DOWN_PAYMENT` | `DISABLE_PO_REDUCTION`: `EV_FLG_DP_AND_DPR_REDU_DISABLE = 'X'` → down payment request và down payment không giảm commitment của PO |
| Implicit trong FUGR `FMBWB` | ENHO hook | `ZENH_SEND_MAIL_FMBB` | Tự gửi email khi bấm `Hold` ở FMBB; có nhánh theo `u_okcode` = `PREPOST`/`POST`; không có PRCTR |
| Implicit trong FUGR `RWCL` | ENHO hook | `ZENH_AC_DOCUMENT_POST` | "Accounting document post"; không có PRCTR/FISTL/GEBER/FIPEX |

CMOD `FMRESERV`/`SAPLFMDT`/`PCA00005` đều nằm trong project `ZCADIVI` (đã kích hoạt, theo `MODACT`).

## C. Đã đọc/quét, KHÔNG có `PRCTR`/`FISTL`/`FICTR`/`GEBER`/`FIPEX`

- BAdI class: `ZCL_IM_ENH_ACC_DOC_EXT2` (`ACC_DOCUMENT`, filter `BKPFF`), `ZCL_IM_ENH_PROCESS_PO_CUST`, `ZCL_IM_ENH_ME_PROCESS_REQ`, `ZCL_IM_IMP_MB21_CHECK`, `ZCL_IM_ENH_MIGO_BADI`, `ZCL_IM_CHECK_POST_MIGO`, `ZCL_IM_FI_ITEMS_CH_DATA`, `ZCL_IM_ENH_WORKORDER_INFOS`, `ZCL_BW_EXTRACTOR_BADI` (chỉ có dòng comment "Profit Segment").
- ENHO hook (15 object, đọc source): `ZENH_SET_FIELDS_VBRP`, `ZENH_FINT_CALCULATE`, `ZFI_FIX_REGROUP_EXT_END`, `ZEN_GET_DATA_FBL5N`, `ZENH_SET_VAL_TYPE`, `ZENH_VI01_SET_KOSTL`, `ZENH_VI01_SET_KOSTL_2`, `ZENH_SUBMIT_CKM3`, `ZENH_SUBMIT_CO09`, `ZENH_SUBMIT_KSS2`, `ZENH_RIAUFK20`, `ZENH_VF04_POSTO_INTERCOMPANY`, `ZEN_MIGO_A10_MTSNR`, `ZENH_BLOCK_BILL_BY_DATE`, `ZENH_CHECK_CREATE_BILLING_VF01`; thêm `ZENH_ZCO05_SUBMIT`, `ZENH_ZCO05_SUBMIT1`.

## D. Chưa xác minh / giới hạn

- **Không đọc được source** của 3 ENHO: `ZFI_FIX_CASH_LEDGER` (xử lý `cc_acc`/`cc_berk` thiếu bên credit), `ZFI_FIX_REGROUP_END` (reset biến remeasurement của FAGLF101 cho ledger 0L), `ZKKBC_SUBMIT` ("KKBC submit") — grep trả rỗng dù URI đúng. Theo mô tả thì không liên quan PRCTR/FM, nhưng chưa xác nhận bằng source (xem SE80/SE19).
- **Không quét** ~55 ENHO Z còn lại (SD/CRM/QM/PM, vd `SAPMV45A`, `SAPMV50A`, `V60A`...) vì tên/chương trình chính không liên quan FM/FI. Nếu cần chắc hơn có thể quét thêm.
- **Chưa kiểm tra trạng thái active** của các new BAdI (`ENHO`/ENHS: `ZENH_FMKU_BUDGET_EVNT`, `ZENH_MAPPING_COST_CENTER_TO_FM`, `ZFMOI_PO_DOWN_PAYMENT_REDUCE`) — không có trong `SXC_EXIT` vì không phải BAdI cổ điển.
- **Chưa xem cấu hình (không phải enhancement):** FM derivation strategy (`FMDERIVE`), gán Fund Center ↔ Profit Center, PCA settings. Các cấu hình này có thể gán Profit Center mà không cần code Z.
- **Chưa xem enhancement chuẩn SAP** đang chạy ở hệ (vd `FMPP_ENH_SET_PRCTR` / `CL_FMPP_ENH_SET_PRCTR` là implementation chuẩn có liên quan PRCTR, không phải Z).

## Gợi ý xử lý

- Dọn `BREAK-POINT` trong `ZCL_IM_ENH_FMBB_ENTRY_DOC~CHANGE_DOCUMENT` trước khi chuyển lên PRD (đang gắn riêng user `CT.SUPPORT2`).
- Nếu yêu cầu thật là gán/derive Profit Center trong FM: hiện chưa có code Z nào làm việc đó; cần kiểm tra cấu hình `FMDERIVE`/PCA trước khi viết enhancement mới (và hỏi xác nhận trước khi tạo code/object).
