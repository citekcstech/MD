# BDP — SDVFX008: gán IO / Segment cho dòng trích trước của Condition Contract (WCOCO)

Nguồn: `CodeABAP/BDP/Enhance/BIDIPHAR_TKCN_SD_SDVFX008_GanIO_TrichTruoc_WCOCO_V1.0.docx` (v1.0, 07.10.2026, 8 lần điều chỉnh).
Code local: `CodeABAP/BDP/Enhance/SDVFX008_GanIO_WCOCO/src/` (2 file, chưa đẩy lên SAP).
Ngày làm: 04.11.2026. Đã đối chiếu hệ `GUI_BIDIPHAR_DEV100` (DEV, client 100, release 816, HANA).

## 1. Tài liệu yêu cầu gì (rút gọn)

Billing có điều kiện trích trước ZRA1 lấy từ WCOCO → chứng từ kế toán phải có IO trên dòng trích trước; Segment mặc định theo WCOCO cho dòng chi phí; quyết toán WB2R_SC cũng phải có IO và Segment.

| # | Hạng mục | Cách làm trong TS | Loại |
|---|---|---|---|
| 1 | Gán IO trên chứng từ Billing | Include `ZXVVFU08` (exit `EXIT_SAPLV60B_008`, SDVFX008): XACCIT → CKOMV (KNUMH, KRUEK, SAKN1/2) → KONH-CCNUM → WCOCOH-ASSIGNMENT → AUFK | **Code** |
| 2 | Segment trên chứng từ Billing (tùy chọn) | Cùng include: WCOCOH-REFERENCE ∈ FAGL_SEGM → ACCIT-SEGMENT, chỉ dòng G/L Account (CKOMV-SAKN1 = 632) | **Code** |
| 3 | Segment trên chứng từ quyết toán WB2R_SC (tùy chọn) | BAdI `WLF_ACC_ENHANCEMENT_EXT` (spot `WLF_DOCUMENT_SPOT`), method `CHANGE_AFTER_SUMMARIZATION`, class `ZCL_WLF_ACC_SEGMENT` | **Code + SE19** |
| 4 | IO trên chứng từ quyết toán | Transfer Manager, không code: `VC_TMTR` (event 71, group ZZ, `WCOCOH-ASSIGNMENT` → `KOMZRPE-AUFNR`, Replace) + `VC_TMFKTG` (loại settlement ZS12 → event 71 → group ZZ) | Config |
| 5 | Tài khoản trích trước dạng P&L | VKOA ZKOF/ZS03/ZRU: G/L Account = 6321000001 (632), Accruals Acc. = 3350000199 (335, loại P, CElem category 1) | Config |
| 6 | Document Splitting | `V_T8G17`: tài khoản trích trước phân loại 20000 Expense (nếu không Billing báo lỗi GLT2076) | Config |
| 7 | Dữ liệu chủ | IO không gán Profit Center (KO02); WCOCO nhập Assignment = IO, Reference = mã Segment | Dữ liệu |
| 8 | Kiểm thử | 8 kịch bản (TS mục 4–9, 11) | Test |

## 2. Hiện trạng trên DEV BIDIPHAR (đã đọc, khác với hệ làm TS)

TS làm trên hệ **S4S** (chart ACO, project CMOD `ZACG`). BDP DEV100 khác:

