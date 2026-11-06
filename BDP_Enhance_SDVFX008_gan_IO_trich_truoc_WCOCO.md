# BDP — SDVFX008: gán IO cho dòng trích trước của Condition Contract (WCOCO)

Nguồn: `CodeABAP/BDP/Enhance/BIDIPHAR_TKCN_SD_SDVFX008_GanIO_TrichTruoc_WCOCO_V1.0.docx` (v1.0, 07.10.2026, 8 lần điều chỉnh).
Code local: `CodeABAP/BDP/Enhance/SDVFX008_GanIO_WCOCO/src/`.
Đối chiếu hệ `GUI_BIDIPHAR_DEV100` (DEV, client 100, release 816, HANA). Cập nhật 06.11.2026.

## 1. Quyết định 06.11.2026 (chốt theo anh Dương)

| Câu hỏi | Anh Bình | Anh Dương (**chốt**) | Hệ quả cho enhance |
|---|---|---|---|
| Có làm Segment / BA không? | Cho rằng đã có khi trích trước; final settlement cần Segment/BA đồng nhất, đề xuất lấy theo Sales org | Segment đã có lúc hạch toán; enhance **chỉ thêm IO** vào dòng hạch toán | **Bỏ toàn bộ phần Segment**: khối Segment trong include, BAdI `WLF_ACC_ENHANCEMENT_EXT`, class `ZCL_WLF_ACC_SEGMENT`, SE19 impl |
| Final settlement | — | Không có final settlement bằng WCOCO; WCOCO chỉ **đảo trích trước**. Final settlement sinh **SO giảm trừ** → Segment = Sales org = BA và gán IO | Phần SO giảm trừ **ngoài enhance này**: anh Dương tự loại trừ không cho phát sinh condition type ZRA* ở SO giảm trừ → exit không có gì để xử lý, không cần làm gì thêm |
| Tài khoản 6321000001 / 3350000199 | Hardcode hay theo Account key? | Theo **VKOA**, enhance không tác động | Code đã không hardcode tài khoản (so với `CKOMV-SAKN1/SAKN2`); không cần tài khoản COAO từ kế toán cho code |

## 2. Phạm vi còn lại

| # | Hạng mục | Cách làm | Loại | Trạng thái |
|---|---|---|---|---|
| 1 | Gán IO trên chứng từ Billing | Include `ZXVVFU08` (exit `EXIT_SAPLV60B_008`, SDVFX008): XACCIT → CKOMV (KNUMH, KRUEK, SAKN1/2) → KONH-CCNUM → WCOCOH-ASSIGNMENT → AUFK; chỉ dòng tài khoản loại P | Code | Local xong (bản chỉ IO); **chưa vào SAP** (xem mục 4) |
| 2 | IO trên chứng từ đảo trích trước (WB2R_SC) | Transfer Manager, không code: `VC_TMTR` (event 71, group ZZ, `WCOCOH-ASSIGNMENT` → `KOMZRPE-AUFNR`, Replace) + `VC_TMFKTG` (loại settlement → event 71 → group ZZ) | Cấu hình | Chưa làm trên BDP; cần xác nhận loại chứng từ settlement |
| 3 | Tài khoản trích trước | VKOA (kế toán/FI quyết định) | Cấu hình | Ngoài enhance |
| 4 | Document Splitting | `V_T8G17`: tài khoản trích trước loại P phân loại 20000 Expense (nếu không Billing báo GLT2076) | Cấu hình | Chưa làm |
| 5 | Dữ liệu chủ | IO không gán Profit Center (KO02); WCOCO nhập Assignment = IO | Dữ liệu | — |
| 6 | Kiểm thử | Kịch bản 1–3 của TS (IO trên Billing, nhiều WCOCO trên 1 dòng, tài khoản P&L); kịch bản 4–8 liên quan Segment không còn trong phạm vi | Test | Chưa test (DEV100 chưa có WCOCO/cấu hình đầy đủ) |

## 3. Hiện trạng trên DEV BIDIPHAR (khác hệ làm TS)

TS làm trên hệ **S4S** (chart ACO, project CMOD `ZACG`). BDP DEV100 khác:

- `ZXVVFU08` có code của người khác (marker `CTQUYBV` 28.10.2026: ZTXT short text + điền TDV/ASM/RSM lên dòng công nợ 131*) và 2 lệnh `CHECK` giữa include → khối mới phải chèn **trước** `CHECK` đầu tiên, không dán đè.
- CMOD: SDVFX008 thuộc project **`ZBDP_FI`** (Active). `ZBDP_SD` có trong TR `DEVK901163` nhưng rỗng, chưa active.
- Exit nằm ở function group `XVVF`; `XACCIT`, `CKOMV` có header line → dùng `XACCIT[]`, `CKOMV[]`.
- Chart of accounts công ty 1000 = **COAO** (không có 3350000199, 6321000001, 338700000F, 511110101F trong SKA1).
- `T685`: có `ZRA1`; chưa thấy `ZRS1`, `ZAV1`, `ZKOF` (client 100 và 200). `WCOCOH`: client 100/300 rỗng, client 200 có 2 WCOCO. `TMFKTG` client 100 chỉ có cấu hình chuẩn `0C..`.

## 4. Trạng thái trên SAP DEV100 (TR `DEVK901163`, task `DEVK901164`, package `ZPK_BDP`)

| Object | Hiện trạng | Cần làm |
|---|---|---|
| Include `ZXVVFU08` | **Đã dán bản mới (chỉ IO)**, Active, sửa 06.11.2026 11:53:27 bởi CT.CSTECH; nội dung = `src/zxvvfu08.prog.abap`, không còn bản sao comment ở cuối (MCP không ghi được `PROG/I`: `package metadata not found`, nên user dán tay) | Xong |
| Class `ZCL_WLF_ACC_SEGMENT` | Đã tạo + activate, **không gán BAdI** nên không chạy. User quyết **giữ nguyên, không xoá** | Không tạo `ZEI_WLF_ACC_SEGMENT` / `ZBI_WLF_ACC_SEGMENT`. Gán BAdI sẽ làm dòng 6321000001 của chứng từ đảo trích trước nhận Segment theo Reference của WCOCO, trái quyết định bỏ Segment |
| CMOD `ZBDP_SD` trong TR | Rỗng, chưa active | User quyết định giữ hay bỏ; SDVFX008 vẫn ở `ZBDP_FI` |

Cách dán `ZXVVFU08`: SE38 hoặc Eclipse ADT → `ZXVVFU08` → Change → thay toàn bộ bằng nội dung `src/zxvvfu08.prog.abap` (= code `CTQUYBV` giữ nguyên + khối `"SangVT add begin/end 06.11.2026` trước `CHECK XACCIT[] IS NOT INITIAL AND CVBRP[] IS NOT INITIAL.`) → TR `DEVK901163` → Check → Activate. Đọc lại include live trước khi dán để chắc `CTQUYBV` chưa sửa thêm.

## 5. Điểm mở

- ~~SO giảm trừ của final settlement~~: **đã xong** (06.11.2026) — anh Dương tự tìm cách loại trừ không phát sinh condition type ZRA* ở SO này nên enhance không cần xử lý.
- IO trên chứng từ đảo trích trước (WB2R_SC) vẫn theo Transfer Manager (mục 2 dòng 2): xác nhận với anh Dương là vẫn cần.
- Assignment trống / IO sai / khác mã công ty thì không gán IO và **không báo lỗi** → TS đề xuất kiểm tra bắt buộc khi lưu WCOCO (cần KH xác nhận).
- IO đang là loại real: CO xác nhận real + settlement rule hay statistical.
- Huỷ Billing (VF11) cũng đi qua exit → chưa test.
- TS v1.0 cần cập nhật v1.1: bỏ chương Segment (7, 8, 10), nêu project `ZBDP_FI`, chart COAO, function group `XVVF`.

## 6. Code (bản chỉ IO) khác với TS

1. Viết thẳng logic cuối; bỏ khối comment lịch sử lần 2–6 và dòng code cũ bị comment.
2. Không `SELECT SINGLE` trong `LOOP` (chuẩn team): đọc theo lô bằng `INNER JOIN @itab` trước vòng lặp; billing không có điều kiện trích trước thì không đọc DB.
3. Số IO vẫn dùng `CONVERSION_EXIT_ALPHA_INPUT` như TS.

Kiểm cú pháp: `SyntaxCheck` MCP với include không đáng tin (code sai vẫn trả `null`) → bọc include vào FORM, gọi `SyntaxCheck` với URL program có sẵn `ZSD_RHR02A_FIXDATA`: **sạch lỗi**. Chưa chạy thật.
