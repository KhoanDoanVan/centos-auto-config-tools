# Chương 5 — Samba/SMB từ cơ bản đến từng command

## 1. Samba là gì?

SMB là protocol chia sẻ file/printer phổ biến trong Windows. Samba là implementation SMB cho Linux, cho phép:

- Linux chia sẻ thư mục cho Windows/Linux/macOS.
- Linux truy cập Windows share.
- Quản lý user và quyền truy cập mạng.

Một share có địa chỉ UNC:

```text
\\server\share       (cách viết Windows)
//server/share         (cách viết Linux/toolkit)
```

Ví dụ `//192.168.10.20/lessons`.

## 2. Ba lớp quyền cần hiểu

Khi client bị `Access denied`, phải kiểm tra cả ba lớp:

1. **Samba authentication/authorization**: user có đăng nhập và nằm trong `valid users` không?
2. **Linux filesystem permission**: owner/group/mode có cho process truy cập không?
3. **SELinux**: path có context phù hợp cho Samba không?

Mở một lớp không tự động mở hai lớp còn lại. `chmod 777` không giải quyết được user Samba chưa tồn tại hay SELinux context sai.

## 3. Linux user và Samba user

Samba user dựa trên một Linux user nhưng giữ password Samba riêng:

```text
Linux account: /etc/passwd, group, quyền file
Samba account: passdb, password dùng qua SMB
```

Vì vậy quy trình tạo là: có Linux user → thêm Samba password bằng `smbpasswd -a`.

Toolkit tạo user với `/sbin/nologin`, không có home. User dùng chia sẻ file nhưng không đăng nhập shell thông thường.

## 4. Public share và protected share

- **Public/guest share**: client không cần tài khoản; thuận tiện nhưng ít an toàn.
- **Group share**: chỉ user thuộc Linux/Samba group truy cập.
- **Read-only**: client đọc/tải về nhưng không tạo/sửa/xóa.
- **Read-write**: client có thể thay đổi nếu cả Samba, filesystem và SELinux cho phép.

## 5. Tool `samba install`

```bash
sudo ./bin/netadmin samba install
```

Tool cài:

- `samba`: server.
- `samba-common`: file/thành phần chung.
- `samba-common-tools`: `testparm`, account tools.
- `samba-client`: `smbclient`.
- `cifs-utils`: `mount.cifs`.

Nếu chưa có `smb.conf`, tool tạo global config cơ bản:

```text
[global]
  workgroup = WORKGROUP
  security = user
  map to guest = Bad User
  logging = file
  log file = /var/log/samba/%m.log
```

Sau đó chạy `testparm`, enable `smb`/`nmb` và mở firewall service `samba`. Tool chưa start server trước khi có share.

## 6. Tool `share add-public`

```bash
sudo ./bin/netadmin samba share add-public \
  <name> <path> [read-only|read-write]
```

Ví dụ:

```bash
sudo ./bin/netadmin samba share add-public \
  public /srv/samba/public read-only
```

Tool thực hiện:

1. Tạo path.
2. Owner `nobody:nobody`.
3. Mode `0755` nếu read-only, `0777` nếu read-write.
4. Gắn SELinux context `samba_share_t`.
5. Backup `smb.conf`.
6. Thêm share block.
7. Chạy `testparm` và rollback khi lỗi.

Block:

```text
[public]
  path = /srv/samba/public
  guest ok = yes
  guest only = yes
  read only = yes
  browseable = yes
  create mask = 0660
  directory mask = 0770
```

Public `read-write` dùng mode `0777`, nghĩa là mọi local user cũng có thể ghi. Chỉ dùng trong lab/mạng tin cậy.

## 7. Tool `share add-group`

```bash
sudo ./bin/netadmin samba share add-group \
  <name> <path> <group> [read-only|read-write]
```

Ví dụ:

```bash
sudo ./bin/netadmin samba share add-group \
  lessons /data/lessons labusers read-write
```

Group phải tồn tại trước. Bạn có thể tạo thông qua `samba user add`, hoặc `groupadd` thủ công.

