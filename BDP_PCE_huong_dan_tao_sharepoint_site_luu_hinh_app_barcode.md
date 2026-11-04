# BDP – Hướng dẫn tạo SharePoint site và App registration để lưu hình ảnh từ App Barcode bảo trì

> Dành cho: bộ phận IT / quản trị Microsoft 365 của BIDIPHAR (người có quyền tạo site và đăng ký App trên tenant).
> Mục tiêu: chuẩn bị nơi lưu hình ảnh do App Barcode bảo trì (PDA) tải lên và cấp bộ thông số kết nối cho Citek cấu hình vào app.
> Hạn cần xong: trước giai đoạn đào tạo/UAT (từ 02/11/2026).

---

## 1. Tóm tắt nhanh

- **"Link SharePoint"** chính là địa chỉ của site, ghép từ 2 thông số: `SHAREPOINT_HOSTNAME` + `SHAREPOINT_SITE_PATH`
  → `https://bidiphar.sharepoint.com/sites/bidiphar.pda`
- Phải làm **2 việc** trên Microsoft 365:
  1. **Tạo site SharePoint** (có thư mục gốc `PDA`) – mục 3.
  2. **Đăng ký 1 App trong Microsoft Entra ID (Azure AD)** để app PDA đăng nhập và tải hình lên site đó – mục 4 đến 6. Việc này giống thao tác "tạo App trên MS 365".
- Từ App sẽ lấy được 3 giá trị: `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`.
- 2 thông số `UPLOAD_MAX_MB` và `UPLOAD_ALLOWED_EXT` **không tạo trên M365**, chỉ là quy định của app (giá trị cố định ở bảng dưới).

## 2. Bộ thông số cần có

| Tham số | Giá trị | Lấy / tạo ở đâu |
|---|---|---|
| `AZURE_TENANT_ID` | GUID của tenant BIDIPHAR | Entra admin center → Overview → **Tenant ID** (hoặc ở trang Overview của App registration, mục 4) |
| `AZURE_CLIENT_ID` | GUID của App vừa đăng ký | App registration → Overview → **Application (client) ID** (mục 4) |
| `AZURE_CLIENT_SECRET` | Chuỗi bí mật của App | App registration → Certificates & secrets → **Value** (mục 5). **Không ghi vào tài liệu/email** |
| `SHAREPOINT_HOSTNAME` | `bidiphar.sharepoint.com` | Tên miền SharePoint của tenant |
| `SHAREPOINT_SITE_PATH` | `/sites/bidiphar.pda` | Phần đường dẫn sau tên miền của site tạo ở mục 3 |
| `SHAREPOINT_ROOT_FOLDER` | `PDA` | Thư mục gốc tạo trong thư viện tài liệu của site (mục 3.3) |
| `UPLOAD_MAX_MB` | `25` | Dung lượng tối đa 1 tệp tải lên (MB) – app kiểm tra |
| `UPLOAD_ALLOWED_EXT` | `pdf, png, jpg, jpeg, xlsx, xls, docx, doc, zip` | Các phần mở rộng tệp được phép – app kiểm tra |

---

## 3. Tạo SharePoint site

Tài khoản thực hiện: **SharePoint Administrator** / **Global Administrator** (hoặc user được phép tự tạo site nếu tenant bật Self-Service Site Creation).

### 3.1 Tạo site
1. Vào SharePoint admin center: `https://bidiphar-admin.sharepoint.com` → **Sites → Active sites → + Create**.
   (Cách khác: trang chủ SharePoint `https://bidiphar.sharepoint.com` → **+ Create site**.)
2. Chọn loại site: **Team site** (hoặc **Communication site**). Với mục đích lưu tệp thì loại nào cũng được.
3. Điền thông tin:
   - **Site name**: `BIDIPHAR PDA`
   - **Site address (URL)**: `bidiphar.pda` → địa chỉ đầy đủ là `https://bidiphar.sharepoint.com/sites/bidiphar.pda`
   - **Owner**: người quản trị phụ trách (IT BIDIPHAR)
   - **Privacy / Sharing**: **Private**
4. **Create site**.

