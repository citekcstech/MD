# ST03N — thống kê API (RFC / HTTP-OData-SOAP) được gọi trong 3 tháng gần nhất

Ngày soạn: 26.10.2026. "3 tháng gần nhất" = 26.07.2026 → 26.10.2026.

## 0. "API" ở đây là loại nào?

ST03N không có khái niệm "API", chỉ có các loại tác vụ (task type). Chọn view theo loại:

| Loại API | Chiều | Xem ở đâu trong ST03N |
|---|---|---|
| RFC / BAPI / Z function module (hệ thống ngoài gọi vào SAP) | Inbound | Analysis Views → **RFC Profile → phía Server** |
| OData / ICF service / SOAP service (gọi HTTP vào SAP) | Inbound | Analysis Views → **Transaction Profile**, lọc loại tác vụ **HTTP(S)** — cột tên là đường dẫn ICF/service |
| SAP gọi RFC ra hệ thống ngoài | Outbound | Analysis Views → **RFC Profile → phía Client** |
| SAP gọi HTTP/SOAP ra ngoài (CL_HTTP_CLIENT, proxy) | Outbound | **Không có trong ST03N** → xem mục 6 |

Tên menu có thể lệch nhẹ theo release (ECC / S/4HANA).

## 1. Kiểm tra dữ liệu còn lưu được bao lâu (làm trước)

ST03N chỉ giữ dữ liệu tổng hợp trong thời gian đã cấu hình; quá hạn thì job reorganize xoá. Nếu hệ thống chỉ giữ 2 tháng thì không thể có đủ 3 tháng.

1. Chạy `ST03N` → đổi chế độ sang **Expert mode** (dropdown góc trên bên trái; ở Administrator mode không thấy kỳ dài).
2. Cây trái: **Collector & Performance DB → Performance Database → Reorganization** (hoặc **Workload Collector Database → Reorganization → Control**) → xem số ngày/tuần/tháng giữ lại cho từng loại (Day / Week / Month, riêng "Transaction Profile" và "RFC Profile").
3. Hoặc xem nhanh: cây trái **Workload → <hệ thống> → Total → Month**, danh sách tháng hiện ra là các tháng còn dữ liệu.

Mặc định các nguồn tham khảo không thống nhất (2 / 3 / 12 tháng tuỳ release và cấu hình) → phải xem trên chính hệ thống. Tăng retention chỉ có tác dụng từ thời điểm đổi trở đi, không lấy lại được dữ liệu đã xoá.

## 2. Chọn đúng hệ thống và kỳ

1. Đăng nhập **PRD** (hệ thống có lưu lượng thật), client có API chạy.
2. `ST03N` → Expert mode.
3. Cây trái: **Workload → TOTAL** (gộp mọi app server; nếu nhiều instance mà không có TOTAL thì làm từng instance rồi cộng).
4. Chọn kỳ **Month** → nhấp đúp từng tháng cần xem. Với 3 tháng gần nhất (hôm nay 26.10):
   - Tháng 08, tháng 09: đủ tháng.
   - Tháng 10: tháng đang chạy, chỉ đến hôm nay.
   - Tháng 07: chỉ cần phần từ 26.07; tháng 07 aggregate là cả tháng → nếu muốn đúng 3 tháng tròn thì lấy 07, 08, 09 (+10 nếu muốn phần mới nhất) và ghi rõ phạm vi.
5. **Không trộn** dữ liệu Month với Week/Day: ở lần xuất 05.10.2026 (PRD 0012) tổng tháng thấp hơn tổng các tuần khoảng 30% một cách đồng đều → chọn một cơ sở (khuyến nghị: Month) cho cả 3 tháng.

## 3. Lấy danh sách RFC (inbound)

1. Trong từng tháng đã chọn: **Analysis Views → RFC Profile** (đôi khi nằm trong "Aggregated RFC Statistics").
2. Mở phía **Server** (SAP là bên được gọi).
3. Chọn tab/nhóm theo **Function Module** (có thể có thêm nhóm theo Destination/hệ thống gọi, User).
4. Lọc tên `Z*` (hoặc `Y*`, namespace riêng) bằng nút Filter của ALV; sắp xếp theo **Count**.
5. Cột cần lấy: tên FM, Count, Response time, (nếu có) Destination/User gọi.

## 4. Lấy danh sách HTTP / OData / SOAP (inbound)

