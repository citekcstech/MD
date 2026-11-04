# Lỗi sau upgrade ECC → S/4HANA 2025: `FORM "SET_SHELL_STATE" does not exist` (ZPG_MM_RT110 / include ML01AO0X)

## 1. Hiện tượng (từ ảnh chụp SE80/SE38)

- Chương trình Z: `ZPG_MM_RT110` (Create/Change/Display/Edit Allocation Table).
- Include: `ML01AO0X`, module `xaupo_init OUTPUT`, dòng 13:

```abap
MODULE xaupo_init OUTPUT.
  PERFORM xaupo_init_dyn.
*  To Handle Dirty State
  PERFORM set_shell_state.      " <-- dòng 13, lỗi
ENDMODULE.
```

- Syntax check: **1 error** — `FORM "SET_SHELL_STATE" does not exist`.
- Các dòng vàng (ML01AF2B dòng 179, 671, 500…: `CLIENT SPECIFIED` → `USING CLIENT`) chỉ là **warning**, không chặn kích hoạt. Chỉ cần sửa lỗi đỏ trước.

## 2. Nguyên nhân (nhận định)

Nhìn cây object: `ZPG_MM_RT110` dùng **trực tiếp các include chuẩn của SAP** (`ML01AO0X`, `ML01ACDC`, `ML01ACDV`, `ML01AF0A`…, không có tiền tố Z). Tức là chương trình Z là bản copy "vỏ" của program SAP, còn include dùng chung với bản chuẩn.

Khi upgrade lên S/4HANA 2025:
1. Include `ML01AO0X` đã đổi nội dung (xuất hiện `PERFORM set_shell_state`).
2. Nhưng `FORM set_shell_state` được định nghĩa ở nơi khác (include mới / main program chuẩn) mà chương trình Z **không include** → báo FORM không tồn tại.

> Lưu ý: đây là nhận định từ ảnh, chưa xác nhận được trên hệ thống. Cần làm bước 3 để biết chính xác `set_shell_state` nằm ở đâu và ai thêm dòng PERFORM đó (SAP hay người dùng).

## 3. Cách xử lý

### Bước 1 — Xác định include thuộc về ai, ai sửa
- Trong `ML01AO0X`: **Utilities → Versions → Version Management** (hoặc Goto → Attributes): xem Package, Last changed by, Release. Nếu dòng `PERFORM set_shell_state` + comment `To Handle Dirty State` nằm ở version do user sửa → là modification của dự án; nếu nằm ở version của SAP (upgrade) → là thay đổi chuẩn.
- SE16N bảng `D010INC`: `INCLUDE = 'ML01AO0X'` → cột `MASTER` cho biết **program chuẩn nào** đang include nó (đây là program gốc để so sánh).

### Bước 2 — Tìm FORM `set_shell_state` nằm ở đâu
- Mở program gốc (master tìm được ở bước 1) trong SE38/SE80, Ctrl+F → `set_shell_state` → chọn **"In main program"** (tìm trong cả include). Hoặc dùng `RPR_ABAP_SOURCE_SCAN` (SE38) với program gốc.
- Ghi lại tên include chứa `FORM set_shell_state` (ví dụ `ML01Axxx`).

### Bước 3 — So sánh danh sách include của program gốc vs. `ZPG_MM_RT110`
- SE16N `D010INC` với `MASTER = <program gốc>` và `MASTER = 'ZPG_MM_RT110'` → include nào có ở gốc mà Z thiếu = include SAP thêm mới trong S/4.

### Bước 4 — Sửa (chọn 1)
| Hướng | Làm gì | Khi nào dùng |
|---|---|---|
| **A. Đồng bộ lại Z với chuẩn (nhanh nhất)** | Thêm `INCLUDE <include chứa set_shell_state>.` (và các include mới khác nếu có) vào main/TOP của `ZPG_MM_RT110`, đúng thứ tự như program gốc; kích hoạt, syntax check lại cả program (Ctrl+F2) | Chương trình Z ít thay đổi so với chuẩn |
| **B. Copy lại từ program chuẩn S/4** | SE38 → Copy program gốc (kèm include) → áp lại phần custom (dùng Version Compare / SE95 Modification Browser để lấy diff từ bản ECC) | Chương trình Z bị lệch nhiều so với chuẩn, hoặc đi A mà phát sinh thêm nhiều lỗi |
| **C. Bỏ copy, dùng chuẩn + enhancement** | Gọi transaction/program chuẩn, đưa phần custom vào BAdI / enhancement spot / user exit | Hướng dài hạn, ít vỡ nhất khi upgrade tiếp |

- **Không** sửa trực tiếp `ML01AO0X` để "xóa dòng PERFORM" cho hết lỗi: include đang dùng chung với chuẩn nên sẽ thành modification, và lúc chạy chuẩn có thể bỏ sót logic Dirty/Shell State.
- Nếu `FORM set_shell_state` thực sự chỉ có trong chương trình Z cũ (custom) mà bị mất lúc upgrade → khôi phục từ transport/version ECC, đặt vào include Z riêng (ví dụ `ZPG_MM_RT110_F01`).

### Bước 5 — Xử lý hậu kiểm
- Sau khi hết lỗi đỏ, sửa nốt warning `CLIENT SPECIFIED` → `USING CLIENT` (chỉ sửa nếu code nằm trong include Z; code trong include chuẩn SAP thì bỏ qua).
- Chạy ATC với check variant **S/4HANA readiness** (SCI/ATC, `SYCM`) cho các Z program còn lại để bắt các lỗi tương tự (Z copy từ chuẩn → lệch sau upgrade) — đặc biệt các Z program dùng include chuẩn trực tiếp.
- Chạy thử transaction thật (không chỉ syntax check) vì `xaupo_init` là PBO module → lỗi runtime sẽ xuất hiện ngay khi mở màn hình.

## 4. Quy tắc chung cho các lỗi tương tự sau upgrade

- "Form/Function/Include does not exist" trong Z program copy từ chuẩn ⇒ hầu như luôn là **include chuẩn đã đổi, còn program Z đã copy từ bản cũ** → so sánh với program gốc trong S/4 rồi đồng bộ lại.
- Đi theo thứ tự: tìm master (D010INC) → tìm nơi định nghĩa (Find in main program) → so include list → đồng bộ/copy lại.
- Search SAP Notes/KBA theo tên object + release nếu chuẩn đã đổi (không tìm được kết quả web cho `SET_SHELL_STATE`/`ML01AO0X` khi tra cứu lần này).