- `ZXVVFU08` **đã có code của người khác** (marker `CTQUYBV` 28.10.2026: ZTXT short text + điền TDV/ASM/RSM lên dòng công nợ 131*) và có 2 lệnh `CHECK` giữa include → code mới phải chèn **trước** `CHECK` đầu tiên, nếu không bị bỏ qua khi billing không có SO/partner. Không được dán đè theo bước 3 của TS ("xoá toàn bộ nội dung").
- CMOD: SDVFX008 đã gán vào project **`ZBDP_FI`** (Active). Không có project `ZACG` → bỏ bước tạo/gán ZACG, chỉ cần đảm bảo ZBDP_FI vẫn Active.
- Exit nằm ở function group `XVVF` (không phải `XV60B`); tham số `XACCIT`, `XACCCR`, `CVBRP`, `CKOMV` (LIKE KOMV) có header line → dùng `XACCIT[]`, `CKOMV[]`.
- Interface `IF_WLF_ACC_ENHANCEMENT_EXT` có **25 method** (2 method `DEFAULT IGNORE`) → class phải có 23 method, TS chỉ nhắc 2.
- Chart of accounts công ty 1000 (Bidiphar) = **COAO**. SKA1 **không có** 3350000199, 6321000001, 338700000F, 511110101F. COAO có các tài khoản P `3352100099`…`3352500099` (nhóm 335).
- `T685`: có `ZRA1` (V); **chưa thấy** `ZRS1`, `ZAV1`, `ZKOF` (client 100 và 200).
- `WCOCOH`: client 100 và 300 rỗng; client 200 có 2 WCOCO (`1000000000`, `1000000001`, loại ZS02, Reference = Assignment = `1020000038` trên dòng 2).
- `TMFKTG` client 100 chỉ có cấu hình chuẩn `0C..`; chưa có ZZ/event 71.
- `FAGL_SEGM` client 100: `S1000`, `S1101`…`S1112`, `S4000`, `S6000`, `SEG_A`, `SEG_B` (không có `S001`, `S498` như TS).
- `ZCL_WLF_ACC_SEGMENT`, `ZEI_WLF_*` chưa tồn tại.
- Không có WCOCO/điều kiện đầy đủ để test ở DEV100 → **chưa test được chạy thật**.

## 3. Việc đã làm (local)

| File | Nội dung |
|---|---|
| `src/zxvvfu08.prog.abap` | Bản đầy đủ của include trên DEV (giữ nguyên code `CTQUYBV`) + khối `"SangVT add begin/end 04.11.2026` chèn trước `CHECK` đầu tiên. Khối Segment tách 3 chỗ bằng comment `[TUY CHON - SEGMENT THEO WCOCO] BAT DAU/KET THUC` (như TS mục 10) |
| `src/zcl_wlf_acc_segment.clas.abap` | Class BAdI mới (`" SangVT create`), logic = `ZCL_WLF_ACC_SEGMENT_v3` của TS, tách method nhỏ; 22 method còn lại để trống |

Khác với TS (cùng hành vi, khác cách viết):
1. Bỏ khối comment lịch sử lần 2–6 và dòng code cũ bị comment; viết thẳng logic cuối (TS v6 / class v3).
2. Không `SELECT SINGLE` trong `LOOP` (chuẩn team): đọc theo lô bằng `INNER JOIN @itab` trước vòng lặp; billing không có điều kiện trích trước thì không đọc DB.
3. Segment tra bằng join `FAGL_SEGM-SEGMENT = WCOCOH-REFERENCE` nên Reference dài hơn 10 ký tự không bị cắt rồi khớp nhầm (TS gán CHAR16 → CHAR10).
4. Số IO vẫn dùng `CONVERSION_EXIT_ALPHA_INPUT` như TS (template `ALPHA = IN` sẽ đệm theo độ dài 16 rồi cắt sai).

Kiểm tra: `SyntaxCheck` MCP với include không đáng tin (code sai vẫn trả `null`) → đã kiểm bằng cách bọc include trong FORM / class trong local class, chạy trong ngữ cảnh program có sẵn: **sạch lỗi**. Chưa chạy được thật (thiếu dữ liệu).

## 3b. Đã đẩy lên DEV100 (04.11.2026, TR `DEVK901163`, task `DEVK901164`, package `ZPK_BDP`)

| Object | Kết quả |
|---|---|
| Class `ZCL_WLF_ACC_SEGMENT` | **Đã tạo + activate.** Chưa có tác dụng cho đến khi gán BAdI ở SE19 |
| Include `ZXVVFU08` | **Chưa ghi được**: `UpdateObjectAtomic` / `EditSource` lỗi `package metadata not found` (bug ghi `PROG/I` qua MCP, đã có trong kho ghi chú team). Include trên SAP vẫn là bản cũ (đã đọc lại, không bị khoá) → **user dán tay** |

