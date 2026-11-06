# QCM_UPG – ZCL_EXCEL_READER_2007: sửa 28 finding ATC (local, 06.11.2026)

Thư mục: `CodeABAP/QCM_UPG/06_Source Code 20261022/Class/zcl_excel_reader_2007/`
Chỉ sửa file local, **chưa đẩy lên DS4**, **chưa chạy lại ATC/SyntaxCheck** (repo chưa có server MCP cho DS4). Marker: `"SangVT modify|add|comment begin/end 06.11.2026 13:37:57`, code cũ được comment lại, BOM + CRLF giữ nguyên.

ATC không kèm số dòng → định vị bằng cách **đối chiếu số lượng thông điệp với số câu lệnh trong source**; 9 nhóm đều khớp đúng số lượng.

| # | Finding ATC (SLIN) | SL | Vị trí trong source | Cách sửa |
|---|---|---|---|---|
| 1 | Exception is not handled and is not declared in the RAISING clause | 1 | `LOAD_THEME` gọi `get_ixml_from_zip_archive` (raise ZCX_EXCEL) nhưng không khai RAISING | Thêm `RAISING ZCX_EXCEL` vào khai báo method (file class) |
| 2 | Slow parameter passing (string, VALUE, không đổi) | 1 | `LOAD_THEME` – `value(IV_PATH) type STRING` | Đổi sang truyền tham chiếu `IV_PATH type STRING` |
| 3 | Possible sequential read on a sorted table | 1 | `fill_row_outlines` – `LOOP ... WHERE outline_level >= ...` (khoá bảng là ROW) | `LOOP` + `CHECK` (vẫn quét hết bảng, cùng kết quả, cùng thứ tự) |
| 4 | Possible sequential read on a hashed table | 2 | `resolve_referenced_formulae` – 2 vòng `LOOP ... WHERE ref <> / = space` (khoá hashed là sheet/row/column) | `LOOP` + `CHECK` như trên |
| 5 | Exception handling for CX_.. is empty | 2 | `load_drawing_anchor` – 2 × `CATCH cx_root.` rỗng quanh `emu2pixel` | Thu hẹp thành `cx_sy_arithmetic_error ##NO_HANDLER` (emu2pixel chỉ có thể tràn số) + comment lý do |
| 6 | Exception of category CX_STATIC_CHECK not handled | 10 | 10 × `CATCH zcx_excel.` rỗng chưa có pragma: `resolve_referenced_formulae` 4, `load_worksheet` 5, `load_workbook` 1 (2 chỗ đã có `"#EC NO_HANDLER` thì không bị báo → xác nhận cơ chế) | Thêm `##NO_HANDLER` (giữ nguyên hành vi "bỏ qua lỗi" theo thiết kế abap2xlsx, comment giải thích đã có sẵn) |
| 7 | Function module exception not handled | 5 | `SCMS_BINARY_TO_XSTRING` ×2 (`read_from_applserver`, `read_from_local_file`); `TRINT_SPLIT_FILE_AND_PATH` ×3 (`load_workbook`, `load_worksheet`, `load_worksheet_drawing`) | Thêm `EXCEPTIONS` + kiểm `sy-subrc` → `zcx_excel=>raise_text` (SCMS: `failed = 1 OTHERS = 2`; TRINT: `OTHERS = 1`) |
| 8 | Text element missing in a character string | 2 | 2 × `'A problem occured when reading the file'(001)` | Gán 1 lần đầu method + `##NO_TEXT` (**chỉ ẩn cảnh báo**, xem lưu ý) |
| 9 | The REGEX standard POSIX is obsolete | 4 | `resolve_path` 1, `load_worksheet` 2, `load_workbook` 1 (`FIND`/`REPLACE REGEX`) | Đổi `REGEX` → `PCRE`; pattern giữ nguyên (không có alternation, kết quả POSIX/PCRE như nhau) |

## Lưu ý / việc còn lại
- **Text element (#8)**: `##NO_TEXT` chỉ tắt cảnh báo. Gốc rễ có thể là text pool 001 chưa có theo ngôn ngữ logon của ATC → muốn dứt điểm thì nhập text 001 trong SE24 (Goto → Text elements) cho ngôn ngữ cần dùng.
- **Hành vi thay đổi có chủ đích**: nếu `SCMS_BINARY_TO_XSTRING`/`TRINT_SPLIT_FILE_AND_PATH` lỗi thì nay raise `ZCX_EXCEL` (trước đây dump vì exception FM không bắt). `LOAD_THEME` nay khai báo `RAISING ZCX_EXCEL` (chỉ `load_workbook` gọi, đã có RAISING).
- **Local class `LCL_*ZIP_ARCHIVE`** (include CCIMP của class) **không có trong bản extract** → nếu ATC còn finding nằm ở đó thì chưa sửa được từ file local.
- Số liệu "28" là số dòng dán; đối chiếu bằng cách đếm câu lệnh, **chưa xác nhận bằng ATC chạy lại** → cần chạy lại ATC cho `ZCL_EXCEL_READER_2007` sau khi đẩy lên DEV (cần user đồng ý trước khi ghi lên hệ thống).
- Các cảnh báo abaplint trong IDE (CR, non-ASCII, whitespace cuối dòng, "Unknown object type") là của định dạng file extract, có từ trước, không do lần sửa này.
