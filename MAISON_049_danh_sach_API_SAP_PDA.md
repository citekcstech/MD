# MAISON_049 (PDA scanner React Native) – Danh sách API SAP

Project: `C:\ABAP\PDA\MAISON\MAISON_049` – app React Native (Android) quét barcode kho cho Maison, version `0.4.9`.

## 1. Tổng quan

- **33 API SAP** (SOAP Web Service dạng RFC-enabled FM, SICF path `/sap/bc/srt/rfc/sap/...`), khai báo tập trung trong hàm `MAISON_API_NEWFunc()` – `C:\ABAP\PDA\MAISON\MAISON_049\src\global\appGlobal.js` (dòng 65-310).
- Tên FM/WS đều có tiền tố `ZBM_FM_WS_*` (ngoại lệ: `ZbmFmWsKtnk`, `ZbmFmWsKikeGetsloc` dạng mc-style).
- Gọi qua `appGlobal.WSRequest(url, {functionName, inputJson, success, error}, urn)` – dùng `rn-fetch-blob` (`trusty: true` bỏ qua SSL, timeout 10s, Basic Auth) – `C:\ABAP\PDA\MAISON\MAISON_049\src\global\appGlobal.js` dòng 725. Có thêm bản `WSRequest_Axios` (axios, timeout 30s) – cùng file, dòng 577, chỉ dùng trong test/dev.
- URL: `{host}/sap/bc/srt/rfc/sap/<service>/<client>/<binding>/<binding>`; host/client/user theo "kênh" (`@CHANNEL` = DEV/QAS/PRD) trong `channelConfigDefault` – `C:\ABAP\PDA\MAISON\MAISON_049\src\global\appGlobal.js` dòng 2230.

| Kênh | Host | Client |
|---|---|---|
| DEV | `https://171.244.45.209:50015` | 300 |
| QAS | `https://14.238.104.90:50016` | 900 |
| PRD | `https://171.244.45.209:50017` | 900 |

User kết nối: `MS-BARCODE` (mật khẩu hard-code trong `appGlobal.js`, không chép lại ở đây).

## 2. Danh sách 33 API

Namespace (urn): mặc định `urn:sap-com:document:sap:rfc:functions`; riêng #32, #33 là `urn:sap-com:document:sap:soap:functions:mc-style`.
Cột "Màn hình" chỉ liệt kê file đang nằm trong `Routes.js` (số là dòng gọi `MAISON_API_NEWFunc`).

### Đăng nhập / chung
| # | Key JS | functionName | Service (SICF) | Màn hình / nơi dùng |
|---|---|---|---|---|
| 1 | `getSite` | ZBM_FM_WS_GET_SITE | `zbm_fm_ws_get_site` | LoginScreen:623 |
| 2 | `login` | ZBM_FM_WS_LOGIN | `zbm_fm_ws_login` | `appGlobal.checkLoginData` (appGlobal:1807) – gọi trước khi chuyển SAP ở màn 1, 2, 3, 4 (x3) |
| 3 | `loginNV` | ZBM_FM_WS_LOGIN_NV | `zbm_fm_ws_login_nv` | LoginScreen:481 |

### 1. Nhập kho mua hàng
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 4 | `getPOList` | ZBM_FM_WS_GETPODD | `zbm_fm_ws_getpodd` | 1NhapKho:294, 3PutAway:269, 9XacNhan:293 |
| 5 | `getPOData` | ZBM_FM_WS_GETPO | `zbm_fm_ws_getpo` | 1NhapKho:766, 9XacNhan:503, 6DongGoi:474, 8KiemTra:351 (2 màn sau gọi trong `requestLSXfromWS`) |
| 6 | `getGTIN` | ZBM_FM_WS_GETGTIN | `zbm_fm_ws_getgtin` | 2PullBack:907, 5SoanHang:1277, 6DongGoi:1066, 7KiemKe:722 & 1087, 8KiemTra:569 (ở 1NhapKho:1049 và 9XacNhan:811 đã comment) |
| 7 | `NhapKhoMuaHang` | ZBM_FM_WS_NKMH | `zbm_fm_ws_nkmh` | 1NhapKho:2413, 8KiemTra:1107 |
| 8 | `getQtyData` | ZBM_FM_WS_CHECKQTY_SENT | `zbm_fm_ws_checkqty_sent` | 1NhapKho:376 |
| 9 | `sendQtyTemp` | ZBM_FM_WS_CHECKQTY_RECEIVE | `zbm_fm_ws_checkqty_receive` | 1NhapKho:491 |

