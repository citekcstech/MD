# BDP_PCE – Import "MIC long text" vào Inspection Plan: phân tích & thiết kế

Ngày: 31.10.2026 · Dev: `GUI_BIDIPHAR_DEV100` · Test: `GUI_BIDIPHAR_DEV300` (cùng system DEV, client 300) · Nền tảng: **On-Premise** (release 816, HANA)

File nguồn: `CodeABAP/BDP_PCE/MIC_Long_text/BDP_Plan2000_InspPlan_MIC_LongText.xlsx`

## 1. File Excel

| Mục | Giá trị |
|---|---|
| Sheet | `InspPlan_MIC_LongText` (1 sheet) |
| Header | dòng 9: `Material · Plant · Group · Group counter · Operation · Char. · MIC · MIC description · MIC long text` (cột A–I) |
| Dữ liệu | dòng 10–574 = **565 dòng**, 37 material, 44 plan (group+counter), Plant 2000 |
| Khoá duy nhất | (Group, Group counter, Operation, Char.) – không trùng dòng nào |
| Dòng rỗng long text | 26 dòng (cột I trống) → bỏ qua, ghi log |
| Độ dài long text | tối đa **2.380** ký tự, trung bình 141, 143 dòng > 132, 54 dòng > 255 |
| Xuống dòng trong ô | 37 ô có `\n` |
| Kiểu ô | toàn chuỗi (giữ số 0 đầu: `0010`, `01`); Char. là `10`/`100`/`1000` (2–4 ký tự, cần đệm về `MERKNR` 4 số) |

Hệ quả kỹ thuật: ô dài tới 2.380 ký tự → **không dùng `TEXT_CONVERT_XLS_TO_SAP`** (cách `ZQM_PG_UPLOAD` đang dùng, bị giới hạn độ dài ô). Dùng `cl_fdt_xl_spreadsheet` (đọc thẳng xlsx, ô kiểu string).

## 2. Long text của Inspection Plan characteristic lưu ở đâu

- Bảng `PLMK` (plan characteristic): khoá `PLNTY, PLNNR, PLNKN, KZEINSTELL, MERKNR, ZAEHL`; cờ `LTEXTKZ` (có long text), `LTEXTSPR` (ngôn ngữ).
- Text object **`QSS`**, text ID **`QM`** ("Inspection feature long text"). (`QPMERKMAL`/`QPMT` là của master MIC, không phải plan.)
- Đường nối từ Excel → `PLMK`:
  `MAPL (matnr, werks, plnty='Q', plnnr, plnal)` → `PLAS (plnty, plnnr, plnal, plnkn)` → `PLPO (plnkn, vornr)` → `PLMK (plnkn, merknr, verwmerkm)`.
  Đã đối chiếu thật trên DEV300 với dòng đầu file (Material 2100283 / Plant 2000 / Group B2100283 / 01 / Op 0010 / Char. 10 / MIC TINHCHAT): **khớp**.

## 3. Tình trạng data trên 2 client

| | DEV100 | DEV300 |
|---|---|---|
| `PLMK` | **0 dòng** (chưa có inspection plan) | 589 dòng (đủ plan, `LTEXTKZ` rỗng hết = chưa có long text) |
| `STXH` object `QSS`/`QPMERKMAL` | trống | trống |

→ Lập trình ở DEV100 (repository dùng chung mọi client), **test ghi data chỉ làm được ở DEV300**.

## 4. Cách ghi: dùng BAPI chuẩn, không UPDATE trực tiếp

`BAPI_INSPECTIONPLAN_CHANGE` (FG `CPCC_ES`) → `CPCC_S_TASK_LIST_MAINTAIN` → `CPCC_P_TASK_LIST_MAINT_LTEXT` → `CQ_CL_S_CHA_LTEXT_CREATE` (ghi `SAVE_TEXT` QSS/QM + cập nhật cờ `LTEXTKZ`, `LTEXTSPR`, `KURZTEXT` của PLMK + change document).

Tham số cần truyền:

