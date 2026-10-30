# VAS PDA ↔ Sales Portal: Phiếu đăng ký (bản 2.2.7)

Nguồn: `FS/VAS_Tích hợp PDA_SP.xlsx` (3 sheet + wireframe) và tài liệu API `Document/VASG_FS_INTEGRATION_SAP_V1.4.docx` (mục 2.13–2.16, 21/10/2026). Repo: `VAS_PDA_2_2_5`.
Version: **2.2.6 → 2.2.7**, versionCode **226 → 227**, ngày **30/10/2026** (`app/build.gradle`, `activity_main.xml`).
Môi trường: **Dev / QAS / PRD** (tài liệu API ghi QAS là "UAT").

## 1. Quyết định đã chốt

1. PDA hiển thị **4 tab theo FS/wireframe** (Dự kiến vào nhà máy, Chưa vào cổng, Chờ cân đầu vào, Chờ ra cổng), luôn đủ 4 tab, số phiếu từng tab tính từ dữ liệu Portal trả về (xem mục 2.1). *(30/10/2026: đổi từ "3 tab như Portal" vì Portal v1.4 chỉ có 3 cột và dữ liệu thay đổi theo ngày.)*
2. **Tài khoản gọi Portal lấy từ SAP**: bảng Z + API REST trên SAP; PDA gọi bằng user SAP đã đăng nhập.
3. **Danh sách địa điểm (mã + tên) lấy từ SAP**: bảng Z + API REST trên SAP.
4. Nút "Xác nhận hoàn thành" **bật/tắt theo `canCompleteExport`** (1 = bật).

## 2. Luồng PDA

```
PDA --GET SAP_SP_ACCOUNT (Basic: user SAP)--> SAP  => {username,password}
PDA --POST SP_TOKEN_URL--> Portal                  => access_token (3600s, lưu đến gần hết hạn; 401 thì đăng nhập lại 1 lần)
PDA --POST SP_PDK_GET     (Bearer, {qrCode})-->                Quét QR -> thông tin phiếu
PDA --GET  SAP_SP_LOCATION--> SAP                              Danh sách địa điểm (mã + tên)
PDA --POST SP_PDK_LIST    (Bearer, {receivingLocation=mã, receivingDate=yyyy-MM-dd, registrationNo?})
PDA --POST SP_PDK_STATUS  (Bearer, {registrationNo})-->        Xác nhận hoàn thành xuất hàng
```

| Màn hình | File |
|---|---|
| Xuất kho bán hàng → quét QR / nhập tay | `XKBH_QuetPDK` |
| Phiếu đăng ký (header + DS SO) | `XKBH_PhieuDangKy` |
| Xuất kho bán hàng từ SO đã chọn | `XuatKhoBanHangPDK` (kế thừa `XuatKhoBanHang`, không sửa file gốc) |
| Option 9: Danh sách phiếu đăng ký (4 tab) | `DanhSachPhieuDK` |
| Chi tiết phiếu + xác nhận hoàn thành | `ChiTietPhieuDK` |
| API Portal + SAP, token | `Controller/SalesPortalApi.java` |

Cách đọc dữ liệu theo API v1.4:
- **Quét QR (`pda/resolve`)**: chỉ gửi `qrCode` (vd `AHT00000032|aaa48`); `items[]` phẳng được gom theo `soCode`; SO hoàn thành khi mọi dòng của SO có `completionStatus = X`; ngày ISO đổi sang `dd/MM/yyyy`. Lỗi hiển thị đúng `message` của Portal.
- **Danh sách (`pda/registrations/search`)**: `data` có các cột `waiting` (Chờ nhận hàng) / `inService` (Đang nhận hàng) / `received` (Đã nhận hàng); thẻ phiếu hiện số phiếu, ngày, khách hàng, nhóm hàng (gộp từ `productItems[].productGroup`) | khối lượng, trạng thái = `registrationStatusName`.
- **Xác nhận hoàn thành (`sap/export-status`)**: gửi `{registrationNo}`, hiển thị `message` khi lỗi (vd "chưa nhận đủ dữ liệu thực xuất…").

### 2.1. Chia phiếu vào 4 tab (`SalesPortalApi.PhanTab` / `TabCuaPhieu`)

Portal chỉ có 3 cột nhưng FS có 4 tab, nên PDA tự chia từng phiếu vào tab. Dữ liệu thật của Portal Dev (địa điểm Z7, tháng 10/2026) cho thấy các trạng thái nằm trong từng cột:

