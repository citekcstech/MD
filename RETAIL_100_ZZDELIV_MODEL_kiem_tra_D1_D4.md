# RETAIL_100 — Cờ ZZDELIV_MODEL (Delivery Model): hiện trạng, đã làm, kiểm thử, việc còn lại

Cập nhật lần cuối: 24/10/2026. Hệ thống: S4R (S/4HANA), client 100, MCP `GUI_RETAIL_100` (user CT.TUAN). Transport: `S4RK900112` ("CS_SangVT_21.10.2026 EKPO Delivery Model", tasks `S4RK900113` Dev/Correction và `S4RK900114` Repair), package `ZPK_LTG`. Chưa release.

## 1. Tóm tắt trạng thái

| Hạng mục | Trạng thái | Ghi chú |
|---|---|---|
| Field `ZZDELIV_MODEL` trên PO | Xong, đã test | Nằm trong customer include `CI_EKPODB`, có trong EKPO / BEKPO / `MEPOITEM` |
| D1: nhập cờ trên ME21N / ME22N / ME23N | Xong; ME22N và ME23N test đạt | ME21N tạo PO mới chưa ghi nhận kết quả |
| D2: gán cờ vào KOMP (pricing PO) | Có code, chưa test pricing | Exit `EXIT_SAPLMEKO_002` (include `ZXM06U15`) và BAdI `ME_PO_PRICING_CUST` cùng gán; user chốt giữ cả hai |
| D3: cờ trên hóa đơn (RSEG) | Không làm | Lấy cờ từ EKPO qua join (user chốt) |
| D4: view doanh số có cờ | Xong | CDS extend `ZVWB2_RBKP_RSEG_1` |
| Việc 1: `CI_EKPODBX` (cờ X cho MEMASSPO/BAPI) | Đã tạo 23/10 22:11 (CT.TUAN), chưa test | MEMASSPO và `BAPI_PO_CHANGE` chưa chạy thử |
| Settlement: `ZWLF_DOCUMENT_EXT` | Active, chưa test | Giả định `KOMLFP-CONTRACT` là số EBELN |
| Việc 4: tự gán cờ theo quy tắc | Không làm | Chờ QCM chốt |

## 2. Quyết định thiết kế đã chốt (không hỏi lại)

- D3: không chép cờ vào RSEG; view doanh số lấy cờ từ EKPO qua join (kết hợp D4).
- D4: thêm `ekpo.zzdeliv_model` vào CDS extend `ZVWB2_RBKP_RSEG_1` (extend view `V_WB2_RBKP_RSEG_1`, SQL view append `ZVWB2_RBKPRSEG_1`).
- D1: dùng BAdI `ME_GUI_PO_CUST`, implementation `ZME_GUI_PO_CUST`, class `ZCL_IM_ME_GUI_PO_CUST`. `ZME_PROCESS_PO_CUST` / `ZCL_ME_PROCESS_PO_CUS` để rỗng.
- DDIC: chuyển field từ append `ZAST_EKPO` sang `CI_EKPODB` (user đồng ý 23/10/2026).
- Việc 2: giữ nguyên cả exit lẫn BAdI (user quyết định 24/10/2026). Nếu sau này chỉ giữ một nơi thì comment code trong `PROCESS_KOMP`, không xóa.

## 3. Đối tượng đã làm hoặc đã có

