# Hướng dẫn demo NetAdmin Toolkit trong 13–15 phút

Tài liệu này là kịch bản trình bày ngắn gọn, bám sát mã nguồn và giao diện hiện tại của dự án. Môi trường demo đang được giả định là **CentOS Stream 10 + Cockpit**.

> Lưu ý quan trọng: CentOS Stream 10 không còn ISC DHCP. Module cho phép xem luồng và dữ liệu mẫu khi Dry run bật, đồng thời ghi rõ đây là dữ liệu mô phỏng. Thực thi DHCP thật vẫn cần hệ RHEL 9 hoặc một backend Kea mới.

## 1. Mục tiêu và phân bổ thời gian

| Phần | Nội dung | Thời gian |
|---|---|---:|
| Slide 1 | Chủ đề và nhóm thực hiện | 45 giây |
| Slide 2 | Mục đích đề tài | 1 phút 15 giây |
| Slide 3 | Mô hình hệ thống | 1 phút 30 giây |
| Slide 4 | Quy trình thực hiện | 45 giây |
| Slide 5 | Demo trực tiếp trên Cockpit | 7 phút 15 giây |
| Slide 6 | Kết luận | 1 phút 10 giây |
| Slide 7 | Phân công công việc | 50 giây |
| Slide 8 | Cảm ơn | 15 giây |
| **Tổng** | | **Khoảng 13 phút 45 giây** |

Không kéo dài phần giới thiệu. Nếu còn thời gian, ưu tiên giải thích output thật trong demo hoặc dành cho câu hỏi.

## 2. Checklist trước ngày trình bày

### 2.1. Đồng bộ và cài lại runtime Cockpit

```bash
cd ~/centos-auto-config-tools
git pull origin main
chmod +x bin/netadmin scripts/*.sh scripts/*.mjs
sudo ./bin/netadmin ui install
sudo systemctl restart cockpit.socket
```

Đăng xuất Cockpit, đăng nhập lại và nhấn `Ctrl + Shift + R` để trình duyệt bỏ cache cũ.

### 2.2. Cài dependency dùng trong demo

Các lệnh dưới đây phải chạy với Dry run tắt. Chạy trong Terminal sẽ thực thi thật theo mặc định:

```bash
cd ~/centos-auto-config-tools
sudo ./bin/netadmin dns install
sudo ./bin/netadmin web install
```

Không cần cài toàn bộ Mail, Samba và FTP nếu không sử dụng chúng trong kịch bản demo.

### 2.3. Kiểm tra command và dịch vụ

```bash
command -v nmcli named-checkconf named-checkzone dig apachectl lsblk
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin web config check
sudo systemctl is-active cockpit.socket named httpd
```

Kết quả mong đợi:

- Các lệnh `command -v` đều trả về một đường dẫn.
- Hai lệnh kiểm tra cấu hình không báo lỗi cú pháp.
- `cockpit.socket`, `named` và `httpd` trả về `active`.

### 2.4. Chạy audit mã nguồn

```bash
./scripts/audit-static.sh
```

Dòng cuối mong đợi:

```text
Static audit: 0 failure(s).
```

Audit tĩnh xác nhận mapping và cú pháp, không thay thế kiểm thử dịch vụ thật.

### 2.5. Chuẩn bị trình duyệt

- Mở `https://127.0.0.1:9090/netadmin` nếu trình bày ngay trong VM.
- Nếu mở từ máy Mac, dùng `https://<IP-CENTOS>:9090/netadmin`.
- Đăng nhập trước khi bắt đầu.
- Bật **Administrative access** trong Cockpit.
- Đặt zoom trình duyệt khoảng 90–100%.
- Mở sẵn NetAdmin Tools và một cửa sổ Terminal dự phòng.
- Giữ **Dry run bật** khi bắt đầu demo.
- Đóng các cửa sổ chứa mật khẩu hoặc thông tin cá nhân.

## 3. Kịch bản trình bày theo slide

## Slide 1 — Chủ đề và nhóm thực hiện — 45 giây

**Nói:**

