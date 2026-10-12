# Cài đặt và kiểm thử NetAdmin Cockpit UI

## 1. Yêu cầu

- CentOS Stream, AlmaLinux hoặc Rocky Linux dùng `dnf`/`yum`.
- Tài khoản thuộc nhóm `wheel` hoặc được phép nâng quyền quản trị.
- Thư mục dự án đầy đủ, gồm `bin/`, `src/` và `site/dist/`.

## 2. Cài giao diện

Tại thư mục gốc của dự án:

```bash
sudo ./bin/netadmin ui install
```

Lệnh này cài Cockpit nếu cần, chép UI vào `/usr/local/share/cockpit/netadmin`, cài CLI runtime dùng chung vào `/opt/netadmin`, tạo `/usr/local/bin/netadmin`, bật `cockpit.socket` và mở service Cockpit trong firewalld. Runtime nằm ngoài thư mục home nên nhiều tài khoản Linux có thể sử dụng.

Kiểm tra:

```bash
sudo ./bin/netadmin ui status
```

Kết quả mong đợi:

```text
Cockpit socket         active
Cockpit package        installed
NetAdmin CLI           /usr/local/bin/netadmin
Package registry       detected
```

## 3. Mở giao diện

```bash
hostname -I
```

Từ trình duyệt trên máy khác, mở `https://<IP-CENTOS>:9090`, đăng nhập bằng tài khoản Linux và chọn **NetAdmin Tools**.

## 4. Kiểm thử an toàn trước

Giữ **Dry run** bật rồi chạy lần lượt:

1. `Doctor > Kiểm tra môi trường`.
2. `DNS > Liệt kê kết nối mạng`.
3. `DNS > DNS config: check`.
4. `Samba > Samba config: check`.
5. `Storage > Liệt kê ổ đĩa`.

Output phải xuất hiện trực tiếp trong cửa sổ **Kết quả thực thi**. Với Dry run, thao tác thay đổi hệ thống chỉ in command dưới dạng `[DRY-RUN]`.

## 5. Kiểm thử thao tác thật

Tắt **Dry run** sau khi command preview đã đúng. Cockpit có thể yêu cầu mật khẩu để cấp quyền quản trị.

Các thao tác sau có xác nhận bổ sung:

- Tạo partition: nhập lại chính xác device.
- Format filesystem: nhập lại chính xác partition.
- Tạo LVM Physical Volume: nhập lại chính xác partition.
- Mở rộng Logical Volume: xác nhận trước khi thực thi.
- Samba user/client: mật khẩu được gửi qua PTY, không xuất hiện trong command preview hoặc lịch sử.

## 6. Cập nhật và gỡ

Sau khi cập nhật source:

```bash
sudo ./bin/netadmin ui update
```

Tải lại trang bằng `Ctrl + Shift + R` hoặc `Cmd + Shift + R`.

Gỡ UI:

```bash
sudo ./bin/netadmin ui uninstall
```

Lệnh gỡ không xóa cấu hình DNS, DHCP, Samba, Storage hoặc backup.

## 7. Xử lý lỗi

### Không thấy NetAdmin Tools

```bash
cockpit-bridge --packages | grep -A5 netadmin
sudo ./bin/netadmin ui update
sudo systemctl restart cockpit.socket
```

Đăng xuất Cockpit, đăng nhập lại rồi tải lại trang.

### Access denied

```bash
sudo -v
groups
```

Tài khoản quản trị thông thường cần thuộc nhóm `wheel`.

### Không truy cập được cổng 9090

```bash
sudo systemctl status cockpit.socket
sudo firewall-cmd --list-services
sudo ss -lntp | grep 9090
```

### Thay đổi IP làm mất kết nối

Nếu thay IP của card đang dùng cho Cockpit, hãy truy cập lại `https://<IP-MỚI>:9090`.
