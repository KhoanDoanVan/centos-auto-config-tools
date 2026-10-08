# Autoscript DHCP

Phần này tóm tắt tools và thứ tự thực hiện dựa trên `dhcp_manager.sh` và `lib_dhcp_core.sh`.

## 1. Tools và gói phụ thuộc

### Môi trường

- Linux họ Red Hat/CentOS, ưu tiên CentOS 7.
- Bash 4.2 trở lên.
- Quyền root hoặc `sudo`.

### Lệnh và package được script sử dụng

- `yum`: tự cài các package còn thiếu.
- `rpm`: kiểm tra package `dhcp` đã được cài chưa.
- `systemctl`: kiểm tra, tắt và vô hiệu hóa `firewalld`; dừng, khởi động, khởi động lại và xem trạng thái `dhcpd`.
- `ipcalc`: tính Network và Broadcast; trên CentOS 7 script cài package `initscripts` nếu chưa có lệnh này.
- `dhcpd`: dịch vụ DHCP và kiểm tra cấu hình (`dhcpd -t`).
- `grep`, `awk`, `sed`, `rm`: tìm kiếm, đọc/sửa cấu hình DHCP/lease và xóa lease của host.
- `cut`, `tr`, `cat`: trích xuất thông tin, chuẩn hóa MAC và đọc/ghi file.

Script cũng dùng các lệnh Bash tích hợp như `source`, `read`, `echo`, `printf` và `command -v`.

### Package chính

- `dhcp`: cung cấp dịch vụ `dhcpd` và cấu hình tại `/etc/dhcp/dhcpd.conf`.
- `initscripts`: được cài bổ sung nếu thiếu `ipcalc`.

## 2. Thứ tự thực hiện

### Bước 1: Đặt các file script cùng thư mục

Đặt `dhcp_manager.sh` và `lib_dhcp_core.sh` cạnh nhau. Script chính tự nạp thư viện bằng đường dẫn tính từ vị trí file chính, nên có thể gọi từ thư mục làm việc khác.

### Bước 2: Cấp quyền thực thi cho script chính

```bash
chmod +x dhcp_manager.sh
```

`lib_dhcp_core.sh` chỉ được nạp bằng `source`, nên cần quyền đọc nhưng không cần quyền thực thi.

### Bước 3: Chạy bằng quyền root

```bash
sudo ./dhcp_manager.sh
```

Khi khởi chạy, script nạp thư viện, kiểm tra quyền root và dừng nếu không đủ quyền.

### Bước 4: Script tự chuẩn bị dependency

Hàm `check_and_install_dependencies` thực hiện:

1. Nếu `firewalld` đang active, dừng và vô hiệu hóa dịch vụ.
2. Nếu `rpm` cho thấy package `dhcp` chưa được cài, chạy `yum install dhcp -y`.
3. Nếu chưa tìm thấy `ipcalc`, chạy `yum install initscripts -y`.

### Bước 5: Thao tác trong menu

Menu cho phép tạo, cập nhật và xóa Scope; tạo và xóa Host/IP tĩnh; xem cấu hình; và quản lý dịch vụ DHCP.

Trong mục **[7] Quản lý dịch vụ**, có thể:

1. Kiểm tra cấu hình bằng `dhcpd -t -cf /etc/dhcp/dhcpd.conf`.
2. Khởi động lại dịch vụ bằng `systemctl restart dhcpd`.
3. Xem trạng thái bằng `systemctl status dhcpd -l`.

---

# Hướng dẫn chuẩn bị và chạy Autoscript DNS BIND

Phần này tóm tắt tools và thứ tự thực hiện dựa trên `code.sh` và `README.md` của Autoscript DNS.

## 1. Tools và gói phụ thuộc

### Hệ điều hành và quyền chạy

- Linux họ Red Hat: CentOS, RHEL, Fedora hoặc Rocky Linux.
- Bash để chạy script.
- Quyền root, chạy trực tiếp bằng root hoặc qua `sudo`.

### Gói và lệnh hệ thống

- `bind`: dịch vụ DNS `named` và lệnh `named-checkconf`.
- `bind-utils`: tiện ích truy vấn DNS, trong đó script sử dụng `nslookup`.
- `NetworkManager` và `nmcli`: dùng cho chức năng cấu hình IP tĩnh/động.
- `yum`: cài đặt package theo hướng dẫn trong README.
- `systemctl`: khởi động và khởi động lại dịch vụ `named`.

### Các tiện ích được script sử dụng

