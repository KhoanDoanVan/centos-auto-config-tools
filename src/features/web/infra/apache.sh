#!/usr/bin/env bash

web_config_dir() { system_path "${WEB_CONFIG_DIR:-/etc/httpd/conf.d}"; }
web_log_dir() { system_path "${WEB_LOG_DIR:-/var/log/httpd}"; }
web_domain_key() { printf '%s' "$1" | tr '.:/' '---'; }
web_site_config() { printf '%s/netadmin-%s.conf\n' "$(web_config_dir)" "$(web_domain_key "$1")"; }

web_check() {
  require_command_after_install apachectl 'netadmin web install'
  run apachectl configtest
}

web_prepare_selinux_path() {
  selinux_set_file_context "$1" httpd_sys_content_t
}
