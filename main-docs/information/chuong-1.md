# CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI

## 1.1 Bối cảnh quản trị mạng trên CentOS

Trong các hệ thống máy chủ Linux, quản trị mạng không chỉ dừng lại ở việc đặt địa chỉ IP hoặc kiểm tra kết nối. Người quản trị còn phải cài đặt dịch vụ, chỉnh sửa nhiều tệp cấu hình, mở cổng trên tường lửa, thiết lập quyền truy cập, xử lý chính sách SELinux, khởi động dịch vụ và kiểm tra kết quả từ máy khách. Các nội dung này xuất hiện xuyên suốt trong môn Quản trị mạng, từ các bài thực hành cơ bản như DHCP, DNS, quản lý ổ đĩa đến các dịch vụ ứng dụng như Samba, Web, FTP và Mail Server.

CentOS và các hệ điều hành tương thích Red Hat thường được sử dụng trong môi trường học tập vì có cách tổ chức dịch vụ rõ ràng, sử dụng systemd để quản lý tiến trình, DNF để quản lý gói và firewalld kết hợp SELinux để bảo vệ hệ thống. Tuy nhiên, chính sự đầy đủ này làm cho một bài thực hành thường gồm nhiều bước phụ thuộc nhau. Ví dụ, để một máy khách truy cập website bằng tên miền, người học phải đồng thời bảo đảm card mạng có địa chỉ phù hợp, bản ghi DNS tồn tại, Apache có VirtualHost tương ứng, firewall cho phép HTTP và dịch vụ đang hoạt động. Chỉ một sai sót nhỏ trong bất kỳ bước nào cũng có thể khiến toàn bộ kịch bản thất bại.

Trong quá trình học, người mới thường tập trung ghi nhớ câu lệnh thay vì hiểu quan hệ giữa cấu hình, dịch vụ và kết quả kiểm tra. Khi chuyển sang một máy ảo khác, tên card mạng, phiên bản gói hoặc trạng thái ban đầu của hệ thống có thể thay đổi; chuỗi lệnh sao chép từ tài liệu vì thế không còn hoạt động nguyên vẹn. Mặt khác, các script riêng lẻ được viết cho từng bài thường có cách nhập liệu, thông báo lỗi và cấu trúc khác nhau, gây khó khăn khi tái sử dụng hoặc bổ sung tính năng.

Từ bối cảnh đó, đề tài “Xây dựng bộ công cụ tự động cấu hình trên CentOS” hướng tới một nền tảng thống nhất cho các bài thực hành quản trị mạng. Sản phẩm không thay thế kiến thức nền tảng, mà đóng vai trò chuẩn hóa quy trình: người dùng chọn đúng tác vụ, nhập tham số cần thiết, xem trước lệnh, thực thi và nhận kết quả kiểm tra theo cùng một cách. Mỗi thao tác vẫn ánh xạ đến công cụ hệ thống thật như `nmcli`, `dhcpd`, `named`, `parted`, LVM, Samba, Apache, vsftpd, Postfix hoặc Dovecot; vì vậy người học có thể liên hệ trực tiếp giữa giao diện, câu lệnh và dịch vụ bên dưới.

## 1.2 Vấn đề của quy trình cấu hình thủ công

Quy trình cấu hình thủ công có giá trị trong giai đoạn học nguyên lý, nhưng bộc lộ nhiều hạn chế khi số lượng bài thực hành và dịch vụ tăng lên.

Thứ nhất, thao tác bị phân mảnh giữa nhiều công cụ. Một bài DNS có thể cần dùng DNF để cài BIND, Vim để sửa `named.conf`, `named-checkconf` và `named-checkzone` để kiểm tra, systemctl để điều khiển dịch vụ, firewall-cmd để mở cổng và dig để truy vấn. Người học phải tự nhớ thứ tự và tự liên kết lỗi của từng công cụ. Khi lỗi xuất hiện ở bước cuối, nguyên nhân có thể nằm ở tệp cấu hình, quyền truy cập, firewall hoặc chính card mạng.

Thứ hai, việc chỉnh sửa trực tiếp tệp cấu hình dễ phát sinh sai cú pháp và khó khôi phục. Một dấu chấm phẩy thiếu trong BIND, một block share đặt sai trong Samba hoặc một VirtualHost trùng lặp trong Apache đều có thể làm dịch vụ không khởi động. Nếu người dùng ghi đè tệp trước khi tạo bản sao lưu, việc quay lại trạng thái hoạt động gần nhất phụ thuộc hoàn toàn vào kinh nghiệm cá nhân.

