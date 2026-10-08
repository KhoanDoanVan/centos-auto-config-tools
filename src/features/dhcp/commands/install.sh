#!/usr/bin/env bash

dhcp_install() {
  require_root
  if command_exists dnf; then install_packages dhcp-server
  else install_packages dhcp; fi
  dhcp_ensure_config
  service_action dhcpd enable
  firewall_add_service dhcp
  log_ok "Đã cài DHCP. Hãy tạo scope trước khi khởi động dhcpd."
}
