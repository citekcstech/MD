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

## 9. Yêu cầu bổ sung (bạn Huyền, 01.11.2026): gắn formula cho MIC có Char. 79xx

Yêu cầu: với MIC có số Char. 79xx → (1) vào Control Indicators chọn "Calculated characteristic"; (2) ô Formula hiện ra, nhập công thức, back, save. Dự kiến thêm **cột J "Formula"** vào template.

**Kết luận: làm được, dùng chính `BAPI_INSPECTIONPLAN_CHANGE` đang dùng cho long text (không cần BDC).** Chưa test ghi thật.

| Thao tác trên QP02 | Trường BAPI (`INSPECTION_CHARACTERISTICS` + `_X`) | PLMK |
|---|---|---|
| Control Indicators → Calculated Characteristic (QKZFORMEL) | `FORMULA_IND = 'X'` | `STEUERKZ` vị trí 15 = `X` |
| Tab Quantitative Data → Calculate Formula (QFORMELSL "Check and Calculate Formula in QM") | `FORMULA_CHECK_BY_SAP = 'X'` | `FORMELSL = 'X'` |
| Ô Formula | `FORMULA_FIELD_1` (+ `FORMULA_FIELD_2`), mỗi ô CHAR 60 | `FORMEL1`, `FORMEL2` |

Bằng chứng từ data DEV300 (đọc, không ghi):
- Có đúng **13 dòng `PLMK` đã có formula**, đều là Char. 7901 / MIC `ZAPI`, `FORMELSL = X`, `STEUERKZ` vị trí 15 = `X` (khác các dòng không formula đúng ở vị trí này). 13 dòng này trùng khớp 13 dòng Char. 7901 trong Excel (13 plan: B2100283, B2100414, B2100417, B2100549, B2100563 ×2, B2100571 ×3, B2100644, B2100904, B2101070, B2101841).
- Dạng công thức đang dùng: `C07001`; `C07001 * ( 100 - C07101 ) / 100`; `( C07001 * ( 100 - C07101 ) / 100 ) * ( 677.185 / 623.139 )`. Cú pháp tham chiếu: `C0` + số Char. 4 chữ số trong cùng operation (`C07001` = Char. 7001, `C07101` = Char. 7101 độ ẩm).
- Excel có 13 dòng Char. 7001 và 9 dòng Char. 7101; 12/13 dòng 7901 có long text trống.
- Plan `A2100277` (màn hình bạn gửi): Char. 7901 chưa có formula, `QPMK_REF` rỗng (không by-reference) → dùng làm plan test.

Thiết kế đề xuất (chưa làm, chờ user đồng ý):
- Cột J "Formula" tùy chọn; không có cột → chương trình chạy như cũ.
- Mỗi dòng có 2 phần độc lập (long text, formula); bỏ quy tắc "long text trống → bỏ qua cả dòng" (dòng chỉ có formula vẫn xử lý).
- Cùng 1 lần gọi BAPI / plan: thêm dòng `MAINTAIN_MODE = 'M'` vào `INSPECTION_CHARACTERISTICS` (+ `_X`, `FLAG_BAR_POINTER`).
- Kiểm tra: ô > 60 ký tự → tách sang `FORMULA_FIELD_2` (tối đa 120); các `Cnnnnn` phải tồn tại cùng operation; đã có formula: giống → bỏ qua, khác → chỉ ghi đè khi tick Overwrite.
- Rủi ro cần test bằng SAP GUI ở DEV300: BAPI mode `M` có nhận chỉ các field formula không, có cần `OPERATION_ID`, `STEUERKZ` có tự cập nhật đúng không. DEV100 thiếu customizing QM (`TCA41`), DEV300 chặn `ExecuteABAP` → không test ghi được bằng MCP.

## 10. File công thức Plant 1000 – tạm dừng chờ bổ sung cột (01.11.2026)

File: `CodeABAP/BDP_PCE/MIC_Long_text/BDP_Plan1000_InspPlan_CongThuc.xlsx` – sheet `InspPlan_CongThuc`, header dòng 9, dữ liệu dòng 10–151 (**142 dòng**, 135 plan, 92 material).

