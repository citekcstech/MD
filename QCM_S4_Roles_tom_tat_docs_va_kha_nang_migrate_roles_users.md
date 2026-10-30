# QCM S4 Conversion – Roles/Docs: tóm tắt & đánh giá khả năng migrate Roles/Users

Nguồn: `QCM - 01_S4_Conversion\06_Source Code 20261022\Roles\Docs` (3 file .docx, ghi chú của Huy từ các buổi workshop 05–06/10/2026 với WCM).
Ngày tổng hợp: 29/10/2026.

> Lưu ý phạm vi: thư mục chỉ có 3 file ghi chú/ảnh chụp Teams. **Không có source code ABAP, spec hay danh sách object của tool Z Roles.** Mọi kết luận về "tool làm được gì" dựa trên ảnh demo + ghi chú, không phải đọc code.

## 1. Ba file gồm gì

| File | Nội dung thật | Liên quan Roles? |
|---|---|---|
| `05.10.2026__Huy_notes_Masterdata.docx` (5 MB) | Ghi chú Masterdata: landed cost hàng nhập khẩu (hao hụt, MR11, PO Return override giá, claim Nợ 331/Có 632), chi phí vận chuyển STO DC→DC được vốn hoá, phí license MML 3% trên sales-in, và CMD.05.002 *article block for purchasing* (chặn đặt hàng theo tỉnh/site/urban/rural, assortment, 3 Z-table có hiệu lực từ–đến, ZMD03). 6 ảnh: Article 10187672, PO 4193598106 (landed cost). | Không |
| `06.10.2026_Huy_notes_sang_ketoan_roles.docx` (41 KB) | **Sáng 06/10 – Kế toán:** COA/Group COA, cashflow, đánh giá CLTG, WHT gross/net, Internal Order, TSCĐ mã 1 đồng/0 đồng, điều chuyển tài sản, zero balance theo segment, Fund cho CAPEX. **Chiều 06/10 – Kỹ thuật/Roles** (dòng 228–407): cây duyệt PR/PO, Fund Group, derive GL từ MCH5, thiết kế Roles cho cửa hàng, ROP/STO/workflow, performance, demo Z Roles, auto tạo site, tính license FUE. | Phần chiều: **có** |
| `06.10.2026_Huy_notes_chieu_roles_demo.docx` (124 MB) | Chỉ có **44 ảnh chụp màn hình** bản ghi Teams (02:22:44 → 03:08:24), không có chữ. Là demo của anh Đồng/Phong/Thịnh trên **ECC PRD client 800**: tool ZRT305 / ZRT305B, SU01, PFCG, job auto tạo site. | **Có – là nguồn chính** |

## 2. Thiết kế Roles của WCM (ghi chú chiều 06/10)

- Roles theo **Position** (chức danh HR), không gán trực tiếp từng người. Master/template role (vd Chuyên viên tài chính) chứa tcode → **derive** ra role đích danh theo user/site.
- Cửa hàng trưởng = role Non-trade (PR, PO: ME51N, ME21N) + **Org role** theo cửa hàng (CH01).
- Giới hạn SAP: một org-level field chứa tối đa **999 giá trị** → người duyệt toàn quốc phải tách role theo vùng/miền; Miền Bắc đã >1000 store, nhỏ nhất là cấp quản lý khu vực (QLKV).
- QLKV/vùng/miền xoay vòng liên tục → role gán theo khu vực cứng (A1…A20) khó đổi → dùng "role vỏ" (template) + Org role.
- **Kiêm nhiệm có end date.** Giám đốc tài chính 3 miền = 1 position, 3 user.
- "Roles làm từ DEV lên PRD" (transport). Thêm role template cho position → có chức năng riêng để cập nhật.
- User tích hợp (PI/PO → SAP) dùng user Digital access; user Bizzi được làm MIRO; license tính theo document (PO, SO, Billing), Store user tạo PR/PO không tính FUE.

## 3. Flow các tool Z (từ ảnh demo)

