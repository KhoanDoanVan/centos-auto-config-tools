# MỤC LỤC CHI TIẾT ĐỀ XUẤT

## Phần đầu báo cáo

- TRANG BÌA
- TRANG PHỤ BÌA
- LỜI CAM ĐOAN
- LỜI CẢM ƠN
- MỤC LỤC
- DANH MỤC VIẾT TẮT
- DANH MỤC BẢNG BIỂU
- DANH MỤC HÌNH ẢNH

## MỞ ĐẦU

### 1. Lý do chọn đề tài

### 2. Mục tiêu của đề tài

### 3. Đối tượng và phạm vi nghiên cứu

### 4. Phương pháp thực hiện

### 5. Kết quả dự kiến và giá trị ứng dụng

### 6. Cấu trúc báo cáo

## CHƯƠNG 1. TỔNG QUAN ĐỀ TÀI

### 1.1. Bối cảnh quản trị hệ thống mạng trên CentOS

### 1.2. Các vấn đề của quy trình cấu hình thủ công

#### 1.2.1. Khó khăn đối với người học chưa có nền tảng quản trị mạng

#### 1.2.2. Sai sót khi thao tác trực tiếp trên file cấu hình và dịch vụ

#### 1.2.3. Khó khăn trong việc tái sử dụng và mở rộng các script riêng lẻ

#### 1.2.4. Rủi ro khi thực hiện thao tác bằng quyền quản trị

### 1.3. Ý tưởng xây dựng NetAdmin Toolkit

### 1.4. Mục tiêu tổng quát

### 1.5. Mục tiêu cụ thể

#### 1.5.1. Chuẩn hóa công cụ dòng lệnh bằng một entry point thống nhất

#### 1.5.2. Tự động hóa các bài thực hành quản trị mạng

#### 1.5.3. Tổ chức mã nguồn theo kiến trúc dễ mở rộng và bảo trì

#### 1.5.4. Cung cấp giao diện Cockpit thân thiện với người mới

#### 1.5.5. Bảo đảm khả năng kiểm tra, sao lưu và khôi phục cấu hình

### 1.6. Đối tượng sử dụng

### 1.7. Phạm vi chức năng của hệ thống

#### 1.7.1. Kiểm tra môi trường và dependency

#### 1.7.2. Quản lý DHCP

#### 1.7.3. Quản lý DNS và cấu hình mạng

#### 1.7.4. Quản lý lưu trữ, LVM và quota

#### 1.7.5. Quản lý chia sẻ tệp qua Samba

#### 1.7.6. Quản lý Web Server

#### 1.7.7. Quản lý FTP Server

#### 1.7.8. Quản lý Mail Server

#### 1.7.9. Quản lý công cụ qua Cockpit UI

### 1.8. Giới hạn của đề tài

### 1.9. Kết quả đạt được ở mức tổng quan

### 1.10. Kết chương

## CHƯƠNG 2. CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ SỬ DỤNG

### 2.1. Tổng quan về hệ điều hành CentOS và quản trị Linux

#### 2.1.1. Package và trình quản lý gói DNF YUM

#### 2.1.2. Dịch vụ hệ thống và systemd

#### 2.1.3. Người dùng, nhóm và quyền truy cập

#### 2.1.4. File cấu hình và nguyên tắc kiểm tra trước khi áp dụng

### 2.2. Kiến thức mạng nền tảng

#### 2.2.1. Mô hình server và client

#### 2.2.2. Địa chỉ IPv4, subnet mask và CIDR

#### 2.2.3. Gateway, định tuyến và default route

#### 2.2.4. Port, protocol và socket dịch vụ

#### 2.2.5. NetworkManager, interface và connection profile

### 2.3. Cơ sở lý thuyết về DHCP

#### 2.3.1. Vai trò của DHCP trong mạng nội bộ

#### 2.3.2. Quy trình DORA

#### 2.3.3. Scope, range, lease và reservation

#### 2.3.4. Cấu trúc dịch vụ dhcpd trên CentOS

