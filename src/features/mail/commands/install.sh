#!/usr/bin/env bash

mail_install() {
  require_root
  install_packages postfix dovecot s-nail nmap-ncat bind bind-utils policycoreutils
  service_action postfix enable
  service_action dovecot enable
  firewall_add_service smtp
  firewall_add_service imap
  firewall_add_service pop3
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 && ! -e "$(dns_config_path)" ]]; then
    log_info "Sẽ chuẩn bị BIND, enable/start named và mở DNS sau khi cài package."
    log_ok "Sẽ cài Postfix và Dovecot; cần chạy 'netadmin mail configure ...' trước khi khởi động dịch vụ."
    return
  fi
  dns_ensure_managed_include
  dns_check
  service_action named enable-now
  firewall_add_service dns
  log_ok "Đã cài Postfix và Dovecot. Chạy 'netadmin mail configure ...' trước khi khởi động dịch vụ."
  log_warn "Webmail không tự cài vì SquirrelMail không bảo đảm có trên CentOS Stream 10; Roundcube cần stack PHP/database riêng."
}
