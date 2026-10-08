# Chương 1 — CLI, Doctor và cơ chế an toàn

## 1. Entry point `netadmin`

File `bin/netadmin` là cửa vào duy nhất. Nó xác định thư mục dự án, nạp core, nạp từng module rồi chuyển command đến đúng handler.

```bash
./bin/netadmin help
./bin/netadmin version
./bin/netadmin <module> help
```

Nếu bạn gõ module không tồn tại, tool in root help rồi thoát với lỗi. Nếu thiếu tham số, tool in đúng cú pháp cần dùng.

### Vì sao dùng một entry point?

Nếu mỗi tính năng là một script độc lập, mỗi script phải tự viết lại log, kiểm tra root, backup và validation. Một entry point giúp hành vi nhất quán và giảm lỗi khi mở rộng.

## 2. `doctor run`

```bash
./bin/netadmin doctor
```

Doctor không sửa hệ thống. Nó kiểm tra nền tảng chung:

| Dòng output | Cần hiểu gì? |
|---|---|
| `OS` | Tên và version hệ điều hành đọc từ `/etc/os-release` |
| `Bash` | Version shell thực thi toolkit |
| `Privilege` | `root` hoặc `non-root` |
| `awk`, `grep`, ... | `OK` nếu command tồn tại; `MISSING` nếu thiếu |

Ví dụ output:

```text
CHECK              RESULT
OS                 CentOS Linux 7
Bash               4.2.46(2)-release
Privilege          non-root
awk                OK
grep               OK
sed                OK
install            OK
systemctl          OK
ip                 OK
```

`non-root` không phải lỗi nếu chỉ kiểm tra hoặc xem thông tin. Nó sẽ là vấn đề khi cài package hay sửa cấu hình.

Doctor không kiểm tra mọi dependency của mọi module. Ví dụ `named-checkzone` chỉ được yêu cầu khi bạn thao tác DNS zone.

## 3. Log của toolkit

| Prefix | Ý nghĩa |
|---|---|
| `[INFO]` | Thông tin đang thực hiện, thường không phải lỗi |
| `[OK]` | Tác vụ hoàn tất |
| `[WARN]` | Tác vụ vẫn tiếp tục nhưng có điều cần chú ý |
| `[ERROR]` | Tác vụ thất bại; exit code khác 0 |
| `[DRY-RUN]` | Command chỉ được in, chưa thực thi |

Để tắt màu khi redirect output vào file:

```bash
NO_COLOR=1 ./bin/netadmin doctor > doctor.txt
```

## 4. Dry-run

Dry-run giúp nhìn thấy command hệ thống trước khi thực thi:

```bash
sudo NETADMIN_DRY_RUN=1 ./bin/netadmin dns service restart
```

Output có thể là:

```text
[DRY-RUN] systemctl restart named
```

Giới hạn quan trọng:

- Chỉ command đi qua hàm `run` được bỏ qua.
- Các bước đọc file, validation input và kiểm tra dependency vẫn chạy.
- Một số command cần file/config thật tồn tại để đi hết luồng dry-run.
- Dry-run không phải môi trường giả lập hoàn chỉnh.

## 5. Xác nhận thông thường

Các thao tác như rollback hỏi:

```text
Khôi phục /etc/samba/smb.conf từ ...? [y/N]:
```

Chỉ `y` hoặc `Y` đồng ý. Enter mặc định là từ chối.

Có thể tự xác nhận trong automation:

```bash
sudo NETADMIN_ASSUME_YES=1 ./bin/netadmin samba config rollback
```

Không nên dùng biến này khi bạn chưa đọc kỹ command.

## 6. Xác nhận phá hủy

Partition, format và `pv-create` yêu cầu nhập lại chính xác target:

```text
[WARN] Thao tác có thể làm mất dữ liệu trên: /dev/sdb
Nhập chính xác '/dev/sdb' để tiếp tục:
```

`NETADMIN_ASSUME_YES=1` không bỏ qua bước này. Đây là lớp bảo vệ để giảm khả năng format nhầm disk.

## 7. Backup

Trước khi sửa file quan trọng, toolkit sao chép file hiện tại:

```text
/var/backups/netadmin/<module>/<basename>.<YYYYMMDD-HHMMSS>.bak
```

Ví dụ:

```text
/var/backups/netadmin/dhcp/dhcpd.conf.20261008-103012.bak
/var/backups/netadmin/samba/smb.conf.20261008-104501.bak
```

Backup giữ metadata bằng `cp -a`. Các module có thư mục riêng để không trộn lẫn.

## 8. Rollback thủ công và tự động

Rollback thủ công:

```bash
sudo ./bin/netadmin dhcp config rollback
sudo ./bin/netadmin dns config rollback
sudo ./bin/netadmin samba config rollback
```

Toolkit tìm backup mới nhất có cùng basename, hỏi xác nhận rồi chép trở lại.

Rollback tự động diễn ra khi:

- DHCP config mới không qua `dhcpd -t`.
- DNS config/zone không qua validator.
- Samba config không qua `testparm`.

Lưu ý `dns config rollback` khôi phục `named.conf`. Zone file được backup riêng, nên khi cần khôi phục zone thủ công phải chọn đúng file trong `/var/backups/netadmin/dns`.

## 9. Managed marker

Toolkit không cố hiểu hoặc viết lại toàn bộ cấu hình. Nó đánh dấu block do mình tạo:

```text
# NETADMIN:SCOPE:lab-lan:BEGIN
...
# NETADMIN:SCOPE:lab-lan:END
```

Khi xóa/cập nhật, toolkit chỉ tìm giữa hai marker có cùng loại và tên. Nhờ đó cấu hình viết tay bên ngoài block được giữ nguyên.

Không nên:

- Đổi tên một marker nhưng không đổi marker còn lại.
- Lồng block NetAdmin vào nhau.
- Xóa marker rồi mong `remove` tìm được block.

## 10. Rootfs thay thế

```bash
sudo NETADMIN_ROOT=/mnt/image ./bin/netadmin dhcp config show
```

Đường dẫn `/etc/dhcp/dhcpd.conf` sẽ được ánh xạ thành:

```text
/mnt/image/etc/dhcp/dhcpd.conf
```

Tính năng này hữu ích khi chuẩn bị image/chroot. Tuy nhiên command package, service, disk, user, `nmcli` và mount vẫn chạy trên host. Vì vậy không xem `NETADMIN_ROOT` là sandbox an toàn.

## 11. File cấu hình của toolkit

Toolkit tự tìm:

```text
config/netadmin.conf
```

File này chưa có mặc định. Sao chép template:

```bash
cp config/netadmin.conf.example config/netadmin.conf
```

Sau đó bỏ dấu `#` ở biến muốn thay đổi. Đây là Bash config và được `source`, vì vậy chỉ đặt nội dung bạn tin cậy trong file.

## 12. Cách xử lý khi command lỗi

Thực hiện theo thứ tự:

1. Đọc dòng `[ERROR]` đầu tiên.
2. Kiểm tra đã dùng `sudo` chưa.
3. Chạy `./bin/netadmin doctor`.
4. Kiểm tra dependency được nêu trong chương tương ứng.
5. Chạy `config check` của module.
6. Xem trạng thái service.
7. Xem log systemd bằng `journalctl -u <service>`.
8. Chỉ rollback nếu hiểu thay đổi nào cần bỏ.

Ví dụ DHCP không start:

```bash
sudo ./bin/netadmin dhcp config check
sudo ./bin/netadmin dhcp service status
sudo journalctl -u dhcpd --no-pager -n 100
```

