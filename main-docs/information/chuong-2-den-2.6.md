# CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ

Chương này trình bày những kiến thức nền trực tiếp chi phối cách NetAdmin Toolkit cấu hình và kiểm tra hệ thống. Nội dung không tách rời sản phẩm thành một phần lý thuyết chung, mà giải thích vì sao mỗi thành phần được chọn, nó tham gia vào luồng vận hành nào và các command trong dự án chuyển kiến thức đó thành thao tác thực tế ra sao. Phạm vi của chương từ mục 2.1 đến 2.6 gồm nền tảng CentOS, cấu hình mạng, DHCP, DNS, lưu trữ và Samba.

## 2.1 CentOS và quản trị dịch vụ Linux

CentOS thuộc họ hệ điều hành Linux tương thích với hệ sinh thái Red Hat Enterprise Linux. Trong môi trường môn Quản trị mạng, CentOS phù hợp để triển khai máy chủ vì các thành phần hệ thống được tổ chức theo quy ước rõ ràng: phần mềm được phân phối dưới dạng package, cấu hình đặt trong các thư mục chuẩn dưới `/etc`, tiến trình nền được quản lý bằng systemd, log tập trung qua journal hoặc thư mục `/var/log`, còn truy cập mạng được kiểm soát bởi firewalld và SELinux. Những quy ước này giúp một kịch bản lab có thể tái lập trên nhiều máy nếu người thực hiện kiểm soát đúng phiên bản package, service và tệp cấu hình.

Một dịch vụ mạng trên CentOS không chỉ là một chương trình đang chạy. Nó là tập hợp nhiều thành phần phụ thuộc lẫn nhau. Package cung cấp executable, unit file và các tệp mặc định; file cấu hình mô tả hành vi; service tạo tiến trình nền; port là điểm tiếp nhận kết nối; firewall quyết định traffic có được vào máy hay không; SELinux tiếp tục giới hạn tiến trình được phép đọc, ghi hoặc bind vào tài nguyên nào. Vì vậy, trạng thái “đã cài package” không đồng nghĩa với “dịch vụ đã sẵn sàng”. Một DNS server chỉ hoạt động đúng khi BIND đã được cài, `named.conf` và zone hợp lệ, service `named` đang chạy, cổng 53 được mở và context của zone file phù hợp.

**Bảng 2.1. Các thành phần của một dịch vụ Linux trong NetAdmin Toolkit**

| Thành phần | Vai trò | Ví dụ trong dự án |
|---|---|---|
| Package | Cung cấp chương trình và dependency | `bind`, `dhcp-server`, `samba`, `lvm2` |
| Configuration | Quy định cách dịch vụ hoạt động | `/etc/named.conf`, `/etc/dhcp/dhcpd.conf`, `/etc/samba/smb.conf` |
| Service | Quản lý tiến trình nền | `named`, `dhcpd`, `smb`, `nmb` |
| Port hoặc protocol | Điểm trao đổi dữ liệu với client | DNS 53 TCP/UDP, DHCP 67/68 UDP, SMB 445 TCP |
| Firewall | Cho phép traffic hợp lệ đi qua | service `dns`, `dhcp`, `samba` trong firewalld |
| SELinux | Giới hạn quyền của tiến trình | context `samba_share_t` cho thư mục chia sẻ |

DNF là trình quản lý package chính trên các bản CentOS/RHEL mới. Nó giải quyết dependency và ghi nhận package đã cài để hệ thống có thể cập nhật hoặc gỡ bỏ có kiểm soát. Dự án ưu tiên `dnf`, đồng thời có nhánh tương thích `yum` cho môi trường cũ. Quyền cài package, thay đổi file dưới `/etc`, điều khiển service hoặc thao tác disk đều yêu cầu root; bởi vậy người dùng chạy các command thay đổi hệ thống với `sudo`, trong khi command help, list hoặc query có thể chạy bằng tài khoản thường nếu dữ liệu cho phép.

