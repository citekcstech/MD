# BDP_PCE – ZBCPM01: tem in bị mất chữ "ó" (thiết bị 100448, client 200)

Ngày: 02.11.2026 · Hệ: `GUI_BIDIPHAR_DEV200` (system DEV, client 200, chỉ đọc).

## Hiện tượng

- Xem trước Adobe Form: `Test_Cụm cấp gi[trống]  số 20-ĐK-LTT` — mất chữ "ó" trong "gió".
- ALV trước khi in vẫn hiện đủ `Test_Cụm cấp gió số 20-ĐK-LTT`.

## Dữ liệu thật (`EQKT-EQKTX`, equipment 100448, `SPRAS = E`)

Giá trị lưu: `Test_Cụm cấp gió số 20-ĐK-LTT`. Cấu trúc ký tự (kiểm bằng `RunQuery` với `LIKE` và `_`, mẫu chỉ gồm ASCII):

| Chữ | Cách lưu | Mẫu khớp | Mẫu không khớp |
|---|---|---|---|
| gió | `o` + dấu sắc rời (U+0301) | `gio_ s`, `gi__ s` | `gi_ s` |
| cấp | `a` + 2 dấu rời (mũ + sắc) | `ca__p` | `c_p g` |
| Cụm | `u` + dấu chấm dưới rời | `Cu_m` | — |
| số | `ô` dựng sẵn + dấu sắc rời | `s__ 20` | `s_ 20`, `so_ 20`, `so__ 20`, `s___ 20` |
| ĐK | ký tự dựng sẵn | `-ĐK-` | — |

→ Tên thiết bị đang ở **dạng tổ hợp Unicode (NFD, lẫn lộn)**, không phải ký tự dựng sẵn (NFC). Tool `RunQuery` truyền chữ có dấu đúng (câu đối chứng `-ĐK-` khớp).

## Phân tích

- Code `zbcpm01.abap` đưa `descr` sang form nguyên vẹn (`ls_label-descr = <lfs_alv>-descr`, CHAR 40 sang CHAR 40, không cắt: chuỗi dài 34 đơn vị mã < 40) → dữ liệu không bị mất ở ABAP. ALV hiển thị đúng xác nhận điều đó.
- Chỗ mất chữ là bước Adobe dựng PDF. Form dùng font `Arial` (`adobe/gen_zpm_af_tem.py`).
- **Chưa giải thích được** vì sao chỉ "gió" mất còn "cấp", "số", "Cụm" (cũng tổ hợp) vẫn hiện. Đây là suy luận, chưa kiểm chứng bằng in thử.
- `ExecuteABAP` bị chặn ở client 200 (`TK730`, client không sửa được repository) nên chưa dump được mã Unicode từng ký tự; thay bằng cách đếm ký tự ở trên.

## Đã sửa và đẩy lên SAP (02.11.2026 10:10, user xác nhận)

- DEV100, TR `DEVK900344`: 3 lần `EditSource` (`syntax_check=true`), cả 3 activate thành công. `ExportToFile` source SAP (853 dòng) `diff` với file local: giống hệt.
- Thêm FORM `NORMALIZE_NFC` (`CHANGING cv_text TYPE char40`), gọi ngay sau khi gán `gs_alv-descr` ở `get_data_equipment` và `get_data_funcloc` → ALV, log và tem cùng dạng NFC. Lỗi ICU thì giữ nguyên văn bản.
- **Chưa test chạy**: cần in lại thiết bị 100448 ở client 200.

Cách làm (lõi là lời gọi class chuẩn, đặt trong FORM thay vì trong `print_selected`):

```abap
cl_icu_normalization=>normalize(
  EXPORTING im_text     = <lfs_alv>-descr
            im_normmode = cl_icu_normalization=>unorm_nfc
  IMPORTING ex_text     = lv_descr ).
```

- Class chuẩn `CL_ICU_NORMALIZATION` (package `SI18N_ICU`, kernel `icunrmkm_normalize`). Ngoại lệ: `CX_ICU_NOT_A_UNICODE_SYSTEM`, `CX_ICU_OTHER_ERROR`, `CX_ICU_WRONG_NORMMODE` → bắt và dùng nguyên văn nếu lỗi.
- Sau khi sửa, in lại 100448 ở client 200 để xác nhận "gió" hiện đủ. Nếu vẫn mất thì bước tiếp theo là kiểm tra font nhúng/ADS của form (không phải dữ liệu).
- Nguồn gốc dữ liệu NFD (nhập từ bộ gõ/ứng dụng nào) chưa rõ; nên chuẩn hoá khi nhập thiết bị nếu còn nhập thêm.

## Quan sát phụ (chưa kiểm tra, ngoài phạm vi)

Ở ALV (ảnh chụp), tiêu đề cột 5 và 6 hiện `Logical System` và `Plant` thay vì `Sub-asset` và `Nhà máy` như `display_alv` đặt bằng `set_long_text`. Có thể do `optimize` chọn text ngắn/vừa từ DDIC; cần đặt thêm `set_medium_text`/`set_short_text` nếu muốn sửa.
