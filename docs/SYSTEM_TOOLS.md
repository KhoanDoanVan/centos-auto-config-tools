# Công cụ hệ thống và dependency

Tài liệu này giải thích các command/package bên ngoài mà NetAdmin Toolkit sử dụng. Các tiện ích Bash cơ bản như `printf`, `read`, `source`, `test` và `command` không cần package riêng.

## 1. Nền tảng chung

| Tool | Vai trò | Package thường gặp |
|---|---|---|
| `bash` | Chạy toàn bộ toolkit | `bash` |
| `awk`, `sed`, `grep`, `cut`, `tr` | Đọc và biến đổi file cấu hình | `gawk`, `sed`, `grep`, `coreutils` |
| `install`, `cp`, `mv`, `mkdir`, `rm` | Ghi file an toàn, backup và tổ chức thư mục | `coreutils` |
| `find`, `head` | Tìm và chọn backup mới nhất | `findutils`, `coreutils` |
| `date`, `mktemp` | Timestamp, serial DNS và file tạm | `coreutils` |
| `dnf` hoặc `yum` | Cài package | Theo phiên bản hệ điều hành |
| `systemctl` | Quản lý service | `systemd` |
| `firewall-cmd` | Mở service trong firewall | `firewalld` |
| `semanage`, `restorecon`, `chcon` | Context SELinux cho Samba share | `policycoreutils-python-utils` hoặc `policycoreutils-python` |

## 2. DHCP

| Tool | Công dụng |
|---|---|
| `dhcpd` | DHCP daemon và validator `dhcpd -t` |
| `omshell` | Xóa lease qua OMAPI |
| `systemctl` | `dhcpd` start/stop/restart/enable/status |
| `firewall-cmd --add-service=dhcp` | Cho phép DHCP qua firewalld |

Package:

- CentOS 7/yum: `dhcp`.
- RHEL/Rocky/Alma/Fedora mới/dnf: `dhcp-server`.

File và service:

| Thành phần | Mặc định |
|---|---|
| Cấu hình | `/etc/dhcp/dhcpd.conf` |
| Lease | `/var/lib/dhcpd/dhcpd.leases` |
| Service | `dhcpd.service` |
| Firewall service | `dhcp` |

## 3. DNS và NetworkManager

| Tool | Công dụng | Package |
|---|---|---|
| `named` | BIND DNS server | `bind` |
| `named-checkconf` | Kiểm tra toàn bộ cấu hình BIND | `bind` |
| `named-checkzone` | Kiểm tra syntax và dữ liệu zone | `bind` |
| `dig` | Truy vấn DNS | `bind-utils` |
| `nmcli` | Liệt kê và thay đổi network connection | `NetworkManager` |
| `systemctl` | Quản lý `named` | `systemd` |

File và thư mục:

| Thành phần | Mặc định |
|---|---|
| Cấu hình chính | `/etc/named.conf` |
| Zone fragment | `/etc/named/netadmin-zones.conf` |
| Master zone files | `/var/named/db.<zone-key>` |
| Secondary zone files | `/var/named/slaves/` |
| Service | `named.service` |
| Firewall service | `dns` |

Zone file được cài với owner/group `named:named` và mode `0640`.

## 4. Disk, filesystem và LVM

| Tool | Công dụng | Package thường gặp |
|---|---|---|
| `lsblk`, `findmnt`, `mount`, `blkid` | Khảo sát block device, mount và filesystem | `util-linux` |
| `parted`, `partprobe` | Tạo partition và refresh kernel partition table | `parted` |
| `udevadm` | Chờ udev hoàn tất tạo device node | `systemd-udev` |
| `mkfs.xfs`, `xfs_growfs` | Tạo và mở rộng XFS | `xfsprogs` |
| `mkfs.ext3`, `mkfs.ext4`, `resize2fs` | Tạo và mở rộng ext filesystem | `e2fsprogs` |
| `pvcreate`, `vgcreate`, `vgextend` | Quản lý physical/volume group | `lvm2` |
| `lvcreate`, `lvextend`, `pvs`, `vgs`, `lvs` | Quản lý logical volume | `lvm2` |

Toolkit chỉ tự cài `lvm2` khi gọi `storage lvm install`. Cần chuẩn bị `parted`, `xfsprogs` hoặc `e2fsprogs` trước khi dùng chức năng tương ứng.

File được chỉnh sửa:

- `/etc/fstab` khi mount persistent hoặc bật quota.
- Không có metadata riêng của toolkit trên disk; LVM/partition được native tools ghi trực tiếp.

## 5. Quota

| Tool | Công dụng | Package |
|---|---|---|
| `quotacheck` | Khởi tạo/kiểm tra quota database cho ext filesystem | `quota` |
| `quotaon` | Bật quota | `quota` |
| `setquota` | Đặt block/inode limit | `quota` |
| `repquota` | In báo cáo quota | `quota` |

`storage quota enable` tự cài package `quota`.

## 6. Samba và CIFS

| Tool | Công dụng | Package |
|---|---|---|
| `smbd`/service `smb` | SMB file server | `samba` |
| `nmbd`/service `nmb` | NetBIOS name service | `samba` |
| `testparm` | Kiểm tra và chuẩn hóa `smb.conf` | `samba-common-tools` hoặc Samba package theo distro |
| `smbstatus` | Xem session và lock | `samba` |
| `pdbedit`, `smbpasswd` | Quản lý Samba account database | `samba-common-tools`/`samba` |
| `smbclient` | Liệt kê/truy cập share từ client | `samba-client` |
| `mount.cifs` | Mount SMB share vào Linux | `cifs-utils` |
| `groupadd`, `useradd`, `usermod` | Linux group/user cho protected share | `shadow-utils` |
| `getent` | Tra cứu account/group | `glibc-common` |

File và service:

| Thành phần | Mặc định |
|---|---|
| Cấu hình | `/etc/samba/smb.conf` |
| Services | `smb.service`, `nmb.service` |
| Firewall service | `samba` |

## 7. Những package được tự động cài

| Command | Package |
|---|---|
| `dhcp install` | `dhcp-server` hoặc `dhcp` |
| `dns install` | `bind`, `bind-utils`, `NetworkManager` |
| `storage lvm install` | `lvm2` |
| `storage quota enable` | `quota` |
| `samba install` | `samba`, `samba-common`, `samba-common-tools`, `samba-client`, `cifs-utils` |

Các package khác không được tự động cài để tránh thay đổi hệ thống ngoài feature đang dùng.

## 8. Kiểm tra dependency thủ công

```bash
./bin/netadmin doctor

command -v dhcpd omshell
command -v named-checkconf named-checkzone dig nmcli
command -v parted lsblk blkid mkfs.xfs mkfs.ext4
command -v pvcreate vgcreate lvcreate
command -v quotacheck quotaon setquota repquota
command -v testparm smbstatus pdbedit smbclient mount.cifs
```

Trên CentOS 7 có thể chuẩn bị đầy đủ môi trường lab bằng:

```bash
sudo yum install -y \
  dhcp bind bind-utils NetworkManager \
  parted lvm2 xfsprogs e2fsprogs quota \
  samba samba-common samba-common-tools samba-client cifs-utils
```
