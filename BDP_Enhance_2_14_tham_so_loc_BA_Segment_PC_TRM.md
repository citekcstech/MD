# BDP — Enhance 2.14: Tham số lọc Business Area / Segment / Profit center ở TBB1, TPM10, TPM13, TPM20

Nguồn: `CodeABAP/BDP/Enhance/BIDIPHAR_FI_Enhancement_V1.0_internal (1).docx`, mục 2.14. Mục này **chỉ có ở bản "(1)"** (so với bản không có "(1)" — đã diff, khác nhau đúng mục 2.14). Mục "Mô tả thiết kế kỹ thuật" của FS **để trống** → phải tự đề xuất.
Hệ đọc: `GUI_BIDIPHAR_DEV100` (client 100, đọc 05.11.2026). **Chưa tạo/sửa gì trên SAP.**
Trạng thái (05.11.2026): đã đọc FS + đối chiếu hệ; user đã chốt Q1/Q2 (mục 5) → **giai đoạn này chỉ làm lọc Profit center**; BA/Segment để sau khi mục 2.6 xong. Chờ user duyệt thiết kế mục 6 rồi mới code.

## 0. Phạm vi đã chốt (05.11.2026)

- Q1: chỉ làm **lọc Profit center** trước (dùng `VTBFHA-PRCTR`); **BA và Segment hoãn** đến khi mục 2.6 (custom field BA trên Transaction) xong. Mục 3 giữ nguyên làm thiết kế cho giai đoạn sau.
- Q2: theo bảng FS — 4 Tcode `TBB1`, `TBB1_LC`, `TPM10`, `TPM13`; `TPM20` không làm.
- Hệ quả: **TPM13 không có việc gì ở giai đoạn này** (FS để trống cột Profit center vì chuẩn đã có `so_prft`; chỉ còn BA/Segment bị hoãn). Việc thực tế = **TBB1 + TBB1_LC (cùng program `RFTBBB00`) và TPM10**.

## 1. Yêu cầu trong FS (mục 2.14)

- Hiện trạng: màn hình các Tcode phân hệ TRM thiếu tham số lọc Business Area, Segment, Profit center.
- Yêu cầu: thêm tham số lọc theo bảng (mục "Yêu cầu thay đổi" và "Thiết kế nghiệp vụ" ghi **giống hệt** nhau):

| Tcode | Segment | Profit center | Business Area | Ghi chú FS |
|---|---|---|---|---|
| TBB1 | X | X | X | Search help chuẩn SAP; lọc các Transaction tương ứng |
| TBB1_LC | X | X | X | như trên |
| TPM10 | X | X | X | như trên |
| TPM13 | X | (trống) | X | như trên |

- **Mâu thuẫn trong FS**: tiêu đề mục ghi `TBB1, TPM10, TPM13, TPM20` nhưng bảng không có `TPM20` mà có thêm `TBB1_LC` → xem câu hỏi Q2.

## 2. Hiện trạng hệ (đọc DEV100, 05.11.2026)

| Tcode | Program | Cách chọn dữ liệu hiện tại | Segment / BA / PC có sẵn? |
|---|---|---|---|
| TBB1 | `RFTBBB00` | `SELECT DISTINCT ... FROM vtbfha INNER JOIN vtbfhapo` trong `FORM bewegungen_lesen`; màn hình chọn ở include `RFTBBB00_SEL` (block `common`: `s_bukrs`, `s_rfha`, `s_sgsart`, ... `s_fhazba`). Kết quả vào `i_fha` (BUKRS, RFHA, SANLF, RANL) rồi đẩy sang `lcl_rtpm_parallelization_tbb1` | **PC**: `VTBFHA-PRCTR` có sẵn nhưng chưa có ô lọc. **BA/Segment**: không có field nào trong `VTBFHA`/`VTBFHAPO` |
| TBB1_LC | `RFTBBB00_LEGACY_CONVERSION` (gọi cùng logic, cờ `p_legacy`) | như TBB1 | như TBB1 |
| TPM10 | `RTPM_SLD_ASYNC_POST` | Chọn qua `cl_query_service_sld=>cls_get_trans_by_cc_va_dn` (theo số deal) hoặc `cls_get_trans_by_position` (ranges `difs_selection_ranges_add`); kết quả `l_tab_trans_marked` (có `company_code`, `deal_number`) rồi hiển thị `TPM_SLD_ASYNC_POST_DISPLAY` | `DIFT_POS_IDENT-PROFIT_CENTER` có trong dữ liệu position nhưng **không có ô lọc** trên màn hình; BA/Segment không có |
| TPM13 | `RTPM_TRL_SHOW_FLOWS` | Include chuẩn `ITPM_POSITION_SELECTION`; gọi `TPM_TRL_FLOW_PROTOCOL` với các `so_*` | **PC đã có** `so_prft` (`MODIF ID PRF`, bật/tắt qua `handle_position_attributes` — chưa đọc form này) → khớp việc FS để trống PC cho TPM13. BA/Segment: không có trong `trgs_position_selection` |
| TPM20 | `RTPM_TRAC_POSTING_JOURNAL` | **Chưa đọc** (không có trong bảng FS) | — |