> Kính thưa thầy và các bạn. Nhóm em xin trình bày đề tài “Xây dựng bộ công cụ tự động cấu hình trên CentOS”, với sản phẩm NetAdmin Toolkit. Nhóm gồm Đoàn Văn Khoan, Trần Gia Hân, Nguyễn Vương Hoàng Tịnh và Nguyễn Thành Nhân. Đề tài tập trung chuẩn hóa các bài thực hành quản trị mạng thành một CLI Bash thống nhất và một giao diện Cockpit dễ sử dụng.

**Chuyển ý:**

> Trước tiên, nhóm em xin trình bày vấn đề và mục tiêu của đề tài.

## Slide 2 — Mục đích đề tài — 1 phút 15 giây

**Nói:**

> Khi thực hành quản trị mạng, người học phải nhớ nhiều câu lệnh, package, service và tệp cấu hình khác nhau. Nếu thao tác sai, lỗi có thể đến từ cú pháp, quyền, firewall, SELinux hoặc thứ tự cấu hình. Mục tiêu của nhóm là gom các use case này vào một quy trình thống nhất: chọn công cụ, nhập tham số, xem lệnh Bash, thực thi và đọc kết quả.

> Dự án hiện có 8 nhóm nghiệp vụ và 123 thao tác trên giao diện. Giao diện không che giấu Linux mà luôn hiển thị lệnh `netadmin` tương ứng. Dự án còn có validation, Dry run, xác nhận thao tác nhạy cảm và backup hoặc rollback cho các cấu hình phù hợp.

**Điểm cần nhấn mạnh:**

- 8 nhóm nghiệp vụ: Doctor, DNS, DHCP, Storage, Samba, Web, FTP và Mail.
- 123 là số thao tác được map lên UI, không phải tuyên bố 123 thao tác đã được nghiệm thu trên mọi phiên bản Linux.

## Slide 3 — Mô hình của đề tài — 1 phút 30 giây

**Nói:**

> Luồng bắt đầu từ trình duyệt. Người dùng chọn tool trong NetAdmin Tools, nhập tham số và xem trước lệnh. Cockpit dùng cơ chế bridge để gọi một điểm vào duy nhất là `/usr/local/bin/netadmin`; dự án không cần xây thêm một HTTP backend riêng.

> Bên dưới CLI là core dùng chung gồm validation, logging, backup, prompt an toàn và system runner. Mỗi nhóm nghiệp vụ được tách thành module riêng. Module sau đó làm việc với dịch vụ thật như NetworkManager, BIND, Samba, Apache, Postfix, Dovecot, systemd, firewalld và SELinux.

> Dry run chỉ mô phỏng lệnh; khi tắt Dry run, Cockpit mới yêu cầu quyền quản trị và thay đổi hệ thống. UI và Terminal dùng cùng hợp đồng CLI nên có thể kiểm tra chéo và có phương án dự phòng khi giao diện gặp sự cố.

**Không nói:** “Cockpit chạy lệnh trực tiếp không cần backend nào.”

**Nên nói:** “Không cần backend HTTP tự xây; Cockpit bridge là runtime trung gian có xác thực và quản lý quyền.”

## Slide 4 — Các bước thực hiện — 45 giây

**Nói:**

> Nhóm thực hiện theo năm bước: khảo sát bài học và AutoScript, chuẩn hóa use case thành hợp đồng CLI, tách core và module, tích hợp Cockpit gọi lại cùng CLI, sau đó kiểm tra theo các lớp từ cú pháp đến dịch vụ và client. Nguyên tắc của nhóm là không tắt firewall hoặc SELinux để né lỗi và không thực thi thao tác phá hủy nếu chưa xác nhận đúng mục tiêu.

**Chuyển ý:**

> Sau đây là phần demo trực tiếp.

## Slide 5 — Demo — 7 phút 15 giây

Khi slide “DEMO” xuất hiện, chuyển ngay sang Cockpit. Trong mỗi bước, nói theo ba ý: **đang chọn gì — lệnh nào chạy — kết quả chứng minh điều gì**.

### Bước 1. Giới thiệu giao diện — 45 giây

**Thao tác:**