Systemd là hệ thống khởi tạo và quản lý service. `systemctl start` chạy dịch vụ trong phiên hiện tại; `enable` đăng ký tự chạy ở các lần boot tiếp theo; `enable --now` hoặc hành động `enable-now` vừa đăng ký vừa khởi động. `restart` dừng rồi chạy lại, thích hợp khi chương trình không hỗ trợ reload hoặc khi cần nạp toàn bộ cấu hình. `status` cho biết trạng thái active, mã thoát và log gần nhất. Dự án chuẩn hóa các hành động này qua cú pháp `netadmin <module> service <action>`, nhờ đó người học không phải nhớ tên service khác nhau của từng module.

Firewalld tổ chức rule theo zone và service. NetAdmin Toolkit không tắt firewall để làm bài lab chạy nhanh, mà mở đúng service cần thiết nếu firewalld đang hoạt động. Cách làm này phản ánh nguyên tắc giảm bề mặt tấn công: DNS chỉ cần TCP/UDP 53, DHCP server cần UDP 67 và Samba chủ yếu cần SMB cùng các dịch vụ liên quan. Tương tự, SELinux được giữ ở trạng thái enforcing. Khi Samba chia sẻ một thư mục ngoài đường dẫn mặc định, toolkit đặt context phù hợp thay vì yêu cầu `setenforce 0`. Điều này giúp bài thực hành gần với môi trường vận hành thật hơn.

Trong kiến trúc dự án, các thao tác dùng chung như phát hiện package manager, kiểm tra quyền root, điều khiển systemd, quản lý firewall, log và exit code được đặt trong `src/core`. Feature chỉ mô tả nghiệp vụ riêng, ví dụ DHCP tạo scope hay DNS tạo zone. Thiết kế này tránh lặp code và bảo đảm mọi module phản hồi theo cùng một quy ước.

Trước khi cấu hình dịch vụ, người dùng có thể kiểm tra môi trường bằng:

```bash
./bin/netadmin doctor
```

Kết quả mong đợi là hệ điều hành, Bash và các dependency nền được nhận diện; các thiếu sót được báo bằng thông điệp rõ ràng. Sau khi cài một module, quy trình kiểm tra cơ bản gồm xem cấu hình, chạy validator, bật service và xem status. Ví dụ với DNS:

```bash
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns service enable-now
sudo ./bin/netadmin dns service status
```

Ba lệnh lần lượt xác nhận cú pháp, đưa service vào trạng thái chạy hiện tại và tự chạy khi boot, rồi hiển thị bằng chứng vận hành. Đây là khuôn mẫu chung được tái sử dụng trong các phần tiếp theo.

## 2.2 Địa chỉ IP, gateway và NetworkManager

Mọi dịch vụ mạng cần một địa chỉ có thể xác định ổn định. IPv4 gồm 32 bit, thường viết thành bốn số thập phân từ 0 đến 255. Địa chỉ được chia thành phần network và phần host theo subnet mask hoặc tiền tố CIDR. Với `192.168.10.2/24`, 24 bit đầu biểu diễn mạng `192.168.10.0`, địa chỉ broadcast là `192.168.10.255`, còn dải host thường dùng là `192.168.10.1` đến `192.168.10.254`. Network address và broadcast address không được gán cho host thông thường.

Subnet quyết định hai thiết bị có thể trao đổi trực tiếp ở lớp mạng hay phải đi qua router. Nếu đích cùng subnet, máy dùng ARP để tìm MAC và gửi frame trực tiếp. Nếu đích ngoài subnet, packet được gửi tới default gateway. Gateway vì vậy phải nằm trong cùng subnet với interface của host. DNS server là một tham số khác: nó chuyển tên thành IP, không thay thế gateway. Một máy có thể đồng thời làm DNS server và router, nhưng đây là hai vai trò độc lập.

**Bảng 2.2. Ý nghĩa các tham số mạng trong mô hình lab**

