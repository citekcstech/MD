# Biến laptop thành máy remote cho nhiều người (nhiều session)

> **Cập nhật phạm vi:** nhu cầu thực tế chỉ **1 người remote vào máy Windows đang có** → dùng mục **11** (đơn giản nhất). Mục 1–10 chỉ cần khi sau này mở rộng cho nhiều người.

## 1. Điểm cần biết trước

- **Windows 10/11 Home/Pro chỉ cho 1 phiên RDP desktop tại 1 thời điểm.** Người thứ 2 đăng nhập → người đầu bị đá ra (hoặc phải chọn ngắt).
- Muốn nhiều người cùng làm việc đồng thời, có 4 hướng hợp lệ:
  1. Hệ điều hành đa người dùng (Linux, hoặc Windows Server + RDS).
  2. 1 máy ảo (VM) cho mỗi người trên cùng laptop.
  3. Chỉ cấp quyền terminal (SSH) thay vì desktop.
  4. Truy cập qua trình duyệt (Guacamole, code-server).
- **RDP Wrapper** (hack termsrv.dll để Windows Pro đa phiên): không chính thức, có thể vi phạm license Microsoft, hỏng sau mỗi lần update Windows, antivirus hay báo. Không nên dùng cho công việc thật.
- Windows 11 Enterprise multi-session chỉ có trên Azure Virtual Desktop, không cài trên laptop thường.

## 2. Chọn giải pháp theo nhu cầu

| Nhu cầu | Giải pháp | Ghi chú |
|---|---|---|
| Chỉ cần terminal: chạy code, git, Claude Code, script | **SSH + tmux** (Linux) hoặc OpenSSH Server của Windows | Nhẹ nhất, nhiều người cùng lúc, tốn ít RAM |
| Mỗi người 1 desktop riêng, không cần app Windows | **Ubuntu + xrdp** | Mỗi user có session desktop độc lập, miễn phí |
| Cần app Windows (SAP GUI, Office...) cho từng người | **Windows Server 2022 + RDS** (cần RDS CAL, có 120 ngày dùng thử) hoặc **Hyper-V VM mỗi người** | Hyper-V có sẵn trên Windows 10 Pro; mỗi VM Windows cần license riêng |
| Vào qua trình duyệt, không cài client | **Apache Guacamole** (RDP/SSH/VNC qua web) hoặc **code-server** (VS Code web) | code-server: 1 instance/người |

## 3. Cấu hình khuyến nghị (đơn giản, rẻ)

**Ubuntu (cài thay Windows, dual boot, hoặc chạy trong VM) + SSH + xrdp + Tailscale**

