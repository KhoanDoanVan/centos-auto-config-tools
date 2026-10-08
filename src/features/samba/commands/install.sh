#!/usr/bin/env bash

samba_install() {
  require_root
  install_packages samba samba-common samba-common-tools samba-client cifs-utils
  samba_ensure_config; samba_check
  service_action smb enable; service_action nmb enable
  firewall_add_service samba
  log_ok "Đã cài Samba. Hãy tạo share rồi khởi động dịch vụ."
}
