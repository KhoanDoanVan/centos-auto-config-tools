# Phạm vi và mức độ kiểm chứng NetAdmin Toolkit

Ngày audit gần nhất: 27/11/2026.

Phạm vi được đối chiếu trực tiếp từ mã Bash trong `src/features/` và catalog Cockpit trong `site/dist/app.js`. Tài liệu yêu cầu thô đã được loại khỏi repository public sau khi hoàn tất chuẩn hóa.

## Kết luận

- Các chức năng trong phạm vi công bố có CLI Bash tương ứng.
- 123 thao tác được đưa lên Cockpit UI: Doctor 1, DNS 20, DHCP 14, Samba 18, Web 14, FTP 25, Mail 15 và Storage 16.
- `scripts/audit-static.sh` đã xác nhận cú pháp Bash/JavaScript, toàn bộ module dispatch, 123 route UI/CLI, placeholder/field và đường dẫn Cockpit runtime.
- Kết quả này **không đồng nghĩa 123 thao tác đã được nghiệm thu trên dịch vụ thật**. Các lệnh thay đổi package, service, firewall, SELinux, user, disk và tệp cấu hình phải chạy trên máy lab Linux phù hợp.
- Runtime hiện nhắm họ RHEL dùng `dnf`/`yum`. Ubuntu chỉ phù hợp chạy audit tĩnh; không dùng làm bằng chứng rằng package, service và đường dẫn CentOS hoạt động.
- RHEL/CentOS 10 đã bỏ ISC DHCP và chuyển sang Kea. Module DHCP hiện dùng `dhcpd`, vì vậy cần hệ RHEL cũ hơn 10; ưu tiên Rocky/Alma 9. Trên CentOS 10, `dhcp install` chủ động dừng với thông báo rõ thay vì báo hoàn tất giả.
- Webmail chưa được đánh dấu hoàn tất vì tài liệu yêu cầu kiểm tra package SquirrelMail hoặc chọn Roundcube cùng PHP/database. Đây là một quyết định triển khai chưa được định nghĩa, không phải một tool Bash có thể cài an toàn bằng giả định.
- Network Load Balancing chưa có script hoặc yêu cầu nguồn trong tài liệu, nên không thể đối chiếu hay tự suy diễn implementation.

Trạng thái dùng trong bảng:

- **Đủ:** có CLI, có UI và có kiểm tra/rollback phù hợp.
- **Đủ, an toàn hơn:** đạt mục tiêu bài học nhưng không tắt SELinux/firewall hoặc không xóa dữ liệu vĩnh viễn như script cũ.
- **Cần test CentOS:** đã implement và kiểm tra tĩnh, cần xác nhận package/service thật.
- **Có điều kiện:** cần lựa chọn thêm từ người triển khai.
- **Chưa có đặc tả:** tài liệu nguồn không cung cấp chức năng để implement.

## DHCP

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Cài DHCP server | `dhcp install` | Có | Hệ RHEL cũ hơn 10; ưu tiên Rocky/Alma 9; bị chặn trên RHEL/CentOS 10 |
| Tạo/cập nhật/xóa subnet scope | `dhcp scope add/update/remove` | Có | Đủ |
| Liệt kê scope | `dhcp scope list` | Có | Đủ |
| Reservation theo MAC/IP | `dhcp reservation add/list/remove` | Có | Đủ |
| Xem và release lease | `dhcp lease list/release` | Có | Đủ; release cần OMAPI hoạt động |
| Xem/check/rollback config | `dhcp config show/check/rollback` | Có | Đủ |
| Start/stop/restart/status/enable | `dhcp service ...` | Có | Đủ |

## DNS và cấu hình mạng

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Cài BIND/bind-utils | `dns install` | Có | Đủ; cần test CentOS |
| Xem NetworkManager connections | `dns network list` | Có | Đủ |
| IP tĩnh và chuyển lại DHCP | `dns network static/dhcp` | Có | Đủ |
| Master forward zone | `dns zone add` | Có | Đủ |
| Reverse zone | `dns zone add-reverse` | Có | Đủ |
| Secondary zone | `dns zone add-secondary` | Có | Đủ |
| List/remove zone | `dns zone list/remove` | Có | Đủ, an toàn hơn: zone file được đổi tên |
| A/AAAA/CNAME/MX/NS/TXT/PTR | `dns record add/list/remove` | Có | Đủ |
| Zone transfer | `dns transfer allow` | Có | Đủ |
| Forwarders | `dns forwarders set/clear` | Có | Đủ |
| Query bằng dig | `dns query` | Có | Đủ |
| Check/rollback/service | `dns config ...`, `dns service ...` | Có | Đủ |

## Storage, LVM và quota

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Xem disk và vùng trống | `storage disk list/free` | Có | Đủ |
| Tạo partition | `storage partition create` | Có | Đủ; có xác nhận target chống nhầm disk |
| Format và mount filesystem | `storage filesystem format/mount/list` | Có | Đủ; có xác nhận thao tác mất dữ liệu |
| Cài và xem LVM | `storage lvm install/list` | Có | Đủ |
| PV/VG/LV create/extend | `storage lvm ...` | Có | Đủ |
| Bật, đặt và báo cáo quota | `storage quota enable/set/report` | Có | Đủ |

