# NetAdmin Toolkit

NetAdmin Toolkit là bộ công cụ Bash giúp cài đặt, cấu hình và vận hành các bài thực hành quản trị mạng trên hệ Linux thuộc họ RHEL. Dự án cung cấp một CLI thống nhất và giao diện Cockpit gọi trực tiếp cùng CLI, không cần backend HTTP riêng.

## Phạm vi

- Doctor: kiểm tra môi trường và dependency lõi.
- DNS: NetworkManager, BIND, zone, record, forwarder và transfer.
- DHCP: scope, reservation và lease trên ISC DHCP; CentOS/RHEL 10 chỉ hỗ trợ Dry run vì ISC DHCP đã được thay thế.
- Storage: disk, partition, filesystem, mount, LVM và quota.
- Samba: share, user, permission và SMB client.
- Web: Apache VirtualHost, DNS, log, backup và restore.
- FTP: vsftpd, user, share, TLS và chẩn đoán.
- Mail: Postfix, Dovecot, user, DNS, queue và kiểm tra protocol.

Catalog Cockpit hiện có 123 thao tác được map tới CLI.

## Môi trường hỗ trợ

- Khuyến nghị để chạy đầy đủ: Rocky Linux 9 hoặc AlmaLinux 9.
- CentOS Stream/RHEL 10: các module khác có thể chạy, nhưng backend ISC DHCP không được hỗ trợ.
- Ubuntu/Debian: chỉ dùng để audit mã nguồn hoặc xem UI; runtime cấu hình thật chưa được hỗ trợ.

## Cài đặt nhanh

```bash
git clone https://github.com/KhoanDoanVan/centos-auto-config-tools.git
cd centos-auto-config-tools
chmod +x bin/netadmin scripts/*.sh scripts/*.mjs
sudo ./bin/netadmin ui install
```

Mở Cockpit:

```text
https://<IP-SERVER>:9090/netadmin
```

Kiểm tra CLI:

```bash
./bin/netadmin version
sudo ./bin/netadmin doctor
./bin/netadmin help
```

## Kiểm tra source

```bash
./scripts/audit-static.sh
sudo ./scripts/audit-runtime.sh
```

`audit-static.sh` kiểm tra cú pháp, module dispatch và mapping UI/CLI. `audit-runtime.sh` kiểm tra dependency trên máy Linux nhưng không thay thế kiểm thử dịch vụ và client thật.

## Cấu trúc

```text
bin/netadmin       CLI entry point
src/core/          validation, logging, backup và system runner
src/features/      module nghiệp vụ độc lập
site/dist/         Cockpit package
scripts/           audit source và runtime
config/            cấu hình mẫu
docs/              hướng dẫn sử dụng và tài liệu kỹ thuật
```

## Tài liệu

- [Bắt đầu với Cockpit](docs/QUICKSTART-COCKPIT-UI.md)
- [CLI reference](docs/CLI_REFERENCE.md)
- [Danh sách công cụ](docs/TOOLS-LIST.md)
- [Phạm vi và kết quả audit](docs/TOOL-COVERAGE-AUDIT.md)
- [Giáo trình cho người mới](docs/handbook/README.md)

## Nguyên tắc an toàn

- Giữ Dry run bật khi chưa chắc chắn về tham số.
- Kiểm tra đúng connection profile trước khi đổi IP.
- Không format, partition hoặc thay đổi LVM trên ổ chứa hệ điều hành.
- Không tắt SELinux hoặc firewalld để né lỗi.
- Sao lưu cấu hình và kiểm tra syntax trước khi restart dịch vụ.