### 2. Nhập hàng Pullback
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 10 | `getIDCartonData` | ZBM_FM_WS_GETCARTON | `zbm_fm_ws_getcarton` | 2PullBack:369 |
| 11 | `NhapHangPullBack` | ZBM_FM_WS_NKHT | `zbm_fm_ws_nkht` | 2PullBack:1370 |

### 3. Put Away
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 12 | `getPutAway` | ZBM_FM_WS_GETPUT | `zbm_fm_ws_getput` | 3PutAway:477 |
| 13 | `getBINPutAway` | ZBM_FM_WS_BINPUT | `zbm_fm_ws_binput` | 3PutAway:683 |
| 14 | `ChuyenSAPPutAway` | ZBM_FM_WS_PUTA | `zbm_fm_ws_puta` | 3PutAway:1664 |

### 4. Điều chuyển vị trí (có TO)
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 15 | `getDCVTData` | ZBM_FM_WS_GETDCVT | `zbm_fm_ws_getdcvt` | 4DCVT:471, 4DCVT_KhongTO:418 |
| 16 | `checkBinXuatNhapDCVT` | ZBM_FM_WS_BINDCHVTDI | `zbm_fm_ws_dchvtdi` | 4DCVT:698 |
| 17 | `checkGTINDCVT` | ZBM_FM_WS_GETGTIN_DCVT | `zbm_fm_ws_getgtin_dcvt` | 4DCVT:1284, 4DCVT_KhongTO:1498 |
| 18 | `chuyenSAPDCVT` | ZBM_FM_WS_DCVT | `zbm_fm_ws_dcvt` | 4DCVT:1776 |

### 4b. Điều chuyển vị trí không TO / trực tiếp
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 19 | `checkBINDCVT_KHONGTO` | ZBM_FM_WS_BINDCHVTDI_NOTO | `zbm_fm_ws_bindchvtdi_noto` | 4DCVT_KhongTO:620, 4DCVT_TrucTiep:478 |
| 20 | `chuyenSAPDCVT_KHONGTO` | ZBM_FM_WS_DCVT_NOTO | `zbm_fm_ws_dcvt_noto` | 4DCVT_KhongTO:2024, 4DCVT_TrucTiep:1921 |

### 5. Soạn hàng
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 21 | `getListSoanHang` | ZBM_FM_WS_GETSOHADD | `zbm_fm_ws_getsohadd` | 5SoanHang:372 |
| 22 | `getSoanHangData` | ZBM_FM_WS_GETSOHA | `zbm_fm_ws_getsoha` | 5SoanHang:614 |
| 23 | `getBinSoanHang` | ZBM_FM_WS_BINSOHA | `zbm_fm_ws_binsoha` | 5SoanHang:873 |
| 24 | `ChuyenSAPSoanHang` | ZBM_FM_WS_SOHA | `zbm_fm_ws_soha` | 5SoanHang:1964 |

### 6. Đóng gói
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 25 | `getDongGoiData` | ZBM_FM_WS_GETDOGO | `zbm_fm_ws_getdogo` | 6DongGoi:484 |
| 26 | `ChuyenSAPDongGoi` | ZBM_FM_WS_DOGO | `zbm_fm_ws_dogo` | 6DongGoi:1659 |

