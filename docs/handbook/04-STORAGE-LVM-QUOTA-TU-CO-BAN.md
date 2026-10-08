# Chương 4 — Disk, filesystem, LVM và quota từ cơ bản

## 1. Cảnh báo quan trọng

Storage khác DHCP/DNS: cấu hình sai có thể làm mất dữ liệu ngay. Trước mọi thao tác ghi:

1. Chụp snapshot VM hoặc backup dữ liệu.
2. Dùng `lsblk` nhận diện disk theo size/model.
3. Phân biệt disk hệ điều hành và disk lab.
4. Không đoán `/dev/sdb` chỉ vì bài hướng dẫn dùng tên đó.
5. Đọc lại target trước khi nhập xác nhận.

Trong VM, hãy thêm một virtual disk riêng để thực hành.

## 2. Mô hình lớp lưu trữ

Không dùng LVM:

```text
/dev/sdb → /dev/sdb1 → XFS → /data
 disk       partition   fs     mountpoint
```

Dùng LVM:

```text
/dev/sdb1 → PV → VG vg_lab → LV lv_data → XFS → /data
```

Tên `/dev/sda`, `/dev/sdb` có thể thay đổi giữa các lần boot. UUID filesystem ổn định hơn, nên fstab dùng UUID.

## 3. Tool `storage disk list`

```bash
./bin/netadmin storage disk list
```

Các cột:

| Cột | Ý nghĩa |
|---|---|
| `NAME` | Tên ngắn, ví dụ `sdb1` |
| `PATH` | Đường dẫn `/dev/sdb1` |
| `SIZE` | Dung lượng |
| `TYPE` | `disk`, `part`, `lvm`... |
| `FSTYPE` | `xfs`, `ext4`, `LVM2_member`... |
| `MOUNTPOINTS` | Nơi filesystem đang gắn |
| `MODEL` | Model giúp nhận diện disk |

Ví dụ:

```text
sda  /dev/sda  40G disk              Virtual Disk
├─sda1          1G part xfs /boot
└─sda2         39G part LVM2_member
sdb  /dev/sdb  20G disk              Virtual Disk
```

`sdb` chưa có con, chưa có FSTYPE và chưa mount là dấu hiệu disk trống, nhưng vẫn phải xác minh trong hypervisor.

## 4. Tool `storage disk free`

```bash
./bin/netadmin storage disk free /dev/sdb
```

Tool dùng `parted ... print free` để hiển thị partition table và vùng `Free Space`. Đây là read-only.

Nếu thấy `unrecognised disk label`, disk chưa có partition table. Bạn có thể tạo GPT trong bước partition.

## 5. Tool `storage partition create`

```bash
sudo ./bin/netadmin storage partition create \
  <device> <start> <end> [gpt|msdos]
```

Ví dụ dùng toàn bộ disk:

```bash
sudo ./bin/netadmin storage partition create /dev/sdb 1MiB 100% gpt
```

### Từng tham số

- `device`: toàn bộ disk như `/dev/sdb`, không phải mountpoint.
- `start`: vị trí bắt đầu. `1MiB` giúp alignment tốt và chừa vùng metadata đầu disk.
- `end`: vị trí kết thúc; `100%` là cuối disk.
- `gpt|msdos`: partition table tùy chọn.

Nếu truyền `gpt` hoặc `msdos`, `mklabel` thay partition table hiện tại. Các partition cũ sẽ mất khỏi bảng. Đây là lý do tool yêu cầu nhập lại device.

Sau `parted`, tool chạy `partprobe` và `udevadm settle` để kernel/udev tạo device mới như `/dev/sdb1`.

Kiểm tra:

```bash
./bin/netadmin storage disk list
```

## 6. Tool `storage filesystem format`

```bash
sudo ./bin/netadmin storage filesystem format \
  <partition> <xfs|ext4|ext3> [label]
```

Ví dụ:

```bash
sudo ./bin/netadmin storage filesystem format /dev/sdb1 xfs DATA
```

### Chọn filesystem

- **XFS**: mặc định phổ biến trên CentOS/RHEL; mở rộng online tốt; không shrink bằng tool chuẩn.
- **ext4**: phổ biến, linh hoạt; có thể grow và có quy trình shrink offline riêng.
- **ext3**: cũ, chỉ dùng khi bài học yêu cầu tương thích.

