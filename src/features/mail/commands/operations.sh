#!/usr/bin/env bash

mail_status() {
  systemctl status postfix --no-pager || true
  systemctl status dovecot --no-pager || true
  command_exists ss && ss -lntp | awk 'NR==1 || /:(25|110|143)[[:space:]]/' || true
}

mail_queue() {
  require_command mailq
  mailq
}

mail_log() {
  local lines="$1" file
  assert_uint "$lines"; (( lines > 0 && lines <= 5000 )) || die "Số dòng phải từ 1 đến 5000"
  for file in "$(system_path /var/log/maillog)" "$(system_path /var/log/mail.log)"; do
    if [[ -r "$file" ]]; then tail -n "$lines" "$file"; return; fi
  done
  if command_exists journalctl; then journalctl -u postfix -u dovecot -n "$lines" --no-pager; else die "Không tìm thấy mail log."; fi
}

mail_config_command() {
  local action="${1:-show}" postfix_config dovecot_config
  postfix_config="$(mail_postfix_config)"; dovecot_config="$(mail_dovecot_config)"
  case "$action" in
    show)
      require_command postconf
      postconf -n
      printf '\n### Dovecot\n'
      [[ -r "$dovecot_config" ]] && cat "$dovecot_config" || true
      ;;
    check) mail_check ;;
    rollback)
      require_root
      restore_latest_backup "$postfix_config" mail
      if latest_backup mail "$(basename "$dovecot_config")" >/dev/null 2>&1; then restore_latest_backup "$dovecot_config" mail; fi
      mail_check
      ;;
    *) die "Mail config action không hỗ trợ: $action" ;;
  esac
}

mail_service_command() {
  require_args 2 "$#" 'netadmin mail service postfix|dovecot <action>'
  [[ "$1" == postfix || "$1" == dovecot ]] || die "Service chỉ nhận postfix hoặc dovecot"
  service_action "$1" "$2"
}
