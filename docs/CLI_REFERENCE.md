# Tham chiếu toàn bộ CLI

## 1. Quy ước chung

Entry point của dự án là `bin/netadmin`:

```bash
./bin/netadmin <module> <command> [arguments]
```

Các ký hiệu trong tài liệu:

- `<value>`: tham số bắt buộc.
- `[value]`: tham số tùy chọn.
- `a|b`: chọn một trong các giá trị.
- Danh sách IP dùng dấu phẩy và không có khoảng trắng, ví dụ `1.1.1.1,8.8.8.8`.
- Các command thay đổi package, service, user hoặc file hệ thống cần chạy bằng `sudo`.

### Command cấp cao

| Command | Công dụng |
|---|---|
| `netadmin help` | Hiện danh sách module và biến môi trường |
| `netadmin version` | Hiện phiên bản toolkit |
| `netadmin doctor [run]` | Kiểm tra môi trường tối thiểu |
| `netadmin <module> help` | Hiện trợ giúp ngắn của module |

Ví dụ trong tài liệu giả sử đang đứng tại thư mục dự án. Có thể tạo alias cho phiên shell hiện tại:

```bash
alias netadmin="$PWD/bin/netadmin"
```

## 2. Biến môi trường

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `NETADMIN_CONFIG` | `config/netadmin.conf` | File cấu hình được source khi khởi động |
| `NETADMIN_DRY_RUN` | `0` | Giá trị `1` chỉ in những lệnh đi qua lớp `run`, không thực thi |
| `NETADMIN_ASSUME_YES` | `0` | Giá trị `1` tự chấp nhận xác nhận thông thường |
| `NETADMIN_ROOT` | rỗng | Ghép prefix rootfs vào đường dẫn cấu hình hệ thống |
| `NETADMIN_BACKUP_DIR` | `/var/backups/netadmin` | Thư mục chứa backup theo module |
| `NO_COLOR` | `0` | Giá trị `1` tắt màu log |
| `DHCP_CONFIG` | `/etc/dhcp/dhcpd.conf` | File cấu hình DHCP |
| `DHCP_LEASES` | `/var/lib/dhcpd/dhcpd.leases` | File lease DHCP |
| `DNS_CONFIG` | `/etc/named.conf` | File cấu hình chính BIND |
| `DNS_MANAGED_CONFIG` | `/etc/named/netadmin-zones.conf` | Fragment zone do toolkit quản lý |
| `DNS_ZONE_DIR` | `/var/named` | Thư mục zone file |
| `SAMBA_CONFIG` | `/etc/samba/smb.conf` | File cấu hình Samba |

`NETADMIN_ROOT` chỉ phù hợp khi chuẩn bị image hoặc rootfs. Các command service, package, disk, `nmcli`, user và mount vẫn tác động lên hệ thống đang chạy.

Ví dụ xem lệnh mà không thực thi:

```bash
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin samba install
```

Dry-run vẫn có thể yêu cầu dependency native để chạy bước kiểm tra cấu hình. Không dùng `NETADMIN_ASSUME_YES` để bỏ qua xác nhận disk: thao tác phá hủy luôn yêu cầu nhập lại chính xác device.

## 3. Doctor

### `doctor run`

```bash
./bin/netadmin doctor
./bin/netadmin doctor run
```

Hiển thị:

- Tên và phiên bản hệ điều hành từ `/etc/os-release`.
- Phiên bản Bash.
- Trạng thái quyền root.
- Sự tồn tại của `awk`, `grep`, `sed`, `install`, `systemctl` và `ip`.

Command trả exit code khác `0` nếu thiếu ít nhất một command cơ bản. Doctor chỉ kiểm tra nền tảng chung; dependency chuyên biệt được kiểm tra khi gọi từng feature.

## 4. DHCP

### 4.1 Cài đặt

```bash
sudo ./bin/netadmin dhcp install
```

Thực hiện:

