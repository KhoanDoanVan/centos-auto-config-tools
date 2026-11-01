#!/usr/bin/env bash

web_log_command() {
  local kind="${1:-access}" lines="${2:-50}" domain="${3:-}" file
  [[ "$kind" == access || "$kind" == error ]] || die "Log chỉ nhận access hoặc error"
  assert_uint "$lines"; (( lines > 0 && lines <= 5000 )) || die "Số dòng phải từ 1 đến 5000"
  if [[ -n "$domain" ]]; then
    assert_domain "$domain"; file="$(web_log_dir)/${domain}-${kind}.log"
  else
    file="$(web_log_dir)/${kind}_log"
  fi
  [[ -r "$file" ]] || die "Không đọc được log: $file"
  tail -n "$lines" "$file"
}

web_config_command() {
  local action="${1:-show}"
  case "$action" in
    show)
      local directory; directory="$(web_config_dir)"
      grep -l '^# NETADMIN:WEB:' "$directory"/netadmin-*.conf 2>/dev/null | while IFS= read -r file; do
        printf '\n### %s\n' "$file"; cat "$file"
      done
      ;;
    check) web_check ;;
    rollback)
      require_root; require_args 2 "$#" 'netadmin web config rollback <domain>'
      local config; config="$(web_site_config "$2")"
      restore_latest_backup "$config" web; web_check
      ;;
    *) die "Web config action không hỗ trợ: $action" ;;
  esac
}