| Đối tượng | Loại | Nội dung |
|---|---|---|
| `ZDE_DELIV_MODEL` / `ZDO_DELIV_MODEL` | Data element / domain | CHAR 3, không có giá trị cố định, không có value table |
| `ZST_EKPO` | Structure | Một field `ZZDELIV_MODEL`; dùng cho screen và FM |
| `CI_EKPODB` | Structure (customer include EKPO) | Field `ZZDELIV_MODEL`; tạo 23/10/2026 qua `CreateStructureAtomic` |
| `ZAST_EKPO` | Append EKPO | Đã xóa (thay bằng `CI_EKPODB`) |
| `ZAST_RSEG`, `ZAST_KOMP`, `ZAST_KOMPAZ`, `ZAST_KOM_AZ`, `ZAST_WB2_S_BVB_FIELDCAT` | Append | Có từ 21/10/2026 (RSEG, KOMP, KOMPAZ, field catalog CCM) |
| `CI_EKPODBX` | Structure (cờ X cho BAPI) | Do user tạo 23/10/2026 22:11; `BAPI_TE_MEPOITEMX` đã thấy field |
| `ZME_GUI_PO_CUST` / `ZCL_IM_ME_GUI_PO_CUST` | BAdI implementation / class | `SUBSCRIBE`, `MAP_DYNPRO_FIELDS`, `TRANSPORT_FROM_MODEL`, `TRANSPORT_TO_DYNP`, `TRANSPORT_FROM_DYNP`, `TRANSPORT_TO_MODEL`; `EXECUTE` rỗng |
| `ZFG_ME_GUI_PO` | Function group | TOP `LZFG_ME_GUI_POTOP`; FM `ZFM_ME_GUI_PO_ITEM_PUT` / `_GET`; screen 0100 (Subscreen, do user tạo trong SE80) |
| `ZME_PO_PRICING_CUST` / `ZCL_IM_ME_PO_PRICING_CUST` | BAdI implementation / class | `PROCESS_KOMP`: `ch_komp-zzdeliv_model = im_ekpo-zzdeliv_model.` |
| `ZXM06U15` | Include của `EXIT_SAPLMEKO_002` | `e_komp-zzdeliv_model = i_ekpo-zzdeliv_model.` (user, 23/10/2026); gán qua enhancement `LMEKO002` trong project `ZLTG` |
| `ZLTG` | Project CMOD (active) | Components: LMEKO002, LWZRE001, MBCFC004, MM06E005, PPCO0007, PPCO0012, PPCO0020, QEVA0008, SDVFX001, SDVFX008 |
| `ZVWB2_RBKP_RSEG_1` | CDS extend | Thêm `ekko.bsart` và `ekpo.zzdeliv_model` vào `V_WB2_RBKP_RSEG_1` |
| `ZWLF_DOCUMENT_EXT` (ENHO + class) | BAdI `WLF_DOCUMENT_EXT` | `CHANGE_PRICING_ITEM`: lấy cờ từ EKPO theo `KOMLFP-CONTRACT` / `CONTRACT_ITEM` |
| `ZXLFXU02` | Include của `EXIT_SAPLWLF0_002` (LWZRE001) | Chỉ có `e_komp = i_komp.` và dòng TODO |
| `ZME_PROCESS_PO_CUST` / `ZCL_ME_PROCESS_PO_CUS` | ENHO / class | Rỗng, không dùng |

Cấu hình CCM có từ trước (theo tài liệu CITEK): field combination `ZDM1`, dòng `WB2_D_BUSVOLBASE` (`ZDM1`, `ZZDELIV_MODEL = DC`), hợp đồng 1200000000, request `S4RK900123`.

## 4. Chi tiết kỹ thuật từng hạng mục

### 4.1 Chuyển field sang CI_EKPODB
- Vấn đề: `ZZDELIV_MODEL` nằm ở append `ZAST_EKPO` gắn thẳng EKPO (cuối bảng, vị trí 485) nên có trong EKPO nhưng KHÔNG có trong `MEPOITEM`. PO model chỉ mang field khách hàng thuộc `CI_EKPODB` (qua `EKPO_INCL_EEW_PS`, có trong EKPO, BEKPO và `MEPOITEM_DATA`). Nếu không sửa, `get_data`/`set_data` của item không có field và ME21N không ghi được xuống EKPO.
- `CI_EKPODB` trước đó chưa tồn tại (customer include: SAP đã trỏ sẵn tới tên này, chỉ cần tạo structure đúng tên).
- Cách làm: gỡ tạm `ekpo.zzdeliv_model` khỏi CDS D4 → `DeleteObjectAtomic ZAST_EKPO` → `CreateStructureAtomic CI_EKPODB` → khôi phục CDS. Cả hai bước đổi DDIC bị timeout phía client (kích hoạt EKPO chậm) nhưng server hoàn tất.
- Kết quả: field có ở `CI_EKPODB`, `MEPOITEM_DATA` (0291), `MEPOITEM` (0292), `EKPO` (0318), `BEKPO` (0319); RSEG, KOMP, MASSEKPO, PURGDOCITEMROW, WB2_* vẫn còn field; EKPO còn 8.152 dòng.

