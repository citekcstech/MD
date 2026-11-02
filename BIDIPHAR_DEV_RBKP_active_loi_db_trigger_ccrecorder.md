# BIDIPHAR DEV — lỗi activate bảng RBKP: "There is a DB trigger on the table"

Ngày kiểm: 02.11.2026 · Hệ DEV (client 100/200/300 dùng chung 1 DB HANA, `10.100.100.33:44300`) · User `CT.CSTECH`

## Hiện tượng

SE14 log (DEV/100) khi convert RBKP để thêm field `ZZ1_BUDGETDEPT_MIH` (Key User custom field):

- `Trigger CCRECORDER_20261102064245_300_RBKP_*_TRIGGER does not comply with SAP LT Trigger Naming Convention`
- `Table change not possible. There is a DB trigger on the table.`
- `Compare module DD_DECIDE ended with error(s)` → `Request for RBKP could not be executed`

## Nguyên nhân gốc

Trigger thừa của một **client copy bị chết giữa chừng**, không phải trigger riêng của RBKP.

| Bằng chứng | Kết quả |
|---|---|
| `SYS.TRIGGERS` | 57.706 trigger `CCRECORDER_20261102064245_300_*` (3 trigger/bảng, ~19.800 bảng), tạo 13:45:22 → 13:51:32 (giờ DB). RBKP có đúng 3 trigger AFTER INSERT/UPDATE/DELETE. Không có bộ CCRECORDER nào khác |
| Thân trigger | Đọc `CCTABWORKLIST` (`tstamp='20261102064245'`, `table_status='READY'`) rồi ghi `CCTRIGGERLOGGER` (chỉ `MANDT='300'`) — cơ chế ghi delta của Client Copy |
| `CCCFLOWV2` session `20261102064245` (`CUSTADMIN`) | `STATUS_PROCESSING = CANCELLED`, `ABORTED`: "Processing stopped without DB update (timeout, system shutdown, uncatchable exception) - Last known status: SAVE_SELTAB" |
| `CCTABWORKLIST` | Session `064245` **không có dòng nào** → trigger không ghi gì, nhưng vẫn chặn đổi cấu trúc bảng |
| Session đang chạy | Không còn session client copy nào active. Mọi session khác của CT.MFG / CT.SD / CT.FICO / CT.MM đều `FINISHED`. Job `CLIENTCOPY_REBUILD_CLIENT_SIZE_C` (CT.MFG, đang chạy) chỉ là bước tính lại client size |
| DB RBKP | Có `ZZ1_CREATEDBYEMAIL_MIH`, `ZZ1_EXRATEHAIQUAN_MIH`; **chưa có** `ZZ1_BUDGETDEPT_MIH` (dù DDIC active, `RBKP_DATA` vị trí 164) |

Trigger ở mức DB nên chặn DDIC conversion của **mọi client** (100/200/300) và **mọi bảng** có trigger — không chỉ RBKP.

## Cách xử lý (chưa thực hiện — chờ user đồng ý)

**Khuyến nghị:** chạy công cụ dọn trigger thừa chuẩn của SAP — FM `SCCR_TRIGGER_LEFTOVER_DROP` (FUGR `SCCR_TRIGGER`, SE37 → F8, không tham số).

- Logic SAP (`CL_SCCR_TRIGGER_LEFTOVER_CHECK`): trigger `CCRECORDER_%` có timestamp không thuộc process đang chạy là "thừa" → `DROP TRIGGER` từng cái.
- Trước khi chạy: xác nhận không ai đang chạy client copy mới (SCC3 / SCC9N).
- Sau khi chạy: kiểm `SYS.TRIGGERS` hết `CCRECORDER_%`, rồi SE14 → RBKP → Activate and adjust database (thêm cột `ZZ1_BUDGETDEPT_MIH`, HANA ADD COLUMN nhanh).

Phương án hẹp (không khuyến nghị): chỉ `DROP` 3 trigger của RBKP — mở được RBKP nhưng 57.703 trigger còn lại vẫn chặn mọi bảng khác (field Key User khác sẽ lỗi y hệt).

## Cần soát lại sau khi dọn

Mọi field Key User / thay đổi cấu trúc bảng kích hoạt **từ 13:45 ngày 02.11.2026** trên bất kỳ bảng nào có thể đã lỗi giống RBKP (VD các job `CFD_FIELD_GENERATION` của CT.CSTECH 20:56–21:33). Sau khi dọn trigger, kiểm lại SE14 log / chạy lại.

## Tác động đang xảy ra (phát hiện lúc xử lý)

RBKP đang **lệch DDIC ↔ DB** (DDIC active có `ZZ1_BUDGETDEPT_MIH`, DB chưa có cột) nên người dùng thật đang dump: `Inconsistency in the dictionary for structure "RBKP"` và `Syntax error in program "SAPLFMRI"/"SAPMF05L"` (CT.FICO, client 100/200; dump mới nhất 23:01:33). Các chương trình hạch toán/thuế dùng RBKP (SAPLPC32, SAPLTAX1, SAPMF05L, SAPLFMRI) đều dính → cần activate xong RBKP càng sớm càng tốt.

