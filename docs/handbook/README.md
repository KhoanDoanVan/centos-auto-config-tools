# NetAdmin Toolkit

Bộ công cụ Bash tự động hóa các bài thực hành Quản trị mạng trên CentOS/RHEL. Dự án hiện tập trung vào tool và nghiệp vụ; không có giao diện đồ họa hoặc test suite theo đúng phạm vi hiện tại.

Tài liệu đầy đủ:

- [Giáo trình chi tiết cho người bắt đầu từ số 0](docs/README.md)
- [Tham chiếu tất cả CLI và ví dụ](docs/CLI_REFERENCE.md)
- [Package, command hệ thống và file liên quan](docs/SYSTEM_TOOLS.md)
- [Mục lục tài liệu](docs/README.md)

## Phạm vi tính năng

- **DHCP:** cài đặt, tạo/cập nhật/xóa scope, static reservation, lease, kiểm tra/rollback cấu hình và vận hành `dhcpd`.
- **DNS:** IP tĩnh/DHCP qua NetworkManager, master/reverse/secondary zone, record, zone transfer, forwarder, truy vấn và vận hành BIND.
- **Storage:** khảo sát disk, partition, filesystem, persistent mount, LVM create/extend và user/group quota.
- **Samba:** public/group share, user, quyền đọc-ghi, SELinux, firewall, backup/rollback, theo dõi session và sao chép từ SMB share.
- **Doctor:** kiểm tra nhanh môi trường chạy.

Toolkit không tắt firewall hoặc SELinux. Nó chỉ mở đúng service và gắn context/boolean cần thiết, phù hợp hơn cho bài lab lẫn môi trường dài hạn.

## Kiến trúc

```text
bin/netadmin                    # composition root / CLI entrypoint
config/                         # cấu hình triển khai
src/core/                       # cross-cutting: log, validation, backup, OS adapters
src/features/
├── dhcp/
│   ├── module.sh               # router của bounded context
│   ├── commands/               # application use-cases
│   └── infra/                  # adapter dhcpd/filesystem
├── dns/                        # cùng quy ước
├── storage/
├── samba/
└── doctor/
```

Mỗi feature là một bounded context độc lập. `module.sh` chỉ dispatch command; nghiệp vụ nằm trong `commands/`; tương tác với file/service native nằm trong `infra/`. Core không phụ thuộc ngược vào feature. Khi thêm sub-tool, tạo file command mới và source nó từ `module.sh`, không cần sửa các feature khác.

Các đoạn cấu hình sinh tự động có marker `NETADMIN:*`. Tool chỉ cập nhật block do chính nó quản lý và giữ nguyên phần cấu hình thủ công.

## Yêu cầu

- CentOS 7, RHEL/Rocky/AlmaLinux hoặc Fedora dùng `yum`/`dnf`.
- Bash 3.2+; quyền root cho mọi tác vụ thay đổi hệ thống.
- Các package theo module có thể cài bằng command `install` tương ứng.

## Bắt đầu

```bash
chmod +x bin/netadmin
./bin/netadmin help
sudo ./bin/netadmin doctor
sudo ./bin/netadmin dhcp install
sudo ./bin/netadmin dns install
sudo ./bin/netadmin samba install
```

Có thể tạo cấu hình riêng:

```bash
cp config/netadmin.conf.example config/netadmin.conf
```

### Ví dụ DHCP

```bash
sudo ./bin/netadmin dhcp scope add lab-lan \
  192.168.10.0 255.255.255.0 192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2,1.1.1.1 lab.local 600
sudo ./bin/netadmin dhcp reservation add pc01 00:11:22:33:44:55 192.168.10.10 pc01
sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp service enable-now
```

### Ví dụ DNS

```bash
sudo ./bin/netadmin dns zone add lab.local 192.168.10.2
sudo ./bin/netadmin dns record add lab.local www A 192.168.10.20
sudo ./bin/netadmin dns zone add-reverse 10.168.192.in-addr.arpa ns1.lab.local
sudo ./bin/netadmin dns record add 10.168.192.in-addr.arpa 20 PTR www.lab.local.
sudo ./bin/netadmin dns forwarders set 1.1.1.1,8.8.8.8
sudo ./bin/netadmin dns config check
```

### Ví dụ storage

```bash
./bin/netadmin storage disk list
sudo ./bin/netadmin storage partition create /dev/sdb 1MiB 100% gpt
sudo ./bin/netadmin storage filesystem format /dev/sdb1 xfs DATA
sudo ./bin/netadmin storage filesystem mount /dev/sdb1 /data
sudo ./bin/netadmin storage quota enable /data
```

### Ví dụ Samba

```bash
sudo ./bin/netadmin samba user add student labusers
sudo ./bin/netadmin samba share add-group lessons /data/lessons labusers read-write
sudo ./bin/netadmin samba config apply
./bin/netadmin samba sessions
```

## An toàn và vận hành

- Dùng `NETADMIN_DRY_RUN=1` để xem các command hệ thống trước khi chạy.
- Partition, format và `pv-create` yêu cầu nhập lại chính xác device; không thể bỏ qua bằng `NETADMIN_ASSUME_YES`.
- File cấu hình được backup vào `/var/backups/netadmin/<module>` trước khi sửa.
- Thay đổi DHCP/DNS/Samba được kiểm tra bằng `dhcpd -t`, `named-checkconf`/`named-checkzone`, hoặc `testparm`.
- Xóa DNS zone chỉ đổi tên zone file; xóa Samba share không xóa dữ liệu trong thư mục.
- `NETADMIN_ROOT=/path/to/rootfs` đổi root cấu hình, hữu ích khi chuẩn bị image/chroot. Không dùng biến này cho thao tác disk hoặc service thật.

Chạy `./bin/netadmin <module> help` để xem toàn bộ command của từng nhóm.