Tool đặt:

- Owner `root:labusers`.
- Mode `2770` read-write hoặc `2750` read-only.
- `valid users = @labusers`.
- `force group = labusers`.

`@labusers` nghĩa là group, không phải user tên `@labusers`. Setgid/force group giúp file mới dùng group chung, giảm lỗi người A tạo file mà người B trong cùng nhóm không sửa được.

## 8. Tool share list/remove

```bash
./bin/netadmin samba share list
sudo ./bin/netadmin samba share remove lessons
```

`list` chỉ hiện share có marker NetAdmin. Các section viết tay vẫn hoạt động nhưng không hiện.

`remove` xóa section trong config, không xóa `/data/lessons`, file, owner hoặc SELinux context. Đây là hành vi bảo vệ dữ liệu.

## 9. Tool `samba user add`

```bash
sudo ./bin/netadmin samba user add <username> <group>
```

Ví dụ:

```bash
sudo ./bin/netadmin samba user add student labusers
```

Luồng:

1. Nếu `labusers` chưa tồn tại, chạy `groupadd labusers`.
2. Nếu `student` chưa tồn tại, chạy `useradd -M -s /sbin/nologin -G labusers student`.
3. Chạy `usermod -aG labusers student` để chắc chắn membership.
4. Chạy `smbpasswd -a student` và hỏi password hai lần.

Password không hiển thị khi nhập. Đây là password SMB, có thể khác password Linux.

Kiểm tra group:

```bash
id student
getent group labusers
```

## 10. Tool user list/remove

```bash
sudo ./bin/netadmin samba user list
sudo ./bin/netadmin samba user remove student
```

`list` dùng `pdbedit -L -v`, có thể hiện username, SID, flags và thông tin passdb.

`remove` chỉ xóa Samba account bằng `smbpasswd -x`. Linux user, group membership, file và owner không bị xóa. Điều này tránh mất dữ liệu hoặc biến file thành owner ID khó hiểu.

## 11. Tool `permissions grant`

```bash
sudo ./bin/netadmin samba permissions grant \
  <share> <username|@group> <read|write>
```

Ví dụ:

```bash
sudo ./bin/netadmin samba permissions grant lessons @teachers write
```

Tool thêm `write list = @teachers` hoặc `read list = ...` vào section. Đây là quyền bổ sung bên trong Samba; principal vẫn cần vượt qua `valid users` và filesystem permission.

Implementation hiện tại thay thế read/write list trước đó mỗi lần gọi. Nếu cần nhiều người, tạo group và cấp cho `@group` thay vì gọi nhiều lần.

Sau thay đổi gọi `config apply`.

## 12. Tool config show/check

```bash
./bin/netadmin samba config show
sudo ./bin/netadmin samba config check
```

- `show`: in file thô.
- `check`: chạy `testparm -s`, vừa kiểm tra vừa in cấu hình hiệu lực đã chuẩn hóa.

`testparm` thành công chỉ chứng minh syntax/option hợp lệ. Nó không chứng minh path tồn tại, user nhập đúng password, firewall mở hoặc permission runtime đúng.

## 13. Tool `config apply`

```bash
sudo ./bin/netadmin samba config apply
```

Tool validate trước, sau đó restart `smb` và `nmb`. Tách bước tạo share và apply cho phép bạn thêm nhiều share rồi restart một lần.

Các kết nối/file đang mở có thể bị ảnh hưởng khi restart. Kiểm tra `sessions` trước trong hệ thống đang sử dụng thật.

## 14. Tool `config rollback`

```bash
sudo ./bin/netadmin samba config rollback
```

Tool chọn backup `smb.conf` gần nhất, hỏi xác nhận, copy trở lại và validate. Rollback config không tự hoàn nguyên chmod/chown/SELinux context đã đặt trên thư mục.

## 15. Tool service và status

