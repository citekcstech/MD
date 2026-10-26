# MPC PRD800 — Danh mục API đang cấu hình trong SAP (inbound / outbound)

Ngày kiểm tra: 26.10.2026. Hệ thống: **PRD, client 800, release 750** (MCP `GUI_MPC_PRD800`, user CITEKSUPPORT, host ADT `https://prdci1cloud.minhphu.com:44333`). Chỉ đọc (RunQuery / GetSource / GrepObjects), không ghi gì lên hệ thống.

## 0. Phạm vi và giới hạn — đọc trước

- **Đã quét**: object khách hàng (namespace Z). Bao gồm RFC function module (TFDIR, FMODE=R), service SOAP (VEPFUNCTION + ICF), REST (ICF handler Z), OData Gateway (/IWFND/I_MED_SRH), RFC destination (RFCDES), bảng cấu hình tích hợp (ZTB_INT_PATH, ZTB_TPS_URL), log tích hợp (ZTB_INT_LOG).
- **Mức xác nhận "đang dùng" (cập nhật 26.10.2026, sau khi đối chiếu file ST03N tháng 10):** OData đã có số liệu chính xác Aug–Oct/2026 từ bảng Gateway (mục 5.2); SOAP chỉ có tháng 10 từ ST03N (mục 5.1); outbound đối chiếu bằng log/job/ST03N (mục 2.1, 5.3). **RFC thuần và REST `/sap/zcrm/customers` vẫn chưa xác nhận được** (file ST03N không có RFC Profile). `CallRFC` báo lỗi `ZADT_VSP WebSocket ... bad handshake` (ZADT_VSP chưa deploy trên PRD800) nên không tự đọc ST03N qua MCP.
- Bằng chứng gián tiếp dùng được: `ZTB_INT_LOG` (log gọi eApp), lịch sử job `TBTCO` (**chỉ giữ từ 12.10.2026**, nên không đủ 3 tháng).
- Cột "Sửa lần cuối" (ICF/OData) là ngày chỉnh object, **không** phải ngày có người gọi.
- **Host công khai mà bên gọi đang dùng chưa xác nhận.** Host ghi dưới đây là host kết nối ADT của MCP. Port/host thật (qua reverse proxy, SAP Web Dispatcher) cần Basis xác nhận (SMICM / profile `icm/server_port_*`).
- Không đọc các cột chứa thông tin đăng nhập (`ZTB_INT_PATH.BASICAUTH`, `ZTB_TPS_URL.USERNAME/PASSWORD`, `ICF_PASSWD`). Xem mục 4 về rủi ro lưu thông tin đăng nhập.

## 1. Inbound — hệ thống ngoài gọi vào SAP

### 1.1 SOAP web service (ICF `/sap/bc/srt/rfc/sap/...`, nền là RFC function module)

URL dạng `https://<host>:<port>/sap/bc/srt/rfc/sap/<service_def>/800/<service>/<binding>` (WSDL: thêm `?wsdl`). Payload là SOAP envelope; tham số lấy từ interface của function module (bảng dưới). Mọi tham số input đều **optional** trừ khi ghi "bắt buộc".

#### Nhóm CRM — 21 service `ZWS_CRM01..21` (tạo 01.03.2022 – 02.08.2022)

ICF path chung: `/sap/bc/srt/rfc/sap/zws_crmNN/800/zsn/zbn`.

| Service | Function module | Input (SOAP request) | Output (SOAP response) |
|---|---|---|---|
| ZWS_CRM01 | ZCRM_CUSTOMER | CRM_CUSTOMERS_INPUT (ZCRM_CUSTOMER_INPUT_TT, **bắt buộc**) | CRM_CUSTOMERS_OUTPUT (ZCRM_CUSTOMER_OUTPUT_TT), CRM_RETURN (ZCRM_RETURN_TT) |
| ZWS_CRM02 | ZCRM_DOANHSOKH | SALESORG, PROFILEFOREIGNCODE (KUNNR), FROM_PERIOD, TO_PERIOD (SPMON) | DOANHSO_DATAS (ZCRM_DOANHSOKH_TT) |
| ZWS_CRM03 | ZCRM_HOPDONGDAKY | SALESORG, PROFILEFOREIGNCODE, FROM_PERIOD, TO_PERIOD | HOPDONGDAKY_DATAS (ZCRM_HOPDONGDAKY_TT) |
| ZWS_CRM04 | ZCRM_DUYETDONHANG | SAP_SALESORDER (VBELN), USER_STATUS (J_BERSL), USER_CRM (ZUSER_CRM) | CRM_RETURN (ZCRM_RETURN_TT) |
| ZWS_CRM05 | ZCRM_HOPDONG | SALESDOCUMENT, PROFILEFOREIGNCODE, FROM_DATE, TO_DATE, STATUS, PO_FROM_DATE, PO_TO_DATE, ORDER_STATUS, PERSONNELNUMBER, PARNERFUNCTION, SIZENOIBO, BUYER | HOPDONG_DATAS (ZCRM_HOPDONG_TT) |
| ZWS_CRM06 | ZCRM_HOPDONG_CANHBAO | SALESDOCUMENT, PROFILEFOREIGNCODE | HOPDONG_DATAS (ZCRM_HOPDONG_TT) |
| ZWS_CRM07 | ZCRM_CUOCTAU | HANGTAU, CANGDEN, FROM_DATE, TO_DATE | CUOCTAU_DATAS (ZCRM_CUOCTAU_TT) |
| ZWS_CRM08 | ZCRM_NHANVIEN | PERSONNEL_NUMBER | EMPLOYEE_DATAS (ZCRM_NHANVIEN_TT) |
| ZWS_CRM09 | ZCRM_DONHANG | SALESDOCUMENT, PROFILEFOREIGNCODE, FROM_DATE, TO_DATE, STATUS, PERSONNELNUMBER, PARNERFUNCTION | DONHANG_DATAS (ZCRM_DONHANG_TT) |
| ZWS_CRM10 | ZCRM_DOANHSOXUATBAN | SALESORG, DISTRIBUTIONCHANNEL, FROM_DATE, TO_DATE, BILLINGDOCUMENT, PROFILEFOREIGNCODE | DOANHSO_DATAS (ZCRM_DOANHSOXUATBAN_TT) |
| ZWS_CRM11 | ZCRM_DOANHSONHANVIEN | FROM_DATE, TO_DATE, PERSONNELNUMBER, PARNERFUNCTION | DOANHSO_DATAS (ZCRM_DOANHSONHANVIEN_TT) |
| ZWS_CRM12 | ZCRM_DOANHTHUXUATKHAU | FROM_DATE, TO_DATE, PLANT, THITRUONGCAP2XK (VKGRP), COMPARATIVE | DOANHSO_DATAS (ZCRM_DOANHTHUXUATKHAU_TT_TT) |
| ZWS_CRM13 | ZCRM_TONKHO | PLANT, MATERIALS (range), MATERIAL_DESCS (range), BATCHS (range), GR_DATES (range) | TONKHO_DATAS (ZCRM_TONKHO_TT) |
| ZWS_CRM14 | ZCRM_HOPDONG_HEADER | như ZCRM_HOPDONG | HOPDONG_DATAS (ZCRM_HOPDONG_HEADER_TT) |
| ZWS_CRM15 | ZCRM_CUOCTAU_MASTER | như ZCRM_CUOCTAU | CUOCTAU_DATAS (ZCRM_CUOCTAU_TT) |
| ZWS_CRM16 | ZCRM_DOANHTHUXUATKHAU_MASTER | như ZCRM_DOANHTHUXUATKHAU | DOANHSO_DATAS (ZCRM_DOANHTHUXUATKHAU_TT) |
| ZWS_CRM17 | ZCRM_DONHANG_HEADER | như ZCRM_DONHANG + CUSTOMER_NAME (TEXT255) | DONHANG_DATAS (ZCRM_DONHANG_HEADER_TT) |
| ZWS_CRM18 | ZCRM_DOANHSOXUATBAN_MASTER | như ZCRM_DOANHSOXUATBAN | DOANHSO_DATAS (ZCRM_DOANHSOXUATBAN_MT_TT) |
| ZWS_CRM19 | ZCRM_ATTACHMENT_FILES | SALESDOCUMENT (VBELN_VA) | FILES (ZCRM_FILES) |
| ZWS_CRM20 | ZCRM_CANG_DEN | (không có) | CANG_DEN_LIST (ZCRM_CANG_DEN_TT) |
| ZWS_CRM21 | ZCRM_BUYERS | BUYER (ZDE_BUYER) | BUYERS (ZTT_BUYER) |

`ZWS_CRM01` (nhận dữ liệu khách hàng) và `ZWS_CRM04` (đổi user status đơn hàng) có tham số vào dạng dữ liệu/trạng thái nên nhiều khả năng **ghi** vào SAP; các service còn lại có dạng đọc (lọc theo ngày/khách/đơn). Chưa đọc source từng FM để khẳng định.

#### Nhóm ZBM — kho (8 service, tạo 12.2014 – 05.2015)

ICF path: `/sap/bc/srt/rfc/sap/zbm_ws_<mã>/800/zbm_sn_<mã>`. Với KIKE, NKHT, NKKH, NKMH, NKSX, XKTL, XNSX còn có thêm node `/800/zbm_ws_<mã>`; KIKE có thêm `zbm_sn_kike2`. Mọi service còn node `/900/...` — hệ thống chỉ có client 000 và 800 (bảng T000) nên các node client 900 là cấu hình thừa. Interface mọi FM giống nhau: input `IS_INPUT` (ZBM_ST_WS_<mã>, **bắt buộc**); output `ES_OUTPUT` (cùng structure), `EW_RESULT` (CHAR10), `EW_MSG` (CHAR255).

| Service | Function module | Mô tả (text FM) | Structure vào/ra |
|---|---|---|---|
| ZBM_WS_CHKH | ZBM_FM_WS_CHKH | Nhập kho mua hàng nội bộ (text FM) | ZBM_ST_WS_CHKH |
| ZBM_WS_KIKE | ZBM_FM_WS_KIKE | Nhập kho mua hàng nội bộ (text FM) | ZBM_ST_WS_KIKE |
| ZBM_WS_NKHT | ZBM_FM_WS_NKHT | Nhập kho hàng khách trả lại | ZBM_ST_WS_NKHT |
| ZBM_WS_NKKH | ZBM_FM_WS_NKKH | Nhập kho khác (Transfer Order) | ZBM_ST_WS_NKKH |
| ZBM_WS_NKMH | ZBM_FM_WS_NKMH | Nhập kho mua hàng nội bộ | ZBM_ST_WS_NKMH |
| ZBM_WS_NKSX | ZBM_FM_WS_NKSX | Nhập kho sản xuất | ZBM_ST_WS_NKSX |
| ZBM_WS_XKTL | ZBM_FM_WS_XKTL | Xuất kho (Transfer Order) | ZBM_ST_WS_XKTL |
| ZBM_WS_XNSX | ZBM_FM_WS_XNSX | Text FM: nhập kho mua hàng nội bộ (trùng do copy; mã XNSX có thể là xuất/nhập SX — chưa xác nhận) | ZBM_ST_WS_XNSX |