### 2.4. Cơ sở lý thuyết về DNS và BIND

#### 2.4.1. Phân giải tên miền và mô hình DNS

#### 2.4.2. Resolver, authoritative server và cache

#### 2.4.3. Domain, FQDN, zone và record

#### 2.4.4. SOA, serial và TTL

#### 2.4.5. Forward lookup và reverse lookup

#### 2.4.6. Primary DNS, secondary DNS và zone transfer

#### 2.4.7. DNS forwarder

### 2.5. Cơ sở lý thuyết về lưu trữ

#### 2.5.1. Disk, partition, filesystem và mount point

#### 2.5.2. Persistent mount và file fstab

#### 2.5.3. Logical Volume Manager

#### 2.5.4. Physical Volume, Volume Group và Logical Volume

#### 2.5.5. Cơ chế quota theo người dùng

### 2.6. Cơ sở lý thuyết về Samba và SMB

#### 2.6.1. Giao thức SMB và vai trò của Samba

#### 2.6.2. Public share và protected share

#### 2.6.3. Linux user, Samba user và group

#### 2.6.4. Quan hệ giữa quyền filesystem, cấu hình share và SELinux

#### 2.6.5. SMB client và phiên kết nối

### 2.7. Cơ sở lý thuyết về Web Server

#### 2.7.1. HTTP và mô hình hoạt động của Apache

#### 2.7.2. DocumentRoot và VirtualHost

#### 2.7.3. DNS record cho website

#### 2.7.4. Access log và error log

### 2.8. Cơ sở lý thuyết về FTP Server

#### 2.8.1. Kênh điều khiển và kênh dữ liệu của FTP

#### 2.8.2. Active mode và passive mode

#### 2.8.3. Anonymous user và local user

#### 2.8.4. Chroot và phân quyền thư mục FTP

#### 2.8.5. TLS trong FTP

### 2.9. Cơ sở lý thuyết về Mail Server

#### 2.9.1. Kiến trúc hệ thống thư điện tử

#### 2.9.2. SMTP và Postfix

#### 2.9.3. POP3, IMAP và Dovecot

#### 2.9.4. Maildir và tài khoản thư cục bộ

#### 2.9.5. DNS A record và MX record cho Mail Server

#### 2.9.6. Xác thực SMTP qua Dovecot SASL

### 2.10. Firewall và SELinux

#### 2.10.1. Vai trò của firewalld

#### 2.10.2. Firewall service và port range

#### 2.10.3. SELinux context và boolean

#### 2.10.4. Nguyên tắc không tắt cơ chế bảo vệ hệ thống

### 2.11. Tự động hóa quản trị bằng Bash

#### 2.11.1. Đặc điểm của Bash trong quản trị Linux

#### 2.11.2. Xử lý tham số, exit code và pipeline

#### 2.11.3. Kiểm tra dữ liệu đầu vào

#### 2.11.4. Tạo và cập nhật file cấu hình an toàn

#### 2.11.5. Tính lặp lại của công cụ tự động hóa

### 2.12. Cockpit và giao diện quản trị trên trình duyệt

#### 2.12.1. Kiến trúc Cockpit

#### 2.12.2. Cockpit package và JavaScript runtime

#### 2.12.3. Thực thi lệnh đặc quyền từ giao diện

#### 2.12.4. Dry run và terminal output trên giao diện

### 2.13. Kết chương

## CHƯƠNG 3. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

### 3.1. Khảo sát yêu cầu

#### 3.1.1. Yêu cầu chức năng

#### 3.1.2. Yêu cầu phi chức năng

#### 3.1.3. Yêu cầu về an toàn và khả năng khôi phục

#### 3.1.4. Yêu cầu về trải nghiệm người dùng

### 3.2. Tác nhân và các trường hợp sử dụng

#### 3.2.1. Người học quản trị mạng

#### 3.2.2. Người quản trị hệ thống

#### 3.2.3. Các nhóm use case chính

