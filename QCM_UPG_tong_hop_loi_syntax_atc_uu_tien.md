# QCM_UPG – Tổng hợp lỗi syntax và ATC theo thứ tự ưu tiên

Nguồn: `CodeABAP/QCM_UPG/06_Source Code 20261022/CHECK_ATC` (23 file kết quả ATC, chạy 21–22/10/2026) và `/syntax` (29 file danh mục đối tượng đã quét, 23/10/2026).
File kết quả chi tiết: `CodeABAP/QCM_UPG/06_Source Code 20261022/WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC.xlsx` (9 sheet: Tổng quan, Ưu tiên xử lý, Lỗi syntax, Theo object, Theo package, Theo người phụ trách, Chi tiết ATC, Danh mục đã quét, Include đã xóa).

## Kết luận

- ATC có **16.400 lượt phát hiện trên 799 object**: P1 1.758 lượt (296 object), P2 3.488 (422), P3 11.154 (671).
- **Lỗi syntax: 89 object (CLAS: 39, PROG: 38, FUGR: 9, ENHO: 3) với 292 thông điệp ATC.**
- Thư mục `/syntax` **không chứa lỗi**: là danh mục 38.070 đối tượng đã quét (37.790 OK, 280 Deleted – toàn bộ là include `LxxxT99` của nhóm hàm không còn tồn tại, không phải lỗi mã).
- **Độ phủ chưa đủ**: 6 package có danh mục trong /syntax nhưng không có file kết quả trong /CHECK_ATC: ZP_ABAP2XLSX (331 đối tượng); ZP_HDDT_EFPT (49 đối tượng); ZP_RETAIL (20.222 đối tượng); ZSPDD (1 đối tượng); ZUPG_ACTIVE_OBJ (7 đối tượng); Z_ASP_FPA_EXPORT_EXT (1 đối tượng). Riêng ZP_RETAIL có 1.160 chương trình, 191 lớp, 16.299 include nhóm hàm… nhưng chỉ xuất hiện 135 dòng ATC (2 chương trình nằm lẫn trong kết quả của ZP_HDDT và ZP_FICO). Không thể kết luận các package này 'sạch': cần chạy ATC bổ sung.
- Kết quả ATC chạy 21–22/10, trước lần xuất lại Class/Function_group ngày 23/10; sau khi sửa cần chạy lại ATC.

## Thứ tự xử lý đề xuất

| Bước | Nội dung |
|---|---|
| Bước 0 – Bổ sung độ phủ | Chạy ATC cho 6 package chưa có kết quả (đặc biệt ZP_RETAIL: 1.160 chương trình, 191 lớp) trước khi chốt danh sách lỗi. |
| Bước 1 – Sửa lỗi cú pháp | 89 object (CLAS 39, PROG 38, FUGR 9, ENHO 3); mở từng object, chạy Syntax Check rồi kích hoạt. Người phụ trách nhiều nhất: HRMS-DUNGDTX (30), V_BANGNV (24), HRMS-VINHDT (4), V_PHONG (3). Sheet 'Lỗi syntax'. |
| Bước 2 – Gọi sai/đối tượng không tồn tại | 48 lượt P1 (sai kiểu tham số hàm), 87 lượt P2 (hàm/SUBMIT/tham số/GUI status không tồn tại) và 123 lượt P3 'Used object … does not exist' (36 object) – dễ dump sau nâng cấp. |
| Bước 3 – Kết quả sai trên HANA | 22 lượt P1 (DELETE ADJACENT DUPLICATES/READ BINARY SEARCH trên kết quả SELECT không ORDER BY) – thêm ORDER BY/SORT; sau đó rà 834 lượt P3 (SELECT SINGLE không duy nhất…). |
| Bước 4 – Tương thích S/4HANA và WHERE bảng lớn | Nhóm 4: 74 P2 + 296 P3 (bảng có đối tượng thay thế, enhancement cấu trúc, hàm lỗi thời); nhóm 5: 90 P1 + 75 P2 (WHERE không dùng index/không có WHERE trên bảng lớn). |
| Bước 5 – Exception | 1.203 lượt P1 'Exception is not handled…' tập trung ở 107 object (sửa theo mẫu: TRY…CATCH hoặc khai báo RAISING), kèm 1.964 P2 và 944 P3. |
| Bước 6 – Phần còn lại | Thuộc tính bảng DDIC (change log 47 P1), GUI/Dynpro (56 P1), dọn dẹp mã, hiệu năng, câu lệnh nhạy cảm; thấp nhất là text element/message chưa định nghĩa (7.645 lượt P3). |

