# Chương 8 — Thiết lập hai card mạng trên VMware Fusion

Tài liệu này ghi lại quy trình đã kiểm chứng trên VMware Fusion với VM AlmaLinux ARM. Mục tiêu là giữ một card NAT để truy cập Internet và tạo một card private riêng cho các bài lab DHCP/DNS/Samba.

## 1. Kết quả cần đạt

```text
VM Server
├── NIC 1: NAT / Share with my Mac
│   ├── Nhận IP động từ VMware
│   └── Giữ default route ra Internet
└── NIC 2: Private/custom network
    ├── IP tĩnh 192.168.10.2/24
    ├── Không tạo default route
    └── Dùng cho DHCP, DNS và Samba lab
```

Kết quả thực tế trong lần thiết lập này:

| Vai trò | Device | Connection | Địa chỉ |
|---|---|---|---|
| NAT/Internet | `enp2s0` | `enp2s0` | `192.168.65.129/24` do VMware cấp |
| Lab | `enp26s0` | `netadmin-lab` | `192.168.10.2/24` tĩnh |

Tên device có thể khác trên VM khác. Không sao chép `enp2s0` hoặc `enp26s0` nếu output máy bạn dùng tên khác.

## 2. Vì sao cần hai card mạng?

Nếu chỉ có một card và đổi nó sang `192.168.10.2/24`, VM có thể mất:

- Default route ra Internet.
- DNS do VMware cung cấp.
- Kết nối SSH từ máy host.
- Khả năng cài package bằng `dnf`/`yum`.

Hai card tách hai vai trò:

- NAT chỉ phục vụ quản trị và tải package.
- Private NIC chỉ phục vụ mạng thực hành.

## 3. Thêm Network Adapter trong VMware Fusion

Tắt VM hoàn toàn bằng **Shut Down**, không dùng Suspend.

Trong cửa sổ VM Settings:

1. Nhấn **Add Device…**.
2. Chọn **Network Adapter**.
3. Nhấn **Add**.
4. Giữ card cũ ở chế độ **Share with my Mac**.
5. Đặt card mới thành **Private to my Mac** hoặc custom private network.
6. Bật **Connect Network Adapter** cho cả hai card.

Sau khi thêm, Settings phải có hai biểu tượng:

```text
Network Adapter
Network Adapter 2
```

### DHCP của VMware trên private network

Để test DHCP server của toolkit, mạng lab không được có DHCP server thứ hai. Nếu VMware Fusion cho phép tạo custom network:

1. Mở VMware Fusion Settings/Preferences.
2. Mở phần Network.
3. Tạo custom network, ví dụ `NETADMIN-LAB`.
4. Bỏ chọn **Provide addresses on this network via DHCP**.
5. Gắn NIC lab của cả Server và Client vào cùng network này.

Nếu dùng `Private to my Mac` mặc định, cần xác nhận VMware DHCP đã tắt trước khi bật `dhcpd` của toolkit.

## 4. Kiểm tra hệ điều hành đã nhận card mới

Khởi động hoặc reboot VM, rồi chạy:

```bash
nmcli device status
ip -br link
```

Phân biệt hai lệnh:

- `nmcli device status` hiện mọi network device NetworkManager nhìn thấy.
- `nmcli connection show` chủ yếu hiện connection profile đã được tạo.

Một card có thể xuất hiện trong `device status` nhưng chưa xuất hiện trong `connection show` nếu chưa có profile.

Ví dụ trước khi tạo profile:

```text
DEVICE   TYPE      STATE                   CONNECTION
enp2s0   ethernet  connected               enp2s0
lo       loopback  connected (externally)  lo
enp26s0  ethernet  disconnected            --
```

Ý nghĩa:

- Kernel và NetworkManager đã nhận `enp26s0`.
- Card chưa có connection profile nên đang disconnected.

Nếu card thứ hai không xuất hiện:

1. Kiểm tra **Connect Network Adapter** trong VMware.
2. Kiểm tra VM đã reboot sau khi thêm card.
3. Chạy lại `ip -br link`.
4. Không tạo profile với một tên device tự đoán.

