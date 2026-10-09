# Tài liệu NetAdmin Toolkit

Thư mục này có hai tầng tài liệu:

- **Giáo trình từ cơ bản:** dành cho người chưa có kiến thức network/Linux domain.
- **Tham chiếu nhanh:** dành cho lúc đã hiểu khái niệm và cần tra command.

## Lộ trình cho người mới

Đọc theo thứ tự:

1. [Kiến thức nền: IP, gateway, service, disk, permission](handbook/00-KIEN-THUC-NEN.md)
2. [CLI, Doctor, dry-run, backup và an toàn](handbook/01-CLI-VA-AN-TOAN.md)
3. [DHCP từ cơ bản đến từng command](handbook/02-DHCP-TU-CO-BAN.md)
4. [DNS/BIND từ cơ bản đến từng command](handbook/03-DNS-BIND-TU-CO-BAN.md)
5. [Storage, LVM và quota từ cơ bản](handbook/04-STORAGE-LVM-QUOTA-TU-CO-BAN.md)
6. [Samba/SMB từ cơ bản đến từng command](handbook/05-SAMBA-TU-CO-BAN.md)
7. [Từ điển từng công cụ Linux bên dưới](handbook/06-TU-DIEN-CONG-CU-LINUX.md)
8. [Runbook kiểm thử thực tế trên CentOS](handbook/07-RUNBOOK-KIEM-THU-TREN-CENTOS.md)

## Tra nhanh từng nhóm tool

| Tool cần hiểu | Chương giải thích |
|---|---|
| `netadmin`, `help`, `version`, `doctor` | [CLI và an toàn](handbook/01-CLI-VA-AN-TOAN.md) |
| Biến môi trường, dry-run, backup, rollback, marker | [CLI và an toàn](handbook/01-CLI-VA-AN-TOAN.md) |
| `dhcp install` | [DHCP](handbook/02-DHCP-TU-CO-BAN.md) |
| `dhcp scope add/update/list/remove` | [DHCP](handbook/02-DHCP-TU-CO-BAN.md) |
| `dhcp reservation add/list/remove` | [DHCP](handbook/02-DHCP-TU-CO-BAN.md) |
| `dhcp lease list/release` | [DHCP](handbook/02-DHCP-TU-CO-BAN.md) |
| `dhcp config`, `dhcp service` | [DHCP](handbook/02-DHCP-TU-CO-BAN.md) |
| `dns install`, `dns network` | [DNS/BIND](handbook/03-DNS-BIND-TU-CO-BAN.md) |
| `dns zone add/add-reverse/add-secondary/list/remove` | [DNS/BIND](handbook/03-DNS-BIND-TU-CO-BAN.md) |
| `dns record add/list/remove` | [DNS/BIND](handbook/03-DNS-BIND-TU-CO-BAN.md) |
| `dns transfer`, `forwarders`, `query`, `config`, `service` | [DNS/BIND](handbook/03-DNS-BIND-TU-CO-BAN.md) |
| `storage disk`, `partition`, `filesystem` | [Storage](handbook/04-STORAGE-LVM-QUOTA-TU-CO-BAN.md) |
| `storage lvm` | [Storage](handbook/04-STORAGE-LVM-QUOTA-TU-CO-BAN.md) |
| `storage quota` | [Storage](handbook/04-STORAGE-LVM-QUOTA-TU-CO-BAN.md) |
| `samba install`, `share`, `user`, `permissions` | [Samba](handbook/05-SAMBA-TU-CO-BAN.md) |
| `samba config`, `service`, `status`, `sessions`, `client` | [Samba](handbook/05-SAMBA-TU-CO-BAN.md) |
| `awk`, `grep`, `systemctl`, `firewall-cmd`, SELinux tools | [Từ điển công cụ](handbook/06-TU-DIEN-CONG-CU-LINUX.md) |
| `dhcpd`, `omshell`, `named`, `dig`, `nmcli` | [Từ điển công cụ](handbook/06-TU-DIEN-CONG-CU-LINUX.md) |
| `parted`, `mkfs`, LVM, quota, Samba/CIFS commands | [Từ điển công cụ](handbook/06-TU-DIEN-CONG-CU-LINUX.md) |
| Quy trình test đầy đủ trên 2 VM CentOS | [Runbook kiểm thử CentOS](handbook/07-RUNBOOK-KIEM-THU-TREN-CENTOS.md) |

## Tài liệu tham chiếu

| Tài liệu | Nội dung |
|---|---|
| [CLI_REFERENCE.md](CLI_REFERENCE.md) | Tất cả command, tham số, kết quả và ví dụ |
| [SYSTEM_TOOLS.md](SYSTEM_TOOLS.md) | Package, command hệ thống, service và file cấu hình được sử dụng |

Đọc nhanh:

```bash
./bin/netadmin help
./bin/netadmin <module> help
```

Các module hiện có là `doctor`, `dhcp`, `dns`, `storage` và `samba`.
