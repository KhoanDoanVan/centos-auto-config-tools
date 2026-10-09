# Chương 7 — Runbook kiểm thử trên CentOS

Runbook này hướng dẫn dựng lab và kiểm thử thực tế từng module. Hãy làm tuần tự và không bỏ qua cảnh báo Storage.

## 1. Mô hình lab

Chuẩn bị hai VM và hai disk phụ:

```text
Internet
   |
NAT NIC
   |
SERVER CentOS 7
  NIC 1: NAT/DHCP, dùng cài package
  NIC 2: 192.168.10.2/24, mạng NETADMIN-LAB
  Disk OS: tuyệt đối không thao tác
  Disk B: 10 GiB rỗng, test filesystem
  Disk C: 10 GiB rỗng, test LVM
   |
Internal/Host-only network: NETADMIN-LAB
   |
CLIENT CentOS 7
  NIC 1: DHCP
```

Giá trị dùng xuyên suốt:

| Thành phần | Giá trị |
|---|---|
| Mạng lab | `192.168.10.0/24` |
| Server | `192.168.10.2` |
| Gateway phát cho client | `192.168.10.1` |
| DHCP range | `192.168.10.100–192.168.10.200` |
| Domain | `lab.test` |
| Reverse zone | `10.168.192.in-addr.arpa` |

`.test` tránh xung đột với domain Internet thật hoặc multicast DNS `.local`.

## 2. Chuẩn bị hypervisor an toàn

Server cần 2 GiB RAM, 1–2 vCPU, một disk OS và hai disk rỗng. Client cần 1–2 GiB RAM và một NIC cùng mạng lab.

Các điều kiện bắt buộc:

- Tắt DHCP của VirtualBox/VMware trên `NETADMIN-LAB`; chỉ DHCP đang test được phép phát IP.
- Tạo snapshot `clean-os` và `before-netadmin`.
- Có quyền mở console VM; không phụ thuộc duy nhất vào SSH.
- Hai disk phụ không chứa dữ liệu.
- Dùng Internal Network/LAN Segment nếu không chắc host-only DHCP đã tắt.

## 3. Chuẩn bị CentOS Server

### 3.1 Kiểm tra hệ điều hành và repository

```bash
cat /etc/centos-release
bash --version | head -n1
ip address
ip route
ping -c 3 1.1.1.1
sudo yum makecache
```

PASS khi NIC NAT có IP/default route, ping IP ngoài được và `yum makecache` thành công. Nếu repository CentOS 7 không hoạt động, hãy cấu hình mirror/vault do lớp học hoặc tổ chức cung cấp trước; toolkit không cài được dependency khi `yum` hỏng.

```bash
sudo yum install -y \
  bash coreutils findutils grep gawk sed iproute \
  NetworkManager firewalld git vim \
  parted xfsprogs e2fsprogs

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now firewalld
```

### 3.2 Chép project

Nếu có Git server:

```bash
cd ~
git clone <repository-url> centos-auto-config-tool
cd centos-auto-config-tool
```

Hoặc từ máy đang chứa project:

```bash
scp -r centos-auto-config-tool <user>@<server-ip>:~/
```

Internal Network thuần túy thường không truy cập được từ host; khi đó dùng shared folder, ISO hoặc NAT port forwarding.

```bash
cd ~/centos-auto-config-tool
chmod +x bin/netadmin
./bin/netadmin version
./bin/netadmin help
```

PASS khi thấy `netadmin 1.0.0` và danh sách module.

## 4. Ghi topology thật

```bash
nmcli device status
nmcli connection show
ip -4 address
ip route
```

Điền trước khi tiếp tục:

| Vai trò | Interface | Connection profile |
|---|---|---|
| NAT/Internet | `________` | `________________` |
| NETADMIN-LAB | `________` | `________________` |

Ví dụ sau dùng interface `enp0s8` và profile `System enp0s8`. Máy bạn có thể dùng `ens33`, `ens37` hoặc tên khác; luôn thay bằng giá trị thật.

## 5. Test Doctor và CLI

```bash
./bin/netadmin doctor
./bin/netadmin dhcp help
./bin/netadmin dns help
./bin/netadmin storage help
./bin/netadmin samba help
```