1. **Analysis Views → Transaction Profile**.
2. Đổi loại tác vụ sang **HTTP(S)** (hoặc lọc cột Type = HTTP). Cột tên hiện đường dẫn ICF, ví dụ `/sap/opu/odata/sap/Z..._SRV/...` hoặc `/sap/bc/srt/...`.
3. Lọc tên chứa `Z` / `/sap/opu/odata/` / `/sap/bc/`, sắp xếp theo số bước (Steps/Count).
4. Một service OData thường hiện nhiều dòng (mỗi đường dẫn) → cộng gộp theo service khi tổng hợp.

## 5. Xuất file và cộng 3 tháng

1. Mỗi view, mỗi tháng: **List → Save → Spreadsheet / Local File**, đặt tên có tháng (VD `st03n_rfc_server_2026_09.xlsx`).
2. Gộp 3 file vào 1 bảng, pivot theo tên FM / service, cộng Count. Object nào có Count > 0 trong ít nhất 1 tháng = "đang được dùng".
3. Cột `TOT.*.TIME` tính bằng giây, `AVG` bằng ms (đơn vị trong file xuất).

## 6. Giới hạn — đọc kỹ trước khi kết luận

- ST03N **chỉ cho biết đã được gọi**, không có = không được gọi trong khoảng dữ liệu còn lưu (hoặc chạy ở hệ thống/client khác), **không** phải "object không tồn tại / có thể xoá".
- Không phân biệt "đầu vào" hay "đầu ra" của nghiệp vụ: chỉ phân biệt chiều gọi (RFC Server = vào SAP, RFC Client = ra ngoài).
- HTTP outbound (SAP gọi dịch vụ ngoài) không có. Thay thế: `SRT_MONI`/`SRT_UTIL` (SOAP), `SXMB_MONI` (nếu có PI/PO), `SM59` kết hợp log phía hệ thống đích.
- Nếu retention không đủ 3 tháng: (a) tăng retention rồi chờ tích luỹ; (b) `/IWFND/STATS` cho OData Gateway (nếu đã bật thu thập); (c) `STAD` chỉ giữ rất ngắn (vài giờ–vài ngày); (d) Solution Manager / EarlyWatch nếu hệ thống có kết nối.
- Chạy ST03N ở sai hệ thống (VD hệ thống không phải nơi API chạy) cho kết quả 0 — ví dụ ZHR ở hệ thống PRD 0012 có 114 giao dịch Z nhưng 0 hoạt động vì chạy ở hệ thống HR khác.

## 7. File đã có trong project (tham khảo)

Theo ghi chú phiên trước: `CodeABAP/QCM_UPG/06_Source Code 20261022/ST03N/ST03.ALL.0012.PRD.*.txt` (xuất 05.10.2026, chỉ có tháng 08–09 + 5 tuần + 12 ngày) → chưa đủ 3 tháng đến 26.10, cần xuất lại nếu muốn số liệu mới.

## 8. Xem log ICM / ICF để biết ai gọi 1 REST/HTTP service (VD `/sap/zcrm/customers`)

Bối cảnh: ST03N gộp mọi request HTTP vào dòng `SAPMHTTP` nên không tách được từng URL. Các cách dưới đây, sắp theo thứ tự nên thử. **Hầu hết chỉ ghi từ lúc bật, không cho lịch sử 3 tháng trước đó.**

### 8.1 Kiểm tra nhanh, không cần đổi cấu hình

- **Thống kê ICF có sẵn:** SE16 bảng `ICF_SERV_STAT` (cột PATH, COUNTER, TIME). Trên PRD800 bảng này chỉ có 36 dòng, **ngừng cập nhật từ 31.12.2022** nên không dùng được cho hiện tại (không có `/sap/zcrm`).
- **Cấu hình node ICF `/sap/zcrm` (đọc từ PRD800):** chưa bật trace (`ICF_TRACE` trống), chưa bật log (`LOG_FLAG` trống), không bắt buộc SSL. Vào SICF → `default_host/sap/zcrm` → tab **Logon Data** để xem node có cho đăng nhập ẩn danh hay dùng user cố định (nếu có user cố định thì mọi bên gọi sẽ hiện chung 1 user).

### 8.2 SMICM — access log của ICM (log "ai gọi URL nào")

