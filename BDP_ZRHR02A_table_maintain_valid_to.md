# BDP – ZRHR02A: khóa cột "Valid To", tự đóng dòng cũ khi thêm dòng mới

Ngày kiểm tra: 01.11.2026 – MCP `GUI_BIDIPHAR_DEV100` (client 100, user CT.CSTECH, On-Premise).

## 1. Kết quả kiểm tra hiện trạng

| Hạng mục | Giá trị |
|---|---|
| T-code | `ZRHR02A` (TRAN/T, package `ZPK_BDP`) |
| Bảng | **`ZTB_RHR02A`** (không có bảng tên `ZRHR02A`; `GetTable ZRHR02A` báo 404) |
| Delivery class / data maint. | `A` / `#ALLOWED` |
| Function group | `ZFG_RHR02A` (TABLEFRAME/TABLEPROC được sinh bởi generator) |
| Kiểu maintenance (TVDIR) | `TYPE = 1` (one-step), overview screen `0001`, **không có detail screen**, GENDATE 27.10.2026 |
| Event (TVIMF) | **Trống – chưa có event nào**, chưa có include `LZFG_RHR02AF01` |
| Include đã có | `LZFG_RHR02ATOP`, `LZFG_RHR02AT00` (chỉ code generator sinh) |
| Dữ liệu `ZTB_RHR02A` ở DEV client 100 | **Rỗng** |

Khóa bảng: `MANDT, VTWEG, PERNR, DATBI` (DATBI = "Valid To" nằm trong khóa).
Cột thường: `DATAB` (Valid From), `ASM`, `RSM`, `SUPPORT`, `ERNAM`, `ERDAT`, `AENAM`, `AEDAT`.

### Lưu ý

- Ảnh chụp màn hình là hệ **DEV/200**, còn MCP đang nối **DEV client 100** (bảng rỗng) → không đối chiếu được dữ liệu trong ảnh. Cấu trúc bảng/maintenance dùng chung giữa client (customizing cross-client), nhưng dữ liệu thì không.
- Cột Created By/On, Changed By/On trong ảnh trống vì chưa có event nào ghi các trường này.
- Ảnh cho thấy lỗi đang xảy ra với PERNR 00014024: dòng DATBI 31.12.2026 (từ 01.01.2026) và dòng DATBI 31.12.9999 (từ 01.10.2026) **chồng thời gian** – đúng thứ cần tự động đóng lại (dòng cũ phải kết thúc 30.09.2026).
- Không đọc được màn hình `SAPLZFG_RHR02A/0001` qua MCP (`D021S`/`D022S`: lỗi authorization check của datapreview) → việc khóa field trên screen phải làm tay ở SE51.

## 2. Yêu cầu

1. Cột **Valid To (DATBI)** không cho user sửa.
2. Thêm dòng mới → DATBI mặc định `31.12.9999`.
3. Dòng đang valid trước đó (cùng VTWEG + PERNR) → DATBI = **Valid From của dòng mới − 1 ngày**.
4. `ERNAM`, `ERDAT`, `AENAM`, `AEDAT` tự động điền người/ngày(giờ) tạo và thay đổi, user không sửa tay (bổ sung 01.11.2026).

Quy tắc điền (event 01, theo `<action>` của dòng trong TOTAL):

| Trường hợp | ERNAM / ERDAT | AENAM / AEDAT |
|---|---|---|
| Dòng mới (`N`, kể cả Copy Entries) | `sy-uname` / `sy-datum` (ghi đè giá trị user/copy) | để trống |
| Dòng sửa (`U`) | giữ nguyên của dòng gốc trong DB | `sy-uname` / `sy-datum` |
| Dòng cũ bị đóng (DATBI = Valid From mới − 1) | giữ nguyên | `sy-uname` / `sy-datum` |

**Bẫy:** `ZTB_RHR02A` chỉ có `ERDAT`/`AEDAT` (kiểu ngày), **không có trường giờ** (`ERZET`/`AEZET`). Nếu cần "giờ" phải thêm 2 trường vào bảng (xem câu hỏi 6 ở 4.3).

## 3. Vướng mắc kỹ thuật

- DATBI là **trường khóa** → không UPDATE trực tiếp được; muốn đổi DATBI của dòng cũ phải **DELETE dòng cũ + INSERT dòng mới với khóa mới** (trong cùng LUW với lần Save của SM30).
- Dòng mới mặc định DATBI = 31.12.9999 sẽ **trùng khóa** với dòng cũ nếu dòng cũ cũng đang là 31.12.9999 → phải xử lý dòng cũ trước khi INSERT dòng mới (thứ tự trong event 01: xóa/đổi khóa dòng cũ rồi mới để SM30 ghi dòng mới).

## 4. Phương án đề xuất

### 4.1 Khóa cột Valid To (làm tay, MCP không làm được)
SE51 → program `SAPLZFG_RHR02A`, screen `0001` → field `ZTB_RHR02A-DATBI` **và 4 field `ERNAM`, `ERDAT`, `AENAM`, `AEDAT`** → tích **Output only** (user chỉ xem; code event 01 vẫn ghi đè/điền giá trị để chặn trường hợp sửa tay).
(Hoặc SE54 → Environment → Modification → Maintenance Screens.) Lưu ý: generate lại table maintenance ở SE54 có thể ghi đè screen → ghi chú lại trong NOTES.