Lưu ý: text mô tả của vài FM trùng nhau do copy; ý nghĩa nghiệp vụ suy từ tên mã (CHKH, KIKE, NKHT...) — cần đối chiếu với nghiệp vụ.

#### Nhóm báo cáo CITEKA và các service lẻ

| Service (VEPNAME) | Function module | ICF path (đã thấy trong SICF) | Input | Output | Sửa lần cuối |
|---|---|---|---|---|---|
| ZWS_DOANHSO | ZFM_CITEKA_DOANHSO | `/sap/bc/srt/rfc/sap/zws_doanhso/800/zsn_doanhso/zsn_doanhso` | I_MONTH (NUMC2), I_YEAR (NUMC4), I_COMPANY_CODE (NUMC4) | E_KETQUA (CHAR255) | 13.04.2018 |
| ZWS_LOINHUANGOP | ZFM_CITEKA_LOINHUANGOP | `/sap/bc/srt/rfc/sap/zws_loinhuangop/800/zsn_lng/zsn_lng` | như trên | E_KETQUA | 13.04.2018 |
| ZWS_CHIPHIBANHANG | ZFM_CITEKA_CHIPHIBANHANG | `/sap/bc/srt/rfc/sap/prd8001/800/zsn_cpbh/zsn_cpbh` (suy luận theo tên `cpbh` = chi phí bán hàng) | như trên | E_KETQUA | 13.04.2018 |
| ZWS_CHIPHIQUANLY | ZFM_CITEKA_CHIPHIQUANLY | `/sap/bc/srt/rfc/sap/prd8002/800/zsn_cpql/zsn_cpql` (suy luận: `cpql` = chi phí quản lý) | như trên | E_KETQUA | 13.04.2018 |
| ZWS_PLANT_SLOC | ZFM_GET_PLANT_SLOC | `/sap/bc/srt/rfc/sap/zws_plant_sloc/800/zsn/zbn` | IDAPP (CHAR20) | PLANT (WERKS_D), STORAGES (ZBM_TT_PLANT_SLOC) | 18.11.2019 |
| ZWS_SHIPMENT | ZSD_FM_SHIPMENT | `/sap/bc/srt/rfc/sap/zws_shipment/800/zsn_shipment/zbn_shipment` | TPBEZ, TNDR_TRKID | ET_SHIPMENT (ZTT_SHIPMENT_API), ET_SHIPMENT_DETAIL (ZTT_SHIPMENT_DETAIL_API), ET_SHIPMENT_SUBTOTAL (ZTT_SHIPMENT_SUBTOTAL_API), E_MSG, E_MSGNO, E_MSGTY | 14.06.2019 |

Service có định nghĩa (VEPFUNCTION) nhưng **không thấy node ICF** (SICF) theo tên Z nên chưa phát hành ra ngoài: `ZWS_INT_IMPORT_VC` (ZFM_INT_WS_IMPORT: IS_INPUT / ES_OUTPUT ZST_INT_VC_H, EW_MSG), `ZWS_LOGIN` (ZBM_FM_WS_LOGIN → E_CODE FLAG), `ZWS_TX` (ZFM_BM_TX: INTERVAL NRNR → NUMBER_TX AUFNR). Cần kiểm tra thêm trong SOAMANAGER nếu nghi ngờ vẫn có bên gọi.

#### RFC function module không qua SOAP

- `ZSAP_FM_L_INV_COUNT` (nhóm SAPLZSAP_FG_LMDE): RFC kiểm kê kho, input I_INPUT_METHOD + bảng S_LINV (E1LINVX), output ALLE_LGNUM/IVNUM/NVERS, nhiều exception — dạng nhập IDoc/kiểm kê, chưa xác định bên gọi.
- 8 FM RFC mang tên Z nhưng nằm trong function group do SAP giao (SAPLFVZLWF, SAPLPC66, SAPLMDS_CMPT_COMPARISON, SAPLFVD_PROPOSALS, SAPLFCCT, SAPLCY04, SAPLLSO_WEBSRV): `ZGP_DISPLAY`, `ZNB_DISPLAY`, `ZPCA_POST_RFC_PLANDATA_ACCOUNT`, `ZREAD_COMPARE_TOOL_CUSTOMIZING`, `Z_VERTRAG_MODUS`, `ZCCARD_AUTH_SIMULATION`, `Z_TR_CIF_TEST`, `Z_SOAP_TEST` — của SAP, không phải API khách hàng.

Tổng RFC-enabled function module Z: 47 (21 ZCRM + 9 ZBM + 4 ZFM_CITEKA + ZFM_GET_PLANT_SLOC + ZFM_BM_TX + ZFM_INT_WS_IMPORT + ZSD_FM_SHIPMENT + ZSAP_FM_L_INV_COUNT + 8 của SAP).

### 1.2 REST (ICF handler Z)

| Link | Handler | Method | Input | Response |
|---|---|---|---|---|
| `https://<host>/sap/zcrm/customers` | `ZCL_REST_CRM_HANDLER` → `ZCL_REST_CUSTOMER_RESOURCE` (package ZMPC, mô tả "API CRM Customer") | GET | không có tham số lọc | JSON mảng (camelCase): `customerCode` (KUNNR), `customerName1..4` (NAME1..4 của KNA1) |

Ghi chú: handler đọc **toàn bộ KNA1**, không lọc, không phân trang. Tạo 10.07.2025, sửa 14.07.2025. Chưa đọc cấu hình đăng nhập của node ICF.

### 1.3 OData (SAP Gateway)

Gateway đăng ký **196 service Z** (đều trạng thái A, version 0001). Chi tiết ở Phụ lục A. Phân nhóm:

| Nhóm | Số lượng | Bản chất |
|---|---|---|
| `ZODP_*` | 140 | Tên theo mẫu ODP/DataSource (0CUSTOMER_ATTR, 2LIS_11_VAHDR, 0FI_GL_14...); bên tiêu thụ đã xác nhận ở mục 5.2: Power BI/Fabric (user `FABRIC.BW`). 39/140 có gọi trong Aug–Oct/2026 |
| `ZBW_CDS_*` + `ZBW_*` | 45 | CDS view publish OData (`..._CDS`); cùng bên tiêu thụ `FABRIC.BW`. 21/45 có gọi |
| `ZCDS_TB_*` | 9 | CDS view publish OData |
| `ZINT_*` | 2 | Tích hợp eApp (bên dưới) |

34 service có ngày sửa từ 25–26.10.2026 (nhiều service ZODP lúc 02:00–03:00 ngày 26.10) — có thể do job/transport, **không chứng minh có người gọi**.

#### ZINT_EAPP_PO_SRV — eApp → SAP (kết quả phê duyệt PO), sửa 19.03.2026

- Base: `/sap/opu/odata/sap/ZINT_EAPP_PO_SRV/`
- Entity set: `HeaderSet` (entity `Header`), `ItemSet` (entity `Item`), navigation `items`.
- `Header`: stt, deNghiMuaVatTuSo, ticketId, ghiChu, nguoiDeNghi, soDienThoai, phongBan, NotephongBan, status, message, ngayLapPhieu, gioLapPhieu, maNhanVien, code, messCode, prNum, prType, poNum, note, plant, ngayChange, gioChange, maNVChange.
- `Item`: reqNum, ticketId, item, maVatTu, tenVatTu, soLuong, donViTinh, ngayGiao, storageLocation, purchasingGroup, valuationPrice, ghiChuBPYC, ghiChuMDSD, ghiChuItem, NoteitemQc, deleteLine.
- Ghi: `create_deep_entity` + `headerset_create_entity` → bảng `ZTB_PO_EAPP` (ZTICKET_ID, EBELN, ZSTATUS, NOTE, MESS). Hiện có 5.821 dòng: COMPLETED 5.632, DELETE_DRAFT_TICKET 87, DRAFT 68, CANCEL 26, ERROR 7, OPENED 1. Bảng không có cột ngày nên không tách được 3 tháng.
- Trường dùng làm phản hồi theo model (entity `Header`): `code`, `messCode`, `status`, `message`, `poNum`. Chưa có response mẫu thực tế.
- Chiều gọi: eApp gọi vào SAP (suy luận từ việc service nhận POST/deep insert và ghi `ZTB_PO_EAPP`; chưa thấy log phía gọi).

#### ZINT_EAPP_PR_SRV — sửa 28.03.2026

- Entity: `PRHEAD` (set `PRHEADSET`; ZREQUEST_NUMBER, ZTICKET_ID, TXLINE, TXLINE_SDT, TXLINE_BPYC, NOTEITEM_BPYC, ZSTATUS, ZMESSAGE, ZENTERED_ON/AT, ZUSER_BY), `PRITEM` (set `PRITEMSET`; BNFPO, MATNR, TXZ01, MENGE, MEINS, EEIND, WERKS, LGOBE, EKGRP, PREIS, ZNOTEITEM, ZNOTEITEM_QC).
- Class `ZCL_ZINT_EAPP_PR_DPC_EXT` **không có method nào được viết** (chỉ `inheriting from ZCL_ZINT_EAPP_PR_DPC`) → service có model nhưng chưa có logic xử lý. **Đính chính sau khi đối chiếu:** service **có người gọi** (user `FPT.EAPP`, 207 / 198 / 147 lượt ở tháng 08 / 09 / 10, xem mục 5.2) — nội dung trả về chưa kiểm tra.

## 2. Outbound — SAP gọi ra hệ thống ngoài

Quy ước: RFC destination loại G (HTTP ra ngoài), H (HTTP tới ABAP), 3 (ABAP), T (TCP/IP), I (internal), X (ABAP-driver). RFCDES có 28 dest loại 3, 15 loại G, 2 loại H, 14 loại I, 1 loại L, 29 loại T, 3 loại X. Dưới đây chỉ liệt kê loại G/H (API HTTP).

### 2.1 eApp — workflow phê duyệt (có bằng chứng đang chạy)

Cấu hình `ZTB_INT_PATH` (client 800):

| OBJECT | Base URL | End point | Dest | Ghi chú |
|---|---|---|---|---|
| 01 | `https://eapp.minhphu.com` | `/api/masterdata/masterData/sync` | `ZEAPP_DEV` | Đồng bộ danh mục vật tư (suy luận: chương trình `ZPG_INT_MATNR_TO_EAPP` gọi `ZFM_INT_POST`; xem bên dưới). RFC dest `ZEAPP_DEV` **không tồn tại trong RFCDES** (mọi loại) — code dùng `create_by_url`, không dùng dest này |
| 02 | `https://eapp.minhphu.com` | `/api/business/bpmProcInst/createBasicAuth/` + `<procdefid>` + `/0` | (trống) | **Tạo phiếu duyệt đơn đặt hàng (PO)** — đang chạy |
| 03 | `https://eapp.minhphu.com` | `/api/business/service-pack/getServiceByIdBasicAuth?serviceId=` | (trống) | Chỉ có cấu hình, chưa thấy code gọi |

