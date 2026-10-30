# QCM_UPG – Dòng "Ưu tiên xử lý" có cột Tcode (trực tiếp) trống (29/10/2026)

File: `CodeABAP/QCM_UPG/Citek_WCM_ATC_PhanCong_v1.1.xlsx`, sheet "Ưu tiên xử lý" (169 dòng, mỗi dòng = 1 thông điệp ATC gộp).

**Object** = đối tượng repository ABAP mà ATC báo lỗi (PROG, CLAS, FUGR, TABL, VIEW, ENHO…). Cột "Số object" = số object cùng bị thông điệp đó. Danh sách object cụ thể: sheet "Chi tiết ATC", lọc theo Check Message (cột Object, Loại, Package).
Cột Tcode (trực tiếp) trống = không object nào của thông điệp có tcode chạy trực tiếp (chương trình đích của tcode chứa object, hoặc tcode SM30 của bảng).

## Số liệu
- 39 / 169 dòng trống (704 / 37.967 lượt ≈ 1,9%): P1 12, P2 11, P3 16.
- 131 object: TABL 39, FUGR 35, CLAS 25, PROG 16, ENHO 7, VIEW 7, XINX 1, WDYN 1.
- Hoạt động ST03N của 131 object: không thấy 48, không xác định 43, trung bình 15, cao 13, thấp 12. 32 object có tcode gián tiếp.
- Trống ≠ không dùng: bảng/view/class/nhóm hàm/enhancement vốn không có tcode trực tiếp; class/ENHO/BAdI/ZHR ST03N không đo được.

## Phân loại 39 dòng
**A. Có hoạt động hoặc tcode gián tiếp → xử lý theo mức (19 dòng, 208 lượt)**: UT-028, 071, 074, 084, 082, 085, 083, 046, 047, 131, 132, 133, 134, 151, 136, 157, 110, 160, 138.
**B. Không đo được (ENHO/BAdI/class/ZHR) → xác nhận đang dùng rồi xử lý (7 dòng, 458 lượt)**: UT-031 (341 lượt, Dynpro 'X field' 8 object), 013 (Method was not implemented, 10 class), 033, 001 (ENHO 'Program contains syntax errors', 6 object), 086, 139, 169. UT-031/033 thuộc nhóm GUI tiện dụng (accessibility), không gây dump dù ATC xếp P1.
**C. Toàn object không thấy hoạt động → hoãn/cân nhắc loại bỏ (13 dòng, 38 lượt)**: UT-002 (2 chương trình demo ZDEMO_EXCEL26/32), 005, 036, 023, 015, 024, 026, 087, 097, 155, 137, 126, 111. Chỉ loại bỏ sau khi nghiệp vụ xác nhận (kỳ ST03N chỉ ~2 tháng; chương trình chạy theo quý/năm có thể không xuất hiện).

Ra quyết định theo mức nghiêm trọng và hoạt động của object (sheet "Ưu tiên theo ST03N"), không theo riêng cột tcode.

## Đính chính và 2 cột đã thêm vào bản sao (29/10/2026)
- Bản đầu xếp UT-002 vào nhóm A do gộp 2 nhóm vấn đề có cùng thông điệp "Syntax check warning with very high change priority" (7 chương trình ở nhóm 4 có hoạt động). Dòng UT-002 thuộc nhóm 1 và chỉ có 2 chương trình demo không hoạt động → nhóm C. Số đúng: A 19 / B 7 / C 13.
- Hai cột nằm trong bản sao `Citek_WCM_ATC_PhanCong_v1.1_them_cot_link_ST03N.xlsx` (file v1.1 gốc đang mở trong Excel nên không ghi đè). Cột R "Phân loại tcode trống" (A/B/C) ở sheet "Ưu tiên xử lý" (chỉ ghi chú, không đổi trạng thái/phân công); autofilter mở rộng A4:R173.
- Cột E "Link ST03N" chèn vào bảng `tblWCM` của sheet "WCM Task List", ngay sau "Link chi tiết": task ST/SY → dòng của chính object trong "Ưu tiên theo ST03N"; task UT → dòng của object đứng đầu thứ tự ưu tiên trong các object của thông điệp (kèm tên object). Mọi tham chiếu cột ≥ E (công thức TG dự kiến, 245 công thức ở PhanCong_DEV/DEV Status, data validation, độ rộng cột, định nghĩa bảng) đã dịch sang phải 1 cột. File v1.1 gốc giữ nguyên.

## Cập nhật file dùng chung (29/10/2026 14:28)
Hai cột trên (E "Link ST03N" ở WCM Task List, R "Phân loại tcode trống" ở Ưu tiên xử lý) cùng 3 sheet `LC - …` đã được thêm trực tiếp vào `Citek_WCM_ATC_PhanCong_v1.0.xlsx` trong thư mục `Tổng hợp` (SharePoint). "Tình Trạng DEV" và phân công của đích giữ nguyên. Bản trước khi cập nhật: `CodeABAP/QCM_UPG/Citek_WCM_ATC_PhanCong_v1.0_shared_truoc_khi_cap_nhat_29.10.xlsx`.