1. Mở NetAdmin Tools.
2. Chỉ vào menu module, ô tìm kiếm, danh sách tool, panel tham số và công tắc Dry run.
3. Chỉ trạng thái “Cockpit đã kết nối”.

**Nói:**

> Bên trái là các module, ở giữa là danh sách thao tác và bên phải là tham số cùng lệnh Bash được sinh ra. Dry run đang bật nên thao tác thay đổi hệ thống chỉ được mô phỏng. Giao diện đang chạy bên trong Cockpit nên có thể gọi CLI thật và nhận output theo thời gian thực.

### Bước 2. Doctor — 1 phút

**Thao tác:** Doctor → Kiểm tra môi trường → Chạy tool.

**Nói:**

> Doctor kiểm tra hệ điều hành, Bash, quyền và các command lõi. Máy demo dùng CentOS Stream 10 nên kết quả là `PARTIAL`, không phải hệ thống bị hỏng. Nguyên nhân là CentOS 10 đã loại bỏ ISC DHCP, còn các module được dùng trong demo vẫn hoạt động sau khi cài dependency.

**Kết quả cần chỉ:**

- OS là CentOS Stream 10.
- Các command lõi hiển thị `OK`.
- Dòng `Runtime support: PARTIAL` được giải thích chủ động.

Không nói “Doctor đã kiểm tra đầy đủ mọi package của 123 tool”. Doctor chỉ kiểm tra môi trường lõi; dependency chi tiết được kiểm tra theo module và bằng `scripts/audit-runtime.sh`.

### Bước 3. Quan sát NetworkManager — 1 phút

**Thao tác:** DNS → Liệt kê kết nối mạng → Chạy tool.

**Nói:**

> Công cụ đọc trực tiếp connection của NetworkManager. Tên connection và interface có thể khác nhau, vì vậy dự án không hard-code `enp2s0` cho mọi máy. Người dùng phải lấy đúng tên ở bước này trước khi đặt IP tĩnh hoặc thay đổi DHCP client.

Tool hiện chấp nhận cả tên connection profile và tên interface. Nếu nhập interface như `enp26s0`, CLI sẽ tự ánh xạ sang profile đang hoạt động, ví dụ `netadmin-lab`.

**Kết quả cần chỉ:** connection đang hoạt động và interface tương ứng.

### Bước 4. Kiểm tra BIND và danh sách zone — 1 phút 15 giây

**Thao tác:**

1. DNS → DNS config: check → Chạy tool.
2. DNS → Liệt kê DNS zones → Chạy tool.

**Nói:**

> Trước khi restart BIND, dự án gọi công cụ kiểm tra cấu hình thật của dịch vụ. Nếu cấu hình hợp lệ, ta mới tiếp tục vận hành. Danh sách zone chỉ hiển thị các block do NetAdmin quản lý, giúp tránh sửa nhầm những cấu hình ngoài phạm vi dự án.

**Nếu danh sách zone trống:**

> Máy demo hiện chưa tạo zone bằng NetAdmin nên danh sách trống; đây không phải lỗi. Muốn thêm record, bắt buộc phải tạo zone trước.

Không chạy “Thêm DNS record” nếu chưa có zone tương ứng. Với `lab.local`, file do dự án tạo sẽ có dạng `/var/named/db.lab-local`.

### Bước 5. Mô phỏng tạo website — 1 phút 30 giây

**Thao tác:**

1. Chọn Web → Tạo website.
2. Domain: `demo.lab.local`.
3. DocumentRoot: `/var/www/demo.lab.local`.
4. Giữ Dry run bật.
5. Chỉ lệnh xem trước rồi chạy.

**Nói:**

> Đây là một use case thay đổi hệ thống. UI kiểm tra domain và đường dẫn tuyệt đối, sau đó hiển thị lệnh CLI hoàn chỉnh. Vì Dry run đang bật, dự án chỉ in các thao tác dự kiến như tạo thư mục, file cấu hình và kiểm tra Apache; chưa tạo website thật.

**Kết quả cần chỉ:** output có `[DRY-RUN]` và trạng thái “Mô phỏng hoàn tất; hệ thống chưa được thay đổi”.

