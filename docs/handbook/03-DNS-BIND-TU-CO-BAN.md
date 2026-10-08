# Chương 3 — DNS và BIND từ cơ bản đến từng command

## 1. DNS giải quyết vấn đề gì?

Máy gửi packet tới IP, nhưng người dùng muốn nhớ tên. DNS là hệ thống dữ liệu phân tán ánh xạ tên và thông tin liên quan.

```text
Người dùng nhập: files.lab.local
        ↓ hỏi DNS
DNS trả lời: 192.168.10.20
        ↓
Client kết nối tới 192.168.10.20
```

DNS không vận chuyển file/web. Nó chỉ cung cấp thông tin để client tìm đúng đích.

## 2. Resolver, authoritative server và cache

- **Stub resolver** nằm trên máy client, nhận yêu cầu từ ứng dụng.
- **Recursive resolver** đi tìm câu trả lời, cache kết quả.
- **Authoritative server** giữ dữ liệu chính thức của một zone.
- **Forwarder** là DNS upstream mà server chuyển truy vấn chưa biết tới.

BIND (`named`) có thể làm authoritative server và recursive/caching resolver tùy cấu hình.

## 3. Domain, FQDN và dấu chấm cuối

`lab.local` là domain. `files.lab.local.` là FQDN tuyệt đối; dấu `.` cuối đại diện DNS root.

Trong zone file `lab.local`:

```text
files        IN A     192.168.10.20
alias        IN CNAME files.lab.local.
```

Tên `files` tương đối sẽ thành `files.lab.local.`. Giá trị `files.lab.local.` có dấu chấm nên không bị nối domain thêm lần nữa.

## 4. Zone và record

**Zone** là phần namespace mà server quản lý. Zone `lab.local` có thể chứa nhiều record.

| Record | Công dụng | Ví dụ |
|---|---|---|
| `A` | Tên → IPv4 | `www A 192.168.10.20` |
| `AAAA` | Tên → IPv6 | `www AAAA 2001:db8::20` |
| `CNAME` | Alias → tên chuẩn | `files CNAME server.lab.local.` |
| `MX` | Mail exchanger và priority | `@ MX 10 mail.lab.local.` |
| `NS` | Name server của zone | `@ NS ns1.lab.local.` |
| `TXT` | Text metadata | SPF, verification, ghi chú lab |
| `PTR` | IP → tên trong reverse zone | `20 PTR files.lab.local.` |

`@` trong zone file nghĩa là chính zone apex, ví dụ `lab.local.`.

## 5. SOA, serial và TTL

Mỗi master zone cần SOA:

```text
@ IN SOA ns1.lab.local. hostmaster.lab.local. (
  2026100800 ; serial
  3600       ; refresh
  900        ; retry
  604800     ; expire
  86400      ; minimum
)
```

- **Primary NS**: server nguồn của zone.
- **RNAME**: email quản trị, nhưng ký tự `@` được biểu diễn bằng dấu chấm đầu tiên.
- **Serial**: version zone. Secondary chỉ biết zone đổi khi serial tăng.
- **Refresh/retry/expire**: lịch secondary đồng bộ.
- **TTL**: thời gian resolver được cache record.

Toolkit tăng serial sau mỗi thay đổi record. TTL mặc định record là 3600 giây.

## 6. Forward lookup và reverse lookup

- Forward: `files.lab.local` → `192.168.10.20`.
- Reverse: `192.168.10.20` → `files.lab.local`.

Reverse IPv4 dùng namespace `in-addr.arpa` và đảo thứ tự octet mạng. Với `192.168.10.0/24`:

```text
Reverse zone: 10.168.192.in-addr.arpa
Owner 20:     đại diện 192.168.10.20
```

Có A record không tự sinh PTR. Phải cấu hình hai chiều riêng.

## 7. Tool `dns install`

```bash
sudo ./bin/netadmin dns install
```

Tool:

1. Cài `bind`, `bind-utils`, `NetworkManager`.
2. Tạo `/etc/named/netadmin-zones.conf` nếu thiếu.
3. Thêm `include "/etc/named/netadmin-zones.conf";` vào `named.conf`.
4. Chạy `named-checkconf`.
5. Enable `named`.
6. Mở DNS trong firewalld.

Chưa start `named` để bạn tạo zone trước.

## 8. Tool `dns network list`

```bash
./bin/netadmin dns network list
```

Output từ `nmcli` gồm:

- `NAME`: tên connection profile dùng trong command tiếp theo.
- `UUID`: ID duy nhất của profile.
- `TYPE`: ethernet, wifi, bridge...
- `DEVICE`: interface đang gắn với profile.

