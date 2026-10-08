#!/usr/bin/env bash

source "$APP_ROOT/src/features/dhcp/infra/dhcpd.sh"
source "$APP_ROOT/src/features/dhcp/commands/install.sh"
source "$APP_ROOT/src/features/dhcp/commands/scope.sh"
source "$APP_ROOT/src/features/dhcp/commands/reservation.sh"
source "$APP_ROOT/src/features/dhcp/commands/operations.sh"

dhcp_help() {
  cat <<'EOF'
Cách dùng: netadmin dhcp <command> [arguments]

  install
  scope add|update <name> <subnet> <netmask> <start-ip> <end-ip> <gateway> <dns[,dns]> [domain] [lease-seconds]
  scope list | scope remove <name>
  reservation add <name> <mac> <ip> [hostname]
  reservation list | reservation remove <name>
  lease list | lease release <ip>
  config show | config check | config rollback
  service <start|stop|restart|status|enable|enable-now>
EOF
}

dhcp_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install) dhcp_install "$@" ;;
    scope) dhcp_scope_command "$@" ;;
    reservation) dhcp_reservation_command "$@" ;;
    lease) dhcp_lease_command "$@" ;;
    config) dhcp_config_command "$@" ;;
    service) require_args 1 "$#" 'netadmin dhcp service <action>'; service_action dhcpd "$1" ;;
    help|-h|--help) dhcp_help ;;
    *) dhcp_help; die "DHCP command không hỗ trợ: $command" ;;
  esac
}