1. Cài `dhcp-server` bằng `dnf`, hoặc `dhcp` bằng `yum`.
2. Tạo cấu hình DHCP tối thiểu nếu file chưa tồn tại.
3. Enable service `dhcpd`, chưa tự start khi chưa có scope.
4. Mở service `dhcp` trong firewalld nếu firewalld đang chạy.

Toolkit không tắt firewall.

### 4.2 Tạo scope

```bash
sudo ./bin/netadmin dhcp scope add \
  <name> <subnet> <netmask> <start-ip> <end-ip> \
  <gateway> <dns[,dns]> [domain] [lease-seconds]
```

Ví dụ:

```bash
sudo ./bin/netadmin dhcp scope add lab-lan \
  192.168.10.0 255.255.255.0 \
  192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2,1.1.1.1 lab.local 600
```

Ý nghĩa tham số:

| Tham số | Ý nghĩa |
|---|---|
| `name` | ID duy nhất của block cấu hình; không phải tên interface |
| `subnet` | Network address của mạng cấp phát |
| `netmask` | Subnet mask dạng dotted decimal |
| `start-ip`, `end-ip` | Khoảng địa chỉ cấp động |
| `gateway` | Router gửi cho client qua DHCP option |
| `dns[,dns]` | Một hoặc nhiều DNS server |
| `domain` | Domain cấp cho client; mặc định `lab.local` |
| `lease-seconds` | Default lease; mặc định `600`; max lease được đặt bằng 12 lần giá trị này |

Tool kiểm tra IPv4, netmask, thứ tự range và đảm bảo range/gateway cùng subnet. Scope được ghi giữa marker `NETADMIN:SCOPE` rồi kiểm tra bằng `dhcpd -t`.

### 4.3 Cập nhật scope

```bash
sudo ./bin/netadmin dhcp scope update <các-tham-số-giống-scope-add>
```

Scope phải tồn tại. Block cũ được thay thế theo `name`; nếu cấu hình mới không hợp lệ, file gốc được tự động khôi phục.

### 4.4 Liệt kê và xóa scope

```bash
./bin/netadmin dhcp scope list
sudo ./bin/netadmin dhcp scope remove lab-lan
```

`list` chỉ liệt kê scope do NetAdmin quản lý. `remove` xóa block cấu hình, không xóa lease hiện có của client.

### 4.5 Reservation IP tĩnh

```bash
sudo ./bin/netadmin dhcp reservation add <name> <mac> <ip> [hostname]
./bin/netadmin dhcp reservation list
sudo ./bin/netadmin dhcp reservation remove <name>
```

Ví dụ:

```bash
sudo ./bin/netadmin dhcp reservation add \
  pc01 00:11:22:33:44:55 192.168.10.10 pc01
```

Tool chuẩn hóa MAC thành chữ thường, chặn trùng tên/MAC/IP trong cấu hình và kiểm tra file trước khi giữ thay đổi. Nếu bỏ `hostname`, tool dùng `name`.

### 4.6 Lease

```bash
./bin/netadmin dhcp lease list
sudo ./bin/netadmin dhcp lease release <ip>
```

- `lease list`: đọc lease file và in IP, thời gian bắt đầu, kết thúc, hostname.
- `lease release`: yêu cầu `omshell`, kết nối OMAPI tại `localhost:7911` và yêu cầu xóa lease theo IP. DHCP server phải được cấu hình OMAPI phù hợp thì thao tác mới thành công.

### 4.7 Cấu hình và service

```bash
./bin/netadmin dhcp config show
sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp config rollback
sudo ./bin/netadmin dhcp service <start|stop|restart|status|enable|enable-now>
```

| Command | Mô tả |
|---|---|
| `config show` | In toàn bộ `dhcpd.conf` |
| `config check` | Chạy `dhcpd -t -cf ...` |
| `config rollback` | Khôi phục backup gần nhất của `dhcpd.conf`, có hỏi xác nhận |
| `service enable` | Cho phép tự khởi động cùng hệ thống |
| `service enable-now` | Enable và start ngay |

