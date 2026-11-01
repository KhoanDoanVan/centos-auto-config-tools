# Web, FTP và Mail Server từ cơ bản đến từng command

Chương này giải thích ba module mới `web`, `ftp` và `mail` cho người chưa quen quản trị mạng. Mỗi module quản lý một dịch vụ khác nhau:

| Module | Dịch vụ | Client thường dùng | Cổng cơ bản |
|---|---|---|---|
| Web | Apache HTTP Server | Trình duyệt, `curl` | TCP 80 |
| FTP | vsftpd | FileZilla, `lftp` | TCP 21 và passive ports |
| Mail | Postfix + Dovecot | Mail client, Telnet trong lab | SMTP 25, POP3 110, IMAP 143 |

Ba dịch vụ không thay thế nhau. Web phục vụ trang web, FTP truyền file, còn Mail chuyển và lưu thư điện tử.

## 1. Nguyên tắc an toàn chung

Trước khi thực thi thật, xem command bằng Cockpit với **Dry run** bật hoặc chạy:

```bash
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin web install
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin ftp install
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin mail install
```

Toolkit thực hiện các nguyên tắc sau:

- Không tắt toàn bộ firewall; chỉ mở service/cổng cần thiết.
- Không tắt SELinux; đặt context hoặc boolean theo tính năng.
- Backup cấu hình trước khi thay đổi quan trọng.
- Xóa VirtualHost, FTP share hoặc user không tự xóa dữ liệu tương ứng.
- Kiểm tra cấu hình trước khi báo thành công.

Các cấu hình trong tài liệu phục vụ mạng lab. Nếu đưa dịch vụ ra Internet, cần bổ sung TLS, chính sách mật khẩu, chống brute force, cập nhật bảo mật và giới hạn truy cập.

## 2. Web Server và Apache

### 2.1 Apache làm gì?

Apache (`httpd`) lắng nghe yêu cầu HTTP từ trình duyệt. Mỗi website có:

- `ServerName`: tên miền website, ví dụ `lab.local`.
- `DocumentRoot`: thư mục chứa `index.html` và các file web.
- VirtualHost: khối cấu hình liên kết tên miền với DocumentRoot.
- Access log: ghi request của client.
- Error log: ghi lỗi xử lý request.

### 2.2 Cài Apache

```bash
sudo ./bin/netadmin web install
```

Command cài `httpd`, `curl`, `tar`, công cụ SELinux; kiểm tra cấu hình, enable/start service và mở HTTP trong firewalld. HTTPS không được mở/cấu hình tự động khi chưa có certificate TLS.

### 2.3 Tạo website

```bash
sudo ./bin/netadmin web site add <domain> <document-root>
```

Ví dụ:

```bash
sudo ./bin/netadmin web site add lab.local /var/www/lab.local
```

Tool sẽ:

1. Xác thực domain và đường dẫn tuyệt đối.
2. Tạo DocumentRoot nếu chưa có.
3. Tạo `index.html` mẫu nếu file chưa tồn tại.
4. Tạo VirtualHost trong `/etc/httpd/conf.d/netadmin-<domain>.conf`.
5. Chuẩn bị SELinux context cho nội dung web.
6. Chạy `apachectl configtest`.

Module Web cung cấp tool DNS riêng để có thể kiểm soát rõ thay đổi:

```bash
sudo ./bin/netadmin web dns setup lab.local @ 192.168.10.2
```

Hoặc dùng hostname `www`:

```bash
sudo ./bin/netadmin web dns setup lab.local www 192.168.10.2
sudo ./bin/netadmin web dns remove lab.local www
```

`dns setup` tạo zone nếu chưa có rồi thêm A record. Tool dùng chung validator, backup và kiểm tra zone của module DNS.

### 2.4 Liệt kê và xem website

```bash
./bin/netadmin web site list
./bin/netadmin web site show lab.local
```

`list` chỉ hiển thị VirtualHost do NetAdmin quản lý. `show` in toàn bộ file cấu hình của domain được chọn.

### 2.5 Gỡ VirtualHost

```bash
sudo ./bin/netadmin web site remove lab.local
```

Command backup rồi xóa file VirtualHost và kiểm tra lại Apache. DocumentRoot cùng dữ liệu website được giữ nguyên.

### 2.6 Backup và restore website

```bash
sudo ./bin/netadmin web site backup lab.local
sudo ./bin/netadmin web site restore lab.local
sudo ./bin/netadmin web site restore lab.local /path/to/archive.tar.gz
```

Backup chứa VirtualHost, metadata và toàn bộ DocumentRoot, mặc định nằm trong `/var/backups/netadmin/web-sites`. Restore dùng backup mới nhất nếu không truyền archive, kiểm tra member path, từ chối symlink và yêu cầu xác nhận trước khi ghi đè file trùng tên. File khác đang có trong DocumentRoot không bị tự động xóa.

### 2.7 Log, cấu hình và service