### 4.2 Code trong include mới `LZFG_RHR02AF01` (tạo bằng MCP sau khi bạn đồng ý)

| Event (TVIMF) | FORM | Việc làm |
|---|---|---|
| `05` Creating a new entry | `f_new_entry` | Gán `ztb_rhr02a-datbi = '99991231'` cho dòng mới |
| `01` Before saving | `f_before_save` | Với mỗi dòng mới (`<action> = 'N'`): ép DATBI = 31.12.9999, kiểm tra DATAB không rỗng; tìm dòng cũ cùng VTWEG+PERNR có `DATAB < DATAB mới <= DATBI`; nếu có → DELETE dòng cũ + INSERT lại với `DATBI = DATAB mới − 1`; điền ERNAM/ERDAT (dòng mới), AENAM/AEDAT (dòng cũ bị đóng) |

Đăng ký event: **SE54** → `ZTB_RHR02A` → Environment → Modification → **Events** → thêm dòng `05` + `01` với tên FORM và include `LZFG_RHR02AF01` (MCP không ghi được TVIMF an toàn).

### 4.3 Các tình huống cần chốt (câu hỏi cho user)

1. DATAB dòng mới **≤ DATAB dòng đang mở** (nhập lùi ngày, trước hoặc trùng ngày bắt đầu dòng cũ) → báo lỗi chặn Save hay cho qua? (đề xuất: **báo lỗi**).
2. "Dòng đang valid trước đó" = dòng **cover ngày DATAB mới** (DATAB cũ < DATAB mới ≤ DATBI cũ), hay chỉ dòng **DATBI = 31.12.9999**? (đề xuất: dòng cover ngày DATAB mới; không có thì bỏ qua).
3. Hai dòng mới cùng VTWEG+PERNR trong 1 lần Save → báo lỗi? (đề xuất: báo lỗi).
4. Có cần xử lý dữ liệu chồng lấp đã có (như ảnh PERNR 00014024) bằng script dọn riêng không?
5. Test ở client nào? Ảnh là DEV/200, MCP nối DEV/100.
6. "Ngày giờ" tạo/sửa: chỉ cần **ngày** (dùng `ERDAT`/`AEDAT` sẵn có, không đổi bảng) hay cần cả **giờ**? Nếu cần giờ → thêm `ERZET`, `AEZET` (kiểu `erzet`, kiểu giờ `TIMS`) vào `ZTB_RHR02A`, activate bảng, rồi **generate lại table maintenance ở SE54** để 2 cột hiện trên màn hình (generate lại có thể ghi đè screen đã chỉnh Output only → làm lại bước 4.1). Đề xuất: **chỉ ngày** nếu không bắt buộc giờ.

## 5. Việc tiếp theo (chờ user xác nhận)

- [ ] Xác nhận 4.3 + cho phép tạo include `LZFG_RHR02AF01` trên DEV (cần TR/package `ZPK_BDP`).
- [ ] User khóa field DATBI ở SE51 và đăng ký event ở SE54 (hoặc nhờ mình hướng dẫn từng bước).
- [ ] Test ở SM30/`ZRHR02A`: thêm dòng mới, kiểm tra dòng cũ đổi DATBI.

## 6. Cập nhật 01.11.2026 (thay thế các mục trên nếu mâu thuẫn)

- **Đối tượng maintenance thật là view `ZMV_RHR02A`** (T-code `ZRHR02A` = `SM30 VIEWNAME=ZMV_RHR02A;UPDATE=X`, screen `0002`, FG `ZFG_RHR02A`), không phải bảng (screen `0001`). Event đăng ký ở SE54 cho **`ZMV_RHR02A`**; screen cần khóa là `SAPLZFG_RHR02A/0002`.
- Bảng đã có thêm `ERZET`, `AEZET` (user thêm) → câu hỏi 6 = **cần cả giờ**. TR `DEVK900922` (task của request `DEVK900921`).
- Quyết định đã chốt (câu hỏi 1–3, 4.3): chặn Save nếu Valid From mới ≤ Valid From đã có; dòng cũ = dòng cover ngày Valid From mới; chặn 2 dòng mới cùng VTWEG + PERNR.
- **Bẫy framework:** event 05 chạy ngay trước check trùng khóa của SM30 → nếu PERNR đã có dòng đang mở (31.12.9999) thì dòng mới **không thể hiện sẵn 31.12.9999** (bị báo "entry already exists"). Code chỉ default 31.12.9999 khi khóa còn trống (PERNR chưa có dòng đang mở); còn lại Valid To để trống đến lúc Save rồi event 01 gán 31.12.9999 và đóng dòng cũ.
- Code: `CodeABAP/BDP/ZRHR02A/src/zfg_rhr02a.fugr.lzfg_rhr02af01.abap` (FORM `F_NEW_ENTRY`, `F_BEFORE_SAVE`, `F_UPDATE_TOTAL_ROW`); SyntaxCheck SAP trong ngữ cảnh FG sạch. Event 01: validate (Valid From bắt buộc, 2 dòng mới cùng khóa, Valid From ≤ dòng đã có, khóa sau khi đóng trùng dòng khác) → INSERT dòng cũ với DATBI = Valid From mới − 1 rồi DELETE khóa cũ → đồng bộ TOTAL/EXTRACT → gán ERNAM/ERDAT/ERZET (dòng mới), AENAM/AEDAT/AEZET (dòng sửa + dòng cũ bị đóng).
- **ADT không tạo được include `LZFG_RHR02AF01`** (`FUGR/I` không hỗ trợ; `PROG/I` bị chặn vì tên `L...` dành cho FG include). Chưa ghi gì lên SAP.