| Tham số | Giá trị |
|---|---|
| `GROUP`, `GROUPCOUNTER` | Group (cột C), Group counter (cột D) |
| `MATERIAL`, `PLANT` | tuỳ chọn (cột A, B) |
| `TEXT_ALLOCATIONS-MAINTAIN_MODE` | `C` = tạo mới (chưa có long text), `M` = thay thế (đã có; thực chất xoá + tạo lại, bỏ qua nếu nội dung y hệt), `D` = xoá |
| `OBJECT_TYPE` | `19` (inspection characteristic) |
| `SEQUENCE_NO` | `000000` (sequence chuẩn) |
| `ACTIVITY` | Operation (cột E, `0010`) |
| `INSP_CHAR_NO` | Char. (cột F, đệm 4 số) |
| `CHA_TEXT_TYPE` | `C` (long text của characteristic; `S` là sampling text) – **cần xác nhận khi test** |
| `LINE_FROM/LINE_TO` | khoảng dòng trong bảng `TEXT` |
| `TEXT` | `FORMAT_COL` (`*`), `TEXT_LINE` (CHAR 132) |

Chú ý:
- Lỗi cấu trúc: `M` trên đặc trưng chưa có long text sẽ lỗi (`CQ_CL_S_CHA_LTEXT_PROVIDE` → `text_not_found`) → phải chọn `C`/`M` theo `PLMK-LTEXTKZ` đọc trước.
- Plan characteristic **tham chiếu master MIC theo kiểu by-reference** (`QPMK_REF`) bị từ chối ghi long text (message CQCL 011).
- BAPI không tự commit: cần `BAPI_TRANSACTION_COMMIT` (`WAIT = 'X'`); chế độ test dùng `BAPI_TRANSACTION_ROLLBACK`.
- Ngôn ngữ long text = ngôn ngữ đăng nhập (`SY-LANGU`), BAPI change không có tham số ngôn ngữ.
- `TDLINE` rộng 132: phải cắt long text theo `\n` rồi theo độ dài (ưu tiên ngắt tại dấu cách).

## 5. Thiết kế chương trình (đề xuất)

Report `PROG/P` đơn (không dùng include – bug ghi `PROG/I` qua MCP), cấu trúc theo `ZQM_PG_UPLOAD`:

- **Selection screen**: `P_FILE` (F4 `file_open_dialog`), `P_TEST` (mặc định `X` = chạy thử, rollback), `P_OVR` (ghi đè nếu đã có long text), tuỳ chọn Plant.
- **Đọc file**: `cl_gui_frontend_services=>gui_upload` (binary) → xstring → `cl_fdt_xl_spreadsheet`; kiểm tra header dòng 9; bỏ dòng thiếu key.
- **Kiểm tra từng dòng** (1 SELECT gộp theo plan): có `MAPL` đúng Material/Plant/Group/counter, có `PLMK` đúng Operation/Char., MIC cột G = `PLMK-VERWMERKM`, đã có long text hay chưa, long text rỗng.
- **Ghi**: gom theo (Group, counter) → 1 lần gọi `BAPI_INSPECTIONPLAN_CHANGE` / plan, kiểm `RETURN`, commit/rollback.
- **Kết quả**: ALV (`cl_salv_table`) mỗi dòng Excel: trạng thái (xanh/vàng/đỏ), message, thao tác (Tạo/Thay/Bỏ qua).
- Quy ước: tên biến theo skill `abap-naming-convention`; 1 dòng `" SangVT create 31.10.2026` đầu file (object tạo mới).

## 6. Giới hạn khi test tự động

- `ZADT_VSP` (WebSocket) **chưa cài trên DEV300** → `RunReport`/debugger không dùng được.
- `ExecuteABAP` chỉ chạy mức `harmless` (không ghi DB) → dùng được cho kiểm tra phần parse/cắt dòng/validate, **không** chạy được BAPI ghi.
- Upload file từ máy trạm cần SAP GUI → bước chạy thật (test mode `P_TEST = X`, rồi chạy thật) do user thực hiện trên SAP GUI ở DEV300; tôi đọc kết quả bằng `RunQuery` trên `PLMK`/`STXH`.

## 7. Đã chốt với user (31.10.2026)