Nếu xuất hiện thiếu `apachectl`, phần cài Web chưa được chạy thật. Không tiếp tục sửa trong lúc trình bày; chuyển sang bước Storage và dùng phương án Terminal sau buổi demo.

### Bước 6. Storage và cơ chế an toàn — 1 phút 15 giây

**Thao tác:**

1. Storage → Liệt kê ổ đĩa → Chạy tool.
2. Mở Tạo partition để chỉ form và bước xác nhận, nhưng không thực thi.

**Nói:**

> Storage là nhóm có rủi ro cao nhất. Các thao tác đọc như `lsblk` được tách khỏi thao tác ghi. Khi tạo partition, người dùng phải xác nhận chính xác tên thiết bị mục tiêu. Trong buổi demo nhóm chỉ trình bày cơ chế này và không thay đổi ổ đĩa.

Tuyệt đối không tắt Dry run và không xác nhận `/dev/sda`, `/dev/nvme0n1` hoặc ổ chứa hệ điều hành.

### Bước 7. Lịch sử lệnh — 30 giây

**Thao tác:** mở lịch sử lệnh vừa chạy.

**Nói:**

> Lịch sử cho thấy các module khác nhau vẫn sử dụng cùng một hợp đồng `netadmin`. Người học có thể xem lại lệnh, đối chiếu output và chạy lại bằng Terminal khi cần.

**Câu kết demo:**

> Phần demo cho thấy NetAdmin Toolkit không chỉ gom lệnh vào các nút bấm mà tổ chức chúng thành một quy trình có kiểm tra, xem trước và phản hồi rõ ràng.

### Tùy chọn khi được hỏi về DHCP — tối đa 1 phút

Giữ Dry run bật, chọn lần lượt **DHCP → Liệt kê DHCP scopes**, **Liệt kê reservations** hoặc **Liệt kê DHCP leases**. Output sử dụng một bộ dữ liệu mẫu nhất quán và dòng cuối ghi rõ:

```text
[DRY-RUN] Dữ liệu mô phỏng DHCP trên CentOS 10; hệ thống chưa được thay đổi.
```

**Nói:**

> CentOS 10 không còn ISC DHCP nên đây là luồng Dry run với dữ liệu mô phỏng để trình bày cách UI và CLI xử lý scope, reservation và lease. Khi tắt Dry run, công cụ chủ động từ chối chạy backend không tương thích. Muốn cấp lease thật, nhóm sẽ dùng RHEL 9 hoặc phát triển adapter Kea.

Không nói service hoặc lease mô phỏng là kết quả runtime thật.

## Slide 6 — Kết luận — 1 phút 10 giây

**Nói:**

> NetAdmin Toolkit đã thống nhất 8 nhóm nghiệp vụ và 123 thao tác UI trên một CLI Bash. Core cung cấp validation, Dry run, xác nhận và backup hoặc rollback cho những cấu hình phù hợp. Kiến trúc module giúp bổ sung bài học mới mà không phải viết lại toàn bộ hệ thống.

> Giới hạn hiện tại là kết quả vẫn phụ thuộc phiên bản hệ điều hành, package và trạng thái dịch vụ thật. CentOS Stream 10 không chạy backend ISC DHCP hiện tại; hướng phát triển phù hợp là bổ sung Kea hoặc dùng RHEL 9 cho bài lab DHCP. Giá trị cốt lõi của dự án là giúp người học thao tác dễ hơn nhưng vẫn nhìn thấy lệnh Bash và dịch vụ thật bên dưới.

## Slide 7 — Phân công công việc — 50 giây

**Nói:**

> Nhóm phân chia theo module nhưng có kiểm tra chéo giữa code, giao diện và tài liệu. Đoàn Văn Khoan phụ trách kiến trúc, core và CLI. Trần Gia Hân phụ trách Network, DNS và DHCP. Nguyễn Vương Hoàng Tịnh phụ trách Storage và Samba. Nguyễn Thành Nhân phụ trách Web, FTP, Mail và giao diện Cockpit. Các thành viên cùng tham gia setup, kiểm thử và hoàn thiện báo cáo.

Không đọc từng gạch đầu dòng nhỏ trong bảng.