| Cột Portal | Mã trạng thái | Tên trạng thái (`registrationStatusName`) |
|---|---|---|
| `waiting` Chờ nhận hàng | XEPTAI | Chưa vào cổng; Đã xếp tài |
| `inService` Đang nhận hàng | VAOKHO; DAGIAO | Đang nhận hàng; Đã giao hàng |
| `received` Đã nhận hàng | NHANHANG; CANRA; DAGIAO; CHECKOUT | Chờ cân đầu ra; Chờ ra cổng; Đã giao hàng; Đã ra cổng |

`XEPTAI` dùng cho cả "Chưa vào cổng" và "Đã xếp tài" nên PDA phân biệt theo **tên** trạng thái, không theo mã.

Quy tắc xếp tab (kiểm tra theo thứ tự, so khớp tên không dấu, không phân biệt hoa thường):

| Điều kiện | Tab |
|---|---|
| Tên chứa "Chưa vào cổng" | Chưa vào cổng |
| Tên chứa "Chờ cân đầu vào" | Chờ cân đầu vào |
| Tên chứa "Chờ ra cổng" hoặc "Chờ cân đầu ra" | Chờ ra cổng |
| Tên chứa "Dự kiến", "Xe đã đến", "xếp tài" | Dự kiến vào nhà máy |
| Còn lại (Đang nhận hàng, Đã giao hàng, Đã ra cổng...) theo cột Portal: `waiting` / `inService` / `received` | Dự kiến vào nhà máy / Chờ cân đầu vào / Chờ ra cổng |
| Cột Portal có khóa lạ: theo vị trí cột | cột đầu → Dự kiến vào nhà máy, cột cuối → Chờ ra cổng, cột giữa → Chờ cân đầu vào |

Tính linh động: tab nào Portal không trả phiếu thì hiện **0** và "Không có phiếu"; Portal thiếu cột hoặc đổi sang 4 cột vẫn chia được; **không phiếu nào bị ẩn** (tổng 4 tab luôn bằng tổng phiếu Portal trả). Tên trạng thái thật của từng phiếu vẫn hiện trên dòng phiếu.

**Cần xác nhận với FS/Portal**: FS không nêu rõ trạng thái nào thuộc tab nào. Các trạng thái "Đang nhận hàng", "Đã giao hàng", "Đã ra cổng" hiện xếp theo cột Portal (không có tab riêng trong FS). Nếu cần khác, chỉ sửa 1 hàm `TabCuaPhieu`.

## 3. Cấu hình thiết bị (đã thêm vào `Document/Storage Card/XMLConfig/`)

Đã thêm 6 key vào `LinkWebservice.xml`, `_DEV.xml`, `_QAS.xml`, `_PRD.xml` để copy vào thiết bị (XML đã kiểm tra hợp lệ):

| Key | Dev | QAS | PRD |
|---|---|---|---|
| `SP_TOKEN_URL` | `https://vasg-salesportal-dev.isystem.vn/app/integration/api/auth/token` | `https://vasg-integration-uat.isystem.vn/api/auth/token` | **chưa có** (chú thích) |
| `SP_PDK_GET` | `.../logistics-api/api/v1/integration/delivery-registration/pda/resolve` | **chưa có** | **chưa có** |
| `SP_PDK_LIST` | `.../pda/registrations/search` | **chưa có** | **chưa có** |
| `SP_PDK_STATUS` | `.../sap/export-status` | **chưa có** | **chưa có** |
| `SAP_SP_ACCOUNT` / `SAP_SP_LOCATION` | `http://192.168.100.75:8001/sap/bc/zbm_pda_sp?sap-client=300&type=ACCOUNT` / `LOCATION` | `http://nisqas.nis.vn:8002/...sap-client=600...` | `http://192.168.100.73:8003/...sap-client=800...` |

Các URL Dev gọi thử không kèm token đều có phản hồi (logistics 401, token 400). Host/client SAP lấy từ các link `zbm_ws_*` sẵn có trong từng file.

## 4. Thiết kế + triển khai phía SAP (NDE, đã tạo một phần ngày 30/10/2026)

Thư mục `CodeABAP/VAS/SD_PDA_SP/` trong repo:
- `TS/VAS_TS_ApiCauHinhSalesPortalChoPDA_SDPDA01_V1.0.md` — TS chuẩn 9 mục để gửi khách (chưa xuất .docx vì thiếu tên công ty khách + logo header).
- `THIET_KE_SD_PDA_SP.md` — object list, luồng, 10 quyết định kỹ thuật, bảo mật mật khẩu, phương án "SAP làm token broker", 9 giả định mở.
- `HUONG_DAN_TAO_SD_PDA_SP.md` — thứ tự tạo object, code mẫu class handler + form TMG, 17 test case, cấu hình PDA theo môi trường, checklist transport.

