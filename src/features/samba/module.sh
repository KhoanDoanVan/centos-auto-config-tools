#!/usr/bin/env bash

source "$APP_ROOT/src/features/samba/infra/smb.sh"
source "$APP_ROOT/src/features/samba/commands/install.sh"
source "$APP_ROOT/src/features/samba/commands/share.sh"
source "$APP_ROOT/src/features/samba/commands/user.sh"
source "$APP_ROOT/src/features/samba/commands/operations.sh"
source "$APP_ROOT/src/features/samba/commands/client.sh"

samba_help() {
  cat <<'EOF'
Cách dùng: netadmin samba <command> [arguments]

  install
  share add-public <name> <path> [read-only|read-write]
  share add-group <name> <path> <group> [read-only|read-write]
  share list | share remove <name>
  user add <username> <group> | user remove <username> | user list
  permissions grant <share> <username|@group> <read|write>
  status | sessions
  config show | config check | config apply | config rollback
  service <start|stop|restart|status|enable|enable-now>
  client list //<server>/<share> [username]
  client copy //<server>/<share> <remote-item> <destination> [username]
EOF
}

samba_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install) samba_install "$@" ;;
    share) samba_share_command "$@" ;;
    user) samba_user_command "$@" ;;
    permissions) samba_permissions_command "$@" ;;
    status) service_action smb status ;;
    sessions) require_command smbstatus; smbstatus ;;
    config) samba_config_command "$@" ;;
    service) require_args 1 "$#" 'netadmin samba service <action>'; service_action smb "$1"; [[ "$1" == status ]] || service_action nmb "$1" ;;
    client) samba_client_command "$@" ;;
    help|-h|--help) samba_help ;;
    *) samba_help; die "Samba command không hỗ trợ: $command" ;;
  esac
}
