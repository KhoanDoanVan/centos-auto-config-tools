#!/usr/bin/env bash

source "$APP_ROOT/src/features/ftp/infra/vsftpd.sh"
source "$APP_ROOT/src/features/dns/infra/bind.sh"
source "$APP_ROOT/src/features/dns/commands/zone.sh"
source "$APP_ROOT/src/features/dns/commands/record.sh"
source "$APP_ROOT/src/features/ftp/commands/install.sh"
source "$APP_ROOT/src/features/ftp/commands/share.sh"
source "$APP_ROOT/src/features/ftp/commands/user.sh"
source "$APP_ROOT/src/features/ftp/commands/operations.sh"
source "$APP_ROOT/src/features/ftp/commands/tls.sh"
source "$APP_ROOT/src/features/ftp/commands/dns.sh"

ftp_help() {
  cat <<'EOF'
Cách dùng: netadmin ftp <command> [arguments]

  install
  share add-anonymous <name> [read-only|read-write]
  share list | share remove <name> | share backup <name>
  share restore <name> [backup-dir]
  user add <username> <home> | user list | user remove <username>
  user lock|unlock <username>
  status | sessions | diagnose | log [lines]
  tls configure <certificate> <private-key> | tls disable | tls status
  dns setup <zone> <host|@> <server-ip> | dns check <fqdn> [dns-server]
  dns remove <zone> <host|@>
  config show | config check | config rollback
  service <start|stop|restart|status|enable|enable-now>
EOF
}

ftp_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install) ftp_install "$@" ;;
    share) ftp_share_command "$@" ;;
    user) ftp_user_command "$@" ;;
    status) ftp_status ;;
    sessions) ftp_sessions ;;
    diagnose) ftp_diagnose ;;
    log) ftp_log "${1:-50}" ;;
    tls) ftp_tls_command "$@" ;;
    dns) ftp_dns_command "$@" ;;
    config) ftp_config_command "$@" ;;
    service) require_args 1 "$#" 'netadmin ftp service <action>'; service_action vsftpd "$1" ;;
    help|-h|--help) ftp_help ;;
    *) ftp_help; die "FTP command không hỗ trợ: $command" ;;
  esac
}
