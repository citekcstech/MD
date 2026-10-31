# BIDIPHAR ZPRO — Phân tích 9 issue ABAP "Chưa thực hiện"/"WIP" (cập nhật 31.10.2026)

Nguồn: `CodeABAP/BIDIPHAR_ZPRO/BDP_ChecklistIssue_Promotion.V0.1.xlsx` (sheet "List issue", dòng TRẠNG THÁI ABAP = Chưa thực hiện / WIP).
Hệ thống đọc: MCP `GUI_BIDIPHAR_DEV200` — DEV, client 200, chỉ đọc. Không sửa code, không ghi gì lên SAP.
FS đối chiếu: **chỉ** `FS/BIDIPHAR_FS_SD_ZPRO_ChucNangKhuyenMaiTangHang_V1.0 (1).docx` (trích text). Bản `V2.0.pdf` **chưa đọc được** (máy không có công cụ render PDF). Comment trong code (22/10) trích "FS mới trang 82/111" và có đoạn lệch với docx → docx V1.0 (1) có thể không phải bản chuẩn; xem câu hỏi 0.

## Tóm tắt trạng thái phân tích

| STT | Nội dung | Mức xác định |
|---|---|---|
| 63 | Lỗi font chữ | Đã xác định nguyên nhân (dữ liệu D021T) |
| 45 | Độ rộng field Text (Condition Header) | Đã xác định: `ZDE_PRO_TYPTXT` = CHAR 125 |
| 50 | Mã hình thức chỉ dành cho Z3 | Đã xác định: FS xác nhận, thiếu validation + dữ liệu sai |
| 64 | Description SO type/item cat | Không tái hiện được trên DEV200 |
| 44 | ZK01/ZK02 "ăn vào amount" | Xung đột yêu cầu / cấu hình (chưa có trong FS) |
| 65 | Duyệt xong sinh Condition Contract | Đã xác định: code là khung rỗng; thông tin field nằm trong ảnh FS |
| 66 | Pop-up mọi chương trình thoả | Logic đã có; khác FS docx ở điều kiện hiện pop-up |
| 69 | Nút "Kiểm tra quan hệ" | Code + dữ liệu test đều có; chưa rõ vì sao user thấy "không dùng được" |
| 54 | Condition Value pop-up không bắt giá trị | Chưa tái hiện; có 1 ứng viên nguyên nhân (Z2 điều kiện 04) |

## Chi tiết từng issue

### STT 63 — Lỗi font chữ (Tcode ZPRO → khai báo)
- **Nguyên nhân**: bảng `D021T` (text field màn hình) của `ZSD_PG_PROMOTION` đang lưu **ký tự `#` thật** trong DB, không phải lỗi hiển thị. Vd `Ki#m tra quan h#`, `#i#u ki#n tiên quy#t`, `Ch##ng trình #ính kèm`. Chỉ ký tự nằm ngoài Latin-1 (ạ ư ơ ế ệ ứ Đ...) bị thay bằng `#`; ký tự Latin-1 (à á â ê ì ô...) vẫn đúng.
- **Phạm vi** (query `D021T` các chương trình Z%/SAPLZ%): `ZSD_PG_PROMOTION` màn hình **0200** (18 text), **0210** (14), **0350** (2), **0340** (1, `CMND NÐD`). Không còn chương trình Z nào khác dính.
- Màn hình 0230/0270/0290 và các text 0340 khác có tiếng Việt đúng → các màn hình hỏng có thể do cách ghi/import khác (chưa xác định cách ghi).
- `Ð` (U+00D0) thay cho `Đ` (U+0110): `ÐVT FOC` (0200), `CMND NÐD` (0340), và text condition type ZK01 trong `T685T` = `CK ngay theo HÐ`.
- DDIC sạch: `DD04T`/`DD02T`/`DD03T` (ZDE_PRO%, Z%PRO%) và `VCLSTRUCT`/`VCLDIRT` (cluster ZVC_PRO_DF) lưu tiếng Việt đúng.
- Ô vuông `ch□□ng` ở Dialog Structure (SM34) trong ảnh STT 64: text trong DB đúng → nhiều khả năng là font của GUI/theme (**chưa xác minh**, nên thử trên GUI/theme khác).
- **Cách xử lý đề xuất**: nhập lại ~35 text ở trên bằng SE51 (layout) trên GUI, không dùng công cụ ghi screen bằng file/ADT. Sau đó transport.