1. Chạy `SMICM`.
2. **Kiểm tra access log có được bật không:** menu **Goto → Parameters → Display**, tìm `icm/HTTP/logging_0` (và `_1`, `_2`...). Nếu không có tham số nào → **chưa có access log**, không có gì để xem.
3. **Xem log (nếu đã bật):** menu **Goto → HTTP Plug-In → Server Logs** (release cũ: **Goto → HTTP Log → Server**) → chọn file log → **Display Entries**; **More Information** cho tên file, định dạng, kích thước, số dòng. Bản ghi mới nằm trong buffer ghi đĩa nên có thể chưa thấy ngay; dùng nút làm trống buffer (write buffer) rồi hiển thị lại.
4. Tìm dòng chứa `/sap/zcrm` — mỗi dòng có thời gian, IP bên gọi, user, URL, mã HTTP trả về (tuỳ `LOGFORMAT`).
5. **Bật access log (Basis làm, ví dụ — chỉnh theo chuẩn hệ thống):** thêm vào profile instance (RZ10) rồi áp dụng:
   `icm/HTTP/logging_0 = PREFIX=/, LOGFILE=http_%y_%m_%d.log, LOGFORMAT=%t %a %u %r %s %b %T, MAXSIZEKB=50000, SWITCHTF=day`
   Lưu ý: log handler ghi tuần tự nên có thể thành điểm nghẽn, vì vậy thường không bật mặc định; chọn `MAXSIZEKB`/`SWITCHTF` để file không phình; chỉ có dữ liệu từ lúc bật.
6. Nếu hệ thống có **SAP Web Dispatcher / reverse proxy / WAF** đứng trước SAP (URL của bạn là tên miền `minhphu.com`), access log ở đó thường **đã bật sẵn** và có đủ lịch sử — hỏi đội hạ tầng trước khi bật log trên ICM.

### 8.3 SMICM — trace ICM (chỉ để chẩn đoán ngắn hạn)

- **Goto → Trace File → Display All** để đọc `dev_icm`; **Goto → Trace Level → Increase** (mức 2) để thấy header HTTP của request. Trace mức cao ghi rất nhiều và làm chậm hệ thống production → bật vài phút rồi trả về mức cũ. Chưa xác nhận trace cho thấy IP bên gọi trên mọi release — nếu cần chắc chắn dùng access log ở 8.2.

### 8.4 SICF — ICF Recorder / Trace theo từng service

- `SICF` → chọn node `default_host/sap/zcrm` → bật **Recorder** (ghi lại request, có thể giới hạn theo user/client hoặc ghi tất cả; chọn chỉ request hoặc cả request + response) hoặc **Trace** (đặt thời hạn hiệu lực). Tên menu có thể khác theo release. Xem lại bản ghi trong cùng màn hình, **tắt Recorder/Trace sau khi xong** để không ảnh hưởng hiệu năng.

### 8.5 Cách thay thế nếu không muốn đụng cấu hình hệ thống

- **STAD** (Statistical Records) trên app server: lọc theo user của node ICF và khoảng thời gian gần đây; chỉ giữ rất ngắn (vài giờ đến vài ngày) nên chỉ trả lời được "đang có ai gọi lúc này không".
- **Ghi log trong handler** `ZCL_REST_CUSTOMER_RESOURCE~GET` (thời gian, user, IP) vào bảng Z — bền vững nhất nhưng phải sửa code (cần xác nhận theo quy trình dự án trước khi làm).
- Hỏi trực tiếp bên dùng API CRM (ISD) xem còn gọi `/sap/zcrm/customers` không — nhanh nhất nếu danh sách bên gọi ít.

## Nguồn tham khảo

- [SAP Help — hiển thị/cấu hình HTTP access log của ICM (`icm/HTTP/logging_<xx>`, SMICM Goto → HTTP Plug-In → Server Logs)](https://help.sap.com/saphelp_em92/helpdata/en/48/406e93ca2331c3e10000000a42189d/content.htm)
- [SAP Help — ICF Recorder / trace theo service](https://help.sap.com/saphelp_em92/helpdata/en/48/d185a9f6c96745e10000000a421937/content.htm)
- [SAP KBA 2430473 — thống kê sử dụng ICF service (`ICF_SERV_STAT`, `ICF_STAT_COLLECTOR`)](https://userapps.support.sap.com/sap/support/knowledge/en/2430473)

- [SAP Help — Controlling reorganization of the performance database (ST03 → Collector & Performance DB → Reorganization)](https://help.sap.com/saphelp_em92/helpdata/en/4c/0f0e422efcdf2ce10000000a1550b0/content.htm)
- [SAP Community — retention mặc định của Workload Collector / Monitoring DB](https://archive.sap.com/discussions/thread/531174)
- [SAP Technical Guru — cách kiểm tra RFC usage (ST03N)](https://www.saptechnicalguru.com/tag/st03/)
- [SAP KBA 2622556 — không thấy RFC profile trong Analysis Views](https://userapps.support.sap.com/sap/support/knowledge/en/2622556)
