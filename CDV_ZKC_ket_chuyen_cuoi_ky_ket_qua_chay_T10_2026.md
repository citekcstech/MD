# CDV – Tcode ZKC (Kết chuyển cuối kỳ): chạy với tham số T10/2026 thì ra gì?

Nguồn: MCP `GUI_CDV_PRD800` (PRD, client 800, chỉ đọc), đọc ngày 02.11.2026.

## 1. Tham số trong ảnh

| Field | Giá trị |
|---|---|
| Rule type | 1. Giá thành |
| Company Code | 1000 (CADIVI Việt Nam, VND) |
| Fiscal Year / Period | 2026 / 10 |
| Document Type | KC |
| Document Date / Posting Date | 31.10.2026 |
| Header Text | (trống) |
| Reverse Posted Document | không tick |

## 2. Kết luận

**Chạy đúng tham số này sẽ KHÔNG sinh chứng từ mới.** Chương trình dừng ở lỗi:

> E017 – "This parameter was posted. Posted Document is **2629000118**!"

Lý do: bảng log `ZTB_FI_KC_LOG` đã có bản ghi (1000 / 2026 / 10 / Rule type 1):

| Field | Giá trị |
|---|---|
| BELNR | 2629000118 |
| STBLG (chứng từ reverse) | trống – chưa reverse |
| Người tạo | CDV.FICO31, 01.11.2026 00:02:51 |

BKPF của chứng từ này: Tcode ZKC, BLART KC, BLDAT = BUDAT = 31.10.2026, MONAT 10, BKTXT "KC Giá thành T10.2026", XREVERSAL trống.
Vì chứng từ còn hiệu lực và không tick Reverse nên `CHECK_POST_OR_REVERSE` báo E017.

## 3. Chứng từ đã sinh (2629000118) – giá trị

Tất cả dòng dùng cost center `1000KC99`. Số dưới đây là giá trị lưu DB (BSEG-DMBTR), VND có 0 số lẻ.

| Dòng | Nợ (PK 40) | Có (PK 50) | Số tiền |
|---|---|---|---|
| 001/002 | 1541000002 | 1541000099 | 54.531.716,78 |
| 003/004 | 1541000004 | 1541000099 | 2.561.257,68 |
| 005/006 | 1541000006 | 1541000099 | 54.800,00 |
| 007/008 | 1541000008 | 1541000099 | 657.444,00 |
| 009/010 | 1541000099 | 6219999999 | 64.809.566.309,46 |
| 011/012 | 1541000099 | 6229999999 | 84.944.760,95 |
| 013/014 | 1541000099 | 6279999999 | 407.893.955,10 |
| **Tổng mỗi bên (7 dòng Nợ, 7 dòng Có)** | | | **65.360.210.243,97** |

Cách đọc: các TK 621/622/627 (nguồn, mapping `ZTB_FI_MAPKC`) được kết chuyển về TK 1541000099; TK 154100000x có số dư Có nên được kết chuyển ngược lại về 1541000099.

**Lưu ý đơn vị:** VND có `TCURX-CURRDEC = 0`, chương trình nhân `GW_XPLUS = 100` khi gọi BAPI. Số hiển thị trên GUI (FB03) = giá trị DB × 100 (ví dụ tổng 65.360.210.243,97 ở DB ↔ 6.536.021.024.397 VND). Cần mở FB03 để chốt số hiển thị.

## 4. Đối chiếu số liệu (FAGLFLEXT, ledger 0L, năm 2026, kỳ 10)

HSL10 hiện tại của các TK đối ứng khớp đúng số trên chứng từ:
- 6219999999 = -64.809.566.309,46
- 6229999999 = -84.944.760,95
- 6279999999 = -407.893.955,10

Tổng HSL10 của các TK nguồn 6211…6219000xxx ≈ 64.809,6 triệu (khớp dòng 009/010). HSL10 của 1541000002/4/6/8 hiện = 0 vì đã bị chứng từ KC bù trừ.
Nên nếu reverse rồi chạy lại, bảng preview sẽ ra lại đúng 7 cặp trên (miễn là chưa có phát sinh mới ở kỳ 10 sau 01.11.2026).

## 5. Logic chương trình ZFI_PG_KC (include ZFI_IN_KC_TOP / F01 / F02 / F03)

1. Lấy mapping `ZTB_FI_MAPKC` theo BUKRS + RULTY (Rule type 1 của CT 1000 có 151 dòng: SACCT → DACCT/DCOST, OACCT/OCOST).
2. Lấy số dư kỳ: `FAGLFLEXT` (RLDNR 0L, RYEAR = năm) cộng theo TK, lấy cột `HSL<P_MONAT>` (phát sinh của riêng kỳ đó, KHÔNG cộng dồn).
3. Gom theo (DACCT, DCOST, OACCT, OCOST). Mỗi nhóm có DMBTR ≠ 0 sinh 1 cặp dòng:
   - DMBTR > 0: Nợ DACCT / Có OACCT.
   - DMBTR < 0: Nợ OACCT / Có DACCT, số tiền lấy trị tuyệt đối.