```bash
./bin/netadmin web log access 50
./bin/netadmin web log error 100 lab.local
./bin/netadmin web config show
sudo ./bin/netadmin web config check
sudo ./bin/netadmin web config rollback lab.local
sudo ./bin/netadmin web service enable-now
sudo ./bin/netadmin web service restart
sudo ./bin/netadmin web service status
```

`rollback <domain>` khôi phục backup gần nhất của file VirtualHost. Sau khi tạo hoặc sửa website, dùng `reload` hoặc `restart` để Apache đọc cấu hình mới.

### 2.7 Kiểm thử Web

```bash
curl -I http://127.0.0.1
curl http://lab.local
```

Nếu tên miền chưa phân giải, kiểm tra bằng `dig`, DNS record hoặc file `hosts` của client.

## 3. FTP Server và vsftpd

### 3.1 FTP hoạt động thế nào?

FTP dùng một kết nối điều khiển trên TCP 21 và kết nối dữ liệu riêng. Trong passive mode, server mở thêm một cổng thuộc dải cấu hình. NetAdmin dùng dải `30000-31000/tcp`.

FTP truyền username, password và dữ liệu không mã hóa. `vsftpd` và `lftp` đã bị deprecate trên RHEL 10; chỉ sử dụng FTP thuần trong mạng lab. Với hệ thống mới, ưu tiên SFTP hoặc WebDAV.

### 3.2 Cài vsftpd

```bash
sudo ./bin/netadmin ftp install
```

Command cài `vsftpd`, `lftp`, `nc`, OpenSSL, BIND, công cụ firewall/SELinux và thiết lập baseline:

- IPv4 listener bật, IPv6 listener tắt để tránh xung đột.
- Local user và quyền ghi được bật.
- Local user bị chroot trong home.
- Anonymous ban đầu tắt.
- Passive ports là `30000-31000`.
- Firewall mở FTP và dải passive ports.
- BIND được chuẩn bị để module có thể tạo A record FTP.

Thiết lập và kiểm tra DNS FTP:

```bash
sudo ./bin/netadmin ftp dns setup lab.local ftp 192.168.10.2
./bin/netadmin ftp dns check ftp.lab.local 192.168.10.2
sudo ./bin/netadmin ftp dns remove lab.local ftp
```

### 3.3 Tạo anonymous share

Read-only:

```bash
sudo ./bin/netadmin ftp share add-anonymous public read-only
```

Cho phép ghi trong mạng lab:

```bash
sudo ./bin/netadmin ftp share add-anonymous upload read-write
```

Share được tạo dưới `/var/ftp/<name>`. Chế độ read-write bật upload/mkdir anonymous và SELinux boolean tương ứng. Anonymous write có rủi ro cao; không bật trên server public.

### 3.4 Liệt kê và gỡ share

```bash
./bin/netadmin ftp share list
sudo ./bin/netadmin ftp share remove public
sudo ./bin/netadmin ftp share backup public
sudo ./bin/netadmin ftp share restore public
```

`remove` chuyển thư mục cùng metadata vào `/var/backups/netadmin/ftp-shares/<name>-<timestamp>` rồi mới gỡ registry. `backup` sao chép snapshot nhưng giữ share hoạt động; `restore` dùng snapshot mới nhất nếu không truyền đường dẫn.

### 3.5 Local FTP user

```bash
sudo ./bin/netadmin ftp user add ftpuser /srv/ftp/ftpuser
./bin/netadmin ftp user list
sudo ./bin/netadmin ftp user remove ftpuser
sudo ./bin/netadmin ftp user lock ftpuser
sudo ./bin/netadmin ftp user unlock ftpuser
```

`user add` tạo Linux user có shell `/sbin/nologin`, tạo home và yêu cầu nhập mật khẩu hai lần. `user remove` xóa account nhưng không dùng `userdel -r`, do đó home vẫn còn.

Trên Cockpit, mật khẩu được chuyển qua PTY và không xuất hiện trong command preview.

### 3.6 Kiểm tra và vận hành FTP

```bash
./bin/netadmin ftp config show
sudo ./bin/netadmin ftp config check
sudo ./bin/netadmin ftp config rollback
sudo ./bin/netadmin ftp service enable-now
./bin/netadmin ftp status
./bin/netadmin ftp sessions
./bin/netadmin ftp diagnose
./bin/netadmin ftp log 100
```

vsftpd không có validator offline tương đương `apachectl configtest`; `config check` kiểm tra cú pháp `key=value` cơ bản và xung đột listener trước khi restart.

TLS cho local user:

```bash
sudo ./bin/netadmin ftp tls configure /etc/pki/tls/certs/ftp.crt /etc/pki/tls/private/ftp.key
./bin/netadmin ftp tls status
sudo ./bin/netadmin ftp tls disable
```

Tool dùng `openssl` kiểm tra certificate/private key trước khi sửa cấu hình và rollback nếu validator phát hiện lỗi.

### 3.7 Kiểm thử bằng lftp

