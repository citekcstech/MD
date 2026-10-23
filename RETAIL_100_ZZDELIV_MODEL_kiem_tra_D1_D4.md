# RETAIL_100 — Kiểm tra D1–D4 (cờ ZZDELIV_MODEL, luồng WCOCO)

Kiểm tra ngày 23/10/2026 qua MCP `GUI_RETAIL_100` (client 100, user CT.TUAN), chỉ đọc, không sửa gì trên hệ thống.

## Cập nhật 23/10/2026 15:10 — D1 và D4 đã xong (TR S4RK900112), chờ test ME21N

- **DDIC đã chuyển (user đồng ý):** xóa append `ZAST_EKPO` khỏi EKPO, tạo structure `CI_EKPODB` (customer include có sẵn tham chiếu trong EKPO / BEKPO / `MEPOITEM_DATA`, trước đó chưa tồn tại) chứa `ZZDELIV_MODEL`. Kết quả kiểm chứng: field có ở `CI_EKPODB`, `MEPOITEM_DATA` (0291), `MEPOITEM` (0292), `EKPO` (0318), `BEKPO` (0319); các view/structure phụ thuộc (RSEG, KOMP, MASSEKPO, PURGDOCITEMROW, WB2_*) vẫn còn field; EKPO còn 8.152 dòng. Hai bước (xóa, tạo) bị timeout phía client vì kích hoạt EKPO chậm nhưng server đã hoàn tất.
- **D4 (CDS extend `ZVWB2_RBKP_RSEG_1`, extend `V_WB2_RBKP_RSEG_1`):** user đã tự thêm `ekpo.zzdeliv_model`. Mình tạm bỏ dòng này trong lúc đổi DDIC rồi khôi phục đúng nguyên văn; `DD27S` của `ZVWB2_RBKPRSEG_1` có `BSART` (EKKO) và `ZZDELIV_MODEL` (EKPO).
- **D1 (`ZCL_IM_ME_GUI_PO_CUST`, BAdI `ME_GUI_PO_CUST`):** đã viết `SUBSCRIBE` (tab "Delivery Model" ở item PO, program `SAPLZFG_ME_GUI_PO`, screen 0100), `TRANSPORT_FROM_MODEL`, `TRANSPORT_TO_DYNP`, `TRANSPORT_FROM_DYNP`, `TRANSPORT_TO_MODEL` (ghi `set_data` vào `MEPOITEM`). Có cờ `MV_DYNP_LOADED` để không ghi đè nhầm giá trị item khác, và `MV_DISPLAY` để khóa ô nhập khi PO ở chế độ hiển thị (cần flow logic screen 0100 có `MODULE status_0100.` trong PBO). Syntax check sạch, đã activate, không còn object inactive.
- **Chưa test trên màn hình thật.** Cách test: ME21N tạo PO → chọn item → tab "Delivery Model" → nhập (VD `DC`) → lưu → kiểm tra `SELECT ebeln, ebelp, zzdeliv_model FROM ekpo WHERE zzdeliv_model <> ''`; ME22N sửa giá trị; ME23N ô phải khóa.
- **Lưu ý còn lại:** project CMOD `ZLTG` hiện có thêm `LMEKO002` (include `ZXM06U15` còn rỗng) và `MM06E005`, trùng với hướng BAdI đã làm (D2 qua `ZME_PO_PRICING_CUST`, D1 qua `ZME_GUI_PO_CUST`); `MM06E005` còn có thể sinh thêm tab "Customer data" trống. Nếu không dùng thì gỡ khỏi `ZLTG` trong CMOD.

## Cập nhật 23/10/2026 14:11 — đã làm trên hệ thống (TR S4RK900112)

