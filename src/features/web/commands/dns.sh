#!/usr/bin/env bash

web_dns_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    setup) require_args 3 "$#" 'netadmin web dns setup <zone> <host|@> <server-ip>'; web_dns_setup "$1" "$2" "$3" ;;
    remove) require_args 2 "$#" 'netadmin web dns remove <zone> <host|@>'; dns_record_remove "$1" "$2" A ;;
    *) die "Web DNS action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

web_dns_setup() {
  local zone="${1%.}" host="$2" ip="$3" file fqdn
  require_root; assert_domain "$zone"; [[ "$host" == @ ]] || assert_identifier "$host"; assert_ipv4 "$ip"
  file="$(dns_zone_file "$zone")"
  if [[ ! -e "$file" ]]; then
    dns_zone_add "$zone" "$ip"
  fi
  if awk -v name="$host" -v ip="$ip" '$1==name && ($3=="A" || $4=="A") && $NF==ip {found=1} END{exit !found}' "$file"; then
    log_info "A record đã tồn tại: $host.$zone -> $ip"
  else
    dns_record_add "$zone" "$host" A "$ip"
  fi
  if [[ "$host" == @ ]]; then fqdn="$zone"; else fqdn="$host.$zone"; fi
  log_ok "DNS đã sẵn sàng cho $fqdn -> $ip"
}
