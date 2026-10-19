# APA PRD800 — KKML3: thêm cột Cost Component vào template (yêu cầu chị Phụng)

- Hệ thống: APA PRD, client 800 (MCP `GUI_APA_PRD800`)
- Ngày kiểm tra: 19.10.2026
- Cách kiểm tra: đọc DDIC + bảng cấu hình qua MCP (client 800 nên được phép SELECT). Chưa ghi/sửa gì lên hệ thống.

## 1. Yêu cầu

Chị Phụng muốn vào Tcode **KKML3** của APA để edit template, bổ sung các cột **cost component chi tiết**. Chị vào KKML3 không thấy thông tin và hỏi có chỗ nào bật cấu hình không.

## 2. Kết luận ngắn

| # | Câu hỏi | Kết luận |
|---|---------|----------|
| 1 | KKML3 sửa template được không? | **Không.** KKML3 = *Display Drilldown Report* (chỉ xem). Sửa report dùng **KKML2**, sửa form (template cột) dùng **KKML5**. Màn hình trong ảnh là KKML4 (Create Form). |
| 2 | Sao vào không thấy thông tin? | Trong PRD 800 chỉ có **1 report** (`01MLREPORT`) và **1 form** (`01ML_FORM`), cả hai là bản chuẩn SAP. Không có report/form Z nào. Phải nhập đúng tên mới hiện nội dung. |
| 3 | Có chỗ bật cấu hình không? | **Không có công tắc nào để bật.** Vấn đề không nằm ở cấu hình mà ở dữ liệu nguồn (mục 4). |
| 4 | Thêm cột cost component vào form được không? | **Không được bằng form thuần.** Bảng nguồn của drilldown ML (`KKBML`) không có field cost component, và không thể append thêm field (mục 4). |

## 3. Số liệu đã kiểm tra

### 3.1 Tcode KKML* (bảng TSTC / TSTCT)

| Tcode | Chức năng | Program |
|-------|-----------|---------|
| KKML0 | Run Drilldown Report | SAPMKCEE (dynpro 0500) |
| KKML1 | Create Drilldown Report | SAPMKCEE (dynpro 1125) |
| KKML2 | Change Drilldown Report | SAPMKCEE (dynpro 0500) |
| **KKML3** | **Display Drilldown Report** | SAPMKCEE (dynpro 0500) |
| KKML4 | Create Form | SAPMKES1 (dynpro 0100) |
| KKML5 | Change Form | SAPMKES1 (dynpro 0200) |
| KKML6 | Display Form | SAPMKES1 (dynpro 0200) |
| KKML7 | Maintain Key Figures | RKDKENNZ (gọi KCK0) |

### 3.2 Report và form của application class `KKML` (TKEB1, TKES1)

| Loại | Tên | Bảng dữ liệu | Tạo | Sửa gần nhất | Auth group |
|------|-----|--------------|-----|--------------|------------|
| Report | `01MLREPORT` | KKBML | 08.12.2011 (SAP) | 31.05.2013 (SAP) | N12 |
| Form | `01ML_FORM` | KKBML | — | 31.05.2013 (SAP) | — |

- Form **`ZMLFROM`** (ảnh chụp màn hình, mô tả "ML Template: Form Z1") **không có trong TKES1 client 800**. Nghĩa là form này chưa được lưu, màn hình trong ảnh chỉ là đang tạo mới.
- Không có report/form Z nào của KKML trong PRD 800.

## 4. Vì sao không thêm được cột cost component

1. Popup *Key figures 6 Entries* trong ảnh khớp đúng 6 field số của structure **`KKBML`** (Drilldown Structure Material Ledger/Actual Costing):

   | Key figure | Mô tả trong popup |
   |------------|-------------------|
   | BEWER | Prelim. valuation |
   | MENGE | Quantity |
   | PABWE_E | 1-level price diff. |
   | PABWE_M | Multilevel price dif |
   | KABWE_E | Sing-lev.ExchRateDif |
   | KABWE_M | Multil. ExchRateDiff |

2. `KKBML` **không có field cost component** (không có KST001…KST040 hay tương đương). Các field còn lại chỉ là characteristic (MATNR, WERKS, BUKRS, BWKEY, POPER, BDATJ, PSPNR, ...) và 5 field `CUST01..CUST05` kiểu CHAR (không phải số tiền nên không dùng làm key figure được).
3. `KKBML` có annotation `@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE` → **không append thêm field** được. KKML7 (Maintain Key Figures) cũng chỉ cấu hình key figure dựa trên field có sẵn của KKBML.
4. Dữ liệu cost component split của Material Ledger nằm ở bảng khác, và **trên PRD 800 chỉ có bản "for Prices" chứa dữ liệu**:

   | Bảng | Nội dung | Số dòng PRD 800 |
   |------|----------|-----------------|
   | `CKMLPRKEKO` | Header split theo giá | 2.208.634 |
   | `CKMLPRKEPH` | Elements split theo giá (KST001…KST040) | có dữ liệu, ~18.000–18.600 dòng/kỳ trong 2026 |
   | `CKMLKEKO` / `CKMLKEPH` | Split theo giá trị kỳ (Schichtung) | **0 dòng (rỗng)** |

   Drilldown report KKML không đọc các bảng này. Xem ví dụ 1 cột ở mục 8.

