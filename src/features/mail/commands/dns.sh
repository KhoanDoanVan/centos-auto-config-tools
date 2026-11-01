#!/usr/bin/env bash

mail_dns_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    setup) require_args 3 "$#" 'netadmin mail dns setup <domain> <server-fqdn> <server-ip>'; mail_dns_setup "$1" "$2" "$3" ;;
    check) require_args 1 "$#" 'netadmin mail dns check <domain> [dns-server]'; mail_dns_check "$@" ;;
    *) die "Mail DNS action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

mail_dns_setup() {
  local domain="${1%.}" fqdn="${2%.}" ip="$3" host file mx_value
  require_root; assert_domain "$domain"; assert_hostname "$fqdn"; assert_ipv4 "$ip"
  [[ "$fqdn" == "$domain" || "$fqdn" == *".$domain" ]] || die "FQDN phải thuộc domain $domain"
  if [[ "$fqdn" == "$domain" ]]; then host=@; else host="${fqdn%.$domain}"; assert_identifier "$host"; fi
  file="$(dns_zone_file "$domain")"
  [[ -e "$file" ]] || dns_zone_add "$domain" "$ip"
  if ! awk -v name="$host" -v ip="$ip" '$1==name && ($3=="A" || $4=="A") && $NF==ip {found=1} END{exit !found}' "$file"; then
    dns_record_add "$domain" "$host" A "$ip"
  fi
  mx_value="10 $fqdn."
  if ! awk -v value="$mx_value" '$1=="@" && ($3=="MX" || $4=="MX") {candidate=$(NF-1) " " $NF; if(candidate==value)found=1} END{exit !found}' "$file"; then
    dns_record_add "$domain" @ MX "$mx_value"
  fi
  log_ok "DNS mail đã sẵn sàng: $fqdn -> $ip; $domain MX $fqdn"
}

mail_dns_check() {
  local domain="${1%.}" server="${2:-}" query_args=()
  assert_domain "$domain"; require_command dig
  if [[ -n "$server" ]]; then assert_ipv4 "$server"; query_args+=("@$server"); fi
  dig "${query_args[@]}" "$domain" MX
}
