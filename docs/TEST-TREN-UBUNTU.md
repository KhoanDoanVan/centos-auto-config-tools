# Kiểm tra dự án trên Ubuntu

Ubuntu dùng được để kiểm tra mã nguồn, đối chiếu 123 tool và mở giao diện Cockpit ở chế độ xem lệnh. Ubuntu **không phải** môi trường nghiệm thu các thao tác cấu hình thật vì dự án dùng package, service và đường dẫn của họ RHEL.

## 1. Cài dependency audit

```bash
sudo apt update
sudo apt install -y bash nodejs ripgrep shellcheck unzip
```

Trong thư mục dự án:

```bash
chmod +x bin/netadmin scripts/*.sh scripts/*.mjs
./scripts/audit-static.sh
```

Kết quả mong đợi:

```text
TOTAL   123   OK
Static audit: 0 failure(s).
```

Audit này kiểm tra:

- Cú pháp toàn bộ file Bash và JavaScript.
- Dispatch của 9 module CLI, gồm cả module `ui`.
- 123 thao tác Cockpit có route CLI tương ứng.
- Placeholder trên command khớp field của form.
- UI gọi đúng `/usr/local/bin/netadmin` mà installer tạo.
- Không có helper feature bỏ qua Dry run khi cấu hình SELinux.

## 2. Mở giao diện trên Ubuntu để kiểm tra UX

Cài Cockpit trước, vì NetAdmin không tự dùng `apt` để cài package RHEL:

```bash
sudo apt install -y cockpit
sudo systemctl enable --now cockpit.socket
sudo ./bin/netadmin ui install
```

Mở:

```text
https://<IP-UBUNTU>:9090
```

Trên Ubuntu chỉ kiểm tra danh mục tool, form, command preview, Dry run, history và output dialog. Không dùng kết quả này để xác nhận BIND, DHCP, Apache, Samba, FTP hoặc Mail đã chạy đúng theo CentOS.

## 3. Kiểm tra runtime read-only

```bash
./scripts/audit-runtime.sh
```

Script sẽ trả trạng thái không hỗ trợ trên Ubuntu. Đây là kết quả đúng, giúp ngăn chạy nhầm cấu hình CentOS trên hệ dùng `apt`, `apache2`, `bind9` và đường dẫn khác.

## 4. Môi trường nghiệm thu đầy đủ

Dùng Rocky Linux 9 hoặc AlmaLinux 9. Trước khi chạy tool thay đổi hệ thống:

```bash
./scripts/audit-static.sh
./scripts/audit-runtime.sh
sudo ./bin/netadmin doctor
```

Sau đó kiểm thử từng module theo `docs/handbook/07-RUNBOOK-KIEM-THU-TREN-CENTOS.md` và dùng client thứ hai để kiểm tra DHCP, DNS, SMB, Web, FTP và Mail.

Không dùng CentOS Stream 10 để nghiệm thu module DHCP hiện tại. RHEL/CentOS 10 đã thay ISC DHCP bằng Kea, trong khi module đang quản lý `dhcpd.conf`.