## Nhóm vấn đề × mức ATC (theo thứ tự ưu tiên nhóm)

| Nhóm vấn đề | P1 | P2 | P3 | Tổng lượt | Số object |
|---|---:|---:|---:|---:|---:|
| 1. Lỗi cú pháp – chương trình/lớp không biên dịch được | 292 | 0 | 0 | 292 | 89 |
| 2. Gọi hàm/chương trình/đối tượng sai hoặc không tồn tại – nguy cơ dump | 48 | 87 | 123 | 258 | 84 |
| 3. Kết quả sai trên HANA – SELECT không ORDER BY nhưng dùng thứ tự kết quả | 22 | 7 | 834 | 863 | 230 |
| 4. Tương thích S/4HANA – bảng thay thế, enhancement cấu trúc, API lỗi thời | 0 | 74 | 296 | 370 | 151 |
| 5. WHERE không dùng index/khóa trên bảng lớn (S/4HANA, HANA) | 90 | 75 | 0 | 165 | 79 |
| 6. Exception chưa xử lý/khai báo, xử lý rỗng | 1.203 | 1.964 | 944 | 4.111 | 327 |
| 7. Câu lệnh nhạy cảm (Native SQL, DB hint, CALL TRANSACTION, ROLLBACK, chương trình ngoài) | 0 | 23 | 241 | 264 | 101 |
| 8. Hiệu năng – SELECT *, bỏ qua buffer, FOR ALL ENTRIES, tham số truyền VALUE, bảng nội bộ | 0 | 954 | 59 | 1.013 | 252 |
| 9. Thuộc tính bảng DDIC (change log, buffering, index, client) | 47 | 17 | 188 | 252 | 177 |
| 10. Dọn dẹp mã (BREAK-POINT, mã không chạy tới, CASE trùng, ghi đè SY-field…) | 0 | 225 | 824 | 1.049 | 196 |
| 11. Text element/message/GUI chưa định nghĩa (đa ngôn ngữ) | 0 | 34 | 7.645 | 7.679 | 382 |
| 12. GUI/Dynpro – tiện dụng và khả năng truy cập | 56 | 28 | 0 | 84 | 54 |

## Thông điệp P1 (theo thứ tự ưu tiên)

| Nhóm | Check Title | Thông điệp | Số lượt | Số object |
|---:|---|---|---:|---:|
| 1 | Prerequisites for the extended program check (SLIN) | Program contains syntax errors | 73 | 73 |
| 1 | Low Performance Operations on Internal Tables | Syntax error in .... | 70 | 70 |
| 1 | Prerequisites for the test | Syntax error in .... | 70 | 70 |
| 1 | Extended Program Check (SLIN) | Method was not implemented | 67 | 7 |
| 1 | Extended Program Check (SLIN) | Syntax check warning with very high change priority | 4 | 4 |
| 1 | Extended Program Check (SLIN) | Byte-like values can use only the numbers 0-9 and the uppercase letters A-F | 3 | 1 |
| 1 | Extended Program Check (SLIN) | Illegal characters in ABAP source code | 2 | 1 |
| 1 | Prerequisites for the extended program check (SLIN) | Program source cannot be analyzed | 2 | 2 |
| 1 | Extended Program Check (SLIN) | Program does not exist | 1 | 1 |
| 2 | Extended Program Check (SLIN) | Formal parameter incompatible with actual parameter | 39 | 10 |
| 2 | Extended Program Check (SLIN) | Literal incompatible with formal parameter | 9 | 6 |
| 3 | Search problematic statements for result of SELECT/OPEN CURSOR without ORDER BY | DELETE ADJACENT DUPLICATES for result of statement at ... line ... | 12 | 7 |
| 3 | Search problematic statements for result of SELECT/OPEN CURSOR without ORDER BY | READ .. BINARY SEARCH for result of statement at ... line ... | 5 | 5 |
| 3 | Search problematic statements for result of SELECT/OPEN CURSOR without ORDER BY | LOOP AT itab. AT ... ENDAT. for result of statement at ... line ... | 4 | 2 |
| 3 | Search problematic statements for result of SELECT/OPEN CURSOR without ORDER BY | LOOP AT itab. ON CHANGE OF ... ENDON. for result of statement at ... line ... | 1 | 1 |
| 5 | Analysis of WHERE Condition for SELECT | S/4HANA - Large table ...: No field of a HDB table index in WHERE condition | 68 | 34 |
| 5 | Analysis of WHERE Condition for SELECT | Large table ...: No WHERE condition | 14 | 6 |
| 5 | Analysis of WHERE Condition in UPDATE and DELETE | S/4HANA - large table ...: WHERE condition does not contain any fields of an HDB table index | 6 | 2 |
| 5 | Analysis of WHERE Condition for SELECT | S/4HANA - Large table ...: No first field of a HDB table index in WHERE condition | 1 | 1 |
| 5 | Analysis of WHERE Condition in UPDATE and DELETE | Large table ...: No WHERE condition | 1 | 1 |

