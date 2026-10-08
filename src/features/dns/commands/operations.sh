#!/usr/bin/env bash

dns_transfer_command() {
  local action="${1:-}"; shift || true
  [[ "$action" == allow ]] || die 'Cách dùng: netadmin dns transfer allow <zone> <secondary-ip>'
  require_args 2 "$#" 'netadmin dns transfer allow <zone> <secondary-ip>'; require_root
  local zone="${1%.}" secondary="$2" managed temporary backup
  assert_ipv4 "$secondary"; managed="$(dns_managed_config_path)"; temporary="$(mktemp)"
  backup="$(backup_file "$managed" dns)"
  if ! awk -v begin="// NETADMIN:ZONE:$zone:BEGIN" -v ip="$secondary" '
      $0==begin {inside=1; found=1} inside && /allow-transfer/ {next}
      inside && /^[[:space:]]*};/ {print "  allow-transfer { " ip "; };"; inside=0}
      {print}
      END {if(!found) exit 4}
    ' "$managed" > "$temporary"; then
    rm -f "$temporary"; die "Không tìm thấy zone: $zone"
  fi
  run install -m 0644 "$temporary" "$managed"; rm -f "$temporary"
  dns_check || { restore_backup_now "$managed" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã cho phép transfer $zone tới $secondary"
}

dns_forwarders_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    set) require_args 1 "$#" 'netadmin dns forwarders set <ip[,ip]>'; dns_forwarders_set "$1" ;;
    clear) dns_forwarders_set '' ;;
    *) die "Forwarders action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

dns_forwarders_set() {
  require_root
  local csv="$1" config temporary ip list='' backup
  config="$(dns_config_path)"; backup="$(backup_file "$config" dns)"
  if [[ -n "$csv" ]]; then IFS=',' read -r -a values <<< "$csv"; for ip in "${values[@]}"; do assert_ipv4 "$ip"; list+=" $ip;"; done; fi
  temporary="$(mktemp)"
  awk -v value="$list" '
    /\/\/ NETADMIN:FORWARDERS/ {next}
    !inserted && /^[[:space:]]*options[[:space:]]*\{/ {print; if(value!="") print "  forwarders {" value " }; // NETADMIN:FORWARDERS"; inserted=1; next}
    {print}
  ' "$config" > "$temporary"
  run install -m 0640 "$temporary" "$config"; rm -f "$temporary"
  dns_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã cập nhật DNS forwarders."
}

dns_query() {
  require_args 1 "$#" 'netadmin dns query <name> [server]'; require_command dig
  if [[ -n "${2:-}" ]]; then assert_ipv4 "$2"; dig "@$2" "$1"; else dig "$1"; fi
}

dns_config_command() {
  local action="${1:-show}" config; config="$(dns_config_path)"
  case "$action" in
    show) cat "$config"; printf '\n'; cat "$(dns_managed_config_path)" ;;
    check) dns_check; log_ok 'Cấu hình BIND hợp lệ.' ;;
    rollback) require_root; restore_latest_backup "$config" dns; dns_check ;;
    *) die "Config action không hỗ trợ: $action" ;;
  esac
}