### 4.2 D1: luồng dữ liệu của tab "Delivery Model"
- Khung ME (`CL_EX_ME_GUI_PO_CUST`) gọi `SUBSCRIBE` (application `PO`, element `HEADER` rồi `ITEM`; code chỉ trả tab cho `ITEM`), sau đó `MAP_DYNPRO_FIELDS`.
- PBO của subscreen (module `event_pbo`): `TRANSPORT_FROM_MODEL` đọc `mepoitem-zzdeliv_model` vào `ms_data`, nhận biết chế độ hiển thị bằng `header->is_changeable( )`; `TRANSPORT_TO_DYNP` gọi `ZFM_ME_GUI_PO_ITEM_PUT`; module `status_0100` khóa ô khi `gv_display = X`.
- PAI (module `event_pai`): `TRANSPORT_FROM_DYNP` gọi `ZFM_ME_GUI_PO_ITEM_GET`, báo đổi nếu khác; `TRANSPORT_TO_MODEL` ghi `set_data` vào item. Cờ `MV_DYNP_LOADED` tránh ghi đè nhầm giá trị của item khác.
- Flow logic screen 0100:
  ```
  PROCESS BEFORE OUTPUT.
    MODULE event_pbo.
    MODULE status_0100.
  PROCESS AFTER INPUT.
    MODULE event_pai.
  ```
- Mẫu chuẩn của SAP để đối chiếu: class `CL_EXM_IM_ME_GUI_PO_CUST`, function group `MEPOBADIEX`.

### 4.3 D2 và settlement
- Exit `EXIT_SAPLMEKO_002` (function group `XM06`) và BAdI `ME_PO_PRICING_CUST~PROCESS_KOMP` cùng điền `KOMP-ZZDELIV_MODEL` từ EKPO nên cho cùng kết quả. KOMP/KOMG đã có field (append `ZAST_KOMP`, `ZAST_KOMPAZ`); field combination `ZDM1` khai `FIELDNAME_KOMG = ZZDELIV_MODEL`.
- `ZWLF_DOCUMENT_EXT`: code gốc dùng `i_komlfp-ebeln/ebelp` (KOMLFP không có) nên inactive; đã đổi sang `CONTRACT` (CHAR 10) / `CONTRACT_ITEM` (NUMC 6) qua biến `lv_ebeln` / `lv_ebelp` (EKPO-EBELP là NUMC 5), code cũ comment lại. Chưa test với settlement document thật.

### 4.4 D4 và D3
- `VWB2_RBKP_RSEG_1` là SQL view của CDS `V_WB2_RBKP_RSEG_1`, sửa được bằng `EditSource` trên DDLS `ZVWB2_RBKP_RSEG_1`. Theo tài liệu CITEK, trước khi có cột `ZZDELIV_MODEL`, `WB2R_BUSVOL` báo 1.806 lỗi WB2R 460; sau khi có cột thì chạy xong không lỗi.
- D3: RSEG có field (append `ZAST_RSEG`) nhưng không dùng; không BAdI `INVOICE_UPDATE` (chỉ có tham số importing, không sửa được RSEG).

## 5. Kết quả kiểm thử

- Dữ liệu ban đầu: EKPO 8.152 dòng và RSEG 8.230 dòng, `ZZDELIV_MODEL` đều trống.
- ME22N (24/10/2026): tab hiện, nhập `DC`, lưu PO `4000000329`: EKPO có item 10 và 30 = `DC`, item 20 và 40 trống (mỗi item lưu riêng, không lẫn giá trị). Mở lại ME22N hiện đúng giá trị, sửa được.
- ME23N: ô nhập bị khóa (user xác nhận).
- Chưa test: pricing PO (PO có cờ phải có `ZRA1`; dòng không cờ thì không), ME21N tạo PO mới, MEMASSPO, `BAPI_PO_CHANGE` TESTRUN, `ZWLF_DOCUMENT_EXT`, `WB2R_SC`.

## 6. Bẫy kỹ thuật đã gặp (chi tiết trong `_ghichu_mcp_gui.md` section 1)