### 7. Kiểm kê
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 27 | `getBBKKData` | ZBM_FM_WS_GETKIKE | `zbm_fm_ws_getkike` | 7KiemKe:388 |
| 28 | `checkBINKiemKe` | ZBM_FM_WS_BINKIKE | `zbm_fm_ws_binkike` | 7KiemKe:634 |
| 29 | `ChuyenSAPKiemKe` | ZBM_FM_WS_KIKE | `zbm_fm_ws_kike` | 7KiemKe:1664 |
| 33 | `getSlocKiemKe` | ZbmFmWsKikeGetsloc | `zbm_ws_kike_getsloc` (binding `kike_getsloc`) | 7KiemKe:1818 |
| 31 | `getAllMaterial` | ZBM_FM_WS_GETMATK | `zbm_fm_ws_getmatk` | 7KiemKe:1989 |

### 8. Tồn kho vị trí / 9. Xác nhận kiểm đếm
| # | Key JS | functionName | Service (SICF) | Màn hình |
|---|---|---|---|---|
| 30 | `getTonKhoViTri` | ZBM_FM_WS_GETKTTT | `zbm_fm_ws_getkttt` | 3PutAway:1377, 8KiemTra:820 |
| 32 | `XacNhanKiemDem` | ZbmFmWsKtnk | `zbm_fm_ws_ktnk` | 9XacNhan:1956 |

## 2b. Tóm tắt API logon (3 API: #1, #2, #3)

Luồng đăng nhập ở `C:\ABAP\PDA\MAISON\MAISON_049\src\screens\LoginScreen.js`:

1. **`getSite` – ZBM_FM_WS_GET_SITE** (`_getSiteWS`, LoginScreen:606): user nhập IDNV + PASS → gọi để lấy danh sách site (plant) cho user chọn.
   - Input: `IS_INPUT { IDNV, PASS }`
   - Output: `EW_RESULT` (`'1'` = OK), `EW_MSG`, `ES_OUTPUT.item[]` (map `Key`/`Name` → `siteList`).
2. **`loginNV` – ZBM_FM_WS_LOGIN_NV** (`_dangNhapPress`, LoginScreen:459): sau khi chọn site → xác thực nhân viên.
   - Input: `IS_INPUT { IDNV, PASS, SITE }`
   - Output: `EW_RESULT` (`'1'` = OK → `_loginStep2()` lưu userObj), `EW_MSG` (hiện Alert khi lỗi).
   - Có shortcut DEV/PRD: gõ `1.`/`2.`/`3.`/`4.` ở ô username sẽ tự thay bằng user test hard-code (LoginScreen:495-512).
3. **`login` – ZBM_FM_WS_LOGIN** (`appGlobal.checkLoginData`, appGlobal:1804): **không phải đăng nhập nhân viên**, chỉ là health-check kết nối/user kỹ thuật `MS-BARCODE`; gọi trước mỗi lần "Chuyển SAP" ở màn 1, 2, 3, 4. Không có input; kết quả `E_CODE === 'X'` là hợp lệ. (`LoginScreen_bk.js:379` là bản cũ.)

Lưu ý: ở `loginNV`/`getSite` nếu server trả HTTP 500 thì code hiện chỉ tắt loading (không báo lỗi, không đăng nhập) – comment cũ ghi "lỗi 500 tức là đã đăng nhập được".

## 3. Điểm cần lưu ý

