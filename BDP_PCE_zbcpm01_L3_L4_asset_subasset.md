# BDP_PCE – ZBCPM01: chỉnh logic L3 Asset / L4 Sub-asset

Ngày: 02.11.2026 · Hệ: `GUI_BIDIPHAR_DEV100` (code), đọc data ở `GUI_BIDIPHAR_DEV300` (client 300).

## So sánh FS, code cũ và hệ thống

| Tag | FS V1.0 / V1.1 cũ | FS `V1.1 (1).docx` (mới) | Code cũ | Thực tế DEV300 |
|---|---|---|---|---|
| L3 Asset | `Z_EQ_ASSET` | `Z_ASSET`, class `Z_EQ` | `Z_EQ_ASSET` | `Z_ASSET` (ATINN 850, CHAR 12) |
| L4 Sub-asset | `Z_EQ_ASSET_NO` | `Z_ASSET_NO`, class `Z_EQ`, **hiển thị L3 – L4** | `Z_EQ_ASSET_NO` | `Z_SUBASSET` (ATINN 855, CHAR 4) |

- `CABN` ở client 100 và 300 không có `Z_EQ%` hay `%ASSET_NO` → code cũ cho L3/L4 luôn rỗng, tem in `—`.
- Class thực tế `Z_EQ` (CLINT 367, KLART 002). Code không lọc theo class nên không ảnh hưởng.
- `Z_ASSET` và `Z_SUBASSET` đều 1 giá trị (`ATEIN = X`): mỗi thiết bị tối đa 1 asset + 1 sub-asset.
- Ảnh mẫu nhãn trong FS mới: `Tài sản: 2110000045`, `Tài sản con: 2110000045-0001` → L4 in dạng `<Asset>-<Sub-asset>`.
- FS vẫn ghi độ rộng L3/L4 = 12, nhưng L4 hiển thị tới 17 ký tự. `ZPM_ST_AF_TEM-SUBASSET` là CHAR 60, form Adobe có caption "Tài sản:" / "Tài sản con:" (L4 tối đa 3 dòng) → không cần đổi DDIC/form.

## Dữ liệu mẫu – thiết bị 100314 (client 300)

| Bảng | Giá trị |
|---|---|
| `EQUI` | `EQTYP` M, `EQART` 117, tạo 31.10.2026 bởi CT.MFG |
| `EQKT` | `MÁY ĐÓNG GÓI SG1` (SPRAS E) |
| `EQUZ` | plant `1000`, `ILOAN` 3744, hiệu lực 01.01.2026 – 31.12.9999 |
| `ILOA` 3744 | `BUKRS` 1000, FL `BDP-K08`, `ANLNR`/`ANLUN` rỗng |
| `KSSK` | KLART 002, class `Z_EQ` |
| `AUSP` | `Z_ASSET` = `10000000`, `Z_SUBASSET` = `0001`, `Z_ENNAME` = PACKAGING MACHINE, `Z_PPID` = 1104A, `Z_USAGELIMIT` = 10000H |

`ANLA` và `ILOA` không có asset nào → `AUSP` là nguồn duy nhất.

## Đã sửa ở file local `zbcpm01.abap` (02.11.2026 08:29:29, marker `SangVT`)

1. Hằng số: `gc_atnam_ast = 'Z_ASSET'`, `gc_atnam_sub = 'Z_SUBASSET'` (dòng cũ comment lại).
2. `get_classification`: gom giá trị sub-asset vào bảng `lt_sub`, sau đó mỗi giá trị in `<Asset>-<Sub>`; nhiều sub ngăn cách `, `; không có Asset thì in riêng sub (đoạn cũ comment lại).
3. Chú thích đầu file cập nhật.

Kỳ vọng thiết bị `100314`: L3 `10000000`, L4 `10000000-0001`.

## Đã đẩy lên SAP (02.11.2026, user xác nhận)

- DEV100, TR `DEVK900344`: 4 lần `EditSource` (`syntax_check=true`), cả 4 activate thành công, không có message lỗi.
- Kiểm chứng: `ExportToFile` source từ SAP (824 dòng) `diff` với file local → giống hệt. `ZBCPM01` không nằm trong danh sách object chưa active.

## Còn lại
- Quyết định `Z_ASSET_NO` (FS) hay `Z_SUBASSET` (hệ): code đang dùng `Z_SUBASSET`. Muốn đúng FS thì tạo characteristic `Z_ASSET_NO` trong class `Z_EQ` hoặc đổi FS.
- Test ở client 300 bằng thiết bị `100314`.