## 5. Có thể chị Phụng "không thấy thông tin" vì (chưa kiểm chứng)

- Chưa nhập tên report khi vào KKML3: chỉ có `01MLREPORT` để chọn.
- Report/form có **authorization group N12**. Hệ thống có các authorization object cho drilldown (`K_KA_RPT` cho report, `K_KA_RCS` cho row/column structure). **Chưa kiểm tra role/quyền của chị Phụng** nên chưa kết luận được thiếu quyền hay không. Cách kiểm tra nhanh: chị Phụng vào KKML3, nếu báo thiếu quyền thì chạy SU53 ngay sau đó.

## 6. Hướng xử lý đề xuất

1. **Hỏi lại chị Phụng** nhu cầu cụ thể trước khi làm: cột cost component muốn xem theo giá nào (price determination / actual period), cấp độ nào (material – plant – period), và dùng để làm gì (đối chiếu, báo cáo định kỳ...).
2. Hướng làm khả thi cho nhu cầu "cột cost component chi tiết": **viết report Z (ABAP/ALV)** đọc `CKMLPRKEPH` + `CKMLPRKEKO` (kết hợp `CKMLHD` để ra material, `CKMLCR` để đối chiếu giá). **Không đọc `CKMLKEPH`/`CKMLKEKO` vì rỗng trên PRD 800.** Không đi theo hướng sửa form KKML vì nguồn không có dữ liệu. Ví dụ 1 cột ở mục 8.
3. Nếu chị chỉ cần xem tạm số liệu cost component của từng material, có thể dùng màn hình chuẩn của ML (ví dụ CKM3). **Chưa kiểm chứng** màn hình/menu cụ thể trên APA, cần mở thử trước khi hướng dẫn chị.
4. Nếu vẫn muốn dùng KKML cho các key figure hiện có: dùng **KKML5** để tạo/sửa form (copy từ `01ML_FORM`, đặt tên Z), **KKML2** để tạo/sửa report gắn form đó.

## 7. Chưa làm / việc còn mở

- Chưa kiểm tra quyền của chị Phụng (role, auth object `K_KA_RPT`/`K_KA_RCS`, group N12).
- Chưa xác nhận trên giao diện SAP các bước dùng CKM3 để xem cost component.
- Chưa tạo/sửa bất kỳ object nào trên hệ thống. Report Z (nếu làm) cần user đồng ý trước khi tạo.
- Chênh lệch tổng split và giá kỳ chưa giải thích được (mục 8, bước 5).

## 8. Ví dụ xử lý 1 cột: "NVL chính" (cost component 001)

Mọi bước dưới đây chỉ là đọc dữ liệu PRD 800, chưa tạo object nào.

### Bước 1 — Xác định cột là gì trong hệ thống

- APA dùng cost component structure **Z1** (bảng `TCKH1`/`TCKH3`, 9 thành phần). Structure `01` (chuẩn SAP, tiếng Anh) cũng còn nhưng dữ liệu split trong `CKMLPRKEKO` đều dùng `ELEHK = Z1`.
- Cột "NVL chính" là cost component **001** của structure Z1 → field **`KST001`** trong `CKMLPRKEPH`.

| ELEMT | Field | Tên cột (TCKH1, structure Z1) |
|-------|-------|-------------------------------|
| 001 | KST001 | NVL chính |
| 002 | KST002 | NVL phụ, tá dược |
| 003 | KST003 | Bao bì |
| 004 | KST004 | Nhân công trực tiếp |
| 005 | KST005 | Nhân công gián tiếp |
| 006 | KST006 | Chi phí khấu hao |
| 007 | KST007 | Điện |
| 008 | KST008 | Chi phí SX chung |
| 009 | KST009 | Tài khoản trung gian |

Quy ước ánh xạ `ELEMT nnn → KSTnnn` là suy ra từ tên field và từ dữ liệu (số liệu khớp với `STPRS` ở bước 5). Chỉ mới đọc KST001–KST009; chưa kiểm tra KST010–KST040 và chưa đối chiếu với tài liệu SAP.

### Bước 2 — Tìm bảng chứa số liệu của cột đó

- `CKMLKEPH.KST001` rỗng (bảng 0 dòng) → bỏ.
- `CKMLPRKEPH.KST001` có dữ liệu (kỳ 2026/009: 18.632 dòng, PRTYP S và V, CURTP 10 = tiền tệ công ty, WAERS = VND).

