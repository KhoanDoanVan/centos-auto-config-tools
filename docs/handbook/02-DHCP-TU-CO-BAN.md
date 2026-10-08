# Chương 2 — DHCP từ cơ bản đến từng command

## 1. Vấn đề DHCP giải quyết

Nếu không có DHCP, quản trị viên phải tới từng máy và nhập thủ công:

- IP address.
- Subnet mask.
- Default gateway.
- DNS server.
- Domain search.

Việc này chậm và dễ gây hai máy trùng IP. DHCP tự cấp các thông tin đó trong một khoảng do quản trị viên kiểm soát.

## 2. Quá trình DORA

Khi client chưa có IP, quá trình cơ bản gồm bốn bước:

```text
Client                           DHCP server
   |--- DHCPDISCOVER (broadcast) ---->|
   |<-- DHCPOFFER --------------------|
   |--- DHCPREQUEST ----------------->|
   |<-- DHCPACK ----------------------|
```

- **Discover**: client hỏi trong LAN xem có DHCP server không.
- **Offer**: server đề nghị một IP và các option.
- **Request**: client chọn một offer và yêu cầu IP đó.
- **ACK**: server xác nhận lease.

Lúc đầu client chưa có IP nên dùng broadcast. Router thông thường không chuyển broadcast sang mạng khác. Nếu client và DHCP server khác subnet, cần DHCP relay; toolkit hiện chưa cấu hình relay.

## 3. Scope, range, lease và reservation

### Scope

Scope là chính sách cấp IP cho một subnet. Nó gồm network, netmask, range, gateway, DNS và thời hạn lease.

### Range

Range là đoạn IP được cấp động, ví dụ `192.168.10.100` đến `192.168.10.200`.

Không nên đặt IP server, router, access point hoặc printer quan trọng bên trong range nếu bạn gán các thiết bị đó thủ công.

### Lease

Lease là quyền sử dụng IP trong một khoảng thời gian. Client phải renew trước khi hết hạn.

- Lease ngắn: IP quay vòng nhanh, nhiều traffic renew hơn.
- Lease dài: ổn định hơn, IP bị giữ lâu khi client rời mạng.

Lab có thể dùng 600 giây. Mạng văn phòng thường dùng nhiều giờ hoặc ngày tùy chính sách.

### Reservation

Reservation ánh xạ MAC cố định tới IP cố định. Client vẫn dùng DHCP nhưng luôn nhận cùng IP.

## 4. Chuẩn bị topology

Ví dụ chương này:

| Thành phần | Giá trị |
|---|---|
| Interface server | `ens33` |
| IP server | `192.168.10.2/24` |
| Network | `192.168.10.0` |
| Netmask | `255.255.255.0` |
| Gateway | `192.168.10.1` |
| Range | `192.168.10.100–192.168.10.200` |
| DNS | `192.168.10.2`, `1.1.1.1` |
| Domain | `lab.local` |

DHCP server phải có IP tĩnh. Nếu server tự đổi IP, client có thể nhận DNS/gateway sai hoặc không renew được.

## 5. Tool `dhcp install`

```bash
sudo ./bin/netadmin dhcp install
```

### Tool làm gì?

1. Kiểm tra có `dnf` hay `yum`.
2. Cài package DHCP phù hợp.
3. Nếu chưa có `/etc/dhcp/dhcpd.conf`, tạo cấu hình nền:

```text
authoritative;
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
```

4. Enable `dhcpd` để có thể tự chạy khi boot.
5. Nếu firewalld active, mở service `dhcp`.
6. Chưa start service vì chưa chắc đã có scope hợp lệ.

### Ý nghĩa cấu hình nền

- `authoritative`: server này có thẩm quyền trên mạng; nó có thể gửi DHCPNAK khi client giữ cấu hình không hợp lệ.
- `ddns-update-style none`: DHCP không tự cập nhật DNS động.
- `default-lease-time`: thời gian lease mặc định.
- `max-lease-time`: giới hạn tối đa.

### Kết quả mong đợi

```text
[OK] Đã cài DHCP. Hãy tạo scope trước khi khởi động dhcpd.
```

Nếu lỗi `Chỉ hỗ trợ hệ thống dùng dnf hoặc yum`, máy không thuộc họ distro được hỗ trợ hoặc PATH không chứa package manager.

## 6. Tool `dhcp scope add`

```bash
sudo ./bin/netadmin dhcp scope add \
  <name> <subnet> <netmask> <start> <end> \
  <gateway> <dns[,dns]> [domain] [lease]
```

Ví dụ hoàn chỉnh:

```bash
sudo ./bin/netadmin dhcp scope add \
  lab-lan \
  192.168.10.0 \
  255.255.255.0 \
  192.168.10.100 \
  192.168.10.200 \
  192.168.10.1 \
  192.168.10.2,1.1.1.1 \
  lab.local \
  600
```