```bash
sudo apt update && sudo apt install -y openssh-server xrdp tmux xfce4
sudo systemctl enable --now ssh xrdp
sudo adduser user1            # mỗi người 1 user OS riêng
echo xfce4-session > ~user1/.xsession   # xrdp đa phiên ổn định hơn với XFCE so với GNOME
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

- Người dùng cài Tailscale trên máy họ, cùng tailnet → RDP/SSH tới IP Tailscale của laptop. **Không cần mở port router**, không lộ RDP/SSH ra internet.
- Mỗi người: `ssh user1@<ip-tailscale>` hoặc mở Remote Desktop tới `<ip-tailscale>:3389`.

**Nếu bắt buộc giữ Windows (SSH đa người dùng, không phải desktop):**

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

## 4. Chuẩn bị laptop để chạy 24/7

- Cắm sạc liền; nếu pin chai/phồng → tháo pin hoặc giới hạn sạc 60–80% (nếu BIOS hỗ trợ).
- Power plan: **Never sleep**, **Lid close = Do nothing** (Windows: Power Options → Choose what closing the lid does).
- Dùng **dây LAN** thay Wi-Fi; DHCP reservation hoặc IP tĩnh cho laptop.
- BIOS: bật "AC Power Recovery / Restore on AC" để tự bật lại sau mất điện. Wake-on-LAN nếu cần.
- Tản nhiệt: kê cao, tránh bụi; theo dõi nhiệt độ khi nhiều người chạy nặng.
- Auto-start dịch vụ (sshd, xrdp, tailscale) khi boot; tắt auto-update làm reboot giữa giờ làm việc.

## 5. Dung lượng tài nguyên (ước lượng)

- Mỗi người dùng nhẹ (terminal, editor, git): ~1–2 GB RAM, 1 core.
- Mỗi desktop (XFCE/Windows): ~2–4 GB RAM.
- Laptop 16 GB RAM / 4–8 core → khoảng 3–5 người nhẹ; build nặng, Docker, SAP GUI → giảm số người.
- Ổ SSD, tách quota thư mục home từng user (Linux: `quota`; Windows: FSRM trên Server).

## 6. Bảo mật (bắt buộc nếu cho người khác vào)

- Mỗi người **1 user OS riêng, không cấp quyền admin/sudo**; không dùng chung 1 tài khoản.
- Mật khẩu mạnh + SSH key; tắt đăng nhập SSH bằng password nếu được; MFA nếu dùng Guacamole/Cloudflare Access.
- **Không port-forward 3389/22 ra internet** — dùng Tailscale/ZeroTier/Cloudflare Tunnel (+ Access).
- Firewall chỉ cho interface Tailscale/LAN; bật log đăng nhập; cập nhật OS định kỳ.
- Backup dữ liệu quan trọng ra nơi khác (laptop chết là mất hết).
- Nếu dùng cho công ty: kiểm tra license OS/phần mềm (Windows client OS, SAP GUI, Office) và chính sách bảo mật dữ liệu khách hàng.
- Công cụ AI (Claude Code...) dùng chung máy: mỗi người đăng nhập tài khoản của riêng mình trong user OS của mình, không chia sẻ thông tin đăng nhập.

## 7. Truy cập từ xa qua internet — so sánh nhanh

| Cách | Ưu | Nhược |
|---|---|---|
| Tailscale / ZeroTier (VPN mesh) | Dễ nhất, không mở port, mã hóa | Mỗi người phải cài client; gói free có giới hạn số user |
| Cloudflare Tunnel + Access | Truy cập qua trình duyệt/hostname, có SSO/MFA | Cấu hình phức tạp hơn, cần domain |
| Port-forward + DDNS | Không cần client | **Rủi ro cao** (bị scan/brute-force) — không khuyến nghị |

## 8. Lộ trình đề xuất

1. Xác định nhu cầu (chỉ terminal hay cần desktop/app Windows) và số người dùng đồng thời.
2. Chọn OS: Ubuntu (nếu không cần app Windows) / Windows Server + RDS hoặc Hyper-V VM (nếu cần SAP GUI...).
3. Cài Tailscale, tạo user riêng cho từng người, bật SSH/xrdp.
4. Chỉnh power/BIOS/LAN cho chạy 24/7.
5. Test 2–3 người đồng thời, theo dõi RAM/CPU/nhiệt độ rồi mới mở rộng.

## 9. Truy cập qua trình duyệt (Apache Guacamole)

### 9.1 Kiến trúc

```
Trình duyệt ──HTTPS──> Cloudflare Tunnel (+Access SSO/MFA)
                          └─> Guacamole (Docker, laptop, 127.0.0.1:8080)
                                 ├─ SSH  ──> laptop (user OS riêng)
                                 ├─ RDP  ──> xrdp (Ubuntu) – mỗi người 1 session
                                 └─ RDP  ──> VM Windows/Hyper-V (nếu cần SAP GUI)
