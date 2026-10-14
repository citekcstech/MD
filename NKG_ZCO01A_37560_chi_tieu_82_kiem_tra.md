# NAMKIM #37560 – ZCO01A – Kiểm tra logic chỉ tiêu 82

| | |
|---|---|
| **Chỉ tiêu** | 82 – SL nhập thu hồi Thép cán nóng PO (Group 51\*) |
| **Báo cáo** | ZCO01A → giả định chương trình `ZCO_PG_BCGTTT_NEW_B` (thư mục repo). **Cần xác nhận bằng Q01:** header chương trình ghi "Tunning báo cáo ZCO01A > Program `ZCO_PG_BCGTTT_NEW_A`". Màn hình chọn trong ảnh khớp bản `_B` (mặc định loại trừ `Z*`) |
| **Variant** | `CT_37560` (PRD/DEV) – Plant `1100`, Material `52000348`, kỳ `3/2026`, không tick "Loại trừ thu hồi" |
| **Hệ thống** | NKG PRD, client 100 |
| **Người kiểm tra** | SangVT – 14.10.2026 (deadline ticket: 14.10.2026) |
| **Trạng thái** | ✅ Đã xác định nguyên nhân · ✏️ **đã sửa trên local (hướng A), chưa dán vào SAP, chưa biên dịch** · ⏳ còn 3 điểm chưa kiểm |

> ### Kết luận nhanh
> - **Nguyên nhân:** ZCO01A lấy `BWART` từ `MSEG` với `ZEILE = 1` cho **mọi** dòng CO của cùng mat doc (F01:827–828). Mat doc `4903335106` có item 1 = **531** (lệnh …693) và item 2 = **Z01** (lệnh …692). Dòng CO của lệnh …692 bị gán `BWART = 531` → không thuộc {Z01, Y01} → bị loại khỏi `SLTH_MATKL05`.
> - **Giá trị kỳ vọng** của chỉ tiêu 82 từ lệnh …692: **13.240 KG** (giá trị 1.878.358,80).
> - **Cờ reverse ở KOB1 không phải nguyên nhân:** code không đọc cờ này, và việc hủy một phần chỉ tác động item 1 (lệnh …693, thành phẩm khác).
> - **Chưa kiểm:** `BVALT` khớp (H4), so source PRD với repo (H7), phạm vi ảnh hưởng (Q11).
> - Dữ liệu ở mục 5 do SangVT chạy tay bằng ZSQL. MCP `GUI_NKG_PRD100` vẫn không kết nối được từ máy Claude (kiểm tra lại 14.10.2026 12:19: TCP `10.10.2.46:44335` không mở, đường đi qua Wi-Fi `10.1.4.1`, không có adapter VPN).

---

## 1. Ticket

- Người gửi: Nguyễn Thị Kim Nhi (Business Consultant).
- Nội dung: PRD **có giá trị** nhưng ZCO01A **không lấy lên** chỉ tiêu 82.
- Quan sát của người gửi: line thu hồi bị tick **reverse** ở KOB1 (mat doc `4903335106`), nhưng mat doc thu hồi chỉ reverse **một phần** (lệnh SX `20200022693`); thu hồi của lệnh SX `20200022692` **không reverse**.
- Tham số variant `CT_37560` (đọc từ ảnh màn hình chọn):

| Plant | Material | Valuation Type | Posting period | Fiscal Year | Phiên bản | Loại trừ thu hồi |
|---|---|---|---|---|---|---|
| 1100 | 52000348 | (trống) | 3 | 2026 | **loại trừ `Z*`** | không tick |

> **Đính chính:** ô "Phiên bản = `Z*`" là điều kiện **loại trừ** (mặc định ở `INIT_PROC`, F01:10: `SIGN = 'E'`, `OPTION = 'CP'`, `LOW = 'Z*'`; trên màn hình có icon đỏ cạnh nhãn). Ghi chú trước đây coi nó là điều kiện bao gồm là sai. Xem H2.

## 2. Đặc tả FS (`NKG_FS_FI_ZCO01A_…_V0.06.xlsx`, sheet `FORM_ZCO01A`, ô O1099)

- CKM3 (Plant, Period, Year theo tham số; View *PS Price Determination Structure*; Category *Receipts-Production*) → tìm các LSX của thành phẩm.
- Vào KOB1 của các LSX đó, lấy `SUM(Total Quantity)` các dòng thỏa:
  - Cost Element bắt đầu `621*`
  - Offset Account Type khác NULL
  - Material thuộc Material Group bắt đầu `51*`
  - **Chỉ lấy movement type Z01, Y01**
- FS không nói gì về dòng đã bị reverse/hủy.
- Lịch sử FS: v0.04–0.05 thêm "Loại trừ thu hồi"; v0.06 (02.10.2026) chỉ đổi chỉ tiêu 27, 54, 55, 76, 77. **Chỉ tiêu 82 không đổi ở v0.06.**

