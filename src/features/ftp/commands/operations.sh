#!/usr/bin/env bash

ftp_status() {
  systemctl status vsftpd --no-pager || true
  command_exists ss && ss -lntp | awk 'NR==1 || /:21[[:space:]]/' || true
}

ftp_sessions() {
  if command_exists ss; then
    ss -ntp | awk 'NR==1 || /:21[[:space:]]/'
  else
    die "Thiếu command: ss"
  fi
}

ftp_log() {
  local lines="${1:-50}" file
  assert_uint "$lines"; (( lines > 0 && lines <= 5000 )) || die "Số dòng phải từ 1 đến 5000"
  for file in "$(system_path /var/log/xferlog)" "$(system_path /var/log/vsftpd.log)"; do
    if [[ -r "$file" ]]; then tail -n "$lines" "$file"; return; fi
  done
  command_exists journalctl && journalctl -u vsftpd -n "$lines" --no-pager || die "Không tìm thấy FTP log."
}

ftp_diagnose() {
  local config registry path mode name failed=0
  config="$(ftp_config_path)"; registry="$(ftp_share_registry)"
  printf '%-24s %s\n' 'vsftpd service' "$(systemctl is-active vsftpd 2>/dev/null || true)"
  if command_exists ss; then ss -lnt | awk 'NR==1 || /:21[[:space:]]/'; else log_warn 'Thiếu ss'; failed=1; fi
  if command_exists firewall-cmd && service_is_active firewalld; then firewall-cmd --list-services; firewall-cmd --list-ports; else log_warn 'firewalld không hoạt động'; fi
  command_exists getenforce && printf '%-24s %s\n' SELinux "$(getenforce)"
  ftp_check || failed=1
  if [[ -r "$registry" ]]; then
    while IFS=$'\t' read -r name path mode; do
      [[ -z "$name" || "$name" == \#* ]] && continue
      [[ -d "$(system_path "$path")" ]] || { log_warn "Share path bị thiếu: $name -> $path"; failed=1; }
    done < "$registry"
  fi
  (( failed == 0 )) && log_ok 'FTP diagnostics không phát hiện lỗi.' || die 'FTP diagnostics phát hiện vấn đề.'
}

ftp_config_command() {
  local action="${1:-show}" config; config="$(ftp_config_path)"
  case "$action" in
    show) cat "$config" ;;
    check) ftp_check ;;
    rollback) require_root; restore_latest_backup "$config" ftp; ftp_check ;;
    *) die "FTP config action không hỗ trợ: $action" ;;
  esac
}