### STT 45 — Độ rộng field Text (Khai báo Condition Header)
- Bảng `ZTB_PRO_CF_COND`, field `COND_TYPE_TXT` kiểu `ZDE_PRO_TYPTXT` → domain `ZDO_PRO_TYPTXT` = **CHAR 125** (output length 125). Dữ liệu thực chỉ ≤ 20 ký tự ("Distribution Channel"). Vì vậy cột "Text Type" rộng bất thường (đúng ảnh sheet 45).
- **Cách xử lý đề xuất**: giảm độ dài domain/data element (vd 30–40; kiểm tra nơi dùng `ZDE_PRO_TYPTXT` trước, code dùng `COND_TYPE_TXT` trong message báo lỗi) **hoặc** chỉnh độ rộng cột ở screen maintenance `SAPLZFG_PRO_DF` liste 0007 (SE54). STT 46 (Name/Description của Company code – IO type, đã DONE) là mẫu cùng loại.
- Quan sát thêm: Z2 có 1 dòng rác `COND` trống; Z2 điều kiện 04 khai `FIELDNAME = KNVV`, còn Z1/Z3 khai `KDGRP` (liên quan STT 54).

### STT 50 — Mapping SO Type–Item Category: Mã hình thức chỉ dành cho Z3
- **FS xác nhận**: mục Mapping SO Type – Item Category ghi cột "Hình thức": "Chỉ cho điền nếu Loại chương trình = Z3". FS cũng chỉ định key = Loại chương trình + Hình thức + Nguồn ngân sách (3 key); Loại chi trả và Loại điều kiện **không phải key**. Bảng `ZTB_PRO_SOITEM` đang có **5 key** (protyp, hinhthuc, ngansach, paytype, condtyp) → lệch FS.
- Maintenance trong `ZFG_PRO_DF` (liste 0026). Event TVIMF chỉ `01`/`21` (`FILL_SOITEM_TXT`) → **không có kiểm tra** → lưu được `HINHTHUC` cho Z1/Z2.
- Dữ liệu hiện có (DEV200): Z2 có dòng `HINHTHUC` = 02, 03 (ZOR2 / ZT3B, ZT2C); Z1 có dòng `HINHTHUC` = 01 (ZOR2) và 1 dòng rác `HINHTHUC` = 03, mọi cột khác trống. Theo FS các dòng Z1/Z2 này là dữ liệu sai.
- Code đọc bảng: `ZCL_PRO_APPLY=>FIND_ITEM_CATEGORY` coi ô trống = áp dụng mọi giá trị; chọn dòng khớp `protyp` và (`hinhthuc` trống hoặc = Hình thức của item). Với Z2 FS (mục tính hàng tặng) chỉ dùng "Trạng thái đăng ký/Loại điều kiện + SO Type", không nhắc Hình thức. Dòng Z2 có `HINHTHUC` 02/03 chỉ khớp khi item Z2 có Hình thức đó → dọn đi không làm mất dòng mapping có ô Hình thức trống.
- **Hướng xử lý**: thêm kiểm tra ở event TVIMF (trước khi lưu) báo lỗi khi `PROTYP <> 'Z3'` mà `HINHTHUC` có giá trị; dọn dữ liệu cũ trên DEV; xem xét key bảng theo FS.

### STT 64 — Description không bắt theo order type, item cat
- `FILL_SOITEM_TXT` (LZFG_PRO_DFF01) đã có, chạy ở event 01 (trước khi lưu) và 21 (fill hidden fields), dùng `ASSIGN ... CASTING` cho dòng TOTAL phẳng của view cluster.
- Dữ liệu DEV200: mọi dòng có `AUART`/`PSTYV` đều đã có `AUART_TXT`/`PSTYV_TXT` (trừ dòng rác không có AUART). **Không tái hiện được.**
- STT 49 (cùng nội dung) đang ghi DONE → STT 64 có thể là trùng/hồi quy. Ảnh sheet 50 cho thấy sau khi lưu ("Data was saved") text mới hiện → có thể mong muốn là hiện ngay khi chọn SO Type (không chờ Enter/Save).