| Tham số | Ví dụ | Ý nghĩa |
|---|---|---|
| Interface | `enp2s0`, `enp26s0` | Card mạng mà cấu hình được áp dụng |
| IPv4/CIDR | `192.168.10.2/24` | Địa chỉ server và kích thước subnet |
| Network | `192.168.10.0/24` | Miền địa chỉ của mạng lab |
| Gateway | `192.168.10.1` | Router cho traffic ra ngoài subnet |
| DNS | `127.0.0.1,1.1.1.1` | Resolver cục bộ và resolver dự phòng |
| Connection profile | `netadmin-lab` | Đối tượng cấu hình do NetworkManager quản lý |

Trên CentOS, NetworkManager quản lý interface thông qua connection profile. Interface là thiết bị thật hoặc thiết bị ảo do kernel nhận diện, còn connection là tập cấu hình có thể được gán cho thiết bị đó. Hai tên này không nhất thiết giống nhau. Lỗi “unknown connection” xuất hiện khi người dùng truyền tên interface vào vị trí yêu cầu tên profile không tồn tại. Ngược lại, lỗi “mismatching interface name” xảy ra khi profile bị ràng buộc với một interface khác. Vì vậy bước khảo sát phải thực hiện trước bước thay đổi:

```bash
nmcli device status
nmcli -f NAME,UUID,TYPE,DEVICE connection show
ip -4 address
ip route
```

Mô hình lab của dự án ưu tiên hai card mạng. Card thứ nhất nối NAT để máy chủ truy cập Internet và cài package. Card thứ hai nối private network để DHCP, DNS, Samba và các dịch vụ lab phục vụ client trong mạng riêng. Cách tách này giảm nguy cơ DHCP của bài thực hành phát địa chỉ vào mạng NAT, đồng thời giữ một đường quản trị khi cấu hình IP private thay đổi. Tên thiết bị phải lấy từ kết quả thực tế, không sao chép `ens33` hoặc `enp2s0` từ máy khác.

NetAdmin Toolkit đặt thao tác NetworkManager trong module DNS vì địa chỉ DNS server cần ổn định trước khi tạo zone và phân phối cho client. Lệnh liệt kê:

```bash
./bin/netadmin dns network list
```

Lệnh cấu hình tĩnh nhận connection, địa chỉ CIDR, gateway và danh sách DNS:

```bash
sudo ./bin/netadmin dns network static \
  netadmin-lab 192.168.10.2/24 192.168.10.1 \
  127.0.0.1,1.1.1.1
```

Khi thực thi, project dùng `nmcli connection modify` để đặt `ipv4.method manual`, địa chỉ, gateway và DNS, sau đó đưa profile lên bằng `nmcli connection up`. DNS `127.0.0.1` khiến chính server hỏi BIND chạy cục bộ. Resolver công cộng chỉ nên là nguồn dự phòng hoặc forwarder; nếu client hỏi trực tiếp DNS công cộng, zone nội bộ như `lab.local` sẽ không được biết tới.

Để trả profile về nhận cấu hình tự động:

```bash
sudo ./bin/netadmin dns network dhcp netadmin-lab
```

Lệnh đặt `ipv4.method auto` và loại bỏ các giá trị thủ công. Tuy nhiên, DNS server hoặc DHCP server không nên dùng địa chỉ động lâu dài vì client cần biết điểm dịch vụ ổn định. Đổi IP cũng có thể làm mất phiên SSH hoặc Cockpit, nên thao tác mạng được khuyến nghị thực hiện từ console VM hoặc qua card quản trị còn lại.

Sau cấu hình, kết quả cần xác nhận gồm: interface ở trạng thái connected; địa chỉ `192.168.10.2/24` xuất hiện trên đúng card; route tới `192.168.10.0/24` tồn tại; default route không bị tạo trùng trên card private nếu nó không dùng để ra Internet; và resolver trỏ đúng server. Các lệnh `ip -4 address show <interface>`, `ip route` và `nmcli connection show <profile>` cung cấp bằng chứng cho từng điều kiện này.

## 2.3 Dịch vụ DHCP