1. **Không khớp tên service ↔ functionName**: `checkBinXuatNhapDCVT` có functionName `ZBM_FM_WS_BINDCHVTDI` nhưng service path là `zbm_fm_ws_dchvtdi` (thiếu `bin`). Khi tạo/đối chiếu service trong SOAMANAGER cần dùng đúng path này.
2. **Binding không đồng nhất**: `login` dùng `/zbm/zsn`; đa số API dùng `/zsn/zbm`; `getQtyData`, `sendQtyTemp`, `XacNhanKiemDem`, `getSlocKiemKe` dùng binding trùng tên service (và 2 cái cuối dùng urn mc-style).
3. **`checkGTIN` không tồn tại** trong `MAISON_API_NEWFunc` nhưng vẫn bị destructure ở các file không nằm trong Routes: `3PutAwayScreen copy.js:712`, `4DieuChuyenViTriScreen_v1.js:726,989`, `6DongGoiScreen_bk:703` → là code backup/cũ (sẽ là `undefined` nếu chạy).
4. **Bảo mật**: `appGlobal.js` chứa user/password SAP (`MS-BARCODE`) và IP public dạng plaintext; `trusty: true` tắt kiểm tra SSL. Nên chuyển sang cấu hình ngoài/secret nếu phát hành rộng.
5. API `getPOList`/`getPOData` còn được dùng ở màn 3PutAway & 9XacNhan, không chỉ màn Nhập kho mua hàng.

## 4. HTTP không phải SAP SOAP (để tham khảo)

| Endpoint | Vị trí | Ghi chú |
|---|---|---|
| `{myDomain}/Auth/GetAppConfigByKey` | appGlobal.js:1285 | Backend riêng (REST JSON), `myDomain` mặc định `debugDomain = http://192.168.5.187:3000` – di sản từ bản CADIVI |
| `{myDomain}/Auth/CheckLoginDevice` | appGlobal.js:1321 | Như trên |
| `http://solarplusapi.tk/Solar/MaisonError?error=...` | 9XacNhanKiemDemScreen.js:1939 | Gửi log lỗi ra dịch vụ ngoài (không phải SAP) |

## 5. API test/dev (không nằm trong app chạy chính)

`TestPDAScannerScreen.js` và `DevScraffoldScreen.Axios.js` (không có trong `Routes.js`) còn trỏ tới các service cũ: `zbm_ws_login`, `zbm_ws_nksx`, `zbm_ws_get_prod_order`, `zbm_ws_check_batch` (mc-style, host `171.244.45.165`) và `zbm_fm_ws_login` trên `101.99.29.102:50015` – di sản/test, không dùng trong luồng chính.

## 6. Cách tìm lại

- Danh sách: `grep -n "functionName:" src/global/appGlobal.js`
- Nơi gọi: `grep -rn "MAISON_API_NEWFunc" src/screens/*.js`

## 7. URL đầy đủ – kênh DEV, client 300

Host DEV mặc định: `https://171.244.45.209:50015` (`channelConfigDefault.hostDEV`, `clientDEV = 300`) trong `C:\ABAP\PDA\MAISON\MAISON_049\src\globalppGlobal.js` dòng 2250-2255. Sinh tự động từ `MAISON_API_NEWFunc()`.

- App gọi POST SOAP, thêm `?v=<timestamp>` vào cuối URL (chống cache), Basic Auth theo `user/passDEV` trong cấu hình kênh.
- Host/client thực tế có thể bị đổi bởi `@CHANNELCONFIG` lưu trên máy PDA (màn Cập nhật kênh) nên khác mặc định.
- WSDL: thêm `?sap-client=300` và dùng đường `/sap/bc/srt/wsdl/.../bndg_url/<path>` (xem comment appGlobal.js:102).