## 3. Logic trong code (`zco_in_bcgttt_new_b_f01.abap`, FORM `GET_KOB1`, dòng 764–1055)

Chỉ tiêu 82 = cột `SLTH_MATKL05` (`'SLTH_' && FNAME`, dòng 947; `'51*'` → `MATKL05` ở `MAP_MATKL`, dòng 1204). Cộng dồn `SLTH_MATKL05 = SLTH_MATKL05 - MBGBTR` khi dòng COEP đi qua đủ các "cửa":

| # | Điều kiện | Dòng code | Kết quả với ca này |
|---|---|---|---|
| 1 | COEP: `KOKRS = 'NKG'`, `PERIO = P_POPER`, `GJAHR = P_GJAHR` | 832–834 | ✅ |
| 2 | `KSTAR LIKE '621%'` **và** `GKOAR <> space` | 836 | ✅ (`GKOAR = M`) |
| 3 | Nối AFPO: `'OR' && AUFNR = COEP~OBJNR`; `AFPO~MATNR` thuộc `GT_DATA`; `AFPO~DWERK` thuộc plant | 825, 830–831 | ✅ (lệnh …692 → 52000348/1100) |
| 4 | `BVALT` lấy từ `GT_BVALT` theo AUFNR (LEFT JOIN; bảng dựng ở 471–481 từ MLDOC) | 826 | ⏳ chưa kiểm |
| 5 | **`BWART` lấy từ `MSEG` với `MSEG~ZEILE = 1`** (chỉ item đầu của mat doc) | 827–828 | ❌ **gán 531 thay vì Z01** |
| 6 | `MATKL_CO` = `MARA~MATKL` của `COEP~MATNR`, phải có trong `GT_MATKL` (nhóm `51*`) | 829, 895–898 | ✅ (51001) |
| 7 | `BWART = 'Z01'` hoặc `'Y01'` → cộng vào `SLTH_` | 944–960 | ❌ không vào được (do cửa 5) |
| 8 | Dòng COEP chỉ cộng vào dòng `GT_DATA` có cùng `(MATNR, WERKS, BVALT)` | 850–859 | ⏳ chưa kiểm |
| 9 | Dòng `GT_DATA` chỉ được giữ nếu `VERID IN S_VERID` | 591 | ✅ dự kiến (chỉ loại version bắt đầu `Z`; lệnh …692 là `B201`; chưa kiểm `VERID` thực của dòng `GT_DATA`) |

Nhận xét thêm từ source:

- **Không có xử lý reverse:** không lọc `STFLG`/`STOKZ`, không đọc cờ reversal. Dòng reverse vẫn được đọc, miễn qua các cửa trên.
- Thay đổi #37497 (06.10.2026) chỉ thêm `CONTINUE` cho `MATKL = 62001`, không ảnh hưởng nhóm `51*`.
- Cơ chế `ZEILE = 1` cũng dùng cho các cột xuất (261/262, F01:923) và nhóm 627\* (F01:1005).
- `SELECT` trên COEP **không lọc Value Type / Version**, trong khi KOB1 chỉ hiển thị actual. Chưa có bằng chứng ảnh hưởng ca này (Q05: cả 2 dòng đều Value Type 4, Version 0). Quan sát phụ, chưa kiểm.

## 4. Bằng chứng từ 2 ảnh trong ticket (PRD/100)

**MB51 – vật tư 51000012 "PO 2.0 x 1200 S06", lệnh 20200022692:**

| Mat doc | Item | MvT | Ngày | SL (KG) | Giá trị (VND) |
|---|---|---|---|---|---|
| 4903335101 | 2 | 261 | 11.03.2026 | 23.760- | 337.083.120- |
| 4903335101 | 1 | 261 | 11.03.2026 | 22.650- | 321.335.550- |
| **4903335106** | **2** | **Z01** "Nhập vật tư thu hồi" | 11.03.2026 | **13.240** | **187.835.880** |
| 4903335171 | 1 | 261 | 11.03.2026 | 23.810- | 337.792.470- |
| 4903335994 | 1 | 262 | 11.03.2026 | 22.650 | 321.335.550 |
| 4903336014 | 1 | 261 | 11.03.2026 | 22.650- | 321.335.550- |
| 4903336053 | 1 | 262 | 11.03.2026 | 23.810 | 337.792.470 |

Dòng `4903335106`: batch 1004630929, Val. Type SANXUAT, header text "NHẬP THU HỒI". Ngoài ra có GR 101 vật tư 52000348: 10.080 KG và 22.180 KG.

**KOB1 – lệnh 20200022692, Cost Element 6211000004 "CP SP (Xuất LSX)", vật tư 51000012:**