Thứ ba, nhiều tác vụ mang tính phá hủy hoặc làm gián đoạn kết nối. Tạo partition, format filesystem, thay đổi IP tĩnh hoặc xóa tài nguyên là những ví dụ điển hình. Trong môi trường máy ảo, đặt sai connection profile còn có thể làm mất phiên SSH hoặc Cockpit đang sử dụng. Một công cụ phục vụ người học phải phân biệt rõ thao tác chỉ đọc và thao tác thay đổi hệ thống, đồng thời yêu cầu xác nhận đối với hành động có nguy cơ mất dữ liệu.

Thứ tư, script đơn lẻ thường khó mở rộng. Khi mỗi dịch vụ có một file lớn tự xử lý cài đặt, nhập liệu, kiểm tra và ghi cấu hình, các đoạn mã kiểm tra quyền root, log, backup hoặc xác thực IP bị lặp lại. Việc sửa một quy tắc an toàn phải thực hiện ở nhiều nơi và dễ tạo ra hành vi không đồng nhất. Ngoài ra, giao diện đồ họa nếu tự ghép chuỗi lệnh mà không dùng chung định nghĩa với CLI sẽ nhanh chóng lệch khỏi chức năng thật.

Thứ năm, kết quả thực hành khó tái lập và khó đánh giá. Hai sinh viên có thể thực hiện cùng một bài nhưng tạo cấu hình khác nhau do bỏ sót bước hoặc dùng giá trị mặc định khác nhau. Khi không có lệnh kiểm tra thống nhất, giảng viên và người học khó xác định trạng thái nào được xem là hoàn thành. Do đó, hệ thống cần cung cấp không chỉ lệnh cấu hình mà còn lệnh liệt kê, kiểm tra cú pháp, xem trạng thái dịch vụ và xác nhận từ phía máy khách.

Các vấn đề trên cho thấy nhu cầu về một bộ công cụ có cấu trúc, có khả năng kiểm tra và có cơ chế an toàn mặc định. Tự động hóa trong đề tài được hiểu là giảm thao tác lặp lại nhưng vẫn giữ cho người dùng nhìn thấy lệnh, tham số và kết quả, thay vì che giấu hoàn toàn hoạt động của hệ điều hành.

## 1.3 Mục tiêu và yêu cầu của đề tài

Mục tiêu tổng quát của đề tài là xây dựng NetAdmin Toolkit - bộ công cụ Bash hỗ trợ tự động cấu hình, vận hành và kiểm tra các dịch vụ chính trong môn Quản trị mạng trên CentOS, đồng thời cung cấp giao diện Cockpit để người không quen dòng lệnh vẫn có thể sử dụng theo quy trình có hướng dẫn.

Từ mục tiêu tổng quát, đề tài xác định các mục tiêu cụ thể sau:

1. Chuẩn hóa toàn bộ tác vụ dưới một điểm vào duy nhất là lệnh `netadmin`, với cú pháp `netadmin <module> <command> [arguments]`.
2. Bao phủ các nhóm bài học gồm kiểm tra môi trường, DHCP, DNS và cấu hình mạng, Storage/LVM/quota, Samba, Web Server, FTP Server, Mail Server và quản lý giao diện Cockpit.
3. Tách mã nguồn theo module và theo lớp trách nhiệm để có thể bổ sung command mới mà không làm thay đổi các module không liên quan.
4. Dùng chung cơ chế log, kiểm tra quyền, xác thực tham số, chạy lệnh hệ thống, sao lưu, xác nhận và xử lý lỗi.
5. Hỗ trợ chế độ dry run để người dùng xem trước thao tác trước khi thay đổi máy.
6. Kiểm tra cấu hình trước khi restart hoặc reload dịch vụ; tự khôi phục bản sao lưu trong các luồng có validator khi cấu hình mới không hợp lệ.
7. Giữ firewall và SELinux ở trạng thái hoạt động, cấu hình đúng rule hoặc context thay vì tắt cơ chế bảo vệ để “làm cho dịch vụ chạy”.
8. Cung cấp giao diện Cockpit thân thiện, cho phép tìm kiếm tool, nhập tham số, xem trước command, theo dõi output và phân biệt chế độ chạy thử với chạy thật.
9. Xây dựng tài liệu giải thích từ kiến thức nền đến cách sử dụng từng command, kèm runbook kiểm thử trên CentOS.

Về yêu cầu chức năng, mỗi module phải có các thao tác phù hợp với vòng đời của tài nguyên: cài đặt, tạo hoặc cập nhật cấu hình, liệt kê, kiểm tra, sao lưu hoặc khôi phục và điều khiển dịch vụ. Các lệnh chỉ đọc phải cung cấp thông tin đủ để chẩn đoán, trong khi lệnh thay đổi hệ thống phải xác thực đầu vào và trả exit code rõ ràng.