## Package có nhiều P1 nhất

| Package | Object lỗi syntax | P1 | P2 | P3 | Có kết quả ATC |
|---|---:|---:|---:|---:|---|
| ZP_VCM | 20 | 1.284 | 600 | 2.952 | Có |
| ZHR | 43 | 223 | 454 | 3.819 | Có |
| ZP_SU01 | 2 | 74 | 83 | 203 | Có |
| ZP_FICO | 11 | 56 | 538 | 1.570 | Có |
| ZMS | 1 | 28 | 148 | 419 | Có |
| ZP_HDDT | 0 | 21 | 272 | 617 | Có |
| Z001 | 2 | 15 | 162 | 705 | Có |
| ZP_ARIBA | 6 | 12 | 60 | 46 | Có |

## Người phụ trách (Contact Person) có nhiều P1 nhất

| Contact Person | Object | Object lỗi syntax | P1 | P2 | P3 |
|---|---:|---:|---:|---:|---:|
| V_BANGNV | 296 | 24 | 1.203 | 918 | 3.170 |
| HRMS-DUNGDTX | 59 | 30 | 151 | 9 | 55 |
| V_ANHNT19 | 21 | 2 | 85 | 37 | 381 |
| V_KHUPV | 16 | 0 | 80 | 26 | 357 |
| V_DUYPM1 | 71 | 3 | 49 | 268 | 927 |
| V_DUYND5 | 1 | 0 | 25 | 5 | 144 |
| HRMS-VINHDT | 40 | 6 | 23 | 152 | 446 |
| V_HAIBV2 | 22 | 0 | 19 | 39 | 188 |

## Ghi chú

- Mỗi object lỗi cú pháp thường xuất hiện 2 dòng (`Prerequisites for the test` và `Low Performance Operations on Internal Tables`) do cùng một nguyên nhân; sửa một lần là hết.
- ATC không báo số dòng; muốn xem dòng lỗi phải mở object trong SE38/ADT hoặc xem lại kết quả ATC trên hệ thống.
- Cách phân nhóm và thứ hạng (1 = khẩn nhất) do người lập đề xuất dựa trên ý nghĩa thông điệp; mức P1/P2/P3 là của ATC. Thông điệp P3 nhưng nên xem sớm (đối tượng không tồn tại, bảng có đối tượng thay thế) được đánh dấu ở cột Ghi chú của sheet 'Ưu tiên xử lý'.

## Ưu tiên theo tần suất ST03N

Sheet `Ưu tiên theo ST03N` và `Điểm vào ST03N` trong cùng file xlsx; phương pháp và ma trận ở sheet `Tổng quan`, mục 7. Nguồn: thư mục `ST03N` (ST03.ALL.0012.PRD, xuất 05/10/2026; 01/08–04/10/2026).

- Thước đo: số dialog step trong **5 tuần liên tiếp 31/08–04/10**. Tổng hợp tháng của ST03N thấp hơn đều ~30% so với tổng các tuần nên chỉ để tham khảo.
- Gắn tần suất vào object: giao dịch → chương trình (TSTC), báo cáo → chương trình, RFC → function module; lan truyền theo tham chiếu trong ExtractSAP (tối đa 4 cấp). Gián tiếp là ước tính chặn trên, tối đa xếp mức 'Cao'.
- Ngưỡng mức hoạt động: Rất cao ≥ 100.000 bước; Cao 10.000–99.999; Trung bình 500–9.999; Thấp 1–499.