### STT 44 — Condition type ZK01, ZK02 "auto ăn vào amount"
- Pricing procedure `ZRVA01` (kappl V): **ZK01 bước 210, ZK02 bước 220 đều Statistical = X**, KZWIW = 3, **KVSL1 (account key) trống**.
- `ZCL_PRO_VA_FLOW=>WRITE_CONDITIONS`: 29.10 21:36 bỏ tick Statistical (khớp STT 61 "DONE"); **30.10 đã đổi lại `ls_x-kstat = 'X'`** vì ZK01/ZK02 không sinh hạch toán. Hai trạng thái này mâu thuẫn nhau.
- FS docx V1.0 (1) **không nhắc** ZK01/ZK02/Statistical; chỉ nói "điền Amount vào Condition Type khai báo ở mức Item của dòng đơn (Item Data → tab Condition)". Chưa có căn cứ FS cho "ăn vào amount".
- Hệ quả nếu bỏ Statistical: giá trị trừ vào Net Value nhưng condition không có account key → có thể lỗi xác định tài khoản khi billing (suy luận từ cấu hình, chưa test).
- Text condition: ZK01 = "CK ngay theo HÐ", ZK02 = "Chiết khấu ngay".

### STT 65 — Duyệt chương trình: tích luỹ duyệt xong sinh Condition Contract
- Tcode ZRB24 → `ZRB_PG_APPROVE_REBATE`. `FORM RELEASE` (ZRB_IN_APPROVE_REBATE_F01 ~3431): với Z3 gọi `PERFORM CREATE_COND_CONTRACT` (~3472); lỗi (LV_OK = false) thì bỏ qua chương trình đó, không duyệt.
- **`FORM CREATE_COND_CONTRACT` (~4452) là khung rỗng**: chỉ `LPW_OK = ABAP_TRUE. CLEAR LPW_MSG.`; comment: "TODO: chưa có thông tin chi tiết các field tạo Condition Contract (FS trang 68 là hình ảnh). Hiện chưa tạo contract, luôn trả OK." → Z3 hiện được chuyển sang 02 Đã phê duyệt **mà không tạo WCOCO**, field Condition Contract (CDCT, screen 0210, luôn xám) không được cập nhật.
- FS (docx): Z3 có 2 bước — Bước 1 tạo Condition Contract trích trước và lưu số về màn hình khai báo; Bước 2 phê duyệt (02). Field Condition Contract trống ở Z3 nghĩa là chưa duyệt; Z1/Z2 không có.
- Thông tin field để tạo contract nằm trong **ảnh** trang 68 của FS → cần BA gửi dạng text.

### STT 66 — VA02: pop-up tất cả chương trình thoả
- Luồng: nút Apply (`ZCL_PRO_VA_BTN`) → `ZCL_PRO_VA_FLOW=>APPLY_PROMOTION` → `ZCL_PRO_APPLY=>PROCESS_UNIFIED` → `ZCL_PRO_PICK=>RUN`.
- Pop-up SALV đã có: nhóm theo dòng đơn, cột Chọn, Promotion No, Chương trình, Loại, Chương trình con, "Cách áp dụng" (Thủ công/Tự động · chung/riêng), Mức, Amount, FOC... Code còn đang được sửa trong ngày 30.10 (nhiều đoạn 11:12, 11:49, 14:05).
- **Điều kiện hiện pop-up**: `ZCL_PRO_PICK=>RUN`: `iv_popup = true AND line_exists( gt_prog[ manual = true ] )` → **chỉ hiện khi có ít nhất 1 chương trình Manual**. Toàn Auto thì không hiện pop-up, chỉ báo "Đã áp dụng N dòng chương trình" (đúng ảnh sheet 66).
- FS docx (Trường hợp 2.1/2.2): tất cả Option Auto → hệ thống tự áp dụng (không popup); tất cả Manual → popup. Nghĩa là code hiện tại khớp docx; yêu cầu STT 66 (pop-up luôn hiện, kể cả Auto) là thay đổi so với docx — có thể theo FS V2.0 / demo VA02 v2.2 (comment code 21/10 trích "demo VA02 v2.2").
- Ngoài ra docx (Z1 Manual) ghi Condition Header cho loại chiết khấu tiền, còn code (22/10) ghi Item theo "FS mới trang 82/111" → hai bản FS khác nhau.