```bash
sudo ./bin/netadmin samba service enable-now
sudo ./bin/netadmin samba service restart
sudo ./bin/netadmin samba service stop
sudo ./bin/netadmin samba service status
sudo ./bin/netadmin samba status
```

Với action ngoài `status`, toolkit áp dụng cho cả `smb` và `nmb`. `status` chỉ xem `smb`.

- `smb`: dịch vụ file sharing chính.
- `nmb`: NetBIOS name/browse cũ; truy cập trực tiếp IP hoặc DNS hiện đại có thể không cần nó, nhưng CentOS 7 lab thường vẫn dùng.

## 16. Tool `sessions`

```bash
sudo ./bin/netadmin samba sessions
```

`smbstatus` cho biết:

- PID process phục vụ.
- Username/group.
- Client address.
- Protocol version.
- Share đang dùng.
- File lock.

Hữu ích trước restart hoặc khi user báo file bị khóa.

## 17. Tool `client list`

Guest:

```bash
./bin/netadmin samba client list //192.168.10.20/public
```

Có tài khoản:

```bash
./bin/netadmin samba client list //192.168.10.20/lessons student
```

Tool dùng `smbclient`. Với username, chương trình hỏi password. Đây là cách kiểm tra SMB ở tầng ứng dụng tốt hơn `ping`: ping thành công không chứng minh SMB hoạt động.

## 18. Tool `client copy`

```bash
sudo ./bin/netadmin samba client copy \
  //<server>/<share> <remote-item> <destination> [username]
```

Ví dụ:

```bash
sudo ./bin/netadmin samba client copy \
  //192.168.10.20/lessons week01 /data/import student
```

Luồng:

1. Tạo mountpoint tạm.
2. Nếu có username, tạo credential file mode `600` và hỏi password không echo.
3. `mount.cifs` share.
4. Kiểm tra `remote-item` tồn tại và không chứa `..`.
5. `cp -a` vào destination.
6. Unmount.
7. Xóa mountpoint/credential tạm, kể cả khi process thoát lỗi.

`remote-item` là path tương đối bên trong share, không bắt đầu bằng `/`.

## 19. Kiểm tra từ Windows

Trong File Explorer nhập:

```text
\\192.168.10.20\lessons
```

Hoặc PowerShell:

```powershell
Test-NetConnection 192.168.10.20 -Port 445
net use Z: \\192.168.10.20\lessons /user:student
```

Windows có thể cache credential cũ. Xóa mapping/credential khi test lại user khác:

```powershell
net use * /delete
```

## 20. Lỗi thường gặp

### `NT_STATUS_LOGON_FAILURE`

Sai password hoặc Samba account chưa được tạo. Kiểm tra `samba user list`, rồi `smbpasswd`.

### `NT_STATUS_ACCESS_DENIED`

Authentication có thể đúng nhưng `valid users`, read/write list, Linux mode/group hoặc SELinux chặn.

```bash
id student
namei -l /data/lessons
ls -ldZ /data/lessons
sudo testparm -s
```

### Kết nối timeout/refused

Kiểm tra `smb` active, TCP 445, firewall và route:

```bash
sudo systemctl status smb -l
sudo firewall-cmd --list-services
ss -lntp | grep ':445'
```

### Guest vẫn hỏi password

Kiểm tra `guest ok`, `guest only`, `map to guest`, client credential cache và policy Windows chặn guest insecure logon.

### Ghi file lỗi dù share read-write

Kiểm tra `read only = no`, directory mode/owner/group, user membership, SELinux và filesystem có mount read-only không.

## 21. Bài lab hoàn chỉnh

```bash
sudo ./bin/netadmin samba install
sudo ./bin/netadmin samba user add student labusers
sudo ./bin/netadmin samba user add teacher labusers
sudo ./bin/netadmin samba share add-group lessons /data/lessons labusers read-write
sudo ./bin/netadmin samba config check
sudo ./bin/netadmin samba config apply
sudo ./bin/netadmin samba service enable
./bin/netadmin samba client list //127.0.0.1/lessons student
sudo ./bin/netadmin samba sessions
```

