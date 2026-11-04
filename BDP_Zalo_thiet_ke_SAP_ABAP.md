# BDP Zalo — tóm tắt thiết kế file source ABAP (03.11.2026)

Thiết kế đầy đủ và khung code: `C:\Users\sang.vu\Documents\GitHub\VSCodeSkillAI\CodeABAP\BDP_Zalo\SAP_ABAP\` (`THIET_KE_SAP_ABAP_ZALO.md`, thư mục `src/`). **Đã tạo và activate 26 object trên DEV100, TR `DEVK901153`** (03.11.2026), danh sách và việc làm tay còn lại ở mục 12 của tài liệu thiết kế. `ZTB_ZALO_LOG` không sửa (nằm trong TR DEVK900335 của người khác).

## Phạm vi
Luồng ZL.01–ZL.10 giữa SAP S/4HANA và Zalo Mini App (GMO): 8 luồng SAP→ZMA (khách hàng, hoá đơn + huỷ/điều chỉnh, tổng công nợ, công nợ theo hoá đơn, lịch sử thanh toán, nhân viên giao hàng, OD đã PGI, Freight Order) và 1 luồng ZMA→SAP (xác nhận giao hàng POD). ZL.11 (truy vấn chương trình tích luỹ) chỉ làm FS ở giai đoạn này, chưa có API. Nguồn chuẩn: FS v1.1 + ZMA v2.1 (không dùng FS ECC cũ, blueprint, biên bản trao đổi).

## Hiện trạng DEV100 (đã kiểm)
- Có sẵn nhưng rỗng/chưa hoàn chỉnh: `ZTB_ZALO_LOG`, `ZTB_ZALO_PARAM`, `ZFM_ZALO_BILLING` (gọi từ ZEIV01, `BUILD_JSON` rỗng), `ZFM_DMS_BILLING` stub. `ZCL_REST_CONSUMER` không đọc được HTTP status/Bearer nên không dùng.
- Chưa có: `ZTB_ZALO_OBJECT/NVGH/POD`, Tcode ZZALO, number range `ZZL_OBJID`.
- Field FS dùng tên `ZZ_*` không có trên DEV; tên thật (user cung cấp, đã đối chiếu DD03L): BP `ZZ1_*_CUS` (KNA1), `LIKP-ZZ1_DIACHIGH_DLH`/`ZZ1_GHICHU_DLH`, `LIPS-ZZ1_GHICHU_ITEM_DLI`, GPP/GDP từ `BUT0ID` loại `Z00007`. `Z004`/`Z005` (CMND chủ/đại diện) không có trong `TB039A`.
- Có TM nhúng (`/SCMTMS/D_TOR*`), `ACDOCA`, `PRCD_ELEMENTS`.

## Kiến trúc
Một interface `ZIF_ZALO_OBJECT` + lớp cơ sở `ZCL_ZALO_OBJECT_BASE` (kiểm bật/tắt → dựng request → gửi tuần tự → ghi log → COMMIT), mỗi luồng 1 class con; lõi dùng chung `ZCL_ZALO_CONFIG/HTTP/LOG/UTIL`; realtime qua FM RFC `ZFM_ZALO_SEND_RT` (tRFC); inbound qua ICF handler `ZCL_ZALO_ICF_HANDLER`; Tcode ZZALO ↔ `ZSD_PG_ZALO` (dialog + job nền). Bảng mới: `ZTB_ZALO_STATE` (trạng thái + hash payload để biết "đã gửi nhưng có thay đổi"), `ZTB_ZALO_LOGJ` (JSON theo request), thêm `REQUEST_ID` vào `ZTB_ZALO_LOG`.

## Quyết định đã chốt (user, 03.11.2026)
`billing_type` gửi `INV_CAT` 1/2; `payment_method_name` gửi tên (`T003T-LTEXT`); ZL.10 dùng `DTABF`, response `S`/`E`; bỏ luồng "gửi lại hoá đơn sau POD"; ZL.11 chỉ FS; ZL.10 nhận tại `https://dev.sap.bidiphar.com/sap/zalo/<client>/deliveryconfirm`, không xác thực (user cố định đặt ở node SICF); số giấy tờ định danh chủ nhà thuốc/người đại diện là `BUT0ID` loại `Z00003`/`Z00004`; field giao hàng `LIKP-ZZ1_DIACHIGH_DLH`, `LIKP-ZZ1_GHICHU_DLH`, `LIPS-ZZ1_GHICHU_ITEM_DLI`; số đăng ký `MARA-ZZ1_SDK_PRD`; `biz_status` = `KNA1-ZZ1_TT_KINHDOANH_CUS`.

## Đang theo ZMA, chưa có phản hồi
Công nợ gói 1.000 thay vì 20.000, `tax_rate`/`discount_percent` dạng chuỗi, 3 trường hợp huỷ OD, phone NVGH dạng chuỗi, FS cuối cùng cần duyệt. Bảng đầy đủ: mục 7b của tài liệu thiết kế. Không còn câu hỏi nào về tên field; bước tiếp theo là user đồng ý tạo object trên DEV (TR + package).

## Rủi ro đáng chú ý
Số tiền VND lệch ×100 khi đọc thẳng từ DB (`TCURX-CURRDEC` của VND = 0, đã kiểm DEV100) — xử lý bằng FM chuẩn `FIWT_CONVERT_AMOUNT_TO_DISPLAY` / `FIWT_CONVERT_AMOUNT_TO_SAP` (bọc trong `ZCL_ZALO_UTIL`), convert từng dòng rồi cộng bằng `decfloat34` vì FM trả `DMBTR` (tối đa ≈ 100 tỷ VND), phải đối chiếu hoá đơn thật; hook realtime cho thanh toán (ZL.06) và BP (ZL.07) chưa chọn điểm chèn; API cập nhật POD (VLPOD) và sự kiện Freight Unit chưa chốt; token ZMA nằm plain-text trong tài liệu GMO và trong cột `TOKEN` của `ZTB_ZALO_PARAM`.

## Trạng thái file
Hoàn chỉnh (chưa chạy): 6 bảng DDIC, `ZCX_ZALO`, `ZIF_ZALO_OBJECT`, `ZIF_ZALO_TYPES`, `ZCL_ZALO_CONFIG/HTTP/LOG/UTIL/OBJECT_BASE/FACTORY`, `ZCL_ZALO_ICF_HANDLER`, `ZFM_ZALO_SEND_RT`. Khung (chọn dữ liệu + dựng JSON chưa viết): 8 class luồng, `ZCL_ZALO_POD_API`, `ZSD_PG_ZALO` (chưa có ALV master-detail). Đã bỏ `ZCL_ZALO_PROMO_API` (ZL.11 ngoài phạm vi giai đoạn này).