| Ref. doc | Val.in rep.cur. | Reversed | ReverseDoc | Reversal Ref. |
|---|---|---|---|---|
| 4903335171 | 337.792.470 | X | | 4903336053 |
| 4903335101 | 321.335.550 | X | | 4903335994 |
| 4903335101 | 337.083.120 | X | | 4903335994 |
| **4903335106** | **187.835.880-** | **X** | | **4903336059** |
| 4903335994 | 321.335.550- | | X | 4903335101 |
| 4903336014 | 321.335.550 | | | |
| 4903336053 | 337.792.470- | | X | 4903335171 |

Tổng KOB1 trên màn hình: 470.582.790 (đã cộng lại các dòng: đúng).

Quan sát:

- Dòng `4903335106` có cờ **Reversed = X** (Reversal Ref. `4903336059`) nhưng **không có dòng nào của `4903336059` trong lệnh …692**. Chứng từ hủy này thuộc lệnh khác, đúng như ticket.
- Dòng `337.083.120` của `4903335101` cũng bị cờ Reversed nhưng chứng từ hủy `4903335994` chỉ có đúng 1 dòng `321.335.550-`. Tức **cờ Reversed gắn cho cả chứng từ CO khi chỉ hủy một phần item**, nên không dùng cờ này để kết luận dòng đã bị hủy.

## 5. Dữ liệu PRD (SangVT chạy ZSQL; ABAP SQL, chỉ đọc)

Tham số: Plant `1100`, thành phẩm `52000348`, vật tư thu hồi `51000012`, mat doc `4903335106` / `4903336059` (năm 2026), lệnh `…692` / `…693`, kỳ `003/2026`, KOKRS `NKG`. Số vật tư/lệnh dùng `LIKE '%…'` để không phụ thuộc số 0 đứng đầu.

### Q01 – Tcode → chương trình

```sql
SELECT tcode, pgmna FROM tstc WHERE tcode = 'ZCO01A'
```

Chưa ghi kết quả (kỳ vọng `ZCO_PG_BCGTTT_NEW_B`).

### Q02 – Header 2 lệnh sản xuất

```sql
SELECT aufnr, matnr, dwerk, verid, psmng, wemng
  FROM afpo
 WHERE aufnr LIKE '%20200022692' OR aufnr LIKE '%20200022693'
```

| Order | Material | Plant | Production Version | Total Qty | GR Qty |
|---|---|---|---|---|---|
| 20200022692 | 52000348 | 1100 | B201 | 30,000.000 | 32,260.000 |
| 20200022693 | **52000548** | 1100 | B201 | 30,000.000 | 32,820.000 |

→ Lệnh …693 là **thành phẩm khác** (52000548), không thuộc variant (Material = 52000348).

### Q03 – Các item của mat doc thu hồi và mat doc hủy (kiểm H1, H5)

```sql
SELECT mblnr, mjahr, zeile, bwart, matnr, werks, aufnr, menge, meins, dmbtr, shkzg, smbln, smblp
  FROM mseg
 WHERE mjahr = '2026' AND mblnr IN ( '4903335106', '4903336059' )
 ORDER BY mblnr, zeile
```

| Mat doc | Năm | Item | BWART | Material | Plant | Order | SL | ĐVT | Amt LC | S/H | Ref doc (SMBLN) | Ref item (SMBLP) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 4903335106 | 2026 | **1** | **531** | 51000012 | 1100 | 20200022693 | 13,520.000 | KG | 1,918,082.40 | S | | 0 |
| 4903335106 | 2026 | **2** | **Z01** | 51000012 | 1100 | 20200022692 | 13,240.000 | KG | 1,878,358.80 | S | | 0 |
| 4903336059 | 2026 | 1 | 532 | 51000012 | 1100 | 20200022693 | 13,520.000 | KG | 1,918,082.40 | H | 4903335106 | 1 |

→ **H1 xác nhận.** `ZEILE = 1` của `4903335106` là `531`, không phải Z01. Chứng từ hủy `4903336059` chỉ hủy item 1 (531 → 532, lệnh …693).

### Q04 – Các dòng CO 621\* của 2 lệnh trong kỳ 003/2026 (kiểm H3)

```sql
SELECT belnr, buzei, objnr, kstar, gkoar, gkont, wkgbtr, mbgbtr, meinb, awkey, matnr
  FROM coep
 WHERE kokrs = 'NKG' AND gjahr = '2026' AND perio = '003'
   AND ( objnr LIKE 'OR%20200022692' OR objnr LIKE 'OR%20200022693' )
   AND kstar LIKE '621%'
 ORDER BY objnr, belnr, buzei
```

