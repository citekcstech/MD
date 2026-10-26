# WCM – Phân công 4 DEV xử lý lỗi syntax / ATC

Ngày lập: 26/10/2026 · Mẫu: `Citek_BIDIPHAR_RICEWF_v1.0.xlsx` · Nguồn task: `WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx`

**File kết quả:** `CodeABAP/CITEK_RETAIL/Citek_WCM_ATC_PhanCong_v1.0.xlsx`

| Sheet | Nội dung (tương ứng sheet mẫu) |
|---|---|
| `PhanCong_DEV` | Tải theo người, ma trận Nhóm ưu tiên × ABAP (số task + MD), quy tắc chia, cách ước tính MD, lưu ý chồng lấn (mẫu: `GiaoCung_A2`/`SoSanh_PhuongAn`) |
| `DEV Status` | Đếm theo ABAP × Tình Trạng DEV / Test, theo Nhóm ưu tiên; tới hạn/trễ deadline, MD hoàn thành (mẫu: `DEV Status`) |
| `WCM Task List` | 1.034 task (bảng `tblWCM`), cột ABAP Phụ trách / Tình Trạng DEV / TG / Test / Note (mẫu: `RICEWF List`). **Cột D "Link chi tiết"** (thêm 26/10 sau khi anh Sang move 3 sheet chi tiết vào file): bấm → nhảy tới đúng dòng task ở sheet chi tiết |
| `TT` | Danh sách 4 DEV + công suất (mẫu: `TT`) |
| `Ưu tiên xử lý`, `Ưu tiên theo ST03N`, `Lỗi syntax` | 3 sheet chi tiết nguồn (anh Sang move vào file) |

**Tcode bị cắt "(+19)" ở sheet `Ưu tiên xử lý`:** cột K chỉ hiện tối đa 10 tcode (theo tiêu đề cột). Bản `Citek_WCM_ATC_PhanCong_v1.0_tcode_day_du.xlsx` thêm **cột L "Tcode (trực tiếp) – đầy đủ"** (K giữ nguyên): dựng từ sheet `Chi tiết ATC` + `Điểm vào ST03N` của `WCM_NEXUS_Tong_Hop_Loi_Syntax_ATC_v1.0.xlsx`, đối chiếu 146/146 dòng khớp cột J (số tcode) và 10 tcode đầu của cột K; 1 tcode (`ZHR_QUERY_TM_HIDE`) bù từ `TSTC Bổ sung.xlsx`. Còn **chưa** thay vào file chính vì file đang mở trong Excel. Cột "Tcode (gián tiếp)" ở sheet `Ưu tiên theo ST03N` (29 ô) và `Lỗi syntax` (3 ô) cũng bị cắt "(+n)", chưa xử lý.

Link ở cột D: `=IFERROR(HYPERLINK("#'<sheet>'!A<dòng>:<cột cuối><dòng>","→ dòng <dòng>"),"Không thấy")`, dòng = MATCH(số STT trong Mã task, cột A sheet chi tiết) nên vẫn đúng khi sort/lọc sheet chi tiết. Sheet chi tiết bị **đổi tên** thì link hiện "Không thấy". Bản gốc trước khi thêm link: `Citek_WCM_ATC_PhanCong_v1.0_goc_truoc_khi_them_link.xlsx` (cùng thư mục, xoá được).

Task: 146 từ "Ưu tiên xử lý" (UT-xxx) + 799 từ "Ưu tiên theo ST03N" (ST-xxxx) + 89 từ "Lỗi syntax" (SY-xxx).

## Phân công

| DEV | Công suất | Task | MD (ước tính sơ bộ) | Phạm vi |
|---|---|---|---|---|
| Lê Đa Khoa | 100% | 59 | 176,9 | UT P1 (anh Sang chốt) + P2/P3 nhóm Exception, SELECT không ORDER BY trên HANA, WHERE không dùng index |
| Bùi Viết Quý | 100% | 556 | 189,3 | ST03N Ưu tiên 1 (anh Sang chốt) + Ưu tiên 2–4 mọi package trừ ZHR (bỏ object dính lỗi syntax) |
| Trần Thanh Phát | **100%** | 371 | 175,7 | Lỗi syntax (anh Sang chốt) + phần ATC còn lại của các object đó + toàn bộ package ZHR + P2/P3 nhóm Gọi hàm sai, DDIC, GUI/Dynpro, S/4HANA, Text element |
| Đặng Hoàng Danh | 50% | 48 | 84,8 (≈ 170 nếu quy 100%) | P2/P3 nhóm Hiệu năng, Dọn dẹp mã, Câu lệnh nhạy cảm |

Phát: anh Sang xác nhận 26/10 là làm 100% cho WCM (không giảm tải vì BDP), nên chia ngang Khoa/Quý.

## Quy tắc

- R1: giữ nguyên việc anh Sang đã chốt (Khoa UT P1, Quý ST03N Ưu tiên 1, Phát Lỗi syntax).
- R2: 1 object – 1 người. Cả 89 object Lỗi syntax đều có trong ST03N → cùng người sửa. Riêng 2 object thuộc Ưu tiên 1 (ZPG_FI_WF_TS00407862_MASS, ZFI_ITEMS) → Quý (**điểm duy nhất khác phân công anh Sang nêu**: 2 task SY chuyển Phát → Quý).
- R3: UT P2/P3 chia theo Nhóm vấn đề (cùng cách sửa).
- R4: ST03N Ưu tiên 2–4 chia theo package: ZHR → Phát (đã có 43 object lỗi syntax ở đó), còn lại → Quý.

## Lưu ý cần chốt

1. **3 sheet nguồn chồng lấn:** cùng 16.400 lượt ATC được phân rã theo thông điệp (UT) và theo object (ST03N). MD 2 cách xấp xỉ nhau (≈ 325 vs ≈ 302) → khối lượng thật chỉ ≈ 300–330 MD, không phải tổng 626,7.
2. UT-001..009 (Khoa, ≈ 50 MD) chính là lỗi syntax của 89 object Phát xử lý → Phát làm xong thì Khoa đóng 9 task này, Khoa có thêm ≈ 50 MD trống.
3. MD là **ước tính sơ bộ do mình đặt hệ số** (cách tính ở `PhanCong_DEV` mục 5), cần anh Sang chỉnh theo kinh nghiệm thực tế.
4. Cột "TG dự kiến hoàn thành lập trình" để trống (chưa có lịch).
5. Chưa mở được bằng Excel trong phiên (không có Excel/LibreOffice): đã kiểm tra cấu trúc file và tự tính lại 289 ô công thức, khớp 100%.