## Tiến độ xử lý (02.11.2026)

- 23:00 — user đồng ý phương án "chạy FM chuẩn SAP". Đã kiểm trước: không còn session client copy nào active (`CCCFLOWV2` không có session ngoài FINISHED/CANCELLED).
- 23:00 — `ExecuteABAP` mức `dangerous`: `CALL FUNCTION 'SCCR_TRIGGER_LEFTOVER_DROP' STARTING NEW TASK 'DROPLEFT'` → `subrc = 0`. SAP tự đánh giá có 57.046 trigger thừa (`CL_SCCR_TRIGGER_LEFTOVER_CHECK`; thấp hơn tổng 57.706 là 660 trigger, nghi tên dài bị cắt trong cấu trúc SAP — chưa xác nhận).
- Job nền khởi động chậm ~45 giây rồi drop ~65–70 trigger/giây: 57.706 (23:01:37) → 54.913 (23:02:24) → 53.768 (23:02:42) → 51.230 (23:03:19). Dự kiến xong khoảng 23:16.
- Lúc 23:03 RBKP vẫn còn 3 trigger (thứ tự drop không theo bảng). 23:09:16 còn 26.548.
- **23:16:01 — dọn xong:** `SYS.TRIGGERS` còn **0** trigger `CCRECORDER%` (kể cả 660 trigger SAP không đếm ở bước kiểm — giả thuyết "tên dài bị cắt" không gây sót), RBKP còn **0** trigger. Tổng thời gian khoảng 16 phút, không có dump từ job dọn. Cột `ZZ1_BUDGETDEPT_MIH` vẫn **chưa có** trong DB RBKP → chờ SE14 activate.

## Việc còn lại

1. ~~Dọn trigger~~ — xong, 0 trigger còn lại.
2. ~~Gọi lại FM nếu time-out~~ — không cần.
3. ~~Activate RBKP~~ — user làm trong SE14 lúc 23:17:14 (xem "Kết quả cuối").
4. Soát các field Key User / bảng khác đã lỗi từ 13:45 (xem mục "Cần soát lại") — **chưa làm**.

## Kết quả cuối (02.11.2026 ~23:20) — RBKP đã xử lý xong

- 23:17:14 — user activate RBKP trong SE14 (*Activate and adjust database*). `DD02L` RBKP `AS4TIME = 231714`. DB (`SYS.TABLE_COLUMNS`) có `ZZ1_BUDGETDEPT_MIH` ở vị trí 206, cạnh `ZZ1_CREATEDBYEMAIL_MIH` (204) và `ZZ1_EXRATEHAIQUAN_MIH` (205). `SYS.TRIGGERS`: 0 trigger `CCRECORDER%` / RBKP.
- DDIC tự activate dây chuyền các structure include trực tiếp RBKP (10 structure): `MCRBHD` 23:17:42, `EDOC_RBKP` và `MCRBKP` 23:17:43, `WB2_RBKP` 23:17:44, `SAPI_LIV_HEADER`/`_CTRL` 23:17:56, `SAPI_LIV_ITEM` 23:17:57, `SAPI_LIV_ITEM_CTRL` 23:17:58, `WB2_ALV_IV_HEAD` 23:17:59, `WB2_IV_DATA` 23:18:00.
- Dump cuối cùng liên quan: 23:17:53 `DDIC_TYPE_REF_ACCESS_ERROR` (CT.SD, client 200, `SAPLWB2_TEW_ACTION_SERVICE`: "WB2_IV_DATA refers to type WB2_RBKP — abap type or abap length inconsistent"). Nó rơi vào khoảng giữa `WB2_RBKP` (23:17:44) và `WB2_IV_DATA` (23:18:00) của đợt activate dây chuyền → thoáng qua. Không có dump RBKP nào sau đó.
- Không thuộc lỗi này: append `ZAEKPO_INCL_EEW_PS_ANA` (CT.CSTECH) đang inactive (`AS4LOCAL = N`, 23:18:46) — việc khác của user.

## Ghi chú khác

- Session `20261102051117` (CUSTADMIN) cũng `CANCELLED` (DELETE_COPY) và vẫn còn 127.754 dòng `READY` + 56 `WAIT_DELETE` trong `CCTABWORKLIST`. Trigger của session này không còn trong DB nên không chặn gì; dữ liệu worklist là rác tồn đọng, không cần xử lý cho lỗi RBKP.
- Đã ghi kiến thức vào `.claude/skills/abap-platform-constraints/reference/_ghichu_local.md` (mục On-Premise). Phần hành vi tool MCP (`ExecuteABAP` + ADBC đọc `SYS.TRIGGERS`) chưa ghi vào `_ghichu_mcp_gui.md` vì file đang conflict git (UU).