```

- Guacamole chỉ là **cổng web** (gateway). Số session đồng thời vẫn do **máy đích** quyết định:
  - Đích là Ubuntu + xrdp / SSH → đa phiên bình thường.
  - Đích là Windows 10/11 Pro → vẫn **1 phiên**; muốn nhiều người phải mỗi người 1 VM Windows (hoặc Windows Server + RDS).
- Mỗi người có tài khoản Guacamole riêng, chỉ thấy các connection được cấp. Để trống user/password trong connection → người dùng tự nhập tài khoản OS của mình (không lưu mật khẩu chung).

### 9.2 Chạy Guacamole bằng Docker

Chuẩn bị schema DB (1 lần, trước khi `up` lần đầu):

```bash
mkdir -p guac/initdb && cd guac
docker run --rm guacamole/guacamole:1.5.5 /opt/guacamole/bin/initdb.sh --postgresql > initdb/001-initdb.sql
```

`docker-compose.yml` (thay `<mat-khau-db>`; kiểm tra tag mới nhất trên Docker Hub rồi ghim version):

```yaml
services:
  guacd:
    image: guacamole/guacd:1.5.5
    restart: unless-stopped
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: guacamole_db
      POSTGRES_USER: guacamole_user
      POSTGRES_PASSWORD: <mat-khau-db>
    volumes:
      - ./initdb:/docker-entrypoint-initdb.d:ro
      - pgdata:/var/lib/postgresql/data
  guacamole:
    image: guacamole/guacamole:1.5.5
    restart: unless-stopped
    depends_on: [guacd, postgres]
    ports:
      - "127.0.0.1:8080:8080"      # chỉ localhost; cho ra ngoài qua tunnel
    environment:
      GUACD_HOSTNAME: guacd
      POSTGRESQL_HOSTNAME: postgres
      POSTGRESQL_DATABASE: guacamole_db
      POSTGRESQL_USER: guacamole_user
      POSTGRESQL_PASSWORD: <mat-khau-db>
      WEBAPP_CONTEXT: ROOT          # phục vụ ở / thay vì /guacamole
      TOTP_ENABLED: "true"          # bắt người dùng đăng ký MFA (Google Authenticator...)
volumes:
  pgdata:
```

- `docker compose up -d` → mở `http://localhost:8080`, đăng nhập `guacadmin/guacadmin` và **đổi mật khẩu + tạo admin riêng ngay** (xoá/vô hiệu guacadmin).
- Container → host: trên Linux thêm `extra_hosts: ["host.docker.internal:host-gateway"]` cho service `guacamole`/`guacd` rồi dùng `host.docker.internal` làm hostname connection; hoặc dùng IP LAN của laptop.
- Windows laptop: cần Docker Desktop (WSL2). Đích đa phiên nên là VM Ubuntu trong Hyper-V (xrdp) hoặc VM mỗi người.

### 9.3 Tạo user và connection

1. Settings → Users → New User (1 người 1 tài khoản).
2. Settings → Connections → New Connection:
   - SSH: hostname = laptop/VM, port 22.
   - RDP (xrdp): port 3389, Security = `any`, tick *Ignore server certificate*; Resize method = `display-update`.
   - Bật clipboard; tắt/giới hạn drive & printing nếu không cần.
3. Cấp quyền connection cho từng user; đặt *Maximum connections per user* để tránh 1 người chiếm hết RAM.

### 9.4 Đưa ra internet mà người dùng chỉ cần trình duyệt

| Cách | Cần client? | Ghi chú |
|---|---|---|
| **Cloudflare Tunnel + Access** (khuyến nghị) | Không | Cần domain; Access đặt lớp SSO/MFA trước Guacamole; hỗ trợ WebSocket |
| Tailscale Funnel | Không | URL `*.ts.net` công khai, không có lớp Access → phải dựa vào mật khẩu + TOTP của Guacamole |
| Tailscale Serve (chỉ tailnet) | Có (Tailscale) | An toàn nhất nhưng mất ý nghĩa "chỉ cần trình duyệt" |
| Port-forward 443 + DDNS | Không | Không khuyến nghị (bị scan/brute-force) |

Cloudflare Tunnel (tóm tắt):

```bash
cloudflared tunnel login
cloudflared tunnel create laptop-remote
cloudflared tunnel route dns laptop-remote remote.<domain-cua-ban>
# ~/.cloudflared/config.yml:
#   tunnel: <TUNNEL-ID>
#   credentials-file: <duong-dan>/<TUNNEL-ID>.json
#   ingress:
#     - hostname: remote.<domain-cua-ban>
#       service: http://localhost:8080
#     - service: http_status:404
cloudflared service install
```

