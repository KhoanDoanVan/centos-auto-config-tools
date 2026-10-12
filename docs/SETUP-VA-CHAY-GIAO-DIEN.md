# Setup và chạy giao diện NetAdmin trên CentOS

Tài liệu này hướng dẫn từ lúc có source code trên CentOS đến khi mở được giao diện và chạy Bash tool thật. Không cần tự viết hoặc khởi động backend riêng: Cockpit cung cấp web server, đăng nhập Linux và cầu nối để giao diện gọi `/usr/local/bin/netadmin`.

## 1. Kết quả sau khi hoàn tất

Bạn sẽ truy cập giao diện tại:

```text
https://IP-CUA-CENTOS:9090
```

Sau khi đăng nhập, menu **NetAdmin Tools** cho phép chọn tool, nhập tham số và xem output trực tiếp trên giao diện.

> `IP-CUA-CENTOS` là địa chỉ IP thật của máy CentOS, ví dụ `192.168.65.129`. Không nhập nguyên văn chữ `IP-CUA-CENTOS`.

## 2. Điều kiện cần có

- CentOS Stream, AlmaLinux hoặc Rocky Linux có `dnf` hoặc `yum`.
- Tài khoản Linux có quyền `sudo`.
- Máy CentOS có kết nối mạng để cài Cockpit nếu package chưa tồn tại.
- Source dự án có đủ các thư mục `bin/`, `src/`, `config/` và `site/dist/`.

Nếu chạy bằng VMware, nên dùng:

- Card mạng NAT hoặc Shared with Mac để tải package và truy cập Internet.
- Card private/host-only thứ hai nếu bài lab cần mạng nội bộ riêng.

Giao diện có thể chạy chỉ với một card mạng. Card thứ hai không phải điều kiện bắt buộc của Cockpit.

## 3. Vào đúng thư mục dự án

Ví dụ source nằm trong thư mục home:

```bash
cd ~/centos-auto-config-tool
pwd
ls
```

Kết quả của `ls` phải có ít nhất:

```text
bin  config  docs  site  src
```

Kiểm tra file giao diện:

```bash
ls site/dist/index.html site/dist/manifest.json
```

## 4. Cài giao diện bằng một command

Chạy tại thư mục gốc của dự án:

```bash
chmod +x bin/netadmin
sudo ./bin/netadmin ui install
```

Lệnh trên tự động:

1. Cài Cockpit nếu máy chưa có.
2. Chép giao diện vào `/usr/local/share/cockpit/netadmin`.
3. Chép Bash runtime vào `/opt/netadmin`.
4. Tạo command dùng chung `/usr/local/bin/netadmin`.
5. Bật `cockpit.socket` để Cockpit khởi động cùng hệ thống.
6. Mở service `cockpit` trong firewalld.

Thông báo thành công dự kiến:

```text
[OK] Đã cài NetAdmin Cockpit UI.
Mở: https://<IP-CENTOS>:9090 và chọn 'NetAdmin Tools'.
```

## 5. Kiểm tra trạng thái sau khi cài

```bash
sudo ./bin/netadmin ui status
sudo systemctl status cockpit.socket --no-pager
```

Trạng thái đúng thường có:

```text
Cockpit socket         active
Cockpit package        installed
NetAdmin CLI           /usr/local/bin/netadmin
Package registry       detected
```

Kiểm tra trực tiếp command đã cài:

```bash
/usr/local/bin/netadmin version
/usr/local/bin/netadmin help
```

## 6. Lấy địa chỉ IP của CentOS

```bash
hostname -I
ip -4 address
```

Ví dụ máy trả về `192.168.65.129`, địa chỉ giao diện là:

```text
https://192.168.65.129:9090
```

Nên dùng IP của card đang ở trạng thái `UP` và có thể truy cập từ máy mở trình duyệt. Không dùng `127.0.0.1` từ một máy khác.

## 7. Đăng nhập giao diện

1. Mở trình duyệt trên máy Mac hoặc một máy cùng mạng.
2. Truy cập `https://IP-CUA-CENTOS:9090`.
3. Nếu trình duyệt cảnh báo chứng chỉ, chọn tiếp tục truy cập. Cockpit mặc định có thể dùng chứng chỉ tự ký trong môi trường lab.
4. Đăng nhập bằng username và password của tài khoản Linux trên CentOS.
5. Chọn **NetAdmin Tools** trong menu Cockpit.

Nếu tài khoản chưa có quyền quản trị, thêm tài khoản vào nhóm `wheel`:

```bash
sudo usermod -aG wheel TEN_USER
```

Thay `TEN_USER` bằng username thật, sau đó đăng xuất khỏi CentOS/Cockpit và đăng nhập lại.

## 8. Kiểm thử an toàn lần đầu

Giữ công tắc **Dry run** ở trạng thái bật. Chạy lần lượt:

1. **Doctor** → kiểm tra môi trường.
2. **DNS** → liệt kê kết nối mạng.
3. **Storage** → liệt kê ổ đĩa.
4. **Samba** → kiểm tra cấu hình.

Command chuẩn bị chạy và output phải xuất hiện trong vùng **Kết quả thực thi**. Với tác vụ thay đổi hệ thống, Dry run chỉ hiển thị command dự kiến và không áp dụng thay đổi.

Khi đã kiểm tra đúng tham số, tắt **Dry run** để thực thi thật. Cockpit có thể yêu cầu xác nhận quyền quản trị hoặc nhập lại mật khẩu.

> Cẩn thận với các tool thay IP, tạo partition, format filesystem và tạo LVM. Thay IP của chính card đang dùng để mở Cockpit có thể làm phiên web mất kết nối; hãy mở lại bằng IP mới.

## 9. Khởi động, dừng và khởi động lại giao diện

Khởi động Cockpit:

```bash
sudo systemctl start cockpit.socket
```

Dừng Cockpit:

```bash
sudo systemctl stop cockpit.socket
```

Khởi động lại sau khi xử lý lỗi:

```bash
sudo systemctl restart cockpit.socket
```

Bật tự khởi động cùng CentOS:

```bash
sudo systemctl enable cockpit.socket
```

## 10. Cập nhật giao diện khi source thay đổi

Sau khi lấy source mới hoặc sửa UI, đứng tại thư mục dự án và chạy:

```bash
sudo ./bin/netadmin ui update
```

Sau đó tải lại trang bằng `Ctrl + Shift + R` trên Linux/Windows hoặc `Cmd + Shift + R` trên macOS.

`ui update` cài lại cả UI và Bash runtime, vì vậy các tool mới trong `src/` cũng được cập nhật vào `/opt/netadmin`.

## 11. Phân biệt preview tĩnh và giao diện chạy thật

Lệnh sau chỉ dùng để xem bố cục giao diện khi phát triển:

```bash
cd site/dist
python3 -m http.server 8080
```

Trang `http://localhost:8080` không có Cockpit bridge nên sẽ hiện **Demo mode** và không thể chạy command trên CentOS.

Muốn tool thực thi thật, bắt buộc mở giao diện qua Cockpit:

```text
https://IP-CUA-CENTOS:9090
```

## 12. Xử lý lỗi thường gặp

### Không truy cập được cổng 9090

```bash
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --add-service=cockpit --permanent
sudo firewall-cmd --reload
sudo ss -lntp | grep 9090
```

Nếu `ss` cho thấy cổng 9090 đang lắng nghe nhưng máy Mac vẫn không truy cập được, kiểm tra lại IP và chế độ Network Adapter của VMware.

### Không thấy menu NetAdmin Tools

```bash
cockpit-bridge --packages | grep -A8 netadmin
sudo ./bin/netadmin ui update
sudo systemctl restart cockpit.socket
```

Sau đó đăng xuất Cockpit, đăng nhập lại và hard refresh trình duyệt.

### Giao diện báo Demo mode

Bạn đang mở bản preview tĩnh hoặc website demo. Hãy mở đúng URL Cockpit `https://IP-CUA-CENTOS:9090` và đăng nhập vào CentOS.

### Giao diện báo không đủ quyền

```bash
sudo -v
groups
```

Đảm bảo username xuất hiện trong nhóm `wheel`. Nếu vừa thêm nhóm, cần đăng xuất rồi đăng nhập lại.

### Không tìm thấy command netadmin

```bash
ls -l /usr/local/bin/netadmin
ls -l /opt/netadmin/bin/netadmin
sudo ./bin/netadmin ui status
```

Nếu file còn thiếu, cài lại:

```bash
sudo ./bin/netadmin ui install
```

### Đã cập nhật nhưng giao diện vẫn là bản cũ

```bash
sudo ./bin/netadmin ui update
sudo systemctl restart cockpit.socket
```

Sau đó hard refresh hoặc mở một cửa sổ trình duyệt riêng tư.

## 13. Gỡ riêng giao diện

```bash
sudo ./bin/netadmin ui uninstall
```

Lệnh này gỡ package NetAdmin khỏi Cockpit nhưng không xóa cấu hình DHCP, DNS, Storage, Samba hoặc các bản backup đã tạo.

## 14. Checklist hoàn tất

- [ ] `ui install` chạy không báo lỗi.
- [ ] `ui status` hiển thị socket `active` và package `installed`.
- [ ] Trình duyệt mở được `https://IP-CUA-CENTOS:9090`.
- [ ] Đăng nhập được bằng tài khoản Linux.
- [ ] Menu **NetAdmin Tools** xuất hiện.
- [ ] Giao diện không báo **Demo mode**.
- [ ] Chạy **Doctor** với Dry run và nhìn thấy output.
- [ ] Chạy được một tool đọc dữ liệu như **Storage → liệt kê ổ đĩa**.