PASS khi Doctor không báo dependency nền bị thiếu và mọi module hiện help.

```text
[ ] PASS  [ ] FAIL — Doctor/CLI
Ghi chú: ______________________________________________
```

## 6. Test cấu hình IP tĩnh

Ngăn NIC lab chiếm default route của NIC NAT:

```bash
sudo nmcli connection modify 'System enp0s8' ipv4.never-default yes
```

Dùng toolkit:

```bash
./bin/netadmin dns network list

sudo ./bin/netadmin dns network static \
  'System enp0s8' 192.168.10.2/24 \
  192.168.10.1 127.0.0.1,1.1.1.1
```

Kiểm tra:

```bash
ip -4 address show enp0s8
ip route
nmcli -f ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.never-default \
  connection show 'System enp0s8'
ping -c 3 1.1.1.1
```

PASS khi NIC lab có `192.168.10.2/24`, `never-default=yes`, default route vẫn qua NIC NAT và Internet còn hoạt động. Nên thực hiện từ console vì active connection có thể ngắt SSH.

## 7. Chuẩn bị Client

Trên client, tìm connection name:

```bash
nmcli device status
nmcli connection show
```

Đặt nhận DHCP:

```bash
sudo nmcli connection modify '<client-connection>' \
  ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns ''
```

Cài client tools trước khi chuyển hoàn toàn sang mạng cô lập nếu cần:

```bash
sudo yum install -y bind-utils samba-client cifs-utils
```

## 8. Test DHCP

### 8.1 Cài và giới hạn interface

Trên server:

```bash
sudo ./bin/netadmin dhcp install
rpm -q dhcp
sudo firewall-cmd --list-services
```

Mở `/etc/sysconfig/dhcpd`:

```bash
sudo vim /etc/sysconfig/dhcpd
```

Đặt NIC lab thật:

```text
DHCPDARGS="enp0s8"
```

Điều này tránh phục vụ DHCP trên NIC NAT. Có thể dùng `systemctl cat dhcpd` để xác nhận unit đọc `DHCPDARGS`.

### 8.2 Tạo scope và start

```bash
sudo ./bin/netadmin dhcp scope add \
  lab-lan 192.168.10.0 255.255.255.0 \
  192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2 lab.test 600

./bin/netadmin dhcp scope list
sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp service enable-now
sudo ./bin/netadmin dhcp service status
sudo ss -lunp | grep ':67'
```

### 8.3 Xin lease từ client

Trên client:

```bash
sudo nmcli connection down '<client-connection>'
sudo nmcli connection up '<client-connection>'
ip -4 address
ip route
cat /etc/resolv.conf
ping -c 3 192.168.10.2
```

PASS khi client nhận IP `192.168.10.100–200`, prefix `/24`, gateway `.1`, DNS `.2` và ping server được.

Trên server:

```bash
sudo ./bin/netadmin dhcp lease list
```

### 8.4 Test reservation

Lấy MAC thật bằng `ip link` trên client. Ví dụ nếu là `08:00:27:aa:bb:cc`:

```bash
sudo ./bin/netadmin dhcp reservation add \
  client01 08:00:27:aa:bb:cc 192.168.10.50 client01

./bin/netadmin dhcp reservation list
sudo ./bin/netadmin dhcp service restart
```

Reconnect client. PASS khi nhận `.50`. Nếu còn lease cũ, reconnect/release hoặc chờ hết lease; không dùng MAC mẫu thay MAC thật.

## 9. Test DNS/BIND

### 9.1 Cài và cho phép mạng lab truy vấn

```bash
sudo ./bin/netadmin dns install
sudo cp -a /etc/named.conf /etc/named.conf.before-lab
sudo vim /etc/named.conf
```

CentOS 7 thường chỉ cho localhost. Trong block `options`, sửa directive hiện có, không thêm bản trùng:

```text
listen-on port 53 { 127.0.0.1; 192.168.10.2; };
allow-query     { localhost; 192.168.10.0/24; };
```

```bash
sudo ./bin/netadmin dns config check
```

### 9.2 Tạo zone và record