> Lưu ý: nếu hệ thống không chấp nhận dấu chấm trong URL, đặt tên khác (ví dụ `bidipharpda`) rồi **báo lại Citek** – giá trị `SHAREPOINT_SITE_PATH` phải khớp đúng địa chỉ thật của site.

### 3.2 Phân quyền cho người dùng xem hình
Mở site → **Settings (bánh răng) → Site permissions** → thêm nhóm/người cần xem hình (bảo trì, quản lý) vào **Members** (xem + sửa) hoặc **Visitors** (chỉ xem).
App PDA **không** đăng nhập bằng tài khoản người dùng nên quyền của app cấp riêng ở mục 6.

### 3.3 Tạo thư mục gốc `PDA`
1. Mở site → **Documents** (thư viện tài liệu mặc định, có thể hiển thị tiếng Việt là "Tài liệu").
2. **+ New → Folder** → đặt tên đúng `PDA` (viết hoa, không dấu cách).
3. Các thư mục con theo từng ứng dụng/ngày (ví dụ `PDA/BaoTri/2026/11`) do app tự tạo khi tải lên, không cần tạo tay.

### 3.4 Kiểm tra
Mở trình duyệt vào `https://bidiphar.sharepoint.com/sites/bidiphar.pda` thấy site và thư viện **Documents** có thư mục **PDA** là đạt.

---

## 4. Đăng ký App trong Microsoft Entra ID

Tài khoản thực hiện: **Application Administrator** / **Cloud Application Administrator** / **Global Administrator**.

1. Vào `https://entra.microsoft.com` (hoặc `https://portal.azure.com` → **Microsoft Entra ID**) → **Identity → Applications → App registrations → + New registration**.
2. Điền:
   - **Name**: `BIDIPHAR PDA SharePoint Upload`
   - **Supported account types**: **Accounts in this organizational directory only (Single tenant)**
   - **Redirect URI**: để trống
3. **Register**.
4. Ở trang **Overview** của App, ghi lại:
   - **Application (client) ID** → `AZURE_CLIENT_ID`
   - **Directory (tenant) ID** → `AZURE_TENANT_ID`

## 5. Tạo Client Secret

1. Trong App → **Certificates & secrets → Client secrets → + New client secret**.
2. **Description**: `PDA SharePoint upload`; **Expires**: chọn thời hạn (tối đa 24 tháng).
3. **Add**, rồi **copy ngay cột `Value`** (không phải cột *Secret ID*). Giá trị này **chỉ hiện 1 lần**, rời trang là không xem lại được; mất thì phải tạo secret mới.
4. Đặt nhắc lịch gia hạn trước ngày hết hạn. Secret hết hạn thì app PDA không tải được hình lên.
5. Gửi secret cho Citek qua **kênh bảo mật** (tin nhắn riêng, trình quản lý mật khẩu, hoặc đọc trực tiếp), không gửi qua email thường hoặc ghi trong tài liệu chung.

---

## 6. Cấp quyền cho App truy cập site

Có 2 cách. Khuyến nghị **Cách A** (chỉ cho App chạm vào đúng site `bidiphar.pda`, đúng yêu cầu "thư mục được phân quyền Read, Write").

### Cách A – Sites.Selected (khuyến nghị, an toàn)

**Bước A1 – Thêm API permission cho App (cấp ở mức tenant, chưa có quyền vào site nào)**
1. App → **API permissions → + Add a permission → Microsoft Graph → Application permissions**.
2. Tìm và tick **`Sites.Selected`** → **Add permissions**.
3. Bấm **Grant admin consent for BIDIPHAR** → xác nhận. Cột Status phải hiện dấu tick xanh **Granted**.

**Bước A2 – Lấy Site ID**
Dùng Graph Explorer (`https://developer.microsoft.com/graph/graph-explorer`), đăng nhập bằng tài khoản admin, chạy:

```
GET https://graph.microsoft.com/v1.0/sites/bidiphar.sharepoint.com:/sites/bidiphar.pda
```

Kết quả có trường `id` dạng `bidiphar.sharepoint.com,<GUID>,<GUID>` → đây là `{site-id}`.