### 3.3. Kiến trúc tổng thể của NetAdmin Toolkit

#### 3.3.1. Thành phần CLI Bash

#### 3.3.2. Thành phần Cockpit UI

#### 3.3.3. Các dịch vụ hệ thống được quản lý

#### 3.3.4. Luồng tương tác từ người dùng đến hệ điều hành

### 3.4. Áp dụng Clean Architecture trong dự án Bash

#### 3.4.1. Composition root và entry point

#### 3.4.2. Core dùng chung

#### 3.4.3. Feature module và command use case

#### 3.4.4. Infrastructure adapter

#### 3.4.5. Nguyên tắc phụ thuộc giữa các lớp

### 3.5. Tổ chức mã nguồn

#### 3.5.1. Thư mục bin

#### 3.5.2. Thư mục config

#### 3.5.3. Thư mục src core

#### 3.5.4. Thư mục src features

#### 3.5.5. Thư mục site và Cockpit package

#### 3.5.6. Thư mục docs

### 3.6. Thiết kế CLI và cơ chế định tuyến command

#### 3.6.1. Cú pháp lệnh thống nhất

#### 3.6.2. Module registry

#### 3.6.3. Module dispatcher và subcommand

#### 3.6.4. Help, version và log output

### 3.7. Thiết kế cấu hình và dependency

#### 3.7.1. File cấu hình toàn cục

#### 3.7.2. Biến môi trường

#### 3.7.3. Cài package theo từng module

#### 3.7.4. Quản lý đường dẫn hệ thống

### 3.8. Thiết kế cơ chế an toàn

#### 3.8.1. Validation dữ liệu đầu vào

#### 3.8.2. Kiểm tra quyền root

#### 3.8.3. Chế độ dry run

#### 3.8.4. Xác nhận thao tác có nguy cơ mất dữ liệu

#### 3.8.5. Backup và rollback

#### 3.8.6. Managed marker trong file cấu hình

#### 3.8.7. Kiểm tra cấu hình trước khi áp dụng

#### 3.8.8. Bảo toàn dữ liệu khi xóa tài nguyên

### 3.9. Thiết kế giao diện Cockpit

#### 3.9.1. Nguyên tắc UX cho người chưa có kiến thức mạng

#### 3.9.2. Bố cục module và danh mục tool

#### 3.9.3. Tìm kiếm và lọc thao tác

#### 3.9.4. Form tham số và command preview

#### 3.9.5. Chuyển đổi dry run và thực thi thật

#### 3.9.6. Terminal output, trạng thái và lịch sử lệnh

#### 3.9.7. Cơ chế superuser và PTY

### 3.10. Thiết kế triển khai trên CentOS

#### 3.10.1. Cài CLI vào hệ thống

#### 3.10.2. Cài Cockpit package

#### 3.10.3. Truy cập qua cổng 9090

#### 3.10.4. Quy trình cập nhật source và giao diện

### 3.11. Kết chương

## CHƯƠNG 4. CÀI ĐẶT, TRIỂN KHAI VÀ KẾT QUẢ THỰC NGHIỆM

### 4.1. Môi trường triển khai và mô hình thực nghiệm

#### 4.1.1. Cấu hình máy chủ CentOS

#### 4.1.2. Cấu hình máy client

#### 4.1.3. Mô hình hai card mạng NAT và private network

#### 4.1.4. Sơ đồ địa chỉ IP và tên miền sử dụng

#### 4.1.5. Quy ước ghi nhận lệnh, log và ảnh kết quả

### 4.2. Khởi tạo NetAdmin Toolkit và kiểm tra môi trường

#### 4.2.1. Chuẩn bị source và quyền thực thi

#### 4.2.2. Entry point netadmin

#### 4.2.3. Doctor và kiểm tra dependency

#### 4.2.4. Thử nghiệm chế độ dry run

#### 4.2.5. Kết quả khởi tạo hệ thống

### 4.3. Triển khai module DHCP

#### 4.3.1. Mục tiêu cấu hình DHCP trong mô hình lab