Connection profile và interface khác nhau. Profile có thể tên `System ens33`, còn interface là `ens33`.

## 9. Tool `dns network static`

```bash
sudo ./bin/netadmin dns network static \
  <connection> <address/prefix> <gateway> <dns[,dns]>
```

Ví dụ:

```bash
sudo ./bin/netadmin dns network static \
  'System ens33' 192.168.10.2/24 192.168.10.1 127.0.0.1,1.1.1.1
```

Tool đặt `ipv4.method manual`, address, gateway, DNS rồi chạy `nmcli connection up`.

Giải thích:

- Đặt tên connection trong nháy nếu có khoảng trắng.
- `192.168.10.2/24` là IP server và prefix.
- `127.0.0.1` khiến server tự hỏi BIND cục bộ.
- DNS ngoài như `1.1.1.1` có thể là dự phòng, nhưng client resolver có thể hỏi nó trực tiếp và không biết zone nội bộ.

Nếu làm qua SSH, connection up có thể ngắt phiên khi IP đổi. Nên thao tác từ console VM.

## 10. Tool `dns network dhcp`

```bash
sudo ./bin/netadmin dns network dhcp 'System ens33'
```

Tool đổi method về `auto`, xóa address/gateway/DNS thủ công và active profile. Không nên dùng IP động cho DNS server lâu dài vì client cần biết địa chỉ DNS ổn định.

## 11. Tool `dns zone add`

```bash
sudo ./bin/netadmin dns zone add <domain> <server-ip> [admin-label]
```

Ví dụ:

```bash
sudo ./bin/netadmin dns zone add lab.local 192.168.10.2 hostmaster
```

Tool tạo master zone và zone file với:

- SOA trỏ tới `ns1.lab.local.`.
- NS record cho `ns1`.
- A record `ns1 → 192.168.10.2`.
- A record apex `lab.local → 192.168.10.2`.

Declaration:

```text
zone "lab.local" IN {
  type master;
  file "db.lab-local";
  allow-update { none; };
};
```

`allow-update none` ngăn dynamic update. Đây là lựa chọn an toàn cho lab quản lý record tĩnh.

Tool đặt owner zone file là `named:named`, mode `0640`, rồi chạy cả `named-checkzone` và `named-checkconf`.

## 12. Tool `dns zone add-reverse`

```bash
sudo ./bin/netadmin dns zone add-reverse \
  10.168.192.in-addr.arpa ns1.lab.local
```

Tham số đầu là tên reverse zone đã đảo, không phải `192.168.10.0/24`. Tham số hai là FQDN DNS server.

Sau đó tạo PTR:

```bash
sudo ./bin/netadmin dns record add \
  10.168.192.in-addr.arpa 20 PTR files.lab.local.
```

## 13. Tool `dns zone add-secondary`

Chạy trên secondary server:

```bash
sudo ./bin/netadmin dns zone add-secondary lab.local 192.168.10.2
```

Declaration gồm:

```text
type slave;
masters { 192.168.10.2; };
file "slaves/db.lab-local";
```

Secondary không chỉnh record trực tiếp; nó nhận zone qua transfer từ primary. Trên primary phải chạy:

```bash
sudo ./bin/netadmin dns transfer allow lab.local 192.168.10.3
```

Zone transfer dùng TCP 53, nên firewall giữa hai server phải cho phép.

## 14. Tool zone list/remove

```bash
./bin/netadmin dns zone list
sudo ./bin/netadmin dns zone remove lab.local
```

`list` đọc marker, không hỏi live service. `remove` xóa declaration, validate config rồi đổi tên zone file thành `.removed.<epoch>` để có thể cứu lại. Secondary file trong `slaves` không được xử lý như master zone file.

## 15. Tool `dns record add`

```bash
sudo ./bin/netadmin dns record add \
  <zone> <name> <type> <value> [ttl]
```

Ví dụ từng type:

```bash
sudo ./bin/netadmin dns record add lab.local files A 192.168.10.20
sudo ./bin/netadmin dns record add lab.local files6 AAAA 2001:db8::20
sudo ./bin/netadmin dns record add lab.local share CNAME files.lab.local.
sudo ./bin/netadmin dns record add lab.local @ MX '10 mail.lab.local.'
sudo ./bin/netadmin dns record add lab.local @ NS ns2.lab.local.
sudo ./bin/netadmin dns record add lab.local @ TXT 'lop quan tri mang'
sudo ./bin/netadmin dns record add 10.168.192.in-addr.arpa 20 PTR files.lab.local.
```

Tool backup zone, append record, tăng serial và validate. Với `CNAME`, `NS`, `PTR`, nên dùng dấu chấm cuối cho FQDN tuyệt đối.

