#!/usr/bin/env bash

dns_record_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    add) dns_record_add "$@" ;;
    list) require_args 1 "$#" 'netadmin dns record list <zone>'; cat "$(dns_zone_file "${1%.}")" ;;
    remove) dns_record_remove "$@" ;;
    *) die "Record action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

dns_validate_record() {
  local type="$1" value="$2"
  case "$type" in
    A) assert_ipv4 "$value" ;;
    AAAA) [[ "$value" == *:* ]] || die "IPv6 không hợp lệ: $value" ;;
    CNAME|NS|PTR) assert_hostname "${value%.}" ;;
    MX) [[ "$value" =~ ^[0-9]+[[:space:]]+[A-Za-z0-9.-]+\.?$ ]] || die "MX cần dạng '<priority> <host>'" ;;
    TXT) [[ "$value" != *$'\n'* ]] || die 'TXT không được chứa newline' ;;
    *) die "Record type không hỗ trợ: $type" ;;
  esac
}

dns_record_add() {
  require_args 4 "$#" 'netadmin dns record add <zone> <name> <type> <value> [ttl]'
  require_root
  local zone="${1%.}" name="$2" type value="$4" ttl="${5:-3600}" file backup
  type="$(printf '%s' "$3" | tr '[:lower:]' '[:upper:]')"
  [[ "$name" == @ || "$name" == \* ]] || assert_identifier "$name"
  assert_uint "$ttl"; dns_validate_record "$type" "$value"
  file="$(dns_zone_file "$zone")"; [[ -e "$file" ]] || die "Không tìm thấy zone file: $file"
  backup="$(backup_file "$file" dns)"
  if [[ "$type" == TXT ]]; then value="\"${value//\"/}\""; fi
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then log_info "Sẽ thêm $name $type vào $file"
  else printf '%-24s %s IN %-7s %s\n' "$name" "$ttl" "$type" "$value" >> "$file"; fi
  dns_bump_serial "$file"
  dns_zone_check "$zone" || { restore_backup_now "$file" "$backup"; die "Zone không hợp lệ; đã rollback."; }
  log_ok "Đã thêm $type record: $name"
}

dns_record_remove() {
  require_args 3 "$#" 'netadmin dns record remove <zone> <name> <type>'
  require_root
  local zone="${1%.}" name="$2" type file temporary backup
  type="$(printf '%s' "$3" | tr '[:lower:]' '[:upper:]')"
  file="$(dns_zone_file "$zone")"; [[ -e "$file" ]] || die "Không tìm thấy zone file: $file"
  backup="$(backup_file "$file" dns)"; temporary="$(mktemp)"
  awk -v n="$name" -v t="$type" 'BEGIN{IGNORECASE=1} $1==n && ($3==t || $4==t){found=1; next} {print} END{if(!found) exit 4}' "$file" > "$temporary" || { local s=$?; rm -f "$temporary"; [[ $s -eq 4 ]] && die "Không tìm thấy record"; return "$s"; }
  run install -o named -g named -m 0640 "$temporary" "$file"; rm -f "$temporary"
  dns_bump_serial "$file"
  dns_zone_check "$zone" || { restore_backup_now "$file" "$backup"; die "Zone không hợp lệ; đã rollback."; }
  log_ok "Đã xóa record $name $type"
}

dns_bump_serial() {
  local file="$1" temporary serial current
  serial="$(dns_next_serial)"
  current="$(awk '/; serial/{gsub(/[^0-9]/,"",$0); print $0; exit}' "$file")"
  if [[ "$current" =~ ^[0-9]+$ ]] && (( current >= serial )); then serial=$((current + 1)); fi
  temporary="$(mktemp)"
  awk -v s="$serial" '!done && /; serial/{sub(/^[[:space:]]*[0-9]+/,"  " s); done=1} {print}' "$file" > "$temporary"
  run install -o named -g named -m 0640 "$temporary" "$file"; rm -f "$temporary"
}