| # | Key JS | functionName | URL (DEV, client 300) |
|---|---|---|---|
| 1 | `getSite` | ZBM_FM_WS_GET_SITE | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_get_site/300/zsn/zbm` |
| 2 | `login` | ZBM_FM_WS_LOGIN | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_login/300/zbm/zsn` |
| 3 | `loginNV` | ZBM_FM_WS_LOGIN_NV | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_login_nv/300/zsn/zbm` |
| 4 | `getPOList` | ZBM_FM_WS_GETPODD | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getpodd/300/zsn/zbm` |
| 5 | `getPOData` | ZBM_FM_WS_GETPO | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getpo/300/zsn/zbm` |
| 6 | `getGTIN` | ZBM_FM_WS_GETGTIN | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getgtin/300/zsn/zbm` |
| 7 | `NhapKhoMuaHang` | ZBM_FM_WS_NKMH | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_nkmh/300/zsn/zbm` |
| 8 | `getQtyData` | ZBM_FM_WS_CHECKQTY_SENT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_checkqty_sent/300/zbm_fm_ws_checkqty_sent/zbm_fm_ws_checkqty_sent` |
| 9 | `sendQtyTemp` | ZBM_FM_WS_CHECKQTY_RECEIVE | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_checkqty_receive/300/zbm_fm_ws_checkqty_receive/zbm_fm_ws_checkqty_receive` |
| 10 | `getIDCartonData` | ZBM_FM_WS_GETCARTON | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getcarton/300/zsn/zbm` |
| 11 | `NhapHangPullBack` | ZBM_FM_WS_NKHT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_nkht/300/zsn/zbm` |
| 12 | `getPutAway` | ZBM_FM_WS_GETPUT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getput/300/zsn/zbm` |
| 13 | `getBINPutAway` | ZBM_FM_WS_BINPUT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_binput/300/zsn/zbm` |
| 14 | `ChuyenSAPPutAway` | ZBM_FM_WS_PUTA | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_puta/300/zsn/zbm` |
| 15 | `getDCVTData` | ZBM_FM_WS_GETDCVT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getdcvt/300/zsn/zbm` |
| 16 | `checkBinXuatNhapDCVT` | ZBM_FM_WS_BINDCHVTDI | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_dchvtdi/300/zsn/zbm` |
| 17 | `checkGTINDCVT` | ZBM_FM_WS_GETGTIN_DCVT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getgtin_dcvt/300/zsn/zbm` |
| 18 | `chuyenSAPDCVT` | ZBM_FM_WS_DCVT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_dcvt/300/zsn/zbm` |
| 19 | `checkBINDCVT_KHONGTO` | ZBM_FM_WS_BINDCHVTDI_NOTO | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_bindchvtdi_noto/300/zsn/zbm` |
| 20 | `chuyenSAPDCVT_KHONGTO` | ZBM_FM_WS_DCVT_NOTO | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_dcvt_noto/300/zsn/zbm` |
| 21 | `getListSoanHang` | ZBM_FM_WS_GETSOHADD | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getsohadd/300/zsn/zbm` |
| 22 | `getSoanHangData` | ZBM_FM_WS_GETSOHA | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getsoha/300/zsn/zbm` |
| 23 | `getBinSoanHang` | ZBM_FM_WS_BINSOHA | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_binsoha/300/zsn/zbm` |
| 24 | `ChuyenSAPSoanHang` | ZBM_FM_WS_SOHA | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_soha/300/zsn/zbm` |
| 25 | `getDongGoiData` | ZBM_FM_WS_GETDOGO | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getdogo/300/zsn/zbm` |
| 26 | `ChuyenSAPDongGoi` | ZBM_FM_WS_DOGO | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_dogo/300/zsn/zbm` |
| 27 | `getBBKKData` | ZBM_FM_WS_GETKIKE | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getkike/300/zsn/zbm` |
| 28 | `checkBINKiemKe` | ZBM_FM_WS_BINKIKE | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_binkike/300/zsn/zbm` |
| 29 | `ChuyenSAPKiemKe` | ZBM_FM_WS_KIKE | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_kike/300/zsn/zbm` |
| 30 | `getTonKhoViTri` | ZBM_FM_WS_GETKTTT | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getkttt/300/zsn/zbm` |
| 31 | `getAllMaterial` | ZBM_FM_WS_GETMATK | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_getmatk/300/zsn/zbm` |
| 32 | `XacNhanKiemDem` | ZbmFmWsKtnk | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_fm_ws_ktnk/300/zbm_fm_ws_ktnk/zbm_fm_ws_ktnk` |
| 33 | `getSlocKiemKe` | ZbmFmWsKikeGetsloc | `https://171.244.45.209:50015/sap/bc/srt/rfc/sap/zbm_ws_kike_getsloc/300/zbm_ws_kike_getsloc/kike_getsloc` |