DHCP, viết tắt của Dynamic Host Configuration Protocol, tự động cung cấp cho client địa chỉ IP, subnet mask, default gateway, DNS server, domain search và một số option khác. Nếu cấu hình thủ công từng máy, quản trị viên dễ cấp trùng IP hoặc nhập sai gateway, đặc biệt trong lớp học có nhiều máy ảo. DHCP giải quyết vấn đề này bằng cách quản lý một pool địa chỉ và cấp quyền sử dụng có thời hạn gọi là lease.

Client ban đầu chưa có IP nên quá trình cơ bản sử dụng broadcast trong cùng miền quảng bá. Luồng DORA gồm bốn thông điệp.

**Bảng 2.3. Chu trình DORA của DHCP**

| Bước | Thông điệp | Ý nghĩa |
|---:|---|---|
| 1 | DHCPDISCOVER | Client phát quảng bá để tìm DHCP server |
| 2 | DHCPOFFER | Server đề nghị một địa chỉ và các option |
| 3 | DHCPREQUEST | Client chọn offer và yêu cầu sử dụng địa chỉ |
| 4 | DHCPACK | Server xác nhận lease và thời hạn sử dụng |

DHCP server lắng nghe UDP 67, client dùng UDP 68. Router thông thường không chuyển broadcast DHCP sang subnet khác; khi server và client khác subnet cần DHCP relay, nhưng relay không thuộc phạm vi hiện tại của toolkit. Trong mô hình lab, client và card private của server phải cùng virtual network.

Một scope mô tả chính sách cấp phát cho một subnet. Nó gồm network, netmask, dải động, gateway, DNS, domain và thời hạn lease. Range không nên chứa IP tĩnh của router, server, access point hoặc printer. Lease ngắn giúp thu hồi IP nhanh nhưng tăng traffic renew; lease dài ổn định hơn nhưng giữ địa chỉ lâu khi client rời mạng. Reservation ánh xạ MAC với một IP cố định: thiết bị vẫn dùng DHCP nhưng luôn nhận cùng địa chỉ, phù hợp cho printer hoặc máy lab cần nhận diện ổn định.

Trong dự án, package DHCP được cài bằng:

```bash
sudo ./bin/netadmin dhcp install
```

Command tạo cấu hình nền với `authoritative`, tắt dynamic DNS update mặc định, đặt thời gian lease, enable `dhcpd` và mở service DHCP trong firewalld. Dịch vụ chưa được start ngay vì một `dhcpd.conf` chưa có scope hợp lệ sẽ không thể phục vụ client. Đây là quyết định an toàn: cài đặt và khai báo dữ liệu được tách khỏi bước đưa service vào vận hành.

Ví dụ tạo scope cho mạng lab:

```bash
sudo ./bin/netadmin dhcp scope add \
  lab-lan 192.168.10.0 255.255.255.0 \
  192.168.10.100 192.168.10.200 \
  192.168.10.1 192.168.10.2,1.1.1.1 \
  lab.local 600
```

Toolkit kiểm tra subnet và netmask hợp lệ, range nằm trong subnet, địa chỉ đầu không lớn hơn địa chỉ cuối, gateway cùng subnet và danh sách DNS đúng định dạng. Block được bao bằng marker `NETADMIN:SCOPE` để có thể list, update hoặc remove mà không ảnh hưởng phần cấu hình khác. Trước khi giữ thay đổi, project chạy `dhcpd -t`; nếu validator thất bại, bản sao lưu được phục hồi.

Reservation được tạo bằng:

```bash
sudo ./bin/netadmin dhcp reservation add \
  client01 00:11:22:33:44:55 192.168.10.10 client01
```

Các lệnh `scope list`, `reservation list` và `lease list` cung cấp ba góc nhìn khác nhau: chính sách đã định nghĩa, ánh xạ cố định và trạng thái cấp phát thực tế. `lease release <ip>` thao tác trên dữ liệu lease phía server; nó không thay thế việc renew/release ở client nếu client vẫn đang online.

Quy trình đưa DHCP vào hoạt động gồm:

```bash
sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp service enable-now
sudo ./bin/netadmin dhcp service status
./bin/netadmin dhcp lease list
```