## 5. DNS/BIND

### 5.1 Cài đặt

```bash
sudo ./bin/netadmin dns install
```

Cài `bind`, `bind-utils`, `NetworkManager`; tạo `netadmin-zones.conf`; thêm một dòng `include` vào `named.conf`; enable `named`; và mở DNS trong firewalld. Cấu hình được kiểm tra bằng `named-checkconf`.

### 5.2 Cấu hình IPv4 bằng NetworkManager

Liệt kê connection:

```bash
./bin/netadmin dns network list
```

Đặt IP tĩnh:

```bash
sudo ./bin/netadmin dns network static \
  <connection> <address/prefix> <gateway> <dns[,dns]>
```

Ví dụ:

```bash
sudo ./bin/netadmin dns network static \
  'System eth0' 192.168.10.2/24 192.168.10.1 127.0.0.1,1.1.1.1
```

Chuyển connection về DHCP:

```bash
sudo ./bin/netadmin dns network dhcp 'System eth0'
```

Cả hai command thay đổi profile bằng `nmcli` và kích hoạt lại connection ngay. Nếu thao tác từ SSH qua chính interface đó, phiên SSH có thể bị ngắt.

### 5.3 Master forward zone

```bash
sudo ./bin/netadmin dns zone add <domain> <server-ip> [admin-label]
```

Ví dụ:

```bash
sudo ./bin/netadmin dns zone add lab.local 192.168.10.2 hostmaster
```

Tool tạo:

- Master zone declaration trong `netadmin-zones.conf`.
- Zone file `db.<zone-key>`.
- SOA, NS `ns1`, A record cho `ns1` và apex `@`.
- Serial khởi tạo theo dạng `YYYYMMDD00`.

`admin-label` là phần đứng trước domain trong RNAME của SOA, mặc định `hostmaster`.

### 5.4 Reverse zone

```bash
sudo ./bin/netadmin dns zone add-reverse \
  <reverse-zone> <server-fqdn>
```

Ví dụ mạng `192.168.10.0/24`:

```bash
sudo ./bin/netadmin dns zone add-reverse \
  10.168.192.in-addr.arpa ns1.lab.local
```

Command nhận tên reverse zone đã chuyển đổi, không nhận CIDR. Sau đó thêm PTR bằng record command:

```bash
sudo ./bin/netadmin dns record add \
  10.168.192.in-addr.arpa 20 PTR www.lab.local.
```

### 5.5 Secondary zone

```bash
sudo ./bin/netadmin dns zone add-secondary <domain> <primary-ip>
```

Ví dụ:

```bash
sudo ./bin/netadmin dns zone add-secondary lab.local 192.168.10.2
```

Tool tạo thư mục `/var/named/slaves` với quyền cho `named` và khai báo slave zone. Primary phải cho phép zone transfer tới IP của secondary.

### 5.6 Liệt kê và xóa zone

```bash
./bin/netadmin dns zone list
sudo ./bin/netadmin dns zone remove <domain-or-reverse-zone>
```

`list` chỉ hiện zone có marker NetAdmin. Khi xóa master zone, zone file không bị xóa vĩnh viễn mà được đổi tên với hậu tố `.removed.<epoch>`.

### 5.7 Quản lý record

```bash
sudo ./bin/netadmin dns record add \
  <zone> <name> <A|AAAA|CNAME|MX|NS|TXT|PTR> <value> [ttl]

./bin/netadmin dns record list <zone>

sudo ./bin/netadmin dns record remove <zone> <name> <type>
```

Ví dụ:

```bash
sudo ./bin/netadmin dns record add lab.local www A 192.168.10.20
sudo ./bin/netadmin dns record add lab.local files CNAME www.lab.local.
sudo ./bin/netadmin dns record add lab.local @ MX '10 mail.lab.local.'
sudo ./bin/netadmin dns record add lab.local @ TXT 'network administration lab'
```

Quy tắc:

- TTL mặc định là `3600` giây.
- Tên record nhận identifier, `@` hoặc `*`.
- Giá trị `MX` phải có dạng `<priority> <hostname>` và nên đặt trong dấu nháy shell.
- TXT được tool đặt trong dấu nháy trong zone file.
- Sau mỗi thay đổi, serial tăng đơn điệu và `named-checkzone` được chạy.
- `record list` in nguyên nội dung zone file, gồm cả SOA/NS.

### 5.8 Cho phép zone transfer

```bash
sudo ./bin/netadmin dns transfer allow <zone> <secondary-ip>
```

Command thêm hoặc thay thế `allow-transfer` trong master zone do NetAdmin quản lý. Cần chạy trên primary DNS.

### 5.9 Forwarders

```bash
sudo ./bin/netadmin dns forwarders set 1.1.1.1,8.8.8.8
sudo ./bin/netadmin dns forwarders clear
```

`set` chèn directive `forwarders` có marker vào block `options` đầu tiên trong `named.conf`. `clear` chỉ xóa dòng forwarder do NetAdmin tạo.

### 5.10 Truy vấn, cấu hình và service

```bash
./bin/netadmin dns query <name> [server-ip]
./bin/netadmin dns config show
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns config rollback
sudo ./bin/netadmin dns service <start|stop|restart|status|enable|enable-now>
```

- `query` dùng `dig`; nếu có server, truy vấn dạng `dig @server name`.
- `config show` in cả `named.conf` và fragment zone managed.
- `config rollback` chỉ khôi phục backup gần nhất của `named.conf`; zone file có backup riêng trong cùng thư mục backup DNS.
- Thao tác tạo/sửa zone tự rollback khi validator báo lỗi.

## 6. Storage

> Partition, format và LVM có thể làm mất dữ liệu. Kiểm tra thiết bị bằng `lsblk`, sao lưu dữ liệu và tuyệt đối không chọn disk hệ điều hành nếu không chủ đích.

### 6.1 Khảo sát disk

```bash
./bin/netadmin storage disk list
./bin/netadmin storage disk free <device>
```

- `disk list`: dùng `lsblk`, hiển thị path, size, type, filesystem, mountpoint và model; loại loop device major 7.
- `disk free`: dùng `parted` hiển thị partition và vùng trống theo GiB.

### 6.2 Tạo partition

```bash
sudo ./bin/netadmin storage partition create \
  <device> <start> <end> [gpt|msdos]
```

Ví dụ:

```bash
sudo ./bin/netadmin storage partition create /dev/sdb 1MiB 100% gpt
```

`start` và `end` nhận số kèm `MiB`, `GiB`, `MB`, `GB` hoặc `%`. Nếu truyền `gpt`/`msdos`, tool chạy `mklabel` trước và bảng partition hiện có sẽ bị thay thế. Tool yêu cầu nhập lại chính xác device, chạy `partprobe` và chờ `udevadm settle`.

### 6.3 Format filesystem

```bash
sudo ./bin/netadmin storage filesystem format \
  <partition> <xfs|ext4|ext3> [label]
```

Tool từ chối format device đang mount và yêu cầu nhập lại device. XFS dùng `mkfs.xfs -f`; ext dùng `mkfs.ext* -F`.

### 6.4 Mount persistent

```bash
sudo ./bin/netadmin storage filesystem mount \
  <partition> <mountpoint> [options]
```

Ví dụ:

```bash
sudo ./bin/netadmin storage filesystem mount /dev/sdb1 /data defaults
```

Tool đọc UUID và filesystem bằng `blkid`, tạo mountpoint, ghi dòng `UUID=...` vào `/etc/fstab`, rồi mount. Nó từ chối nếu mountpoint đã có entry active trong fstab.

Liệt kê filesystem và mount thực:

```bash
./bin/netadmin storage filesystem list
```

### 6.5 LVM

Cài dependency:

```bash
sudo ./bin/netadmin storage lvm install
```

Liệt kê PV/VG/LV:

```bash
sudo ./bin/netadmin storage lvm list
```

Tạo PV:

```bash
sudo ./bin/netadmin storage lvm pv-create /dev/sdb1
```

`pv-create` là thao tác phá hủy và yêu cầu nhập lại partition.

Tạo hoặc mở rộng VG:

```bash
sudo ./bin/netadmin storage lvm vg-create vg_lab /dev/sdb1
sudo ./bin/netadmin storage lvm vg-extend vg_lab /dev/sdc1
```

Tạo LV:

```bash
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_data 10G
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_rest 100%FREE
```

Mở rộng LV và filesystem:

```bash
sudo ./bin/netadmin storage lvm lv-extend /dev/vg_lab/lv_data +5G
sudo ./bin/netadmin storage lvm lv-extend /dev/vg_lab/lv_data +100%FREE
```

Kích thước dạng `%` dùng extent (`-l`), các dạng còn lại dùng byte size (`-L`). Sau `lvextend`, tool tự chạy:

- `xfs_growfs <mountpoint>` cho XFS đang mount.
- `resize2fs <lv-path>` cho ext2/ext3/ext4.
- Chỉ cảnh báo với filesystem chưa hỗ trợ.

### 6.6 Quota

Bật quota:

```bash
sudo ./bin/netadmin storage quota enable <mountpoint>
```

Tool cài package `quota`, thêm option vào fstab và remount:

- XFS: `uquota,gquota`.
- Filesystem khác: `usrquota,grpquota`, sau đó chạy `quotacheck` và `quotaon`.

Đặt giới hạn user:

```bash
sudo ./bin/netadmin storage quota set \
  <mountpoint> <user> \
  <soft-blocks> <hard-blocks> <soft-inodes> <hard-inodes>
```

Ví dụ:

```bash
sudo ./bin/netadmin storage quota set /data student 102400 122880 1000 1200
```

Các giới hạn là số nguyên không âm. Đơn vị block phụ thuộc implementation quota/filesystem; kiểm tra kết quả bằng:

```bash
sudo ./bin/netadmin storage quota report /data
```

## 7. Samba

### 7.1 Cài đặt

```bash
sudo ./bin/netadmin samba install
```

Cài `samba`, `samba-common`, `samba-common-tools`, `samba-client`, `cifs-utils`; tạo cấu hình cơ bản nếu chưa tồn tại; enable `smb`/`nmb`; và mở Samba trong firewalld. Tool không start service trước khi có share.

### 7.2 Public share

```bash
sudo ./bin/netadmin samba share add-public \
  <name> <path> [read-only|read-write]
```

Ví dụ:

```bash
sudo ./bin/netadmin samba share add-public public /srv/samba/public read-only
```

Tool tạo thư mục, đặt owner `nobody:nobody`, mode `0755` cho read-only hoặc `0777` cho read-write, rồi tạo guest share. Public read-write chỉ nên dùng trong mạng lab đáng tin cậy.

### 7.3 Share bảo vệ theo group

```bash
sudo ./bin/netadmin samba share add-group \
  <name> <path> <group> [read-only|read-write]
```

Ví dụ:

```bash
sudo ./bin/netadmin samba share add-group \
  lessons /data/lessons labusers read-write
```

Group Linux phải tồn tại. Tool đặt owner `root:<group>`, setgid directory và chỉ cho `@group` truy cập. Mode mặc định là `read-write`.

Với SELinux đang bật, tool dùng `semanage fcontext` + `restorecon` nếu có; nếu không, fallback sang `chcon` và cảnh báo context có thể mất sau relabel.

### 7.4 Liệt kê và xóa share

```bash
./bin/netadmin samba share list
sudo ./bin/netadmin samba share remove <name>
```

`remove` chỉ xóa block trong `smb.conf`, không xóa thư mục hoặc dữ liệu của share.

### 7.5 Samba user

```bash
sudo ./bin/netadmin samba user add <username> <group>
sudo ./bin/netadmin samba user remove <username>
sudo ./bin/netadmin samba user list
```

