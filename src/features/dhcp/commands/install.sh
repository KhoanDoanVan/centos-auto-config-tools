#!/usr/bin/env bash

dhcp_install() {
  require_root
  local version major
  version="$(os_version_id 2>/dev/null || true)"; major="${version%%.*}"
  if is_rhel_family && [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 10 )); then
    die "RHEL/CentOS 10 đã gỡ ISC DHCP. Module hiện dùng dhcpd và cần hệ RHEL cũ hơn 10 (ưu tiên Rocky/Alma 9); không cài package giả hoặc bỏ qua lỗi."
  fi
  if command_exists dnf; then install_packages dhcp-server
  else install_packages dhcp; fi
  dhcp_ensure_config
  service_action dhcpd enable
  firewall_add_service dhcp
  log_ok "Đã cài DHCP. Hãy tạo scope trước khi khởi động dhcpd."
}