### STT 69 — Nút "Kiểm tra quan hệ"
- `BT_CHKREL` (screen 0200 của ZSD_PG_PROMOTION): `WHEN 'CHKREL'` (I01 ~556) → `FORM CHECK_PRO_RELATION` (F01 ~3654, thêm 19.10.2026). Hiện popup ALV các chương trình còn hiệu lực (Valid From–To giao với chương trình đang xem) có quan hệ Include/Exclude, đối chiếu hai chiều trong `ZTB_PRO_LINKPRO`; mức Header. **Khớp FS** mô tả nút (Change & Display).
- Nút ẩn ở chế độ New (O01 ~217); không có dữ liệu quan hệ thì chỉ hiện status bar (type S) → người test dễ tưởng "không dùng được". Label nút đang hỏng do STT 63 (`Ki#m tra quan h#`).
- **Dữ liệu test có sẵn** (`ZTB_PRO_LINKPRO` 6 dòng, đều Include, không có Exclude): `1000000001`↔`1000000000` (cả hai Z1); `1000000009` (Z1, 19–24/10) ↔ `2000000002` (Z2, 17–22/10); `3000000004` (Z3, 27–31/10) ↔ `1000000018` và `1000000019` (Z1, 27–31/10). Gợi ý test: mở `3000000004` ở chế độ Change/Display, bấm nút → kỳ vọng popup 2 dòng Include.
- STT 43 (nút quan hệ giữa các chương trình) ghi "Không thực hiện" — cần làm rõ có trùng 69 không.

### STT 54 — General Condition: Condition Value pop-up không bắt giá trị
- Chưa tái hiện được nên chưa kết luận. Pop-up đã đọc: "Multiple Selection" (nút `MULT_COND` → screen 0300, structure `ZST_PRO_D16`): lưu giá trị vào `GT_MULT_CONDA` theo khoá (STT, COND, OPTI, COND_VAL) của dòng chính `ZST_PRO_D01`; F4 trong pop-up (`SH_MULCOND_COND_VAL`) lấy Condition từ dòng đang đứng của pop-up, search help từ `ZTB_PRO_CF_COND`, và chỉ đánh dấu field trả về khi `shlpfield = FIELDNAME` của cấu hình.
- **Ứng viên nguyên nhân (chưa xác minh)**: `ZTB_PRO_CF_COND` dòng **Z2 điều kiện 04 (Customer Group) khai `FIELDNAME = KNVV`**, trong khi search help `H_T151` có field `KDGRP` (Z1/Z3 khai `KDGRP`). Code lấy mô tả theo `PASS_VAL_<FIELDNAME>`: có `PASS_VAL_KDGRP`, `PASS_VAL_VKORG`, `PASS_VAL_VTWEG`, **không có `PASS_VAL_KNVV`** (và không thấy `PASS_VAL_PERNR` cho điều kiện 03 Sales Employee ở include F02) → F4 không trả giá trị về ô, mô tả trống, kiểm tra khi lưu ("giá trị không tồn tại", F01 ~5870) có thể báo lỗi. Lưu ý: DEV200 đã lưu được giá trị điều kiện 04 cho Z2 (`2000000007`), có thể khi đó `FIELDNAME` khác — cần tái hiện để chắc.
- Dữ liệu bất thường: `ZTB_PRO_COND_MUL` có **8 dòng `PRONR` trống / `STT` = 0** (vd 01/1108/1000 và Y1–Y7) — khoá lưu sai của pop-up Multiple Selection (`ZTB_PRO_COND` không có dòng nào như vậy).