Client phải đặt IPv4 ở chế độ tự động rồi renew connection. Kết quả đạt yêu cầu khi client nhận IP trong range, subnet mask đúng, gateway và DNS đúng option, server ghi lease tương ứng và client ping được IP card private của server. Nếu client không nhận IP, cần kiểm tra lần lượt topology ảo, trạng thái interface, service `dhcpd`, firewall, subnet declaration và log, thay vì chỉ chỉnh lại range một cách ngẫu nhiên.

## 2.4 Dịch vụ DNS và BIND

DNS, viết tắt của Domain Name System, ánh xạ tên miền với dữ liệu cần thiết để client tìm đúng dịch vụ. DNS không vận chuyển trang web hoặc file; nó chỉ trả lời thông tin như tên `files.lab.local` tương ứng IP nào, mail của domain do server nào nhận, hoặc địa chỉ IP có tên ngược là gì. Nhờ DNS, địa chỉ dịch vụ có thể được biểu diễn bằng tên ổn định ngay cả khi chi tiết hạ tầng thay đổi.

Trong một truy vấn, stub resolver trên client gửi câu hỏi tới recursive resolver. Resolver dùng cache nếu bản ghi còn TTL hoặc tiếp tục hỏi các server có thẩm quyền. Authoritative server lưu dữ liệu chính thức của zone. BIND là bộ phần mềm DNS phổ biến trên Linux; tiến trình `named` có thể làm authoritative server, caching resolver và forwarder tùy cấu hình. Trong lab, một BIND server vừa giữ zone nội bộ vừa chuyển các tên ngoài phạm vi quản lý tới DNS upstream.

Zone là phần namespace do một server quản lý. Forward zone giải tên sang địa chỉ; reverse zone dùng `in-addr.arpa` để tìm tên từ IPv4. FQDN tuyệt đối kết thúc bằng dấu chấm, ví dụ `files.lab.local.`. Trong zone file, tên không có dấu chấm cuối có thể được nối thêm origin; vì vậy CNAME, NS, MX và PTR cần được viết cẩn thận để tránh tạo tên lặp.

**Bảng 2.4. Các loại DNS record được project hỗ trợ**

| Record | Chức năng | Ví dụ |
|---|---|---|
| A | Tên sang IPv4 | `www A 192.168.10.20` |
| AAAA | Tên sang IPv6 | `www AAAA 2001:db8::20` |
| CNAME | Alias sang tên chuẩn | `files CNAME server.lab.local.` |
| MX | Chỉ định mail exchanger và priority | `@ MX 10 mail.lab.local.` |
| NS | Khai báo name server của zone | `@ NS ns1.lab.local.` |
| TXT | Lưu metadata dạng text | SPF hoặc thông tin xác minh |
| PTR | IPv4 sang tên trong reverse zone | `20 PTR files.lab.local.` |

Mỗi master zone có SOA record chứa primary server, địa chỉ quản trị dạng DNS, serial và các khoảng refresh, retry, expire. Serial là phiên bản của zone; secondary chỉ đồng bộ khi serial tăng. TTL quyết định resolver được cache câu trả lời bao lâu. TTL thấp thuận lợi khi thay đổi thường xuyên nhưng tăng số truy vấn; TTL cao giảm tải nhưng khiến thay đổi lan truyền chậm hơn.

Project cài BIND bằng:

```bash
sudo ./bin/netadmin dns install
```

Command cài `bind`, `bind-utils` và NetworkManager, tạo `/etc/named/netadmin-zones.conf`, include tệp này vào `named.conf`, chạy `named-checkconf`, enable `named` và mở DNS trong firewalld. Việc tách declaration do NetAdmin quản lý khỏi file chính giúp giảm xung đột và cho phép rollback có phạm vi.

Ví dụ tạo master zone:

```bash
sudo ./bin/netadmin dns zone add \
  lab.local 192.168.10.2 hostmaster
```