## Slide 8 — Cảm ơn — 15 giây

**Nói:**

> Phần trình bày của nhóm em đến đây là kết thúc. Nhóm em xin cảm ơn thầy và các bạn đã lắng nghe. Nhóm em xin nhận câu hỏi và góp ý.

## 4. Phương án dự phòng bằng Terminal

Nếu Cockpit mất kết nối, nói:

> Giao diện đang mất kết nối với Cockpit runtime. Vì UI và Terminal dùng cùng một CLI nên em chuyển sang Terminal để minh họa các thao tác an toàn.

Sau đó chạy:

```bash
cd ~/centos-auto-config-tools
sudo ./bin/netadmin doctor
sudo ./bin/netadmin dns network list
sudo ./bin/netadmin dns config check
sudo ./bin/netadmin dns zone list
sudo ./bin/netadmin storage disk list
NETADMIN_DRY_RUN=1 sudo ./bin/netadmin web site add demo.lab.local /var/www/demo.lab.local
```

Không cố sửa mạng, package hoặc Cockpit trong thời gian trình bày.

## 5. Câu hỏi giảng viên có thể hỏi

### Tại sao dùng Bash thay vì Python hoặc một backend web?

Bash phù hợp với các bài quản trị hệ thống vì gọi trực tiếp công cụ chuẩn như `nmcli`, `systemctl`, `named-checkconf`, `testparm` và `apachectl`. Lệnh minh bạch, dễ đối chiếu với nội dung môn học. Hạn chế là Bash khó quản lý mô hình dữ liệu phức tạp; nếu dự án phát triển thành hệ thống quản trị nhiều máy, có thể chuyển orchestration sang Python, Ansible hoặc một backend chuyên dụng.

### Website gọi Terminal bằng cách nào?

NetAdmin UI là package của Cockpit. JavaScript sử dụng `cockpit.spawn()` để gọi `/usr/local/bin/netadmin` và nhận output. Cockpit xử lý phiên đăng nhập và nâng quyền. Dự án không tự mở một HTTP API chạy lệnh tùy ý.

### Có nguy cơ command injection không?

UI truyền command và từng tham số dưới dạng một mảng cho `cockpit.spawn`, không ghép thành chuỗi để đưa qua `sh -c`. CLI còn kiểm tra domain, IP, CIDR, identifier, đường dẫn và lựa chọn hợp lệ. Tuy vậy, đây vẫn là công cụ quản trị có quyền cao nên chỉ nên cấp cho tài khoản được tin cậy và phải tiếp tục rà soát bảo mật khi mở rộng.

### Dry run có bảo đảm lệnh thật chắc chắn thành công không?

Không. Dry run chứng minh lệnh dự kiến và validation đầu vào, nhưng không thể bảo đảm package, service, port hoặc filesystem thực tế sẽ thành công. Vì vậy dự án vẫn cần config check, service status và kiểm thử từ client thật.

### Backup/rollback có hoàn tác toàn bộ hệ thống không?

Không. Cơ chế hiện tại chủ yếu sao lưu và khôi phục các tệp cấu hình do tool quản lý. Nó không phải transaction toàn hệ thống và không thể tự hoàn tác mọi thay đổi package, user, disk hoặc dữ liệu bên ngoài.

### Vì sao Doctor báo `PARTIAL` trên CentOS Stream 10?

Vì RHEL/CentOS 10 đã loại bỏ ISC DHCP và chuyển hướng sang Kea, trong khi module hiện tại quản lý `dhcpd.conf`. Các module khác không tự động hỏng vì cảnh báo này. Có thể demo luồng Dry run bằng dữ liệu mô phỏng; muốn cấp lease thật cần Rocky/Alma/RHEL 9 hoặc backend Kea riêng.

### Vì sao vẫn để DHCP trên giao diện?

DHCP vẫn thuộc nội dung môn học và hợp đồng module của dự án. Giao diện giữ module để tài liệu và CLI nhất quán giữa các môi trường. Trên CentOS 10, Dry run có dữ liệu mô phỏng được ghi nhãn; khi thực thi thật, runtime từ chối cài ISC DHCP thay vì báo thành công giả.