Kết quả tra thêm:

- **Business Area và Segment không nằm ở bất kỳ bảng TRM nào** (`VTBFHA`, `VTBFHAPO`, `DIFT_POS_IDENT` — kiểm `DD03L`). Riêng `PRCTR` có ở `VTBFHA` và `DIFT_POS_IDENT`.
- Mục 2.6 của cùng FS ("Enhance cập nhật Segment, Business Area trên chứng từ TRM") đã yêu cầu **custom field Business Area trên `FTR_CREATE`/`FTR_EDIT`** và Segment/PC lấy từ BA theo ENH-FICO-002. Mục 2.6 **chưa có object Z nào** trên DEV (NOTES, 05.11.2026) → hiện **chưa có chỗ lưu BA của Transaction** để mà lọc.
- Bảng mapping mục 2.1 **đã có**: `ZTB_MAP_BA_SEGM` (khóa `MANDT` + `GSBER`; field `SEGMENT`, `PRCTR`), Tcode `ZBA_SEGMENT` (package `ZPK_BDP`). Client 100 có 19 dòng (vd `1000 → S1000/P1000`, `2001 → S1000/P2001`, `4001 → S4000/P4001`). → Segment lọc được qua BA bằng bảng này (nhiều BA → 1 Segment).
- `ENHOBJ` không có enhancement implementation nào của BDP cho 7 object liên quan (RFTBBB00, RFTBBB00_SEL, RFTBBB00_F01, RTPM_SLD_ASYNC_POST, RTPM_TRL_SHOW_FLOWS, RTPM_TRAC_POSTING_JOURNAL, RFTBBB00_LEGACY_CONVERSION) → chưa ai enhance.
- `VTBFHA` 0 dòng ở client 100/300 → chưa có deal để test; phải tạo tay ở `FTR_CREATE`.

## 3. Đề xuất thiết kế kỹ thuật (nháp, chờ user chốt mục 5)

Nguyên tắc: **1 class dùng chung** `ZCL_TRM_SEL_FILTER` (method `GET_DEALS` nhận range BUKRS + GSBER + SEGMENT + PRCTR, trả danh sách `BUKRS`/`RFHA`) để 4 Tcode cùng 1 logic.

- **Nguồn dữ liệu lọc**
  - Business Area: bảng Z lưu BA theo Transaction (`BUKRS`+`RFHA` → `GSBER`) — **chính là phần "custom field BA" của mục 2.6** (dùng chung hạ tầng tab riêng BAdI `FTR_CUSTOMER_EXTENT` đã làm ở 2.13).
  - Segment: không lưu, suy từ BA qua `ZTB_MAP_BA_SEGM` (đồng bộ với ENH-FICO-002).
  - Profit center: `VTBFHA-PRCTR` (chuẩn). Nếu FS muốn PC suy từ BA qua mapping thì đổi nguồn (Q4).