### Bước 3 — Xác định khóa và các điều kiện lọc

Key của `CKMLPRKEPH`: `MANDT, KALNR, BDATJ, POPER, UNTPER, KEART, PRTYP, KKZST, PATNR, DIPA, CURTP`.

| Điều kiện | Ý nghĩa | Giá trị dùng cho ví dụ |
|-----------|---------|------------------------|
| `BDATJ`, `POPER` | Năm, kỳ | 2026, 009 |
| `UNTPER` | Value type | 000 |
| `PRTYP` | S = split của giá chuẩn, V = split của giá kỳ (periodic unit price) | V |
| `KKZST` | rỗng = lũy kế mọi cấp, `X` = riêng cấp này | rỗng |
| `CURTP` | Loại tiền (10 = tiền công ty) | 10 |
| `KALNR` | Số định giá của material | tra qua `CKMLHD` |

### Bước 4 — Ra material (nối `CKMLHD`)

`CKMLHD` cho `KALNR → MATNR, BWKEY, BWTAR`. Ví dụ: `KALNR 000100014818` → material `51001251`, plant (valuation area) `2000`, không có valuation type.

### Bước 5 — Số liệu thực tế và đối chiếu

Material `51001251`, plant `2000`, kỳ 2026/009, CURTP 10 (VND), đơn vị tính `GOI`, `LOSGR` = 1:

| Cột | PRTYP S (giá chuẩn) | PRTYP V, KKZST rỗng (giá kỳ, lũy kế) | PRTYP V, KKZST X (riêng cấp này) |
|-----|---------------------|---------------------------------------|----------------------------------|
| **NVL chính (KST001)** | **1.270,70** | **645,53** | 645,53 |
| NVL phụ (KST002) | 0 | 0 | 0 |
| Bao bì (KST003) | 0 | 292,05 | 292,05 |
| Nhân công trực tiếp (KST004) | 0 | 0 | 0 |
| Nhân công gián tiếp (KST005) | 0 | 53,71 | 53,71 |
| Chi phí khấu hao (KST006) | 0 | 0 | 0 |
| Điện (KST007) | 0 | 73,82 | 29,72 |
| Chi phí SX chung (KST008) | 0 | 73,82 | 29,72 |
| Tài khoản trung gian (KST009) | 0 | 77,81 | 31,32 |

Đối chiếu với `CKMLCR` cùng kỳ: `STPRS` = **1.270,70**, `PVPRS` = **1.210,19**, `PEINH` = 1.

- Giá chuẩn: tổng split S = 1.270,70 = `STPRS` → **khớp**. Điểm đáng chú ý: toàn bộ giá chuẩn nằm hết ở 1 cột KST001 (NVL chính), các cột còn lại bằng 0. Nghĩa là giá chuẩn của material này không có phân tích chi tiết.
- Giá kỳ: tổng 9 cột split V (KKZST rỗng) = 1.216,74 so với `PVPRS` = 1.210,19, **lệch 6,55**. **Chưa giải thích được nguyên nhân**, cần hỏi lại bên Controlling hoặc đối chiếu thêm nhiều material trước khi dùng số này để đối chiếu.

### Bước 6 — Cột này nằm vào đâu trong một report

Nếu làm report Z cho chị Phụng, cột "NVL chính" lấy như sau (mô tả, chưa viết/tạo code):

| Thành phần | Nguồn |
|------------|-------|
| Material, plant | `CKMLHD` (`MATNR`, `BWKEY`) qua `KALNR` |
| Tên cột (header) | `TCKH1-TXELE` (`SPRAS` = 'E' đã kiểm tra, ngôn ngữ khác chưa kiểm tra; `ELEHK` = `CKMLPRKEKO-ELEHK`, `ELEMT` = 001) |
| Giá trị cột | `CKMLPRKEPH-KST001` (có thể nhân `LOSGR` nếu cần giá trị thay vì giá đơn vị, cần chốt với Controlling) |
| Tiền tệ | `CKMLPRKEPH-WAERS` |
| Đối chiếu tổng | `CKMLCR-PVPRS` / `STPRS` |

Mở rộng thêm cột khác (NVL phụ, Bao bì, ...) chỉ là lấy thêm `KST002`, `KST003`... cùng một dòng, không cần join thêm bảng.

### Bước 7 — Còn cần chốt với chị Phụng

1. Lấy theo **giá chuẩn (S)** hay **giá kỳ (V)**? Với dữ liệu trên, giá chuẩn gần như không có phân tích (toàn bộ dồn vào NVL chính).
2. Lũy kế (`KKZST` rỗng) hay riêng cấp (`KKZST` = X)?
3. Hiển thị giá đơn vị hay giá trị (nhân số lượng tồn/số lượng kỳ)?
4. Báo cáo theo kỳ nào, plant nào, có cần dòng tổng không?