### Giải thích từng tham số

#### `name`

Tên nội bộ để toolkit tìm lại block, ví dụ `lab-lan`. Chỉ dùng chữ, số, `_`, `-`, `.` và không quá 64 ký tự. Nó không phải interface và không được DHCP client nhìn thấy.

#### `subnet`

Network address, không phải IP server. Với `/24`, ba octet đầu giữ nguyên và octet cuối thường là `0`.

#### `netmask`

Dạng đầy đủ như `255.255.255.0`. Tool kiểm tra các bit `1` phải liên tục; `255.0.255.0` sẽ bị từ chối.

#### `start` và `end`

Biên đầu/cuối của range cấp động. Tool kiểm tra:

- Cả hai là IPv4 hợp lệ.
- Cùng subnet với `subnet`/`netmask`.
- `start` không lớn hơn `end`.

#### `gateway`

Router mà client dùng để đi ra ngoài subnet. Tool yêu cầu gateway cùng subnet.

#### `dns[,dns]`

Danh sách DNS gửi cho client. Không có khoảng trắng quanh dấu phẩy.

#### `domain`

Domain search suffix. Mặc định `lab.local`. Client có thể thử nối suffix này khi người dùng gõ tên ngắn.

#### `lease`

Số giây default lease. Mặc định `600`. Tool đặt `max-lease-time = lease × 12`.

### Cấu hình sinh ra

```text
# NETADMIN:SCOPE:lab-lan:BEGIN
subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.100 192.168.10.200;
  option routers 192.168.10.1;
  option subnet-mask 255.255.255.0;
  option domain-name "lab.local";
  option domain-name-servers 192.168.10.2, 1.1.1.1;
  default-lease-time 600;
  max-lease-time 7200;
}
# NETADMIN:SCOPE:lab-lan:END
```

Sau khi ghi, tool chạy `dhcpd -t`. Nếu syntax sai, backup được trả lại.

## 7. Tool `dhcp scope update`

```bash
sudo ./bin/netadmin dhcp scope update \
  lab-lan 192.168.10.0 255.255.255.0 \
  192.168.10.50 192.168.10.220 \
  192.168.10.1 192.168.10.2 lab.local 1800
```

`update` cần truyền lại toàn bộ tham số, không chỉ giá trị muốn đổi. Luồng xử lý:

1. Xác nhận scope `lab-lan` tồn tại.
2. Backup file hoàn chỉnh.
3. Bỏ block cũ.
4. Ghi block mới.
5. Validate.
6. Rollback file gốc nếu lỗi.

Scope update không sửa lease đang tồn tại ngay lập tức. Client thường nhận option/range mới ở lần renew tiếp theo.

## 8. Tool `dhcp scope list`

```bash
./bin/netadmin dhcp scope list
```

Output ví dụ:

```text
lab-lan
wifi-lan
```

Tool tìm marker, nên chỉ liệt kê scope do toolkit tạo. Một subnet viết tay trong `dhcpd.conf` không xuất hiện ở đây dù `dhcpd` vẫn sử dụng nó.

## 9. Tool `dhcp scope remove`

```bash
sudo ./bin/netadmin dhcp scope remove lab-lan
```

Tool backup, xóa block giữa hai marker và validate lại file. Nó không:

- Xóa lease hiện có.
- Tắt service.
- Xóa reservation nằm ngoài block scope.
- Thông báo trực tiếp tới client rằng scope đã mất.

Sau khi xóa, restart service khi sẵn sàng.

## 10. Tool `dhcp reservation add`

```bash
sudo ./bin/netadmin dhcp reservation add \
  <name> <mac> <ip> [hostname]
```

Ví dụ:

```bash
sudo ./bin/netadmin dhcp reservation add \
  printer01 00:11:22:33:44:55 192.168.10.10 printer01
```

### Khi nào dùng?

- Printer cần IP không đổi.
- Server lab cần quản lý địa chỉ tập trung.
- Muốn đổi IP sau này ở DHCP server thay vì cấu hình trực tiếp thiết bị.

### Tool kiểm tra gì?

- `name` hợp lệ và chưa có marker trùng.
- MAC đúng sáu cặp hex.
- IP đúng IPv4.
- MAC chưa xuất hiện trong reservation khác.
- IP chưa xuất hiện trong `fixed-address` khác.
- Hostname hợp lệ.

### Cấu hình sinh ra

```text
# NETADMIN:HOST:printer01:BEGIN
host printer01 {
  hardware ethernet 00:11:22:33:44:55;
  fixed-address 192.168.10.10;
  option host-name "printer01";
}
# NETADMIN:HOST:printer01:END
```