## Samba/SMB

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Cài Samba server/client | `samba install` | Có | Đủ; cần test CentOS |
| Public/group share | `samba share add-public/add-group` | Có | Đủ |
| List/remove share | `samba share list/remove` | Có | Đủ, an toàn hơn: không xóa dữ liệu |
| Samba user | `samba user add/list/remove` | Có | Đủ |
| Cấp quyền read/write | `samba permissions grant` | Có | Đủ |
| Status/session | `samba status/sessions` | Có | Đủ |
| Show/check/apply/rollback | `samba config ...` | Có | Đủ |
| Client list/copy qua SMB | `samba client list/copy` | Có | Đủ; password đi qua PTY |
| Service lifecycle | `samba service ...` | Có | Đủ |

## Web Server

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Cài, enable/start Apache, firewall | `web install` | Có | Đủ; cần test CentOS |
| Tạo VirtualHost và DocumentRoot | `web site add` | Có | Đủ |
| DNS zone/A record cho website | `web dns setup/remove` | Có | Đủ; tách thành thao tác rõ ràng thay vì sửa DNS ngầm |
| List/show/remove VirtualHost | `web site list/show/remove` | Có | Đủ, an toàn hơn: giữ DocumentRoot |
| Backup/restore website | `web site backup/restore` | Có | Đủ; archive được kiểm tra path và symlink |
| Access/error log | `web log access/error` | Có | Đủ |
| Config check/rollback | `web config show/check/rollback` | Có | Đủ |
| Service lifecycle | `web service ...` | Có | Đủ |

## FTP Server

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Cài vsftpd/lftp/nc và passive mode | `ftp install` | Có | Đủ; cần test CentOS |
| DNS A record cho FTP | `ftp dns setup/check/remove` | Có | Đủ |
| Anonymous read-only/read-write share | `ftp share add-anonymous` | Có | Đủ |
| Registry/list share | `ftp share list` | Có | Đủ |
| Xóa share bằng cách chuyển vào backup | `ftp share remove` | Có | Đủ, không xóa vĩnh viễn |
| Backup/restore share | `ftp share backup/restore` | Có | Đủ |
| Local user | `ftp user add/list/remove` | Có | Đủ |
| Khóa/mở khóa user | `ftp user lock/unlock` | Có | Đủ |
| Service, port và sessions | `ftp service/status/sessions` | Có | Đủ |
| Diagnostics firewall/SELinux/share | `ftp diagnose` | Có | Đủ |
| Log | `ftp log` | Có | Đủ |
| TLS | `ftp tls configure/disable/status` | Có | Đủ; certificate phải do người quản trị cấp |
| Config check/rollback | `ftp config ...` | Có | Đủ ở mức validator vsftpd cơ bản |

Ghi chú: FTP/vsftpd được giữ để phục vụ bài lab. Với hệ thống mới nên ưu tiên giao thức mã hóa như SFTP.

## Mail Server

| Yêu cầu trong AutoScript | CLI chính | Cockpit | Trạng thái |
|---|---|---:|---|
| Cài Postfix/Dovecot/s-nail/nc | `mail install` | Có | Đủ; cần test CentOS |
| Domain/FQDN/network/Maildir | `mail configure` | Có | Đủ |
| Postfix–Dovecot auth socket/SASL | `mail configure` | Có | Đủ |
| DNS A và MX | `mail dns setup/check` | Có | Đủ |
| Mail user/Maildir | `mail user add/list/remove` | Có | Đủ |
| SMTP/POP3/IMAP TCP check | `mail test ...` | Có | Đủ |
| Status/queue/log | `mail status/queue/log` | Có | Đủ |
| Config check/rollback | `mail config ...` | Có | Đủ |
| Postfix/Dovecot service | `mail service ...` | Có | Đủ |
| Webmail SquirrelMail/Roundcube | Chưa bật | Không | Có điều kiện: phải chọn package, PHP và database được hỗ trợ |

## Network Load Balancing

| Yêu cầu | Trạng thái |
|---|---|
| NLB | Chưa có đặc tả: tài liệu nguồn ghi rõ chưa có script hoặc tài liệu nguồn |

## Checklist kiểm tra và nghiệm thu

Trên Ubuntu hoặc máy phát triển, chỉ chạy audit không thay đổi hệ thống:

```bash
./scripts/audit-static.sh
```

Để nghiệm thu toàn bộ implementation hiện tại, dùng Rocky Linux 9, AlmaLinux 9 hoặc hệ RHEL 8/9 tương đương. Trước khi cài dịch vụ, chạy preflight read-only:

```bash
./scripts/audit-runtime.sh
```

Sau đó chạy:

```bash
sudo ./bin/netadmin doctor
./bin/netadmin web help
./bin/netadmin ftp help
./bin/netadmin mail help
sudo ./bin/netadmin ui install
```

Test từng module theo runbook. Chỉ đánh dấu nghiệm thu khi package cài được, service khởi động, cấu hình qua validator, firewall/SELinux đúng và client khác trong mạng lab truy cập thành công.

CentOS Stream 10 chỉ có thể nghiệm thu các module không phụ thuộc ISC DHCP. Muốn nghiệm thu DHCP trên RHEL/CentOS 10 cần một backend Kea riêng; không được coi `dhcpd.conf` là cấu hình Kea.