## 5. Phân biệt device và connection profile

Đây là nguyên nhân chính của các lỗi đã gặp.

### Device/interface

Device là card mà kernel nhìn thấy, ví dụ:

```text
enp2s0
enp26s0
```

### Connection profile

Connection là bộ cấu hình NetworkManager áp dụng lên device, ví dụ:

```text
enp2s0
netadmin-lab
Wired connection 2
```

Xem cả hai:

```bash
nmcli device status
nmcli -f NAME,UUID,TYPE,DEVICE connection show
```

Trong `connection show`:

- Cột `NAME` là giá trị truyền vào `nmcli connection modify` hoặc toolkit.
- Cột `DEVICE` là card đang dùng profile đó.

Không giả định profile luôn có tên `System <device>`.

## 6. Xác định card NAT

Chạy:

```bash
ip route
```

Card NAT là card xuất hiện trong default route:

```text
default via 192.168.65.2 dev enp2s0
```

Trong ví dụ này, `enp2s0` là card NAT. Không đặt IP lab lên card đó.

Có thể kiểm tra thêm:

```bash
ip -4 address show enp2s0
```

Ví dụ:

```text
inet 192.168.65.129/24 scope global dynamic enp2s0
```

Từ `dynamic` cho thấy địa chỉ được cấp qua DHCP của VMware.

## 7. Tạo profile cho card lab

Giả sử `nmcli device status` xác nhận card lab thật là `enp26s0`:

```bash
sudo nmcli connection add \
  type ethernet \
  ifname enp26s0 \
  con-name netadmin-lab
```

Cú pháp rút gọn:

```bash
sudo nmcli con add type ethernet ifname enp26s0 con-name netadmin-lab
```

Chỉ có một `ifname`. Cấu trúc là:

```text
nmcli connection add
      type ethernet
      ifname <device thật>
      con-name <tên profile mới>
```

Kiểm tra profile đang gắn vào device nào:

```bash
nmcli -g connection.interface-name \
  connection show netadmin-lab
```

Kết quả phải là:

```text
enp26s0
```

## 8. Ngăn card lab chiếm default route

```bash
sudo nmcli connection modify \
  netadmin-lab \
  ipv4.never-default yes
```

Điều này cho phép profile có gateway theo cấu hình bài lab nhưng NetworkManager không dùng gateway đó làm default route của server.

Kiểm tra:

```bash
nmcli -g ipv4.never-default connection show netadmin-lab
```

Kỳ vọng:

```text
yes
```

## 9. Đặt IP tĩnh bằng NetAdmin Toolkit

```bash
sudo ./bin/netadmin dns network static \
  netadmin-lab \
  192.168.10.2/24 \
  192.168.10.1 \
  127.0.0.1,1.1.1.1
```

Ý nghĩa:

- `netadmin-lab`: connection profile, không phải tên device.
- `192.168.10.2/24`: IP server trên LAN lab.
- `192.168.10.1`: gateway được dùng trong topology lab.
- `127.0.0.1,1.1.1.1`: DNS local và DNS ngoài dự phòng.

Toolkit chạy `nmcli connection modify` rồi active profile.

## 10. Xác minh cuối cùng

```bash
nmcli device status
ip -br -4 address
ip route
ping -c 3 1.1.1.1
```

Kết quả đúng:

```text
DEVICE   TYPE      STATE      CONNECTION
enp2s0   ethernet  connected  enp2s0
enp26s0  ethernet  connected  netadmin-lab
```

Địa chỉ:

```text
enp2s0   192.168.65.129/24
enp26s0  192.168.10.2/24
```

Routing:

```text
default via 192.168.65.2 dev enp2s0
192.168.10.0/24 dev enp26s0
192.168.65.0/24 dev enp2s0
```

Không được có default route qua `enp26s0`:

```text
default via 192.168.10.1 dev enp26s0
```

PASS khi:

- Hai card đều `connected`.
- Mỗi card có đúng subnet.
- Default route chỉ đi qua NAT.
- Ping `1.1.1.1` thành công.

## 11. Lỗi: `unknown connection 'System enp0s8'`

Ví dụ lỗi:

```text
Error: unknown connection 'System enp0s8'.
```

Nguyên nhân: `System enp0s8` chỉ là tên ví dụ, không tồn tại trên máy.

Tìm tên thật:

```bash
nmcli -f NAME,UUID,TYPE,DEVICE connection show
```

Luôn dùng cột `NAME`, ví dụ:

```bash
sudo nmcli connection modify netadmin-lab ipv4.never-default yes
```

## 12. Lỗi: `argument 'connected' not understood`

Ví dụ command sai:

```text
nmcli connected add ...
```

Subcommand đúng là `connection`, không phải `connected`:

```bash
sudo nmcli connection add \
  type ethernet \
  ifname enp26s0 \
  con-name netadmin-lab
```

Không nhập `ifname ethernet ifname ...`; `ethernet` là giá trị của `type`, còn `ifname` chỉ nhận tên device.

## 13. Lỗi: `mismatching interface name`

Ví dụ:

```text
No suitable device found for this connection
(device enp26s0 not available because profile is not compatible
with device: mismatching interface name)
```

Nguyên nhân: profile được tạo với `ifname enp2s1`, nhưng card thật là `enp26s0`.

Sửa mà không cần xóa profile:

```bash
sudo nmcli connection modify \
  netadmin-lab \
  connection.interface-name enp26s0
```

Sau đó active lại hoặc chạy tool static.

## 14. Khôi phục khi cấu hình nhầm card NAT

Nếu vô tình chạy static trên `enp2s0`:

```bash
sudo ./bin/netadmin dns network static \
  enp2s0 192.168.10.2/24 \
  192.168.10.1 127.0.0.1,1.1.1.1
```

hãy khôi phục card NAT về DHCP từ console VM:

```bash
sudo ./bin/netadmin dns network dhcp enp2s0
```

Kiểm tra:

```bash
ip -4 address show enp2s0
ip route
```

Kết quả thực tế sau khi khôi phục:

```text
inet 192.168.65.129/24 scope global dynamic enp2s0
default via 192.168.65.2 dev enp2s0 proto dhcp
```

Không reboot trước khi sửa vì profile static sai được lưu persistent.

## 15. Card mạng không làm mất dữ liệu trên disk

Thêm Network Adapter không xóa virtual hard disk. Nếu sau khi boot có vẻ mất dữ liệu, dừng thao tác ghi và kiểm tra:

```bash
whoami
echo "$HOME"
ls -la "$HOME"
findmnt /
findmnt "$HOME"
lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

Trong VMware Fusion kiểm tra, nhưng chưa bấm Revert/Delete:

- Hard Disk đang gắn đúng file/dung lượng.
- Startup Disk là Hard Disk, không phải installer ISO.
- CD/DVD có đang connect ISO khi boot không.
- Snapshot Manager có tự quay về snapshot cũ không.

Các nguyên nhân thường là boot nhầm ISO/disk, login nhầm user, `/home` chưa mount hoặc revert snapshot; không phải bản thân Network Adapter xóa file.

## 16. Checklist ngắn

```text
[ ] VM đã shutdown trước khi thêm NIC
[ ] NIC 1 = Share with my Mac
[ ] NIC 2 = Private/custom network
[ ] DHCP VMware trên lab network đã tắt
[ ] nmcli device status thấy hai Ethernet device
[ ] Đã xác định NAT device bằng default route
[ ] netadmin-lab gắn đúng device thứ hai
[ ] ipv4.never-default = yes trên netadmin-lab
[ ] NAT nhận IP động
[ ] Lab NIC có 192.168.10.2/24
[ ] Default route vẫn qua NAT
[ ] Ping Internet thành công
```

Chỉ sau khi toàn bộ checklist PASS mới tiếp tục bật DHCP server trong lab.