Nên chọn IP ngoài dynamic range để tránh khó hiểu khi theo dõi, dù DHCP server có thể xử lý reservation theo chính sách riêng.

## 11. Tool reservation list/remove

```bash
./bin/netadmin dhcp reservation list
sudo ./bin/netadmin dhcp reservation remove printer01
```

`remove` chỉ xóa cấu hình reservation. Client có thể tiếp tục dùng lease cũ đến khi hết hạn hoặc bị release.

## 12. Tool `dhcp lease list`

```bash
sudo ./bin/netadmin dhcp lease list
```

Tool đọc `/var/lib/dhcpd/dhcpd.leases` và rút ra:

```text
IP               START                  END                    HOSTNAME
192.168.10.101   3 2026/10/08 10:00:00  3 2026/10/08 10:10:00 pc01
```

Số trước ngày là weekday theo format lease của ISC DHCP, không phải một phần của IP. Lease file có thể chứa nhiều block lịch sử cho cùng IP; output là góc nhìn trực tiếp từ file, không phải bảng tổng hợp trạng thái cuối cùng.

## 13. Tool `dhcp lease release`

```bash
sudo ./bin/netadmin dhcp lease release 192.168.10.101
```

Tool gửi lệnh tới OMAPI bằng `omshell` tại `localhost:7911` để remove lease object.

Điều kiện:

- `omshell` đã cài.
- `dhcpd` đang chạy.
- OMAPI listener/config cho phép kết nối.
- Lease tồn tại đúng IP.

Xóa lease trên server không bắt buộc client ngừng dùng IP ngay. Muốn client cập nhật, renew/release trên client hoặc ngắt kết nối client theo cách phù hợp.

## 14. Tool config

### Xem file

```bash
sudo ./bin/netadmin dhcp config show
```

### Kiểm tra syntax

```bash
sudo ./bin/netadmin dhcp config check
```

Lệnh thực tế:

```text
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

Không có output lỗi và thấy `[OK]` nghĩa là parser chấp nhận file. Điều này chưa chứng minh interface, route hoặc topology đúng.

### Rollback

```bash
sudo ./bin/netadmin dhcp config rollback
```

Tool chọn backup `dhcpd.conf` mới nhất, hỏi xác nhận, khôi phục rồi validate.

## 15. Tool service

```bash
sudo ./bin/netadmin dhcp service start
sudo ./bin/netadmin dhcp service stop
sudo ./bin/netadmin dhcp service restart
sudo ./bin/netadmin dhcp service status
sudo ./bin/netadmin dhcp service enable
sudo ./bin/netadmin dhcp service enable-now
```

Luồng triển khai nên là:

```bash
sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp service enable-now
sudo ./bin/netadmin dhcp service status
```

## 16. Kiểm tra từ client

Trên Linux client dùng NetworkManager:

```bash
nmcli device show
ip address
ip route
cat /etc/resolv.conf
```

Cần thấy:

- IP trong range.
- Prefix/netmask đúng.
- Default route qua gateway.
- DNS đúng option đã cấu hình.

Trên Windows:

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
```

## 17. Lỗi thường gặp

### `No subnet declaration for ens33`

IP interface server không thuộc bất kỳ scope nào. Kiểm tra `ip address` và subnet trong scope.

### Client không nhận IP

Kiểm tra lần lượt:

1. Client và server có cùng broadcast domain không?
2. `dhcpd` active không?
3. UDP 67/68 có bị firewall chặn không?
4. Interface server có IP đúng không?
5. Có DHCP server khác trong LAN không?
6. Nếu khác subnet, router đã có DHCP relay chưa?

### Service start lỗi dù `dhcpd -t` thành công

Syntax đúng nhưng runtime có thể sai interface, permission hoặc socket. Xem:

```bash
sudo systemctl status dhcpd -l
sudo journalctl -u dhcpd --no-pager -n 100
```

### Client nhận IP nhưng không ra Internet

DHCP chỉ cấp thông tin. Kiểm tra gateway có routing/NAT đúng không; DHCP server không tự trở thành router.

### Client truy cập IP được nhưng tên không được

Đây thường là vấn đề DNS, không phải cấp IP. Kiểm tra DNS option và DNS server.

## 18. Bài thực hành hoàn chỉnh

```bash
sudo ./bin/netadmin dhcp install

sudo ./bin/netadmin dhcp scope add \
  lab-lan 192.168.10.0 255.255.255.0 \
  192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2 lab.local 600

sudo ./bin/netadmin dhcp reservation add \
  files 00:11:22:33:44:55 192.168.10.20 files

sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp service enable-now
sudo ./bin/netadmin dhcp service status
sudo ./bin/netadmin dhcp lease list
```

Khi kết thúc lab, không cần xóa cấu hình nếu muốn tiếp tục ở chương DNS/Samba.