Không đặt CNAME cùng tên với record type khác. Đây là quy tắc DNS dù validator/input cơ bản không diễn giải mọi xung đột nghiệp vụ.

## 16. Tool record list/remove

```bash
./bin/netadmin dns record list lab.local
sudo ./bin/netadmin dns record remove lab.local files A
```

`list` in nguyên zone file để bạn thấy SOA, serial và record. `remove` tìm dòng có owner/type tương ứng, bỏ dòng, tăng serial và validate. Nếu nhiều dòng cùng owner/type, implementation hiện loại tất cả dòng khớp.

## 17. Tool `dns transfer allow`

```bash
sudo ./bin/netadmin dns transfer allow lab.local 192.168.10.3
```

Chạy trên primary. Tool chèn:

```text
allow-transfer { 192.168.10.3; };
```

Mỗi lần gọi cho cùng zone thay thế directive cũ, nên implementation hiện phù hợp một secondary IP. Nếu cần nhiều secondary, cần mở rộng tool hoặc chỉnh block cẩn thận.

## 18. Tool forwarders

```bash
sudo ./bin/netadmin dns forwarders set 1.1.1.1,8.8.8.8
sudo ./bin/netadmin dns forwarders clear
```

Forwarder được dùng khi server không có câu trả lời authoritative/cache và cấu hình recursion cho phép. Tool chèn vào block `options` đầu tiên:

```text
forwarders { 1.1.1.1; 8.8.8.8; }; // NETADMIN:FORWARDERS
```

`clear` xóa dòng có marker. Nó không xóa forwarder viết tay không có marker.

## 19. Tool `dns query`

```bash
./bin/netadmin dns query files.lab.local
./bin/netadmin dns query files.lab.local 192.168.10.2
```

Không truyền server: `dig` dùng resolver cấu hình trên máy. Có server: hỏi trực tiếp server đó.

Trong output `dig`, chú ý:

- `status: NOERROR`: truy vấn được xử lý thành công.
- `status: NXDOMAIN`: tên không tồn tại.
- `ANSWER SECTION`: câu trả lời.
- `SERVER`: DNS thực sự đã trả lời.
- `AUTHORITY SECTION`: server/zone có thẩm quyền.

## 20. Tool config/service

```bash
./bin/netadmin dns config show
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns config rollback
sudo ./bin/netadmin dns service enable-now
sudo ./bin/netadmin dns service restart
sudo ./bin/netadmin dns service status
```

`config show` in `named.conf` rồi fragment NetAdmin. `config check` kiểm tra cấu hình tổng thể, không kiểm tra từng zone file riêng nếu BIND không load tới lỗi đó theo cách mong đợi; record command luôn gọi thêm `named-checkzone`.

## 21. Quy trình lab hoàn chỉnh

Trên primary `192.168.10.2`:

```bash
sudo ./bin/netadmin dns install
sudo ./bin/netadmin dns zone add lab.local 192.168.10.2
sudo ./bin/netadmin dns zone add-reverse 10.168.192.in-addr.arpa ns1.lab.local
sudo ./bin/netadmin dns record add lab.local files A 192.168.10.20
sudo ./bin/netadmin dns record add 10.168.192.in-addr.arpa 20 PTR files.lab.local.
sudo ./bin/netadmin dns forwarders set 1.1.1.1,8.8.8.8
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns service enable-now
./bin/netadmin dns query files.lab.local 192.168.10.2
```

CLI `dns query` nhận tên forward. Để kiểm tra reverse, dùng trực tiếp:

```bash
dig @192.168.10.2 -x 192.168.10.20
```

## 22. Lỗi thường gặp

- **SERVFAIL**: zone lỗi, server không load được, DNSSEC/upstream hoặc permission. Xem `journalctl -u named`.
- **NXDOMAIN**: server trả lời rằng tên không có; kiểm tra zone/name/dấu chấm cuối.
- **Connection timed out**: service/firewall/route hoặc server không listen.
- **Query trả lời từ DNS khác**: xem dòng `SERVER` của `dig`; chỉ định server trực tiếp.
- **Secondary không đồng bộ**: serial chưa tăng, TCP 53 bị chặn, `allow-transfer` sai IP, clock/log.
- **Zone file permission denied**: kiểm tra owner `named`, mode, SELinux context/log.
- **Tên thành `files.lab.local.lab.local`**: thiếu dấu chấm cuối ở giá trị FQDN trong zone file.

Chẩn đoán:

```bash
sudo named-checkconf /etc/named.conf
sudo named-checkzone lab.local /var/named/db.lab-local
sudo systemctl status named -l
sudo journalctl -u named --no-pager -n 100
dig @192.168.10.2 lab.local SOA
```