```bash
sudo ./bin/netadmin dns zone add lab.test 192.168.10.2
sudo ./bin/netadmin dns zone add-reverse \
  10.168.192.in-addr.arpa ns1.lab.test
sudo ./bin/netadmin dns record add lab.test files A 192.168.10.2
sudo ./bin/netadmin dns record add \
  10.168.192.in-addr.arpa 2 PTR files.lab.test.

./bin/netadmin dns zone list
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns service enable-now
sudo ss -lntup | grep ':53'
```

### 9.3 Query server và client

Trên server:

```bash
./bin/netadmin dns query files.lab.test 192.168.10.2
dig @192.168.10.2 -x 192.168.10.2
```

Trên client:

```bash
dig @192.168.10.2 files.lab.test A
dig @192.168.10.2 -x 192.168.10.2
dig files.lab.test A
```

PASS khi forward trả `192.168.10.2`, reverse trả `files.lab.test.` và dòng `SERVER` là `192.168.10.2#53`.

Test forwarder tùy chọn:

```bash
sudo ./bin/netadmin dns forwarders set 1.1.1.1,8.8.8.8
sudo ./bin/netadmin dns service restart
./bin/netadmin dns query example.com 192.168.10.2
```

## 10. Test Storage filesystem trực tiếp

> DỪNG và xác minh disk. `/dev/sdb` chỉ là ví dụ.

```bash
findmnt /
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
```

Điền:

```text
Disk chứa /: __________________  KHÔNG CHỌN
Disk B rỗng: __________________
Disk C rỗng: __________________
```

Nếu không chắc, dừng và kiểm tra hypervisor.

Giả sử Disk B thật sự là `/dev/sdb`:

```bash
./bin/netadmin storage disk free /dev/sdb
sudo ./bin/netadmin storage partition create /dev/sdb 1MiB 100% gpt
sudo ./bin/netadmin storage filesystem format /dev/sdb1 xfs DATA
sudo ./bin/netadmin storage filesystem mount /dev/sdb1 /data defaults

df -h /data
sudo blkid /dev/sdb1
grep '/data' /etc/fstab
```

Test persistent mount:

```bash
sudo touch /data/netadmin-storage-test
sudo umount /data
sudo mount /data
test -f /data/netadmin-storage-test && echo 'PASS: data persisted'
```

## 11. Test LVM và quota

> Dùng Disk C riêng; giả sử là `/dev/sdc`. Không dùng lại `/dev/sdb`.

```bash
sudo ./bin/netadmin storage partition create /dev/sdc 1MiB 100% gpt
sudo ./bin/netadmin storage lvm install
sudo ./bin/netadmin storage lvm pv-create /dev/sdc1
sudo ./bin/netadmin storage lvm vg-create vg_lab /dev/sdc1
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_quota 5G
sudo ./bin/netadmin storage lvm list

sudo ./bin/netadmin storage filesystem format \
  /dev/vg_lab/lv_quota xfs QUOTA
sudo ./bin/netadmin storage filesystem mount \
  /dev/vg_lab/lv_quota /quota-data defaults
```

Mở rộng và xác nhận cả LV lẫn filesystem tăng:

```bash
sudo lvs
df -h /quota-data
sudo ./bin/netadmin storage lvm lv-extend \
  /dev/vg_lab/lv_quota +1G
sudo lvs
df -h /quota-data
```

Quota:

```bash
id student >/dev/null 2>&1 || sudo useradd student
sudo ./bin/netadmin storage quota enable /quota-data
findmnt -no SOURCE,FSTYPE,OPTIONS /quota-data

sudo ./bin/netadmin storage quota set \
  /quota-data student 102400 122880 1000 1200
sudo ./bin/netadmin storage quota report /quota-data
```

PASS khi mount options có quota và report có user `student` cùng limit đã đặt.

Một số phiên bản XFS không kích hoạt quota bằng remount. Nếu `findmnt` chưa thấy `uquota`, bảo đảm fstab đã có option rồi unmount/mount lại khi không có process sử dụng filesystem:

```bash
sudo umount /quota-data
sudo mount /quota-data
findmnt -no SOURCE,FSTYPE,OPTIONS /quota-data
```

## 12. Test Samba

