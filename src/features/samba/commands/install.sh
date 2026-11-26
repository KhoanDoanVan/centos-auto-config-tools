#!/usr/bin/env bash

samba_install() {
  require_root
  install_packages samba samba-common samba-common-tools samba-client cifs-utils
  if ! is_dry_run; then
    require_command_after_install testparm 'netadmin samba install'
    require_command_after_install smbclient 'netadmin samba install'
    require_command_after_install mount.cifs 'netadmin samba install'
  fi
  samba_ensure_config; samba_check
  service_action smb enable; service_action nmb enable
  firewall_add_service samba
  log_ok "Đã cài Samba. Hãy tạo share rồi khởi động dịch vụ."
}