- Chương trình `ZQM_PG_MIC_LONGTEXT`, package `ZPK_QM`, TR mới **`DEVK901110`**, mặc định bỏ qua dòng đã có long text (ô Overwrite để thay), ô Chạy thử mặc định bật.

## 8. Kết quả triển khai

- Source local: `CodeABAP/BDP_PCE/zqm_pg_mic_longtext/zqm_pg_mic_longtext.abap` (895 dòng). Trên SAP: DEV100, `R3STATE = A`, giống hệt file local (`diff` sau `ExportToFile`), thấy được ở DEV300.
- **Điểm thiết kế phát hiện thêm khi đọc source SAP:** `CQ_CL_S_CHA_LTEXT_CREATE` ghi **dòng đầu của long text vào `KURZTEXT`** của characteristic → chương trình luôn đặt dòng 1 = `PLMK-KURZTEXT` hiện có, long text Excel bắt đầu từ dòng 2 (nếu không, MIC description bị ghi đè bằng 40 ký tự đầu của long text).
- Dòng text rộng 72 ký tự, ngắt ở dấu cách, tách theo xuống dòng trong ô, bỏ khoảng trắng cuối đoạn, giữ dòng trống giữa các đoạn.
- Chặn (không ghi, báo trong ALV): long text trống; key trùng trong file; không thấy plan/operation/char.; Material/Plant không thuộc plan (MAPL); MIC khác `PLMK-VERWMERKM`; `PLMK-LTEXTSPR` khác ngôn ngữ đăng nhập; đã có long text mà không tick Overwrite.
- Ghi theo plan (1 lần gọi BAPI / Group + Counter); plan lỗi thì gọi lại từng dòng để cô lập dòng lỗi.
- Nhãn màn hình gán ở `INITIALIZATION` vì `SetTextElements` lỗi (chưa cài `ZADT_VSP`).

### Đã kiểm thử

| Việc | Kết quả |
|---|---|
| SyntaxCheck cả chương trình | sạch (`DeployFromFile`, `EditSource` activate) |
| Cắt dòng long text (`ExecuteABAP` DEV100) | đúng: 72 ký tự, ngắt tại dấu cách, CRLF/trailing space, chuỗi 100 ký tự liền cắt cứng |
| Gọi `BAPI_INSPECTIONPLAN_CHANGE` (`ExecuteABAP` DEV100) | tìm ra lỗi thật: bảng `EMPTY KEY` làm BAPI dump → đã sửa sang key mặc định; BAPI chạy và trả `RETURN` (client 100 thiếu customizing QM nên báo `TCA41`) |
| Ghi thật ở DEV300 | **chưa chạy**: server `GUI_BIDIPHAR_DEV300` chặn `ExecuteABAP` (read-only), upload file cần SAP GUI |
| Đọc xlsx thật (`cl_fdt_xl_spreadsheet`) | **chưa chạy** (cần SAP GUI) |

### Cách user test ở DEV300 (SAP GUI, đăng nhập ngôn ngữ EN)

1. SE38 → `ZQM_PG_MIC_LONGTEXT` → Execute. Chọn file `BDP_Plan2000_InspPlan_MIC_LongText.xlsx`, giữ nguyên **Chạy thử = X**, không tick Overwrite.
2. Kỳ vọng: 565 dòng; ~26 dòng "Long text trống - bỏ qua"; dòng còn lại "Chạy thử OK" (xanh). Dòng đỏ: đọc cột Thông báo.
3. Nếu sạch: chạy lại bỏ tick Chạy thử → ghi thật. Kiểm: `QP02` mở plan `B2100283`, operation 0010, characteristic 10 → long text; hoặc `PLMK-LTEXTKZ = X` và `STXH` object `QSS` ID `QM`.
4. Gửi lại ALV/message lỗi (nếu có) để chỉnh. Chỗ có khả năng cần chỉnh nhất: `cha_text_type = 'C'`, `operation_id` để trống, ngôn ngữ text.

### Việc còn lại / chưa làm

- Chưa chạy ATC; chưa tạo Tcode (MCP không tạo được TRAN, tạo trong SE93 nếu cần).
- Chưa commit git (sửa `.claude/skills/**` cần commit: `_ghichu_mcp_gui.md`, `_ghichu_local.md`).
