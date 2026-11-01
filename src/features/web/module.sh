#!/usr/bin/env bash

source "$APP_ROOT/src/features/web/infra/apache.sh"
source "$APP_ROOT/src/features/dns/infra/bind.sh"
source "$APP_ROOT/src/features/dns/commands/zone.sh"
source "$APP_ROOT/src/features/dns/commands/record.sh"
source "$APP_ROOT/src/features/web/commands/install.sh"
source "$APP_ROOT/src/features/web/commands/site.sh"
source "$APP_ROOT/src/features/web/commands/dns.sh"
source "$APP_ROOT/src/features/web/commands/operations.sh"

web_help() {
  cat <<'EOF'
Cách dùng: netadmin web <command> [arguments]

  install
  site add <domain> <document-root>
  site list | site show <domain> | site remove <domain>
  site backup <domain> | site restore <domain> [archive]
  dns setup <zone> <host|@> <server-ip> | dns remove <zone> <host|@>
  log access|error [lines] [domain]
  config show | config check | config rollback <domain>
  service <start|stop|restart|reload|status|enable|enable-now>
EOF
}

web_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install) web_install "$@" ;;
    site) web_site_command "$@" ;;
    dns) web_dns_command "$@" ;;
    log) web_log_command "$@" ;;
    config) web_config_command "$@" ;;
    service) require_args 1 "$#" 'netadmin web service <action>'; service_action httpd "$1" ;;
    help|-h|--help) web_help ;;
    *) web_help; die "Web command không hỗ trợ: $command" ;;
  esac
}
