# QCM_UPG – Chương trình còn thiếu source (đối chiếu ExtractSAP với 06_Source Code 20261022)

Nguồn đối chiếu: ExtractSAP (DS4 client 100, trích 20/10/2026 15:26) so với thư mục `CodeABAP/QCM_UPG/06_Source Code 20261022` (ngày 22/10/2026; đã đối chiếu lại ngày 23/10/2026 với bản source có thêm `Function_group` và `Class`).
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

## Cập nhật 23/10/2026 – thêm `Function_group` và `Class`

- Source nay có thêm thư mục `Function_group` (850 function module) và `Class` (512 lớp). **Danh sách 34 chương trình tcode và 21 chương trình job ở trên không đổi**: không chương trình nào trong số đó xuất hiện ở bất kỳ thư mục nào của source (kể cả `SAPLZFG_ASORTMENT_REQ` và `SAPLZFG_PPCMAN`, hai nhóm hàm này không có function module nào trong ExtractSAP).
- Function module có source tăng từ 154 lên **851/1.317**. Gồm đủ 807 hàm do khách hàng viết trong nhóm hàm khách hàng và 44 hàm sinh tự động bảo trì bảng.
- 466 hàm còn lại không có source: **388 hàm sinh tự động** (`TABLEFRAME_*`, `TABLEPROC_*`, `VIEWFRAME_*`, `VIEWPROC_*`… không cần download) và **78 hàm Z** (77 hàm nằm trong nhóm hàm chuẩn SAP, 1 hàm trong nhóm namespace `/ACCGO/`; bảng dưới – các nhóm hàm này không nằm trong source). Phần lớn là hàm mẫu/thử (`ZZ_SAMPLE_*`, `*TEST*`) hoặc khung bảo trì bảng (`ZIEWFRAME_V_*`); chỉ cần download nếu muốn đối chiếu thân hàm.