### Các bước tiếp theo

1. **SE54** → `ZMV_RHR02A` → Environment → Modification → **Events** → thêm `05` = `F_NEW_ENTRY`, `01` = `F_BEFORE_SAVE`; double-click tên FORM → tạo include `LZFG_RHR02AF01` (package `ZPK_BDP`, TR `DEVK900922`).
2. Báo lại → Claude ghi code vào include (`UpdateObjectAtomic`), activate, kiểm tra lại.
3. **SE51** `SAPLZFG_RHR02A` screen `0002`: tích **Output only** cho `DATBI`, `ERNAM`, `ERDAT`, `ERZET`, `AENAM`, `AEDAT`, `AEZET`; activate.
4. Test SM30/`ZRHR02A` trên DEV: (a) PERNR mới hoàn toàn; (b) PERNR đã có dòng đang mở, Valid From sau; (c) Valid From ≤ dòng đã có (phải bị chặn); (d) 2 dòng mới cùng PERNR (phải bị chặn); (e) sửa ASM/RSM/Hỗ trợ BH ở dòng cũ (AENAM/AEDAT/AEZET đổi).
5. Dữ liệu chồng lấp sẵn có (PERNR 00014024 ở client 200) cần script dọn riêng nếu user muốn.

## 7. Cập nhật 01.11.2026 (sau) — code đã lên DEV100, sửa dữ liệu DEV200

- Include `LZFG_RHR02AF01` đã có trên SAP, trùng file local, đã active; event `01`/`05` đã đăng ký (`TVIMF`). Cross-client nên client 200 dùng ngay.
- Dữ liệu `ZTB_RHR02A` ở DEV200 (24 dòng): 1 dòng khóa rỗng; `00014024` 1 dòng (01.01.2026–31.12.2026); 11 PERNR (10001001, 10001002, 10001003, 10001004, 10001100, 10001101, 10001103, 10001200, 10001300, 18000017, 18000018) mỗi PERNR 1 dòng đúng (01.10.2026–31.12.9999) + 1 dòng **đảo Valid From/Valid To** trùng hệt ASM/RSM/Hỗ trợ BH; audit trống toàn bộ.
- MCP không ghi được dữ liệu client 200 → report `ZSD_RHR02A_FIXDATA` (package `$TMP`, không TR, đã activate), chạy ở SE38 trong client 200; mặc định **chạy thử**. Kết quả mô phỏng: 24 dòng → 12 dòng (xóa 1 dòng rỗng + 11 dòng đảo ngày); `00014024` thành 01.01.2026–31.12.9999; audit điền người chạy + giờ hiện tại.
- **Đổi khóa 12:20 (01.11.2026):** user đổi khóa `ZTB_RHR02A` thành `MANDT, VTWEG, PERNR, DATAB` (DATBI không còn trong khóa). Save dòng mới `00014024` (Valid From 01.11.2026) báo "Không đóng lại được dòng cũ…" vì event 01 bản cũ `INSERT` khóa mới + `DELETE` khóa cũ → khóa mới của dòng đã đóng trùng dòng cũ (cùng DATAB). Đã sửa include: event 05 luôn default 31.12.9999; event 01 đóng dòng cũ bằng `UPDATE` DATBI/AENAM/AEDAT/AEZET trực tiếp; message tiếng Việt có dấu. DB không bị thay đổi dở.
- **Việc user cần làm sau đổi khóa:** (1) SE11 activate lại view `ZMV_RHR02A`, bảo đảm `DATBI` không là field khóa (DD27S đang vẫn đánh khóa); (2) SE54 sinh lại maintenance cho `ZMV_RHR02A` (include `LZFG_RHR02AF00` đang `WHERE … DATBI =` theo khóa cũ); (3) kiểm lại Output only ở screen `0002` và event `01`/`05` (`TVIMF`); (4) test lại SM30.
- Giả định cần user xác nhận: dòng đảo ngày = bản sao thừa của dòng đúng (trùng ASM/RSM/Hỗ trợ BH) nên xóa; dòng cuối mỗi PERNR = 31.12.9999 (bỏ chọn `P_OPEN` nếu `00014024` thật sự kết thúc 31.12.2026); xóa dòng khóa rỗng (`P_DELB`).
