# KỊCH BẢN TỰ ĐỘNG HÓA (AUTOSCRIPT) – WEB SERVER, FTP SERVER, MAIL SERVER

> **Phạm vi:** Tổng hợp tools/packages, điều kiện chuẩn bị và thứ tự chạy chương trình Web Server, FTP Server và Mail Server trên CentOS Stream 10.
>
> **Lưu ý:** Phần Network Load Balancing chưa có script hoặc tài liệu nguồn.

---

# 1. Chuẩn bị chung

## 1.1. Thông tin hệ thống

| STT | Nội dung | Yêu cầu |
|---:|---|---|
| 1 | Hệ điều hành | CentOS Stream 10 |
| 2 | Quyền thực thi | Root hoặc tài khoản có quyền `sudo` |
| 3 | Địa chỉ IP | Xác định IP tĩnh theo sơ đồ mạng |
| 4 | Hostname/domain | Chuẩn bị tên máy chủ và domain tương ứng từng bài |
| 5 | DNS | Chuẩn bị BIND khi các chức năng cần phân giải tên miền |
| 6 | Firewall | Thống nhất chính sách giữa các dịch vụ |
| 7 | SELinux | Thống nhất trạng thái và cách cấu hình giữa Web, FTP và Mail |
| 8 | Máy client | Chuẩn bị trình duyệt, FileZilla hoặc công cụ kiểm thử theo từng bài |


**Lưu ý về SELinux:** Không sử dụng `setsebool` với giả định rằng boolean vẫn có hiệu lực khi SELinux đã `disabled`. Nếu chuyển trạng thái bằng `/etc/selinux/config`, cần khởi động lại máy để áp dụng. `setenforce 0` chỉ có tác dụng tạm thời khi SELinux đang được bật và hỗ trợ chuyển trạng thái.

---

# 2. Web Server – `webmanager-v4.sh`

## 2.1. Danh sách tools/packages

| STT | Tool/Package | Mục đích sử dụng |
|---:|---|---|
| 1 | `httpd` | Apache Web Server, quản lý VirtualHost và log |
| 2 | `bind` | DNS Server `named`, cấu hình zone |
| 3 | `bind-utils` | Truy vấn DNS bằng `dig`, `nslookup` |
| 4 | `tar` | Đóng gói và giải nén dữ liệu backup/restore |
| 5 | `curl` | Kiểm thử HTTP |
| 6 | `iproute` | Cung cấp lệnh `ip` |
| 7 | `rpm` | Kiểm tra package |
| 8 | `less` | Xem log |
| 9 | `coreutils` | Cung cấp các tiện ích như `realpath`, `mktemp` |
| 10 | `policycoreutils` | Cung cấp `restorecon` để xử lý nhãn SELinux |

Các lệnh `apachectl`, `named-checkconf` và `named-checkzone` được cung cấp bởi các package Apache/BIND tương ứng.

## 2.2. Thứ tự chạy chương trình

| Thứ tự | Menu | Chức năng | Nội dung |
|---:|---:|---|---|
| 0 | — | Chuẩn bị BIND | Chuẩn bị `bind`, `bind-utils` trước khi tạo website bằng menu 6 |
| 1 | 1 | Cài Apache | Cài đặt, enable và khởi động `httpd` |
| 2 | 2 | Start Apache | Khởi động dịch vụ |
| 3 | 3 | Stop Apache | Dừng dịch vụ |
| 4 | 4 | Restart Apache | Kiểm tra cấu hình rồi khởi động lại dịch vụ |
| 5 | 5 | Xem trạng thái | Hiển thị trạng thái Apache |
| 6 | 6 | Tạo website | Nhập domain và DocumentRoot; tạo website mẫu, cấu hình VirtualHost và thiết lập DNS zone |
| 7 | 7 | Backup website | Sao lưu website, cấu hình Apache và cấu hình DNS liên quan |
| 8 | 8 | Restore website | Khôi phục dữ liệu và cấu hình từ bản backup |
| 9 | 9 | Xem log | Xem access log và error log |
| 10 | 10 | Xóa website | Gỡ cấu hình website, xóa zone liên quan và xóa DocumentRoot theo logic script |

### Các bước chính trong menu 6

1. Nhập domain và đường dẫn website.
2. Kiểm tra đường dẫn và xác định IP server.
3. Kiểm tra BIND, backup cấu hình DNS nếu cần và bổ sung file include `/etc/named.webmanager.zones` vào cấu hình `named`.
4. Tạo thư mục website, `index.html` mẫu và VirtualHost.
5. Thiết lập nhãn SELinux phù hợp, kiểm tra cấu hình Apache và reload dịch vụ.