#### 4.3.2. Cài đặt DHCP Server

#### 4.3.3. Tạo và cập nhật scope

#### 4.3.4. Quản lý reservation

#### 4.3.5. Theo dõi và giải phóng lease

#### 4.3.6. Kiểm tra, rollback và điều khiển dịch vụ

#### 4.3.7. Kịch bản demo DHCP từ server đến client

#### 4.3.8. Kết quả và bằng chứng thực nghiệm DHCP

### 4.4. Triển khai module DNS và cấu hình mạng

#### 4.4.1. Mục tiêu cấu hình DNS trong mô hình lab

#### 4.4.2. Liệt kê connection và xác định interface

#### 4.4.3. Cấu hình IP tĩnh và chuyển về DHCP

#### 4.4.4. Cài đặt BIND

#### 4.4.5. Tạo master forward zone

#### 4.4.6. Tạo reverse zone

#### 4.4.7. Tạo secondary zone và cho phép zone transfer

#### 4.4.8. Quản lý A, AAAA, CNAME, MX, NS, TXT và PTR record

#### 4.4.9. Cấu hình DNS forwarder

#### 4.4.10. Truy vấn, kiểm tra và rollback cấu hình

#### 4.4.11. Kịch bản demo phân giải thuận và phân giải ngược

#### 4.4.12. Kết quả và bằng chứng thực nghiệm DNS

### 4.5. Triển khai module Storage, LVM và quota

#### 4.5.1. Mục tiêu quản lý lưu trữ trong mô hình lab

#### 4.5.2. Liệt kê disk và xác định vùng trống

#### 4.5.3. Tạo partition có xác nhận an toàn

#### 4.5.4. Format và mount filesystem

#### 4.5.5. Cài đặt và kiểm tra LVM

#### 4.5.6. Tạo Physical Volume và Volume Group

#### 4.5.7. Tạo và mở rộng Logical Volume

#### 4.5.8. Bật và thiết lập quota

#### 4.5.9. Kịch bản demo lưu trữ và quota

#### 4.5.10. Kết quả và bằng chứng thực nghiệm Storage

### 4.6. Triển khai module Samba

#### 4.6.1. Mục tiêu chia sẻ dữ liệu qua SMB

#### 4.6.2. Cài đặt Samba Server và client

#### 4.6.3. Tạo public share

#### 4.6.4. Tạo group share

#### 4.6.5. Quản lý Samba user

#### 4.6.6. Cấp quyền đọc và ghi cho user hoặc group

#### 4.6.7. Kiểm tra, áp dụng và rollback cấu hình

#### 4.6.8. Theo dõi trạng thái và phiên kết nối

#### 4.6.9. Liệt kê và sao chép tệp bằng SMB client

#### 4.6.10. Kịch bản demo từ máy client

#### 4.6.11. Kết quả và bằng chứng thực nghiệm Samba

### 4.7. Triển khai module Web Server

#### 4.7.1. Mục tiêu triển khai website trong mạng lab

#### 4.7.2. Cài đặt Apache và BIND

#### 4.7.3. Tạo DocumentRoot và VirtualHost

#### 4.7.4. Thiết lập và gỡ DNS record cho website

#### 4.7.5. Liệt kê và xem cấu hình website

#### 4.7.6. Backup và restore website

#### 4.7.7. Xem access log và error log

#### 4.7.8. Kiểm tra, rollback và điều khiển dịch vụ

#### 4.7.9. Kịch bản demo truy cập website từ client

#### 4.7.10. Kết quả và bằng chứng thực nghiệm Web Server

### 4.8. Triển khai module FTP Server

#### 4.8.1. Mục tiêu triển khai FTP trong mạng lab

#### 4.8.2. Cài đặt vsftpd và cấu hình passive port

#### 4.8.3. Thiết lập và kiểm tra DNS cho FTP Server

#### 4.8.4. Tạo anonymous share đọc và ghi

#### 4.8.5. Quản lý local FTP user