Tool từ chối device đang mount, nhưng vẫn không thể biết mọi trường hợp device đang chứa dữ liệu quan trọng. `-f`/`-F` buộc mkfs ghi filesystem mới sau bước xác nhận.

Label là tên dễ đọc, không thay thế UUID. Kiểm tra kết quả:

```bash
lsblk -f
sudo blkid /dev/sdb1
```

## 7. Tool `storage filesystem mount`

```bash
sudo ./bin/netadmin storage filesystem mount \
  <partition> <mountpoint> [options]
```

Ví dụ:

```bash
sudo ./bin/netadmin storage filesystem mount /dev/sdb1 /data defaults
```

Tool:

1. Dùng `blkid` lấy UUID và FSTYPE.
2. Tạo `/data` nếu thiếu.
3. Backup `/etc/fstab`.
4. Thêm dòng dạng:

```text
UUID=... /data xfs defaults 0 0
```

5. Chạy `mount /data` để kiểm tra entry vừa ghi.

Mountpoint là thư mục. Khi filesystem mount vào đó, nội dung cũ trong thư mục tạm bị che khuất chứ không bị xóa; unmount sẽ thấy lại.

Một số option phổ biến:

- `defaults`: tập option mặc định.
- `noexec`: không chạy binary trực tiếp từ filesystem.
- `nodev`: không diễn giải device file.
- `nosuid`: bỏ setuid/setgid executable.
- `nofail`: boot vẫn tiếp tục nếu device thiếu.

Tool nhận option như một chuỗi không có khoảng trắng, ví dụ `defaults,nodev`.

## 8. Tool `storage filesystem list`

```bash
./bin/netadmin storage filesystem list
```

Phần đầu `lsblk -f` cho cấu trúc block device. Phần sau `findmnt --real` cho mount thực. So sánh với `/etc/fstab`: fstab là mong muốn lúc boot, findmnt là trạng thái hiện tại.

## 9. LVM: PV, VG và LV

### PV

PV đánh dấu block device là thành viên LVM. `pvcreate` ghi metadata LVM, có thể phá dữ liệu cũ.

### VG

VG gom dung lượng từ một hay nhiều PV thành pool.

### LV

LV lấy một phần dung lượng VG và xuất hiện như block device, ví dụ `/dev/vg_lab/lv_data`. Sau đó vẫn phải format và mount như partition.

## 10. Tool `storage lvm install/list`

```bash
sudo ./bin/netadmin storage lvm install
sudo ./bin/netadmin storage lvm list
```

`install` cài `lvm2`. `list` lần lượt chạy:

- `pvs`: physical volumes.
- `vgs`: volume groups và dung lượng free.
- `lvs -a -o +devices`: logical volumes và backing devices.

## 11. Tool `storage lvm pv-create`

```bash
sudo ./bin/netadmin storage lvm pv-create /dev/sdb1
```

Tool kiểm tra block device và yêu cầu nhập lại target. Sau đó chạy `pvcreate`. Kiểm tra bằng `pvs`.

Không format XFS/ext4 trước nếu partition được dùng trực tiếp làm PV. LVM metadata và filesystem không cùng nằm ở một tầng.

## 12. Tool vg-create/vg-extend

Tạo VG:

```bash
sudo ./bin/netadmin storage lvm vg-create vg_lab /dev/sdb1
```

Thêm PV mới vào VG:

```bash
sudo ./bin/netadmin storage lvm pv-create /dev/sdc1
sudo ./bin/netadmin storage lvm vg-extend vg_lab /dev/sdc1
```

`vg-extend` không tự mở rộng LV; nó chỉ tăng free space của pool.

## 13. Tool `storage lvm lv-create`

```bash
sudo ./bin/netadmin storage lvm lv-create <vg> <lv> <size>
```

Ví dụ cố định 10 GiB:

```bash
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_data 10G
```

Dùng toàn bộ extent còn trống:

```bash
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_data 100%FREE
```

Sau đó:

```bash
sudo ./bin/netadmin storage filesystem format /dev/vg_lab/lv_data xfs DATA
sudo ./bin/netadmin storage filesystem mount /dev/vg_lab/lv_data /data
```

