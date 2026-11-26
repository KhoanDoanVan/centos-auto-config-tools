#!/usr/bin/env bash

dns_install() {
  require_root
  install_packages bind bind-utils NetworkManager
  if ! is_dry_run; then
    require_command_after_install named-checkconf 'netadmin dns install'
    require_command_after_install named-checkzone 'netadmin dns install'
    require_command_after_install dig 'netadmin dns install'
  fi
  dns_ensure_managed_include
  dns_check
  service_action named enable
  firewall_add_service dns
  log_ok "Đã cài BIND và tạo vùng cấu hình managed."
}