- Luồng code (function group `ZFG_INT_EAPP`): chương trình `ZPG_INT_PO_TO_EAPP` (gọi `ZFM_INT_PO_EAPP_MANUAL`) và `ZPG_INT_MATNR_TO_EAPP` gọi `ZFM_INT_POST` (HTTP bằng `cl_http_client=>create_by_url`, URL = `base_url` + `end_point` trong `ZTB_INT_PATH`) → ghi log `ZFM_APPS_API_LOG` vào `ZTB_INT_LOG`. `ZFM_INT_PO_EAPP` (bản không MANUAL) không có chỗ gọi tĩnh trong cross-reference — có thể gọi động/từ BAdI, chưa xác nhận.
- **Bằng chứng job**: lịch sử job (TBTCO) chỉ giữ từ 12.10.2026. Trong 12–26.10.2026, `ZPG_INT_MATNR_TO_EAPP` chạy **4.165 lần**, trạng thái F (xong), lần cuối 26.10.2026 → đồng bộ vật tư sang eApp đang chạy định kỳ (tần suất cao). `ZPG_INT_PO_TO_EAPP` (tcode `ZEAPP_PO`) và `ZPG_INTEG_TPSOFT` không có job trong cửa sổ đó nhưng ST03N tháng 10 cho thấy chạy dialog (mục 5.3).
- Header gửi đi: `Content-Type` và `Accept` = `application/json`, `messageId` = GUID 32, `authorization` = chuỗi Basic lấy từ `ZTB_INT_PATH.BASICAUTH` (không đọc).
- **Payload (POST)** — cấu trúc đúng như log thực tế:
  ```json
  { "variables": {
      "requestSubject": {"value": "Phê duyệt đơn đặt hàng", "type": "string", "valueInfo": null},
      "start_txt_donHangSo": {...}, "start_txt_congTy": {...}, "start_txt_puchorg": {...},
      "start_txt_punchgroup": {...}, "starttxt_maNcc": {...}, "start_txt_tenNcc": {...},
      "start_dtm_ngayLapPhieu": {...}, "start_txt_tongTien": {...}, "start_txt_donViTienTe": {...},
      "start_txt_tongTienTruocThue": {...}, "start_txt_tongTienSauThue": {...},
      "start_tbl_xinVuiLongCungCapChoChungToiCacMatHangVoiNhungChiTietDieuKienSau":
         {"value": "{\"data\":{\"tableName\":\"\",\"data\":[{ txt_maVatTu, txt_tenVatTu, txt_soLuong,
           txt_donViTinh, dtm_ngayGiao, txt_donGia, txt_thanhTien, txt_loaiTien, txt_thue, ... }]}}", "type": "Json"}
    },
    "serviceId": 16, "isDraft": true, "priorityId": 1, "appCode": "SAP",
    "account": "", "requestCode": "<số PO>" }
  ```
  Mỗi trường `variables.*` có dạng `{value, type, valueInfo}`; còn nhiều trường khác (địa chỉ/điện thoại người nhận, địa điểm giao hàng, phương thức thanh toán...).
- **Response** (log): `{"code":-1,"message":"Account là trường bắt buộc !","data":null}` hoặc thành công (`code` = 0). Sau đó eApp gọi ngược lại `ZINT_EAPP_PO_SRV` (mục 1.3) để trả trạng thái.
- **Bằng chứng sử dụng (ZTB_INT_LOG, chỉ có object 02, method POST, from SAP):** tổng 5.916 dòng; **từ 26.07.2026 đến 26.10.2026: 2.580 dòng**, dòng mới nhất 26.10.2026. Cột `FAILED` luôn trống kể cả khi response báo lỗi (`code = -1`) → không dùng `FAILED` để đo tỉ lệ lỗi, phải đọc `RESPONSE`.

### 2.2 TPS (phiếu cân) — function group `ZFG_TPS_GEN`

URL lấy từ `ZTB_TPS_URL` theo `LOGSYS` + `MA_CTY` (đăng nhập lấy token trước):

| MA_CTY | URL |
|---|---|
| 1 | `https://phancotom-camau-apisap.minhphu.com:8889` |
| 2 | `https://phancotom-haugiang-apisap.minhphu.com:8890` |
| 3 | `https://phancotom-khanhan-apisap.minhphu.com:6435` |

Cùng host có RFC destination `PHANCOTOM-CAMAU/-HAUGIANG/-KHANHAN` (loại G; Khánh An có path `/version`).

| Function module | Input | Output |
|---|---|---|
| ZFM_TPS_GETTOKEN | (đọc URL/user/pass từ ZTB_TPS_URL) | TOKEN; exception NO_URL, NO_USERNAME, NO_PASSWORD, LOGIN_FAILED, ERROR_CALL_API |
| ZFM_TPS_GETLISTPHIEUCAN | I_BUKRS, I_MA_DL (optional) | PHIEU_SU, PHIEU_THE (ZTT_LISTPHIEUCAN) |
| ZFM_TPS_GETCHITIETPHIEUCAN | ID (bảng) | PHIEU_SU (ZTT_CHITIETPHIEUCAN), PHIEU_THE (ZTT_CHITIETPHIEUCAN_THE) |
| ZFM_TPS_GETCHITIET_JSON | ID | JSON thô |
| ZFM_TPS_GETSTATUS | ID (bảng), I_BUKRS | E_RETURN (ZTT_ID_GETSTATUS) |
| ZFM_TPS_SETSTATUS | ID (ZTT_ID_SETSTATUS), I_BUKRS | E_RETURN (ZST_SETSTATUS_RETURN) |
| ZFM_JSON_REST_API (hàm dùng chung) | URL, METHOD (GET/POST/PUT), TOKEN (Bearer), BODY | E_RESPONSE, E_STATUS, E_REASON |

Chương trình gọi: `ZPG_INTEG_TPSOFT` ("Tích hợp phiếu cân tôm"; include `ZIN_INTEG_TPSOFT_F01` gọi GETLISTPHIEUCAN, GETCHITIETPHIEUCAN, GETSTATUS, SETSTATUS). Không có job trong lịch sử job 12–26.10.2026, nhưng ST03N tháng 10/2026 ghi **160 bước dialog** → đang được dùng thủ công (mục 5.3).

### 2.3 CRM API (bên ISD)

RFC destination (loại G, TLS 443): `CRMAPI` → `https://crm-api1.minhphu.com/api/v1/Customer/Profile/SyncProfile`; `ISD_CRM_API_TRAINNING` → cùng path (môi trường đào tạo); `ISD` → `https://crm-api1.minhphu.com/` (gốc). `MINHPHU-API.ISDCORP.VN` → `https://minhphu-api.isdcorp.vn/swagger/index.html` (trang Swagger, có thể chỉ để test kết nối). Chưa xác định được code gọi (cross-reference các lớp HTTP client trong Z chỉ thấy `ZCL_REST_CONSUMER` và `ZSUPPORT_HUB_CERT_RENEWAL`; destination có thể được gọi bằng cách khác), nên chưa có payload/response.

### 2.4 Hoá đơn điện tử

| Destination | Loại | URL |
|---|---|---|
| VNPT | H | `https://cptdtsminhphuadmin.vnpt-invoice.com.vn/PublishService.asmx` (SOAP .asmx) |
| VNPT_1 | G | `https://cptdtsminhphu-tt78admin.vnpt-invoice.com.vn/PublishService.asmx` (bản TT78) |
| TEST-VIETTEL-EINVOICE | G | `https://api-vinvoice.viettel.vn/auth/login` (thử nghiệm) |

**Đính chính sau khi đối chiếu ST03N:** hoá đơn điện tử VNPT gọi qua **ABAP consumer proxy `ZWS_EINVCO_PORTAL_SERVICE_SOAP`** (logical port, method `LIST_INV_BY_CUS_FKEY`) trong `ZFI_PG_EINV_UPDATE` (job `ZEIV_UPDATE`) và màn hình `ZEIV01` (`ZFI_PG_EINV_PROC`) — chi tiết ở mục 5.3. Chưa có payload/response mẫu.

### 2.5 Hạ tầng / SAP chuẩn (không phải API nghiệp vụ)

`ADS` (Adobe Document Services, `adscloudji.minhphu.com:50100`), `RCC_GRID_ENGINE` (`harwich01:55000`), `CSI_AWS_EC2`/`CSI_AWS_S3` (AWS), `SAP-SUPPORT_NOTE_DOWNLOAD`, `SAP-SUPPORT_PARCELBOX`, `SAP-SUPPORT_PORTAL` (SAP Support Hub). HTTP client Z còn thấy: `ZSUPPORT_HUB_CERT_RENEWAL` (gia hạn chứng chỉ Support Hub), `ZCL_REST_CONSUMER` (wrapper chung `cl_http_client`, dùng trong `ZFG_INT_EAPP`).

## 3. Việc cần làm tiếp để kết luận "đang dùng trong 3 tháng"

(Đã làm một phần ở mục 5 sau khi có file ST03N tháng 10.)

1. Xuất thêm từ ST03N: **RFC Profile → Server** (để xét RFC thuần: `ZSAP_FM_L_INV_COUNT`, `ZFM_INT_WS_IMPORT`, `ZBM_FM_WS_LOGIN`, `ZFM_BM_TX`...) và **Transaction Profile tháng 08, 09** (để đủ 3 tháng cho SOAP, mục 5.1).
2. Xem ICF/ICM log hoặc `SMICM` để biết `/sap/zcrm/customers` có người gọi không (ST03N gộp mọi HTTP vào `SAPMHTTP`).
3. Triển khai ZADT_VSP (hoặc dùng người có quyền chạy `SAPWL_WORKLOAD_GET_STATISTIC`) nếu muốn tự động hoá việc này qua MCP.
3. Cần mở rộng nếu muốn: payload mức field của các structure/table type (ZBM_ST_WS_*, ZCRM_*_TT, ZTT_SHIPMENT_API...) — hiện chỉ ghi tên kiểu.
4. Truy vết bên gọi của các destination CRM/VNPT/Viettel/TPS (tìm chương trình/job; ngoài SAP có thể là hệ thống khác gọi vào).

## 4. Rủi ro phát hiện khi quét

- `ZTB_INT_PATH.BASICAUTH` và `ZTB_TPS_URL.USERNAME/PASSWORD` có vẻ lưu thông tin đăng nhập trực tiếp trong bảng Z (code đọc thẳng ra để gửi), không qua kho bảo mật — cần xem xét bảo vệ bảng (nhóm phân quyền S_TABU_DIS) hoặc chuyển sang SSF/SECSTORE. Chưa xác nhận nội dung vì cố ý không đọc các cột này.
- `/sap/zcrm/customers` trả toàn bộ khách hàng, không phân trang.
- `ZTB_INT_LOG.FAILED` không phản ánh lỗi thật (xem mục 2.1).
- ICF còn các node client 900 (`/zbm_ws_*/900/...`) trong khi hệ thống chỉ có client 000 và 800 (T000) — node thừa, nên dọn.

## 5. Đối chiếu với ST03N tháng 10/2026 và thống kê Gateway

Nguồn đối chiếu (bổ sung ngày 26.10.2026):