Anonymous:

```bash
lftp -e 'ls; quit' ftp://192.168.10.2
```

Local user:

```bash
lftp -u ftpuser ftp://192.168.10.2
```

Nếu client đăng nhập được nhưng không liệt kê/truyền file, kiểm tra dải passive ports trong firewall và chế độ passive của client.

## 4. Mail Server với Postfix và Dovecot

### 4.1 Vai trò của từng thành phần

- Postfix là MTA: nhận, chuyển và xếp hàng thư SMTP.
- Dovecot cho người dùng đọc thư qua POP3 hoặc IMAP.
- Maildir là cấu trúc thư mục lưu mỗi email thành một file trong home user.
- DNS A record ánh xạ hostname mail sang IP.
- DNS MX record cho biết mail server chịu trách nhiệm cho domain.

### 4.2 Cài mail stack

```bash
sudo ./bin/netadmin mail install
```

Command cài Postfix, Dovecot và `s-nail`; enable hai service và mở SMTP/IMAP/POP3 trong firewalld. Command chưa tự cấu hình domain hoặc start service.

Webmail không được tự động cài. SquirrelMail có thể không còn trong repository CentOS Stream 10; Roundcube cần PHP và database riêng nên không được cài ngầm như một package thay thế.

### 4.3 Cấu hình domain mail

```bash
sudo ./bin/netadmin mail configure \
  <domain> <server-fqdn> <trusted-network-cidr>
```

Ví dụ:

```bash
sudo ./bin/netadmin mail configure \
  lab.local mail.lab.local 192.168.10.0/24
```

`trusted-network-cidr` là mạng được phép relay theo bài lab. Không nhập `0.0.0.0/0`, vì điều đó có thể biến server thành open relay.

Tool cấu hình:

- `myhostname`, `mydomain`, `myorigin`.
- IPv4 listener trên các interface.
- `mynetworks` gồm mạng lab và loopback.
- `mydestination` cho hostname/domain local.
- `home_mailbox = Maildir/`.
- Dovecot POP3/IMAP, Maildir và cơ chế login.
- Socket xác thực Dovecot tại `/var/spool/postfix/private/auth` và SMTP AUTH phía Postfix.

Chế độ lab cho phép plaintext authentication trong trusted network. Trước khi đưa ra mạng không tin cậy, phải cấu hình TLS và tắt plaintext authentication.

### 4.4 Tạo DNS record cho Mail

Thiết lập A và MX bằng một command:

```bash
sudo ./bin/netadmin mail dns setup lab.local mail.lab.local 192.168.10.2
```

Kiểm tra:

```bash
dig @192.168.10.2 mail.lab.local A
dig @192.168.10.2 lab.local MX
./bin/netadmin mail dns check lab.local 192.168.10.2
```

### 4.5 Tạo mail user

```bash
sudo ./bin/netadmin mail user add u1
./bin/netadmin mail user list
sudo ./bin/netadmin mail user remove u1
```

`user add` tạo Linux account, yêu cầu mật khẩu và tạo `~/Maildir` với quyền `0700`. `user remove` giữ nguyên home/Maildir để tránh mất thư ngoài ý muốn.

### 4.6 Kiểm tra, queue, log và service

```bash
./bin/netadmin mail config show
sudo ./bin/netadmin mail config check
sudo ./bin/netadmin mail config rollback
sudo ./bin/netadmin mail service postfix enable-now
sudo ./bin/netadmin mail service dovecot enable-now
./bin/netadmin mail status
./bin/netadmin mail queue
./bin/netadmin mail log 100
```

`config check` chạy `postfix check` và `doveconf -n`. `queue` dùng `mailq`. `log` ưu tiên `/var/log/maillog` hoặc `/var/log/mail.log`, sau đó dùng systemd journal.

### 4.7 Kiểm thử trong mạng lab

SMTP:

```bash
telnet 127.0.0.1 25
```

POP3:

```bash
telnet 127.0.0.1 110
```

IMAP:

```bash
telnet 127.0.0.1 143
```

Telnet chỉ phù hợp để quan sát giao thức trong lab. Không gửi mật khẩu thật qua kết nối plaintext trên mạng không tin cậy.

Kiểm tra nhanh port mà không nhập lệnh protocol thủ công:

```bash
./bin/netadmin mail test smtp 127.0.0.1
./bin/netadmin mail test pop3 127.0.0.1
./bin/netadmin mail test imap 127.0.0.1
```

## 5. Luồng demo đề xuất

### Web

```text
install → site add → service enable-now → curl → log → site remove → rollback
```

### FTP

```text
install → share add-anonymous → user add → service enable-now → lftp → sessions
```

### Mail

```text
install → configure → DNS A/MX → user add → start Postfix/Dovecot → status → SMTP/POP3 test
```

Luôn giữ Dry run bật trên giao diện trong lượt đầu và kiểm tra đúng module ở bảng bên phải trước khi nhấn **Chạy tool**.