`user add`:

1. Tạo group nếu chưa tồn tại.
2. Tạo Linux user không home, shell `/sbin/nologin`, nếu user chưa tồn tại.
3. Thêm user vào group.
4. Chạy `smbpasswd -a` để nhập mật khẩu Samba.

`user remove` chỉ chạy `smbpasswd -x`; Linux user và dữ liệu của họ được giữ lại. `user list` dùng `pdbedit -L -v`.

### 7.6 Read/write list

```bash
sudo ./bin/netadmin samba permissions grant \
  <share> <username|@group> <read|write>
```

Ví dụ:

```bash
sudo ./bin/netadmin samba permissions grant lessons @teachers write
```

Command ghi `read list` hoặc `write list` vào block share. Mỗi lần gọi sẽ thay thế dòng read/write list trước đó do command quản lý; muốn nhiều principal, nên dùng group Samba/Linux và cấp cho `@group`.

### 7.7 Kiểm tra và áp dụng cấu hình

```bash
./bin/netadmin samba config show
sudo ./bin/netadmin samba config check
sudo ./bin/netadmin samba config apply
sudo ./bin/netadmin samba config rollback
```

| Command | Mô tả |
|---|---|
| `show` | In `smb.conf` |
| `check` | Chạy và hiển thị `testparm -s` |
| `apply` | Kiểm tra rồi restart `smb` và `nmb` |
| `rollback` | Khôi phục backup `smb.conf` gần nhất, có hỏi xác nhận |

Tạo/xóa share hoặc đổi permission chưa tự restart service; gọi `config apply` khi sẵn sàng áp dụng.

### 7.8 Service và giám sát

```bash
sudo ./bin/netadmin samba service <start|stop|restart|status|enable|enable-now>
sudo ./bin/netadmin samba status
sudo ./bin/netadmin samba sessions
```

- `status` tương đương trạng thái service `smb`.
- Các service action ngoài `status` được áp dụng cho cả `smb` và `nmb`.
- `sessions` chạy `smbstatus`, hiển thị client, file lock và kết nối hiện tại.

### 7.9 SMB client

Liệt kê nội dung share:

```bash
./bin/netadmin samba client list //<server>/<share> [username]
```

Không truyền username thì dùng guest. Có username thì `smbclient` tự hỏi password.

Sao chép một file hoặc thư mục từ share:

```bash
sudo ./bin/netadmin samba client copy \
  //<server>/<share> <remote-item> <destination> [username]
```

Ví dụ:

```bash
sudo ./bin/netadmin samba client copy \
  //192.168.10.5/Lessons week01 /data/import student
```

Tool mount CIFS vào thư mục tạm, hỏi password không echo nếu có username, sao chép bằng `cp -a`, unmount và xóa credential tạm. Cleanup cũng chạy khi command kết thúc bất thường.

## 8. Backup, rollback và marker

Backup mặc định:

```text
/var/backups/netadmin/
├── dhcp/
├── dns/
├── storage/
└── samba/
```

Tên file có timestamp `YYYYMMDD-HHMMSS`. Các command `config rollback` chọn file mới nhất có cùng basename.

Các block do toolkit quản lý có dạng:

```text
# NETADMIN:SCOPE:<name>:BEGIN
...
# NETADMIN:SCOPE:<name>:END
```

DNS dùng comment `//`, Samba dùng `#`. Không đổi hoặc xóa marker thủ công nếu vẫn muốn quản lý block bằng CLI.

## 9. Exit code và xử lý lỗi

- `0`: thành công.
- Khác `0`: validation, dependency hoặc command hệ thống thất bại.
- Khi Bash gặp lỗi ngoài dự kiến, tool in command và số dòng gây lỗi.
- Các thay đổi cấu hình quan trọng được validator native xác nhận trước khi báo thành công.
- Service không tự restart sau mọi thay đổi; điều này cho phép gom nhiều thay đổi rồi apply một lần.