- File ST03N `CodeABAP/CITEK_RETAIL/MINHPHU_ST03N_202610.XLSX`: Transaction Profile tháng 10/2026 (1.118 dòng, xuất ngày 26.10). Không có cột loại tác vụ, **không có RFC Profile**, và mọi request HTTP dồn vào một dòng `SAPMHTTP` (1.199.678 bước) nên không tách được OData/REST theo URL. SOAP tách được vì mỗi service chạy dưới chương trình `SIW=======<tên service>`.
- Bảng Gateway của chính PRD800: `/IWFND/SU_ASTATS` (thống kê tháng theo service, **chỉ có tháng 08, 09, 10/2026**; không có tháng 07) và `/IWFND/SU_STATS` (chi tiết từ 18.10.2026, có user và loại client gọi). Đây là số liệu chính xác theo từng OData service.

### 5.1 SOAP — 38 service định nghĩa, 17 có gọi trong tháng 10/2026

**Có gọi trong tháng 10/2026** (dialog step = số lần gọi service; thời gian là tổng response time):

| Service | Function module | Bước (10/2026) | Tổng response (s) | TB/bước (ms) |
|---|---|---|---|---|
| ZWS_CRM02 | ZCRM_DOANHSOKH | 367,628 | 22,000 | 60 |
| ZWS_CRM03 | ZCRM_HOPDONGDAKY | 220,591 | 11,794 | 53 |
| ZBM_WS_NKSX | ZBM_FM_WS_NKSX | 20,943 | 3,403 | 162 |
| ZWS_CRM11 | ZCRM_DOANHSONHANVIEN | 16,400 | 2,790 | 170 |
| ZBM_WS_CHKH | ZBM_FM_WS_CHKH | 16,365 | 2,846 | 174 |
| ZWS_CRM17 | ZCRM_DONHANG_HEADER | 3,809 | 3,376 | 886 |
| ZWS_PLANT_SLOC | ZFM_GET_PLANT_SLOC | 3,483 | 222 | 64 |
| ZWS_CRM09 | ZCRM_DONHANG | 3,311 | 270 | 82 |
| ZWS_CRM19 | ZCRM_ATTACHMENT_FILES | 3,310 | 1,438 | 434 |
| ZBM_WS_NKKH | ZBM_FM_WS_NKKH | 2,094 | 94 | 45 |
| ZWS_CRM04 | ZCRM_DUYETDONHANG | 1,359 | 94 | 69 |
| ZWS_CRM12 | ZCRM_DOANHTHUXUATKHAU | 473 | 2,427 | 5131 |
| ZWS_SHIPMENT | ZSD_FM_SHIPMENT | 442 | 68 | 154 |
| ZWS_CRM13 | ZCRM_TONKHO | 392 | 2,745 | 7003 |
| ZWS_CRM07 | ZCRM_CUOCTAU | 53 | 4 | 75 |
| ZWS_CRM05 | ZCRM_HOPDONG | 29 | 1,630 | 56207 |
| ZWS_CRM15 | ZCRM_CUOCTAU_MASTER | 16 | 1 | 62 |

**Không thấy gọi trong tháng 10/2026** (21 service): chưa đủ để kết luận bỏ — file chỉ có 1 tháng và không có RFC Profile:

| Service | Function module |
|---|---|
| ZWS_CRM01 | ZCRM_CUSTOMER |
| ZWS_CRM06 | ZCRM_HOPDONG_CANHBAO |
| ZWS_CRM08 | ZCRM_NHANVIEN |
| ZWS_CRM10 | ZCRM_DOANHSOXUATBAN |
| ZWS_CRM14 | ZCRM_HOPDONG_HEADER |
| ZWS_CRM16 | ZCRM_DOANHTHUXUATKHAU_MASTER |
| ZWS_CRM18 | ZCRM_DOANHSOXUATBAN_MASTER |
| ZWS_CRM20 | ZCRM_CANG_DEN |
| ZWS_CRM21 | ZCRM_BUYERS |
| ZBM_WS_KIKE | ZBM_FM_WS_KIKE |
| ZBM_WS_NKHT | ZBM_FM_WS_NKHT |
| ZBM_WS_NKMH | ZBM_FM_WS_NKMH |
| ZBM_WS_XKTL | ZBM_FM_WS_XKTL |
| ZBM_WS_XNSX | ZBM_FM_WS_XNSX |
| ZWS_DOANHSO | ZFM_CITEKA_DOANHSO |
| ZWS_LOINHUANGOP | ZFM_CITEKA_LOINHUANGOP |
| ZWS_CHIPHIBANHANG | ZFM_CITEKA_CHIPHIBANHANG |
| ZWS_CHIPHIQUANLY | ZFM_CITEKA_CHIPHIQUANLY |
| ZWS_INT_IMPORT_VC | ZFM_INT_WS_IMPORT |
| ZWS_LOGIN | ZBM_FM_WS_LOGIN |
| ZWS_TX | ZFM_BM_TX |

**Chậm bất thường** (response trung bình mỗi lần gọi): `ZWS_CRM05` / `ZCRM_HOPDONG` (29 lượt, TB **56 giây**), `ZWS_CRM13` / `ZCRM_TONKHO` (392 lượt, TB 7 giây), `ZWS_CRM12` / `ZCRM_DOANHTHUXUATKHAU` (473 lượt, TB 5 giây), `ZWS_CRM17` (886 ms).

Nhận xét: `ZWS_CRM02` (doanh số khách hàng) và `ZWS_CRM03` (hợp đồng đã ký) chiếm gần như toàn bộ lưu lượng SOAP (khoảng 590 nghìn bước, trung bình ~60 ms mỗi bước) — dạng poll liên tục từ CRM. 3 service chưa phát hành ICF (`ZWS_INT_IMPORT_VC`, `ZWS_LOGIN`, `ZWS_TX`) đúng là không có lưu lượng. `ZWS_CHIPHIBANHANG`/`ZWS_CHIPHIQUANLY` có ICF node tên `prd8001`/`prd8002` nhưng không thấy trong ST03N — nếu chương trình runtime mang tên khác `SIW=======ZWS_*` thì có thể bị bỏ sót (cần xác nhận).

### 5.2 OData — 67 trong 196 service Z có người gọi trong Aug–Oct/2026

| Nhóm | Tổng đăng ký | Có gọi | Không thấy gọi |
|---|---|---|---|
| ZODP_* | 140 | 39 | 101 |
| ZBW_* | 45 | 21 | 24 |
| ZCDS_TB_* | 9 | 5 | 4 |
| ZINT_* | 2 | 2 | 0 |
| **Cộng** | **196** | **67** | **129** |

Bên gọi (`/IWFND/SU_STATS` từ 18.10.2026): các service `ZODP_*`, `ZBW_*`, `ZCDS_TB_*` đều do user `FABRIC.BW`, loại client `Microsoft.Data.Mashup` (Power Query / Microsoft Fabric hoặc Power BI) kéo dữ liệu theo lịch (nhiều lần/ngày); hai service `ZINT_EAPP_PO_SRV` và `ZINT_EAPP_PR_SRV` do user `FPT.EAPP` (client Java/17) gọi. Như vậy nhóm ZODP/ZBW/ZCDS_TB là **đầu ra dữ liệu cho Power BI/Fabric**, đã xác nhận (trước đó mục 1.3 chỉ suy luận là BW).

**Đính chính:** `ZINT_EAPP_PR_SRV` **có người gọi** (207 / 198 / 147 lượt ở tháng 08 / 09 / 10, user `FPT.EAPP`) dù lớp `ZCL_ZINT_EAPP_PR_DPC_EXT` không có logic — phía eApp đang gọi service này; cần xem kết quả trả về (có thể chỉ là kiểm tra kết nối hoặc đọc `$metadata`).

Lượt gọi theo tháng (số thao tác Gateway, `SU_ASTATS`) của các service có gọi:

| Service | Tháng 08 | Tháng 09 | Tháng 10 (đến 26.10) |
|---|---|---|---|
| ZODP_CT_ZBW_DS_MCH1_SRV_1 | 1,441 | 1,431 | 1,185 |
| ZODP_SD_ZBW_DS_VBAP_NOTE_SRV | 1,067 | 1,105 | 825 |
| ZODP_CT_ZBW_DS_AUSP_CW_SRV | 950 | 909 | 750 |
| ZINT_EAPP_PO_SRV | 943 | 777 | 707 |
| ZODP_SD_ZBW_DS_VBKD_1_SRV_01 | 558 | 552 | 474 |
| ZODP_LO_0CUSTOMER_TEXT_SRV2 | 578 | 540 | 456 |
| ZODP_SD_VBAK_BUYER_SRV | 511 | 563 | 463 |
| ZODP_PP_ZDS_ZIS_MAST_STPO_SRV | 523 | 483 | 423 |
| ZODP_PP_ZDS_ZIS_P_MATNR_SRV | 493 | 455 | 375 |
| ZODP_SD_ZBW_DS_MARA_2_SRV | 426 | 426 | 330 |
| ZODP_MM_2LIS_03_UM_SRV | 376 | 372 | 308 |
| ZODP_SD_ZBW_DS_MARM_SRV | 376 | 368 | 304 |
| ZODP_SD_ZBW_DS_VBEP_SRV | 380 | 368 | 300 |
| ZODP_LO_0MATERIAL_ATTR_SRV | 384 | 360 | 300 |
| ZODP_MM_2LIS_03_BF_SRV | 372 | 372 | 300 |
| ZODP_MM_ZBW_DS_MARC_SRV | 377 | 365 | 300 |
| ZODP_SD_2LIS_11_VAITM_SRV_1 | 325 | 430 | 264 |
| ZODP_SD_2LIS_13_VDITM_SRV | 330 | 421 | 264 |
| ZODP_SD_2LIS_13_VDKON_SRV | 326 | 316 | 264 |
| ZODP_SD_2LIS_11_VAHDR_SRV | 330 | 311 | 264 |
| ZODP_SD_2LIS_13_VDHDR_SRV | 326 | 311 | 264 |
| ZCDS_TB_VBRP_VTTK_CDS | 299 | 285 | 228 |
| ZBW_CDS_CKMLCR_DQ1_CDS | 279 | 273 | 258 |
| ZODP_SD_VBAP_TVM5T_DELTA_SRV | 282 | 285 | 234 |
| ZBW_CDS_CO_PC_ACT_1_D_CDS | 291 | 276 | 225 |
| ZODP_SD_ZBW_DS_PA0002_SRV | 288 | 279 | 225 |
| ZCDS_TB_MSEG_LH_D_CDS | 290 | 270 | 231 |
| ZBW_CDS_MSEG_AUSP_SXXK_CDS | 288 | 277 | 225 |
| ZODP_SD_0SALES_GRP_TEXT_SRV | 285 | 279 | 225 |
| ZBW_CDS_VBKD_INCO_CDS | 282 | 279 | 225 |
| ZODP_LO_0CUSTOMER_ATTR_SRV1 | 288 | 273 | 225 |
| ZBW_CDS_ZPP_TB_SLNL_CDS | 282 | 270 | 231 |
| ZODP_CT_TCURR_SRV | 285 | 273 | 225 |
| ZODP_LO_0PLANT_TEXT_SRV | 285 | 273 | 225 |
| ZODP_SD_T179_SRV | 279 | 273 | 231 |
| ZBW_CDS_EKET_DELIV_CDS | 279 | 273 | 228 |
| ZODP_LO_0MATERIAL_TEXT_SRV | 282 | 270 | 228 |
| ZODP_LO_0PLANT_ATTR_SRV | 282 | 273 | 225 |
| ZODP_MM_0VENDOR_ATTR_SRV | 285 | 270 | 225 |
| ZODP_SD_0SALES_DIST_TEXT_SRV | 282 | 273 | 225 |
| ZODP_SD_0SALES_OFF_TEXT_SRV | 282 | 273 | 225 |
| ZBW_CDS_VBKD_PAYTERM_CDS | 282 | 270 | 225 |
| ZINT_EAPP_PR_SRV | 207 | 198 | 147 |
| ZBW_CDS_OFFSET_ACC_62_CDS | 171 | 171 | 114 |
| ZODP_SD_ZBW_DS_LIPS_SRV | 155 | 160 | 125 |
| ZBW_CDS_EKPO_D_CDS | 96 | 93 | 75 |
| ZCDS_TB_EKPO_D_CDS | 93 | 96 | 75 |
| ZBW_AR_NOIBO_CDS | 96 | 93 | 72 |
| ZBW_CDS_FI_AP_04_D_CDS | 96 | 93 | 72 |
| ZBW_CDS_FI_GL_14_CHIPHI_D_CDS | 99 | 90 | 72 |
| ZODP_CT_ZBW_DS_MSKA_SRV | 96 | 90 | 75 |
| ZBW_CDS_FI_AR_221_CDS | 96 | 90 | 74 |
| ZBW_AP_NOIBO_CDS | 93 | 93 | 72 |
| ZBW_CDS_EKKO_SUBMI_CDS | 93 | 90 | 75 |
| ZBW_CDS_FI_GL_10_CDS | 93 | 90 | 75 |
| ZCDS_TB_RSEG_D_CDS | 93 | 90 | 75 |
| ZBW_CDS_FI_AP_04_338_CDS | 93 | 90 | 72 |
| ZBW_CDS_FI_AR_04_D_CDS | 93 | 90 | 72 |
| ZBW_CDS_FI_AR_138_CDS | 93 | 90 | 72 |
| ZBW_CDS_OFFSET_ACC_214_CDS | 93 | 90 | 72 |
| ZODP_MM_ZBW_DS_MBEWH_SRV | 37 | 12 | 12 |
| ZBW_CDS_VTBFHA_VTBFHAPO_CDS | 15 | 12 | 12 |
| ZODP_SD_2LIS_13_VDITM_SRV_2 | 0 | 17 | 0 |
| ZODP_MM_ZBW_DS_MBEW_SRV | 5 | 5 | 5 |
| ZODP_SD_2LIS_13_VDITM_SRV_1 | 0 | 10 | 0 |
| ZCDS_TB_EKPO_CDS | 0 | 0 | 7 |
| ZODP_PP_ZDS_ZIS_P_COMP_SRV | 0 | 0 | 7 |