### Lưu ý về backup/restore

- Backup tạo file dạng `website_YYYYMMDD_HHMMSS.tar.gz` trong `/root/web-backups`.
- Restore kiểm tra đường dẫn, nội dung archive và các symlink có khả năng trỏ đến vị trí không an toàn.
- Việc kiểm tra archive không đồng nghĩa với quét mã độc.
- Xóa website có thể xóa dữ liệu thật bằng `rm -rf`; cần backup trước khi thực hiện.

### Giới hạn kết nối

Script không tự mở port 80 và 53. BIND cũng có thể mặc định chỉ lắng nghe loopback. Vì vậy, việc tạo website thành công chưa đảm bảo máy client truy cập được; cần cấu hình DNS, địa chỉ lắng nghe và firewall phù hợp.

## 2.3. Thứ tự demo đề xuất

1. Chuẩn bị BIND và `bind-utils`.
2. Chọn menu **1** để cài Apache.
3. Chọn menu **6** để tạo website.
4. Chọn menu **7** để backup.
5. Chọn menu **10** để xóa website.
6. Chọn menu **8** để restore.
7. Chọn menu **9** để xem log.

**Luồng demo chính:** `6 → 7 → 10 → 8`.

---

# 3. FTP Server – `ftp_server_manager.sh` (Phương án 2)

## 3.1. Danh sách tools/packages phía server

| STT | Tool/Package | Mục đích sử dụng |
|---:|---|---|
| 1 | `vsftpd` | FTP Server |
| 2 | `bind` | DNS Server khi sử dụng domain FTP |
| 3 | `bind-utils` | Truy vấn DNS |
| 4 | `lftp` | FTP client dòng lệnh để kiểm thử |
| 5 | `firewalld` | Quản lý firewall |
| 6 | `policycoreutils` | Cung cấp `setsebool`, `restorecon` |
| 7 | `libselinux-utils` | Cung cấp `getenforce`, `getsebool` |
| 8 | `iproute` | Cung cấp `ip`, `ss` |
| 9 | `util-linux` | Cung cấp `runuser` |
| 10 | `shadow-utils` | Cung cấp `useradd`, `passwd` |
| 11 | `curl` | Công cụ HTTP phụ trợ, không phải FTP client chính |
| 12 | `nmap-ncat` | Cung cấp `nc` để kiểm tra kết nối TCP khi cần |

**Lưu ý:** Script chính tự cài `vsftpd` bằng `dnf install -y vsftpd`. Các package phụ trợ không mặc nhiên được tự cài.

`policycoreutils-python-utils` chủ yếu cung cấp `semanage`, không phải package bắt buộc chỉ để dùng `setsebool` và `restorecon`.

## 3.2. Tools phía máy client

| Tool/Thành phần | Mục đích |
|---|---|
| FileZilla Client | Kết nối FTP, đăng nhập và truyền file |
| File `hosts` của client | Ánh xạ `ftp.sgu.edu.vn` đến IP FTP Server nếu không sử dụng DNS phù hợp |
| Passive mode | Cho phép client kết nối theo cấu hình passive FTP của server |

Khi sử dụng Passive mode, cấu hình client phải phù hợp với dải passive ports `30000–31000` trên server. Firewall phải cho phép TCP port 21 và dải passive ports nếu kết nối từ máy khác.

## 3.3. Tham số baseline FTP

Các tham số quan trọng cần đối chiếu với `/etc/vsftpd/vsftpd.conf`:

| Tham số | Giá trị | Mục đích |
|---|---|---|
| `listen` | `YES` | Lắng nghe kết nối IPv4 |
| `listen_ipv6` | `NO` | Không sử dụng chế độ lắng nghe IPv6 đồng thời với `listen=YES` |
| `anonymous_enable` | `NO` ban đầu | Tắt anonymous cho đến khi tạo share anonymous |
| `local_enable` | `YES` | Cho phép tài khoản local đăng nhập |
| `write_enable` | `YES` | Cho phép các thao tác ghi khi quyền và cấu hình khác cho phép |
| `chroot_local_user` | `YES` | Giới hạn user local trong thư mục chroot |
| `allow_writeable_chroot` | `YES` | Cho phép chroot có quyền ghi trong trường hợp cần thiết; cần cân nhắc bảo mật |
| `no_anon_password` | `YES` nếu cần | Không yêu cầu mật khẩu anonymous theo cấu hình hỗ trợ |
| `reverse_lookup_enable` | `NO` | Tắt reverse DNS lookup để tránh độ trễ khi client kết nối |
| `pasv_min_port` | `30000` | Cổng passive nhỏ nhất |
| `pasv_max_port` | `31000` | Cổng passive lớn nhất |