Header hiện có: `Material · Tên mã · Group · Group counter · Ngày hiệu lực · STT MIC · MIC · Công thức`. **Thiếu `Plant` và `Operation`** → user tạm dừng việc sửa `ZQM_PG_MIC_LONGTEXT`, sẽ bổ sung 2 cột này (chưa sửa chương trình, chưa ghi SAP).

Đối chiếu với DEV300 (đọc, trước khi mất kết nối): `PLMK` plan `A%` có đúng 134 dòng Char. 7901/`ZAPI` + 1 dòng 7911/`ZAPI` + 5 dòng 7911/`ZAPI2` + 2 dòng 7902/`ZAPI2` = 142, khớp file; `MAPL` Plant 1000 có 557 plan `A%`; chưa có formula nào ở Plant 1000.

Điểm cần user kiểm trong file:
- Dòng 131 (A2100648 counter 02): formula `C7001` – nhiều khả năng gõ thiếu số 0, đúng dạng là `C07001`.
- Dòng 87 (82 ký tự) và dòng 96 (68 ký tự) dài hơn 60 → phải tách `FORMEL1`/`FORMEL2`.
- Char. không chỉ 7901: có 7911 (6 dòng) và 7902 (2 dòng); formula tham chiếu thêm `C07201`, `C07301`, `C07002`, `C07102`.
- Một số dòng lệch khoảng trắng (dòng 42, 73, 140) – vô hại, chương trình sẽ gộp khoảng trắng.

Thiết kế đã chốt hướng (làm khi file đủ cột): chế độ chọn bằng radio **Long text + Formula (mặc định) / Chỉ Long text / Chỉ Formula**; header nhận thêm `STT MIC` (= Char.) và `Công thức`/`Formula`; `Operation` nếu để trống thì suy ra từ SAP (báo lỗi nếu Char. nằm ở nhiều operation); kiểm formula: dạng `C` + 5 chữ số, Char. tham chiếu phải có trong cùng operation, ≤ 120 ký tự (tách tại dấu cách).

## 11. Cập nhật 01.11.2026: file đủ cột, đã sửa chương trình (local)

File dùng: `CodeABAP/BDP_PCE/MIC_Long_text/BDP_Plan1000_InspPlan_CongThuc 1.xlsx` – header dòng 9: `Material · Tên mã · Plant · Group · Group counter · Ngày hiệu lực · Operation · STT MIC · MIC · Công thức` (A–J), 142 dòng, Plant 1000, Operation 0010, key không trùng, công thức giống file trước. Vẫn còn dòng 131 `C7001` (chương trình sẽ báo lỗi dòng này) và 2 dòng > 60 ký tự (87, 96).

`zqm_pg_mic_longtext.abap` (local, ~1.300 dòng) đã sửa:
- Selection screen thêm 3 radio: **Long text + Formula** (mặc định) / **Chỉ Long text** / **Chỉ Formula**; ô Overwrite dùng chung cho long text và formula.
- Header nhận thêm `STT MIC` (= Char.) và `Công thức`/`Formula`. `Operation` vẫn bắt buộc (file đã có cột). Bắt buộc thêm cột MIC long text (chế độ Chỉ Long text), Formula (Chỉ Formula) hoặc ít nhất 1 trong 2 (mặc định).
- Mỗi dòng có 2 phần độc lập (long text: C/M/S/E, formula: F/S/E) và thông báo riêng; ALV thêm cột Formula (file), Formula hiện có, Formula - thao tác. Dòng chỉ có formula (long text trống) vẫn được xử lý.
- Formula: chuẩn hoá (chữ hoa, gộp khoảng trắng); tham chiếu phải dạng `C` + 5 chữ số; Char. được tham chiếu phải có trong cùng operation; đã có formula giống file → bỏ qua, khác → chỉ ghi đè khi tick Overwrite. Ghi bằng `INSPECTION_CHARACTERISTICS` + `_X` (`FORMULA_IND`, `FORMULA_CHECK_BY_SAP`, `FORMULA_FIELD_1/2`), cùng lần gọi BAPI theo plan với long text.
- Tách 2 ô: cắt tại dấu cách cuối cùng trong 61 ký tự đầu, `FORMEL2` mở đầu bằng 1 dấu cách (đúng với cả 2 cách SAP nối ô). Dòng 87: ô 1 = `IF ( C07001 / 693 < C07002 / 139 ) THEN C07001 / 693 * 100`, ô 2 = ` ELSE C07002 / 139 * 100`; dòng 96: ô 1 dài 60 ký tự, ô 2 = ` 546.7 )`.
- Plan lỗi: gọi lại từng dòng, từng phần (long text / formula) để cô lập phần lỗi.

