#!/usr/bin/env bash

dispatch_command() {
  local command="$1"; shift
  case "$command" in
    doctor) doctor_command "$@" ;;
    dhcp) dhcp_command "$@" ;;
    dns) dns_command "$@" ;;
    storage) storage_command "$@" ;;
    samba) samba_command "$@" ;;
    *) print_root_help; die "Command không tồn tại: $command" ;;
  esac
}

print_root_help() {
  cat <<'EOF'
NetAdmin Toolkit - tự động cấu hình bài thực hành Quản trị mạng

Cách dùng:
  netadmin [--help|--version]
  netadmin <module> <command> [arguments]

Modules:
  doctor    Kiểm tra môi trường và dependencies
  dhcp      DHCP scopes, reservations và dịch vụ dhcpd
  dns       Network, BIND zones/records, secondary và forwarding
  storage   Disk, filesystem, LVM và quota
  samba     Samba shares, users, client và vận hành dịch vụ

Biến môi trường:
  NETADMIN_DRY_RUN=1       In lệnh thay vì thực thi
  NETADMIN_ASSUME_YES=1    Tự xác nhận thao tác không phá huỷ
  NETADMIN_ROOT=/path      Rootfs đích thay cho /
  NO_COLOR=1               Tắt màu output

Chạy `netadmin <module> help` để xem chi tiết.
EOF
}
