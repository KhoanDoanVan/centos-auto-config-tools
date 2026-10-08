#!/usr/bin/env bash

dns_zone_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add) dns_zone_add "$@" ;;
    add-reverse) dns_reverse_zone_add "$@" ;;
    add-secondary) dns_secondary_zone_add "$@" ;;
    list) grep '^// NETADMIN:ZONE:.*:BEGIN$' "$(dns_managed_config_path)" 2>/dev/null | cut -d: -f3 || true ;;
    remove) require_args 1 "$#" 'netadmin dns zone remove <zone>'; dns_zone_remove "$1" ;;
    *) die "Zone action không hỗ trợ: $action" ;;
  esac
}

dns_zone_add() {
  require_args 2 "$#" 'netadmin dns zone add <domain> <server-ip> [admin-label]'
  require_root
  local zone="${1%.}" ip="$2" admin="${3:-hostmaster}" managed zone_file temporary fqdn backup
  assert_domain "$zone"; assert_ipv4 "$ip"; assert_identifier "$admin"
  fqdn="ns1.$zone."; dns_ensure_managed_include; managed="$(dns_managed_config_path)"; zone_file="$(dns_zone_file "$zone")"
  grep -Fqx "// NETADMIN:ZONE:$zone:BEGIN" "$managed" && die "Zone đã tồn tại: $zone"
  [[ ! -e "$zone_file" ]] || die "Zone file đã tồn tại: $zone_file"
  backup="$(backup_file "$managed" dns)"
  temporary="$(mktemp)"
  cat > "$temporary" <<EOF
\$TTL 86400
@ IN SOA $fqdn $admin.$zone. (
  $(dns_next_serial) ; serial
  3600 ; refresh
  900 ; retry
  604800 ; expire
  86400 ; minimum
)
@   IN NS $fqdn
ns1 IN A  $ip
@   IN A  $ip
EOF
  dns_install_zone_file "$temporary" "$zone_file"; rm -f "$temporary"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then cat >> "$managed" <<EOF

// NETADMIN:ZONE:$zone:BEGIN
zone "$zone" IN {
  type master;
  file "$(basename "$zone_file")";
  allow-update { none; };
};
// NETADMIN:ZONE:$zone:END
EOF
  fi
  if ! dns_zone_check "$zone" || ! dns_check; then
    restore_backup_now "$managed" "$backup"
    [[ -e "$zone_file" ]] && run mv "$zone_file" "$zone_file.failed.$(date +%s)"
    die "Cấu hình zone lỗi; đã rollback."
  fi
  log_ok "Đã tạo master zone: $zone"
}

dns_reverse_zone_add() {
  require_args 2 "$#" 'netadmin dns zone add-reverse <reverse-zone> <server-fqdn>'
  require_root
  local zone="${1%.}" server="${2%.}." managed zone_file temporary backup
  [[ "$zone" == *.in-addr.arpa ]] || die "Reverse zone phải kết thúc bằng .in-addr.arpa"
  assert_hostname "${server%.}"; dns_ensure_managed_include; managed="$(dns_managed_config_path)"; zone_file="$(dns_zone_file "$zone")"
  grep -Fqx "// NETADMIN:ZONE:$zone:BEGIN" "$managed" && die "Zone đã tồn tại: $zone"
  backup="$(backup_file "$managed" dns)"
  temporary="$(mktemp)"; cat > "$temporary" <<EOF
\$TTL 86400
@ IN SOA $server hostmaster.${server} (
  $(dns_next_serial) 3600 900 604800 86400
)
@ IN NS $server
EOF
  dns_install_zone_file "$temporary" "$zone_file"; rm -f "$temporary"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then cat >> "$managed" <<EOF

// NETADMIN:ZONE:$zone:BEGIN
zone "$zone" IN { type master; file "$(basename "$zone_file")"; allow-update { none; }; };
// NETADMIN:ZONE:$zone:END
EOF
  fi
  if ! dns_zone_check "$zone" || ! dns_check; then
    restore_backup_now "$managed" "$backup"
    [[ -e "$zone_file" ]] && run mv "$zone_file" "$zone_file.failed.$(date +%s)"
    die "Cấu hình zone lỗi; đã rollback."
  fi
  log_ok "Đã tạo reverse zone: $zone"
}

dns_secondary_zone_add() {
  require_args 2 "$#" 'netadmin dns zone add-secondary <domain> <primary-ip>'
  require_root
  local zone="${1%.}" primary="$2" managed slave_dir backup
  assert_domain "$zone"; assert_ipv4 "$primary"; dns_ensure_managed_include
  managed="$(dns_managed_config_path)"; slave_dir="$(system_path /var/named/slaves)"
  grep -Fqx "// NETADMIN:ZONE:$zone:BEGIN" "$managed" && die "Zone đã tồn tại: $zone"
  backup="$(backup_file "$managed" dns)"
  run install -d -o named -g named -m 0770 "$slave_dir"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then cat >> "$managed" <<EOF

// NETADMIN:ZONE:$zone:BEGIN
zone "$zone" IN {
  type slave;
  masters { $primary; };
  file "slaves/db.$(dns_zone_key "$zone")";
};
// NETADMIN:ZONE:$zone:END
EOF
  fi
  dns_check || { restore_backup_now "$managed" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã tạo secondary zone: $zone"
}

dns_zone_remove() {
  require_root
  local zone="${1%.}" file managed backup
  [[ "$zone" == *.in-addr.arpa ]] || assert_domain "$zone"
  managed="$(dns_managed_config_path)"; file="$(dns_zone_file "$zone")"
  backup="$(backup_file "$managed" dns)"; [[ -e "$file" ]] && backup_file "$file" dns >/dev/null
  dns_remove_zone_block "$zone" || die "Không tìm thấy zone: $zone"
  dns_check || { restore_backup_now "$managed" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  if [[ -e "$file" ]]; then run mv "$file" "$file.removed.$(date +%s)"; fi
  log_ok "Đã gỡ zone: $zone"
}