- `grep`, `sed`, `cat`: tìm kiếm và chỉnh sửa cấu hình, tạo file zone.
- `chown`, `chmod`: đặt chủ sở hữu và quyền truy cập file/thư mục.
- `mkdir`, `rm`: tạo thư mục slave và xóa file zone slave cũ.
- `head`: lấy tên kết nối mạng đang hoạt động.
- `named-checkconf`, `nslookup`: kiểm tra cấu hình BIND và truy vấn DNS.

## 2. Thứ tự thực hiện

### Bước 1: Cài đặt BIND và tiện ích DNS

Theo hướng dẫn trong README:

```bash
sudo yum install bind bind-utils -y
sudo systemctl enable --now named
```

### Bước 2: Chuẩn bị script và cấp quyền thực thi

Đặt file script (`code.sh`, hoặc tên đã đổi như `setup_dns.sh`) trên máy chủ, sau đó cấp quyền:

```bash
chmod +x code.sh
```

### Bước 3: Chạy script bằng quyền root

```bash
sudo ./code.sh
```

Script kiểm tra quyền root khi bắt đầu; nếu không có quyền root thì thoát.

### Bước 4: Thực hiện chức năng trong menu

1. **Cấu hình IP:** dùng `nmcli` để đặt IP tĩnh hoặc chuyển sang nhận IP động.
2. **Cấu hình domain:** thêm khai báo zone vào `/etc/named.conf`, tạo file zone trong `/var/named/` và đặt quyền file.
3. **Cấu hình Backup DNS:** cấu hình `allow-transfer` trên Primary hoặc khai báo zone `slave`, tạo thư mục `/var/named/slaves` trên Backup.
4. **Cấu hình Forward DNS:** cập nhật địa chỉ `forwarders` trong cấu hình BIND.
5. **Kiểm tra phân giải:** dùng `nslookup`.
6. **Khởi động lại dịch vụ DNS:** menu chạy `named-checkconf`, sau đó dùng `systemctl restart named` nếu kiểm tra cấu hình thành công.

---

# Autoscript quản lý ổ đĩa CentOS

Phần này dựa trên `Automated-CentOS-Disk-Management-Script.sh` và README tương ứng.

## 1. Tools và gói phụ thuộc

### Môi trường

- CentOS 7, Bash và quyền `root`/`sudo`.
- `yum` để cài các package khi cấu hình quota hoặc Samba.

### Phân vùng, filesystem và mount

- `lsblk`, `fdisk`, `partprobe`: liệt kê thiết bị và tạo phân vùng.
- `mkfs`: định dạng ext4, XFS hoặc ext3.
- `mount`, `mkdir`, `grep`: mount ổ đĩa, tạo mount point và cập nhật `/etc/fstab`.
- `parted`: thao tác vùng trống và tạo partition cho LVM.
- `udevadm`, `sleep`: chờ hệ thống nhận partition mới.

### LVM

- Package **LVM2**, cung cấp `pvcreate`, `vgcreate`, `lvcreate`, `vgs`, `lvs`, `vgextend`, `lvextend`.
- `blkid`, `findmnt`, `resize2fs`, `xfs_growfs`: xác định filesystem và mở rộng filesystem sau khi tăng LV.

### Quota

- Package `quota`, script tự cài bằng `yum` khi chọn chức năng quota.
- Các lệnh `quotaoff`, `quotacheck`, `quotaon`, `setquota`, `repquota`.
- `df`, `mountpoint`, `id`: kiểm tra mount point, filesystem và tài khoản.

### Samba và SELinux

- Các package `samba`, `samba-client`, `samba-common`; script tự cài khi cấu hình share.
- `systemctl`: bật và khởi động lại `smb`/`nmb`.
- `find`, `column`, `chown`, `chmod`, `chcon`, `setsebool`: tìm thư mục, thiết lập quyền và cấu hình SELinux.
- Các tiện ích xử lý văn bản/shell được dùng gồm `awk`, `sed`, `grep`, `cut`, `tr`, `cat`, `tail`, `echo`, `read`.

Các công cụ ngoài package `quota` và Samba cần có sẵn khi dùng chức năng tương ứng. README liệt kê `parted`, LVM2, tiện ích filesystem, quota, Samba và SELinux là các phụ thuộc cần thiết; script không tự cài toàn bộ chúng.

## 2. Thứ tự thực hiện

### Bước 1: Chuẩn bị script và quyền chạy

Đặt `Automated-CentOS-Disk-Management-Script.sh` trên máy CentOS 7:

```bash
chmod +x Automated-CentOS-Disk-Management-Script.sh
```

### Bước 2: Chạy script với quyền root

```bash
sudo ./Automated-CentOS-Disk-Management-Script.sh
```

Script kiểm tra quyền root ngay khi bắt đầu.

### Bước 3: Chọn chức năng trong menu

