# MAISON DEV300 — MM42: giữ số 0 đầu của GTIN (EAN11)

Hệ: `GUI_MAISON_DEV300` (https://eccdev.maisonrmi.com:50015, client 300, user CITEK-HUY).
Màn hình: MM42 → Basic Data → "Units of measure/GTINs/dimensions", cột GTIN (MARM-EAN11 / MEAN-EAN11), Ct = `T1`.
Yêu cầu: nhập `001234576899` → lưu xong vẫn còn `00` ở đầu.

> Chưa thay đổi gì trên SAP. Mọi nội dung dưới đây là kết quả đọc source chuẩn qua MCP.

## 1. Nguyên nhân (đã đọc source xác nhận)

Field EAN11 đi qua conversion exit **EAN11** (FM `CONVERSION_EXIT_EAN11_INPUT` / `_OUTPUT`, function group `CONV_EAN`), hai FM này gọi tiếp function group `WEA1`:

| FM | Việc làm |
|---|---|
| `CONV_EXIT_EAN11_INPUT_INTERN` | **Xoá số 0 đầu** nếu EAN chỉ gồm chữ số (`IF WORK_EAN CO '0123456789 '` → `EAN_AUFBEREITEN`). EAN có chữ cái thì giữ nguyên số 0 (note 703285). Comment trong source: bỏ số 0 để EAN-check không báo "EAN bị thay đổi" (WE068). |
| `CONV_EXIT_EAN11_OUTPUT_INTERN` | **Thêm lại số 0 đầu khi hiển thị**, chỉ khi EAN category (bảng `TNTP`) có `LNEAN` (độ dài EAN) khác rỗng và `ANEAN` (alphanumeric) rỗng: pad số 0 cho đủ `LNEAN`. |

Kết luận: SAP chuẩn **lưu EAN không có số 0 đầu** trong DB (MARM/MEAN) và chỉ "trang trí" số 0 lúc hiển thị, theo độ dài khai báo ở category.

## 2. Hướng xử lý

### Cách 1 — Customizing, không code (nên thử trước)
- SM30 → `V_TNTP` (hoặc SE16 `TNTP`), dòng category **T1**: điền `LNEAN` = 12 (độ dài muốn hiển thị), bỏ cờ `ANEAN`.
- Kết quả: nhập `1234576899` hoặc `001234576899` đều lưu DB là `1234576899`, mở lại MM43/MM42 hiển thị `001234576899`.
- Hạn chế: DB vẫn không có số 0; mọi EAN thuộc T1 đều bị pad đủ 12 ký tự; chương trình/interface đọc thẳng `MEAN-EAN11` sẽ không thấy số 0 (phải gọi `CONVERSION_EXIT_EAN11_OUTPUT`).
- Chưa kiểm được giá trị hiện tại của T1: hệ này không có endpoint datapreview (xem mục 4).

### Cách 2 — Enhancement (chỉ khi DB bắt buộc phải chứa số 0)
- Điểm chèn: implicit enhancement đầu `CONV_EXIT_EAN11_INPUT_INTERN` để bỏ qua bước xoá số 0 (cần điều kiện riêng, vì exit **không có tham số category**: chỉ có INPUT/OUTPUT).
- Rủi ro: exit dùng chung toàn hệ thống (đơn hàng, giao hàng, POS, IDoc, search help…). `0123…` và `123…` thành 2 EAN khác nhau → mất kiểm tra trùng EAN (M3 348), tra cứu theo mã quét lệch; `EAN_SYSTEMATIC`/xác định category theo đầu số cũng có thể sai. Cần regression test rộng.
- Phải xem trước 2 enhancement đã có trên hệ (mục 3) để không chồng chéo.

### Cách 3 — Field Z lưu chuỗi gốc
- Thêm field text riêng (append MARM + screen/subscreen) để lưu nguyên `001234576899`. Nặng nhất, chỉ làm khi nghiệp vụ cần giữ chuỗi gốc song song với EAN11 chuẩn.

## 3. Việc cần kiểm tra thêm
- `SearchObject` thấy 2 enhancement implementation sẵn có: **`ZENH_EAN11`** và **`ZENH_EAN_11`**. `FindReferences` cho thấy `ZENH_EAN11` gắn với 4 FM của `CONV_EAN` (`CONVERSION_EXIT_EAN11_INPUT/OUTPUT/RANGE_I/RANGE_O`), `ZENH_EAN_11` gắn với `CONVERSION_EAN_OUTPUT` (WEA1). Chưa đọc được nội dung (mục 4) → mở SE19/SE80 xem; có thể đã ai đó chỉnh đúng chỗ này.
- Dòng `TNTP` của category T1 (`LNEAN`, `ANEAN`, `PRFZA`).
- Domain `EAN11` có đúng conversion routine `EAN11` không (SE11) — suy ra từ source chuẩn, chưa đọc được DD01L.

## 4. Ghi chú MCP trên `GUI_MAISON_DEV300` (hệ ECC cũ)
- 404: `RunQuery`, `GetTableContents` (`/datapreview/freestyle`, `/datapreview/ddic`), `GetTable` cho bảng transparent (`/ddic/tables/MARM/source/main`), `GetSystemInfo`, `GetTransaction`, `GetObjectStructure`, `GetDataElementLabels`.
- `GitExport` lỗi WebSocket 500 (thiếu ZADT_VSP); `GetSource` không hỗ trợ `ENHO`; `GrepObjects` trên URL enhancement trả rỗng (không phân biệt 404).
- Chạy tốt: `SearchObject`, `GetSource` (FUNC kèm `parent`), `GetFunctionGroup` (tham số `function_group`), `FindReferences` với URI `/sap/bc/adt/vit/wb/object_type/<type>/object_name/<tên>`, `GetConnectionInfo`.
- Hệ quả: không đọc được data/DDIC trên hệ này qua MCP → đọc DDIC/TNTP phải nhờ user chạy SE16/SM30.
- Chưa ghi vào `_ghichu_mcp_gui.md` vì file đang conflict merge (UU) trong git.

## 5. Yêu cầu chốt: số 0 phải nằm thật trong DB → phải enhancement (đã đọc thêm `EAN_SYSTEMATIC`, `LWEA1F01`)

Luồng MM42 khi lưu GTIN: dynpro (conversion exit) → `MARA_EAN11` → `EAN_SYSTEMATIC` (function group `WEA1`) → trả `EAN_NEU` → ghi MARM/MEAN. Số 0 bị xoá ở **2 chỗ**, sửa 1 chỗ là chưa đủ:

| # | Chỗ xoá số 0 | Nằm ở |
|---|---|---|
| 1 | Input exit: `IF WORK_EAN CO '0123456789 '` → `PERFORM EAN_AUFBEREITEN` | `CONV_EXIT_EAN11_INPUT_INTERN` (include `LWEA1U12`) |
| 2 | Cuối `EAN_SYSTEMATIC`: `IF KZ_ALPHANUM = XWERT. EAN_NEU = EAN_NEU_RET. ELSE. PERFORM EAN_AUFBEREITEN USING EAN_NEU.` | FM `EAN_SYSTEMATIC` |

Cơ chế sẵn có để giữ số 0: nhánh **alphanumeric** (`KZ_ALPHANUM = X` → trả lại `EAN_NEU_RET` = chuỗi người dùng nhập, chỉ bỏ space đầu). `KZ_ALPHANUM` chỉ được bật khi EAN có ký tự không phải số (trong `EAN_KONVERTIEREN` hoặc ngay sau BAdI) → EAN toàn số luôn bị xoá số 0.
`BADI_EAN_SYSTEMATIC` (`CALL_USEREXIT`, đổi được `EAN_NEU`/`ETYP_NEU`, có `ALREADY_CHECKED`) **không đủ**: BAdI chạy trước, không đặt được `KZ_ALPHANUM` cho EAN toàn số, bước xoá ở cuối vẫn chạy.

### Hướng thiết kế đề xuất (implicit enhancement, không modification)
1. `CONV_EXIT_EAN11_INPUT_INTERN`: enhancement đầu FM — nếu EAN thuộc diện "giữ số 0" thì `OUTPUT = INPUT` rồi thoát (bỏ qua xoá số 0 và đổi UPC-E).
2. Cho `KZ_ALPHANUM = X` với EAN diện "giữ số 0" để `EAN_SYSTEMATIC` trả `EAN_NEU_RET`: enhancement cuối `FORM EAN_KONVERTIEREN` (EAN đổi/mới) **và** thêm điểm cho trường hợp EAN không đổi (bước xoá cuối FM chạy cả khi EAN không đổi → lưu lại lần sau sẽ xoá số 0 và `MEAN_UPDATE` thấy "EAN đổi"). Điểm thứ 2 cần chốt vị trí khi viết code.
3. Một hàm/class dùng chung quyết định "diện giữ số 0" (đọc bảng cấu hình Z hoặc TVARVC) để 2 chỗ trên luôn nhất quán. Exit không có tham số category → điều kiện phải dựa vào giá trị EAN (số, bắt đầu `0`, độ dài…) và/hoặc `SY-TCODE`.
4. Output exit không cần sửa: chỉ thêm số 0 khi `FL < LNEAN`, giá trị đã đủ số 0 thì giữ nguyên.

### Rủi ro cần chấp nhận
- `001234576899` và `1234576899` là 2 EAN khác nhau trong MEAN: mất kiểm tra trùng M3 348 giữa hai dạng; tra theo mã quét/IDoc/đơn hàng phải nhập đúng dạng có số 0 (input exit chung nên nhất quán nếu cùng điều kiện).
- Dữ liệu cũ đã bị xoá số 0 không tự phục hồi.
- Sửa standard `WEA1` ảnh hưởng mọi nơi dùng EAN11 → regression test: MM41/MM42/MM01/MM02, IDoc MATMAS, upload, VA01 nhập EAN.
- `ZENH_EAN11` / `ZENH_EAN_11` (đã có, gắn với `CONV_EAN` và `CONVERSION_EAN_OUTPUT`) phải đọc trước để không chồng chéo — chưa đọc được qua MCP.

### Code đã viết local (03.11.2026, theo yêu cầu "xem như ZENH_EAN11/ZENH_EAN_11 chưa có")
`C:\Users\sang.vu\Documents\GitHub\VSCodeSkillAI\CodeABAP\MAISON\MM42_GTIN_SO_0\` — class `ZCL_EAN_KEEP_ZERO` (+ ABAP Unit, độ dài fix cứng 12), 2 implicit enhancement (`ZENH_EAN11_KEEP0_IN` đầu FM `CONV_EXIT_EAN11_INPUT_INTERN`, `ZENH_EAN11_KEEP0_CHK` đầu FORM `EAN_ALT_PRUEFEN` → bật `KZ_ALPHANUM` để `EAN_SYSTEMATIC` trả `EAN_NEU_RET`); hướng dẫn tạo + test trong `HUONG_DAN_TAO_MM42_GTIN_SO_0.md`. Chưa tạo gì trên SAP.

### Độ dài giữ số 0: fix cứng, không dùng STVARV (quyết định 03.11.2026)
Class `ZCL_EAN_KEEP_ZERO` có hằng số `mc_keep_length = 12`, không đọc TVARVC. Lý do bỏ biến `ZEAN_KEEP_ZERO_LEN`: TVARVC theo client (áp cho mọi user trong client đó, không theo từng user), phải tạo lại ở từng hệ/client. Fix cứng thì độ dài đi theo transport của class, và exit không còn truy cập DB. Đổi độ dài = sửa hằng số + chuyển TR; muốn tắt nhanh = deactivate hai enhancement trong SE19.

### Việc MCP làm được / không
- Hệ này: `GitExport` WebSocket 500, `GetSource` không hỗ trợ ENHO, chưa thấy tool tạo ENHO → nhiều khả năng phải tạo enhancement bằng SE19/SE80 (mình viết code, user dán), TR do user cung cấp.
