# Windows – biến máy tính thành Remote Desktop (host RDP)

## Hiện trạng đã kiểm tra (06.11.2026)

| Máy | Hệ điều hành | RDP | Ghi chú |
|---|---|---|---|
| CT-SANG-VU-BK (ảnh Settings) | Windows 11 | **On** (theo ảnh) | Đã bật, còn phải kiểm tra user, firewall, cách kết nối |
| CT-SANG-VU (máy chạy Claude Code) | Windows 10 Pro 21H2 | **Off** (`fDenyTSConnections=1`, service TermService đang Stopped) | `citek\sang.vu` **không phải admin** nên không tự bật được; nhóm Remote Desktop Users đang trống; cả 2 card mạng đang ở profile Public |

Windows Home không làm được host RDP (chỉ làm client). Pro/Business/Enterprise/Education thì được.

## Các bước (chạy bằng quyền Administrator)

1. **Bật RDP**: Settings → System → Remote Desktop → gạt **On** → Confirm.
   Hoặc PowerShell admin:
   ```powershell
   Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
   Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
   ```
2. **Cho phép user vào**: tài khoản Administrator được vào sẵn. User thường phải thêm vào nhóm Remote Desktop Users:
   Settings → Remote Desktop → *Remote Desktop users* → Add. Hoặc:
   ```powershell
   Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'citek\sang.vu'
   ```
3. **Giữ máy không ngủ**: máy sleep/hibernate thì không kết nối được. Bản Settings của CT-SANG-VU-BK không có tuỳ chọn "Keep my PC awake" trong mục mở rộng (chỉ có NLA + cổng 3389), nên vào Settings → System → Power → *Screen and sleep* → đặt **Sleep = Never** khi cắm điện. Hoặc PowerShell admin: `powercfg /change standby-timeout-ac 0`.
4. **Firewall/mạng**: nếu kết nối bị chặn, kiểm tra profile mạng (Public thường chặn) và rule "Remote Desktop – User Mode (TCP-In)" cổng 3389.
5. **Kết nối từ máy khác**: `mstsc` → nhập tên máy (`CT-SANG-VU-BK`) hoặc IP → đăng nhập bằng tài khoản Windows của máy host.
   - Cùng LAN/Wi-Fi công ty: dùng tên máy hoặc IP nội bộ.
   - Khác mạng (ở nhà, ngoài công ty): kết nối **VPN công ty** trước rồi mstsc như trên.

## Lưu ý an toàn

- **Không port-forward 3389 ra Internet** (bị dò mật khẩu/ransomware rất nhiều).
- Giữ nguyên "Require Network Level Authentication" (đang bật), dùng mật khẩu mạnh.
- Máy Pro chỉ có 1 phiên: khi có người remote vào, màn hình tại máy sẽ bị khoá.
- Không có VPN: dùng Tailscale, hoặc công cụ khác như Chrome Remote Desktop, thay vì mở cổng RDP.

## Kiểm tra nhanh trên máy host

```powershell
Get-NetTCPConnection -LocalPort 3389 -State Listen   # phải thấy đang Listen
Test-NetConnection <ten-may-host> -Port 3389          # chạy từ máy client, TcpTestSucceeded = True
```