4. **F8 chỉ hiển thị ALV xem trước, chưa tạo chứng từ.** Chứng từ chỉ được tạo khi bấm nút POST (`BAPI_ACC_DOCUMENT_POST`, BUS_ACT RFBU, OBJ_TYPE BKPFF). Sau khi post thành công, ghi `ZTB_FI_KC_LOG` và báo "Document & posted!".
5. Mỗi (BUKRS, GJAHR, MONAT, RULTY) chỉ có 1 chứng từ. Muốn tạo lại phải reverse trước.

## 6. Muốn tạo lại chứng từ T10/2026 (Rule type 1)

1. Chạy ZKC, **tick "Reverse Posted Document"**, F8 → ALV hiện bản ghi log → bấm **REVERSE** → xác nhận. Chương trình gọi `BAPI_ACC_DOCUMENT_REV_POST` (lý do 01) và ghi STBLG vào log.
2. Chạy lại ZKC, bỏ tick Reverse. Log cũ được chuyển sang `ZTB_FI_KC_REV`, hiện thông báo "…Run new one!" rồi ra ALV xem trước mới → bấm POST.

Chỉ nên làm khi đã được kế toán đồng ý; đây là hệ PRD.

## 7. Chứng từ liên quan cùng kỳ (tham khảo)

Rule type 2 cũng đã post: 2629000119, BKTXT "KC Giá thành ML T10.2026", cùng ngày 01.11.2026 00:03:08, 3 dòng Nợ + 3 dòng Có, tổng 589.774.154,01 (DB).

## 8. Ghi chú kỹ thuật khi làm việc này

- `GetTransaction` (TRAN) lỗi `uriMappingError` → tra Tcode bằng `SELECT tcode, pgmna, dypno FROM tstc`.
- `GetTextElements` lỗi WebSocket 500 (cần ZADT_VSP, không dùng được).
- Câu `RunQuery` join kiểu `m~dacct` (alias bảng) báo `Unknown column name "DACC"`; join dùng tên bảng đầy đủ báo `A Boolean expression was expected` → tách thành 2 câu SELECT rồi ghép ngoài.
- Config `GUI_CDV_PRD800` ban đầu `--client 300` (sai) và file `.mcp.json` gốc có dấu phẩy thừa ở cuối, làm cả file không nạp được; đã sửa client 800 và bỏ dấu phẩy.

## 9. Giả sử 2629000118 đã reverse → chứng từ mới (tính ngày 02.11.2026)

Reverse (`BAPI_ACC_DOCUMENT_REV_POST`) post lại vào kỳ 10 theo BUDAT gốc 31.10.2026, nên HSL10 của các TK trở về số trước khi kết chuyển. Bảng preview tính lại từ HSL10 hiện tại, trừ tác động của 2629000118. Các TK nguồn 621/622/627 không bị chứng từ KC cũ đụng tới nên số của chúng lấy thẳng từ FAGLFLEXT hiện tại.

| Nợ | Có | Số tiền (DB) | So với chứng từ cũ |
|---|---|---|---|
| 1541000002 | 1541000099 | 54.531.716,78 | giống |
| 1541000004 | 1541000099 | 2.561.257,68 | giống |
| 1541000006 | 1541000099 | 54.800,00 | giống |
| 1541000008 | 1541000099 | 657.444,00 | giống |
| 1541000099 | 6219999999 | 64.809.566.309,46 | giống |
| 1541000099 | 6229999999 | 84.944.760,95 | giống |
| 1541000099 | 6279999999 | 407.893.955,11 | **lệch +0,01** (cũ 407.893.955,10) |
| **Tổng mỗi bên** | | **65.360.210.243,98** | cũ 65.360.210.243,97 |

- Nhóm 154 (4 cặp): HSL10 hiện của 1541000002/4/6/8 = 0,00 (đã bị chứng từ cũ bù trừ); sau reverse trở về đúng số âm của 4 số trên.
- Nhóm 621: SUM HSL10 các TK 6211000001…6219000999 = 64.809.566.309,46. Nhóm 622: 84.944.760,95.
- Nhóm 627: SUM HSL10 các TK 6271000001…6279000999 = 407.893.955,11. Đã cộng lại từng TK (56 TK có số dư ≠ 0), kết quả khớp.
- Nguyên nhân lệch 0,01 ở nhóm 627 chưa xác định (làm tròn hoặc phát sinh nhỏ vào TK 627 kỳ 10 sau 01.11.2026 00:02). Có hơn 100 chứng từ nhập vào kỳ 10 từ 01.11.2026 (FBVB, ZAR04, FB01, ZUP_R, FB1D, FV50…) nên số có thể đổi tiếp cho tới lúc chạy thật.
- Chứng từ Rule type 2 (2629000119) không bị ảnh hưởng.
- Số chứng từ mới do SAP cấp khi POST, chưa biết trước. Kỳ 10 phải còn mở để reverse và post lại (chưa kiểm OB52).