- **D2 đã xong, theo hướng BAdI thay cho exit `LMEKO002`:** implementation `ZME_PO_PRICING_CUST` (BAdI `ME_PO_PRICING_CUST`, active, tạo sẵn từ 21/10) có class `ZCL_IM_ME_PO_PRICING_CUST`. Đã điền method `PROCESS_KOMP`: `ch_komp-zzdeliv_model = im_ekpo-zzdeliv_model.` (EditSource, syntax check sạch, activate, đã đọc lại source kiểm chứng). Không cần include `ZXM06U15` nữa.
- **`ZWLF_DOCUMENT_EXT` (BAdI `WLF_DOCUMENT_EXT`) đã sửa và activate (23/10/2026 14:29):** code cũ dùng `i_komlfp-ebeln/ebelp` nhưng `KOMLFP` không có 2 field này. Theo yêu cầu đã đổi sang `CONTRACT` (CHAR 10) / `CONTRACT_ITEM` (NUMC 6), qua biến trung gian `lv_ebeln`/`lv_ebelp` vì `EKPO-EBELP` là NUMC 5; code cũ được comment lại (marker `SangVT comment begin/end`). Class và ENHO đều active, hệ thống không còn object inactive. Lưu ý: logic này coi `CONTRACT` là số chứng từ EKPO (EBELN); nếu `CONTRACT` là số hợp đồng điều kiện thì SELECT sẽ không ra dòng, cần test với 1 settlement doc thật.
- **Quyết định thiết kế (user chốt 23/10/2026):** D3 không chép cờ vào RSEG mà lấy từ EKPO qua join khi đọc, kết hợp D4 (thêm `ZZDELIV_MODEL` vào view). D1 dùng implementation `ZME_PROCESS_PO_CUST` (class `ZCL_ME_PROCESS_PO_CUS`, SE19 tự cắt tên, đang rỗng, active).
- **`ZXLFXU02` (exit `EXIT_SAPLWLF0_002`, enhancement `LWZRE001` trong project `ZLTG`) đang active**, chỉ có `e_komp = i_komp.` còn TODO.
- **Chưa làm D1, D3, D4:** xem mục "Việc còn lại" ở cuối file.
- Phần "Kết luận nhanh" và "Chi tiết D2" bên dưới là kết quả kiểm tra ban đầu; riêng D2 đã được thay bằng các dòng trên.

## Kết luận nhanh

| # | Thiếu (theo tài liệu) | Kết quả kiểm tra | Việc cần làm |
|---|---|---|---|
| D1 | Ô nhập ZZDELIV_MODEL ở ME21N/ME22N | **Đúng là thiếu.** Field đã có trong EKPO, nhưng không có BAdI/CMOD nào đưa nó lên màn hình | Implement BAdI `ME_GUI_PO_CUST` + `ME_PROCESS_PO_CUST` (hoặc CMOD `MM06E005`) |
| D2 | Exit `LMEKO002` chưa active, chưa chép EKPO sang KOMP | **Đúng là thiếu.** KOMP đã có field; include `ZXM06U15` chưa tạo; chưa project CMOD nào chứa `LMEKO002` | Tạo include `ZXM06U15`, gán `LMEKO002` vào project CMOD, activate |
| D3 | Chép cờ từ PO sang RSEG khi MIRO | **Đúng là thiếu.** RSEG đã có field, không có implementation Z nào cho INVOICE_UPDATE / MRM_ITEM_CUSTFIELDS | Viết BAdI chép EKPO → RSEG khi MIRO |
| D4 | View doanh số chứa cờ | **Đúng một phần.** Xem chi tiết bên dưới | Thêm field vào append view `ZVWB2_RBKPRSEG_1`; tạo view/CDS mới cho PO có LIFNR, WAERS, BEDAT |

## Đã có sẵn (không cần làm lại)

- Data element `ZDE_DELIV_MODEL` và domain `ZDO_DELIV_MODEL` (CHAR 3, package `ZPK_LTG`). Domain **không có fixed value** và không có value table, nên chưa có F4 / kiểm tra giá trị.
- Field `ZZDELIV_MODEL` active trong EKPO (append `ZAST_EKPO`), RSEG (append `ZAST_RSEG`), KOMP (append `ZAST_KOMP`), KOMPAZ (`ZAST_KOMPAZ`), KOMK, KOMG, MRMRSEG, WB2_EKPO, WB2_RSEG.
- Phía WCOCO / settlement: `WB2_D_BUSVOLBASE` có field, `WB2_V_BVB_CONTR` và `WB2_V_BVB_CONTR2` có field, field catalog có append `ZAST_WB2_S_BVB_FIELDCAT`. Đã có 1 dòng cấu hình `FIELDCOMB = ZDM1`, `ZZDELIV_MODEL = DC` trong `WB2_D_BUSVOLBASE`. Khớp với dòng "phần khai trên WCOCO đã đủ điều kiện".
- Views PO có cờ: `PURGDOCITEMROW`, `PURGORDITEMROW`, `MASSEKPO`, `MASSEKPOCONTRACT`, `MASSEKPOSCHAGREE`.

## Chi tiết từng mục

