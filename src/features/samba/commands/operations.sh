#!/usr/bin/env bash

samba_config_command() {
  local action="${1:-show}" config; config="$(samba_config_path)"
  case "$action" in
    show) cat "$config" ;;
    check) samba_check; testparm -s "$config" ;;
    apply) require_root; samba_check; service_action smb restart; service_action nmb restart; log_ok 'Đã áp dụng cấu hình Samba.' ;;
    rollback) require_root; restore_latest_backup "$config" samba; samba_check ;;
    *) die "Config action không hỗ trợ: $action" ;;
  esac
}