## 14. Tool `storage lvm lv-extend`

```bash
sudo ./bin/netadmin storage lvm lv-extend \
  <lv-path> <size>
```

Ví dụ thêm 5 GiB:

```bash
sudo ./bin/netadmin storage lvm lv-extend /dev/vg_lab/lv_data +5G
```

Tool chạy hai tầng:

1. `lvextend` mở rộng block device LV.
2. `xfs_growfs` hoặc `resize2fs` mở rộng filesystem.

Với XFS, filesystem phải đang mount. Với filesystem chưa hỗ trợ, LV vẫn có thể đã lớn hơn nhưng tool chỉ cảnh báo và không resize filesystem.

Kiểm tra trước/sau:

```bash
sudo lvs
df -h /data
```

`lvs` lớn mà `df` chưa lớn nghĩa là filesystem chưa được grow.

## 15. Quota là gì?

Quota giới hạn tài nguyên filesystem cho user:

- **Block limit**: dung lượng dữ liệu.
- **Inode limit**: số file/directory.
- **Soft limit**: có thể vượt tạm trong grace period.
- **Hard limit**: không được vượt.

Một user có thể dùng ít dung lượng nhưng tạo hàng triệu file nhỏ, vì vậy inode quota có ý nghĩa riêng.

## 16. Tool `storage quota enable`

```bash
sudo ./bin/netadmin storage quota enable /data
```

Yêu cầu `/data` đã là mountpoint. Tool cài `quota`, backup fstab, thêm:

- `uquota,gquota` cho XFS.
- `usrquota,grpquota` cho filesystem khác.

Sau đó remount. Với non-XFS, tool còn chạy `quotacheck -cugm` và `quotaon -vug`.

## 17. Tool quota set/report

```bash
sudo ./bin/netadmin storage quota set \
  /data student 102400 122880 1000 1200
```

Thứ tự số:

1. Soft block.
2. Hard block.
3. Soft inode.
4. Hard inode.

`0` thường mang nghĩa không giới hạn cho trường đó. Đơn vị block tùy filesystem/quota implementation; luôn đọc report thay vì giả định.

```bash
sudo ./bin/netadmin storage quota report /data
```

Report hiển thị usage và limit của từng user.

## 18. Lỗi thường gặp

- **not a block device**: truyền mountpoint hoặc path sai thay vì `/dev/...`.
- **device is busy**: device đang mount/được process dùng.
- **unknown filesystem type**: thiếu `xfsprogs`/`e2fsprogs` hoặc filesystem lỗi.
- **mount: wrong fs type/bad superblock**: FSTYPE sai, chưa format hoặc metadata hỏng.
- **duplicate fstab entry**: mountpoint đã có dòng trong fstab; kiểm tra trước khi thêm.
- **insufficient free space**: VG không đủ free extent.
- **XFS must be mounted to grow**: mount LV rồi chạy extend/grow.
- **quota không có tác dụng**: mount option chưa active; xem `findmnt -o OPTIONS /data`.

## 19. Bài lab không LVM

```bash
./bin/netadmin storage disk list
./bin/netadmin storage disk free /dev/sdb
sudo ./bin/netadmin storage partition create /dev/sdb 1MiB 100% gpt
sudo ./bin/netadmin storage filesystem format /dev/sdb1 xfs DATA
sudo ./bin/netadmin storage filesystem mount /dev/sdb1 /data
./bin/netadmin storage filesystem list
```

## 20. Bài lab LVM và quota

```bash
sudo ./bin/netadmin storage lvm install
sudo ./bin/netadmin storage lvm pv-create /dev/sdb1
sudo ./bin/netadmin storage lvm vg-create vg_lab /dev/sdb1
sudo ./bin/netadmin storage lvm lv-create vg_lab lv_data 10G
sudo ./bin/netadmin storage filesystem format /dev/vg_lab/lv_data xfs DATA
sudo ./bin/netadmin storage filesystem mount /dev/vg_lab/lv_data /data
sudo ./bin/netadmin storage quota enable /data
sudo ./bin/netadmin storage quota set /data student 102400 122880 1000 1200
sudo ./bin/netadmin storage quota report /data
```

