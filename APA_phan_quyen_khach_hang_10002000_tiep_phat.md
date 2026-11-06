# APA — Kiểm soát quyền xem data khách hàng 10002000 (Công ty Tiếp Phát)

Hệ: `GUI_APA_PRD800` (S/4HANA On-Premise, client 800) → mô hình **Authorization Object (SU21) → PFCG role → User**, check bằng `AUTHORITY-CHECK`.

## 1. Trả lời ngắn

- **Được** tạo Authorization Object riêng (SU21) và đưa vào role (PFCG, kèm SU24 để role tự đề xuất object).
- **Nhưng object chỉ là "khoá"** — nó không tự chặn gì. Phải có code gọi `AUTHORITY-CHECK` thì mới có tác dụng.
  - **Report/Tcode Z của APA** (code mình sửa được) → thêm `AUTHORITY-CHECK` được.
  - **Tcode/report chuẩn SAP** → không thêm check vào code chuẩn được (trừ enhancement/BAdI/user-exit) → phải dùng cơ chế chuẩn (mục 3) hoặc enhancement.

## 2. Việc cần làm (report/Tcode Z)

| # | Việc | Ở đâu |
|---|------|-------|
| 0 | Chốt phạm vi: danh sách Tcode/report cần chặn (chuẩn hay Z), chặn cứng KH 10002000 hay một nhóm KH, ai được phép xem | Làm việc với user/key user |
| 1 | Tạo authorization class + object, vd `ZAPA_KUNNR`, field `ACTVT` + `KUNNR` (data element `KUNNR`) | SU21 (kèm TR) |
| 2 | Thêm `AUTHORITY-CHECK` vào từng report Z liên quan (mẫu bên dưới) | Code ABAP |
| 3 | Với Tcode Z: SU24 gán object `ZAPA_KUNNR` vào Tcode (Check/Maintain) | SU24 |
| 4 | Role cho nhóm được xem: thêm object `ZAPA_KUNNR` với `KUNNR = 10002000`, `ACTVT = 03` → sinh lại profile | PFCG |
| 5 | Test bằng 2 user (có / không có quyền) — xem `SU53`, trace `ST01`/`STAUTHTRACE` | SU53, ST01 |
| 6 | Chuyển TR (object + code) và transport role lên PRD (thường do team Basis/Security làm) | STMS |

### Bẫy logic cần chọn trước

`AUTHORITY-CHECK` kiểu "ai có mới được xem": nếu check mọi KH, **mọi role cũ không có object sẽ bị chặn toàn bộ**, phải sửa hết role (gán `*`).
→ Khuyến nghị: **chỉ check với KH nhạy cảm** (danh sách trong bảng Z hoặc TVARVC, ban đầu chỉ chứa 10002000). KH khác không bị ảnh hưởng, role cũ không phải sửa; chỉ role của người được phép xem Tiếp Phát cần thêm object.

(Cách "all except 1 KH" bằng 2 khoảng giá trị trong PFCG cũng làm được nhưng KUNNR là CHAR10 chữ-số, khoảng giá trị dễ sai và phải sửa mọi role → không khuyến nghị.)

### Mẫu code

```abap
" lt_kunnr_nhay_cam: KH nhạy cảm (chỉ 10002000), đọc từ bảng cấu hình / TVARVC
DATA lr_kunnr_cam TYPE RANGE OF kunnr.

LOOP AT lt_kunnr_nhay_cam INTO DATA(lv_kunnr).
  AUTHORITY-CHECK OBJECT 'ZAPA_KUNNR'
    ID 'KUNNR' FIELD lv_kunnr
    ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_kunnr ) TO lr_kunnr_cam.
  ENDIF.
ENDLOOP.

" Đưa vào WHERE của SELECT (tốt nhất):  ... AND kunnr NOT IN @lr_kunnr_cam
" hoặc nếu data đã đọc xong:
IF lr_kunnr_cam IS NOT INITIAL.
  DELETE lt_data WHERE kunnr IN lr_kunnr_cam.
ENDIF.
```

- Check theo **danh sách KH nhạy cảm** (rất ngắn), không check từng dòng kết quả → không ảnh hưởng performance.
- **KUNNR phải ở dạng nội bộ có số 0 đầu: `0010002000`** (CHAR10, ALPHA). `AUTHORITY-CHECK ... FIELD` và giá trị trong PFCG đều dùng `0010002000`, không phải `10002000` — nhập thiếu số 0 thì check luôn fail. Nhớ `CONVERSION_EXIT_ALPHA_INPUT` nếu giá trị lấy từ selection-screen dạng text.
- Nếu KH bị cấm nằm trong selection-screen mà user nhập đích danh → nên báo message "không có quyền" thay vì trả kết quả rỗng im lặng.

## 3. Với Tcode/report chuẩn SAP

Không sửa được code chuẩn, các hướng:

1. **Authorization group của KH** (`KNA1-BEGRU`): gán nhóm vd `TP01` cho KH 10002000, rồi role chỉ cho phép nhóm đó với người được xem (object kiểu `F_KNA1_BED`, SD: `V_KNA1_BRG` — xác nhận tên/field trong SU21). Không cần code, nhưng chỉ có tác dụng ở nơi chuẩn gọi check này (master data, một số report dùng logical database DDF) — **phải trace từng Tcode** (ST01/SU53) để biết có chặn thật không.
2. **Object cấp tổ chức** đã có sẵn trong Tcode (company code `F_BKPF_BUK`, sales org `V_VBAK_VKO`...) — chỉ hợp lý nếu Tiếp Phát nằm riêng 1 company code/sales org.
3. **Enhancement/BAdI/user-exit** thêm `AUTHORITY-CHECK` custom vào Tcode chuẩn (tốn công, cần tìm điểm chèn cho từng Tcode).
4. **Không cấp Tcode** cho nhóm không được xem, thay bằng report Z có check (mục 2).

## 4. Đường vòng phải kiểm tra

Data KH 10002000 còn xuất hiện qua: FBL5N, FD10N, FD11, VA05/VA03, VF05, các report Z khác, và qua **SE16/SE16N/SQVI/SQ01** (đọc thẳng KNA1, BSID, VBAK…). Nếu user vẫn có `S_TABU_DIS`/`S_TABU_NAM` rộng thì object Z ở trên không chặn được các đường này → cần rà luôn quyền xem bảng.

## 5. Phân loại 6 nhóm Tcode user cung cấp (06/11/2026)

Tcode "Z…" ở dưới là **suy từ tên** (chưa tra TSTC vì phiên này không có server APA) — chạy file `query_apa_tcode_phan_quyen_kh_10002000.sql` (câu 1) để xác nhận chương trình thật.

| Nhóm | Tcode | Loại | Hướng chặn đề xuất |
|------|-------|------|--------------------|
| 1. Lên đơn | VA01, VA02, VA03 | Chuẩn SAP | Authorization group KNA1-BEGRU (`V_KNA1_BRG`, nghi chuẩn có check ở sold-to — **phải trace xác nhận**); nếu Tiếp Phát có sales org riêng thì `V_VBAK_VKO`; không đủ → user-exit/BAdI của VA01 (MV45AFZZ…) |
| 2. Báo cáo đơn hàng | ZSD01, ZSD02, ZSD05, ZSD06 | Z | **`AUTHORITY-CHECK` object Z (mục 2)** — chắc chắn làm được, nên làm trước |
| 3. Lên OD | VL01N, VL02N | Chuẩn SAP | Chuẩn check theo shipping point/sales org, không theo KUNNR → authorization group hoặc enhancement; xem SU24 (query câu 2) |
| 4. Billing | VF01, VF04 | Chuẩn SAP | Như nhóm 3 (billing type/sales org); VF04 là danh sách billing due → cân nhắc enhancement |
| 5. Kế hoạch SFC | MD79, MD73 | Chuẩn SAP (nếu chưa bị copy sang Z) | Dữ liệu theo **vật tư/nhà máy**, thường không có chiều KH → chặn theo KH không áp dụng trực tiếp; cần hỏi các màn này có hiện data riêng của KH 10002000 không |
| | ZPP10 | Z | Đọc code xem có field KH không → thêm check nếu có |
| 6. Tồn kho | ZWM06 | Z | Tồn kho thường không gắn KH (trừ tồn đặc biệt theo KH: consignment/sales order stock) → hỏi có hiện KH không |

### Nhận xét

- Chỉ nhóm 2 (+ ZPP10/ZWM06 nếu có chiều KH) là "báo cáo" thật; nhóm 1, 3, 4 là **giao dịch tạo/sửa chứng từ** (lên đơn, OD, billing). Yêu cầu gốc nói "xem dữ liệu trên báo cáo/Tcode" → cần hỏi có chặn cả việc **tạo/sửa** đơn của Tiếp Phát không. Nếu chỉ chặn *xem*, nhóm 1/3/4 chỉ cần quan tâm các Tcode display (VA03) và các report chuẩn khác.
- Nhóm 5 (MD73/MD79) khả năng cao **ngoài phạm vi** (không theo KH).
- Thứ tự làm đề xuất: (1) nhóm 2 + ZPP10/ZWM06 bằng object Z → (2) chạy trace SU53/ST01 cho VA03/VL02N/VF04 xem chuẩn đã chặn được bao nhiêu bằng authorization group → (3) phần còn thiếu mới tính enhancement.

## 6. Câu hỏi còn cần chốt

1. Yêu cầu chặn **xem** hay cả **tạo/sửa** (VA01/VL01N/VF01) đơn của Tiếp Phát?
2. "Chỉ một nhóm người được xem Tiếp Phát" hay "không ai được xem trừ ngoại lệ"? Danh sách người/role ngoại lệ?
3. Chỉ KH 10002000 hay sau này mở rộng nhóm KH?
4. MD79/MD73/ZPP10/ZWM06 có hiện data riêng của KH 10002000 không?
5. Ai quản role PFCG ở APA (team Security/Basis của khách) — để tính thời gian chuyển TR/role.
6. Kết quả chạy `query_apa_tcode_phan_quyen_kh_10002000.sql` (câu 1–5), hoặc cấu hình MCP server `GUI_APA_PRD800` cho phiên này để tôi tự tra.

> Chưa tạo/sửa gì trên SAP. Tạo object/sửa code/lưu TR sẽ hỏi xác nhận trước.