**Lưu ý:** Giá trị thực tế phải được xác nhận từ script và file cấu hình sau khi chạy. `allow_writeable_chroot=YES` và các tùy chọn anonymous cần được sử dụng đúng với mô hình phân quyền của bài lab.

## 3.4. Thứ tự chạy chương trình

| Thứ tự | Chức năng | Nội dung |
|---:|---|---|
| 0 | Chuẩn bị | Chuẩn bị package phụ trợ, DNS nếu cần, firewall, SELinux và máy client |
| 1 | Khởi tạo FTP Server | Script kiểm tra `dnf`, cài `vsftpd` và tạo file quản lý share |
| 2 | Cấu hình baseline | Backup cấu hình gốc, thiết lập local user, quyền ghi, chroot và passive ports |
| 3 | Khởi động dịch vụ | Enable/start `vsftpd` |
| 4 | Quản lý dịch vụ | Start, stop, restart và xem trạng thái |
| 5 | Tạo share anonymous | Tạo thư mục dưới `/var/ftp/`, thiết lập quyền và bật anonymous khi cần |
| 6 | Tạo share local user | Tạo hoặc sử dụng tài khoản Linux, tạo thư mục FTP và thiết lập quyền |
| 7 | Kiểm tra, chẩn đoán | Kiểm tra dịch vụ, port, firewall, SELinux, danh sách share và quyền ghi |
| 8 | Xóa share | Di chuyển thư mục vào `/var/backups/ftp-manager-v2/` và cập nhật danh sách share |
| 9 | Công cụ mở rộng | Gọi FTP version 1 để sử dụng các chức năng DNS/BIND, TLS, log, khóa user và backup/restore nếu được hỗ trợ |

## 3.5. Thứ tự demo đề xuất

1. Chuẩn bị package phụ trợ và cấu hình kết nối client.
2. Chạy chương trình, khởi tạo baseline.
3. Chọn **menu 2 – tạo share anonymous**.
4. Chọn **menu 3 – tạo share local user**.
5. Chọn **menu 5 – kiểm tra, chẩn đoán**.
6. Chọn **menu 4 – xóa share**.

**Luồng demo:** `1 → 2 → 3 (anonymous) → 3 (user) → 5 → 4`.

---

# 4. Mail Server 

## 4.1. Danh sách tools/packages

| STT | Tool/Package | Mục đích sử dụng |
|---:|---|---|
| 1 | `postfix` | SMTP/MTA, gửi và chuyển tiếp thư |
| 2 | `dovecot` | POP3/IMAP, nhận và đọc thư |
| 3 | `httpd` | Apache Web Server phục vụ webmail |
| 4 | `telnet` | Kiểm thử SMTP/POP3 |
| 5 | `epel-release` | Bổ sung repository EPEL khi cần |
| 6 | `squirrelmail` | Webmail theo PDF gốc; phải xác minh package có khả dụng trên CentOS Stream 10 |
| 7 | `bind` | DNS Server, cấu hình zone và bản ghi mail |
| 8 | `bind-utils` | Truy vấn DNS |
| 9 | `dhcp-server` | DHCP nếu yêu cầu bài lab sử dụng lại dịch vụ từ bài trước |

`dhcp-server` không phải dependency trực tiếp của Postfix hoặc Dovecot. Chỉ triển khai DHCP trên máy này nếu đúng yêu cầu của sơ đồ lab.

## 4.2. Thông số mẫu

| Thông số | Giá trị mẫu |
|---|---|
| Domain | `sgu.edu.vn` |
| Hostname/FQDN | `server.sgu.edu.vn` |
| IP server | `192.168.1.1` |
| Subnet | `192.168.1.0/24` |
| `mynetworks` | `192.168.1.0/24, 127.0.0.0/8` |
| DNS zone | `sgu.edu.vn` |
| Bản ghi A | `server.sgu.edu.vn` trỏ đến `192.168.1.1` |
| Bản ghi MX | `sgu.edu.vn` trỏ đến `server.sgu.edu.vn` |
| User thử nghiệm | `u1` |
| Mailbox | `Maildir/` |

Các giá trị trên là thông số mẫu của PDF. Nếu sơ đồ mạng thực tế khác, phải thay IP, subnet, hostname và các bản ghi DNS tương ứng. `mynetworks` chỉ nên chứa những mạng được phép gửi thư qua server.

## 4.3. Thứ tự chạy chương trình

