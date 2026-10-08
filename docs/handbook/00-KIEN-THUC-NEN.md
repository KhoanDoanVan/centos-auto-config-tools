# Chương 0 — Kiến thức nền cho người mới

Chương này không giả định bạn đã học mạng hoặc quản trị Linux. Hãy đọc chương này trước khi chạy DHCP, DNS, Storage hoặc Samba.

## 1. Server, client và dịch vụ là gì?

Một **server** là máy cung cấp một chức năng cho máy khác. Máy sử dụng chức năng đó gọi là **client**.

Ví dụ:

- DHCP server phát địa chỉ IP; laptop xin IP là DHCP client.
- DNS server trả lời tên `www.lab.local` nằm ở IP nào; trình duyệt là DNS client.
- Samba server chia sẻ thư mục; máy Windows mở thư mục đó là SMB client.

Một máy vật lý có thể chạy nhiều dịch vụ cùng lúc. Trong Linux, mỗi dịch vụ thường có:

- Một hoặc nhiều **package** chứa chương trình.
- Một **file cấu hình** mô tả cách chạy.
- Một **service** chạy nền.
- Một hoặc nhiều **port mạng** để nhận yêu cầu.
- Quy tắc **firewall** cho phép traffic đi qua.

Ví dụ với DNS BIND:

```text
package bind
    ↓ cung cấp
chương trình named
    ↓ đọc
/etc/named.conf và các zone file
    ↓ lắng nghe
TCP/UDP port 53
```

## 2. Quyền root và `sudo`

Linux bảo vệ file hệ thống, service, network và disk. User thông thường không được tự ý thay đổi chúng.

- `root` là tài khoản quản trị cao nhất.
- `sudo <command>` chạy một command với quyền quản trị.
- `EUID=0` nghĩa là process hiện tại đang chạy với quyền root.

Ví dụ chỉ đọc trợ giúp, không cần root:

```bash
./bin/netadmin dhcp help
```

Ví dụ cài DHCP, cần root:

```bash
sudo ./bin/netadmin dhcp install
```

Không chạy toàn bộ terminal bằng root nếu không cần thiết. Hãy thêm `sudo` cho đúng command cần thay đổi hệ thống.

## 3. Địa chỉ IPv4

IPv4 là địa chỉ gồm bốn số từ `0` đến `255`, phân cách bằng dấu chấm:

```text
192.168.10.20
```

Một địa chỉ IP có hai phần:

- Phần **network** cho biết thiết bị thuộc mạng nào.
- Phần **host** phân biệt từng thiết bị trong mạng đó.

Subnet mask quyết định ranh giới giữa hai phần. Ví dụ:

```text
IP:          192.168.10.20
Netmask:     255.255.255.0
CIDR:        192.168.10.20/24
Network:     192.168.10.0
Broadcast:   192.168.10.255
Host dùng:   192.168.10.1 đến 192.168.10.254
```

`/24` nghĩa là 24 bit đầu thuộc phần network. Những netmask thường gặp:

| CIDR | Netmask | Số địa chỉ | Host thường dùng được |
|---:|---|---:|---:|
| `/8` | `255.0.0.0` | 16.777.216 | 16.777.214 |
| `/16` | `255.255.0.0` | 65.536 | 65.534 |
| `/24` | `255.255.255.0` | 256 | 254 |
| `/25` | `255.255.255.128` | 128 | 126 |
| `/26` | `255.255.255.192` | 64 | 62 |
| `/27` | `255.255.255.224` | 32 | 30 |
| `/28` | `255.255.255.240` | 16 | 14 |

Trong mạng `/24`, địa chỉ cuối `.0` thường là network address và `.255` là broadcast. Không cấp hai địa chỉ này cho client.

## 4. Gateway, DNS và MAC

### Gateway

**Default gateway** là router mà máy gửi packet tới khi đích nằm ngoài mạng cục bộ.