- **TBB1 / TBB1_LC (`RFTBBB00`)**: 3 `SELECT-OPTIONS` (tham chiếu `GSBER`, `FB_SEGMENT`, `PRCTR` → search help chuẩn) thêm bằng **implicit enhancement ở cuối include `RFTBBB00_SEL`**; lọc bằng implicit enhancement ở **cuối `FORM bewegungen_lesen`**: `DELETE i_fha` các deal không thuộc kết quả `GET_DEALS`. Nếu sau lọc rỗng → báo message như `meldung_erfolglose_selektion`. Không có BAdI chuẩn nào cho việc này (`FTR_TR_DISTRIBUTOR` là phân luồng song song, `FTR_TR_TBB1_EXIT` chỉ có `VBUND_EXIT`).
- **TPM10 (`RTPM_SLD_ASYNC_POST`)**: thêm 3 select-option, lọc `l_tab_trans_marked` theo (`company_code`, `deal_number`) sau bước đọc, trước `TPM_SLD_ASYNC_POST_DISPLAY`.
- **TPM13 (`RTPM_TRL_SHOW_FLOWS`)**: chỉ thêm BA + Segment (PC dùng ô `so_prft` chuẩn, có thể chỉ cần bật qua Customizing position attribute); thu hẹp danh sách deal (`g_tab_sel_otc_deal`/`so_otcnr`) trước khi gọi `TPM_TRL_FLOW_PROTOCOL`.
- **Rủi ro kỹ thuật cần kiểm trước khi code** (không kiểm được qua MCP): `RTPM_SLD_ASYNC_POST` và `RTPM_TRL_SHOW_FLOWS` viết thẳng trong event block của program chính (không có FORM/include để gài) → phải xem trong SE80/SE38 "Edit → Enhancement Operations → Show Implicit Enhancement Options" để biết điểm gài nào dùng được. Nếu không có điểm hợp lý: phương án dự phòng là copy sang program Z + Tcode Z (khác FS vì đổi tên Tcode) hoặc modification có SSCR key (không khuyến nghị).
- **Selection text** của select-option thêm qua enhancement không vào được text pool của program chuẩn → gán text bằng code ở `INITIALIZATION` (`%_<so>_%_APP_%-TEXT`) hoặc dùng `SELECTION-SCREEN COMMENT`.
- Object dự kiến (chưa tạo, đặt tên theo quy ước dự án): class `ZCL_TRM_SEL_FILTER`; bảng BA theo Transaction (nếu làm 2.6 cùng); 4 enhancement implementation (`RFTBBB00_SEL`, `RFTBBB00` form, `RTPM_SLD_ASYNC_POST`, `RTPM_TRL_SHOW_FLOWS`).

## 4. Kế hoạch test (sau khi code)

1. Tạo ≥ 3 deal ở `FTR_CREATE` với BA khác nhau (vd 1000, 2001, 4001) — user làm tay vì chưa có deal.
2. `TBB1` (chạy thử `p_test = X`): lọc theo BA, theo Segment (S1000 phải ra cả deal BA 1000 và 2001), theo PC; để trống cả 3 → kết quả như trước.
3. Lặp lại với `TBB1_LC`, `TPM10`, `TPM13`; kiểm `TPM13` không bị mất ô PC chuẩn.

## 5. Câu hỏi chốt FS

| # | Câu hỏi | Mục FS | Đề xuất của dev | Chặn? | Trả lời |
|---|---|---|---|---|---|
| Q1 | Segment/BA chưa lưu ở đâu trên Transaction (mục 2.6 chưa làm). Làm 2.14 phải làm kèm 2.6 (custom field BA) hay chỉ lọc PC trước? | 2.14 + 2.6 | Làm 2.6 phần lưu BA trước (tab riêng, bảng Z), rồi 2.14 | **[CHẶN]** | 05.11.2026 user chọn: **chỉ làm lọc Profit center trước**, BA/Segment sau khi 2.6 xong |
| Q2 | Tiêu đề ghi `TPM20` nhưng bảng không có; bảng có `TBB1_LC` mà tiêu đề không ghi. Phạm vi thật: TBB1, TBB1_LC, TPM10, TPM13 (theo bảng) và bỏ TPM20? | 2.14 | Theo bảng (4 Tcode), TPM20 làm sau nếu cần | **[CHẶN]** | 05.11.2026 user chọn: **theo bảng, 4 Tcode** (không TPM20) |
| Q3 | Tham số để trống thì không lọc (như hiện tại)? Deal chưa có BA thì ẩn hay vẫn hiện khi người dùng không nhập BA? | 2.14 | Trống = không lọc, deal chưa có BA vẫn hiện; nhập BA thì chỉ ra deal khớp | Không | _chờ_ |
| Q4 | Profit center lọc theo `VTBFHA-PRCTR` của Transaction hay suy từ BA qua `ZTB_MAP_BA_SEGM-PRCTR`? | 2.14 | `VTBFHA-PRCTR` (chuẩn) | Không | _chờ_ |
| Q5 | `RTPM_SLD_ASYNC_POST`/`RTPM_TRL_SHOW_FLOWS` có thể không có điểm gài implicit enhancement → chấp nhận copy program Z + Tcode Z cho 2 Tcode này nếu bắt buộc? | 2.14 | Kiểm SE80 trước; chỉ hỏi lại nếu không có điểm gài | Không | _chờ_ |