Rất ít lượt (có thể chỉ chạy thử): `ZODP_SD_2LIS_13_VDITM_SRV_1` (10, chỉ tháng 09), `ZODP_SD_2LIS_13_VDITM_SRV_2` (17, chỉ tháng 09), `ZCDS_TB_EKPO_CDS` (7, chỉ tháng 10), `ZODP_PP_ZDS_ZIS_P_COMP_SRV` (7, chỉ tháng 10), `ZODP_MM_ZBW_DS_MBEW_SRV` (5/tháng).

**129 service OData Z không có lượt gọi nào trong Aug–Oct/2026** — danh sách ở Phụ lục B (ứng viên ngừng/xoá sau khi xác nhận với bên dùng; chú ý dữ liệu chỉ phủ khoảng 3 tháng gần nhất).

### 5.3 Outbound và chương trình tích hợp trong ST03N tháng 10/2026

| Chương trình / giao dịch | Việc làm | ST03N 10/2026 |
|---|---|---|
| `ZPG_INT_MATNR_TO_EAPP` (job `Z_JOB_INT_MAT_TO_EAPP`) | Đồng bộ danh mục vật tư sang eApp | 7.200 bước (batch) — **đang chạy** |
| Tcode `ZEAPP_PO` → `ZPG_INT_PO_TO_EAPP` | Gửi PO sang eApp tạo phiếu duyệt | 2.493 bước dialog + 31 bước chạy trực tiếp — **đang chạy** (`ZTB_INT_LOG` có 2.580 dòng trong 3 tháng) |
| `ZPG_INTEG_TPSOFT` ("Tích hợp phiếu cân tôm", `ZIN_INTEG_TPSOFT_F01`) | Gọi API TPS (phiếu cân) | 160 bước dialog — **đang chạy** (đính chính: tên chương trình là `ZPG_INTEG_TPSOFT`) |
| Tcode `ZEIV01` → `ZFI_PG_EINV_PROC` ("Hoá đơn điện tử MPC") | Màn hình hoá đơn điện tử | 1.740 bước dialog + 10 bước — **đang chạy** |
| Job `ZEIV_UPDATE` → `ZFI_PG_EINV_UPDATE` | Cập nhật trạng thái HĐĐT từ nhà cung cấp VNPT | 25 bước (batch) — **đang chạy** |
| `ZBM_PG_WS_CHUYENSAP` ("Màn hình chuyển thông tin từ Web Service sang SAP") | Xử lý dữ liệu nhận từ web service | 678 bước |
| `ZINT_PG_INPUT_SO` ("Import/manual phiếu mua tôm nguyên liệu") | Nhập phiếu mua tôm | 114 bước |

**E-invoice VNPT (đính chính mục 2.4):** `ZFI_PG_EINV_UPDATE` gọi qua **ABAP consumer proxy `ZWS_EINVCO_PORTAL_SERVICE_SOAP`** (logical port, method `LIST_INV_BY_CUS_FKEY` — tra cứu hoá đơn theo khoá khách hàng), user/mật khẩu web service lấy từ bảng `ZTB_KB_USER_PASS`. Hai destination `VNPT`/`VNPT_1` trong SM59 nhiều khả năng là điểm đến của logical port; cần xem SOAMANAGER để chắc chắn. Chưa thấy chương trình nào dùng `CRMAPI`/`ISD`/Viettel — chưa có bằng chứng dùng.

### 5.4 RFC Server / RFC Client (ST03N tháng 10/2026) và ICM trace

Nguồn: `MINHPHU_ST03N_202610_RFC_Server.XLSX` (122 function module), `MINHPHU_ST03N_202610_RFC_Client.XLSX` (92 dòng chương trình/giao dịch), `ICM_Log.txt` (dev_icm, 42 MB, trace level 1, từ 22.08 đến 26.10.2026 08:59).

**RFC Server — kết quả cho RFC thuần: không có function module Z nào được gọi qua RFC trong tháng 10.** Cụ thể không thấy `ZSAP_FM_L_INV_COUNT`, `ZFM_INT_WS_IMPORT`, `ZBM_FM_WS_LOGIN`, `ZFM_BM_TX`, `ZSD_FM_SHIPMENT`, `ZCRM_*`, `ZBM_FM_WS_*`, `ZFM_CITEKA_*`. Các FM `ZCRM_*`, `ZBM_FM_WS_*`... chạy được là nhờ SOAP (mục 5.1): service SOAP thực thi FM ngay trong tác vụ HTTP nên không tính là RFC. Toàn bộ RFC server là FM chuẩn SAP (GOS_EXECUTE_SERVICE, KKPF_PARA_SETTLEMENT_EXEC, K_VARIANCES_PARALLEL_CALC, SWNC/SALC/ARFC/BDL...). Ghi nhận: `IDOC_START_INBOUND` 172 lượt, gần khớp 176 IDoc vào (direction 2) trong tháng 10 — **toàn bộ là `INVOIC`/`INVOIC02`** (bảng EDIDC), không phải kiểm kê (`LINV`) nên `ZSAP_FM_L_INV_COUNT` không liên quan luồng này.

Kết luận cho RFC thuần (tháng 10): `ZSAP_FM_L_INV_COUNT`, `ZFM_INT_WS_IMPORT`, `ZBM_FM_WS_LOGIN`, `ZFM_BM_TX` **không có lượt gọi RFC** (ZFM_INT_WS_IMPORT, ZBM_FM_WS_LOGIN, ZFM_BM_TX còn không có node SOAP/ICF).

**RFC Client:** chỉ cho biết chương trình/giao dịch nào phát sinh RFC đi (không có cột destination, không đếm HTTP/SOAP đi). Không thấy `ZPG_INT_MATNR_TO_EAPP`, `ZPG_INT_PO_TO_EAPP`, `ZPG_INTEG_TPSOFT`, `ZFI_PG_EINV_*` — đúng, vì các chương trình này gọi bằng HTTP/SOAP chứ không phải RFC. Các giao dịch Z có RFC (ZFBM01 1.181 lượt, ZWM01 799, ZFSD06 114, ZWM04 110, ZMB51 43, ZRAP01 41...) phần lớn ≤ 2 ms mỗi lần (ngoại lệ: ZMB51 ~308 ms, ZSD11 1 lượt 6,9 giây) — dạng RFC cục bộ, không giống gọi hệ thống ngoài; không thấy `DESTINATION` trong chương trình chính của ZFBM01/ZWM01/ZFSD06/ZWM04 (chưa quét include). Điểm bất thường (ngoài phạm vi API): `VA03` có 6.393 lượt RFC, trung bình ~712 giây mỗi lượt (tổng 4,56 triệu giây), cùng bậc thời gian với `GOS_EXECUTE_SERVICE` bên server (16.179 lượt, tổng 4,6 triệu giây) — nên xem lại dịch vụ đính kèm (GOS) trong VA02/VA03.

**ICM trace (`ICM_Log.txt`) — không phải access log:** trace level 1 chỉ ghi lỗi, **không có dòng nào ghi URL request** (không có `zcrm`, không có `GET`/`POST`), nên **không dùng được để biết ai gọi `/sap/zcrm/customers`**. Nhưng có các sự kiện outbound đáng chú ý trong tháng 10:

| Thời điểm | Sự kiện | Ý nghĩa |
|---|---|---|
| 20.10 07:42–10:24 | Handshake SSL **thất bại `SSSLERR_PEER_CERT_UNTRUSTED`** tới 4 host VNPT: `thuysanminhphat-tt78admin` (24 lượt lỗi), `cptdtsminhphu-tt78admin` (20), `cptdtsminhphuadmin` (10), `minhphuhaugiang-tt78admin` (2), cổng 443 | E-invoice VNPT **có gọi trong tháng 10 cho ít nhất 4 tenant** (chứng chỉ VNPT chưa được tin trong STRUST — client SSL anonymous). Sau 10:24 không còn lỗi. `thuysanminhphat-...` và `minhphuhaugiang-...` **không có trong SM59** → nằm trong logical port của proxy `ZWS_EINVCO_PORTAL_SERVICE_SOAP` |
| 12.10 14:08, 19.10 13:23 | Hết thời gian kết nối 5 giây tới `phancotom-camau-apisap.minhphu.com:8889` | TPS Cà Mau **có được gọi** trong tháng 10 (khớp 160 bước `ZPG_INTEG_TPSOFT`); thỉnh thoảng không kết nối được |
| 01.10–15.10 | `IcmReadFromPartner: No data from server received` (2 lần), `IcmCreateDpRequest: Session does not exist` (7 lần) | Kết nối bị ngắt giữa chừng, rải rác, không có URL |