### D1 — ME21N/ME22N
- Không có project CMOD nào chứa `MM06E005` (`MODACT` rỗng). Chỉ có 2 project: `ZLTG` (LWZRE001, MBCFC004, PPCO0007/0012/0020, QEVA0008, SDVFX001/008) và `ZWPUE` (WPUE0002).
- `ME_GUI_PO_CUST` chỉ có implementation chuẩn `/ACCGO/CAS_IM_GUI_PO`; `ME_PROCESS_PO_CUST` chỉ có `/DMBE/IF_PO_SCHEDULE`, `TXS_MM_PROCESS_PO` (đều của SAP).
- Dữ liệu: 8.152 dòng EKPO, tất cả `ZZDELIV_MODEL` trống.
- Làm: subscreen ở tab item (Customer Data) bằng `ME_GUI_PO_CUST`, đọc/ghi qua `ME_PROCESS_PO_CUST`.
- MEMASSPO: `MASSEKPO` có field, nhưng chưa kiểm tra cấu hình mass change nên chưa chắc nhập được.

### D2 — Exit LMEKO002
- Enhancement `LMEKO002` có component `EXIT_SAPLMEKO_002` (function group `XM06`, "Extend Communication Structure KOMP for Pricing"). FM chứa `INCLUDE ZXM06U15.`.
- Include `ZXM06U15` chưa tồn tại (ADT 404, `TRDIR` không có `ZXM06*`). `MODACT` không có project nào chứa `LMEKO002`.
- Làm: `E_KOMP-ZZDELIV_MODEL = I_EKPO-ZZDELIV_MODEL.` rồi activate project (có thể gán vào project `ZLTG` đang active hoặc project mới).

### D3 — MIRO / RSEG
- `INVOICE_UPDATE` có 20 implementation, `MRM_ITEM_CUSTFIELDS` có 1 (`WKA_ITEM_CUSTFIELDS`), toàn là của SAP. Không có project CMOD nào chứa `MRM*`.
- Dữ liệu: 8.230 dòng RSEG, tất cả `ZZDELIV_MODEL` trống.
- Làm: chép cờ EKPO → RSEG khi lập hóa đơn (candidate: `MRM_ITEM_CUSTFIELDS` hoặc `INVOICE_UPDATE`; cần kiểm tra method trong SE18 trước khi chọn).

### D4 — View doanh số
- `VWB2_RBKP_RSEG_1` (join RBKP, RSEG, EKPO, EKKO) **không có** `ZZDELIV_MODEL`. Append view `ZVWB2_RBKPRSEG_1` đã có nhưng chỉ chứa `EKKO-BSART`.
- `PURGDOCITEMROW`, `MASSEKPO` là view 1 bảng EKPO nên **không có** LIFNR, WAERS, BEDAT (chỉ có EBELN, EBELP, MATNR và cờ). Khớp với tài liệu.
- Làm: thêm `ZZDELIV_MODEL` vào `ZVWB2_RBKPRSEG_1` (lấy từ EKPO đã join sẵn thì không cần chờ D3, lấy từ RSEG thì cần D3); tạo view/CDS PO mới join EKPO + EKKO có cờ, LIFNR, WAERS, BEDAT.

## Việc còn lại (cần thao tác GUI hoặc quyết định thiết kế)

> Các mục D1 và D4 bên dưới là ghi chép trước 15:10 ngày 23/10/2026; hiện D1 và D4 đã xong, xem mục "Cập nhật 15:10" ở đầu file. Chỉ còn: test ME21N/ME22N/ME23N, test `ZWLF_DOCUMENT_EXT` với settlement doc thật, và quyết định có gỡ `LMEKO002`/`MM06E005` khỏi `ZLTG` không.