Cách dán `ZXVVFU08`: mở SE38 (hoặc Eclipse ADT) → `ZXVVFU08` → Change → thay toàn bộ bằng nội dung `src/zxvvfu08.prog.abap` (bản này = bản live + khối `"SangVT add begin/end`; hoặc chỉ chèn khối đó ngay trước dòng `CHECK XACCIT[] IS NOT INITIAL AND CVBRP[] IS NOT INITIAL.`) → gán TR `DEVK901163` → Check → Activate. Đọc lại include live trước khi dán để chắc CTQUYBV chưa sửa thêm.

TR `DEVK901163` còn chứa CMOD `ZBDP_SD` (rỗng, chưa active); SDVFX008 vẫn thuộc `ZBDP_FI` (Active). Muốn dùng `ZBDP_SD` thì phải chuyển SDVFX008 sang đó (một enhancement chỉ thuộc một project) và đảm bảo không làm mất exit đang chạy code `CTQUYBV`.

## 4. Việc còn phải làm

**Cần user quyết / cung cấp**
1. Dán tay `ZXVVFU08` như mục 3b (MCP không ghi được).
2. Có làm phần Segment (khối Segment + BAdI) không — TS ghi là tùy chọn, có thể bỏ khối/tắt impl.
3. Kế toán/FI: tài khoản BDP thực tế (COAO) thay cho 6321000001 / 3350000199, loại P, đã có Document Splitting; tên điều kiện giá thực tế (ZRS1/ZAV1/ZKOF có tạo mới không); loại chứng từ settlement (ZS12 hay loại khác của BDP).

**Làm tay / cấu hình (MCP không làm được)**
4. SE19: Enhancement Implementation `ZEI_WLF_ACC_SEGMENT` (spot `WLF_DOCUMENT_SPOT`), BAdI Implementation `ZBI_WLF_ACC_SEGMENT` trỏ class `ZCL_WLF_ACC_SEGMENT`, filter `WDTYP` ≠ rỗng.
5. Customizing theo mục 1 dòng 4–6 (VKOA, FS00, V_T8G17, VC_TMTR, VC_TMFKTG) + dữ liệu chủ IO/WCOCO; mỗi cấu hình 1 TR Customizing, transport cùng TR code.
6. Test 8 kịch bản trên client có dữ liệu WCOCO (client 200 đang có 2 WCOCO nhưng chưa có cấu hình điều kiện/tài khoản).

**Điểm TS còn mở (mục 12) + phát hiện thêm**
- Chỉ ZS03 đã đổi tài khoản; ZS01/ZS02/ZS51 (key 0R1, ZRU) vẫn dùng 338700000F → kế toán xác nhận.
- Assignment trống / IO sai / khác mã công ty thì không gán IO và **không báo lỗi** → TS đề xuất kiểm tra bắt buộc khi lưu WCOCO (cần KH xác nhận).
- IO đang là loại real: CO xác nhận real + settlement rule hay statistical.
- Huỷ Billing (VF11) và huỷ quyết toán (WAB_CANCEL_B) cũng qua exit/BAdI → chưa test, cần chạy trước UAT.
- Điều kiện Segment đang bám `CKOMV-SAKN1` (= G/L Account của VKOA). Nếu kế toán đổi lại hai cột VKOA phải đổi điều kiện trong cả include và class.
- Segment khác nhau giữa 2 dòng trích trước → Document Splitting sinh dòng Zero-Balance Clearing 1368888888 → kế toán xác nhận chấp nhận được.
- Reference ≥ 10 ký tự hoặc không phải mã Segment thì bỏ qua im lặng (đúng thiết kế); dữ liệu DEV200 hiện có Reference `1020000038` là kiểu này.
- Tài liệu TS có thể cần cập nhật theo hệ BDP (project ZBDP_FI, chart COAO, function group XVVF, 23 method class).