| CO doc | Row | Object | KSTAR | GKOAR | GKONT | Val/COArea | SL (KG) | AWKEY | Material |
|---|---|---|---|---|---|---|---|---|---|
| A0033PWF00 | 1 | OR020200022692 | 6211000004 | M | 1551000000 | 3.377.924,70 | 23,810.000 | 49033351712026 | 51000012 |
| A0033PZH00 | 1 | OR020200022692 | 6211000004 | M | 1551000000 | 3.213.355,50 | 22,650.000 | 49033351012026 | 51000012 |
| A0033PZH00 | 2 | OR020200022692 | 6211000004 | M | 1551000000 | 3.370.831,20 | 23,760.000 | 49033351012026 | 51000012 |
| **A0033PZN00** | **2** | **OR020200022692** | 6211000004 | M | 1551000000 | **1.878.358,80-** | **-13,240** | **49033351062026** | 51000012 |
| A0033QLZ00 | 1 | OR020200022692 | 6211000004 | M | 1551000000 | 3.213.355,50- | -22,650 | 49033359942026 | 51000012 |
| A0033QMH00 | 1 | OR020200022692 | 6211000004 | M | 1551000000 | 3.213.355,50 | 22,650.000 | 49033360142026 | 51000012 |
| A0033QNH00 | 1 | OR020200022692 | 6211000004 | M | 1551000000 | 3.377.924,70- | -23,810 | 49033360532026 | 51000012 |
| A003533700 | 1 | OR020200022692 | 6211000002 | M | 1522000000 | 10.968,43 | 16.400 | 49033711742026 | 22000100 |
| A0033PZG00 | 1 | OR020200022693 | 6211000004 | M | 1551000000 | 3.339.619,80 | 23,540.000 | 49033351002026 | 51000012 |
| A0033PZG00 | 2 | OR020200022693 | 6211000004 | M | 1551000000 | 3.370.831,20 | 23,760.000 | 49033351002026 | 51000012 |
| A0033PZN00 | 1 | OR020200022693 | 6211000004 | M | 1551000000 | 1.918.082,40- | -13,520 | 49033351062026 | 51000012 |
| A0033QNM00 | 1 | OR020200022693 | 6211000004 | M | 1551000000 | 1.918.082,40 | 13,520.000 | 49033360592026 | 51000012 |
| A0033QNO00 | 1 | OR020200022693 | 6211000004 | M | 1551000000 | 1.918.082,40- | -13,520 | 49033360602026 | 51000012 |
| A0033QNP00 | 1 | OR020200022693 | 6211000004 | M | 1551000000 | 1.918.082,40 | 13,520.000 | 49033360612026 | 51000012 |
| A0033QNQ00 | 1 | OR020200022693 | 6211000004 | M | 1551000000 | 1.918.082,40- | -13,520 | 49033360622026 | 51000012 |
| A003533800 | 1 | OR020200022693 | 6211000002 | M | 1522000000 | 11.352,33 | 16.974 | 49033711752026 | 22000100 |

→ Mọi dòng đều `GKOAR = M` → **H3 loại trừ**. Dòng in đậm là dòng Z01 của lệnh …692, dòng mà ZCO01A bỏ sót. Hai dòng của `A0033PZN00` có **cùng AWKEY** `49033351062026` nên cùng nhận `BWART` của item 1.

### Q05 – Toàn bộ cột của dòng CO thuộc mat doc 4903335106

```sql
SELECT * FROM coep
 WHERE kokrs = 'NKG' AND gjahr = '2026' AND awkey LIKE '4903335106%'
```

Các cột có giá trị của 2 dòng (còn lại rỗng hoặc 0):

| Cột | Dòng 1 (lệnh …693) | Dòng 2 (lệnh …692) |
|---|---|---|
| Controlling Area | NKG | NKG |
| Document Number / Posting Row | A0033PZN00 / 1 | A0033PZN00 / 2 |
| Period / Fiscal Year | 3 / 2026 | 3 / 2026 |
| Object number | OR020200022693 | OR020200022692 |
| Value TranCurr = Obj. Crcy = Val/COArea | 1.918.082,40- | 1.878.358,80- |
| FixValue COCurr | 30.974,73- | 30.333,24- |
| Total Quantity | -13,520 | -13,240 |
| Unit / Posted unit | KG / KG | KG / KG |
| Value Type / Version | 4 / 0 | 4 / 0 |
| Cost Element | 6211000004 | 6211000004 |
| CO subkey / Business Transaction | 0000022899 / COIN | 0000022899 / COIN |
| Dr/Cr indicator | C | C |
| Transaction / Object Currency | VND / VND | VND / VND |
| SGTXT | NHẬP THU HỒI | NHẬP THU HỒI |
| Document item / Row in op. version | 2 / 1 | 4 / 2 |
| Offsetting Account / Type | 1551000000 / M | 1551000000 / M |
| Plant / Material | 1100 / 51000012 | 1100 / 51000012 |
| Company Code / Debit Type | 1000 / 1 | 1000 / 1 |
| Profit Center / Partner Profit Ctr | P052 / P051 | P052 / P051 |
| FI Posting Item | 2 | 4 |
| Reference procedure / Object key | MKPF / 49033351062026 | MKPF / 49033351062026 |
| Order / Order category | 020200022693 / 10 | 020200022692 / 10 |
| CO area currency / Object Type | VND / OR | VND / OR |