| Mức nghiêm trọng \ Mức hoạt động | Rất cao | Cao | Trung bình | Thấp | Không xác định | Không thấy hoạt động |
|---|---|---|---|---|---|---|
| A – Nghiêm trọng | UT1 | UT1 | UT2 | UT2 | UT2 | UT3 |
| B – Cao | UT1 | UT2 | UT2 | UT3 | UT3 | UT4 |
| C – Trung bình | UT2 | UT3 | UT3 | UT4 | UT4 | UT4 |
| D – Thấp | UT3 | UT4 | UT4 | UT4 | UT4 | UT4 |

- Kết quả (799 object): Ưu tiên 1: 7 (lỗi syntax 2); Ưu tiên 2: 141 (lỗi syntax 67); Ưu tiên 3: 148 (lỗi syntax 20); Ưu tiên 4: 503 (lỗi syntax 0).
- Mức hoạt động: Rất cao: 3; Cao: 39; Trung bình: 119; Thấp: 86; Không xác định: 264; Không thấy hoạt động: 288.

**Ưu tiên 1 – làm ngay** (lỗi nặng trên đối tượng đang chạy nhiều):

| Object | Loại | Mức nghiêm trọng | P1 | Bước 5 tuần | Điểm vào chính |
|---|---|---|---:|---:|---|
| ZPG_FI_ACC_POST_FI | PROG | A | 2 | 166.405 | ZFI023A (giao dịch, 165.172 bước, trực tiếp) |
| ZPG_RT_309_GI_FROM_STO | PROG | A | 21 | 142.258 | ZPG_RT_309_GI_FROM_STO (báo cáo, 142.258 bước, trực tiếp) |
| ZPG_FI_WF_TS00407862_MASS | PROG | A | 3 | 46.827 | ZWF001 (giao dịch, 46.618 bước, trực tiếp) |
| ZPG_IDPRCNINVOICE_E | PROG | A | 4 | 46.170 | ZFI026E (giao dịch, 31.247 bước, trực tiếp) |
| ZPG_FI_076_MIGO_241_N | PROG | A | 28 | 19.379 | ZFI076N (giao dịch, 19.301 bước, trực tiếp) |
| ZFI_ITEMS | FUGR | A | 3 | 17.572 | ZFI072 (giao dịch, 14.475 bước, gián tiếp, độ sâu 2) |
| ZPG_FI_083_MASS_UPDATE_DOCS | PROG | B | 71 | 197.545 | ZFI083 (giao dịch, 197.523 bước, trực tiếp) |

**Lưu ý**

- Package không có giao dịch nào xuất hiện trong ST03N (ZHR: 0/114 giao dịch Z có hoạt động) nhiều khả năng chạy ở hệ thống khác (HR) – các object đó xếp 'Không xác định', không kết luận là không dùng.
- File ST03N chính chỉ có đối tượng Z (không có giao dịch chuẩn SAP) nên BAdI/enhancement không đo được; kỳ quan sát ~2 tháng nên đối tượng chạy theo quý/năm có thể không xuất hiện – xác nhận với nghiệp vụ trước khi loại bỏ.
- Sheet `Điểm vào ST03N` liệt kê 554 giao dịch/báo cáo/RFC Z kèm số object ATC liên quan; nhiều giao dịch chạy rất nhiều (ZRT149, ZRT116, ZRT191…) nhưng chương trình đích không có lỗi ATC.

## Cột tcode

Đã thêm cột tcode vào các sheet `Ưu tiên xử lý`, `Ưu tiên theo ST03N`, `Điểm vào ST03N`, `Lỗi syntax`, `Theo object`, `Chi tiết ATC` (mục 8 sheet `Tổng quan`).

- Nguồn: `EXPORT_20261021_100735.xlsx` (500 giao dịch Z), `TSTCP.xlsx` (197 giao dịch tham số, 97 cái là `/*SM30 VIEWNAME=<bảng>`); bổ sung từ `TCODE_TSTC` của ExtractSAP (912 tcode, chứa đủ 500 tcode của EXPORT, chương trình trùng 100%).
- **Tcode (trực tiếp)**: tcode chạy chương trình/nhóm hàm chứa object, hoặc bảo trì bảng/view qua SM30. **Tcode (gián tiếp)**: tcode đi tới object qua chuỗi gọi (tối đa 4 cấp), hiển thị số lượng và 5 tcode đầu.
- Phủ: 331/799 object có tcode trực tiếp (PROG 314/386, TABL 12/171, SSFO 5/8), 170 chỉ có tcode gián tiếp, 298 không có (class, enhancement, include/chương trình chỉ chạy bằng job).
