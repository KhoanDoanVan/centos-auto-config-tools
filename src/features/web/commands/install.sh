#!/usr/bin/env bash

web_install() {
  require_root
  install_packages httpd curl tar bind bind-utils policycoreutils
  if ! is_dry_run; then
    require_command_after_install apachectl 'netadmin web install'
    require_command_after_install named-checkconf 'netadmin web install'
  fi
  run mkdir -p "$(web_config_dir)"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]] && { [[ ! -e "$(dns_config_path)" ]] || ! command_exists apachectl; }; then
    log_info "Sẽ kiểm tra Apache/BIND, enable/start httpd và named, rồi mở HTTP/DNS sau khi cài package."
    return
  fi
  if command_exists apachectl; then web_check
  elif [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then log_info "Sẽ chạy apachectl configtest sau khi cài httpd."
  else require_command_after_install apachectl 'netadmin web install'
  fi
  service_action httpd enable-now
  firewall_add_service http
  dns_ensure_managed_include
  dns_check
  service_action named enable-now
  firewall_add_service dns
  log_ok "Đã cài và khởi động Apache/BIND. Hãy tạo website và DNS record."
}
