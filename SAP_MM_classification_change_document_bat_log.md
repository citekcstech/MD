# Log đổi VALUE Characteristic ở MM02 (Classification) — cách bật và cách xem

Nguồn: tra web (SAP KBA/community), **chưa kiểm chứng trên hệ DE1/900** — thử ở DEV trước.

## Bản chất
- Log nằm ở change document object **CLASSIFY** (`CDHDR`/`CDPOS`, `TABNAME = 'AUSP'`), không nằm trong MM04 (change log material master thường).
- Bật theo **Class Type** (vd 001), không bật riêng từng Characteristic, cũng không bật ở MM02.
- Mặc định **tắt**.

## Cách bật
1. Vào **O1CL** (IMG: Maintain Object Types and Class Types) → chọn Class Type (vd 001).
2. Class Type phải bật **Multiple objs allowed** trước, rồi mới tích được **Change docs**.
3. Trên màn hình O1CL (Object Table MARA → Class Types → chi tiết 001), nhóm **Classifications** có 3 ô: ECH (time), ECH (parameter), **Change Docs**. Tích **Change Docs**; ECH và Change Docs loại trừ nhau (nguồn answers.sap.com 529870). Không cần vào node Objects. Cờ là `TCLA-AEBLGZUORD`, cờ multiple objs là `TCLA-MULTOBJ` (xem câu 4 trong file .sql). Vị trí ô xác nhận bằng ảnh màn hình DE1/900.
4. Class Type đã có data phân loại → làm theo **SAP Note 1705101** (chạy report chuyển khóa phân loại, `RCCLUKA2`; một nguồn khác ghi `RCLAUSPT`, kiểm lại theo release) rồi mới bật cờ. Sau chuyển đổi, code custom đọc thẳng `KSSK`/`AUSP` có thể phải sửa.
5. Cấu hình O1CL cần TR → đẩy QAS/PRD theo quy trình.

## Giới hạn đã biết
- Chỉ ghi từ lúc bật, không có log cho các lần đổi trước đó.
- Đổi qua **MDC Mass Processing** không sinh log CLASSIFY; qua MM02 thì có.
- Xoá class assignment khỏi material → change document của assignment đó không tra lại được.
- KBA 3320279: đổi classification ở MM02 không vào change pointer (`BDCP2`).

## Đã gặp trên DE1/900 (02.11.2026)
- Màn hình O1CL class type 001 / MARA: Multiple objs allowed hiện đã tích, Change Docs chưa tích. Popup: "At least one object of type MARA has been assigned to at least one class of class type 001. Before you can classify further objects ... you must start program RCCLUKA2. This program also sets the 'Multiple Objs Allowed' indicator."
- Nghĩa: **bắt buộc chạy RCCLUKA2 trước** (Note 942691/1705101); ô Multiple objs đang tích trên màn hình có thể chỉ là thao tác vừa tích, chưa chắc đã lưu trong DB — kiểm `TCLA-MULTOBJ` bằng câu 4.
- Chưa xác nhận: RCCLUKA2 chạy phải ở từng hệ/client (suy luận, vì là report chuyển dữ liệu, không đi theo transport).

## Ảnh hưởng sang phần khác
- **Có nguồn**: bước chuyển khóa phân loại (`RCCLUKA2`, Note 1705101) đổi khóa classification → code custom đọc thẳng `KSSK`/`AUSP` có thể hỏng. Chỉ phải chạy nếu Class Type 001 **chưa** bật Multiple objs.
- **Suy luận, chưa xác nhận**: mỗi lần đổi value sinh thêm dòng `CDHDR`/`CDPOS` → bảng phình, load hàng loạt (BAPI/LSMW/interface) chậm hơn.
- Dự kiến không ảnh hưởng: Class Type khác, master Characteristic/Class (CT04/CL02), cách nhập ở MM02.
- Việc cần làm trước: chạy câu 4–5 trong `query_log_change_classification_characteristic.sql` để biết 001 đã bật Multiple objs chưa.

## Cách xem
- `CDHDR`/`CDPOS` với `OBJECTCLAS = 'CLASSIFY'` hoặc report `RSSCD100`.
- Query mẫu: `query_log_change_classification_characteristic.sql` (cùng thư mục).

## Nguồn
- https://www.saptechnicalguru.com/tag/change-documents/
- https://userapps.support.sap.com/sap/support/knowledge/en/1705101
- https://userapps.support.sap.com/sap/support/knowledge/en/3320279
- https://community.sap.com/t5/application-development-and-automation-discussions/change-documents-for-material-classification-data-changes/m-p/8558846
