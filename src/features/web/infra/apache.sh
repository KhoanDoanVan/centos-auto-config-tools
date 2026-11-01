#!/usr/bin/env bash

web_config_dir() { system_path "${WEB_CONFIG_DIR:-/etc/httpd/conf.d}"; }
web_log_dir() { system_path "${WEB_LOG_DIR:-/var/log/httpd}"; }
web_domain_key() { printf '%s' "$1" | tr '.:/' '---'; }
web_site_config() { printf '%s/netadmin-%s.conf\n' "$(web_config_dir)" "$(web_domain_key "$1")"; }

web_check() {
  require_command apachectl
  run apachectl configtest
}

web_prepare_selinux_path() {
  local path="$1"
  if command_exists getenforce && [[ "$(getenforce)" != Disabled ]]; then
    if command_exists semanage; then
      semanage fcontext -a -t httpd_sys_content_t "${path}(/.*)?" 2>/dev/null || \
        semanage fcontext -m -t httpd_sys_content_t "${path}(/.*)?"
      run restorecon -Rv "$path"
    elif command_exists chcon; then
      run chcon -Rt httpd_sys_content_t "$path"
      log_warn "SELinux context được đặt bằng chcon và có thể mất sau relabel."
    fi
  fi
}
