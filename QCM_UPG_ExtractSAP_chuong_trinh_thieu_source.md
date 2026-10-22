# QCM_UPG – Chương trình còn thiếu source (đối chiếu ExtractSAP với 06_Source Code 20261022)

Nguồn đối chiếu: ExtractSAP (DS4 client 100, trích 20/10/2026 15:26) so với thư mục `CodeABAP/QCM_UPG/06_Source Code 20261022` (ngày 22/10/2026).
Kết quả chi tiết nằm trong sheet `Đối chiếu source` của 4 workbook `WCM_KiemKe_*_v1.1.xlsx` (thư mục `CodeABAP/QCM_UPG/ExtractSAP`).

## 34/661 chương trình của mã giao dịch

### Cần download: 2 nhóm hàm Z (dialog, có màn hình)

| Chương trình | Mã giao dịch | Download |
|---|---|---|
| `SAPLZFG_ASORTMENT_REQ` | ZRT240A, ZRT240B, ZRT240C | nhóm hàm `ZFG_ASORTMENT_REQ` |
| `SAPLZFG_PPCMAN` | ZPPC | nhóm hàm `ZFG_PPCMAN` |

### SAP Query: 21 chương trình `AQ…` do SAP sinh tự động

Không download chương trình, mà lấy định nghĩa query (SQ01/SQ02, nhóm người dùng + tên query). Tên query bị cắt ở 14 ký tự.

| Nhóm người dùng / query | Mã giao dịch |
|---|---|
| SYSTQV000024 / ZVBRP | ZVBRP |
| SYSTQV000013 / ZREBATE | ZRT059, ZRT159 |
| SYSTQV000032 / SD_SO_01 | ZRT268A |
| ZFI_COA_CI / ZFI_COA_CI | ZFI029C |
| ZFICO / ZFI061 | ZFI061 |
| ZFICO / ZFI062 | ZFI062 |
| ZFICO / ZFI081A | ZFI081A |
| ZFICO / ZFI081B | ZFI081B |
| ZFICO / ZFI089A | ZFI089A |
| ZFICO / ZFI_ACCRUALS2 | ZFI047 |
| ZFICO / ZFI_ACCRUALS | ZFI_ACCRUAL |
| ZFICO / ZFI_ASSET_LIST | ZFI037 |
| ZFICO / ZFI_CONTRACT1 | ZFI048 |
| ZFICO / ZPCCC1 | ZPCCC |
| ZMMREPORT / ZQR_TR_BC01 | ZTC_TR_BC01 |
| ZMMREPORT / ZQR_TR_BC02 | ZTC_TR_BC02 |
| ZMMREPORT / ZRB_CONDITIONN | ZRT164A |
| ZMMREPORT / ZRB_SETLE_PAYD | ZRT206 |
| ZMMREPORT / ZRT108R | ZRT108R |
| ZMMREPORT / Z_CONSIGNMENTW | ZRT212 |
| ZSD_PRICE / ZQR_ARTICLE_ST | ZMD_ACT01 |

### Chương trình chuẩn SAP: 11 chương trình

Không cần download, trừ khi hệ thống có sửa đổi (modification).

| Chương trình chuẩn SAP | Mã giao dịch Z gọi tới |
|---|---|
| HINUULK0 | ZHRF0001 |
| OA_UPLOAD_AND_LINK | ZHR_UPLOADPHOTO |
| RFFOAVIS_FPAYM | ZFI036 |
| RLLI2100 | ZLI21 |
| RM07MMFI | ZRT100 |
| RPCIP_DOCUMENT_ANALYSE | ZHR_FI |
| RPUTRBK0 | ZPU03 |
| RSUSR002 | ZSU00 |
| RWDDOWNLOAD | ZWPER2 |
| RWDIFFERENCEMARCWLK1_ENHANCED | ZSITE15 |
| SAPMSNUM | ZFI033A |

## 21/119 chương trình Z của job

Tất cả đều là chương trình chỉ chạy bằng job, không có mã giao dịch, nên không nằm trong source đã export. Cần download cả 21.

| Chương trình | Số job | Ví dụ tên job |
|---|---|---|
| `ZPG_FI026_NQ` | 12 | ZFI026NQ_B010_10NQ_JOB |
| `ZPG_MM_005_E_AUTO_CLOSE_PR` | 5 | CLOSE_PR_30_DAYS_VCM |
| `ZPG_MONITOR_JOBS_ALERT` | 5 | EARLYWATCH ALERT - BCF 1401 |
| `ZPG_PO_WF_APPROVAL` | 4 | ND_WF_PO_RELEASE |
| `ZPG_CHANGE_CREATE_TVARVC` | 2 | ZJ_NAST_DEL_OUTPUT_APP(EF&ME) |
| `ZPG_FI_SINGLE_RELEASE_REBATE` | 2 | ZJOB_PAYMENT_20548_F0000 |
| `ZPG_REVERSE_DOSTO` | 2 | SUPRA_REVERSE_GIDO_DC |
| `ZPG_RT_315_TU_DONG_HUY_TRA` | 2 | ZMON_COLLECT_STEP_PRJ201 |
| `ZCTK_CUSTOM_EXTRACT` | 1 | ZCTK_CUSTOM_EXTRACT |
| `ZDRFOUT_PMPL_INITIAL` | 1 | ZDMF_PMPL_NEW_INIT |
| `ZPG_CHECK_PRICE_MBEW` | 1 | CHECK_PRICE_MBEW |
| `ZPG_DASHBOARD` | 1 | EMAIL_MONOTOR_DASHBOARD |
| `ZPG_MD_032G_BBY_IDOC_RP` | 1 | ZMON_MD_WPDBBY_IDOC |
| `ZPG_QUEUEIN_ALERT` | 1 | SAP-PO: INBOUND QUEUE ALERT |
| `ZPG_SD_129_SLOC_EX_SO` | 1 | ZPG_SD_129_SLOC_EX_SO |
| `ZPG_SIMULATE_VF01` | 1 | CREATE AUTO BILLING 3RD FC |
| `ZPG_STDZ_XML_MON` | 1 | SAP_BC_XMB_STAND_DELETE_800 |
| `ZPG_SYNC_BBY_IDOC` | 1 | ZSOLMAN_BBY_IDOC_DASHBOARD_E6H |
| `ZPG_SYN_BW_AVCDECC0100` | 1 | DAILYSALES_POSDM_SAP |
| `ZPG_UPDATE_2LIS_06_INV_QUEUE` | 1 | ZPG_UPDATE_2LIS_06_INV_QUEUE |
| `Z_WSOH_WLK1` | 1 | Z_WSOH_WLK1_DISC_DEL |

`ZCTK_CUSTOM_EXTRACT` là chương trình trích của Citek, có thể bỏ qua.

## Ghi chú

- Trong ExtractSAP còn 239 chương trình đã được quét mà source cũng không có, phần lớn là chương trình demo (`ZDEMO_EXCEL*`, `ZABAP2XLSX*`). Chưa lọc riêng những chương trình có chạy thật (mã giao dịch hoặc job).
