# MAISON_049 – Màn hình "8. Kiểm tra thông tin hàng hóa" gọi SAP qua API nào

- Menu: `src/screens/HomeScreen.js:168` → route `KiemTraThongTinScreen`
- Màn hình: `src/screens/8KiemTraThongTinScreen.js`
- Định nghĩa endpoint: `MAISON_API_NEWFunc()` trong `src/global/appGlobal.js:65`

Cả hai gọi qua `appGlobal.WSRequest(...)` (SOAP RFC-enabled FM, URN `urn:sap-com:document:sap:rfc:functions`).

| # | Thao tác trên màn hình | Key API | Function Module (SAP) | URL (sau `${WS_URL}`) | Hàm trong screen |
|---|---|---|---|---|---|
| 1 | Quét barcode GTIN (có thể dạng `GTIN-BATCH`) | `getGTIN` | `ZBM_FM_WS_GETGTIN` | `/sap/bc/srt/rfc/sap/zbm_fm_ws_getgtin/${WS_PORT}/zsn/zbm` | `_scanItem` (dòng 541) |
| 2 | Bấm nút "Tồn kho vị trí" | `getTonKhoViTri` | `ZBM_FM_WS_GETKTTT` | `/sap/bc/srt/rfc/sap/zbm_fm_ws_getkttt/${WS_PORT}/zsn/zbm` | `_onTonKhoViTriPress` (dòng 805) |

## Input
- `getGTIN`: `IS_INPUT { TU: UserName, C3: gtin, SITE: headerInput.site, TB: headerInput.site }`
- `getTonKhoViTri`: `IS_INPUT { C3: GTIN, SITE: headerInput.site, TB: headerInput.site, L1: BATCH }`

## Output
- Cả hai đọc `EW_RESULT` (`1` = OK), `EW_MSG` (thông báo lỗi), `ES_OUTPUT.item` (dữ liệu).
- `getGTIN` → điền các ô GTIN / Article / Batch / Style / Color / Size / Sản phẩm.
- `getTonKhoViTri` → bảng danh sách (Vị trí, SL tồn, Batch, Barcode, Storage Type, Article, Style, Size, Color), sắp theo Storage Type + SL, có dòng tổng theo Storage Type.

## GTIN quét được → tag C3 có xóa số 0 đầu không?
**Không.** Giá trị đi thẳng vào `C3` (và `L1` ở `getTonKhoViTri` lấy từ `cuonItem.GTIN` do SAP trả về), không có bước xóa số 0.

Luồng: `scanner → _xuLyThongTinQRDaScan` (chỉ `barcode.trim()`) `→ _scanItem` (`gtin = barcode`; nếu có `-` thì tách `GTIN-BATCH`) `→ C3: gtin → convert.js2xml` (giữ nguyên chuỗi).

| Nguồn quét | Xử lý trước khi vào C3 |
|---|---|
| Máy quét HW (`myScannerHWEvent`) | chỉ `replace(/\n/g, '')` |
| Zebra scanner | giữ nguyên chuỗi |
| Camera (`onBarCodeRead`) | `appGlobal.formatBarcodeInput`: nếu type là `EAN_13` thì **cắt bỏ ký tự đầu tiên** (`substring(1)`, không kiểm tra có phải số 0) |

- `removeAllLeftZero` (`appGlobal.js:2226`) tồn tại nhưng screen 8 không dùng; chỉ `5SoanHangScreen.js:1729` dùng, và áp lên `article`, không phải GTIN.
- Lưu ý: quét bằng camera mà barcode là EAN-13 thì mất 1 ký tự đầu (thường là số 0 do thư viện camera báo EAN-13 thay cho UPC-A 12 số). Quét bằng máy PDA thì giữ nguyên.
- Không kiểm tra được phần native Android của máy quét HW (event `myScannerHWEvent`) có tự cắt số 0 hay không.

## Ghi chú
- `WS_URL` / `WS_PORT` lấy từ `@CHANNELCONFIG` + `@CHANNEL` trong local storage (không hard-code).
- `requestLSXfromWS` (dòng 345, `getPOData`) trong file này đang dùng mockup + `return` sớm, và chỉ được gọi từ `_onMoChiTietPress` → không dùng thực tế cho màn hình 8.
- `_goiChuyenSAP` (`NhapKhoMuaHang`) cũng đã `return` sớm, không gọi SAP thật.