Toolkit tạo SOA, NS, A record cho `ns1`, A record tại zone apex, đặt owner `named:named`, mode phù hợp và chạy cả `named-checkzone` lẫn `named-checkconf`. Dynamic update bị tắt để record chỉ thay đổi qua quy trình có kiểm soát.

Thêm record và reverse lookup:

```bash
sudo ./bin/netadmin dns record add \
  lab.local files A 192.168.10.20

sudo ./bin/netadmin dns zone add-reverse \
  10.168.192.in-addr.arpa ns1.lab.local

sudo ./bin/netadmin dns record add \
  10.168.192.in-addr.arpa 20 PTR files.lab.local.
```

Khi thêm hoặc xóa record, toolkit backup zone file, tăng serial và validate. Secondary zone được tạo bằng `zone add-secondary`; primary phải cho phép transfer tới IP secondary. Zone transfer dùng TCP 53, còn truy vấn DNS thường dùng UDP 53 và chuyển sang TCP khi cần response lớn hoặc các cơ chế đặc thù.

Forwarder cho tên ngoài được cấu hình bằng:

```bash
sudo ./bin/netadmin dns forwarders set 1.1.1.1,8.8.8.8
```

Sau đó thực hiện:

```bash
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns service enable-now
./bin/netadmin dns query files.lab.local 127.0.0.1
```

Kết quả mong đợi là validator không báo lỗi, `named` active, truy vấn A trả về `192.168.10.20`, truy vấn PTR trả về `files.lab.local.` và client dùng DNS `192.168.10.2` phân giải được zone nội bộ. Nếu server tự truy vấn được nhưng client không truy vấn được, nguyên nhân thường nằm ở firewall, listen/allow-query, topology hoặc DNS trên client chứ không phải bản ghi.

## 2.5 Lưu trữ, filesystem, LVM và quota

Hệ thống lưu trữ Linux gồm nhiều lớp. Disk là thiết bị block toàn bộ; partition chia disk thành vùng; filesystem tổ chức file và thư mục; mount gắn filesystem vào một vị trí trong cây thư mục. Nếu dùng LVM, giữa partition và filesystem có thêm Physical Volume, Volume Group và Logical Volume. Nhầm tầng có thể dẫn đến format sai thiết bị hoặc ghi metadata đè lên dữ liệu.

**Bảng 2.5. Các lớp lưu trữ và công cụ tương ứng**

| Lớp | Ví dụ | Công cụ chính |
|---|---|---|
| Disk | `/dev/sdb` | `lsblk`, `parted` |
| Partition | `/dev/sdb1` | `parted`, `partprobe` |
| PV | `/dev/sdb1` sau `pvcreate` | `pvs`, `pvcreate` |
| VG | `vg_lab` | `vgs`, `vgcreate`, `vgextend` |
| LV | `/dev/vg_lab/lv_data` | `lvs`, `lvcreate`, `lvextend` |
| Filesystem | XFS hoặc ext4 | `mkfs`, `blkid` |
| Mount | `/data` | `mount`, `findmnt`, `/etc/fstab` |
| Quota | giới hạn user trên mountpoint | `setquota`, `repquota` |

Partition table GPT phù hợp với hệ thống hiện đại và disk lớn; kiểu msdos/MBR có nhiều giới hạn hơn. Sau khi tạo partition, kernel và udev phải nhận biết thiết bị mới. Filesystem phổ biến trên CentOS là XFS; XFS hỗ trợ mở rộng online tốt nhưng không shrink bằng công cụ chuẩn. Ext4 linh hoạt và phổ biến trên nhiều distro. Format là thao tác phá hủy vì tạo metadata filesystem mới; do đó project yêu cầu xác nhận target chính xác.

Mountpoint chỉ là một thư mục. Khi filesystem được mount, nội dung cũ bên dưới tạm thời bị che khuất. `/etc/fstab` mô tả mount persistent khi boot. Project ghi entry bằng UUID thay vì tên `/dev/sdX` vì thứ tự thiết bị có thể đổi khi thêm disk. Một entry fstab sai có thể ảnh hưởng quá trình boot, nên toolkit backup file và thử `mount` ngay sau khi ghi.