#### 4.8.6. Khóa và mở khóa tài khoản FTP

#### 4.8.7. Backup, restore và cách ly dữ liệu khi gỡ share

#### 4.8.8. Cấu hình TLS cho FTP

#### 4.8.9. Kiểm tra trạng thái, session, log và diagnostics

#### 4.8.10. Kiểm tra, rollback và điều khiển dịch vụ

#### 4.8.11. Kịch bản demo bằng lftp hoặc FileZilla

#### 4.8.12. Kết quả và bằng chứng thực nghiệm FTP Server

### 4.9. Triển khai module Mail Server

#### 4.9.1. Mục tiêu triển khai Mail Server trong mạng lab

#### 4.9.2. Cài đặt Postfix, Dovecot và công cụ hỗ trợ

#### 4.9.3. Cấu hình domain, FQDN, trusted network và Maildir

#### 4.9.4. Tích hợp Postfix và Dovecot qua SASL socket

#### 4.9.5. Thiết lập và kiểm tra DNS A MX record

#### 4.9.6. Quản lý mail user

#### 4.9.7. Kiểm tra SMTP, POP3 và IMAP

#### 4.9.8. Theo dõi trạng thái, mail queue và log

#### 4.9.9. Kiểm tra, rollback và điều khiển dịch vụ

#### 4.9.10. Kịch bản demo gửi và nhận thư trong mạng lab

#### 4.9.11. Kết quả và bằng chứng thực nghiệm Mail Server

### 4.10. Triển khai giao diện Cockpit

#### 4.10.1. Cài đặt Cockpit và NetAdmin package

#### 4.10.2. Đăng nhập và cấp quyền quản trị

#### 4.10.3. Danh mục 123 thao tác trên giao diện

#### 4.10.4. Tìm kiếm, chọn tool và nhập tham số

#### 4.10.5. Xem trước command và chạy dry run

#### 4.10.6. Thực thi thật và theo dõi terminal output

#### 4.10.7. Kết quả trải nghiệm người dùng

### 4.11. Kịch bản tích hợp các module

#### 4.11.1. Chuẩn bị topology và địa chỉ mạng

#### 4.11.2. Cấp địa chỉ cho client bằng DHCP

#### 4.11.3. Phân giải dịch vụ bằng DNS

#### 4.11.4. Chia sẻ dữ liệu và cung cấp dịch vụ Web FTP Mail

#### 4.11.5. Giám sát dịch vụ qua CLI và Cockpit

#### 4.11.6. Kết quả của kịch bản tích hợp

### 4.12. Kết chương

## CHƯƠNG 5. KIỂM THỬ VÀ ĐÁNH GIÁ HỆ THỐNG

### 5.1. Mục tiêu kiểm thử

### 5.2. Phạm vi và phương pháp kiểm thử

#### 5.2.1. Kiểm tra tĩnh mã nguồn Bash và JavaScript

#### 5.2.2. Kiểm thử chức năng trên CentOS

#### 5.2.3. Kiểm thử từ máy client

#### 5.2.4. Kiểm thử dry run, backup và rollback

#### 5.2.5. Đối chiếu CLI, giao diện và tài liệu AutoScript

### 5.3. Tiêu chí đánh giá

#### 5.3.1. Tính đúng đắn của cấu hình

#### 5.3.2. Khả năng sử dụng

#### 5.3.3. Khả năng mở rộng và bảo trì

#### 5.3.4. Mức độ an toàn của thao tác

#### 5.3.5. Khả năng phục hồi khi xảy ra lỗi

### 5.4. Kết quả kiểm thử theo module

#### 5.4.1. Doctor và core CLI

#### 5.4.2. DHCP

#### 5.4.3. DNS và NetworkManager

#### 5.4.4. Storage, LVM và quota

#### 5.4.5. Samba

#### 5.4.6. Web Server

#### 5.4.7. FTP Server

#### 5.4.8. Mail Server

#### 5.4.9. Cockpit UI

### 5.5. Đánh giá mức độ bao phủ chức năng