**Bước A3 – Cấp quyền ghi cho App trên đúng site đó**
Vẫn trong Graph Explorer (admin cần đồng ý quyền **`Sites.FullControl.All`** ở tab *Modify permissions* của Graph Explorer), chạy:

```
POST https://graph.microsoft.com/v1.0/sites/{site-id}/permissions
Content-Type: application/json

{
  "roles": ["write"],
  "grantedToIdentities": [
    {
      "application": {
        "id": "<AZURE_CLIENT_ID>",
        "displayName": "BIDIPHAR PDA SharePoint Upload"
      }
    }
  ]
}
```

- `"write"` = đọc + ghi (tải hình lên, tạo thư mục con). Muốn chỉ đọc dùng `"read"`.
- Trả về `201 Created` là đã cấp thành công.
- Cách thay thế bằng PowerShell (PnP.PowerShell):
  `Grant-PnPAzureADAppSitePermission -AppId "<AZURE_CLIENT_ID>" -DisplayName "BIDIPHAR PDA SharePoint Upload" -Site "https://bidiphar.sharepoint.com/sites/bidiphar.pda" -Permissions Write`

### Cách B – Sites.ReadWrite.All (nhanh nhưng quyền rộng)
Ở bước A1 chọn **`Sites.ReadWrite.All`** thay cho `Sites.Selected` rồi **Grant admin consent**, bỏ qua A2/A3.
Nhược điểm: App đọc/ghi được **mọi site** trong tenant → chỉ dùng khi IT chấp nhận rủi ro này.

---

## 7. Kiểm tra trước khi gửi Citek (khuyến nghị)

Chạy trong PowerShell, thay 3 giá trị `<...>`:

```powershell
$tenant = "<AZURE_TENANT_ID>"
$body = @{
  client_id     = "<AZURE_CLIENT_ID>"
  client_secret = "<AZURE_CLIENT_SECRET>"
  scope         = "https://graph.microsoft.com/.default"
  grant_type    = "client_credentials"
}
$token = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token" -Body $body).access_token
$h = @{ Authorization = "Bearer $token" }

# 1) Đọc thông tin site
$site = Invoke-RestMethod -Headers $h -Uri "https://graph.microsoft.com/v1.0/sites/bidiphar.sharepoint.com:/sites/bidiphar.pda"
$site.id

# 2) Thử tải 1 tệp vào thư mục PDA
Invoke-RestMethod -Method Put -Headers $h -ContentType "text/plain" -Body "test" `
  -Uri "https://graph.microsoft.com/v1.0/sites/$($site.id)/drive/root:/PDA/test.txt:/content"
```

Bước 2 trả về thông tin tệp, và thấy `test.txt` trong thư mục `PDA` trên SharePoint là đạt. Xoá `test.txt` sau khi thử.

### Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| `401 invalid_client` khi lấy token | Sai Client ID / Client Secret (nhầm *Secret ID* với *Value*) hoặc secret hết hạn | Tạo secret mới, copy đúng cột **Value** |
| `403 Forbidden` / `accessDenied` khi gọi site | Chưa Grant admin consent, hoặc (Cách A) chưa cấp quyền site ở bước A3 | Làm lại bước A1 (consent) và A3 |
| `404 itemNotFound` | Sai `SHAREPOINT_SITE_PATH` hoặc site chưa tạo xong | Kiểm tra lại URL site thật |
| Tải được tệp nhỏ, tệp lớn lỗi | Tải đơn giản của Graph chỉ hỗ trợ tệp dưới 250 MB | Với giới hạn 25 MB của app thì không bị ảnh hưởng |

---

## 8. Danh sách cần gửi lại cho Citek

- [ ] `AZURE_TENANT_ID`
- [ ] `AZURE_CLIENT_ID`
- [ ] `AZURE_CLIENT_SECRET` (gửi qua kênh bảo mật; kèm **ngày hết hạn** của secret)
- [ ] Xác nhận địa chỉ site thật: `https://bidiphar.sharepoint.com/sites/bidiphar.pda`
- [ ] Xác nhận thư mục gốc `PDA` đã tạo trong thư viện **Documents**
- [ ] Xác nhận App đã được cấp quyền Read/Write trên site (mục 6) và đã chạy thử mục 7 thành công
