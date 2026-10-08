# Chương 6 — Từ điển từng công cụ Linux được sử dụng

Chương này giải thích các chương trình mà NetAdmin gọi phía dưới. Bạn không bắt buộc chạy chúng trực tiếp, nhưng hiểu chúng giúp đọc log và sửa lỗi.

## 1. Công cụ shell và xử lý text

### `bash`

Shell thực thi các file `.sh`. Bash đọc biến, function, `if`, `case`, loop và chạy command ngoài. Dự án bật:

- `-e`: dừng khi command không được xử lý trả lỗi.
- `-u`: lỗi khi dùng biến chưa khai báo.
- `-o pipefail`: pipeline lỗi nếu một thành phần lỗi.
- `-E`: ERR trap được kế thừa vào function.

Kiểm tra syntax mà không chạy:

```bash
bash -n bin/netadmin
```

### `grep`

Tìm dòng khớp text/regular expression. Toolkit dùng grep để tìm marker, scope, MAC, IP và entry fstab. `grep` chỉ đọc nếu không kết hợp command ghi khác.

```bash
grep 'NETADMIN' /etc/dhcp/dhcpd.conf
```

### `awk`

Ngôn ngữ xử lý dữ liệu theo dòng/cột. Toolkit dùng awk để bỏ một managed block, đọc lease, chỉnh option fstab và tăng DNS serial. Awk thường ghi ra file tạm; toolkit sau đó dùng `install` thay file đích.

### `sed`

Stream editor. Core doctor kiểm tra nó vì đây là dependency nền tảng phổ biến, dù luồng hiện tại ưu tiên awk cho thay đổi cấu hình phức tạp.

### `cut`

Cắt field theo delimiter. Toolkit dùng `cut -d: -f3` để lấy tên từ marker như `# NETADMIN:SCOPE:lab-lan:BEGIN`.

### `tr`

Thay đổi ký tự. Toolkit dùng để chuyển MAC/type thành lower/upper case và đổi dấu trong domain thành tên file an toàn.

### `find`, `sort`, `head`

Kết hợp để tìm backup, sắp xếp timestamp giảm dần và chọn file mới nhất.

### `mktemp`

Tạo file/thư mục tạm không trùng tên. Quan trọng để tránh ghi nửa chừng trực tiếp vào file cấu hình. File credential Samba cũng dùng `mktemp` và mode `600`.

### `install`

Không phải package installer trong ngữ cảnh này. Coreutils `install` sao chép file đồng thời đặt mode/owner/group:

```bash
install -o named -g named -m 0640 source /var/named/db.lab-local
```

### `cp -a`

Sao chép giữ metadata như permission/timestamp; dùng cho backup và copy dữ liệu từ SMB.

### `mv`

Đổi tên/di chuyển. Khi xóa DNS zone, toolkit đổi zone file thành `.removed.<timestamp>` thay vì xóa vĩnh viễn.

## 2. Package, service, firewall và bảo mật

### `yum` và `dnf`

Package manager giải dependency, tải và cài RPM. `dnf` là thế hệ mới; toolkit ưu tiên nó nếu tồn tại.

```bash
sudo yum install -y bind
sudo dnf install -y bind
```

`-y` tự đồng ý prompt của package manager. Cần Internet hoặc repository nội bộ hoạt động.

### `systemctl`

Giao tiếp với systemd. Unit name như `named`, `dhcpd`, `smb` được systemd ánh xạ thành `.service`.

```bash
systemctl is-active named
systemctl status named -l
systemctl enable --now named
```

Status lỗi nên đọc cùng `journalctl -u named`.

### `firewall-cmd`

CLI của firewalld. Toolkit thêm service vào permanent config rồi reload:

```bash
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload
```

`--permanent` không đổi runtime cho tới reload. Service name ánh xạ tới danh sách port XML do firewalld cung cấp.

### `chown`

Đổi owner/group của file hoặc thư mục:

```bash
chown root:labusers /data/lessons
```

### `chmod`