Các lỗi trước tháng 10 (để tham khảo): 22–24.08 có 26.658 lỗi TLS `certificate unknown` từ host 10.84.17.142 vào cổng 44333 (chỉ trong 3 ngày rồi dừng); `phancotom-haugiang-apisap...:8890` hết thời gian kết nối nhiều lần (nhiều nhất 12.09, 08:00–09:52, khoảng 35 lần, **không còn thấy trong tháng 10**); `eapp.minhphu.com:443` hết thời gian 1 lần (25.08). Host 10.84.17.133 chính là SAProuter trong destination SAP-SUPPORT.

### 5.5 Còn chưa đối chiếu được (tháng 10)

- **REST `/sap/zcrm/customers`**: ST03N gộp HTTP vào `SAPMHTTP`, ICM trace level 1 không ghi URL → **vẫn chưa biết có người gọi hay không**. Cần bật `icm/HTTP/logging_0` (mục 8 của hướng dẫn ST03N), hoặc xem access log của proxy phía trước, hoặc ICF Recorder.
- 21 SOAP service không thấy gọi trong tháng 10 (mục 5.1) và 129 OData service không có lượt gọi từ tháng 08 (Phụ lục B): chỉ là ứng viên ngừng dùng.
- Outbound `CRMAPI`/`ISD`/`MINHPHU-API.ISDCORP.VN`/Viettel: không có dấu vết trong ST03N lẫn ICM trace tháng 10 (ICM chỉ ghi lỗi nên không loại trừ hoàn toàn).

---

## Phụ lục A — 196 OData service Z đã đăng ký trong Gateway (/IWFND/I_MED_SRH)

Đường dẫn gọi: `/sap/opu/odata/sap/<TÊN_SERVICE>/` (metadata: `.../$metadata`). Cột 'Sửa lần cuối' là ngày chỉnh service, không phải ngày có người gọi.

### Nhóm ZBW_ (2 service)

| Service | Ver | Trạng thái | Sửa lần cuối |
|---|---|---|---|
| ZBW_AP_NOIBO_CDS | 0001 | A | 10.12.2025 |
| ZBW_AR_NOIBO_CDS | 0001 | A | 27.11.2025 |

### Nhóm ZBW_CDS_ (43 service)

| Service | Ver | Trạng thái | Sửa lần cuối |
|---|---|---|---|
| ZBW_CDS_A902_KONP_CDS | 0001 | A | 14.05.2025 |
| ZBW_CDS_ACT_1_F3_T_CDS | 0001 | A | 08.12.2025 |
| ZBW_CDS_BSEG_GKONT_CDS | 0001 | A | 05.08.2025 |
| ZBW_CDS_BSEG_GKONT_HM1_CDS | 0001 | A | 05.08.2025 |
| ZBW_CDS_BSEG_GKONT_HM2_CDS | 0001 | A | 05.08.2025 |
| ZBW_CDS_CKMLCR_CDS | 0001 | A | 04.08.2025 |
| ZBW_CDS_CKMLCR_DQ1_CDS | 0001 | A | 04.08.2025 |
| ZBW_CDS_CKMLCR_DQ2_CDS | 0001 | A | 04.08.2025 |
| ZBW_CDS_CKMLCR_DQ3_CDS | 0001 | A | 04.08.2025 |
| ZBW_CDS_CKMLCR_DQ4_CDS | 0001 | A | 04.08.2025 |
| ZBW_CDS_CKMLCR_D_CDS | 0001 | A | 30.07.2025 |
| ZBW_CDS_CO_PC_ACT_1_CDS | 0001 | A | 30.05.2025 |
| ZBW_CDS_CO_PC_ACT_1_D_CDS | 0001 | A | 30.05.2025 |
| ZBW_CDS_EKET_DELIV_CDS | 0001 | A | 09.02.2026 |
| ZBW_CDS_EKKO_SUBMI_CDS | 0001 | A | 25.12.2025 |
| ZBW_CDS_EKPO_CDS | 0001 | A | 02.06.2025 |
| ZBW_CDS_EKPO_D_CDS | 0001 | A | 18.04.2026 |
| ZBW_CDS_FI_AP_04_338_CDS | 0001 | A | 16.11.2025 |
| ZBW_CDS_FI_AP_04_CDS | 0001 | A | 18.11.2025 |
| ZBW_CDS_FI_AP_04_D_CDS | 0001 | A | 18.04.2026 |
| ZBW_CDS_FI_AR_04_CDS | 0001 | A | 26.05.2026 |
| ZBW_CDS_FI_AR_04_D_CDS | 0001 | A | 26.05.2026 |
| ZBW_CDS_FI_AR_138_CDS | 0001 | A | 14.11.2025 |
| ZBW_CDS_FI_AR_221_CDS | 0001 | A | 16.11.2025 |
| ZBW_CDS_FI_GL_10_CDS | 0001 | A | 25.11.2025 |
| ZBW_CDS_FI_GL_14_CDS | 0001 | A | 05.08.2025 |
| ZBW_CDS_FI_GL_14_CHIPHI_CDS | 0001 | A | 04.12.2025 |
| ZBW_CDS_FI_GL_14_CHIPHI_D_CDS | 0001 | A | 18.04.2026 |
| ZBW_CDS_FI_GL_14_D_2_CDS | 0001 | A | 10.08.2025 |
| ZBW_CDS_FI_GL_14_D_3_CDS | 0001 | A | 10.08.2025 |
| ZBW_CDS_FI_GL_14_D_CDS | 0001 | A | 19.11.2025 |
| ZBW_CDS_MSEG_AUSP_SXXK_CDS | 0001 | A | 20.05.2025 |
| ZBW_CDS_OFFSET_ACC_214_CDS | 0001 | A | 03.12.2025 |
| ZBW_CDS_OFFSET_ACC_62_CDS | 0001 | A | 04.12.2025 |
| ZBW_CDS_RSEG_CDS | 0001 | A | 20.01.2026 |
| ZBW_CDS_RSEG_D_CDS | 0001 | A | 20.01.2026 |
| ZBW_CDS_SHIPMENT_COGS_CDS | 0001 | A | 12.08.2025 |
| ZBW_CDS_SHIPMENT_QUANT_CDS | 0001 | A | 13.08.2025 |
| ZBW_CDS_SHIPMENT_REVENUE_CDS | 0001 | A | 12.08.2025 |
| ZBW_CDS_VBKD_INCO_CDS | 0001 | A | 02.06.2025 |
| ZBW_CDS_VBKD_PAYTERM_CDS | 0001 | A | 22.10.2025 |
| ZBW_CDS_VTBFHA_VTBFHAPO_CDS | 0001 | A | 27.10.2025 |
| ZBW_CDS_ZPP_TB_SLNL_CDS | 0001 | A | 17.10.2025 |

### Nhóm ZCDS_TB_ (9 service)

| Service | Ver | Trạng thái | Sửa lần cuối |
|---|---|---|---|
| ZCDS_TB_EKPO_CDS | 0001 | A | 13.10.2026 |
| ZCDS_TB_EKPO_D_CDS | 0001 | A | 13.10.2026 |
| ZCDS_TB_EKPO_NOTRSEG_CDS | 0001 | A | 08.05.2026 |
| ZCDS_TB_EKPO_TEST_CDS | 0001 | A | 10.05.2026 |
| ZCDS_TB_MSEG_LH_CDS | 0001 | A | 26.06.2025 |
| ZCDS_TB_MSEG_LH_D_CDS | 0001 | A | 18.04.2026 |
| ZCDS_TB_RSEG_CDS | 0001 | A | 21.01.2026 |
| ZCDS_TB_RSEG_D_CDS | 0001 | A | 18.04.2026 |
| ZCDS_TB_VBRP_VTTK_CDS | 0001 | A | 12.05.2026 |

### Nhóm ZINT_ (2 service)

| Service | Ver | Trạng thái | Sửa lần cuối |
|---|---|---|---|
| ZINT_EAPP_PO_SRV | 0001 | A | 19.03.2026 |
| ZINT_EAPP_PR_SRV | 0001 | A | 28.03.2026 |

### Nhóm ZODP_ (140 service)

