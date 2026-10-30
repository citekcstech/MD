# QCM_UPG – Bổ sung LiveCompare và ZP_RETAIL vào 2 file tổng hợp (29/10/2026)

Yêu cầu: đọc `LiveCompare/LiveCompare_2026_Aug_Sep.xlsx` và thư mục QCM_UPG, xem có gì bổ sung cho `WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx`; sau đó làm tương tự cho `Citek_WCM_ATC_PhanCong_v1.1.xlsx`. Dòng bổ sung tô vàng. Bản gốc: `*_truoc_khi_bo_sung_29.10.xlsx` cạnh từng file.

## 1. LiveCompare là gì
SAP LiveCompare so sánh **As-Is ECC_DEV** với **To-Be S4_DEV (DS4, kernel 916)**, xuất 28/10/2026. Các sheet: Used (509) / Unused (2.588), Impacted~Top Down/Bottom Up/SSFO (9.851 / 9.851 / 1.378 dòng), BDC (43), Complexity (8.097), quét tĩnh có số dòng: HANA 23.430, Failures 2.164, Missing 7.090, Obsolete 266, Internal 30, ABAP Objects 68, Performance 47.594, Reliability 93.188, Documentation 14.288, Security 8.030; SPDD 213, SPAU 1.399; System Info.

Điểm cần nhớ khi dùng:
- Số dòng theo source **ECC DEV**, có thể lệch source DS4 trong thư mục (ví dụ `ZPR_RT_STO_FORM_VM_E` lệch +34 dòng). Với object này LiveCompare báo đúng 4 lệnh BREAK (83 và 1336 của `ZIN_METHOD_DELIVERY`, 1326 và 1937 của chương trình chính), khớp 4 thông điệp BREAK-POINT của ATC.
- `Used/Unused` là lịch sử hiệu năng của ECC DEV, **không phải PRD** → chỉ tham khảo; ưu tiên theo tần suất vẫn dùng ST03N PRD.
- `Impacted` chỉ gồm chương trình có trong `Used` (282 chương trình). `In1` hiểu là đối tượng chỉ có ở As-Is, không thấy ở To-Be (**cần xác nhận trên DS4**): 27 đối tượng, 21 chương trình dùng, 10 chương trình chưa có trong ATC. Gồm FUNC `MGV_SELOP_AFTER_INITIALIZATION`/`…_START_OF_SEL` (ZPG_RT_BBY_OUTBOUND_D/E, ZPG_MD_NEW_RWDPOSAN), include `ML01A*` (ZPG_MM_RT110, ZPG_IF_ALLOCATIONTABLE), `I_RFUMS_EUVA_FORMS` (ZPR_FI_RFUMSV00/N), 4 ENHO của RM07MSQL (ZPG_RT_RM07IDIF) và `ISAUTO_MRM_MRM_CONST_MRM`, class `CL_SALV_FULLSCREEN_ADAPTER` (ZPG_RT_PLANNING_WORKBENCH_N), 10 SAP Query `AQZZZ…`.
- Các luật quét tĩnh không phải kết quả ATC; một lỗi có thể xuất hiện ở cả hai.

## 2. Đã bổ sung gì
### WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx (openpyxl)
| Phần | Nội dung |
|---|---|
| Chi tiết ATC, Theo object, Ưu tiên theo ST03N, Lỗi syntax | +21.779 lượt ATC, +806 object (ZP_RETAIL 716, ZP_ABAP2XLSX 90), +806 dòng ST03N, +5 object lỗi syntax; tô vàng ở cuối bảng |
| Theo package | 2 dòng ZP_RETAIL, ZP_ABAP2XLSX cập nhật (trước ghi "chưa có ATC") |
| Tổng quan | Mục 9 (tô vàng): nguồn, số liệu, khác cách tính, hạn chế, chưa đưa vào |
| Bổ sung ZP_RETAIL (mới) | Phần chênh theo mức, package, ưu tiên (8 / 91 / 94 / 613), nhóm vấn đề, người phụ trách, 40 thông điệp nhiều nhất |
| LC - Dòng code (mới) | 5.311 dòng: Failures (Error), `$HANA PP*` + dòng SELECT kích hoạt, EXEC SQL, DB Hints, Obsolete, Internal, ABAP Objects, SELECT thiếu WHERE; kèm package, người phụ trách, ưu tiên ST03N |
| LC - Tác động S4 (mới) | 282 chương trình bị ảnh hưởng, số object theo loại, In1 |
| LC - Object bị xóa (mới) | 27 đối tượng In1, chương trình/tcode dùng, hướng xử lý đề xuất |

Các sheet tổng hợp (Ưu tiên xử lý, Điểm vào ST03N, Theo người phụ trách) và số ở Tổng quan mục 3–7 **giữ số 23/10** (799 object, 16.400 lượt); phần chênh nằm ở sheet `Bổ sung ZP_RETAIL`. Phần bổ sung áp dụng đính chính 27/10: object có package check OK thì "Syntax error in ...." là số liệu ATC cũ (62 object, 121 dòng bỏ ra), nên chỉ 5 object mới vào "Lỗi syntax"; phần 23/10 giữ nguyên 86 object OK.

### Citek_WCM_ATC_PhanCong_v1.1.xlsx (vá XML)
Thêm ZP_RETAIL/ZP_ABAP2XLSX theo quy trình 27/10: 837 task mới (1.746 task; 793 task ≈ 205 MD chưa phân công); tô vàng 837 dòng Task List, 26 dòng Ưu tiên xử lý, 806 dòng Ưu tiên theo ST03N, 5 dòng Lỗi syntax; 3 sheet `LC - …` (cột ưu tiên theo ST03N hiện tại của file). Không tạo task từ LiveCompare. Ghi chú ở A2 sheet PhanCong_DEV. Trạng thái/phân công lấy theo kết quả 27/10 (gồm chỉnh tay của team lúc đó). Dòng UT cũ đổi số lượt không tô vàng.

## 3. Chưa làm / lưu ý
- Chưa đưa Performance, Reliability, Documentation, Security, Complexity, Unused, các luật Missing còn lại vào file (khối lượng lớn, chủ yếu gợi ý chất lượng mã). SPDD 213 / SPAU 1.399 của LiveCompare nên đối chiếu với `NEXUS_Plan_ABAP_V1.0.xlsx` (sheet SPDD, SPAU), không để ở 2 file này.
- ZP_HDDT_EFPT, ZSPDD, ZUPG_ACTIVE_OBJ, Z_ASP_FPA_EXPORT_EXT vẫn chưa có kết quả ATC.
- Chưa mở 2 file bằng Excel thật; kiểm tra bằng XML hợp lệ + openpyxl nạp lại (file 1: phần cũ không đổi dòng nào; file 2: 0 sai lệch task↔sheet, 0 vi phạm thứ tự ST03N).
- ~20% dòng LiveCompare không tra được package (include không có trong danh mục /syntax).