Hợp đồng API SAP: `GET /sap/bc/zbm_pda_sp?sap-client=<mandt>&type=ACCOUNT|LOCATION`, Basic auth; body `{isSuccess, message, data}`; lỗi HTTP 400/403/404/500 kèm `message` tiếng Việt, 401 do ICF trả khi sai user/mật khẩu.

Object: bảng `ZBM_SP_ACCOUNT`, `ZBM_SP_LOCATION`; data element `ZBM_SP_*`; function group TMG `ZBM_SP_TMG`; authorization object `ZBM_PDA_SP` (class `ZBM`); message class `ZMC_PDA_SP`; class `ZBM_CL_PDA_SP_HTTP`; node SICF `/sap/bc/zbm_pda_sp`; role `ZBM_PDA_SP_USER` / `ZBM_PDA_SP_ADMIN`.
Điểm khác đề xuất ban đầu: username 50 ký tự, password 100; bảng tài khoản delivery class `A` và không ghi nhận transport (mật khẩu không đi vào request); mỗi mandt đúng 1 tài khoản ACTIVE (>1 thì API trả 500).

**Đã tạo trên hệ NDE (client 100, package ZBC, transport NDEK912178)** bằng MCP `GUI_VAS_100` (sau khi anh cho phép):
- Active: 4 domain (`ZBM_SP_USERNAME/PASSWORD/LOCNAME/SORT`, thêm so với thiết kế vì tool không đặt được kiểu định sẵn khác CHAR 10), 6 data element `ZBM_SP_*`, bảng `ZBM_SP_ACCOUNT` (delivery class A) và `ZBM_SP_LOCATION` (C).
- Class `ZBM_CL_PDA_SP_HTTP`: đã ghi nguồn đầy đủ (`CodeABAP/VAS/SD_PDA_SP/src/zbm_cl_pda_sp_http.clas.abap`) nhưng **chưa active**: tool báo activate OK mà class vẫn nằm trong DWINACTIV và không trả được lỗi biên dịch → anh mở trong ADT/SE24 và kích hoạt (Ctrl+F3).
- Chưa tạo vì MCP không hỗ trợ (làm tay theo `HUONG_DAN_TAO_SD_PDA_SP.md` mục 2): message class `ZMC_PDA_SP`, authorization field `ZSPTYPE` + object `ZBM_PDA_SP`, TBRG `ZSPA/ZSPL`, TMG `ZBM_SP_TMG`, SICF `/sap/bc/zbm_pda_sp`, role PFCG, dữ liệu SM30.
- Sửa lỗi của code mẫu ban đầu: method không được vừa `RETURNING` vừa `EXPORTING`; `AUTHORITY-CHECK` dùng tên object qua biến để class biên dịch được trước khi tạo auth object.
- **Client:** MCP tạo ở client 100, còn link SAP của PDA Dev ghi client 300 (cùng host `192.168.100.75`). Dữ liệu bảng và role theo client nên cần chốt PDA dùng client nào.

## 5. Việc còn lại / cần xác nhận

1. **Hoàn tất phía SAP (làm tay):** kích hoạt class `ZBM_CL_PDA_SP_HTTP`, rồi tạo message class, authorization object, TBRG, TMG, SICF, role và nhập dữ liệu SM30 (mục 4). **Chưa xong các bước này thì PDA chưa chạy được**: màn Danh sách phiếu báo lỗi khi lấy địa điểm, và mọi API Portal báo lỗi khi lấy tài khoản.
2. Kiểm tra trên SAP thật: tên object chưa trùng, ngôn ngữ VI, có `/UI2/CL_JSON`, ABAP ≥ 7.40 (code mẫu chưa kiểm cú pháp, không có MCP nối hệ VAS).
3. Hỏi team Sales Portal: URL logistics cho QAS/PRD, URL token PRD, danh sách `receivingLocation` theo từng môi trường (SAP nhập tay vì Portal không có API địa điểm), tài khoản riêng cho PDA.
4. **Bảo mật:** PDA đang gọi SAP bằng `http://`, nên user/mật khẩu SAP và mật khẩu Portal trong response đi không mã hóa → nên bật HTTPS trước khi lên PRD. Tài liệu API v1.4 ghi sẵn mật khẩu `sap_sync_*` dạng chữ rõ; **không có mật khẩu nào được chép vào code hay tài liệu**, nhập thủ công qua SM30 từng hệ.
5. Giả định cần Portal xác nhận: SO hoàn thành khi mọi dòng `completionStatus = X`; nhập tay mã phiếu không có `|version` thì Portal có chấp nhận không (PDA gửi nguyên nội dung nhập vào `qrCode`); ý nghĩa `canCompleteExport` (suy từ tên field).
6. Nút "PĐK" trong màn xuất kho thay cho màn "danh sách SO line / item" của wireframe, để không sửa layout và logic `XuatKhoBanHang`. Không chặn quét vượt KL còn lại (FS không nêu).
7. Câu hỏi treo trong FS (ô I3–I5 sheet 1): "KL còn lại?" và "trạng thái X với Null ở đâu".