→ COEP **không có cột mang `ZEILE` của MSEG**. "Document item" (2 và 4) và "FI Posting Item" (2 và 4) có vẻ là dòng chứng từ FI (mỗi item MM sinh 2 dòng FI) nên cần xác nhận trước khi dùng cho hướng B (mục 6).

### Q06 – Nhóm vật tư (kiểm H6)

```sql
SELECT matnr, matkl, mtart FROM mara
 WHERE matnr LIKE '%51000012' OR matnr LIKE '%52000348'
```

```sql
SELECT DISTINCT matkl FROM t023t WHERE matkl LIKE '51%'
```

| Material | Material Group | Material type |
|---|---|---|
| 51000012 | 51001 | M051 |
| 52000348 | 52001 | M052 |

`T023T` có các nhóm `51*`: 51001, 51002 → **H6 loại trừ**.

### Q07 – KALNR của thành phẩm

```sql
SELECT kalnr, matnr, bwkey, bwtar FROM ckmlhd
 WHERE matnr LIKE '%52000348' AND bwkey = '1100'
```

| Cost Estimate Number (KALNR) | Material | Valuation area | Valuation Type |
|---|---|---|---|
| 100118058 | 52000348 | 1100 | SANXUAT |
| 100144090 | 52000348 | 1100 | MUANGOAI |
| 102008733 | 52000348 | 1100 | GC_NGOAI |
| 100067750 | 52000348 | 1100 | GIACONG |

### Q08, Q09 – BVALT của lệnh / nhóm BVALT (kiểm H4)

```sql
SELECT DISTINCT bvalt, aufnr FROM mldoc
 WHERE jahrper = '2026003' AND bvalt <> ' ' AND aufnr <> ' ' AND kalnr = '<KALNR>'
 ORDER BY bvalt, aufnr
```

```sql
SELECT bvalt, categ, ptyp, runref, COUNT( * ) AS cnt FROM mldoc
 WHERE jahrper = '2026003' AND kalnr = '<KALNR>' AND curtp = '10'
 GROUP BY bvalt, categ, ptyp, runref
```

Kết quả: "Không có dữ liệu" vì chạy với chữ `<KALNR>` chưa được thay. **Chạy lại bằng Q08b/Q09b ở Phụ lục A.**

### Q10 – Replica câu SELECT của `GET_KOB1`

Lỗi `The INTO/APPENDING clause must be at the end of the SELECT` khi chạy bằng ZSQL (giải thích và bản SQL cho DBACOCKPIT ở Phụ lục B). Không cần chạy lại vì Q03 + Q04 đã đủ để kết luận.

## 6. Phân tích và kết luận

### 6.1 Các giả thuyết

| ID | Giả thuyết | Kết quả | Căn cứ |
|---|---|---|---|
| H1 | `BWART` theo item 1 của mat doc khác Z01/Y01 | ✅ **ĐÚNG – là nguyên nhân** | Q03: item 1 = 531, item 2 = Z01 |
| H2 | Bộ lọc Phiên bản loại dòng thu hồi | ❌ Loại trừ | `Z*` là điều kiện **loại trừ** (F01:10, icon đỏ); lệnh …692 là version `B201`, không bắt đầu bằng `Z` |
| H3 | `GKOAR` rỗng ở dòng Z01 | ❌ Loại trừ | Q04: mọi dòng `GKOAR = M` |
| H4 | `BVALT` của lệnh ≠ `BVALT` dòng `GT_DATA`, hoặc 1 lệnh có >1 `BVALT` | ⏳ Chưa kiểm | Cần Q08b, Q09b |
| H5 | Chứng từ hủy có BWART ∉ {Z01, Y01} làm lệch bù trừ | ⚪ Không liên quan | Q03: hủy `532` chỉ thuộc lệnh …693, ngoài variant |
| H6 | `MATKL` không thuộc `51*` | ❌ Loại trừ | Q06: 51001 |
| H7 | Code trong repo khác bản đang active trên PRD, hoặc ZCO01A chạy chương trình khác (`…_NEW_A`) | ⏳ Chưa kiểm | Cần Q01 (Tcode → chương trình) và `GetSource` PRD hoặc SE38/ADT |

### 6.2 Vì sao ZCO01A không lấy dòng Z01 của lệnh …692