- Subscreen cho `ME_GUI_PO_CUST` cần đủ 4 điều kiện: (1) screen loại Subscreen (`D020S-TYPE = I`); (2) `MAP_DYNPRO_FIELDS` gán metafield (`mmmfd_cust_01`), thiếu thì tab không hiện dù `SUBSCRIBE` đúng; (3) TOP của function group có `DATA: ok-code TYPE sy-ucomm.` và `INCLUDE lmeviewsf01.`, thiếu thì bấm vào tab bị dump `PERFORM_NOT_FOUND` (`SET_SUBSCREEN_AND_PROG`); (4) flow logic gọi `event_pbo` / `event_pai`, thiếu thì ô vẫn hiện nhưng BAdI không được gọi (ME22N không hiện lại giá trị, ME23N không khóa).
- ADT/MCP không tạo được: dynpro, implementation BAdI cổ điển (SXCI), sửa DDIC view cổ điển. Phải làm trong SE80 / SE19 / SE11.
- Không có debugger (`ZADT_VSP` chưa cài): chẩn đoán bằng cách ghi vết vào `INDX` rồi đọc bằng `RunQuery`. `MESSAGE ... TYPE 'I'` trước lệnh ghi vết làm method dừng giữa chừng nên không thấy popup.
- `GetInactiveObjects` và `Activate` qua ADT không đáng tin tuyệt đối; kiểm bằng `GetSource` và `DD02L` / `DD03L`.
- Kích hoạt bảng lớn (EKPO) làm request ADT timeout nhưng server vẫn hoàn tất; sau đó mọi request timeout một lúc rồi chạy lại.

## 7. Việc còn lại

1. Test pricing (ME21N, PO cho NCC 3100001266 có cờ `DC` phải có `ZRA1`), ME21N tạo PO mới, MEMASSPO và `BAPI_PO_CHANGE` TESTRUN (kiểm `CI_EKPODBX`).
2. Quyết định về settlement: giữ hay gỡ `ZWLF_DOCUMENT_EXT` và `ZXLFXU02`; test `WB2R_SC`.
3. Dọn project `ZLTG`: `MM06E005` không cần cho hướng BAdI và có thể sinh tab "Customer data" trống. Chỉ gỡ component, không Deactivate project (dùng chung).
4. Domain `ZDO_DELIV_MODEL` chưa có giá trị cố định, F4 hay kiểm tra: hỏi QCM danh sách giá trị hợp lệ rồi thêm giá trị cố định hoặc kiểm tra khi lưu PO.
5. Trước khi release `S4RK900112`: dọn object thử (`ZME_PROCESS_PO_CUST`, `ZCL_ME_PROCESS_PO_CUS`, `ZXLFXU02` nếu không dùng); import sẽ kích hoạt lại EKPO ở QAS/PRD nên xếp lịch ngoài giờ cao điểm.
6. Dọn 24 dòng vết debug trong `INDX` khu vực `ZZ` (vô hại): câu lệnh ở `sql/query_xoa_vet_debug_indx_zz.sql`.

## 8. Tệp liên quan

- Tài liệu hướng dẫn gửi nhóm ABAP: `CodeABAP/CITEK_RETAIL/Citek_QCM_HuongDan_ABAP_DeliveryModel_v0.1.docx` (đã sửa 2 lần ngày 24/10/2026, phần mình làm hiện bằng chữ đỏ). Bản gốc: `Citek_QCM_HuongDan_ABAP_DeliveryModel_v0.1_goc_truoc_khi_sua.docx` cùng thư mục.
- Dump ST22 đã phân tích: `CodeABAP/CITEK_RETAIL/PERFORM_NOT_FOUND_20261023_162458.zip`.
- Câu lệnh dọn `INDX`: `sql/query_xoa_vet_debug_indx_zz.sql`.
- Ghi chú tool MCP: `_ghichu_mcp_gui.md` (section 1, mục `GUI_RETAIL_100`).

## 9. Dòng thời gian ngắn

- 21/10: tạo DDIC (`ZDE_DELIV_MODEL`, `ZST_EKPO`, append) và các object nháp trong TR.
- 23/10: kiểm tra hiện trạng; điền `PROCESS_KOMP`; sửa `ZWLF_DOCUMENT_EXT`; chuyển field sang `CI_EKPODB`; viết `ZCL_IM_ME_GUI_PO_CUST`, `ZFG_ME_GUI_PO`; xử lý lỗi tab không hiện và dump `PERFORM_NOT_FOUND`; user tạo `CI_EKPODBX`.
- 24/10: tìm ra nguyên nhân flow logic thiếu `event_pbo` / `event_pai`; ME22N và ME23N test đạt; xóa code debug khỏi class; sửa tài liệu Word.