Về yêu cầu phi chức năng, hệ thống phải dễ đọc đối với sinh viên học Bash, chạy được từ CLI mà không phụ thuộc giao diện, giữ hành vi nhất quán giữa CLI và Cockpit, không lưu mật khẩu dạng rõ trong mã nguồn hoặc command preview, và hạn chế tối đa thao tác xóa dữ liệu vĩnh viễn. Mã nguồn cần tương thích với cấu trúc dịch vụ của CentOS Stream/RHEL hiện hành; các khác biệt package hoặc phiên bản phải được thể hiện trong tài liệu và kiểm thử thực tế.

## 1.4 Đối tượng và phạm vi nghiên cứu

Đối tượng sử dụng chính của NetAdmin Toolkit là sinh viên học môn Quản trị mạng, đặc biệt là người mới làm quen với Linux server. Công cụ cũng có thể hỗ trợ giảng viên khi chuẩn bị môi trường demo, hoặc người quản trị cần dựng nhanh một mô hình lab có cấu hình nhất quán. Đề tài không hướng đến việc thay thế các nền tảng quản trị doanh nghiệp quy mô lớn, hệ thống orchestration đa máy chủ hoặc giải pháp Infrastructure as Code trên cloud.

Phạm vi môi trường tập trung vào máy chủ CentOS chạy systemd, DNF, NetworkManager, firewalld và SELinux. Mô hình thực nghiệm ưu tiên hai card mạng: một card NAT để truy cập Internet và cài package, một card private network để máy chủ cung cấp dịch vụ cho client trong mạng lab. Tuy vậy, các chức năng chỉ đọc và giao diện Cockpit vẫn có thể hoạt động trên máy chỉ có một card mạng.

Phạm vi chức năng gồm chín module. `doctor` kiểm tra hệ điều hành, quyền và dependency. `dhcp` quản lý scope, reservation, lease, cấu hình và dịch vụ dhcpd. `dns` quản lý connection NetworkManager, BIND zone, record, reverse zone, secondary zone, transfer và forwarder. `storage` hỗ trợ disk, partition, filesystem, mount, LVM và quota. `samba` quản lý share, user, quyền, phiên kết nối và SMB client. `web` quản lý Apache VirtualHost, DNS liên quan, log, backup và restore. `ftp` quản lý vsftpd, share, local user, TLS, backup và diagnostics. `mail` cấu hình Postfix, Dovecot, SASL, DNS, Maildir, queue và kiểm tra protocol. `ui` cài đặt và quản lý package NetAdmin trong Cockpit.

Đề tài có một số giới hạn được xác định rõ. Công cụ tập trung vào một máy chủ lab, chưa điều phối nhiều node. Chứng chỉ TLS không được tự phát hành thay người quản trị mà chỉ được kiểm tra và áp dụng khi đã cung cấp. Webmail chưa được cài tự động vì cần lựa chọn ứng dụng, phiên bản PHP và cơ sở dữ liệu phù hợp. Network Load Balancing chưa được triển khai do tài liệu nguồn không có đặc tả hoặc kịch bản kiểm thử. Các chức năng thay đổi hệ thống đã được kiểm tra tĩnh và thiết kế cơ chế an toàn, nhưng vẫn phải nghiệm thu trên CentOS với package, service, firewall, SELinux và máy client thật trước khi dùng trong môi trường ngoài phòng lab.

## 1.5 Tổng quan chức năng của NetAdmin Toolkit

NetAdmin Toolkit gồm hai lớp tương tác chính. Lớp thứ nhất là CLI Bash, trong đó `bin/netadmin` đóng vai trò composition root: xác định thư mục dự án, nạp core, đăng ký module và chuyển command đến đúng feature. Lớp thứ hai là giao diện NetAdmin chạy như một package của Cockpit. Giao diện không duy trì backend riêng; JavaScript sử dụng runtime của Cockpit để gọi `/usr/local/bin/netadmin`, yêu cầu quyền quản trị khi cần và truyền output về cửa sổ kết quả.

Phần core cung cấp các khả năng dùng chung như chuẩn hóa đường dẫn, log, exit code, xác thực dữ liệu, prompt xác nhận, chạy command và tạo backup. Các feature được tách thành `module.sh`, thư mục `commands` và `infra`. `module.sh` định tuyến subcommand; `commands` biểu diễn use case mà người dùng gọi; `infra` chứa thao tác gần với dịch vụ hoặc tệp cấu hình. Cách tổ chức này áp dụng tinh thần Clean Architecture vào dự án Bash: phần điều phối không phụ thuộc vào chi tiết giao diện, còn giao diện chỉ gọi hợp đồng CLI thay vì tự chỉnh sửa hệ thống.