LVM tạo lớp trừu tượng linh hoạt. `pvcreate` biến block device thành PV; một hoặc nhiều PV được gom vào VG; LV lấy dung lượng từ VG và xuất hiện như block device mới. Mở rộng VG chỉ tăng pool trống, chưa tăng LV. Mở rộng LV cũng chưa chắc đã tăng filesystem; project xử lý cả hai bước khi filesystem được hỗ trợ. Điều này đặc biệt hữu ích cho `/data`, nơi Samba, FTP hoặc website có thể cần tăng dung lượng sau khi triển khai.

Quota giới hạn mức sử dụng theo user hoặc group. Soft limit là ngưỡng cảnh báo có thể vượt trong grace period; hard limit là trần không được vượt. Block quota kiểm soát dung lượng, inode quota kiểm soát số file. Một user tạo rất nhiều file nhỏ có thể hết inode dù chưa dùng nhiều dung lượng, vì vậy hai loại giới hạn giải quyết hai rủi ro khác nhau.

Trước mọi thao tác ghi, project yêu cầu khảo sát:

```bash
./bin/netadmin storage disk list
./bin/netadmin storage disk free /dev/sdb
```

Người dùng phải đối chiếu size, model, filesystem và mountpoint để chắc chắn `/dev/sdb` là disk lab, không phải disk hệ điều hành. Ví dụ tạo partition, format và mount trực tiếp:

```bash
sudo ./bin/netadmin storage partition create \
  /dev/sdb 1MiB 100% gpt
sudo ./bin/netadmin storage filesystem format \
  /dev/sdb1 xfs DATA
sudo ./bin/netadmin storage filesystem mount \
  /dev/sdb1 /data defaults
```

Kịch bản LVM tương ứng:

```bash
sudo ./bin/netadmin storage lvm install
sudo ./bin/netadmin storage lvm pv-create /dev/sdb1
sudo ./bin/netadmin storage lvm vg-create vg_lab /dev/sdb1
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_data 10G
sudo ./bin/netadmin storage filesystem format \
  /dev/vg_lab/lv_data xfs DATA
sudo ./bin/netadmin storage filesystem mount \
  /dev/vg_lab/lv_data /data defaults
```

Quota được bật và áp dụng bằng:

```bash
sudo ./bin/netadmin storage quota enable /data
sudo ./bin/netadmin storage quota set \
  /data student 102400 122880 1000 1200
sudo ./bin/netadmin storage quota report /data
```

Kết quả cần kiểm tra bằng `storage filesystem list`, `storage lvm list` và quota report. Mount phải tồn tại trong trạng thái runtime lẫn fstab, LV phải hiển thị đúng VG và backing device, còn quota report phải phản ánh limit của user. Với storage, snapshot VM hoặc backup là điều kiện bắt buộc trước demo; dry run giúp xem command nhưng không thể thay thế việc xác minh đúng thiết bị.

## 2.6 Samba và giao thức SMB

SMB là giao thức chia sẻ file và printer phổ biến trong môi trường Windows. Samba là implementation SMB trên Linux, cho phép CentOS cung cấp thư mục cho Windows, Linux và macOS, đồng thời cho phép Linux truy cập share từ server khác. Samba không sử dụng FTP; FTP truyền file theo mô hình và giao thức riêng, còn SMB cung cấp trải nghiệm filesystem mạng với thư mục, quyền, file lock và session người dùng.

Một share có tên mạng dạng `\\server\\share` trên Windows hoặc `//server/share` trong công cụ Linux. Truy cập hiện đại chủ yếu dùng TCP 445. Các cổng NetBIOS 137–139 có thể xuất hiện trong môi trường cũ hoặc khi dùng dịch vụ browse/name legacy. Trên CentOS, `smb` phục vụ SMB, còn `nmb` hỗ trợ NetBIOS cũ.