| Nhóm hàm (SAPL…) | Số hàm | Function module Z |
|---|---:|---|
| 080G | 16 | ZIEWFRAME_V_T6B1, ZIEWFRAME_V_T6B1_ZU, ZIEWFRAME_V_TKSF, ZIEWFRAME_V_TKSFK, ZIEWFRAME_V_TVBO, ZIEWFRAME_V_TVKK, ZIEWFRAME_V_TVKK_PA_PLTYPE, ZIEWFRAME_V_TVKK_STATGRP, ZIEWPROC_V_T6B1, ZIEWPROC_V_T6B1_ZU, ZIEWPROC_V_TKSF, ZIEWPROC_V_TKSFK, ZIEWPROC_V_TVBO, ZIEWPROC_V_TVKK, ZIEWPROC_V_TVKK_PA_PLTYPE, ZIEWPROC_V_TVKK_STATGRP |
| FVZLWF | 6 | ZGP_CHANGE, ZGP_CONFIRMATION, ZGP_DISPLAY, ZNB_CHANGE, ZNB_CONFIRMATION, ZNB_DISPLAY |
| BFFMSMPL2 | 3 | ZZ_SAMPLE_INTERFACE_00001005, ZZ_SAMPLE_PROCESS_00001130, ZZ_SAMPLE_PROCESS_00001140 |
| FMCC | 3 | Z_ENQUEUE_EKBLK, Z_KBLK_FORT_CHECK, Z_WORKITEM_CHECK |
| VS03B | 3 | ZAHLS_CHECK, ZTERM_CHECK, ZUAWA_CHECK |
| BWAF_WRAPPER_FUNCTIONS | 2 | ZMEREP_CONNECTOR_INBOX, ZMEREP_CONNECTOR_OUTBOX |
| FVZWT | 2 | ZWT_CUSTOMER_UPDATE, ZWT_DEBI_WRITE_DOCUMENT |
| PC66 | 2 | ZACE_SOP_CLIENT_READ, ZPCA_POST_RFC_PLANDATA_ACCOUNT |
| /ACCGO/CAS_SETTLEMENT_UI | 1 | ZACCGOTEST |
| CNISN | 1 | ZEITPUNKT_SETZEN |
| CRM_ACTIVITY_MINIAPP | 1 | ZCRM_MA_ACT_PARTNER_SEARCH |
| CVAR | 1 | ZVAR_BN_ID_CONCAT |
| CY01 | 1 | Z_DISP_SEQUENCE_GET |
| EAPARAL | 1 | ZZZZFKK_STPRZ_CONVERT |
| ECATT_GD_TEST | 1 | ZGDTEST |
| EE30 | 1 | ZISU_GET_VKONT_VTREF |
| EKM3 | 1 | Z_ISU_DUNNING_EVENT_0303 |
| EKM5 | 1 | ZFKK_SAMPLE_0810 |
| FBK_SSTN_VENDOR_EMBED | 1 | ZTEST_SCREEN |
| FBQA | 1 | ZSTS_IHC_AUDIT |
| FG_FMFG_TRSYSTOT | 1 | ZSH_LINENO |
| FKCRM_DOCMNT | 1 | Y_FKK_SAMPLE_2821 |
| FKMU | 1 | ZFKK_SAMPLE_1053 |
| FMBTE | 1 | ZTEST_TYPE |
| FMDA | 1 | Z_FM_FMAA_CUST_VALIDATE |
| FMITPOBF | 1 | Z_TEST_BTE_00103520 |
| FVEO | 1 | ZE_DATA_ANZEIGEN |
| FVEP | 1 | ZAHLWEG_ZU_MV |
| LEINT_LDSRV | 1 | YRD_AUDIT |
| LSO_WEBSRV | 1 | Z_SOAP_TEST |
| M61X | 1 | ZUORDNUNGSOBJEKTE_AUFBAUEN |
| MBMV | 1 | ZB_KZVBR_SETZEN |
| MCP6 | 1 | ZXSOPU02 |
| MDS_CMPT_COMPARISON | 1 | ZREAD_COMPARE_TOOL_CUSTOMIZING |
| MG01 | 1 | ZUS_EAN_READ_DESCRIPTION |
| MGUM | 1 | ZEITEINHEIT_PRUEFEN |
| MLSK | 1 | ZME_TEST |
| MMPUR_CCTR | 1 | ZMMPUR_CCTR_SL_CHANGE |
| ODATA_CV_DIR_API | 1 | ZODATA_CV_DIR_LINK_WITH_KPRO |
| OIO_NV | 1 | ZOIO_NV_AFVC_TO_EBAN_S |
| RMOP01 | 1 | ZERO_RATE_CONVERT |
| RSR_CACHE | 1 | ZJK_MAFIA_BUSINES_VOLUME |
| SRT_TEST_FRAMEWORK | 1 | ZL_ADD_DATA1 |
| TBL5 | 1 | ZB_EXPOSURE_GET_SUMS_DRILLDNEW |
| UCONFBADAPTERUNITTESTDATA | 1 | ZUCONFBADAPTERUNITTESTDATA |
| V15B | 1 | ZZ_BONUS_REPORT_NO_READ |
| V45P | 1 | YBT_TEST |
| V50G | 1 | ZZ_EXPIMP_PLANTS_VALUE_REQUEST |
| WVK3 | 1 | Z_PRICING_DOCUMENT_VALP_FILL |

- Mã 149 lớp BAdI trong ExtractSAP khớp thư mục `Enhance_implement`: 146 lớp giống hệt, 3 lớp chỉ khác ở phương thức rỗng (source không xuất file). 7/7 hàm BTE nay có source.
## Ghi chú

- Trong ExtractSAP còn 239 chương trình đã được quét mà source cũng không có, phần lớn là chương trình demo (`ZDEMO_EXCEL*`, `ZABAP2XLSX*`). Chưa lọc riêng những chương trình có chạy thật (mã giao dịch hoặc job).