## 6. Thiết kế giai đoạn này — chỉ lọc Profit center (chờ user duyệt, chưa tạo gì)

| Tcode | Việc làm | Điểm gài (dự kiến) | Ghi chú |
|---|---|---|---|
| TBB1, TBB1_LC (`RFTBBB00`) | Thêm 1 select-option `S_PRCTR FOR vtbfha-prctr` (search help chuẩn của `PRCTR`) vào block "General Selections"; sau khi `FORM bewegungen_lesen` đọc xong `i_fha`, xoá các deal có `VTBFHA-PRCTR` không thuộc `S_PRCTR` | Implicit enhancement cuối include `RFTBBB00_SEL` (khai báo) + cuối `FORM bewegungen_lesen` (lọc) | `TBB1_LC` dùng chung program nên làm 1 lần. Lọc rỗng → báo message không có dữ liệu như `meldung_erfolglose_selektion`. `S_PRCTR` trống = không lọc |
| TPM10 (`RTPM_SLD_ASYNC_POST`) | Thêm select-option Profit center (tham chiếu `dift_pos_ident-profit_center`); lọc `l_tab_trans_marked` theo (`company_code`, `deal_number`) → `VTBFHA-PRCTR` của deal trước khi hiển thị `TPM_SLD_ASYNC_POST_DISPLAY` | Program viết thẳng trong event block (không FORM/include) → **chưa chắc có điểm gài**, phải kiểm SE80 → Edit → Enhancement Operations → Show Implicit Enhancement Options | Nếu không có điểm gài → quay lại hỏi user (Q5) |
| TPM13 (`RTPM_TRL_SHOW_FLOWS`) | **Không làm** ở giai đoạn này | — | Chuẩn đã có `so_prft`; nếu màn hình chưa hiện ô PC thì đó là cấu hình position attribute (Customizing), không phải code |

- Object mới dự kiến: enhancement implementation cho `RFTBBB00_SEL` và `RFTBBB00` (form `BEWEGUNGEN_LESEN`), cho `RTPM_SLD_ASYNC_POST` (nếu có điểm gài); không cần bảng/class Z ở giai đoạn này. Package `ZPK_BDP`, TR mới theo quy ước tên team (`Tên_Phân hệ_Chức năng_dd.mm.yyyy_Mô tả`).
- Selection text cho `S_PRCTR`: gán trong `INITIALIZATION` (`%_S_PRCTR_%_APP_%-TEXT`) vì enhancement không sửa được text pool của program chuẩn.
- Khi ghi lên SAP: enhancement implementation (SE19/SE80) MCP có thể không ghi được (giống include `PROG/I` — `package metadata not found`) → dự phòng: user tạo khung ở SE19, MCP điền code hoặc user dán tay.
- Test: cần deal thật ở `FTR_CREATE` có Profit center khác nhau (VTBFHA đang 0 dòng ở client 100/300).

## 7. Tiến độ code (05.11.2026) — TBB1/TBB1_LC xong code, chờ user tạo hook ở SE80