#### 5.5.1. Đối chiếu với tài liệu AutoScript ban đầu

#### 5.5.2. Đối chiếu command CLI với Cockpit UI

#### 5.5.3. Các chức năng đã hoàn thiện

#### 5.5.4. Các chức năng có điều kiện hoặc chưa có đặc tả

### 5.6. Đánh giá cơ chế an toàn

#### 5.6.1. Validation và kiểm tra cấu hình

#### 5.6.2. Xác nhận thao tác phá hủy

#### 5.6.3. Backup, rollback và bảo toàn dữ liệu

#### 5.6.4. Firewall, SELinux và quyền đặc quyền

### 5.7. Kết quả đạt được

### 5.8. Hạn chế của hệ thống

#### 5.8.1. Phụ thuộc môi trường CentOS và package repository

#### 5.8.2. Giới hạn của validator đối với một số dịch vụ

#### 5.8.3. Webmail chưa chọn stack triển khai chính thức

#### 5.8.4. Network Load Balancing chưa có đặc tả nguồn

#### 5.8.5. Chưa xây dựng bộ kiểm thử tự động đầy đủ

### 5.9. Rủi ro vận hành và biện pháp giảm thiểu

### 5.10. Kết chương

## KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

### 1. Kết luận

### 2. Những đóng góp chính của đề tài

### 3. Hướng phát triển

#### 3.1. Bổ sung Webmail trên stack được hỗ trợ

#### 3.2. Nghiên cứu và bổ sung Network Load Balancing

#### 3.3. Xây dựng bộ kiểm thử tự động và môi trường lab tái lập

#### 3.4. Mở rộng hỗ trợ các bản phân phối Linux khác

#### 3.5. Bổ sung phân quyền người dùng và nhật ký kiểm toán trên giao diện

#### 3.6. Chuẩn hóa đóng gói, cập nhật và phát hành phiên bản

## BẢNG PHÂN CHIA CÔNG VIỆC

## TÀI LIỆU THAM KHẢO

## PHỤ LỤC

### PHỤ LỤC A. DANH SÁCH TOÀN BỘ COMMAND NETADMIN

### PHỤ LỤC B. DANH SÁCH PACKAGE, SERVICE, PORT VÀ FILE CẤU HÌNH

### PHỤ LỤC C. HƯỚNG DẪN CÀI ĐẶT CLI VÀ COCKPIT UI

### PHỤ LỤC D. KỊCH BẢN KIỂM THỬ CHI TIẾT TRÊN CENTOS

### PHỤ LỤC E. MẪU CẤU HÌNH ĐƯỢC SINH BỞI CÁC MODULE

### PHỤ LỤC F. BẢNG ĐỐI CHIẾU AUTOSCRIPT, CLI VÀ COCKPIT UI

### PHỤ LỤC G. LIÊN KẾT MÃ NGUỒN VÀ TÀI LIỆU DỰ ÁN

## Quy ước triển khai nội dung ở bước viết báo cáo

1. Mỗi module trong Chương 4 phải trình bày theo trình tự: mục tiêu bài toán, cấu hình áp dụng, nhóm tool tương ứng, kịch bản demo, ảnh hoặc log minh chứng và nhận xét kết quả.
2. Không biến phần nội dung chính thành danh sách 123 thao tác. Các command cùng mục đích được gom thành nhóm nghiệp vụ; danh sách đầy đủ đặt tại Phụ lục A.
3. Mỗi bảng và hình phải có số thứ tự, tên mô tả rõ ràng và được nhắc tới trong phần nội dung trước hoặc ngay sau vị trí xuất hiện.
4. Chỉ ghi nhận kết quả đã quan sát được trên CentOS. Nội dung chưa chạy thực tế phải được ghi là dự kiến hoặc cần kiểm chứng.
5. Số trang trong Mục lục, Danh mục bảng và Danh mục hình sẽ được Word cập nhật tự động sau khi hoàn thiện toàn bộ nội dung.