1. **Phân vùng và mount:** chọn ổ đĩa, xác nhận thao tác, chọn filesystem; script dùng `fdisk`, `partprobe`, `mkfs`, `mkdir`, `mount` và ghi mount vào `/etc/fstab`.
2. **Quản lý LVM:** chọn tạo LVM mới hoặc mở rộng LVM hiện có; script dùng `parted` và các lệnh LVM, sau đó định dạng/mount LV hoặc resize filesystem.
3. **Cấu hình quota:** chọn mount point đã mount và user hệ thống có sẵn; script cài `quota`, cấu hình mount options trong `/etc/fstab`, bật quota và áp dụng giới hạn blocks/inodes.
4. **Cấu hình Samba share:** chọn mount point đã mount, thư mục và user đại diện; script cài các package Samba, cấu hình quyền/SELinux, cập nhật `smb.conf`, rồi enable/restart `smb` và `nmb`.

> Các chức năng phân vùng/LVM/format có thể thay đổi cấu trúc đĩa và làm mất dữ liệu. Xác nhận đúng thiết bị và sao lưu trước khi thao tác.

---

# Autoscript quản lý Samba CentOS 7

Phần này dựa trên `samba_manager.sh` và README tương ứng.

## 1. Tools và gói phụ thuộc

### Môi trường và lệnh hệ thống

- CentOS 7, Bash và quyền `root`/`sudo`.
- `yum`: cài Samba và CIFS utilities tại chức năng 1.
- `systemctl`: enable/start/restart dịch vụ `smb` và `nmb`.
- `firewall-cmd`: mở dịch vụ Samba trong `firewalld` nếu firewall đang active.
- `testparm`: kiểm tra cú pháp `smb.conf`.
- `smbstatus`, `pdbedit`, `smbpasswd`: trạng thái kết nối và quản lý tài khoản Samba.

### Package và tiện ích chia sẻ

- `samba`, `samba-common`, `samba-client`: dịch vụ và công cụ quản lý Samba.
- `cifs-utils`: cung cấp `mount.cifs` để kết nối tới share Windows.
- `mount.cifs`, `umount`, `du`, `cp`, `mkdir`: mount CIFS, xem dung lượng, sao chép dữ liệu và dọn mount.
- `groupadd`, `useradd`, `userdel`, `id`: quản lý user/group Linux; `nologin` được dùng cho user chia sẻ.
- `chown`, `chmod`, `chcon`, `setsebool`: quyền filesystem và cấu hình SELinux.
- `grep`, `awk`, `sed`, `cut`, `tr`, `cat`, `cp`, `mv`, `rm`: thao tác cấu hình, backup, rollback và dữ liệu.
- `date`, `ls`, `tail`, `head`, `xargs`, `clear`: backup có timestamp, sắp xếp/dọn backup và giao diện menu.

Chức năng 1 tự cài các package Samba/CIFS, bật dịch vụ và mở firewall nếu `firewalld` đang chạy. Chức năng 8 cần máy Windows có share SMB truy cập được qua mạng.

## 2. Thứ tự thực hiện

### Bước 1: Đặt script và cấp quyền

```bash
chmod +x samba_manager.sh
```

### Bước 2: Chạy bằng quyền root

```bash
sudo ./samba_manager.sh
```

Script kiểm tra quyền root khi khởi chạy.

### Bước 3: Cài và kích hoạt Samba

Chọn **[1] Kiểm tra môi trường & Cài đặt Samba**. Script cài `samba`, `samba-common`, `samba-client`, `cifs-utils`; enable/start `smb` và `nmb`; nếu `firewalld` đang active, thêm dịch vụ Samba và reload firewall.

### Bước 4: Cấu hình và quản lý share

Chọn menu theo nhu cầu:

1. **[2]** Tạo share anonymous.
2. **[3]** Tạo group, Linux user, mật khẩu Samba và share bảo vệ theo group.
3. **[4]**, **[5]**, **[6]** Xem share/user, giám sát client hoặc kiểm tra cấu hình bằng `testparm -s`.
4. **[7]** Sao lưu `smb.conf` rồi restart `smb`/`nmb` để áp dụng thay đổi.
5. **[8]** Mount share từ Windows bằng CIFS, chọn file/thư mục để sao chép về Linux, sau đó unmount.
6. **[9]**, **[10]**, **[11]** Xóa share, quản lý user/quyền đọc-ghi hoặc rollback `smb.conf`; sau thay đổi cấu hình cần dùng **[7]** để áp dụng.

Máy Windows client cần cùng mạng hoặc có kết nối tới server; firewall/mạng phải cho phép SMB. File hướng dẫn ghi chú chức năng có thể thiết lập quyền truy cập rộng, nên chỉ sử dụng trong môi trường phù hợp.
