# cswap — đổi tài khoản Claude Code

`cswap` (claude-swap) quản lý nhiều tài khoản Claude trên 1 máy và chuyển qua lại khi 1 tài khoản hết quota 5h/7d.

## Dùng hằng ngày (4 lệnh là đủ)

| Việc cần làm | Lệnh |
|---|---|
| Xem đang dùng tài khoản nào | `cswap status` |
| Xem danh sách + quota từng tài khoản | `cswap list` (viết tắt `cswap ls`) |
| Chuyển sang tài khoản còn nhiều quota nhất | `cswap switch --strategy best` |
| Chuyển sang tài khoản kế tiếp, bỏ qua tài khoản đã hết | `cswap switch --strategy next-available` |

Sau khi switch, **mở lại phiên Claude Code** (đóng/mở lại VS Code panel hoặc terminal) để phiên mới dùng tài khoản mới. Lệnh chạy trong terminal thường, không gõ trong khung chat Claude.

## Chuyển tài khoản cụ thể

- `cswap switch <số|email>` — chuyển thẳng tới 1 tài khoản (số = slot trong `cswap list`).
- `cswap switch` (không kèm strategy) — xoay vòng sang tài khoản kế tiếp.
- `cswap switch --strategy best --model "<tên model>"` — khi so quota, tính thêm giới hạn tuần riêng của model đó (nhiều tên cách nhau dấu phẩy, hoặc `all`).

## Thêm / bớt tài khoản

1. Đăng nhập tài khoản cần thêm vào Claude Code như bình thường (`claude` → `/login`).
2. Chạy `cswap add` — lưu tài khoản đang đăng nhập vào danh sách.
3. Lặp lại cho từng tài khoản khác.

| Lệnh | Tác dụng |
|---|---|
| `cswap add` | thêm tài khoản đang đăng nhập (kèm `--slot N` để chọn số slot) |
| `cswap add-token [TOKEN]` | thêm bằng setup-token hoặc API key |
| `cswap remove <số\|email>` (`rm`) | xoá khỏi danh sách |
| `cswap disable <số\|email>` | giữ tài khoản ngoài vòng tự xoay (không xoá) |
| `cswap enable <số\|email>` | cho tài khoản quay lại vòng xoay |

## Tự động đổi khi gần hết limit

- `cswap auto` — tự chuyển khi gần chạm rate limit.
- `cswap config` xem cấu hình; `cswap config set KEY VALUE` để đổi (ví dụ `autoswitch.model`).

## Gán tài khoản theo thư mục / chạy riêng 1 terminal

- `cswap map <số|email> [đường dẫn]` — thư mục đó luôn dùng tài khoản chỉ định; `cswap map` liệt kê; `cswap unmap [đường dẫn]` bỏ gán.
- `cswap run <số|email>` — chạy Claude bằng tài khoản đó **chỉ trong terminal này**, không đổi tài khoản toàn máy. `cswap run` (không đối số) dùng tài khoản đã map cho thư mục hiện tại.

## Tiện ích khác

| Lệnh | Tác dụng |
|---|---|
| `cswap alias <số\|email> <tên>` | đặt tên ngắn (`--unset` để bỏ); `cswap alias` liệt kê |
| `cswap swap <a> <b>` / `cswap move <a> <slot>` | đổi chỗ số slot |
| `cswap tui` (hoặc gõ `cswap` trơn) / `cswap watch` | bảng điều khiển tương tác / xem quota trực tiếp |
| `cswap export <file>` / `cswap import <file>` | sao lưu / khôi phục danh sách tài khoản (file chứa token — không commit lên git) |
| `cswap list --token-status` | chẩn đoán token OAuth |
| `--json` (với `list`, `status`, `switch`) | xuất JSON cho script |
| `cswap upgrade` | tự nâng cấp bản mới |
| `cswap purge` | **xoá toàn bộ dữ liệu cswap** — cẩn thận |

## Nhờ Claude đổi giùm

Theo `CLAUDE.md` của repo VSCodeSkillAI: khi bạn nói "hết limit / hết quota 5h/7d, đổi tài khoản", Claude chạy `cswap switch --strategy best`. Xem tài khoản hiện tại/danh sách: `cswap status` / `cswap list`.

## Quy trình gợi ý khi hết limit

1. `cswap list` — xem tài khoản nào còn quota.
2. `cswap switch --strategy best`.
3. Mở lại phiên Claude Code, tiếp tục làm việc.
