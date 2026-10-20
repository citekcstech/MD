# Tra công thức MQC (C202) trong KALC — chạy bằng DBACOCKPIT

Công thức trong màn hình **Material Quantity Calculation** (master recipe C201/C202/C203) lưu ở bảng **KALC**, header ở **KALT**.

| Bảng | Ý nghĩa | Khóa |
|---|---|---|
| KALC | Nội dung lưới MQC, 1 dòng = 1 ô. Cột `FORMULA` chứa chuỗi công thức | `MANDT, APPLID, FORM_KEY, VERSION, LINE` |
| KALT | Header MQC (`DESCR`) | `MANDT, APPLID, FORM_KEY, VERSION` |

- `APPLID = 'MR'`: master recipe. `APPLID = 'PO'`: process order (khi đó `FORM_KEY` = số lệnh `AUFNR`).
- `FORM_KEY` của `'MR'` = `MATNR + WERKS + VERID + '01'` nối liền (theo report SAPRMQCD). Số vật tư có thể có số 0 đứng đầu hoặc đệm khoảng trắng nên các câu dưới dùng `LIKE '%<vật tư>%'`.
- `VERSION` = change number (`AENNR`), để trống nếu recipe không dùng thay đổi.

## Cách chạy

1. Đăng nhập **đúng client** có dữ liệu (client trong ảnh) → T-code `DBACOCKPIT`.
2. Menu **Diagnostics → SQL Editor** (chọn đúng hệ thống/DB ở cây bên trái).
3. Dán **từng câu một** vào ô lệnh → **Execute**. Tất cả đều là `SELECT`, không ghi dữ liệu.
4. DBACOCKPIT chạy SQL native của DB, **không tự lọc client** → mỗi câu có sẵn `"MANDT" = '200'`. **Đổi `'200'` thành client của bạn** nếu khác.
5. Đổi vật tư `5100468` ở các câu 2-4 nếu tra vật tư khác.

Trên DEV client 100 bảng KALC đang rỗng nên chưa kiểm chứng bằng dữ liệu thật; chạy ở client 200 (hoặc client có recipe) để xác nhận.

## Câu 1 — Kiểm tra client này có dữ liệu MQC không

```sql
SELECT "APPLID", COUNT(*) AS "CNT"
  FROM "KALC"
 WHERE "MANDT" = '200'
 GROUP BY "APPLID"
 ORDER BY "APPLID"
```

Kỳ vọng: có dòng `MR` (master recipe) và/hoặc `PO` (process order). Không có dòng nào → sai client hoặc chưa có MQC nào được lưu.

## Câu 2 — Header MQC của vật tư (KALT)

```sql
SELECT "APPLID", "FORM_KEY", "VERSION", "DESCR"
  FROM "KALT"
 WHERE "MANDT" = '200'
   AND "APPLID" = 'MR'
   AND "FORM_KEY" LIKE '%5100468%'
 ORDER BY "FORM_KEY", "VERSION"
```

Mỗi dòng là 1 MQC (1 production version + 1 version/change number). Xem `FORM_KEY` để biết MATNR/WERKS/VERID.

## Câu 3 — Toàn bộ ô có công thức của MQC đó (KALC)

```sql
SELECT "FORM_KEY", "VERSION", "LINE",
       "ROW_POS", "ROW_ID", "ROW_TEXT",
       "COL_POS", "COL_ID", "COL_TEXT", "COL_UOM",
       "VALUE", "FORMULA", "FORM_IND", "FORM_ORD"
  FROM "KALC"
 WHERE "MANDT" = '200'
   AND "APPLID" = 'MR'
   AND "FORM_KEY" LIKE '%5100468%'
   AND "FORMULA" <> ''
 ORDER BY "FORM_KEY", "VERSION", "FORM_ORD", "LINE", "COL_POS"
```

- `ROW_ID` = đối tượng ở cột "Object description" (vật tư/operation), `COL_ID/COL_TEXT` = cột (1:Quantity, 2:QC API...).
- `VALUE` = giá trị đã tính, `FORMULA` = chuỗi công thức, `FORM_ORD` = thứ tự tính.

## Câu 4 — Tìm đúng ô trong ảnh theo nội dung công thức

```sql
SELECT "FORM_KEY", "VERSION", "LINE", "ROW_ID", "ROW_TEXT",
       "COL_POS", "COL_ID", "COL_TEXT", "VALUE", "FORMULA"
  FROM "KALC"
 WHERE "MANDT" = '200'
   AND "FORMULA" LIKE '%CSUM(009;002)%'
 ORDER BY "FORM_KEY", "VERSION", "LINE", "COL_POS"
```

Kỳ vọng: ô vật tư 2100430, cột 1 (Quantity) có `FORMULA` = `((170*1000*[001,001]/100000)/(CSUM(009;002)/100)-[009,005])/1000`. Khớp nghĩa là xác nhận công thức lấy từ cột `KALC-FORMULA`.

## Ghi chú

- Nếu DBACOCKPIT báo không có quyền đọc bảng hoặc không thấy menu SQL Editor → nhờ Basis cấp quyền, hoặc dùng `SE16N` (bảng KALC / KALT, điền MANDT = client hiện tại, APPLID = `MR`).
- Nếu tên bảng cần schema, thêm tiền tố schema của hệ thống (VD `SAPxxx."KALC"`).