- **D1 (ME21N):** cần dynpro subscreen (SE80/SE51) và implementation BAdI `ME_GUI_PO_CUST` + `ME_PROCESS_PO_CUST` qua SE19. ADT/MCP không tạo được dynpro hay implementation BAdI cổ điển. Quy trình đã dùng với `ME_PO_PRICING_CUST`: bạn tạo implementation trong SE19 (sinh class `ZCL_IM_...`), mình điền code method qua MCP.
- **D3 (MIRO → RSEG): không code.** Đã chốt lấy cờ từ EKPO qua join khi đọc, không chép vào RSEG; không cần BAdI `INVOICE_UPDATE`.
- **D4 (view hóa đơn): làm trong SE11, ADT không sửa được.** `ZVWB2_RBKPRSEG_1` (append view của `VWB2_RBKP_RSEG_1`, package `ZPK_LTG`) là DDIC view cổ điển (loại `VIEW/DV`, ADT báo 404). Các bước: SE11 → View `ZVWB2_RBKPRSEG_1` → Change → tab View Fields → Table fields → chọn bảng `EKPO` (đã có trong join của view gốc) → chọn field `ZZDELIV_MODEL` → Check → Activate, TR `S4RK900112`. Sau khi xong, kiểm tra bằng `DD27S` (view `ZVWB2_RBKPRSEG_1` phải có thêm dòng `ZZDELIV_MODEL` từ `EKPO`).
- **D1 (ME21N): làm dở, 3 việc còn lại (user chốt dùng BAdI `ME_GUI_PO_CUST`, implementation `ZME_GUI_PO_CUST`, class `ZCL_IM_ME_GUI_PO_CUST`, 7 method đang rỗng).**
  - **Đã tạo (23/10/2026 14:39, TR S4RK900112):** function group `ZFG_ME_GUI_PO` (package `ZPK_LTG`) gồm TOP (`TABLES: zst_ekpo`, biến `gv_display`, module PBO `status_0100` khóa field khi hiển thị), FM `ZFM_ME_GUI_PO_ITEM_PUT` (đẩy giá trị lên screen) và `ZFM_ME_GUI_PO_ITEM_GET` (lấy giá trị từ screen). Chương trình chính `SAPLZFG_ME_GUI_PO` còn hiện inactive trong `DWINACTIV` dù đã Activate nhiều lần qua ADT; sẽ hết khi bạn activate cả function group trong SE80.
  - **(1) DDIC, chặn việc lưu:** `MEPOITEM` (cấu trúc item của PO model) KHÔNG có `ZZDELIV_MODEL`, vì field đang nằm ở append `ZAST_EKPO` gắn thẳng vào bảng EKPO (cuối bảng, vị trí 485). PO model chỉ mang field khách hàng nằm trong `CI_EKPODB` (qua `EKPO_INCL_EEW_PS`, có trong EKPO, BEKPO và `MEPOITEM_DATA`). Nếu không sửa, `get_data`/`set_data` của item không có field này và ME21N không bao giờ ghi nó vào EKPO. Cách sửa chuẩn: xóa append `ZAST_EKPO` khỏi EKPO rồi tạo append structure mới trên `CI_EKPODB` (`extend type ci_ekpodb with ...`, `include zst_ekpo`). Hiện EKPO có 8.152 dòng đều trống cờ nên không mất dữ liệu; nên sửa trước khi release TR (TR chưa release nên QAS/PRD chưa có field, không phải convert lại).
  - **(2) Screen, ADT không tạo được:** trong SE80 mở `ZFG_ME_GUI_PO`, tạo screen `0100` loại Subscreen; layout: text "Delivery Model" + ô nhập lấy từ dictionary `ZST_EKPO-ZZDELIV_MODEL`; flow logic `PROCESS BEFORE OUTPUT. MODULE status_0100.` `PROCESS AFTER INPUT.` (để trống); activate cả function group.
  - **(3) Code class `ZCL_IM_ME_GUI_PO_CUST`:** chờ xong (1) rồi viết `SUBSCRIBE` (application `PO`, element `ITEM`, program `SAPLZFG_ME_GUI_PO`, dynpro `0100`), `TRANSPORT_FROM_MODEL` (đọc `mepoitem-zzdeliv_model`), `TRANSPORT_TO_DYNP` (gọi FM PUT), `TRANSPORT_FROM_DYNP` (gọi FM GET, báo đã đổi), `TRANSPORT_TO_MODEL` (ghi `set_data`).
  - `ZME_PROCESS_PO_CUST` / `ZCL_ME_PROCESS_PO_CUS` không còn cần cho việc lưu giá trị; để rỗng.

## Chưa kiểm tra được
- Màn hình/dynpro thực tế của ME21N (bảng `D021S` bị chặn quyền EU651).
- Cách `WB2R_BUSVOL` và quyết toán đọc dữ liệu (view/CDS nào là nguồn), nên chưa kết luận được D4 cần đúng object nào để lọc theo cờ.
- Code tham chiếu field theo tên (where-used của data element chỉ ra DDIC, không có program/class; `WBCROSSGT` rỗng nên không tra được tham chiếu theo tên field).