Điểm quan trọng nhất khi chẩn đoán Samba là quyền truy cập có nhiều lớp. User đăng nhập đúng nhưng filesystem không cho đọc thì vẫn bị từ chối; chmod rộng nhưng Samba không cho user vào share cũng không giải quyết được; cả hai lớp trên đúng nhưng SELinux không cho `smbd` truy cập path thì client vẫn thất bại.

**Bảng 2.6. Ba lớp kiểm soát truy cập Samba**

| Lớp | Cơ chế | Câu hỏi kiểm tra |
|---|---|---|
| Samba | `valid users`, `read only`, `write list`, passdb | Tài khoản có được xác thực và được share cho phép không? |
| Filesystem Linux | owner, group, mode, setgid | Tiến trình Samba có quyền đọc/ghi path không? |
| SELinux | label và policy | Path có context cho phép Samba truy cập không? |

Samba user dựa trên một Linux user nhưng có password trong passdb riêng. Project tạo Linux account không có home và dùng shell `/sbin/nologin`, sau đó chạy `smbpasswd -a`. Cách này cho phép user truy cập file qua SMB mà không tự động cấp quyền đăng nhập shell. Group là đơn vị quản lý phù hợp hơn việc cấp từng user: thư mục dùng owner group, bit setgid giúp file mới kế thừa group, còn `valid users = @group` giới hạn thành viên được truy cập.

Public share cho phép guest và phù hợp demo nhanh trong mạng tin cậy. Protected share yêu cầu account và thường gắn với group. Read-only hoặc read-write phải đồng thời phù hợp ở cấu hình Samba và mode filesystem. Public read-write với mode `0777` thuận tiện cho lab nhưng không nên coi là cấu hình mặc định an toàn ngoài môi trường học tập.

Project cài các package server, client và CIFS bằng:

```bash
sudo ./bin/netadmin samba install
```

Command tạo global config nếu thiếu, chạy `testparm`, enable `smb` và `nmb`, đồng thời mở firewall service `samba`. Ví dụ tạo public share chỉ đọc:

```bash
sudo ./bin/netadmin samba share add-public \
  public /srv/samba/public read-only
```

Ví dụ tạo user và group share đọc ghi:

```bash
sudo ./bin/netadmin samba user add student labusers
sudo ./bin/netadmin samba share add-group \
  lessons /data/lessons labusers read-write
```

Toolkit tạo thư mục, đặt owner/group và mode, gắn context `samba_share_t`, backup `smb.conf`, thêm section có marker và chạy `testparm`. Với group share read-write, mode `2770` bảo đảm thành viên group được thao tác và file con kế thừa group. Nếu cần một group khác chỉ được đọc hoặc ghi theo chính sách bổ sung, command `permissions grant` điều chỉnh `read list` hoặc `write list`.

Sau khi tạo các share:

```bash
sudo ./bin/netadmin samba config check
sudo ./bin/netadmin samba config apply
sudo ./bin/netadmin samba service status
sudo ./bin/netadmin samba sessions
```

`config check` chỉ chứng minh cú pháp và option có thể được Samba hiểu; nó không chứng minh user nhập đúng password, path tồn tại hay SELinux đã cho phép runtime. `config apply` validate trước khi restart dịch vụ. `sessions` cho biết client đang kết nối và file đang mở, hữu ích trước khi restart trên hệ thống có người dùng.

Client có thể kiểm tra share bằng:

```bash
./bin/netadmin samba client list \
  //192.168.10.2/lessons student
```

Kết quả đạt yêu cầu khi client xác thực thành công, liệt kê được file, user có thể tạo hoặc sửa file đúng với chế độ share, file mới mang group mong đợi và session xuất hiện trên server. Khi gặp `Access denied`, quy trình chẩn đoán phải lần lượt kiểm tra Samba account và group, cấu hình hiệu lực từ `testparm`, quyền thư mục, context SELinux, firewall và đường dẫn client. Cách phân lớp này giúp xác định nguyên nhân thay vì dùng `chmod 777` hoặc tắt SELinux, hai biện pháp có thể che lỗi nhưng làm giảm an toàn hệ thống.

