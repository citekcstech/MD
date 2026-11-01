# BDP — Thêm cấu hình T321 cho MM mvt 561 / 562 (DEV100, client 100)

Ngày: 01.11.2026 · Server: `GUI_BIDIPHAR_DEV100` · Nguồn: `CodeABAP/BDP/T321/BDP_-SPE-V_T3211.XLSX`

## Hiện trạng đã kiểm (chỉ đọc)

- File backup là export của view bảo trì **`/SPE/V_T3211`** (function group `/SPE/GEN_CUST`) — view trên bảng **`T321`**
  ("Assignment MM Movement Type → MM-WM Movement Type"), delivery class E.
- Trường của view: `LGNUM, RBLVS, BSLVS, KZBEW, SOBKZ, BSSKZ, LGREF, LFART, SPE_FOLAR`.
  **Không có** `BWLVS, BESTQ, TBFKZ, WEDKZ, UBFKZ, TAFKZ, WENUM, BSTQE, MAILK, KUNWE, LIFNR`.
- File: 906 dòng, toàn bộ `LGNUM = ***`. T321 client 100: 884 dòng. Bỏ 22 dòng `RBLVS` 561/562 khỏi file thì
  khớp hệ 100% (DOG 427, DIG 356, DTR 98, LB 3) → file = hệ hiện tại + đúng 22 dòng cần thêm.
- `T321` ở client 100 hiện **chưa có** dòng nào với `RBLVS` = 561 hoặc 562. Không có khóa trùng trong file.
- Mapping cột Excel → field: `RefMvtType WM = RBLVS`, `Special stock indic. = BSLVS`, `Movement indicator = KZBEW`,
  `Special Stock = SOBKZ`, `Special movement = BSSKZ`, `Storage loc. ref = LGREF`, `Delivery Type = LFART`, `Subseq.Deliv.Type = SPE_FOLAR`.

## 22 dòng cần thêm (LGNUM `***`, BSLVS/KZBEW/BSSKZ/LGREF/SPE_FOLAR để trống)

| RBLVS | LFART | SOBKZ (11 dòng) |
|---|---|---|
| 561 | DIG | (trống), B, C, E, F, I, J, K, M, Q, R |
| 562 | DOG | (trống), B, C, E, F, I, J, K, M, Q, R |

## Điểm cần quyết định / lưu ý

- Các cột ngoài view (BWLVS...) **file không có** → mặc định để trống (giống nhập qua SM30 `/SPE/V_T3211`).
  Mẫu gần nhất đang có: `RBLVS 563` → `BWLVS 561`, `LFART DIG`; `RBLVS 564` → `BWLVS 562`, `LFART DOG`;
  `BESTQ = Q` với `SOBKZ` trống/E/K/Q. WM mvt 561/562 có trong T333 ở LGNUM `001` và `MLO`.
- Client 100 là **Customizing** (`T000`: `CCCATEGORY = C`, `CCCORACTIV = 1` = tự ghi TR khi sửa qua SM30).
  Ghi thẳng DB bằng `ExecuteABAP` **không sinh TR** → QAS/PRD không nhận.

## Quyết định của user và kết quả (01.11.2026)

- Cột ngoài view: **để trống như file**. Cách ghi: **INSERT + gắn TR Customizing mới** (package `ZPK_BDP`).
- Đã tạo TR **`DEVK901116`** `SangVT_IMG_T321_01.11.2026_Add mvt 561/562 /SPE/V_T3211`, task Customizing `DEVK901117`
  (tên theo quy ước mô tả TR của team: `<Người>_<Module>_<ngày>_<nội dung>`; có thể đổi ở SE09).
- Thử mô phỏng (`harmless`, FM `TR_APPEND_TO_COMM_OBJS_KEYS`, `wi_simulation = X`): request → lỗi `TK 127`, task → `subrc = 0`.
- Ghi thật (`ExecuteABAP` `dangerous`): gắn 22 khóa `R3TR TABU T321` vào task `DEVK901117` → `INSERT t321 FROM TABLE` → `COMMIT WORK`;
  kết quả tự báo `insert subrc=0 dbcnt=22 tr-append subrc=0`.
- **Đã kiểm lại độc lập**: `RunQuery` thấy đủ 22 dòng (561 → DIG, 562 → DOG, 11 `SOBKZ` mỗi mvt, các cột còn lại trống, `BWLVS = 000`);
  tổng `LFART` toàn bảng = DOG 438 / DIG 367 / DTR 98 / LB 3 = 906 dòng, khớp 100% file backup;
  `GetTransport` thấy `R3TR TABU T321` trong task; `E071K` của task có 22 khóa.
- Việc còn lại cho user: kiểm tra (SM30 `/SPE/V_T3211` hoặc `SE16N T321`) → **release TR `DEVK901116`** (SE09) rồi import sang QAS/PRD.
  `BWLVS = 000` là giá trị khởi tạo NUMC, giống khi nhập tay qua SM30.
- Kỹ thuật gắn TR cho nội dung bảng Customizing qua MCP đã ghi vào `.claude/skills/sap-mcp-gui/reference/_ghichu_mcp_gui.md` (section 1).