## Câu hỏi cần làm rõ với BA / khách hàng
0. **Bản FS chuẩn là bản nào?** `V2.0.pdf` (29/10 09:33) hay `V1.0 (1).docx` (29/10 13:34)? Code đang bám "FS mới trang 82/111" (pdf?) và có chỗ lệch docx (Z1 chiết khấu tiền: Header hay Item; popup khi toàn Auto). Xin bản text của FS chuẩn (PDF của tôi không đọc được).
1. **STT 44**: "Ăn vào amount" nghĩa là gì — (a) giảm Net Value/giá trị đơn, hay (b) chỉ điền Amount vào condition? Nếu (a), ZK01/ZK02 phải bỏ Statistical → ai cấu hình account key (KVSL1) và hạch toán ở đâu (Finance)? STT 61 (DONE: bỏ tick Statistical) và việc giữ tick hiện nay đang mâu thuẫn — chốt hướng nào?
2. **STT 50**: xác nhận Z1/Z2 không được có Mã hình thức (theo FS) và dòng Z1/Z2 hiện có là dữ liệu test cần xoá? Có đổi key bảng về 3 key theo FS không (Loại chi trả, Loại điều kiện hiện đang là key)?
3. **STT 64**: tester cung cấp bước tái hiện (SO Type nào, nhập bằng F4 hay gõ tay, text hiện ra khi nào). Mong muốn: hiện ngay khi chọn hay sau Enter/Save? Có trùng STT 49 không?
4. **STT 65**: các thông tin để tạo Condition Contract (WCOCO), nằm trong ảnh FS trang 68: contract type, đối tác (khách hàng nào, hay 1 contract/chương trình), kỳ hiệu lực, condition type/bảng điều kiện lấy từ đâu của Z3, "trích trước" gắn với `ZTB_PRO_CTTT`?, số contract (dùng Pro.No hay number range), xử lý khi tạo lỗi (hiện: không duyệt).
5. **STT 66**: pop-up luôn hiện kể cả khi chỉ có chương trình Auto? Hiện cho cả VA01 hay chỉ VA02? Cột/nhóm hiển thị cho "chung/riêng, manual/auto" đã đủ chưa?
6. **STT 69**: tester dùng ở chế độ nào (Create/Change/Display), chương trình số mấy? Với dữ liệu test nêu trên (ví dụ `3000000004`) nút có ra popup không? Nút này có thay STT 43 (đang "Không thực hiện") không?
7. **STT 45**: độ rộng mong muốn của cột Text là bao nhiêu ký tự (đề xuất 30–40)?
8. **STT 63**: xác nhận lỗi chỉ ở màn hình ZSD_PG_PROMOTION (ZRB11/12/15) hay còn ở màn hình khác (ZRB21, ZRB24, báo cáo)?
9. **STT 54**: chức năng/tab nào, Promotion loại nào (Z1/Z2/Z3), điều kiện số mấy khi mở pop-up, và giá trị cần bắt là gì? Dòng Z2 điều kiện 04 `KNVV` có chủ ý không?

## Việc còn lại khi chạy tiếp
1. STT 54: tái hiện (hoặc hỏi tester theo câu 9); nếu đúng ứng viên nguyên nhân thì kiểm tra thêm `GET_VAL_*`/`PASS_VAL_PERNR` ở các include F02/F03.
2. STT 65: kiểm field lưu số Condition Contract (`ZTB_PRO_HEADER`/screen 0210 `CDCT_TXT`) và xem FS trang 68 khi có bản text.
3. Đối chiếu FS V2.0 khi có bản đọc được (STT 44, 65, 66).
4. Chưa đọc: `ZSD_IN_TTCTTL_F01/F02` (dùng `ZTB_PRO_SOITEM` cho tích luỹ), `ZCL_PRO_VA_BTN`.

## Ghi chú kỹ thuật MCP
Đã ghi vào `.claude/skills/sap-mcp-gui/reference/_ghichu_mcp_gui.md` (mục 1, cuối "Tra Tcode → program → Number Range"): vsp khoá request sau 1 lần đăng nhập sai (và cấu hình `--client` của DEV200), cách tra text màn hình lỗi ký tự bằng `D021T`, `GetSource` file lớn tự lưu ra file. **File skill thay đổi chưa commit** (file này vốn đã có thay đổi chưa commit trước đó của bạn).
- Riêng dự án BIDIPHAR: server `GUI_BIDIPHAR_DEV200` nằm trong `.mcp.json` gốc repo; thư mục `CodeABAP/BIDIPHAR_ZPRO` chưa có `CLAUDE.md`/`NOTES.md` riêng nên landscape dự án chưa có chỗ ghi.