Rồi vào Cloudflare Zero Trust → Access → Applications → thêm app cho `remote.<domain-cua-ban>` với policy (email công ty / Google SSO). Quick tunnel `trycloudflare.com` chỉ dùng test, URL đổi mỗi lần chạy.

### 9.5 Phương án nhẹ hơn nếu chỉ cần terminal/editor

- **code-server** (VS Code trên web): mỗi người 1 instance (mỗi port, mỗi user OS) phía sau reverse proxy; nặng hơn SSH nhưng có editor.
- Hoặc dùng luôn connection **SSH trong Guacamole** + tmux — không cần cài gì thêm.

### 9.6 Lưu ý bảo mật riêng cho cổng web

- Bật HTTPS (Cloudflare lo ở lớp ngoài); Guacamole chỉ bind `127.0.0.1`.
- Bắt MFA (TOTP) cho mọi user; đặt mật khẩu mạnh cho admin.
- Cập nhật image Guacamole định kỳ (có CVE theo từng bản); backup volume `pgdata`.
- Bật audit/ghi hình session (extension history) nếu dùng cho công ty.

## 10. Trường hợp chốt: laptop giữ Windows + OpenVPN + vào jump server qua web

### 10.1 Yêu cầu và hướng giải quyết

- Người dùng mở trình duyệt → Guacamole → RDP/SSH tới **jump server** nằm sau **OpenVPN** của khách hàng.
- Laptop giữ Windows nên **không** để Guacamole/OpenVPN chạy lẫn với Windows host (Guacamole không chạy native trên Windows; VPN của host + WSL2/Docker hay lỗi route/DNS trên Windows 10, không có mirrored networking).
- Thiết kế khuyến nghị: **VM Ubuntu trong Hyper-V** làm gateway; trong VM chạy Docker compose gồm `openvpn` + `guacd` (dùng chung network với container VPN) + `guacamole` + `postgres`, và `cloudflared` chạy ngoài container.

```
Trình duyệt ─HTTPS→ Cloudflare Tunnel (+Access) → [VM Ubuntu / Hyper-V trên laptop Windows]
                                                     cloudflared → guacamole:8080
                                                     guacamole → guacd ══(chung netns)══ openvpn ═VPN═> jump server
```

- Chỉ lưu lượng của guacd đi qua VPN; `cloudflared` và SSH quản trị VM đi đường internet bình thường (tránh lỗi khi file .ovpn đẩy `redirect-gateway` cả máy).
- Cloudflare Tunnel chỉ kết nối **ra ngoài** nên VM dùng switch NAT (Default Switch) là đủ, không cần mở port inbound.
- Laptop Windows Pro/Enterprise/Education có Hyper-V; Home thì dùng VirtualBox. BIOS phải bật virtualization.

### 10.2 Dựng VM Hyper-V (PowerShell admin)

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All   # xong reboot
# Tạo VM Gen2 từ ISO Ubuntu Server 22.04/24.04 (2 vCPU, 4 GB RAM, 40 GB ổ), switch "Default Switch", rồi:
Set-VMFirmware -VMName ubuntu-gw -SecureBootTemplate MicrosoftUEFICertificateAuthority
Set-VM -Name ubuntu-gw -AutomaticStartAction Start -AutomaticStopAction ShutDown
```

- `AutomaticStartAction Start`: VM tự bật khi Windows khởi động, không cần đăng nhập (khác Docker Desktop vốn chỉ chạy sau khi login).
- Trong VM: `sudo apt install docker.io docker-compose-v2` (hoặc Docker Engine chính thức), bật `sshd`, cài `cloudflared` theo mục 9.4.
- PoC nhanh: chạy cùng compose này trên Docker Desktop (WSL2) của Windows, nhưng chỉ nên dùng thử vì route/DNS qua WSL2 không ổn định và Docker Desktop không tự chạy khi chưa đăng nhập.

### 10.3 Docker compose có OpenVPN

Thư mục:

```
guac/
  docker-compose.yml
  initdb/001-initdb.sql      (tạo như mục 9.2)
  vpn/
    Dockerfile
    client.ovpn              (file khách hàng cấp; nếu dùng user/pass: thêm dòng auth-user-pass /vpn/auth.txt)
    auth.txt                 (dòng 1: user, dòng 2: password; chỉ nếu cần)