### Vì sao không chạy đầy đủ trên Ubuntu?

Runtime hiện nhắm họ RHEL: tên package, service, firewall, SELinux và đường dẫn cấu hình đều theo CentOS. Ubuntu có thể dùng để audit mã nguồn hoặc xem UI, nhưng muốn chạy thật cần một adapter riêng cho `apt`, `bind9`, `apache2`, UFW/AppArmor và các đường dẫn tương ứng.

### Con số 123 có ý nghĩa gì?

Đây là 123 thao tác trong catalog Cockpit đã được map tới route CLI hợp lệ. Audit tĩnh kiểm tra mapping, placeholder và dispatch. Con số này không đồng nghĩa mọi thao tác đã được nghiệm thu thực tế trên mọi phiên bản CentOS.

### Clean Architecture được áp dụng như thế nào trong dự án Bash?

UI phụ thuộc vào hợp đồng CLI thay vì phụ thuộc trực tiếp vào BIND, Apache hoặc Samba. Core chứa cơ chế dùng chung; mỗi feature chứa command nghiệp vụ và adapter làm việc với dịch vụ hệ thống. Bash không cưỡng chế dependency bằng compiler, nên kiến trúc được duy trì bằng cấu trúc thư mục, quy ước dispatch và audit tự động.

### Tại sao không tắt SELinux hoặc firewalld cho dễ chạy?

Tắt lớp bảo vệ sẽ làm bài demo dễ hơn nhưng không phản ánh vận hành đúng. Dự án mở đúng service/port trên firewalld và thiết lập context hoặc boolean SELinux khi cần. Nếu thiếu công cụ SELinux, tool cảnh báo thay vì âm thầm tuyên bố hoàn tất.

### Tại sao phải tạo DNS zone trước khi thêm record?

Record luôn thuộc một zone. Với zone `lab.local`, NetAdmin tạo file `/var/named/db.lab-local` và block khai báo trong file managed. Nếu chưa có zone, thêm record phải bị từ chối để tránh ghi vào một file không tồn tại.

## 6. Những điều không nên tuyên bố

- Không nói “123 tool đều đã chạy thành công trên CentOS 10”.
- Không nói “Dry run là kiểm thử đầy đủ”.
- Không nói “backup có thể hoàn tác mọi thay đổi”.
- Không nói “Cockpit không có backend hoặc runtime trung gian”.
- Không nói “DHCP đang hoạt động trên CentOS Stream 10”.
- Không nói “Ubuntu được hỗ trợ đầy đủ”.
- Không demo format disk, tạo partition hoặc đổi IP của connection đang dùng để mở Cockpit.

## 7. Checklist 10 phút trước khi lên trình bày

- [ ] Slide mở được và đúng thứ tự 1–8.
- [ ] Cockpit mở tại cổng `9090`, không phải preview cổng `8000`.
- [ ] NetAdmin Tools hiển thị “Cockpit đã kết nối”.
- [ ] Administrative access đã bật.
- [ ] Dry run đang bật.
- [ ] `named`, `httpd` và `cockpit.socket` đang active.
- [ ] `named-checkconf`, `apachectl` và `lsblk` tồn tại.
- [ ] Doctor hiển thị `PARTIAL` đúng với CentOS Stream 10.
- [ ] DNS config check chạy được.
- [ ] Storage disk list chạy được.
- [ ] Terminal dự phòng đang mở đúng thư mục dự án.
- [ ] Không có mật khẩu xuất hiện trên màn hình.
- [ ] Đã tập nói ít nhất một lần trong khoảng 13–15 phút.

## 8. Tài liệu đối chiếu

- [CLI reference](docs/CLI_REFERENCE.md)
- [Audit mapping tool](docs/TOOL-COVERAGE-AUDIT.md)
- [Hướng dẫn Cockpit](docs/QUICKSTART-COCKPIT-UI.md)
- [Danh sách tool](docs/TOOLS-LIST.md)
- [Red Hat: Kea thay thế ISC DHCP trong RHEL 10](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/considerations_in_adopting_rhel_10/infrastructure-services)