### 3.1 Tcode root ZRT305 – "User Master – Root"
```
ZRT305
├─ Function:  Mapping | Mass Update users | Report Userlist
└─ Display/Maintain (các view bảng Z):
   ├─ Department        (User Dept, 21 dòng: D01 IT, D03 Kế toán, D06 Winmart+, D07 Merchandise…)
   ├─ Position          (User Position, 170 dòng: User group, Chính danh/Kiêm nhiệm, Duration, Department…)
   ├─ Matrix            (User Matrix: Position → Role, 2.894 dòng, cờ Deactiv, mô tả role)
   ├─ Matrix – Do not delete
   ├─ Parameter         (SU3 parameter theo Department, 188 dòng: BUK, EVO, F4METHOD, PRI…)
   ├─ Additional Site Group        (134 dòng: WM_1512…, cột "Role copy" = ZSROL_SITE_CODE_WERKS)
   └─ Additional Site Group_Site   (249 dòng: Site Group ↔ Site)
```

### 3.2 ZRT305B – "Users Creation Tool" (tạo/cập nhật user)
```
Chọn Function: Tạo mới Cửa hàng trưởng | Tạo mới Dược sĩ trưởng | Tạo mới User
               | Cập nhật User | Cập nhật Cửa hàng/Dược sĩ trưởng
   │
   ▼
Nhập Alias/MSNV + Ticket No. ──► [SyncHR] kéo HR Job ID, HR organization (My HR – Workday)
   │
   ▼
Username (V_<tên>; cửa hàng: WMP6410) + Password TỰ SINH (dạng TCX@xxxxxxx, nút generate)
Full name, Email, Mobile, Valid from/to, Company, Site, Department, Position,
Additional Site Groups, bảng Sub-position (kiêm nhiệm: Sub-position, số tháng, From)
   │
   ▼
Lưu (✓) ──► ALV danh sách: Upload file | Clear all data | Send Email
   │
   ▼
Gán roles theo Matrix của Position (+ Sub-position) ; tạo role đích danh theo site (xem 3.3)
   │
   ▼
Send Email: gửi thông tin đăng nhập cho user
```
Khi **Cập nhật User**: ô Password bị khoá (xám) → không đổi password.

### 3.3 Cách role đến với user (ví dụ user WM00992, 49 role)
```
Position (vd D0611 WMP Quản lý khu vực)
   └─ Matrix → composite/role: ZCRRT_PO_APPROVAL_LEVEL_2, ZCRRT_VCM_COMMON_ROLE,
      ZSROL_PG_VMP_ALL, ZSROL_SITE_PUR_VM+_ALL …
   └─ Template org role ZSROL_SITE_*_WERKS (cờ Deactiv = X trong matrix, org level Site để trống – "WM DUMMY")
          │  copy theo "Role copy" của Additional Site Group
          ▼
   Role đích danh ZSROL_SITE_VMP_QLKV_WM00992  (tạo/đổi bởi BT_BATCH 06.10.2026)
          org level: Company 1401, User group VINMARTPLUS/VMP*, Site 2AJI, 2AJS, 2BV8, 5535, 5579, 6486, 6728
          profile sinh lại (T-PD919833)
Mass Update users (ZRT305): lọc Company/Dept/Position/Sub-position/User/Site Group
   → tick Department Description / Position Description / Matrix Role / Parameters → đồng bộ lại hàng loạt
```
(Việc template `_WERKS` được copy ra role đích danh là **suy luận** từ ảnh: cờ Deactiv, cột "Role copy", tên role có hậu tố user, người sửa là BT_BATCH.)