### 12.1 Cài, tạo share và user

```bash
sudo ./bin/netadmin samba install

sudo mkdir -p /data/public
echo 'NetAdmin public test' | sudo tee /data/public/readme.txt
sudo ./bin/netadmin samba share add-public \
  public /data/public read-only

sudo ./bin/netadmin samba user add student labusers
sudo ./bin/netadmin samba share add-group \
  lessons /data/lessons labusers read-write

sudo ./bin/netadmin samba config check
./bin/netadmin samba share list
sudo ./bin/netadmin samba config apply
sudo ./bin/netadmin samba service enable
sudo ss -lntp | grep ':445'
```

Nhập và ghi nhớ password Samba khi `samba user add` hỏi.

### 12.2 Test local và từ client

Trên server:

```bash
./bin/netadmin samba client list //127.0.0.1/public
./bin/netadmin samba client list //127.0.0.1/lessons student
```

Trên client:

```bash
smbclient //192.168.10.2/public -N -c ls
smbclient //192.168.10.2/lessons -U student -c ls

echo 'hello from client' > /tmp/client-test.txt
smbclient //192.168.10.2/lessons -U student \
  -c 'put /tmp/client-test.txt client-test.txt; ls'
```

Trên server kiểm tra file và session:

```bash
ls -lZ /data/lessons/client-test.txt
sudo ./bin/netadmin samba sessions
```

Test client copy của toolkit:

```bash
sudo mkdir -p /tmp/netadmin-copy-result
sudo ./bin/netadmin samba client copy \
  //127.0.0.1/lessons client-test.txt \
  /tmp/netadmin-copy-result student
ls -l /tmp/netadmin-copy-result/client-test.txt
mount | grep cifs
```

PASS khi file copy được và không còn CIFS mount tạm.

## 13. Test backup và rollback

```bash
sudo find /var/backups/netadmin -maxdepth 3 -type f -print | sort
```

Test Samba rollback ít rủi ro:

```bash
sudo ./bin/netadmin samba share add-public \
  rollback-demo /data/rollback-demo read-only
./bin/netadmin samba share list

sudo ./bin/netadmin samba config rollback
sudo ./bin/netadmin samba config check
./bin/netadmin samba share list
```

PASS khi `rollback-demo` biến mất khỏi config. Thư mục dữ liệu vẫn còn vì rollback không xóa data.

## 14. Kiểm thử mở rộng các command còn lại

Phần trên là smoke test chính. Các test dưới đây tăng độ phủ nhưng chỉ nên chạy sau khi mọi mục chính đã PASS và đã có snapshot.

### Dry-run

```bash
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin dhcp service restart
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin dns service restart
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin samba service restart
```

PASS khi chỉ thấy `[DRY-RUN]` và service không bị restart.

### DHCP update và reservation remove

```bash
sudo ./bin/netadmin dhcp scope update \
  lab-lan 192.168.10.0 255.255.255.0 \
  192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2 lab.test 900
sudo ./bin/netadmin dhcp config check

sudo ./bin/netadmin dhcp reservation remove client01
./bin/netadmin dhcp reservation list
```

Không test `lease release` mặc định: command đó cần OMAPI trên `localhost:7911`, trong khi runbook chưa cấu hình authentication/listener OMAPI.

### DNS record remove và zone remove

```bash
sudo ./bin/netadmin dns record add lab.test alias CNAME files.lab.test.
sudo ./bin/netadmin dns record add lab.test @ TXT 'netadmin-test'
./bin/netadmin dns record list lab.test
sudo ./bin/netadmin dns record remove lab.test alias CNAME

sudo ./bin/netadmin dns zone add demo.test 192.168.10.2
./bin/netadmin dns zone list
sudo ./bin/netadmin dns zone remove demo.test
./bin/netadmin dns zone list
```

PASS khi record/zone xuất hiện rồi biến mất; zone file bị đổi tên `.removed.<epoch>` thay vì xóa.

Test secondary DNS và `transfer allow` cần VM DNS thứ ba, ví dụ `192.168.10.3`. Secondary cũng phải có IP tĩnh, firewall DNS, `listen-on` và `allow-query` cho mạng lab tương tự primary. Chỉ thực hiện sau khi primary lab ổn định:

```bash
# Trên primary
sudo ./bin/netadmin dns transfer allow lab.test 192.168.10.3

# Trên secondary đã cài DNS
sudo ./bin/netadmin dns zone add-secondary lab.test 192.168.10.2
sudo ./bin/netadmin dns service restart
dig @192.168.10.3 files.lab.test A
```

### Samba permission và share remove

```bash
sudo ./bin/netadmin samba permissions grant lessons @labusers write
sudo ./bin/netadmin samba config apply
sudo ./bin/netadmin samba share remove public
./bin/netadmin samba share list
sudo ./bin/netadmin samba config apply
```

`share remove` không xóa `/data/public` hoặc `readme.txt`.

### Network DHCP mode

Không chạy `dns network dhcp` trên NIC lab đang phục vụ DHCP/DNS vì server sẽ mất IP tĩnh. Nếu muốn kiểm thử, snapshot trước và chỉ dùng một connection phụ không phục vụ dịch vụ:

```bash
sudo ./bin/netadmin dns network dhcp '<temporary-connection>'
```

### Service stop/start

Có thể test ở cuối lab; client sẽ mất dịch vụ trong khoảng stop:

```bash
sudo ./bin/netadmin dhcp service stop
sudo ./bin/netadmin dhcp service start
sudo ./bin/netadmin dns service stop
sudo ./bin/netadmin dns service start
sudo ./bin/netadmin samba service stop
sudo ./bin/netadmin samba service start
```

## 15. Checklist tổng kết

| ID | Hạng mục | PASS | FAIL | Ghi chú |
|---:|---|:---:|:---:|---|
| 1 | CLI và Doctor | ☐ | ☐ | |
| 2 | Static IP NIC lab | ☐ | ☐ | |
| 3 | DHCP dynamic lease | ☐ | ☐ | |
| 4 | DHCP reservation | ☐ | ☐ | |
| 5 | DNS forward/reverse | ☐ | ☐ | |
| 6 | DNS từ client | ☐ | ☐ | |
| 7 | Partition/format/mount | ☐ | ☐ | |
| 8 | Persistent fstab mount | ☐ | ☐ | |
| 9 | LVM create/extend | ☐ | ☐ | |
| 10 | Quota | ☐ | ☐ | |
| 11 | Samba public share | ☐ | ☐ | |
| 12 | Samba authenticated/write | ☐ | ☐ | |
| 13 | Toolkit SMB client copy | ☐ | ☐ | |
| 14 | Backup/rollback | ☐ | ☐ | |

## 16. Thu thập thông tin khi FAIL

Thông tin chung:

```bash
date
cat /etc/centos-release
./bin/netadmin version
./bin/netadmin doctor
ip address
ip route
sudo firewall-cmd --list-all
```

DHCP:

```bash
sudo ./bin/netadmin dhcp config check
sudo systemctl status dhcpd -l --no-pager
sudo journalctl -u dhcpd --no-pager -n 100
sudo ss -lunp | grep ':67'
```

DNS:

```bash
sudo ./bin/netadmin dns config check
sudo systemctl status named -l --no-pager
sudo journalctl -u named --no-pager -n 100
sudo ss -lntup | grep ':53'
```

Storage:

```bash
lsblk -f
findmnt
sudo pvs
sudo vgs
sudo lvs -a -o +devices
```

Samba:

```bash
sudo testparm -s
sudo systemctl status smb nmb -l --no-pager
sudo journalctl -u smb --no-pager -n 100
sudo smbstatus
ls -ldZ /data/public /data/lessons
id student
```

Khi gửi lỗi, kèm command chính xác, toàn bộ output, ID checklist, distro/version và tên interface. Với Storage, gửi `lsblk` nhưng không format lại để “thử”.

## 17. Kết thúc lab

Lưu checklist rồi shutdown sạch:

```bash
sudo shutdown -h now
```

Tạo snapshot `netadmin-tests-complete` để giữ kết quả, hoặc restore `before-netadmin` để làm lại. Không cần chạy lệnh xóa disk/LVM hàng loạt chỉ để reset lab; restore snapshot an toàn hơn.
