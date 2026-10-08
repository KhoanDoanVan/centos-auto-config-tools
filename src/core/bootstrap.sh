#!/usr/bin/env bash

app_bootstrap() {
  local file
  for file in log errors paths validation prompt system backup registry; do
    # shellcheck source=/dev/null
    source "$APP_ROOT/src/core/$file.sh"
  done

  : "${NETADMIN_CONFIG:=$APP_ROOT/config/netadmin.conf}"
  if [[ -r "$NETADMIN_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$NETADMIN_CONFIG"
  fi
  : "${NETADMIN_BACKUP_DIR:=/var/backups/netadmin}"
  : "${NETADMIN_DRY_RUN:=0}"

  local module
  for module in doctor dhcp dns storage samba; do
    # shellcheck source=/dev/null
    source "$APP_ROOT/src/features/$module/module.sh"
  done
  trap 'on_unexpected_error $? $LINENO "$BASH_COMMAND"' ERR
}

app_dispatch() {
  local command="${1:-help}"
  shift || true
  case "$command" in
    help|-h|--help) print_root_help ;;
    version|--version) printf '%s\n' 'netadmin 1.0.0' ;;
    *) dispatch_command "$command" "$@" ;;
  esac
}