1. COEP có dòng `A0033PZN00`/2 (lệnh …692, 621\*, `GKOAR = M`, −13.240 KG, AWKEY `49033351062026`) → qua các cửa 1, 2, 3, 6.
2. SELECT nối `MSEG` bằng `MBLNR+MJAHR = AWKEY` **và `ZEILE = 1`** → lấy item 1 của `4903335106` → `BWART = 531`.
3. Nhánh `621` kiểm `BWART = 261/262` rồi `BWART = Z01/Y01` (F01:923, 944) → **531 không khớp nhánh nào** → dòng không được cộng vào `SLTH_MATKL05`.
4. KOB1 hiển thị đúng item (Z01), nên có giá trị; ZCO01A thì không.

Về lập luận "dòng bị reverse nên ZCO01A bỏ":

- Code **không dùng cờ reverse**. Việc hủy một phần chỉ tác động item 1 (lệnh …693, thành phẩm **52000548**, ngoài variant).
- Cờ "Reversed" ở KOB1 gắn theo cả chứng từ CO nên dòng của lệnh …692 cũng bị đánh dấu dù không bị hủy. Đây là hiện tượng hiển thị, không phải nguyên nhân.

### 6.3 Hướng xử lý (đã sửa trên local theo hướng A, xem Phụ lục C)

Lấy `BWART` đúng item của dòng CO thay vì cố định `ZEILE = 1`:

- **A.** Nối `MSEG` theo `MBLNR+MJAHR = AWKEY` **và** `MSEG~AUFNR = AFPO~AUFNR` **và** `MSEG~MATNR = COEP~MATNR`. Cần kiểm trường hợp 1 mat doc có nhiều item cùng lệnh + vật tư nhưng khác BWART (dễ nhân đôi dòng COEP).
- **B.** Dùng khóa dòng tham chiếu chứng từ (`AWITEM` ↔ `ZEILE`) nếu COEP/COVP trên hệ này có cột đó. **Chưa khả thi với dữ liệu hiện có:** Q05 (`SELECT *` trên COEP) không có cột nào bằng `ZEILE`; "Document item" và "FI Posting Item" đều là 2 và 4, trong khi `ZEILE` là 1 và 2. Chưa biết COVP/ACDOCA có cột phù hợp hay không (cần Q12, Phụ lục A; máy Claude chưa kết nối được hệ NKG để tự kiểm). Nếu Q12 tìm được cột đúng thì có thể thay hướng A bằng hướng B sau.

Phạm vi: cùng cơ chế `ZEILE = 1` áp dụng cho cột xuất (261/262) và 627\*, nên các chỉ tiêu khác cũng có thể thiếu dòng khi item 1 của mat doc khác loại. Chỉ tiêu 82 đã kiểm; các chỉ tiêu khác chưa kiểm theo yêu cầu.

## 7. Đối chiếu lại yêu cầu ban đầu của ticket

| Ý trong ticket | Kết quả kiểm tra |
|---|---|
| PRD có giá trị nhưng ZCO01A không lấy lên chỉ tiêu 82 | ✅ Đúng. KOB1 có dòng Z01 13.240 KG (lệnh …692); ZCO01A bỏ dòng này vì `BWART` bị gán 531 |
| Line thu hồi bị tick reverse ở KOB1 (mat doc 4903335106) | ✅ Đúng là cờ Reversed = X, nhưng cờ này **không ảnh hưởng** ZCO01A (code không đọc) |
| Mat doc thu hồi chỉ reverse một phần (lệnh …693); thu hồi lệnh …692 không reverse | ✅ Đúng. Chứng từ hủy `4903336059` chỉ hủy item 1 (531 → 532, lệnh …693). Item 2 (Z01, lệnh …692) không bị hủy |
| Nguyên nhân thật | `BWART` lấy theo `ZEILE = 1` (F01:827–828); mat doc có item 1 = 531, item 2 = Z01 |
| Chỉ tiêu 82 đúng với FS không | FS yêu cầu "chỉ lấy movement type Z01, Y01" của dòng KOB1. Code vi phạm FS ở bước xác định movement type của dòng |

## 8. Việc tiếp theo

1. Chạy **Q08b, Q09b** (KALNR thật, Phụ lục A) để kiểm H4: `BVALT` của lệnh …692 có khớp dòng `GT_DATA` hay không. Nếu sửa `BWART` rồi mà chỉ tiêu 82 vẫn bằng 0 thì nghi H4.
2. **Chạy Q01** để xác nhận ZCO01A trỏ tới chương trình nào (`_NEW_B` hay `_NEW_A`), rồi so source đang active trên PRD với bản trong repo (H7). Cần MCP hoặc SE38/ADT. Nếu ZCO01A chạy `_NEW_A` thì toàn bộ phân tích ở mục 3 và 6 phải kiểm lại trên source đó.
3. Chạy **Q11** để biết phạm vi ảnh hưởng của cơ chế `ZEILE = 1`.
4. **Dán bản sửa local vào SAP (DEV)**, biên dịch và kiểm tra theo Phụ lục C: variant `CT_37560` kỳ vọng chỉ tiêu 82 = 13.240 KG. Trước khi dán, so bản trong repo với bản đang active (H7) để không ghi đè thay đổi mới hơn của hệ thống.
5. Bật VPN NKG để MCP kết nối được `10.10.2.46:44335` nếu muốn Claude tự chạy lại các câu SQL.

