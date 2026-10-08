#!/usr/bin/env bash

dhcp_reservation_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add) dhcp_reservation_add "$@" ;;
    list) grep '^# NETADMIN:HOST:.*:BEGIN$' "$(dhcp_config_path)" 2>/dev/null | cut -d: -f3 || true ;;
    remove) require_args 1 "$#" 'netadmin dhcp reservation remove <name>'; dhcp_reservation_remove "$1" ;;
    *) die "Reservation action không hỗ trợ: $action" ;;
  esac
}

dhcp_reservation_add() {
  require_args 3 "$#" 'netadmin dhcp reservation add <name> <mac> <ip> [hostname]'
  require_root
  local name="$1" mac ip="$3" hostname="${4:-$1}" config backup
  mac="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
  assert_identifier "$name"; assert_mac "$mac"; assert_ipv4 "$ip"; assert_hostname "$hostname"
  config="$(dhcp_config_path)"; dhcp_ensure_config
  grep -Fqx "# NETADMIN:HOST:$name:BEGIN" "$config" && die "Reservation đã tồn tại: $name"
  grep -Eiq "^[[:space:]]*hardware ethernet[[:space:]]+$mac;" "$config" && die "MAC đã được dùng trong reservation khác: $mac"
  grep -Eq "^[[:space:]]*fixed-address[[:space:]]+$ip;" "$config" && die "IP đã được dùng trong reservation khác: $ip"
  backup="$(backup_file "$config" dhcp)"
  dhcp_append_block <<EOF

# NETADMIN:HOST:$name:BEGIN
host $name {
  hardware ethernet $mac;
  fixed-address $ip;
  option host-name "$hostname";
}
# NETADMIN:HOST:$name:END
EOF
  dhcp_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã thêm reservation: $name -> $ip"
}

dhcp_reservation_remove() {
  require_root; assert_identifier "$1"
  local config backup; config="$(dhcp_config_path)"; backup="$(backup_file "$config" dhcp)"
  dhcp_remove_block HOST "$1" || die "Không tìm thấy reservation: $1"
  dhcp_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã xóa reservation: $1"
}
