# Quick start: setup và chạy NetAdmin UI

Tài liệu này dành cho lần chạy đầu tiên trên CentOS, AlmaLinux hoặc Rocky Linux. Giao diện NetAdmin chạy như một package của Cockpit và gọi trực tiếp các Bash tools qua `/usr/local/bin/netadmin`; không cần khởi động backend riêng.

## 1. Chuẩn bị source

Vào thư mục dự án:

```bash
cd ~/centos-auto-config-tool
```

Kiểm tra các thành phần bắt buộc:

```bash
ls bin/netadmin
ls src/features/ui/module.sh
ls site/dist/index.html site/dist/manifest.json
```

Nếu cả ba lệnh đều hiển thị file, source đã đủ để cài giao diện.

## 2. Cài NetAdmin UI vào Cockpit

```bash
chmod +x bin/netadmin
sudo ./bin/netadmin ui install
```

Lệnh này sẽ:

- Cài Cockpit nếu cần.
- Cài NetAdmin UI vào `/usr/local/share/cockpit/netadmin`.
- Cài Bash runtime vào `/opt/netadmin`.
- Tạo command `/usr/local/bin/netadmin`.
- Bật `cockpit.socket`.
- Mở service Cockpit trong firewalld.

## 3. Kiểm tra trạng thái

```bash
sudo ./bin/netadmin ui status
sudo systemctl status cockpit.socket --no-pager
```

Kết quả NetAdmin mong đợi:

```text
Cockpit socket         active
Cockpit package        installed
NetAdmin CLI           /usr/local/bin/netadmin
Package registry       detected
```

Nếu socket chưa chạy:

```bash
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --add-service=cockpit --permanent
sudo firewall-cmd --reload
```

Kiểm tra cổng:

```bash
sudo ss -lntp | grep 9090
```

## 4. Mở đúng địa chỉ giao diện

Nếu mở Firefox ngay trong máy CentOS:

```text
https://127.0.0.1:9090
```

Nếu mở trình duyệt từ máy Mac hoặc máy khác, lấy IP của CentOS:

```bash
hostname -I
```

Ví dụ IP là `192.168.65.129`, mở:

```text
https://192.168.65.129:9090
```

Chấp nhận cảnh báo chứng chỉ tự ký nếu trình duyệt hiển thị cảnh báo, sau đó đăng nhập bằng username và password Linux.

> URL chạy tool thật phải dùng cổng `9090`. URL như `http://127.0.0.1:8000/site/dist/` chỉ là preview tĩnh và sẽ báo không có Cockpit runtime.

## 5. Mở NetAdmin Tools

Sau khi đăng nhập Cockpit:

1. Chọn **NetAdmin Tools** ở menu bên trái.
2. Kiểm tra góc dưới giao diện có dòng **Cockpit đã kết nối**.
3. Chọn module như Doctor, DNS, DHCP, Samba hoặc Storage.
4. Chọn chính xác tool trong danh sách giữa màn hình.

Nếu giao diện hiển thị **Demo mode** hoặc **Không có Cockpit runtime**, bạn đang mở bản preview thay vì URL Cockpit cổng `9090`.

## 6. Cấp quyền quản trị

Nếu thanh trên cùng hiển thị ổ khóa vàng và dòng **Limited access**:

1. Nhấn **Limited access**.
2. Chọn bật quyền quản trị hoặc **Administrative access**.
3. Nhập lại mật khẩu tài khoản Linux.

Tài khoản nên thuộc nhóm `wheel`. Kiểm tra bằng:

```bash
groups
sudo -v
```

Nếu chưa thuộc nhóm `wheel`:

```bash
sudo usermod -aG wheel TEN_USER
```

Thay `TEN_USER` bằng username thật, rồi đăng xuất và đăng nhập lại.

## 7. Chạy thử an toàn

Giữ **Dry run** bật trong lần chạy đầu tiên. Thử lần lượt:

1. **Doctor** → Kiểm tra môi trường.
2. **DNS** → Liệt kê kết nối mạng.
3. **Storage** → Liệt kê ổ đĩa.

Nhấn **Chạy tool** và kiểm tra output trong hộp **Kết quả thực thi**.

Khi Dry run bật, command preview có dạng:

```text
NETADMIN_DRY_RUN=1 /usr/local/bin/netadmin dns install
```

Các tác vụ thay đổi hệ thống sẽ chỉ được mô phỏng.

## 8. Thực thi thật

Chỉ tắt **Dry run** khi:

- Đã chọn đúng module và đúng tool.
- Đã kiểm tra các tham số trong bảng bên phải.
- Đã bật Administrative access.
- Đã hiểu thay đổi mà tool sẽ thực hiện.

Sau khi tắt Dry run, nhấn **Chạy tool**. Các tool thay đổi hệ thống sẽ yêu cầu quyền quản trị qua Cockpit.

Đặc biệt cẩn thận với:

- Đặt IP tĩnh cho card mạng đang dùng để truy cập Cockpit.
- Tạo partition.
- Format filesystem.
- Tạo hoặc mở rộng LVM.

## 9. Cập nhật giao diện

Sau khi pull source mới:

```bash
cd ~/centos-auto-config-tool
sudo ./bin/netadmin ui update
sudo systemctl restart cockpit.socket
```

Sau đó tải lại trình duyệt bằng `Ctrl + Shift + R`.

## 10. Lỗi thường gặp

### Không thấy NetAdmin Tools trong menu

```bash
cockpit-bridge --packages | grep -A8 netadmin
sudo ./bin/netadmin ui update
sudo systemctl restart cockpit.socket
```

Đăng xuất Cockpit, đăng nhập lại và hard refresh trình duyệt.

### Hiển thị “Không có Cockpit runtime”

Đóng trang cổng `8000` và mở:

```text
https://127.0.0.1:9090
```

hoặc:

```text
https://IP-CUA-CENTOS:9090
```

### Không thể chạy tool vì thiếu quyền

Nhấn **Limited access** và bật Administrative access. Sau đó kiểm tra:

```bash
sudo -v
groups
```

### Không tìm thấy `/usr/local/bin/netadmin`

```bash
sudo ./bin/netadmin ui install
ls -l /usr/local/bin/netadmin
ls -l /opt/netadmin/bin/netadmin
```

### Không truy cập được cổng 9090

```bash
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --add-service=cockpit --permanent
sudo firewall-cmd --reload
sudo ss -lntp | grep 9090
```

Nếu truy cập từ máy Mac, kiểm tra card VMware NAT/Shared with Mac đang bật và dùng đúng IP của CentOS.

## 11. Checklist hoàn tất

- [ ] `ui install` chạy thành công.
- [ ] `cockpit.socket` ở trạng thái `active`.
- [ ] Trình duyệt đang mở cổng `9090`, không phải `8000`.
- [ ] Đăng nhập được bằng tài khoản Linux.
- [ ] Menu **NetAdmin Tools** xuất hiện.
- [ ] Giao diện hiển thị **Cockpit đã kết nối**.
- [ ] Đã bật Administrative access khi cần.
- [ ] Doctor chạy thành công với Dry run.
- [ ] Output command xuất hiện trong hộp kết quả.

Để đọc hướng dẫn chi tiết hơn, xem [Setup và chạy giao diện NetAdmin trên CentOS](SETUP-VA-CHAY-GIAO-DIEN.md).