Danh mục Cockpit hiện biểu diễn 123 thao tác thuộc tám nhóm nghiệp vụ và Doctor. Người dùng có thể lọc theo module hoặc loại hành động, tìm kiếm theo tên tool hoặc command, chọn một tool để đọc mô tả, nhập tham số và xem lệnh được tạo ra. Dry run được bật mặc định trên giao diện; khi tắt, Cockpit gọi command thật với cơ chế superuser. Những trường cần tương tác như mật khẩu được truyền qua PTY hoặc input riêng và không xuất hiện trong command preview.

Luồng xử lý chung của một thao tác gồm năm bước. Bước một, hệ thống nhận module, command và tham số từ CLI hoặc Cockpit. Bước hai, dữ liệu được kiểm tra theo loại như IPv4, CIDR, domain, username, path hoặc action. Bước ba, hệ thống hiển thị hoặc xác nhận thao tác, đặc biệt với partition, format và xóa tài nguyên. Bước bốn, command hệ thống được thực thi; nếu có thay đổi tệp cấu hình, bản sao lưu được tạo trước. Bước năm, validator chuyên dụng và trạng thái dịch vụ được kiểm tra; kết quả được trả bằng log và exit code thống nhất.

Giá trị chính của hệ thống nằm ở việc kết nối ba góc nhìn. Góc nhìn bài học cho biết người học đang giải quyết DHCP, DNS hay một dịch vụ ứng dụng. Góc nhìn công cụ cho biết command Linux nào thực sự được sử dụng. Góc nhìn vận hành cho biết cấu hình đã hợp lệ, service có hoạt động và client có truy cập được hay không. Nhờ đó, NetAdmin Toolkit vừa là công cụ thực thi, vừa là bản đồ học tập giúp người dùng hiểu quan hệ giữa các thành phần.

## 1.6 Phương pháp thực hiện và tiêu chí đánh giá

Đề tài được thực hiện theo phương pháp phát triển tăng dần dựa trên bài thực hành. Trước hết, nhóm tổng hợp yêu cầu từ các tài liệu AutoScript và phân loại theo dịch vụ. Tiếp theo, mỗi yêu cầu được ánh xạ thành command CLI, dependency hệ thống, tệp cấu hình, service, firewall rule, SELinux rule và bước kiểm tra. Những hành vi có rủi ro được thiết kế cơ chế xác nhận, backup hoặc phương án bảo toàn dữ liệu trước khi triển khai.

Sau khi hoàn thiện CLI, nhóm đối chiếu từng command với danh mục giao diện Cockpit. Giao diện chỉ được xem là bao phủ khi có đúng tool, đúng trường tham số, đúng command preview và đúng cách thực thi. Tài liệu coverage audit được sử dụng để phát hiện chức năng thiếu hoặc mô tả chưa đủ rõ. Các mục không có đặc tả, chẳng hạn Network Load Balancing, không được tự suy diễn thành tính năng đã hoàn thành.

Quá trình kiểm tra gồm hai mức. Kiểm tra tĩnh xác nhận cú pháp Bash và JavaScript, route command, nội dung help, cấu trúc source và sự đồng bộ giữa CLI, UI và tài liệu. Kiểm thử thực tế trên CentOS xác nhận package có thể cài, tệp cấu hình được sinh đúng, validator chấp nhận, service khởi động, firewall và SELinux cho phép đúng phạm vi, đồng thời client trong mạng lab sử dụng được dịch vụ. Đối với thao tác lưu trữ hoặc đổi IP, kịch bản kiểm thử phải chuẩn bị thiết bị và đường kết nối riêng để tránh ảnh hưởng dữ liệu hoặc phiên quản trị.

Hệ thống được đánh giá theo năm nhóm tiêu chí. Tính đúng đắn được xác nhận bằng validator của dịch vụ và kết quả truy cập từ client. Khả năng sử dụng được đánh giá qua cú pháp nhất quán, thông báo rõ ràng, dry run và quy trình trên Cockpit. Khả năng an toàn dựa trên validation, xác nhận thao tác phá hủy, backup, rollback, firewall, SELinux và nguyên tắc không xóa dữ liệu ngoài ý muốn. Khả năng mở rộng được đánh giá qua mức độ độc lập giữa core, feature và infrastructure. Khả năng truy vết được đánh giá bằng log, exit code, command preview và tài liệu đối chiếu giữa yêu cầu, CLI và UI.

Kết quả mong đợi của Chương 1 là xác lập đúng bài toán, giới hạn và tiêu chuẩn nghiệm thu cho toàn bộ đề tài. Các chương sau lần lượt trình bày cơ sở lý thuyết, kiến trúc, quá trình triển khai và kết quả kiểm thử để chứng minh mức độ đáp ứng các mục tiêu đã nêu.