---

## Phụ lục A – SQL chưa có kết quả (viết dạng cổ điển, chạy được trong ZSQL)

KALNR của thành phẩm 52000348 / plant 1100 (Q07, định dạng 12 số): `000100118058` (SANXUAT), `000100144090` (MUANGOAI), `000102008733` (GC_NGOAI), `000100067750` (GIACONG).

```sql
-- Q08b  H4: replica GT_BVALT (F01:471-481) với KALNR thật
SELECT DISTINCT bvalt aufnr FROM mldoc
 WHERE jahrper = '2026003' AND bvalt <> ' ' AND aufnr <> ' '
   AND kalnr IN ('000100118058', '000100144090', '000102008733', '000100067750')
 ORDER BY bvalt aufnr
```

```sql
-- Q09b  H4: các nhóm BVALT / categ / ptyp của thành phẩm trong kỳ
SELECT bvalt categ ptyp runref COUNT( * ) AS cnt FROM mldoc
 WHERE jahrper = '2026003' AND curtp = '10'
   AND kalnr IN ('000100118058', '000100144090', '000102008733', '000100067750')
 GROUP BY bvalt categ ptyp runref
```

```sql
-- Q11  Phạm vi ảnh hưởng: item Z01/Y01 KHÔNG phải item 1 của mat doc, plant 1100, tháng 03/2026
-- (nếu báo không có cột BUDAT_MKPF thì bỏ 2 điều kiện ngày). Sau đó tra BWART của ZEILE = '0001' của các mat doc này.
SELECT mblnr mjahr zeile bwart matnr aufnr menge FROM mseg
 WHERE mjahr = '2026' AND werks = '1100' AND bwart IN ('Z01', 'Y01') AND zeile <> '0001'
   AND budat_mkpf >= '20260301' AND budat_mkpf <= '20260331'
 ORDER BY mblnr zeile
```

```sql
-- Q12  Hướng B: cột nào của COEP / COVP / ACDOCA mang số item của chứng từ tham chiếu (tên bắt đầu AW, REF hoặc ZEILE)
SELECT tabname fieldname rollname FROM dd03l
 WHERE tabname IN ('COEP', 'COVP', 'ACDOCA') AND as4local = 'A'
   AND ( fieldname LIKE 'AW%' OR fieldname LIKE 'REF%' OR fieldname LIKE 'ZEILE%' )
 ORDER BY tabname fieldname
```

Nếu Q12 cho thấy COVP (hoặc COEP) có cột kiểu `AWITEM`/`REFBZ`, chạy tiếp để xem giá trị có bằng `ZEILE` không (thay `<COT>` bằng tên cột tìm được, bảng nào có cột đó):

```sql
-- Q12b  So sánh cột tìm được với ZEILE của mat doc 4903335106 (kỳ vọng 1 cho lệnh …693, 2 cho lệnh …692)
SELECT belnr buzei objnr awkey <COT> FROM coep
 WHERE kokrs = 'NKG' AND gjahr = '2026' AND awkey LIKE '4903335106%'
```

## Phụ lục B – Q10 và lỗi `INTO/APPENDING`

```sql
-- Q10 (ABAP SQL)  replica câu SELECT của GET_KOB1, bỏ phần GT_BVALT
SELECT coep~belnr, coep~kstar, coep~gkoar, coep~mbgbtr, coep~wkgbtr, coep~awkey,
       afpo~aufnr, afpo~matnr, afpo~dwerk, mara~matkl AS matkl_co, mseg~bwart
  FROM coep
  INNER JOIN afpo ON concat( 'OR', afpo~aufnr ) = coep~objnr
  LEFT JOIN mseg ON concat( mseg~mblnr, mseg~mjahr ) = coep~awkey AND mseg~zeile = 1
  LEFT JOIN mara ON mara~matnr = coep~matnr
 WHERE afpo~matnr LIKE '%52000348' AND afpo~dwerk = '1100'
   AND coep~kokrs = 'NKG' AND coep~perio = '003' AND coep~gjahr = '2026'
   AND coep~kstar LIKE '621%' AND coep~gkoar <> ' '
```

**Lỗi `The INTO/APPENDING clause must be at the end of the SELECT`:** ZSQL sinh chương trình có dạng `SELECT <cột> INTO TABLE @t_result UP TO … ROWS FROM …`, tức đặt `INTO`/`UP TO` **trước** `FROM`. Q10 dùng `CONCAT()` trong điều kiện JOIN (cú pháp strict) nên đòi `INTO` ở cuối câu. Khi cần câu có JOIN/biểu thức SQL, chạy trong ADT SQL console hoặc `RunQuery`, hoặc viết dạng cổ điển (cột cách nhau bằng dấu cách, không `CONCAT`).

