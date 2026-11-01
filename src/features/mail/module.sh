#!/usr/bin/env bash

source "$APP_ROOT/src/features/mail/infra/mailstack.sh"
source "$APP_ROOT/src/features/dns/infra/bind.sh"
source "$APP_ROOT/src/features/dns/commands/zone.sh"
source "$APP_ROOT/src/features/dns/commands/record.sh"
source "$APP_ROOT/src/features/mail/commands/install.sh"
source "$APP_ROOT/src/features/mail/commands/configure.sh"
source "$APP_ROOT/src/features/mail/commands/user.sh"
source "$APP_ROOT/src/features/mail/commands/operations.sh"
source "$APP_ROOT/src/features/mail/commands/dns.sh"
source "$APP_ROOT/src/features/mail/commands/test.sh"

mail_help() {
  cat <<'EOF'
Cách dùng: netadmin mail <command> [arguments]

  install
  configure <domain> <server-fqdn> <trusted-network-cidr>
  dns setup <domain> <server-fqdn> <server-ip> | dns check <domain> [dns-server]
  test <smtp|pop3|imap> [host]
  user add <username> | user list | user remove <username>
  status | queue | log [lines]
  config show | config check | config rollback
  service postfix|dovecot <start|stop|restart|status|enable|enable-now>
EOF
}

mail_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install) mail_install "$@" ;;
    configure) mail_configure "$@" ;;
    dns) mail_dns_command "$@" ;;
    test) mail_test_command "$@" ;;
    user) mail_user_command "$@" ;;
    status) mail_status ;;
    queue) mail_queue ;;
    log) mail_log "${1:-50}" ;;
    config) mail_config_command "$@" ;;
    service) mail_service_command "$@" ;;
    help|-h|--help) mail_help ;;
    *) mail_help; die "Mail command không hỗ trợ: $command" ;;
  esac
}