### 3.4 Job auto tạo site ZMON_MD_AUTO_SITE_SUBSEQUENCE
Chạy mỗi 10 phút (program ZPG_AUTO_UPDATE_SITE_FLOW), kích hoạt bởi TR có attribute `ZAUTO_SITE = X` (vd DEVK931959). Log bảng ZTB_SITE_LOG_I, các bước:
```
0 Đẩy customer theo Site lên PRD → 1 Chỉnh variant → 2 Insert 2 bảng cây duyệt PO/PR
→ 3 Tạo Profit/Cost/Fund Center → 4 Mapping Site–FundCenter → 5 Budget/Posting address
→ 6 Partner profile → 7 Gán Cost Center mặc định cho Site → 8 Insert ZTB_BLOCK_ASSORT
→ 9 Tạo & duyệt request/customer → 10 Gửi email cho user + TẠO USER tự động cho các Site trong TR
```
Kết quả báo vào Teams "SAP MasterData Notification". Ảnh 39–44: template Excel `WCM-IT-BM-4200-MD-Retail-Site 1.2.xlsx` và program Upload Plant Master Data (không liên quan roles).

## 4. Trả lời 3 câu hỏi

| # | Yêu cầu | Kết luận | Căn cứ |
|---|---|---|---|
| 1 | Move Roles nguồn → đích | **Không giải quyết được bằng tool trong tài liệu.** | Tool Z chỉ quản lý matrix Position→Role và derive role trong 1 hệ thống. Tài liệu chỉ nói role đi DEV→PRD bằng transport. Không có chức năng export/import role giữa hai hệ thống. |
| 2 | Import User, giữ password, không bắt đổi | **Không.** Tool làm ngược lại. | ZRT305B tự sinh password mới cho user mới và gửi email; chỉ khoá password khi cập nhật. Không có chức năng copy hash/giữ password. |
| 3 | Gán role cho user ở đích giống nguồn | **Một phần, và không phải bản sao 1:1.** | Nếu đưa Z-tool + dữ liệu Z-table sang đích thì Mass Update users gán lại theo matrix. Nhưng kết quả chỉ giống nguồn khi mọi role của user đều xuất phát từ matrix; role gán tay ngoài matrix sẽ không có. |

(Người hỏi ghi "2 vấn đề" nhưng liệt kê 3; trả lời đủ 3.)

### Hướng làm đề xuất (kiến thức SAP chuẩn – **không có trong tài liệu**, cần Basis/Security xác nhận)
1. **Xác định kiểu chuyển đổi trước.** Nếu là *system conversion tại chỗ* (cùng hệ thống nâng lên S/4) thì user, password, role, assignment được giữ nguyên, chỉ cần chỉnh quyền (SU25/SU24) và Fiori catalog/group. Câu hỏi 1–3 chỉ đặt ra nếu đích là hệ thống mới.
2. **Roles:** PFCG transport hoặc download/upload role (kèm composite → single, derived role, org level). Sau import: chạy SU25, sinh lại profile, bổ sung Fiori catalog/group cho S/4. Role đích danh theo site phải sinh lại **sau khi** site master ở đích đã có.
3. **Users + password:** copy user master gồm password hash (vd client export/import profile user master, hoặc chương trình riêng chép USR02). Tạo lại bằng BAPI_USER_CREATE1 với password sẽ là initial password và bắt đổi lần đầu. Cần kiểm tra tương thích thuật toán hash (tham số login/password_hash_algorithm) giữa hai hệ thống, và xin phê duyệt bảo mật vì đây là thao tác nhạy cảm.
4. **Gán role giống nguồn:** trích AGR_USERS từ nguồn (có from/to date, gồm cả role đích danh kiểu ZSROL_SITE_*_<USER>) và AGR_AGRS (composite), sau đó upload ở đích bằng SU10/BAPI_USER_ACTGROUPS_ASSIGN. Thứ tự: role → user → assignment. Song song, migrate các Z-table của ZRT305 (Department, Position, Matrix 2.894 dòng, Parameter, Site Group) để Mass Update về sau còn chạy được.

### Cần xin thêm / hỏi lại
- Spec + source ZRT305, ZRT305B, ZPG_AUTO_UPDATE_SITE_FLOW và danh sách Z-table/TR (anh Lưu Minh Đồng, TCX-TECH-MN).
- Hệ thống đích là in-place conversion hay hệ thống S/4 mới?
- Số lượng user/role thực tế (49 role/user mẫu, 2.894 dòng matrix) và có role gán tay ngoài matrix không.
- Chính sách bảo mật của WCM về việc chuyển password hash.
