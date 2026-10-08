#!/usr/bin/env bash

source "$APP_ROOT/src/features/dns/infra/bind.sh"
source "$APP_ROOT/src/features/dns/commands/install.sh"
source "$APP_ROOT/src/features/dns/commands/network.sh"
source "$APP_ROOT/src/features/dns/commands/zone.sh"
source "$APP_ROOT/src/features/dns/commands/record.sh"
source "$APP_ROOT/src/features/dns/commands/operations.sh"

dns_help() {
  cat <<'EOF'
Cách dùng: netadmin dns <command> [arguments]

  install
  network static <connection> <address/prefix> <gateway> <dns[,dns]>
  network dhcp <connection> | network list
  zone add <domain> <server-ip> [admin-label]
  zone add-reverse <reverse-zone> <server-fqdn>
  zone add-secondary <domain> <primary-ip>
  zone list | zone remove <domain-or-zone>
  record add <zone> <name> <A|AAAA|CNAME|MX|NS|TXT|PTR> <value> [ttl]
  record list <zone> | record remove <zone> <name> <type>
  transfer allow <zone> <secondary-ip>
  forwarders set <ip[,ip]> | forwarders clear
  query <name> [server]
  config show | config check | config rollback
  service <start|stop|restart|status|enable|enable-now>
EOF
}

dns_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install) dns_install "$@" ;;
    network) dns_network_command "$@" ;;
    zone) dns_zone_command "$@" ;;
    record) dns_record_command "$@" ;;
    transfer) dns_transfer_command "$@" ;;
    forwarders) dns_forwarders_command "$@" ;;
    query) dns_query "$@" ;;
    config) dns_config_command "$@" ;;
    service) require_args 1 "$#" 'netadmin dns service <action>'; service_action named "$1" ;;
    help|-h|--help) dns_help ;;
    *) dns_help; die "DNS command không hỗ trợ: $command" ;;
  esac
}