| Service | Ver | Trạng thái | Sửa lần cuối |
|---|---|---|---|
| ZODP_COPC_0CO_PC_01_SRV | 0001 | A | 22.04.2025 |
| ZODP_COPC_0CO_PC_ACT_10_SRV | 0001 | A | 28.02.2025 |
| ZODP_COPC_0CO_PC_ACT_1_SRV | 0001 | A | 07.05.2025 |
| ZODP_COPC_0CO_PC_PCP_20_SRV | 0001 | A | 28.02.2025 |
| ZODP_COPC_0CO_PC_PCP_30_SRV | 0001 | A | 28.02.2025 |
| ZODP_CO_OM_0COSTCENTER_TEXT | 0001 | A | 12.08.2025 |
| ZODP_CT_TCURR_SRV | 0001 | A | 26.10.2026 |
| ZODP_CT_ZBW_DS_AUSP_CTX_SRV | 0001 | A | 08.08.2025 |
| ZODP_CT_ZBW_DS_AUSP_CW_SRV | 0001 | A | 26.10.2026 |
| ZODP_CT_ZBW_DS_MCH1_SRV_1 | 0001 | A | 26.10.2026 |
| ZODP_CT_ZBW_DS_MSKA_SRV | 0001 | A | 25.10.2026 |
| ZODP_CT_ZBW_DS_SMC_SRV | 0001 | A | 11.08.2025 |
| ZODP_CT_ZBW_DS_TR_SRV | 0001 | A | 26.05.2025 |
| ZODP_EC_PCA_0EC_PCA_1_SRV | 0001 | A | 28.02.2025 |
| ZODP_EC_PCA_0EC_PCA_2_SRV | 0001 | A | 28.02.2025 |
| ZODP_EC_PCA_0EC_PCA_3_SRV | 0001 | A | 28.02.2025 |
| ZODP_EC_PCA_0EC_PCA_4_SRV | 0001 | A | 28.02.2025 |
| ZODP_EC_PCA_0PROFIT_CTR_A_SRV | 0001 | A | 28.02.2025 |
| ZODP_EC_PCA_0PROFIT_CTR_T_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0ACCT_TYPE_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0AC_DOCSTAT_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0AC_DOC_TYP_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0BUS_AREA_ATTR_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0BUS_AREA_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_FI_0CHRT_ACCTS_ATTR_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0CHRT_ACCTS_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_0COMP_CODE_ATTR_SRV | 0001 | A | 11.03.2025 |
| ZODP_FI_0COMP_CODE_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_FI_0FI_AP_4_SRV | 0001 | A | 26.03.2025 |
| ZODP_FI_0FI_AR_4_SRV | 0001 | A | 07.12.2025 |
| ZODP_FI_0FI_GL_10_SRV | 0001 | A | 16.07.2025 |
| ZODP_FI_0FI_GL_14_SRV | 0001 | A | 11.04.2025 |
| ZODP_FI_0GL_ACCOUNT_ATTR_SRL | 0001 | A | 29.07.2025 |
| ZODP_FI_0GL_ACCOUNT_TEXT_SRV | 0001 | A | 28.07.2025 |
| ZODP_FI_0SEGMENT_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_FI_ZBW_DS_LFA1_SRV | 0001 | A | 05.08.2025 |
| ZODP_FI_ZBW_DS_OFFSETACCD_SRV | 0001 | A | 05.08.2025 |
| ZODP_FI_ZBW_DS_OFFSETACC_SRV | 0001 | A | 20.11.2025 |
| ZODP_FI_ZBW_DS_VTADD04T_SRV | 0001 | A | 28.07.2025 |
| ZODP_LO_0CUSTOMER_ATTR_SRV1 | 0001 | A | 26.10.2026 |
| ZODP_LO_0CUSTOMER_TEXT_SRV2 | 0001 | A | 26.10.2026 |
| ZODP_LO_0CUST_COMPC_ATTR_SRV1 | 0001 | A | 28.02.2025 |
| ZODP_LO_0CUST_COMPC_TEXT_SRV2 | 0001 | A | 28.02.2025 |
| ZODP_LO_0CUST_SALES_ATTR_SRV3 | 0001 | A | 28.02.2025 |
| ZODP_LO_0CUST_SALES_TEXT_SRV3 | 0001 | A | 28.02.2025 |
| ZODP_LO_0MATERIAL_ATTR_SRV | 0001 | A | 26.10.2026 |
| ZODP_LO_0MATERIAL_TEXT_SRV | 0001 | A | 26.10.2026 |
| ZODP_LO_0MAT_KONDM_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_LO_0MAT_PLANT_ATTR_SRV2 | 0001 | A | 28.02.2025 |
| ZODP_LO_0MAT_PLANT_TEXT_SRV1 | 0001 | A | 28.02.2025 |
| ZODP_LO_0MAT_ST_LOC_ATTR_SRV1 | 0001 | A | 28.02.2025 |
| ZODP_LO_0MAT_ST_LOC_TEXT_SRV2 | 0001 | A | 28.02.2025 |
| ZODP_LO_0MAT_UNIT_ATTR_SRV | 0001 | A | 28.02.2025 |
| ZODP_LO_0PLANT_ATTR_SRV | 0001 | A | 26.10.2026 |
| ZODP_LO_0PLANT_TEXT_SRV | 0001 | A | 26.10.2026 |
| ZODP_LO_0VEN_ACCNT_GRP_T_SRV | 0001 | A | 28.02.2025 |
| ZODP_LO_0VEN_COMPC_ATTR_SRV | 0001 | A | 28.02.2025 |
| ZODP_LO_0VEN_COMPC_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_LO_0VEN_PURORG_ATTR_SRV | 0001 | A | 28.02.2025 |
| ZODP_LO_0VEN_PURORG_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_MM_0CO_PC_ACT_05_SRV | 0001 | A | 30.05.2025 |
| ZODP_MM_0CO_PC_ACT_06_SRV | 0001 | A | 26.03.2025 |
| ZODP_MM_0MATL_CAT_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_MM_0MATL_GROUP_TEXT_SRR | 0001 | A | 11.03.2025 |
| ZODP_MM_0PURCH_ORG_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_MM_0PUR_GROUP_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_MM_0VENDOR_ATTR_SRV | 0001 | A | 26.10.2026 |
| ZODP_MM_0VENDOR_TEXT_SRV | 0001 | A | 01.06.2025 |
| ZODP_MM_2LIS_02_HDR_SRV | 0001 | A | 12.03.2025 |
| ZODP_MM_2LIS_02_ITM_SRV | 0001 | A | 12.03.2025 |
| ZODP_MM_2LIS_02_SCL_SRV | 0001 | A | 18.03.2025 |
| ZODP_MM_2LIS_03_BF_SRV | 0001 | A | 26.10.2026 |
| ZODP_MM_2LIS_03_UM_SRV | 0001 | A | 26.10.2026 |
| ZODP_MM_ZBW_DS_EKPO_SRV | 0001 | A | 15.06.2026 |
| ZODP_MM_ZBW_DS_MARC_SRV | 0001 | A | 26.10.2026 |
| ZODP_MM_ZBW_DS_MARC_SRV_1 | 0001 | A | 03.04.2025 |
| ZODP_MM_ZBW_DS_MBEWH_SRV | 0001 | A | 14.10.2026 |
| ZODP_MM_ZBW_DS_MBEW_SRV | 0001 | A | 14.10.2026 |
| ZODP_MM_ZBW_DS_RSEG_2024_SRV | 0001 | A | 29.05.2025 |
| ZODP_MM_ZDS_ZIS_RSEG_SRV | 0001 | A | 29.05.2025 |
| ZODP_PP_ZDS_ZIS_MAST_STPO_SRV | 0001 | A | 26.10.2026 |
| ZODP_PP_ZDS_ZIS_P_COMP_SRV | 0001 | A | 21.10.2026 |
| ZODP_PP_ZDS_ZIS_P_MATNR_SRV | 0001 | A | 26.10.2026 |
| ZODP_PP_ZDS_ZIS_P_MATNR_SRV1 | 0001 | A | 19.03.2025 |
| ZODP_SD_0CUST_GROUP_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0CUST_GROUP_TEX_SRV | 0001 | A | 28.02.2025 |
| ZODP_SD_0CUST_GRP1_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0CUST_GRP1_TEX_SRV | 0001 | A | 28.02.2025 |
| ZODP_SD_0CUST_GRP2_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0CUST_GRP3_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0CUST_GRP4_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_SD_0CUST_GRP5_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0DISTR_CHAN_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0DIVISION_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0INCOTERMS_TEXT_SRV | 0001 | A | 28.02.2025 |
| ZODP_SD_0MATL_GRP_1_TEXT_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0MATL_GRP_2_TEXT_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0MATL_GRP_3_TEXT_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0MATL_GRP_4_TEXT_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0MATL_GRP_5_TEXT_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0MATL_TYPE_TEXT_SRV | 0001 | A | 11.03.2025 |
| ZODP_SD_0SALESOFFI_ORG_ATTR_S | 0001 | A | 28.02.2025 |
| ZODP_SD_0SALESORG_ATTR_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0SALESORG_TEXT_SRV | 0001 | A | 20.03.2025 |
| ZODP_SD_0SALESORG_TEXT_SRV1 | 0001 | A | 11.03.2025 |
| ZODP_SD_0SALES_DIST_TEXT_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_0SALES_GRP_TEXT_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_0SALES_OFF_TEXT_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_2LIS_11_VAHDR_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_2LIS_11_VAITM_SRV | 0001 | A | 17.03.2025 |
| ZODP_SD_2LIS_11_VAITM_SRV_1 | 0001 | A | 26.10.2026 |
| ZODP_SD_2LIS_11_VAKON_SRV | 0001 | A | 07.07.2025 |
| ZODP_SD_2LIS_12_VCHDR_SRV | 0001 | A | 10.03.2025 |
| ZODP_SD_2LIS_12_VCITM_SRV | 0001 | A | 10.03.2025 |
| ZODP_SD_2LIS_13_VDHDR_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_2LIS_13_VDITM_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_2LIS_13_VDITM_SRV_1 | 0001 | A | 17.09.2026 |
| ZODP_SD_2LIS_13_VDITM_SRV_2 | 0001 | A | 17.09.2026 |
| ZODP_SD_2LIS_13_VDKON_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_DS_VBAP_TVM5T_SRV_1 | 0001 | A | 24.02.2026 |
| ZODP_SD_T179_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_VBAK_BUYER_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_VBAP_TVM5T_DELTA_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_LIPS_SRV | 0001 | A | 25.10.2026 |
| ZODP_SD_ZBW_DS_MARA_2_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_MARA_SRV_01 | 0001 | A | 02.04.2025 |
| ZODP_SD_ZBW_DS_MARM_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_PA0002_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_SHIPMENT_SRV | 0001 | A | 17.08.2025 |
| ZODP_SD_ZBW_DS_VBAK_BUYER_SRV | 0001 | A | 25.05.2026 |
| ZODP_SD_ZBW_DS_VBAP_NOTE_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_VBAP_SRV | 0001 | A | 26.05.2025 |
| ZODP_SD_ZBW_DS_VBAP_TVM5T_SRV | 0001 | A | 01.06.2025 |
| ZODP_SD_ZBW_DS_VBEP_SRV | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_VBKD_1_SRV_01 | 0001 | A | 26.10.2026 |
| ZODP_SD_ZBW_DS_VBKD_SRV | 0001 | A | 01.04.2025 |
| ZODP_SD_ZBW_SHIPMENTCOST_SRV | 0001 | A | 17.08.2025 |
| ZODP_SD_ZDS_ZIS_T006_SRV | 0001 | A | 13.03.2025 |
| ZODP_ZBW_DS_RSEG_1_SRV | 0001 | A | 26.04.2025 |
| ZODP_ZBW_DS_RSEG_SRV | 0001 | A | 07.05.2025 |

---

## Phụ lục B — 129 OData service Z không có lượt gọi trong Aug–Oct/2026 (SU_ASTATS)

Chỉ là danh sách ứng viên; cần xác nhận với bên dùng trước khi ngừng/xoá. Nhóm: ZODP (101), ZBW (24), ZCDS_TB (4), ZINT (0), khác (0).