```

`vpn/Dockerfile`:

```dockerfile
FROM alpine:3.20
RUN apk add --no-cache openvpn
ENTRYPOINT ["openvpn", "--config", "/vpn/client.ovpn"]
```

`docker-compose.yml` (phần Postgres/Guacamole như 9.2, chỉ khác các điểm có chú thích):

```yaml
services:
  openvpn:
    build: ./vpn
    restart: unless-stopped
    cap_add: [NET_ADMIN]
    devices: ["/dev/net/tun:/dev/net/tun"]
    volumes: ["./vpn:/vpn:ro"]
  guacd:
    image: guacamole/guacd:1.5.5
    restart: unless-stopped
    network_mode: "service:openvpn"      # guacd đi chung network với container VPN
    depends_on: [openvpn]
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: guacamole_db
      POSTGRES_USER: guacamole_user
      POSTGRES_PASSWORD: <mat-khau-db>
    volumes:
      - ./initdb:/docker-entrypoint-initdb.d:ro
      - pgdata:/var/lib/postgresql/data
  guacamole:
    image: guacamole/guacamole:1.5.5
    restart: unless-stopped
    depends_on: [openvpn, guacd, postgres]
    ports: ["127.0.0.1:8080:8080"]
    environment:
      GUACD_HOSTNAME: openvpn            # guacd nằm trong network của container openvpn
      POSTGRESQL_HOSTNAME: postgres
      POSTGRESQL_DATABASE: guacamole_db
      POSTGRESQL_USER: guacamole_user
      POSTGRESQL_PASSWORD: <mat-khau-db>
      WEBAPP_CONTEXT: ROOT
      TOTP_ENABLED: "true"
volumes:
  pgdata:
```

Kiểm tra:

```bash
docker compose up -d --build
docker compose logs openvpn | grep "Initialization Sequence Completed"
docker compose exec openvpn ping -c 3 <ip-jump-server>
```

Lưu ý vận hành:
- Nếu container `openvpn` restart, **phải restart luôn `guacd`** (guacd mất network namespace): `docker compose restart openvpn guacd`. Có thể thêm healthcheck/autoheal.
- Container không xử lý DNS push của VPN → trong connection Guacamole dùng **IP** của jump server.
- Nếu VPN yêu cầu **OTP/MFA mỗi lần kết nối**, kết nối tự động sau khi mất mạng sẽ không tự lên được — cần hỏi khách hàng phương thức xác thực khác (cert, hoặc tài khoản dịch vụ).
- Không commit `client.ovpn`/`auth.txt` lên git; phân quyền file chỉ cho user chạy Docker.

### 10.4 Connection tới jump server trong Guacamole

- Jump server Windows → RDP: hostname = IP jump, port 3389, Security = `nla` (hoặc `any`), *Ignore server certificate*, điền *Domain* nếu đăng nhập domain; để trống user/password để mỗi người nhập tài khoản của mình.
- Jump server Linux → SSH: port 22.
- Mỗi người dùng **tài khoản riêng trên jump server**. Số người đồng thời bị giới hạn bởi jump server (Windows Server thường 2 phiên admin nếu chưa có RDS; Linux thì nhiều).
- Chỉ cấp cho user Guacamole đúng connection jump server, đặt *Maximum connections per user* = 1–2.

### 10.5 Rủi ro/chính sách cần chốt với khách hàng trước khi dùng thật

- Laptop + cổng web công khai trở thành **đường vào mạng khách hàng** → cần khách hàng đồng ý bằng văn bản.
- Nhiều người đi qua **1 tài khoản VPN** → log của khách hàng chỉ thấy 1 danh tính/1 IP; kiểm tra điều khoản VPN có cấm dùng chung tài khoản không. Nếu cấm → xin mỗi người 1 tài khoản VPN (khi đó mỗi người 1 container openvpn + guacd riêng) hoặc dùng jump/VPN do khách hàng cấp cho từng người.
- Bắt buộc: Cloudflare Access (SSO/MFA) + TOTP Guacamole, tắt `guacadmin` mặc định, cập nhật image định kỳ, backup `pgdata`.

## 11. Chốt phạm vi: chỉ 1 người, remote vào chính máy Windows đang dùng

Không cần Guacamole/VM/Docker. Windows chỉ cho 1 phiên remote — đúng nhu cầu 1 người. Nếu laptop đã tự nối OpenVPN tới jump server thì sau khi remote vào, bạn dùng VPN/jump server ngay trên máy đó như ngồi trước laptop.

### 11.1 Phương án A — Chrome Remote Desktop (qua trình duyệt, khuyến nghị)

- Chạy được cả Windows Home và Pro, không mở port, không cần domain.
- Trên laptop: mở Chrome/Edge → `remotedesktop.google.com/access` → *Set up remote access* → cài host → đặt tên máy → đặt **PIN** (≥ 6 số).
- Từ máy khác/điện thoại: mở `remotedesktop.google.com/access` bằng **cùng tài khoản Google** → chọn máy → nhập PIN.
- Bật xác minh 2 bước cho tài khoản Google đó; PIN không dùng lại mật khẩu khác.
- Sau khi cài, **restart thử 1 lần** rồi kết nối từ xa để kiểm tra có vào lại được không (khi chưa đăng nhập Windows có thể phải bật tự đăng nhập hoặc mở khoá bằng tay tại máy).

### 11.2 Phương án B — Windows Remote Desktop + Tailscale (cần Windows Pro trở lên, không qua trình duyệt)

- Laptop: Settings → System → Remote Desktop → **On** (giữ NLA bật). Tài khoản Windows dùng để vào phải có **mật khẩu** (không dùng được PIN/mật khẩu trống).
- Cài **Tailscale** trên laptop và trên máy bạn dùng để vào, đăng nhập cùng tài khoản.
- Từ máy kia: `mstsc /v:<ip 100.x của laptop trên Tailscale>` (hoặc tên máy trong tailnet).
- Không port-forward 3389 ra internet. Có thể giới hạn firewall chỉ nhận từ Tailscale (PowerShell admin):

```powershell
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -RemoteAddress 100.64.0.0/10
```

- RDP sẽ khoá màn hình tại chỗ của laptop khi bạn đang vào từ xa.

### 11.3 Chuẩn bị laptop để vào từ xa ổn định

- Cắm sạc liền; Power: **Never sleep**, **Lid close = Do nothing** (PowerShell admin):

```powershell
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
```

- Dùng dây LAN nếu được; BIOS bật "Restore on AC power loss".
- Windows Update: đặt Active hours để máy không tự restart giữa lúc đang làm việc.

### 11.4 Lưu ý khi laptop bật OpenVPN

- Nếu profile OpenVPN đẩy `redirect-gateway` (toàn bộ traffic đi qua VPN), công cụ remote vẫn thường chạy được (kết nối ra ngoài) nhưng có thể chậm hoặc bị firewall của khách hàng chặn → test khi VPN đang bật.
- Nếu laptop nối vào mạng khách hàng, kiểm tra chính sách của khách hàng về việc remote vào máy này bằng công cụ bên thứ ba (Google/Tailscale relay) trước khi dùng cho công việc thật.

## 12. Chốt: Windows RDP + VPN mesh (Tailscale, hoặc ZeroTier)

### 12.1 Hiện trạng máy (kiểm tra chỉ-đọc ngày 06.11.2026)

- Windows 10 **Business** (có RDP host như bản Pro).
- Remote Desktop **đang tắt** (`fDenyTSConnections = 1`).
- **Chưa cài** Tailscale/ZeroTier. Đã có OpenVPN 2.4.7 và OpenVPN Connect 3.9.0 (service `OpenVPNServiceInteractive` đang chạy, Automatic).
- Không đọc được rule firewall "Remote Desktop" khi không có quyền admin.

### 12.2 So sánh và chọn

| | Tailscale (khuyến nghị) | ZeroTier |
|---|---|---|
| Đăng nhập | SSO Google/Microsoft, không phải tạo network | Tạo Network ID, mỗi máy `join` rồi duyệt tay trên ZeroTier Central |
| Dải IP | `100.64.0.0/10` (CGNAT) — ít đụng dải nội bộ của khách hàng | Tự cấp từ dải 10.x / 172.x / 192.168.x → **dễ trùng** dải mạng khách hàng khi bật OpenVPN (chỉnh được nhưng phải tự quản) |
| Tên máy | MagicDNS (`mstsc /v:ten-may`) | Chỉ dùng IP |
| Chạy khi chưa đăng nhập Windows | Có (bật *Run unattended*) | Có (service) |

Với laptop đang dùng OpenVPN tới khách hàng → chọn **Tailscale**. Gói free đủ cho 1 người (kiểm tra giới hạn hiện hành trên trang giá).

### 12.3 Các bước Tailscale + RDP

1. **Laptop:** tải Tailscale for Windows (`tailscale.com/download`), cài, đăng nhập bằng tài khoản bạn kiểm soát (bật 2FA ở nhà cung cấp danh tính). Trong menu Tailscale bật **Run unattended** để vẫn nối khi chưa đăng nhập Windows.
2. **Laptop:** Settings → System → Remote Desktop → **Enable Remote Desktop** (giữ NLA bật). Tài khoản dùng để vào phải có **mật khẩu** (PIN không dùng được).
3. **(Tuỳ chọn, PowerShell admin)** chỉ cho RDP nhận từ Tailscale:

```powershell
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -RemoteAddress 100.64.0.0/10,fd7a:115c:a1e0::/48
```

4. **Máy dùng để vào:** cài Tailscale, đăng nhập **cùng tài khoản**. Lấy tên/IP laptop: `tailscale ip -4` trên laptop hoặc trang `login.tailscale.com/admin/machines`.
5. Kết nối: `mstsc /v:<ten-may-hoac-100.x.y.z>` → nhập user/mật khẩu Windows. Điện thoại: app Tailscale + app Microsoft Remote Desktop.
6. Trên trang admin Tailscale: tắt **key expiry** cho laptop (mặc định key hết hạn sau 180 ngày → máy rớt khỏi tailnet, phải đăng nhập lại tại chỗ).

### 12.4 Các bước ZeroTier (nếu vẫn muốn dùng)

1. Tạo tài khoản + network tại `my.zerotier.com` → lấy Network ID (16 ký tự), có thể đổi dải IP để tránh trùng khách hàng.
2. Cài ZeroTier One trên cả 2 máy → *Join Network* bằng ID.
3. Trên ZeroTier Central tick **Auth** cho cả 2 member, ghi lại IP được cấp.
4. `mstsc /v:<ip-zerotier-cua-laptop>`; vẫn phải bật Remote Desktop như 12.3 bước 2.

### 12.5 Lưu ý riêng khi laptop bật OpenVPN

- Sau khi VPN lên, chạy `route print` kiểm tra khách hàng không đẩy route chồng với `100.64.0.0/10` (Tailscale) hoặc dải ZeroTier; nếu chồng, RDP sẽ đứt lúc VPN bật.
- Full tunnel (`redirect-gateway`) thường vẫn chạy được (route `/10` cụ thể hơn route mặc định) nhưng kết nối tới server điều phối/relay của Tailscale đi qua VPN → có thể chậm hoặc bị firewall khách hàng chặn. **Test 1 lần với VPN đang bật** trước khi dựa vào nó.
- Máy "Business" có thể do công ty quản lý (Intune/GPO): chính sách có thể chặn cài Tailscale/bật RDP hoặc tự tắt lại → hỏi IT nếu cài xong mà không vào được.