## 6. Kiểm chứng đã chạy

- `gradlew :app:assembleDebug` thành công.
- Harness Java độc lập cho phần đọc JSON, dùng đúng các mẫu trong tài liệu v1.4: QR (1 SO và nhiều SO), kanban 3 cột và chia vào 4 tab (7 tình huống: ngày có/không có từng cột, thiếu cột, cột khóa lạ, rỗng), báo lỗi 400, `message` dạng mảng (422), token, ngày, địa điểm SAP.
- `XuatKhoBanHang.java`: không đổi dòng nào.
- **Chưa test**: trên PDA Honeywell, với Portal/SAP thật (chưa có tài khoản PDA và chưa có API SAP).

## 7. Checklist test trên PDA (sau khi có API SAP)

1. Màn hình đầu hiện "Version 2.2.7 - 30/10/2026"; màn Chức năng có "9.Danh Sách Phiếu Đăng Ký".
2. XKBH → quét QR `AHT00000032|aaa48` (súng + Camera) → màn Phiếu đăng ký đúng Số phiếu/Địa điểm/Phương tiện/Ngày; SO đã hoàn thành màu xám, bấm bị chặn; QR sai → hiện đúng thông báo của Portal.
3. Chọn SO chưa hoàn thành → tự mở SO, nhập Số xe, nút PĐK hiện KL đăng ký/còn lại; quét Etiket + CH SAP như cũ; quay lại thì trạng thái SO cập nhật.
4. Quét lại / Thoát đúng điều hướng (Thoát về màn Chức năng).
5. DS phiếu ĐK: địa điểm lấy từ SAP → chọn địa điểm + ngày → Mở → 4 tab có số đếm (phiếu chia theo mục 2.1), tab rỗng hiện "Không có phiếu", Làm mới. Thử các ngày Z7: 27/10 (Chưa vào cổng + Đã xếp tài), 05/10 (Đang nhận hàng), 26/10 (Chờ ra cổng, Chờ cân đầu ra), 30/10 (chỉ Đã giao hàng).
6. Chi tiết phiếu: `canCompleteExport = 0` → nút xám + dòng "chưa đủ điều kiện"; `= 1` → nút bật → Đồng ý/Huỷ → gửi → thông báo → danh sách tự cập nhật.
7. Token: để quá 1 giờ rồi thao tác tiếp vẫn chạy (tự đăng nhập lại); tắt WiFi / sai user SAP → thông báo lỗi rõ.

## 8. Địa điểm nhận hàng: tự cập nhật vào ZBM_SP_LOCATION (cách 1)

- **SAP:** API `/sap/bc/zbm_pda_sp` thêm **POST `?sap-client=300&type=LOCATION`**, body `{"data":[{"locationCode":"Z7","locationName":"VAS An Hưng Tường"}]}` → thêm mới (`ACTIVE = X`) hoặc đổi tên địa điểm đã có; không đổi `ACTIVE`/`SORT_ORDER`. Cần quyền `ZBM_PDA_SP` với `ZSPTYPE = LOCATION`, `ACTVT = 02`. Class `ZBM_CL_PDA_SP_REST` / `ZBM_CL_PDA_SP_HTTP` (bỏ kiểm tra CSRF). Cú pháp đã kiểm sạch trên SAP; **chưa active** (kích hoạt bằng ADT/SE24).
- **PDA:** màn "Danh sách phiếu đăng ký" lấy địa điểm từ SAP; SAP chưa có thì thử lấy từ Portal; mỗi lần tải danh sách phiếu, địa điểm (mã + tên) chưa có trong ô chọn được thêm vào ô chọn và gửi lên SAP.
- **Giới hạn của Portal (đã thử trên Dev):** API danh sách phiếu bắt buộc có địa điểm (bỏ trống → 400 "Cần có mã địa điểm và ngày nhận hàng hợp lệ."), tên không dùng được thay mã, mã `Y0` trong tài liệu không hợp lệ, `Z7` hợp lệ. Vì vậy PDA chưa tự phát hiện được địa điểm đầu tiên.
- **Yêu cầu gửi team Sales Portal (anh Phan Tiến Long):** "API `pda/registrations/search` cho phép bỏ trống `receivingLocation` để trả phiếu của mọi địa điểm đang hoạt động (kèm `receivingLocation`, `receivingLocationName`, `receivingLocationType`), hoặc cung cấp API danh sách địa điểm nhận hàng đang hoạt động (mã, tên, loại). Cần cho PDA tự dựng danh sách địa điểm, không phải khai báo tay ở SAP."

