#!/usr/bin/env bash

ftp_dns_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    setup) require_args 3 "$#" 'netadmin ftp dns setup <zone> <host|@> <server-ip>'; ftp_dns_setup "$1" "$2" "$3" ;;
    check) require_args 1 "$#" 'netadmin ftp dns check <fqdn> [dns-server]'; ftp_dns_check "$@" ;;
    remove) require_args 2 "$#" 'netadmin ftp dns remove <zone> <host|@>'; dns_record_remove "$1" "$2" A ;;
    *) die "FTP DNS action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

ftp_dns_setup() {
  local zone="${1%.}" host="$2" ip="$3" file fqdn
  require_root; assert_domain "$zone"; [[ "$host" == @ ]] || assert_identifier "$host"; assert_ipv4 "$ip"
  file="$(dns_zone_file "$zone")"
  [[ -e "$file" ]] || dns_zone_add "$zone" "$ip"
  if ! awk -v name="$host" -v ip="$ip" '$1==name && ($3=="A" || $4=="A") && $NF==ip {found=1} END{exit !found}' "$file"; then
    dns_record_add "$zone" "$host" A "$ip"
  fi
  if [[ "$host" == @ ]]; then fqdn="$zone"; else fqdn="$host.$zone"; fi
  log_ok "FTP DNS đã sẵn sàng: $fqdn -> $ip"
}

ftp_dns_check() {
  local fqdn="${1%.}" server="${2:-}" args=()
  assert_hostname "$fqdn"; require_command dig
  if [[ -n "$server" ]]; then assert_ipv4 "$server"; args+=("@$server"); fi
  dig "${args[@]}" "$fqdn" A
}