Đã kiểm: abaplint không có lỗi parser mới (chỉ `7bit_ascii` do chữ có dấu); logic tách formula và tham chiếu chạy thử offline trên 142 dòng (chỉ dòng 131 sai dạng).

**Đã đẩy lên SAP (01.11.2026, sau khi MCP kết nối lại)**: `UpdateObjectAtomic` trên DEV100 vào TR `DEVK901110` (Modifiable), active, 1.300 dòng, giống hệt file local (`ExportToFile` + diff, chỉ khác dấu xuống dòng cuối file); `DeployFromFile` qua được bước khoá + SyntaxCheck, lỗi 423 ở bước ghi như đã biết. Chạy thử trên DEV100 (`ExecuteABAP`, không ghi DB): tách formula dòng 87/96 đúng thiết kế, `C7001` bị báo sai dạng, header `Công thức` được nhận (`to_upper` ra `CÔNG THỨC`, `CP 'C*NG TH*C'` khớp).

**Chưa test**: ghi thật ở DEV300 (cần SAP GUI) – chạy "Chạy thử" = X rồi ghi thật; kiểm `QP02` plan `A2100277` Char. 7901 (Calculated characteristic + ô Formula) và 2 dòng formula dài (87, 96); đọc xlsx thật bằng `cl_fdt_xl_spreadsheet`.

## 12. Lỗi "Unable to load worksheet" (FDT_EXCEL_CORE005) – 01.11.2026

Triệu chứng: chạy `ZQM_PG_MIC_LONGTEXT` ở DEV300 với `BDP_Plan1000_InspPlan_CongThuc 1.xlsx` → báo `Unable to load worksheet`.

Nguyên nhân (tra source `CL_FDT_XL_SPREADSHEET`/`CL_FDT_DOC_PKG`, tái hiện bằng file xlsx dựng trong bộ nhớ trên DEV100): file do **openpyxl** tạo (ghi trong `docProps/core.xml`), khác file do Excel lưu (`BDP_Plan2000_...xlsx`):
1. `xl/_rels/workbook.xml.rels` có `Target="/xl/worksheets/sheet1.xml"` (tuyệt đối) → class ghép `xl/` + đường dẫn này nên không tìm thấy sheet → `E005`.
2. Mọi ô chuỗi là `t="inlineStr"`, gói không có `xl/sharedStrings.xml` → sau khi vá đường dẫn, sheet đọc được nhưng **tất cả ô rỗng** (đã tái hiện: 2 dòng × 3 cột toàn `[]`).

Cách xử lý:
- **File dùng ngay**: `CodeABAP/BDP_PCE/MIC_Long_text/BDP_Plan1000_InspPlan_CongThuc_SAP.xlsx` – tạo từ file gốc bằng script (đổi Target thành tương đối, đổi 1.438 ô `inlineStr` thành shared strings – 332 chuỗi duy nhất, thêm `sharedStrings.xml`, relationship và content-type). Nội dung ô, định dạng, filter giữ nguyên, đã so từng ô với bản gốc (giống hệt). Dòng 131 vẫn là `C7001` (chương trình sẽ báo lỗi dòng này).
- **Chương trình**: thêm FORM `NORMALIZE_XLSX` + `INLINE_TO_SHARED`, gọi ngay sau khi upload; tự đổi Target tuyệt đối và ô `inlineStr` về dạng Excel lưu (file do Excel lưu không bị đổi gì; lỗi khi chuẩn hoá thì bỏ qua để class tự báo như cũ). Thuật toán đã kiểm trên DEV100 với file giả lập có xuống dòng trong ô, `&amp;`, `&lt;`, ô rỗng, ô số → đọc đúng 100%. Đã đẩy lên SAP DEV100 (active, giống file local 1.465 dòng).
- Cách thủ công nếu gặp file khác lạ: mở trong Excel rồi Save.
