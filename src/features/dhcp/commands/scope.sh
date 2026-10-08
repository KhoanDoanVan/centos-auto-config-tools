#!/usr/bin/env bash

dhcp_scope_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add) dhcp_scope_add "$@" ;;
    update) DHCP_REPLACE=1 dhcp_scope_add "$@" ;;
    list) grep '^# NETADMIN:SCOPE:.*:BEGIN$' "$(dhcp_config_path)" 2>/dev/null | cut -d: -f3 || true ;;
    remove) require_args 1 "$#" 'netadmin dhcp scope remove <name>'; dhcp_scope_remove "$1" ;;
    *) die "Scope action không hỗ trợ: $action" ;;
  esac
}

dhcp_scope_add() {
  require_args 7 "$#" 'netadmin dhcp scope add <name> <subnet> <netmask> <start> <end> <gateway> <dns[,dns]> [domain] [lease]'
  require_root
  local name="$1" subnet="$2" netmask="$3" start="$4" end="$5" gateway="$6" dns_csv="$7"
  local domain="${8:-lab.local}" lease="${9:-600}" dns formatted_dns config backup
  assert_identifier "$name"; assert_ipv4 "$subnet"; netmask_to_prefix "$netmask" >/dev/null || die "Netmask không hợp lệ: $netmask"
  assert_ipv4 "$start"; assert_ipv4 "$end"; assert_ipv4 "$gateway"; assert_domain "$domain"; assert_uint "$lease"
  ipv4_in_subnet "$start" "$subnet" "$netmask" || die "Start IP nằm ngoài subnet"
  ipv4_in_subnet "$end" "$subnet" "$netmask" || die "End IP nằm ngoài subnet"
  ipv4_in_subnet "$gateway" "$subnet" "$netmask" || die "Gateway nằm ngoài subnet"
  (( $(ipv4_to_int "$start") <= $(ipv4_to_int "$end") )) || die "Start IP phải nhỏ hơn hoặc bằng End IP"
  formatted_dns=''
  IFS=',' read -r -a dns_values <<< "$dns_csv"
  for dns in "${dns_values[@]}"; do assert_ipv4 "$dns"; formatted_dns+="${formatted_dns:+, }$dns"; done
  config="$(dhcp_config_path)"; dhcp_ensure_config
  if grep -Fqx "# NETADMIN:SCOPE:$name:BEGIN" "$config"; then
    [[ "${DHCP_REPLACE:-0}" == 1 ]] || die "Scope đã tồn tại: $name"
  elif [[ "${DHCP_REPLACE:-0}" == 1 ]]; then
    die "Không tìm thấy scope để cập nhật: $name"
  fi
  backup="$(backup_file "$config" dhcp)"
  if [[ "${DHCP_REPLACE:-0}" == 1 ]]; then dhcp_remove_block SCOPE "$name"; fi
  dhcp_append_block <<EOF

# NETADMIN:SCOPE:$name:BEGIN
subnet $subnet netmask $netmask {
  range $start $end;
  option routers $gateway;
  option subnet-mask $netmask;
  option domain-name "$domain";
  option domain-name-servers $formatted_dns;
  default-lease-time $lease;
  max-lease-time $((lease * 12));
}
# NETADMIN:SCOPE:$name:END
EOF
  dhcp_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã lưu DHCP scope: $name"
}

dhcp_scope_remove() {
  require_root; assert_identifier "$1"
  local config backup; config="$(dhcp_config_path)"; backup="$(backup_file "$config" dhcp)"
  dhcp_remove_block SCOPE "$1" || die "Không tìm thấy scope: $1"
  dhcp_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã xóa DHCP scope: $1"
}
