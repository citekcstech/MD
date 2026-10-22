# ECC → S/4HANA 2025 — Chuyển ~7000 user (giữ pass + role) bằng Client Copy/Transport, profile `SAP_USER`

- Ngày soạn: 22.10.2026
- Phạm vi: chuyển user master (kèm role, authorization profile, hash password) từ client ECC sang client S/4HANA 2025 bằng **SCC9** (remote copy) hoặc **SCC8 + SCC7** (export/import qua file).
- Trạng thái: hướng dẫn tổng hợp từ tài liệu SAP + kinh nghiệm, **chưa chạy thử trên hệ thống thật**. Chỗ nào ghi ⚠️ là chưa xác nhận được, phải kiểm tra ở sandbox trước.

## 1. Khi nào dùng cách này

| Tình huống | Có cần làm theo file này không |
|---|---|
| Convert tại chỗ ECC → S/4 (SUM/DMO) | **Không.** User, pass, role nằm cùng database, giữ nguyên. Chỉ chỉnh quyền sau conversion (SU25, SU24). |
| Dựng hệ S/4 2025 mới (greenfield / system copy sang landscape mới) và cần mang user ECC sang | **Có.** Làm theo file này, nếu qua được bước kiểm tra release (mục 3). |
| Ghép user từ hệ Gateway/Fiori (front end) vào S/4 | Xem mục 9 (2 nguồn user). |

## 2. Chọn SCC9 hay SCC8/SCC7

| | SCC9 — Remote client copy | SCC8 + SCC7 — Client export/import |
|---|---|---|
| Cách chạy | Chạy ở **client đích**, kéo data trực tiếp từ nguồn qua RFC | Export ở **client nguồn** ra file transport, import vào client đích rồi post-processing |
| Điều kiện | Phải có đường mạng + RFC từ đích sang nguồn | Không cần RFC; chỉ cần chép file transport (hoặc dùng chung `/usr/sap/trans`) |
| Số bước | Ít hơn, nên ưu tiên | Nhiều hơn, dùng khi 2 hệ thống không nối mạng với nhau |
| Chạy lại khi lỗi | Chạy lại SCC9 | Phải export lại hoặc import lại request |

Khuyến nghị: dùng **SCC9** nếu có RFC giữa 2 hệ thống. Dùng SCC8/SCC7 nếu không có.

## 3. Rủi ro lớn nhất: khác release ECC ↔ S/4

⚠️ Client copy/transport giữa 2 hệ thống **khác release** thường bị chặn hoặc không được SAP hỗ trợ (ECC 6.0 so với S/4HANA 2025). Chưa xác nhận được bằng tài liệu tra được.

Cách kiểm tra rẻ nhất:

1. Làm trước trên **sandbox** (cặp hệ ECC copy + S/4 sandbox), không làm thẳng trên hệ chính.
2. Với SCC9: chạy **Test Run** (mục 5.4). Test Run kiểm tra điều kiện và báo lỗi release ngay, chưa ghi gì.
3. Tra SAP Note trên [me.sap.com](https://me.sap.com) với từ khoá *client copy different release*, *SCC9*, *SAP_USER*, đối chiếu đúng SAP_BASIS của 2 hệ thống.
4. Nếu bị chặn: chuyển sang phương án dự phòng ở mục 10 (report ABAP tự viết, hoặc PFCG transport + SU10).

## 4. Chuẩn bị (checklist)

| # | Việc | Tcode | Ghi chú |
|---|---|---|---|
| 1 | Chốt client nguồn (ECC) và client đích (S/4) | | Ghi lại SID, số client, SAP_BASIS của cả hai (System → Status). |
| 2 | Kiểm tra client đích đã tồn tại chưa | SCC4 | Chưa có thì tạo mới (Client role = Test hoặc Customizing). |
| 3 | Mở khoá client đích để nhận copy | SCC4 | Mục *Protection: Client copy and comparison tool* = **Level 0 (No restriction)**. Sau khi xong đổi về Level 1 để tránh bị ghi đè nhầm. |
| 4 | **Sao lưu user master client đích** | SCC8 (chạy ở đích, profile `SAP_USER`) | ⚠️ `SAP_USER` ghi đè user trùng tên ở đích, và chưa xác nhận được user chỉ có ở đích có bị giữ lại hay không. Phải có bản backup trước khi chạy. |
| 5 | Chuẩn bị user chạy copy | SU01 | Dùng user riêng, quyền `SAP_ALL` tạm thời cho phiên copy, thu hồi sau khi xong. |
| 6 | Client mới tạo bằng SCC4 chưa có user | | Đăng nhập bằng `SAP*` (pass mặc định `PASS`). ⚠️ Nếu tham số `login/no_automatic_user_sapstar` = 1 (mặc định ở bản mới) thì `SAP*` không dùng được, phải đặt tạm = 0 rồi restart, hoặc tạo user sẵn bằng cách khác. |
| 7 | Báo user ngừng đổi pass, ngừng tạo/sửa user từ thời điểm snapshot | | Thay đổi sau thời điểm copy sẽ không có ở đích (xem mục 8). |
| 8 | Đo dung lượng bảng user ở nguồn | SE16N | Các bảng `USR02`, `AGR_USERS`, `AGR_1251`. `AGR_1251` thường lớn nhất, quyết định thời gian chạy. |
| 9 | Chọn khung giờ chạy | | Chạy ngoài giờ cao điểm; nên chạy nền (background). |

## 5. Cách A — SCC9 (Remote client copy)

### 5.1 Tạo RFC destination từ đích sang nguồn

1. Ở hệ **đích (S/4)**, vào **SM59**.
2. Tạo destination loại **3 (ABAP Connection)**, ví dụ tên `ECC_<SID>_<CLIENT>_COPY`.
3. Nhập Target Host, System Number của hệ nguồn. Tab *Logon & Security*: nhập Language, **Client nguồn**, User và Password của user có quyền (mục 4, dòng 5).
4. Bấm **Connection Test** và **Remote Logon**. Cả hai phải thành công trước khi sang bước sau.

### 5.2 Đăng nhập client đích

Đăng nhập vào **đúng client đích** của S/4 (client sẽ nhận user), bằng user có quyền client copy.

### 5.3 Điền màn hình SCC9

| Trường | Giá trị |
|---|---|
| Selected Profile | `SAP_USER` |
| Source Client | Client ECC chứa user cần chuyển |
| Source Client User Master | Để mặc định (cùng client nguồn) |
| Source Destination | RFC tạo ở 5.1 |

### 5.4 Chạy Test Run trước

1. Tick **Test Run**.
2. Chọn **Start Immediately** hoặc **Schedule as Background Job** (khuyến nghị chạy nền).
3. Bấm **Start**. Test Run chưa ghi data, chỉ kiểm tra điều kiện và ước lượng thời gian.
4. Theo dõi ở **SCC3** (mục 5.6). Nếu báo lỗi release hoặc thiếu điều kiện thì dừng, quay lại mục 3.

### 5.5 Chạy thật

1. Vào lại SCC9, **bỏ tick Test Run**, giữ nguyên các thông số.
2. Bấm **Start** (Schedule as Background Job).
3. Hệ thống hỏi xác nhận. Bấm đồng ý sau khi chắc đã có backup (mục 4, dòng 4).

### 5.6 Theo dõi

1. **SCC3** → chọn tab *Copy*/*Client Copy*, xem trạng thái dòng vừa chạy.
2. Bấm vào dòng đó để xem log chi tiết. Trạng thái cuối cần là **Successfully Completed**.
3. Xem thêm job nền ở **SM37** (tên dạng `CLIENTCOPY...`) và dump ở **ST22** nếu lỗi.

## 6. Cách B — SCC8 (export) + SCC7 (import)

### 6.1 Export ở client nguồn (ECC)

1. Đăng nhập **client nguồn**. Vào **SCC8**.
2. Chọn profile `SAP_USER`.
3. Target System: nhập `<SID>.<CLIENT>` của hệ đích (đúng cú pháp theo màn hình SCC8).
4. Chạy **Start Immediately** hoặc **Schedule as Background Job**.
5. Hệ thống tạo các transport request cho client export. ⚠️ Thường là 2–3 request có dạng `<SID>KO…`, `<SID>KT…`, `<SID>KX…`. Số lượng và tên chính xác lấy từ log **SCC3** (tab *Export*), không đoán.

### 6.2 Chép file sang hệ đích

Nếu 2 hệ không dùng chung thư mục transport, chép các file của từng request:

- File data: `/usr/sap/trans/data/` (file `R…` hoặc `D…`)
- File cofile: `/usr/sap/trans/cofiles/` (file `K…`)

Chép sang đúng thư mục trên hệ đích. Giữ nguyên tên file.

### 6.3 Import request vào hệ đích

Cách 1 — qua STMS:

1. Ở hệ đích vào **STMS** → Import Overview → chọn hệ thống đích.
2. Menu **Extras → Other Requests → Add**, nhập số từng request.
3. Chọn request → Import, ở popup chọn **Target Client** = client đích.
4. Import theo thứ tự các request như trong log export (không đảo thứ tự).

Cách 2 — qua dòng lệnh `tp` (do Basis chạy): import từng request với tham số client đích. Cú pháp chi tiết lấy từ tài liệu `tp` của đúng release ⚠️ chưa kiểm tra.

### 6.4 Post-processing bằng SCC7

1. Đăng nhập **client đích**. Vào **SCC7**.
2. Chọn dòng request vừa import, bấm **Start post-processing** (hoặc Schedule job).
3. Theo dõi ở **SCC3** tab *Import* cho đến khi trạng thái là **Successfully Completed**.

## 7. Kiểm tra sau khi copy

| # | Kiểm tra | Cách làm | Đạt khi |
|---|---|---|---|
| 1 | Log client copy | SCC3 | Successfully Completed, không còn lỗi đỏ. |
| 2 | Số user khớp | SE16N bảng `USR02` ở nguồn và đích | Số dòng khớp (trừ user hệ thống khác biệt đã biết). |
| 3 | Số gán role khớp | SE16N bảng `AGR_USERS` ở 2 hệ | Số dòng khớp, hoặc lệch có giải thích. |
| 4 | Số role và profile khớp | SE16N bảng `AGR_DEFINE`, `USR04` | Khớp. |
| 5 | Đăng nhập thử với pass cũ | Chọn 3–5 user (kèm 1 user quyền cao) cho đăng nhập thử | Đăng nhập được bằng pass ECC. Nếu bị buộc đổi pass thì ghi lại nguyên nhân. |
| 6 | Kiểu hash của pass | SE16N bảng `USR02`, cột `CODVN` | ⚠️ Hash kiểu cũ có thể không dùng được trên S/4 2025. Đếm số user theo `CODVN` để biết bao nhiêu người sẽ phải reset pass. Đối chiếu tham số `login/password_hash_algorithm` và `login/password_downwards_compatibility`. |
| 7 | Trạng thái khoá | SUIM → Users → theo trạng thái | Không có user bị khoá hàng loạt ngoài ý muốn. |

## 8. Xử lý role sau khi copy, và delta thay đổi

1. Role đến từ ECC **chưa có các check mới của S/4** (ví dụ `FD03/XD03` thay bằng `BP`, app Fiori). Chạy **SU25** (các bước 2A–2D) và rà **SU24** theo yêu cầu khách ("xoáy nòng" role).
2. Với role Fiori/Gateway: gộp catalog Fiori và `S_SERVICE` (OData) vào role back end sau khi merge sang embedded. Launchpad content đi bằng customizing request, không đi theo role PFCG.
3. **Delta sau thời điểm snapshot** (dự án kéo dài hơn 1 tháng):
   - Chốt ngày snapshot và ngày freeze role.
   - Role thay đổi sau đó: lọc `AGR_DEFINE-CHANGE_DAT` ở nguồn. Chuyển bằng PFCG transport (chọn kèm user assignment).
   - User tạo mới/sửa sau đó: lọc `USR02-ERDAT` (tạo mới) và bảng lịch sử `USH02` (`MODDA`). Bổ sung thủ công hoặc bằng SU10/report.
   - **Không chạy lại SAP_USER lần hai** vào cùng client để lấy delta, vì sẽ ghi đè các chỉnh sửa role đã làm ở đích.

## 9. Lưu ý khi có 2 nguồn user (ECC back end + Gateway/Fiori front end)

- ⚠️ `SAP_USER` ghi đè user trùng tên ở đích. Copy lần 2 từ nguồn thứ hai có thể đè kết quả lần 1.
- Chỉ dùng `SAP_USER` cho **một** nguồn (nguồn nhiều user nhất, thường là ECC back end).
- User/role của hệ Gateway: dùng PFCG transport (role) và SU10/report (user) để bổ sung, không dùng lại SAP_USER.

## 10. Lỗi thường gặp và phương án dự phòng

| Hiện tượng | Nguyên nhân thường gặp | Xử lý |
|---|---|---|
| Test Run báo khác release / không hỗ trợ | Release ECC khác S/4 | Quay lại mục 3. Chuyển sang phương án dự phòng bên dưới. |
| Không đăng nhập được client mới | Client mới chưa có user, `SAP*` bị tắt | Xem mục 4, dòng 6. |
| `Client copy not allowed` / client protected | SCC4 đang để protection level cao | Đặt Level 0 (mục 4, dòng 3). |
| RFC lỗi khi chạy SCC9 | Sai client/user trong SM59, thiếu quyền | Test lại Connection Test và Remote Logon. |
| Job copy bị dừng giữa chừng | Hết work process, hết dung lượng DB, timeout | Xem SM37, ST22; xử lý rồi chạy lại. Nếu đã ghi một phần thì khôi phục từ backup ở mục 4, dòng 4. |
| User đăng nhập bị buộc đổi pass | Hash cũ, chính sách pass ở đích chặt hơn | Chấp nhận reset, hoặc điều chỉnh chính sách theo yêu cầu khách. |

**Phương án dự phòng** nếu không dùng được `SAP_USER`:

1. Report ABAP tự viết: đọc `USR02` (hash), `USR21`/`ADRP`, `AGR_USERS`, `USR04` ở ECC, ra file hoặc RFC. Bên S/4 tạo user bằng `BAPI_USER_CREATE1` rồi gán lại role. Ghi hash trực tiếp vào `USR02` là cách SAP không hỗ trợ chính thức.
2. PFCG transport role (kèm user assignment) + SU10 tạo user hàng loạt. SU10 không đặt pass riêng cho từng user, hệ thống tự sinh initial password, nên user phải đổi pass lần đầu.

## 11. Rollback

1. Dừng job copy nếu còn chạy (SM37).
2. Chạy lại **SCC7** hoặc import bản backup đã export ở mục 4, dòng 4, vào client đích để khôi phục user master cũ.
3. Đặt lại SCC4 protection về Level 1 sau khi xong.
4. Ghi lại nguyên nhân và kết quả vào log dự án.

## 12. Việc cần xác nhận trên sandbox

| # | Câu hỏi | Cách xác nhận |
|---|---|---|
| 1 | Client copy ECC → S/4 2025 có bị chặn do khác release không | SCC9 Test Run + SAP Note |
| 2 | `SAP_USER` có copy hash password không, và hash kiểu cũ có dùng được trên 2025 không | Đăng nhập thử + đếm `CODVN` (mục 7, dòng 5–6) |
| 3 | User chỉ có ở đích có bị xoá khi chạy `SAP_USER` không | So `USR02` ở đích trước và sau khi chạy |
| 4 | Số request và tên request khi SCC8 export | Log SCC3 |
| 5 | Thời gian chạy thật với ~7000 user | Số liệu Test Run và lần chạy sandbox |

## Nguồn tham khảo

- [SAP Help — Client copy profiles (`SAP_USER`)](https://help.sap.com/saphelp_nw73/helpdata/en/4d/806794095114afe10000000a42189c/content.htm)
- [SAP Help — SU10 mass user maintenance](https://help.sap.com/saphelp_em92/helpdata/en/2e/6d9704db7811d2961c0000e82de14a/content.htm)
- [SAP Learning — Transporting Authorization Components](https://learning.sap.com/courses/exploring-the-authorization-concept-for-sap-s-4hana-and-sap-business-suite/transporting-authorization-components)
- [SAP Learning — Client Copy and Client Transport Tools](https://learning.sap.com/courses/technical-implementation-and-operation-ii-of-sap-s-4hana-and-sap-business-suite/client-copy-and-client-transport-tools)
- [SAP Community — Copying users & roles across systems](https://answers.sap.com/questions/8518606/copying-users--roles-across-system.html)