| Thứ tự | Thành phần | Nội dung |
|---:|---|---|
| 0 | Chuẩn bị hệ thống | Xác định IP, hostname, domain, firewall và chính sách SELinux |
| 1 | DNS/BIND | Chuẩn bị zone `sgu.edu.vn`, bản ghi A và MX |
| 2 | Postfix | Cài đặt và cấu hình SMTP trong `/etc/postfix/main.cf` |
| 3 | Tài khoản thử nghiệm | Tạo user `u1` và đặt mật khẩu |
| 4 | Dovecot | Cài đặt, cấu hình POP3/IMAP, Maildir và xác thực |
| 5 | Tích hợp Postfix–Dovecot | Cấu hình socket/listener và quyền tương ứng trong `10-master.conf` |
| 6 | Apache | Cài đặt hoặc sử dụng `httpd` đã có |
| 7 | Webmail | Cài đặt và cấu hình SquirrelMail nếu package khả dụng |
| 8 | Firewall/SELinux | Cho phép các dịch vụ và cổng cần thiết theo mô hình lab |
| 9 | Kiểm thử SMTP | Sử dụng Telnet để kiểm tra SMTP |
| 10 | Kiểm thử POP3 | Sử dụng Telnet để kiểm tra POP3 |
| 11 | Kiểm thử webmail | Đăng nhập bằng `u1`, gửi và nhận thư |

### Các tham số cấu hình chính

**Postfix – `/etc/postfix/main.cf`**

| Tham số | Giá trị mẫu |
|---|---|
| `myhostname` | `server.sgu.edu.vn` |
| `mydomain` | `sgu.edu.vn` |
| `myorigin` | `$mydomain` |
| `inet_interfaces` | `all` |
| `inet_protocols` | Theo IPv4/IPv6 được sử dụng trong lab |
| `mynetworks` | `192.168.1.0/24, 127.0.0.0/8` |
| `home_mailbox` | `Maildir/` |

`mydestination` cần bao gồm hostname/domain mà server chịu trách nhiệm nhận thư.

**Dovecot**

| File cấu hình | Nội dung chính |
|---|---|
| `/etc/dovecot/dovecot.conf` | Khai báo protocol cần dùng, chẳng hạn `imap`, `pop3` |
| `/etc/dovecot/conf.d/10-mail.conf` | Cấu hình `mail_location = maildir:~/Maildir` |
| `/etc/dovecot/conf.d/10-auth.conf` | Cấu hình phương thức xác thực phù hợp |
| `/etc/dovecot/conf.d/10-master.conf` | Cấu hình listener/socket liên quan đến xác thực và tích hợp Postfix |

Trong `10-master.conf`, cần xác định đúng khối `unix_listener` cần chỉnh theo cấu hình thực tế và PDF; không thay đổi hàng loạt các listener. Khối `auth-userdb` chỉ nên được sửa nếu đúng là listener được yêu cầu trong bài.

### Webmail trên CentOS Stream 10

1. Phương án gốc sử dụng SquirrelMail.
2. Cần xác minh package `squirrelmail` có trong repository đã bật hay không.
3. Nếu package không khả dụng, phải ghi rõ thay đổi phương án và chuyển sang webmail khác, chẳng hạn Roundcube.
4. Roundcube có yêu cầu cấu hình riêng về PHP, database, đường dẫn và Apache; không sử dụng nguyên cấu hình SquirrelMail cho phần mềm thay thế.
5. Với Apache 2.4, sử dụng chỉ thị `Require all granted` khi phù hợp; không sử dụng cú pháp Apache 2.2 `Order allow,deny` và `Allow from all`.

## 4.4. SELinux và firewall

- Thống nhất chính sách SELinux giữa Web, FTP và Mail.
- Không tắt SELinux rồi tiếp tục coi các lệnh `setsebool` là có hiệu lực.
- Nếu sửa `/etc/selinux/config` để chuyển trạng thái lâu dài, cần reboot.
- `setenforce 0` chỉ chuyển sang permissive tạm thời khi SELinux đang được bật.
- Chỉ mở những cổng cần thiết cho mô hình lab, ví dụ SMTP TCP/25, POP3 TCP/110 và HTTP TCP/80 khi sử dụng các dịch vụ tương ứng.
- Không tắt toàn bộ firewall nếu có thể cho phép riêng từng dịch vụ.

## 4.5. Kiểm thử Mail Server

**Kiểm thử SMTP:**

```bash
telnet localhost smtp
```

**Kiểm thử POP3:**

```bash
telnet localhost pop3
```

Sau khi các dịch vụ hoạt động:

1. Truy cập webmail theo URL/alias đã cấu hình.
2. Đăng nhập bằng tài khoản `u1`.
3. Gửi thư thử đến tài khoản nhận phù hợp.
4. Xác nhận thư được lưu trong Maildir và có thể đọc qua giao thức đã cấu hình.