**Bản SQL gốc HANA cho DBACOCKPIT:** [`sql/query_chi_tieu_82_replica_get_kob1_hana.sql`](sql/query_chi_tieu_82_replica_get_kob1_hana.sql)
- Câu 1 = logic hiện tại của report (`BWART` theo `ZEILE = '0001'`; kỳ vọng dòng `A0033PZN00`/2 ra `531`).
- Câu 2 (đang comment) = `BWART` theo đúng item của dòng CO (cùng lệnh và vật tư; kỳ vọng ra `Z01`). Dòng CO lặp lại nhiều lần nghĩa là khớp hơn một item, cần lưu ý khi chọn hướng A.

Lưu ý khi chạy bằng RunQuery: giới hạn ~255 ký tự/dòng, kết quả có thể bị cắt quanh 100 dòng (nên dùng thêm `COUNT(*)` để đối chiếu), và một số endpoint không hỗ trợ `JOIN` (báo "Only one SELECT statement is allowed").

## Phụ lục C – Thay đổi đã làm trên local (hướng A, 14.10.2026 12:42:18)

**File:** `CodeABAP/NKG_ZCO01A/zco_pg_bcgttt_new_b/zco_in_bcgttt_new_b_f01.abap` (include `ZCO_IN_BCGTTT_NEW_B_F01`). Chỉ sửa trong FORM `GET_KOB1`, 7 cặp marker `SangVT add/modify begin/end`. Trạng thái: **chưa dán vào SAP, chưa biên dịch**.

| Vị trí (dòng mới) | Nội dung |
|---|---|
| 778–800 | Khai báo `LTY_DOC`, `LTY_MSEG_ITEM`, `LT_DOC`, `LT_MSEG_ITEM` (bảng sorted, khóa `MBLNR MJAHR AUFNR MATNR`), `LV_BWART`, `LV_BWART_ITEM`… |
| 867–888 | Từ `LT_COEP` lấy danh sách mat doc (`AWKEY(10)` = MBLNR, `AWKEY+10(4)` = MJAHR); `SELECT DISTINCT MBLNR, MJAHR, AUFNR, MATNR, BWART` từ `MSEG` nối bảng nội bộ theo `MBLNR`+`MJAHR` |
| 908–930 | Trong `LOOP AT LT_COEP`: `LV_BWART` mặc định = `BWART` của `ZEILE = 1` (như cũ). Nếu không item nào cùng lệnh + vật tư có `BWART` bằng giá trị đó thì lấy `BWART` của item cùng lệnh + vật tư |
| 991–996, 1016–1021 | Nhánh `621*`: `LS_COEP-BWART` → `LV_BWART` (261/262 và Z01/Y01). Dòng cũ được comment |
| 1081–1086, 1106–1111 | Nhánh `627*`: tương tự |

Hành vi:

- Mat doc chỉ có 1 item, hoặc item 1 cùng lệnh + vật tư với dòng CO: **không đổi so với trước**.
- Chỉ đổi khi `BWART` của item 1 không trùng `BWART` của bất kỳ item nào cùng lệnh + vật tư. Ca `4903335106`: dòng …692 đổi từ 531 sang **Z01**.
- Không tìm thấy item khớp (chứng từ không phải mat doc, hoặc `AUFNR` trống): giữ như cũ.
- Hạn chế: nếu một mat doc có item 1 và item khác **cùng lệnh + vật tư nhưng khác `BWART`** thì giữ `BWART` của item 1 như cũ.
- Phạm vi: áp dụng cho **mọi** chỉ tiêu dùng `BWART` (xuất 261/262, thu hồi Z01/Y01, nhóm 621\* và 627\*). Số liệu của các chỉ tiêu khác chỉ đổi ở những dòng thuộc mat doc kiểu `4903335106`.

Cần kiểm tra sau khi dán vào SAP:

1. Biên dịch (Syntax check) include; chú ý các câu `INNER JOIN @LT_DOC`, `<LFS_COEP_KEY>-AWKEY(10)`, `LS_COEP-AWKEY+10(4)`.
2. Variant `CT_37560` (Plant 1100, Material 52000348, kỳ 3/2026, không tick Loại trừ thu hồi): chỉ tiêu 82 kỳ vọng **13.240 KG** (giá trị 1.878.358,80).
3. So toàn bộ chỉ tiêu trước và sau cho cùng kỳ: chỉ các dòng thuộc mat doc có item 1 khác loại mới được đổi (Q11 và câu 2 của file SQL HANA liệt kê trước các dòng đó).
4. Nếu chỉ tiêu 82 vẫn bằng 0 sau khi sửa: kiểm H4 (`BVALT`, Q08b/Q09b).