- ZBW_CDS_A902_KONP_CDS
- ZBW_CDS_ACT_1_F3_T_CDS
- ZBW_CDS_BSEG_GKONT_CDS
- ZBW_CDS_BSEG_GKONT_HM1_CDS
- ZBW_CDS_BSEG_GKONT_HM2_CDS
- ZBW_CDS_CKMLCR_CDS
- ZBW_CDS_CKMLCR_DQ2_CDS
- ZBW_CDS_CKMLCR_DQ3_CDS
- ZBW_CDS_CKMLCR_DQ4_CDS
- ZBW_CDS_CKMLCR_D_CDS
- ZBW_CDS_CO_PC_ACT_1_CDS
- ZBW_CDS_EKPO_CDS
- ZBW_CDS_FI_AP_04_CDS
- ZBW_CDS_FI_AR_04_CDS
- ZBW_CDS_FI_GL_14_CDS
- ZBW_CDS_FI_GL_14_CHIPHI_CDS
- ZBW_CDS_FI_GL_14_D_2_CDS
- ZBW_CDS_FI_GL_14_D_3_CDS
- ZBW_CDS_FI_GL_14_D_CDS
- ZBW_CDS_RSEG_CDS
- ZBW_CDS_RSEG_D_CDS
- ZBW_CDS_SHIPMENT_COGS_CDS
- ZBW_CDS_SHIPMENT_QUANT_CDS
- ZBW_CDS_SHIPMENT_REVENUE_CDS
- ZCDS_TB_EKPO_NOTRSEG_CDS
- ZCDS_TB_EKPO_TEST_CDS
- ZCDS_TB_MSEG_LH_CDS
- ZCDS_TB_RSEG_CDS
- ZODP_COPC_0CO_PC_01_SRV
- ZODP_COPC_0CO_PC_ACT_10_SRV
- ZODP_COPC_0CO_PC_ACT_1_SRV
- ZODP_COPC_0CO_PC_PCP_20_SRV
- ZODP_COPC_0CO_PC_PCP_30_SRV
- ZODP_CO_OM_0COSTCENTER_TEXT
- ZODP_CT_ZBW_DS_AUSP_CTX_SRV
- ZODP_CT_ZBW_DS_SMC_SRV
- ZODP_CT_ZBW_DS_TR_SRV
- ZODP_EC_PCA_0EC_PCA_1_SRV
- ZODP_EC_PCA_0EC_PCA_2_SRV
- ZODP_EC_PCA_0EC_PCA_3_SRV
- ZODP_EC_PCA_0EC_PCA_4_SRV
- ZODP_EC_PCA_0PROFIT_CTR_A_SRV
- ZODP_EC_PCA_0PROFIT_CTR_T_SRV
- ZODP_FI_0ACCT_TYPE_TEXT_SRV
- ZODP_FI_0AC_DOCSTAT_TEXT_SRV
- ZODP_FI_0AC_DOC_TYP_TEXT_SRV
- ZODP_FI_0BUS_AREA_ATTR_SRV
- ZODP_FI_0BUS_AREA_TEXT_SRV
- ZODP_FI_0CHRT_ACCTS_ATTR_SRV
- ZODP_FI_0CHRT_ACCTS_TEXT_SRV
- ZODP_FI_0COMP_CODE_ATTR_SRV
- ZODP_FI_0COMP_CODE_TEXT_SRV
- ZODP_FI_0FI_AP_4_SRV
- ZODP_FI_0FI_AR_4_SRV
- ZODP_FI_0FI_GL_10_SRV
- ZODP_FI_0FI_GL_14_SRV
- ZODP_FI_0GL_ACCOUNT_ATTR_SRL
- ZODP_FI_0GL_ACCOUNT_TEXT_SRV
- ZODP_FI_0SEGMENT_TEXT_SRV
- ZODP_FI_ZBW_DS_LFA1_SRV
- ZODP_FI_ZBW_DS_OFFSETACCD_SRV
- ZODP_FI_ZBW_DS_OFFSETACC_SRV
- ZODP_FI_ZBW_DS_VTADD04T_SRV
- ZODP_LO_0CUST_COMPC_ATTR_SRV1
- ZODP_LO_0CUST_COMPC_TEXT_SRV2
- ZODP_LO_0CUST_SALES_ATTR_SRV3
- ZODP_LO_0CUST_SALES_TEXT_SRV3
- ZODP_LO_0MAT_KONDM_TEXT_SRV
- ZODP_LO_0MAT_PLANT_ATTR_SRV2
- ZODP_LO_0MAT_PLANT_TEXT_SRV1
- ZODP_LO_0MAT_ST_LOC_ATTR_SRV1
- ZODP_LO_0MAT_ST_LOC_TEXT_SRV2
- ZODP_LO_0MAT_UNIT_ATTR_SRV
- ZODP_LO_0VEN_ACCNT_GRP_T_SRV
- ZODP_LO_0VEN_COMPC_ATTR_SRV
- ZODP_LO_0VEN_COMPC_TEXT_SRV
- ZODP_LO_0VEN_PURORG_ATTR_SRV
- ZODP_LO_0VEN_PURORG_TEXT_SRV
- ZODP_MM_0CO_PC_ACT_05_SRV
- ZODP_MM_0CO_PC_ACT_06_SRV
- ZODP_MM_0MATL_CAT_TEXT_SRV
- ZODP_MM_0MATL_GROUP_TEXT_SRR
- ZODP_MM_0PURCH_ORG_TEXT_SRV
- ZODP_MM_0PUR_GROUP_TEXT_SRV
- ZODP_MM_0VENDOR_TEXT_SRV
- ZODP_MM_2LIS_02_HDR_SRV
- ZODP_MM_2LIS_02_ITM_SRV
- ZODP_MM_2LIS_02_SCL_SRV
- ZODP_MM_ZBW_DS_EKPO_SRV
- ZODP_MM_ZBW_DS_MARC_SRV_1
- ZODP_MM_ZBW_DS_RSEG_2024_SRV
- ZODP_MM_ZDS_ZIS_RSEG_SRV
- ZODP_PP_ZDS_ZIS_P_MATNR_SRV1
- ZODP_SD_0CUST_GROUP_TEXT_SRV
- ZODP_SD_0CUST_GROUP_TEX_SRV
- ZODP_SD_0CUST_GRP1_TEXT_SRV
- ZODP_SD_0CUST_GRP1_TEX_SRV
- ZODP_SD_0CUST_GRP2_TEXT_SRV
- ZODP_SD_0CUST_GRP3_TEXT_SRV
- ZODP_SD_0CUST_GRP4_TEXT_SRV
- ZODP_SD_0CUST_GRP5_TEXT_SRV
- ZODP_SD_0DISTR_CHAN_TEXT_SRV
- ZODP_SD_0DIVISION_TEXT_SRV
- ZODP_SD_0INCOTERMS_TEXT_SRV
- ZODP_SD_0MATL_GRP_1_TEXT_SRV1
- ZODP_SD_0MATL_GRP_2_TEXT_SRV1
- ZODP_SD_0MATL_GRP_3_TEXT_SRV1
- ZODP_SD_0MATL_GRP_4_TEXT_SRV1
- ZODP_SD_0MATL_GRP_5_TEXT_SRV1
- ZODP_SD_0MATL_TYPE_TEXT_SRV
- ZODP_SD_0SALESOFFI_ORG_ATTR_S
- ZODP_SD_0SALESORG_ATTR_SRV1
- ZODP_SD_0SALESORG_TEXT_SRV
- ZODP_SD_0SALESORG_TEXT_SRV1
- ZODP_SD_2LIS_11_VAITM_SRV
- ZODP_SD_2LIS_11_VAKON_SRV
- ZODP_SD_2LIS_12_VCHDR_SRV
- ZODP_SD_2LIS_12_VCITM_SRV
- ZODP_SD_DS_VBAP_TVM5T_SRV_1
- ZODP_SD_ZBW_DS_MARA_SRV_01
- ZODP_SD_ZBW_DS_SHIPMENT_SRV
- ZODP_SD_ZBW_DS_VBAK_BUYER_SRV
- ZODP_SD_ZBW_DS_VBAP_SRV
- ZODP_SD_ZBW_DS_VBAP_TVM5T_SRV
- ZODP_SD_ZBW_DS_VBKD_SRV
- ZODP_SD_ZBW_SHIPMENTCOST_SRV
- ZODP_SD_ZDS_ZIS_T006_SRV
- ZODP_ZBW_DS_RSEG_1_SRV
- ZODP_ZBW_DS_RSEG_SRV

---

## Bổ sung 26/10/2026 — API phục vụ hệ thống Trace (SIMP, trace.minhphu.com)

**Kết luận (suy luận, chưa có log người gọi):** API SAP cấp cho SIMP/Trace nhiều khả năng là SOAP `ZWS_SHIPMENT` (FM `ZSD_FM_SHIPMENT`, package ZCITEKA).

Bằng chứng:
- Response chứa dữ liệu truy xuất nguồn gốc: `Z_CODETRUYXUAT` (mã truy xuất), `Z_NGAYSANXUAT` (ngày sản xuất) lấy từ phân loại batch (MCH1/INOB/AUSP), cùng chứng nhận (`CERTF`, `CERTF_TEXT`), số lượng xuất theo MSEG.
- Node ICF `zws_shipment` tạo 05.06.2019; user `SIMP` tạo 06.06.2019 (lệch 1 ngày).
- User `SIMP`: USTYP A (Dialog), role `Z_1000_2000_SIMP` gồm VT03N, VL03N, VA03, MIGO, MM03, ZMB51, ZSD11 (khớp bảng VTTK/VTTP/LIPS/VBAP/VBKD/MSEG mà FM đọc) và `S_SERVICE` = * (không có `S_RFC`). Đăng nhập cuối 26.10.2026 09:40:01.
- ST03N tháng 10/2026: `ZWS_SHIPMENT` 442 lượt, tổng 68 s, trung bình 154 ms.
- Không có dấu vết SAP gọi ra trace.minhphu.com: `ZTB_INT_PATH` chỉ có 3 dòng eApp, không có RFC destination hay object Z nào tên Trace/SIMP. User `SIMP` không có change document, chứng từ kho, job hay lượt OData (`/IWFND/SU_STATS`) → Trace chủ động gọi vào SAP.

Chưa chứng minh được: người gọi (host/IP). Cách xác nhận: hỏi bên Trace URL đang gọi, hoặc bật ICM access log (`icm/HTTP/logging_0`) / ICF Recorder cho `/sap/bc/srt/rfc/sap/zws_shipment`.

Chi tiết API:
- URL: `https://<host>:<port>/sap/bc/srt/rfc/sap/zws_shipment/800/zsn_shipment/zbn_shipment` (WSDL: thêm `?wsdl`; client 800).
- Input: `TPBEZ` (CHAR20, tên shipment), `TNDR_TRKID` (CHAR35, tracking id). FM lọc `VTTK` theo cả hai tham số.
- Output: `ET_SHIPMENT` (ZST_SHIPMENT_API: TKNUM, TPBEZ, TNDR_TRKID, DATBG, VESSEL_NAME, TEXT2-4, ADD01, EXTI1, SIGNI, EXTI2), `ET_SHIPMENT_DETAIL` (ZST_SHIPMENT_DETAIL_API: TKNUM, TPNUM, VBELN, POSNR, BSTKD, Z_NGAYSANXUAT, ZEINR, ARKTX, MENGE, MEINS, ERFMG, ERFME, GROES, Z_CODETRUYXUAT, BSTKD_E, CERTF, CERTF_TEXT), `ET_SHIPMENT_SUBTOTAL` (Z_CODETRUYXUAT, ARKTX, MEINS, ERFME, MENGE, ERFMG), `E_MSG`/`E_MSGNO`/`E_MSGTY` ('S' = OK, 'E' = "ERROR: No data.").
- Logic: dòng chi tiết có MENGE = 0 và ERFMG = 0 bị loại; số lượng lấy từ MSEG theo giao hàng (bỏ chứng từ đã đảo).
- Lưu ý bảo mật: nếu Trace gọi bằng user `SIMP` thì đang dùng user Dialog cho tích hợp (có thể hết hạn mật khẩu làm gián đoạn API); nên chuyển sang user Service/System.

User kỹ thuật khác phát hiện cùng đợt: `APIOFFICE` (USTYP B, tạo 14.07.2025, đăng nhập cuối 17.10.2026 14:43, không có role, không có trong thống kê OData) chưa gắn được vào service nào.