- TR đã tạo: `DEVK901218` (`SangVT_FI_TRM_LocProfitCenter_05.11.2026_Enhance 2.14`, package `ZPK_BDP`), hiện còn trống.
- Code: `CodeABAP/BDP/Enhance/TRM_2_14_PRCTR/src/zenh_fi_trm_tbb1_prctr.enho.abap` (1 enhancement implementation `ZENH_FI_TRM_TBB1_PRCTR`, 3 hook). `SyntaxCheck` sạch khi chạy thử bản bỏ vỏ `ENHANCEMENT/ENDENHANCEMENT` trong wrapper program có sẵn (có vỏ thì chỉ báo warning "enhancement implementation n is not defined", không kiểm thân code).
- **MCP không tạo được enhancement implementation**: `CreateObjectAtomic` loại `ENHO/XHH` → `unsupported object type: ENHO/XHH`; `CreateObject` không có loại ENHO; công cụ cũng không nhận tham số "điểm gài". Chưa tạo gì trên SAP ngoài TR. Việc tạo hook là của user (SE80), MCP chỉ đọc/kiểm tra sau đó.

### 7.1 Các bước user làm ở SE80 (cùng 1 enhancement implementation cho cả 3 hook)

1. SE38 → mở include `RFTBBB00_SEL` (Display) → menu **Edit → Enhancement Operations → Show Implicit Enhancement Options** → đi tới **dòng cuối include** (sau `INCLUDE dbfti_tr_par_creategui.`) → chọn dòng enhancement option → **Enhancement Implementation → Create** → tên `ZENH_FI_TRM_TBB1_PRCTR`, mô tả `Enhance 2.14 - Loc Profit center TBB1`, package `ZPK_BDP`, TR `DEVK901218` → dán **khối 1** (các dòng giữa `ENHANCEMENT 1` và `ENDENHANCEMENT` trong file code) → Activate.
2. Mở program `RFTBBB00` → bật Show Implicit Enhancement Options → tìm `FORM modify_screen` → option ở **ngay trước `ENDFORM`** → Create Implementation, chọn lại implementation `ZENH_FI_TRM_TBB1_PRCTR` đã có → dán **khối 2**.
3. Cùng program `RFTBBB00` → `FORM bewegungen_lesen` → option **ngay trước `ENDFORM`** → chọn lại cùng implementation → dán **khối 3** → Activate toàn bộ implementation.
4. Làm đúng thứ tự 1 → 2 → 3 vì khối 2 và 3 dùng `zprc_ttl`, `s_zprctr` khai báo ở khối 1.
5. Báo lại tên implementation; MCP sẽ kiểm: `RunQuery` `ENHOBJ`/`ENHHEADER` (active), đọc `/sap/bc/adt/enhancements/enhoxhh/zenh_fi_trm_tbb1_prctr/source/main` so với file code, `SyntaxCheck` `RFTBBB00` (kiểm xem lỗi khi activate).

### 7.2 TPM10 — chưa làm, cần user kiểm điểm gài

`RTPM_SLD_ASYNC_POST` không có FORM/include để gài, chỉ có event block. Hai vấn đề:
- Khai báo select-option cần điểm gài ở **đầu program** (sau `REPORT`) — chưa biết có tồn tại không.
- Chỗ lọc (giữa bước "delete duplicates" và `TPM_SLD_ASYNC_POST_DISPLAY`) nằm giữa event block → **không có điểm gài**. Lọc trong `TPM_SLD_ASYNC_POST_DISPLAY` không dùng được vì chạy nền (`SJOB`) thì `pa_dis` bị xoá, FM này không được gọi → bộ lọc bị bỏ qua mà không báo, và job sẽ hạch toán cả deal ngoài Profit center đã chọn.
- Phương án khả thi: (a) gài cuối method `CL_QUERY_SERVICE_SLD=>CLS_GET_TRANS_BY_CC_VA_DN` và `...BY_POSITION` (lọc `re_tab_transaction`), lấy giá trị ô lọc bằng `ASSIGN '(RTPM_SLD_ASYNC_POST)S_ZPRCTR[]'` + chặn bằng `sy-cprog`; cần thêm điểm gài đầu program để khai báo ô. (b) Copy sang `ZTPM10...` + Tcode Z (khác FS). (c) Bỏ TPM10 khỏi đợt này, xin tư vấn.
- Việc user cần làm để chốt: SE38 → `RTPM_SLD_ASYNC_POST` → Show Implicit Enhancement Options → báo có marker nào ở **ngay sau câu `REPORT`** và ở **đầu event `START-OF-SELECTION`** không.