Ví dụ client `192.168.10.20/24` muốn truy cập `8.8.8.8`. Vì `8.8.8.8` không thuộc `192.168.10.0/24`, client chuyển packet cho gateway, ví dụ `192.168.10.1`.

Gateway phải nằm cùng subnet với client.

### DNS server

Con người nhớ tên như `server.lab.local`, còn máy truyền packet tới IP. DNS server chuyển tên thành IP và có thể làm chiều ngược lại.

DNS server không phải gateway. Một máy có thể là cả DNS server và gateway, nhưng hai vai trò khác nhau.

### MAC address

MAC nhận diện card mạng trong mạng LAN. Dạng thường gặp:

```text
00:11:22:33:44:55
```

DHCP dùng MAC để nhận ra client và có thể luôn phát cùng một IP cho card mạng đó.

## 5. Port và protocol

Một IP xác định máy; **port** xác định dịch vụ trên máy đó. TCP và UDP là hai protocol vận chuyển phổ biến.

| Dịch vụ | Protocol/port thường dùng |
|---|---|
| DHCP server | UDP 67 |
| DHCP client | UDP 68 |
| DNS | UDP 53, TCP 53 |
| SMB/Samba | TCP 445; NetBIOS có thể dùng 137–139 |
| SSH | TCP 22 |

UDP nhẹ và không thiết lập kết nối lâu dài. TCP có cơ chế kết nối, thứ tự và truyền lại. DNS thường dùng UDP cho truy vấn nhỏ, TCP cho response lớn hoặc zone transfer.

## 6. Firewall

Firewall quyết định traffic nào được phép vào hoặc ra. Trên CentOS/RHEL, `firewalld` là firewall phổ biến.

Toolkit không tắt firewall. Nó mở đúng service khi chạy command cài đặt:

```text
DHCP  → firewall-cmd --add-service=dhcp
DNS   → firewall-cmd --add-service=dns
Samba → firewall-cmd --add-service=samba
```

Nếu firewalld không chạy, toolkit cảnh báo và bỏ qua. Điều đó không đảm bảo firewall khác, router hoặc cloud security group đã cho phép traffic.

## 7. Service và systemd

`systemd` quản lý process chạy nền. `systemctl` là command điều khiển systemd.

Các trạng thái và hành động cơ bản:

| Hành động | Ý nghĩa |
|---|---|
| `start` | Chạy service ngay, không thay đổi lần boot sau |
| `stop` | Dừng service ngay |
| `restart` | Dừng rồi chạy lại; cần thiết khi chương trình không tự reload config |
| `status` | Xem trạng thái và log gần nhất |
| `enable` | Cho phép tự chạy ở những lần boot sau; chưa chắc chạy ngay |
| `enable-now` | Enable và start ngay |

`enable` và `start` không giống nhau. Đây là lỗi người mới thường gặp.

## 8. Package manager

Package manager tải và cài phần mềm cùng dependency:

- CentOS 7 thường dùng `yum`.
- RHEL/Rocky/Alma/Fedora mới thường dùng `dnf`.

Toolkit tự chọn `dnf` nếu có, nếu không mới dùng `yum`.

Ví dụ package `bind` cung cấp DNS server. Việc cài package không đồng nghĩa service đã chạy hoặc cấu hình đã đúng.

## 9. File cấu hình và validation

Service thường đọc file text. Một dấu `;`, `{` hoặc `}` sai vị trí có thể làm service không khởi động được.

Toolkit dùng validator chính thức trước khi chấp nhận thay đổi:

| Dịch vụ | Validator |
|---|---|
| DHCP | `dhcpd -t` |
| BIND tổng thể | `named-checkconf` |
| Một DNS zone | `named-checkzone` |
| Samba | `testparm` |

Quy trình an toàn:

```text
backup file cũ
    ↓
ghi cấu hình mới
    ↓
chạy validator
    ├── hợp lệ → giữ thay đổi
    └── lỗi     → tự khôi phục backup
```

## 10. Disk, partition, filesystem và mount

Bốn khái niệm này khác nhau:

```text
Disk vật lý /dev/sdb
    ↓ chia vùng
Partition /dev/sdb1
    ↓ format
Filesystem XFS hoặc ext4
    ↓ mount
Thư mục /data mà ứng dụng nhìn thấy
```

- **Disk**: thiết bị lưu trữ toàn bộ.
- **Partition**: một vùng liên tục trên disk.
- **Filesystem**: cấu trúc tổ chức file/thư mục trong partition hoặc logical volume.
- **Mount**: gắn filesystem vào một thư mục trong cây thư mục Linux.

Format tạo filesystem mới và thường làm dữ liệu cũ không còn truy cập được. Vì vậy toolkit yêu cầu nhập lại chính xác tên device.

`/etc/fstab` mô tả những filesystem cần mount tự động khi boot. Toolkit dùng UUID thay vì `/dev/sdb1`, vì tên `/dev/sdX` có thể thay đổi sau khi cắm thêm disk.

## 11. LVM là gì?

LVM thêm một lớp linh hoạt giữa disk và filesystem:

```text
Partition
   ↓ pvcreate
PV (Physical Volume)
   ↓ vgcreate/vgextend
VG (Volume Group: kho dung lượng)
   ↓ lvcreate
LV (Logical Volume)
   ↓ mkfs
Filesystem
```

Ưu điểm lớn nhất là có thể bổ sung disk vào VG và mở rộng LV. Nhưng mở rộng LV và mở rộng filesystem là hai bước khác nhau; toolkit thực hiện cả hai khi filesystem được hỗ trợ.

## 12. User, group và permission

Linux dùng user/group để kiểm soát file:

- **Owner**: user sở hữu.
- **Group**: nhóm sở hữu.
- **Mode**: quyền read/write/execute của owner, group và other.

Ví dụ mode `2770` trên thư mục:

- Owner: đọc, ghi, đi vào thư mục.
- Group: đọc, ghi, đi vào thư mục.
- Other: không có quyền.
- Bit `2` đầu tiên là setgid: file/thư mục con kế thừa group của thư mục cha.

Samba có hai lớp quyền:

1. Quyền trong `smb.conf` quyết định ai được truy cập qua mạng.
2. Quyền filesystem Linux quyết định process Samba có được đọc/ghi file thật hay không.

Cả hai lớp đều phải cho phép.

## 13. SELinux

SELinux là một lớp kiểm soát truy cập bổ sung, ngoài mode/owner. Một thư mục có `chmod 777` vẫn có thể bị Samba từ chối nếu SELinux context không đúng.

Toolkit gắn context `samba_share_t` cho thư mục share. Không nên tắt SELinux chỉ để chữa lỗi permission; nên sửa context đúng.

## 14. Cách đọc command trong tài liệu

Ví dụ:

```bash
netadmin dhcp scope add \
  <name> <subnet> <netmask> <start-ip> <end-ip> \
  <gateway> <dns[,dns]> [domain] [lease-seconds]
```

- Dấu `< >` chỉ tham số bắt buộc; không gõ dấu này.
- Dấu `[ ]` chỉ tham số tùy chọn; không gõ dấu này.
- Dấu `\` ở cuối dòng bảo Bash biết command vẫn tiếp tục ở dòng sau.

Command thật:

```bash
sudo ./bin/netadmin dhcp scope add \
  lab-lan 192.168.10.0 255.255.255.0 \
  192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2 lab.local 600
```

## 15. Lab mẫu dùng xuyên suốt tài liệu

Các chương sau dùng mô hình:

| Thành phần | Giá trị |
|---|---|
| Network | `192.168.10.0/24` |
| Gateway | `192.168.10.1` |
| DHCP/DNS server | `192.168.10.2` |
| DHCP range | `192.168.10.100–192.168.10.200` |
| Domain nội bộ | `lab.local` |
| File server | `192.168.10.20` / `files.lab.local` |
| Secondary DNS | `192.168.10.3` |

Đổi các IP này theo topology thực tế của bạn. Không copy nguyên nếu mạng đang dùng dải khác.