Đổi mode permission. `2770` gồm setgid + `rwxrwx---`. Dùng mode rộng như `0777` cần cân nhắc bảo mật.

### `semanage fcontext`

Ghi quy tắc SELinux context bền vững vào policy store. Toolkit thêm pattern `<path>(/.*)?` với type `samba_share_t`.

### `restorecon`

Áp context theo policy/fcontext rule lên file thật. `-R` đi đệ quy, `-v` hiển thị thay đổi.

### `chcon`

Đổi context trực tiếp. Nhanh nhưng có thể mất sau relabel; toolkit chỉ dùng fallback khi không có `semanage`.

## 3. Công cụ DHCP

### `dhcpd`

ISC DHCP server daemon. Khi chạy bởi systemd, nó lắng nghe DHCP request và quản lý lease. Toolkit dùng chế độ kiểm tra:

```bash
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

`-t` parse config rồi thoát, không chạy server. `-cf` chỉ file cấu hình.

### `omshell`

Shell client cho OMAPI của ISC DHCP. Có thể mở và xóa object lease khi server cho phép. Nó không phải shell Linux và không hoạt động nếu OMAPI chưa cấu hình/listen.

## 4. Công cụ DNS và network

### `named`

Daemon của BIND. Nó đọc `named.conf`, load zone, lắng nghe port 53 và ghi log qua systemd/syslog tùy distro.

### `named-checkconf`

Parse cấu hình BIND mà không start/restart service:

```bash
named-checkconf /etc/named.conf
```

Thường không output khi thành công. Exit code mới là tín hiệu chắc chắn.

### `named-checkzone`

Kiểm tra một zone cụ thể:

```bash
named-checkzone lab.local /var/named/db.lab-local
```

Nó phát hiện lỗi SOA, syntax record và một số consistency issue.

### `dig`

DNS lookup client chi tiết:

```bash
dig @192.168.10.2 files.lab.local A
dig @192.168.10.2 -x 192.168.10.20
dig @192.168.10.2 lab.local SOA
```

`@server` chọn DNS server, tham số cuối có thể là record type. `+short` chỉ in câu trả lời ngắn.

### `nmcli`

CLI của NetworkManager. Nó quản lý **connection profile**, không chỉnh file tùy tiện. Các lệnh toolkit dùng:

```bash
nmcli connection show
nmcli connection modify '<name>' ipv4.method manual ...
nmcli connection up '<name>'
```

`connection up` áp dụng thay đổi và có thể làm mất kết nối SSH.

### `ip`

Công cụ từ `iproute2` để xem/chỉnh link, address và route:

```bash
ip address
ip route
ip link
```

Toolkit doctor kiểm tra `ip`, nhưng module network hiện dùng `nmcli` để thay đổi persistent profile.

## 5. Công cụ disk và filesystem

### `lsblk`

Đọc sysfs/udev để hiển thị cây block device. Đây là bước đầu tiên trước thao tác disk.

### `parted`

Đọc và sửa partition table. `mklabel` tạo bảng mới; `mkpart` tạo partition entry. Thao tác ghi có thể phá dữ liệu.

### `partprobe`

Thông báo kernel đọc lại partition table sau khi sửa. Nó không tạo partition; chỉ đồng bộ kernel view.

### `udevadm settle`

Chờ udev xử lý hết event, giúp `/dev/sdb1` xuất hiện trước bước tiếp theo.

### `mkfs.xfs`, `mkfs.ext4`, `mkfs.ext3`

Tạo filesystem mới. `mkfs` không chỉ “đặt tên format”; nó ghi metadata filesystem và làm dữ liệu cũ khó/không thể truy cập. XFS dùng `-f`, ext dùng `-F` để force.

### `blkid`

Đọc metadata như UUID, TYPE, LABEL:

```bash
blkid -s UUID -o value /dev/sdb1
```

### `mount`

Gắn filesystem vào directory. `mount /data` đọc entry tương ứng từ fstab. Mount runtime mất sau reboot nếu không có fstab.

### `findmnt`

Hiển thị mount tree và tìm source/target/FSTYPE/options. An toàn để khảo sát.

### `xfs_growfs`

Mở rộng XFS đang mount để sử dụng block mới của LV. Nhận mountpoint, không nhận raw device trong cách toolkit dùng.

### `resize2fs`

Resize ext2/ext3/ext4. Toolkit dùng để grow sau `lvextend`.

## 6. Công cụ LVM

### `pvcreate`

Khởi tạo LVM metadata trên block device. Đây là thao tác phá hủy đối với filesystem cũ.

### `vgcreate`

Tạo volume group mới từ PV.

### `vgextend`

Thêm PV vào VG có sẵn, tăng free extent của pool.

### `lvcreate`

Tạo logical volume. `-L 10G` dùng size; `-l 100%FREE` dùng logical extent.

### `lvextend`

Mở rộng LV. Nó không tự bảo đảm filesystem đã mở rộng nếu không dùng option/công cụ bổ sung; toolkit gọi grow tool sau đó.

### `pvs`, `vgs`, `lvs`

Ba command read-only để xem PV, VG, LV. Nên chạy trước và sau mỗi thay đổi.

## 7. Công cụ quota

### `quotacheck`

Quét filesystem và tạo/cập nhật database usage quota. Tùy filesystem và trạng thái mount, việc quét có thể tốn thời gian.

### `quotaon`

Bật enforcement quota sau khi mount options/database sẵn sàng.

### `setquota`

Đặt soft/hard block và inode limit cho user/group. Toolkit dùng `-u` cho user.

### `repquota`

In report usage/limit. `-s` đổi số sang định dạng dễ đọc.

## 8. Công cụ Samba và account

### `testparm`

Parse `smb.conf`, cảnh báo option sai và in effective config. Không thử đăng nhập client hay kiểm tra mọi filesystem permission.

### `smbstatus`

Hỏi daemon/database runtime về session, share và lock đang hoạt động.

### `smbpasswd`

`-a user` thêm/đặt password Samba; `-x user` xóa Samba account. Nó không xóa Linux user.

### `pdbedit`

Quản lý/đọc Samba passdb. Toolkit dùng `pdbedit -L -v` để list chi tiết.

### `smbclient`

Client SMB tương tác giống FTP. Toolkit dùng `-c ls` để list share mà không mount.

### `mount.cifs`

Mount SMB share vào cây thư mục Linux. Cần kernel CIFS support và package `cifs-utils`. Credential file an toàn hơn đặt password trực tiếp trên command line.

### `groupadd`

Tạo Linux group. Group gom user để cấp quyền share/filesystem.

### `useradd`

Tạo Linux user. Toolkit dùng `-M` không tạo home và `-s /sbin/nologin` để cấm shell login.

### `usermod -aG`

Thêm user vào supplementary group. `-a` rất quan trọng: thiếu nó có thể thay thế toàn bộ danh sách group bổ sung hiện có.

### `id` và `getent`

- `id user`: xem UID, primary group và supplementary groups.
- `getent group name`: tra cứu group qua Name Service Switch, không chỉ đọc `/etc/group`.

## 9. Công cụ chẩn đoán nên biết thêm

Các command này không phải tất cả đều được toolkit gọi, nhưng rất hữu ích:

| Command | Dùng để |
|---|---|
| `journalctl -u service` | Đọc log systemd của một service |
| `ss -lntup` | Xem TCP/UDP port đang listen |
| `ping IP` | Kiểm tra ICMP reachability cơ bản |
| `traceroute IP` | Xem đường đi qua router |
| `tcpdump -ni interface port 53` | Quan sát packet DNS |
| `tcpdump -ni interface port 67 or port 68` | Quan sát DHCP DORA |
| `df -h` | Dung lượng filesystem nhìn từ mount |
| `du -sh path` | Dung lượng file dưới một path |
| `namei -l path` | Permission từng thành phần của path |

`ping` thất bại không luôn nghĩa service hỏng vì ICMP có thể bị chặn. `ping` thành công cũng không chứng minh port ứng dụng mở.

